import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../data/models/word.dart';
import '../data/repositories/word_repository.dart';
import 'word_graph_cache.dart';

const double _centerNodeSize = 180.0;
const double _centerNodeHalf = _centerNodeSize / 2;
const double _connectedNodeSize = 80.0;
const double _connectedNodeHalf = _connectedNodeSize / 2;
const double _graphViewportPadding = 28.0;
const double _preferredNodeGap = 28.0;
const double _minimumNodeGap = 12.0;
const double _preferredCenterGap = 18.0;
const double _minimumCenterGap = 8.0;
const double _ringSpacing = 92.0;
const double _labelAnchorFactor = 0.68;
const double _fitBoundsPadding = 72.0;
const double _baseLabelOffset = 12.0;
const int _nodeOverlapAdjustmentPasses = 6;
const double _nodeMaxAngleShift = pi / 18;
const double _nodeMaxRadialShift = 12.0;
const double _crossRingNodeGap = 6.0;
const int _labelPlacementMaxAttempts = 7;
const double _labelPlacementStep = 8.0;
const double _labelPlacementRadialStep = 6.0;
const double _labelMaxShiftDistance = 28.0;
const double _labelCollisionPadding = 4.0;
const double _edgeLabelFontSize = 11.0;
const double _edgeLabelHorizontalPadding = 8.0;
const double _edgeLabelVerticalPadding = 4.0;
const double _centerNodeBorderWidth = 4.0;
const double _centerNodeShadowBlur = 26.0;
const double _centerNodeShadowSpread = 2.0;
const double _connectedNodeDefaultBorderWidth = 2.0;
const double _connectedNodeSelectedBorderWidth = 4.0;
const double _connectedNodeMutedBorderWidth = 1.6;
const double _selectedEdgeStrokeWidth = 4.5;
const double _defaultEdgeStrokeWidth = 2.0;
const double _mutedEdgeStrokeWidth = 1.5;
const double _mutedEdgeOpacity = 0.4;
const double _defaultEdgeLabelBorderWidth = 1.5;
const double _selectedEdgeLabelBorderWidth = 1.8;
const double _defaultEdgeLabelBorderOpacity = 0.9;
const double _mutedEdgeLabelBorderOpacity = 0.72;

class _GraphNodeLayout {
  final int index;
  final Offset center;
  final Rect nodeBounds;
  final Offset labelAnchor;
  final Offset labelNormal;
  final double radius;
  final double angle;
  final int ringIndex;

  const _GraphNodeLayout({
    required this.index,
    required this.center,
    required this.nodeBounds,
    required this.labelAnchor,
    required this.labelNormal,
    required this.radius,
    required this.angle,
    required this.ringIndex,
  });

  Offset labelCenter(double sceneScale) {
    final scale = sceneScale <= 0 ? 1.0 : sceneScale;
    final offset = (_baseLabelOffset / scale).clamp(6.0, 14.0);
    return Offset(
      labelAnchor.dx + labelNormal.dx * offset,
      labelAnchor.dy + labelNormal.dy * offset,
    );
  }
}

class _GraphLayoutData {
  final Size canvasSize;
  final Offset center;
  final Rect centerBounds;
  final List<_GraphNodeLayout> nodeLayouts;
  final Rect contentBounds;
  final Rect fitBounds;
  final List<double> ringRadii;

  const _GraphLayoutData({
    required this.canvasSize,
    required this.center,
    required this.centerBounds,
    required this.nodeLayouts,
    required this.contentBounds,
    required this.fitBounds,
    required this.ringRadii,
  });

  bool get usesMultipleRings => ringRadii.length > 1;
}

class _MutableGraphNodePlacement {
  final int index;
  final int ringIndex;
  final int orderOnRing;
  final double baseAngle;
  final double baseRadius;
  final double minRadius;
  final double maxRadius;
  final double maxAngleShift;
  double angle;
  double radius;

  _MutableGraphNodePlacement({
    required this.index,
    required this.ringIndex,
    required this.orderOnRing,
    required this.baseAngle,
    required this.baseRadius,
    required this.minRadius,
    required this.maxRadius,
    required this.maxAngleShift,
  }) : angle = baseAngle,
       radius = baseRadius;

  double get minAngle => baseAngle - maxAngleShift;
  double get maxAngle => baseAngle + maxAngleShift;
}

/// 신규 단어 생성 다이얼로그의 결과를 담는 DTO
class CreateWordPayload {
  final String language;
  final String? strongNumber;
  final String spelling1;
  final String? pronunciation1;
  final String? meaning1;
  final String? note;

  /// true면 단어 저장 후 현재 중심 단어와 관계 추가를 이어서 진행
  final bool createRelationAfterSave;

  CreateWordPayload({
    required this.language,
    required this.strongNumber,
    required this.spelling1,
    required this.pronunciation1,
    required this.meaning1,
    required this.note,
    required this.createRelationAfterSave,
  });
}

/// CreateRelationPayload
/// - "관계 추가" 다이얼로그에서 사용자가 입력한 값을 담는 DTO(전달용 객체)
/// - WordGraphScreen 내부 로직에서만 쓰지만, Dart의 스코프 제약 때문에
///   파일 최상단에 둔다(타입 인식 안정성 확보).
class CreateRelationPayload {
  final String? categoryCode;
  final String? relationType;
  final String? note;
  final String? source;

  CreateRelationPayload({
    required this.categoryCode,
    required this.relationType,
    required this.note,
    required this.source,
  });
}

/// WordGraphScreen
/// - 중심 단어(선택된 단어)를 기준으로
/// - WORD_RELATION을 통해 연결된 단어들을 원형으로 배치하고
/// - 중심↔연결 단어 간 엣지(선)를 그리는 화면
class WordGraphScreen extends StatefulWidget {
  /// 그래프의 중심이 되는 단어(모델)
  final Word centerWord;

  /// 스플릿뷰 등에서 노드 클릭 시 화면 push 대신
  /// 선택 이벤트만 전달하고 싶을 때 사용한다.
  final ValueChanged<Word>? onSelectWord;

  /// 스플릿뷰에서 이미 선택된 노드를 다시 클릭했을 때
  /// 부모가 중심 단어를 바꾸도록 알린다.
  final ValueChanged<Word>? onChangeCenterWord;

  const WordGraphScreen({
    super.key,
    required this.centerWord,
    this.onSelectWord,
    this.onChangeCenterWord,
  });

  @override
  State<WordGraphScreen> createState() => _WordGraphScreenState();
}

class _WordGraphScreenState extends State<WordGraphScreen> {
  final WordRepository _repository = WordRepository();

  /// 그래프 줌/팬 상태를 관리하는 컨트롤러
  final TransformationController _transformController =
      TransformationController();

  /// 현재 줌 배율(태그 표시/숨김 등에 사용)
  double _currentScale = 1.0;

  /// 이 배율보다 작아지면 엣지 태그를 숨긴다(가독성/겹침 감소)
  static const double _labelVisibleScaleThreshold = 1.15;

  late final Word _centerWord;

  bool _isLoading = true;
  String? _errorMessage;

  /// 중심 단어와 연결된 단어 목록
  List<Word> _connectedWords = [];

  /// 사용자가 클릭(선택)한 주변 노드 id
  /// - 같은 노드를 다시 클릭하면 이동(push)하는 트리거로 사용
  String? _selectedWordId;

  /// 상대 단어 id 기준으로 관계(엣지) 메타를 보관한다.
  /// - 여러 관계가 있을 수 있으나, 현재는 “표시용 1개”만 선택(마지막으로 덮어씀)
  final Map<String, WordRelationEdgeInfo> _edgeInfoByOtherId = {};

  @override
  void initState() {
    super.initState();
    _centerWord = widget.centerWord;
    final cachedGraph = WordGraphDataCache.get(_centerWord.id);
    if (cachedGraph != null) {
      _applyGraphData(
        words: cachedGraph.connectedWords,
        edges: cachedGraph.relationEdges,
      );
      return;
    }

    _loadConnectedWords();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _applyGraphData({
    required List<Word> words,
    required List<WordRelationEdgeInfo> edges,
  }) {
    _connectedWords = words;

    _edgeInfoByOtherId.clear();
    for (final e in edges) {
      _edgeInfoByOtherId[e.otherWordId] = e;
    }

    _errorMessage = null;
    _isLoading = false;
  }

  Future<void> _loadConnectedWords() async {
    final cachedGraph = WordGraphDataCache.get(_centerWord.id);
    if (cachedGraph != null) {
      if (!mounted) return;
      setState(() {
        _applyGraphData(
          words: cachedGraph.connectedWords,
          edges: cachedGraph.relationEdges,
        );
      });
      return;
    }

    try {
      final words = await _repository.getConnectedWords(_centerWord.id);
      final edges = await _repository.getRelationEdges(_centerWord.id);
      WordGraphDataCache.put(
        centerWordId: _centerWord.id,
        connectedWords: words,
        relationEdges: edges,
      );

      if (!mounted) return;
      setState(() {
        _applyGraphData(words: words, edges: edges);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '연결 단어 로딩 실패: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Word Graph')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 에러
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Word Graph')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        final nodes = _connectedWords;
        final layout = _computeGraphLayout(canvasSize, nodes.length);

        // 노드 배치 순서와 동일한 순서로 엣지 색상/라벨 생성
        final edgeColors = nodes.map((w) {
          final info = _edgeInfoByOtherId[w.id];
          return _colorForCategory(info?.categoryCode);
        }).toList();
        final edgeLabels = nodes.map((w) {
          final info = _edgeInfoByOtherId[w.id];
          return _labelForEdge(info);
        }).toList();

        // 선택된 노드가 연결 노드 목록에서 몇 번째인지(없으면 null)
        final int selectedIndexRaw = nodes.indexWhere(
          (w) => w.id == _selectedWordId,
        );
        final int? selectedIndex = (selectedIndexRaw >= 0)
            ? selectedIndexRaw
            : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Word Graph'),
            actions: [
              IconButton(
                tooltip: '전체보기',
                icon: const Icon(Icons.fit_screen),
                onPressed: () => _fitToView(layout),
              ),
              IconButton(
                tooltip: '보기 초기화',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _transformController.value = Matrix4.identity();
                  setState(() => _currentScale = 1.0);
                },
              ),
              IconButton(
                tooltip: '관계 추가',
                icon: const Icon(Icons.add_link),
                onPressed: _showAddRelationFlow,
              ),

              IconButton(
                tooltip: '단어 추가',
                icon: const Icon(Icons.note_add),
                onPressed: _showCreateWordFlow,
              ),
            ],
          ),
          body: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _handlePointerScroll(event);
              }
            },
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.6,
              maxScale: 3.5,
              boundaryMargin: const EdgeInsets.all(2000),
              panEnabled: true,
              scaleEnabled: true,
              onInteractionUpdate: (_) {
                final newScale = _transformController.value.getMaxScaleOnAxis();
                if (newScale != _currentScale) {
                  setState(() => _currentScale = newScale);
                }
              },
              child: SizedBox(
                width: canvasSize.width,
                height: canvasSize.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (nodes.isNotEmpty)
                      CustomPaint(
                        size: canvasSize,
                        painter: GraphLinePainter(
                          layout: layout,
                          edgeColors: edgeColors,
                          edgeLabels: edgeLabels,
                          showLabels: false,
                          sceneScale: _currentScale,
                          selectedIndex: selectedIndex,
                        ),
                      ),
                    Positioned(
                      left: layout.centerBounds.left,
                      top: layout.centerBounds.top,
                      child: _buildCenterNode(_centerWord),
                    ),
                    ..._buildEdgeLabelWidgets(
                      layout,
                      nodes,
                      edgeLabels,
                      edgeColors,
                      selectedIndex: selectedIndex,
                    ),

                    ..._buildWordNodes(
                      layout,
                      nodes,
                      hasSelection: selectedIndex != null,
                    ),
                    if (nodes.isEmpty)
                      Center(
                        child: Text(
                          '연결된 단어가 없습니다.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 중앙(선택) 단어 노드
  Color _blendColor(Color color, Color target, double amount) {
    return Color.lerp(color, target, amount) ?? color;
  }

  Widget _buildCenterNode(Word word) {
    final language = (word.language ?? '').trim();
    final strongNumber = (word.strongNumber ?? '').trim();
    final spelling = (word.spelling1 ?? '').trim();
    final pronunciation = (word.pronunciation1 ?? '').trim();
    final transliteration = (word.transliteration1 ?? '').trim();
    final meaning = (word.meaning1 ?? '').trim();
    final children = <Widget>[];

    void addNodeText(Widget child, {double gap = 6}) {
      if (children.isNotEmpty) {
        children.add(SizedBox(height: gap));
      }
      children.add(child);
    }

    if (language.isNotEmpty) {
      addNodeText(Text(language, style: const TextStyle(fontSize: 12)), gap: 4);
    }

    if (strongNumber.isNotEmpty) {
      addNodeText(
        Text(strongNumber, style: const TextStyle(fontSize: 12)),
        gap: 4,
      );
    }

    if (spelling.isNotEmpty) {
      addNodeText(
        Text(
          spelling,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (transliteration.isNotEmpty) {
      addNodeText(
        Text(
          transliteration,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
      );
    }

    if (pronunciation.isNotEmpty) {
      addNodeText(
        Text(
          pronunciation,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      );
    }

    if (meaning.isNotEmpty) {
      addNodeText(
        Text(
          meaning,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      );
    }

    return Container(
      width: _centerNodeSize,
      height: _centerNodeSize,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white,
            Colors.blue.shade50,
            Colors.blue.shade100,
          ],
          stops: const [0.0, 0.62, 1.0],
        ),
        border: Border.all(
          color: Colors.blue.shade700,
          width: _centerNodeBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withValues(alpha: 0.5),
            blurRadius: _centerNodeShadowBlur,
            spreadRadius: _centerNodeShadowSpread,
          ),
          BoxShadow(
            color: Colors.blue.shade900.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }

  /// 연결 단어 노드(원형)
  Widget _buildWordNode(
    Word word,
    Color borderColor, {
    required bool hasSelection,
  }) {
    final label = (word.spelling1 != null && word.spelling1!.trim().isNotEmpty)
        ? word.spelling1!.trim()
        : word.id;
    final transliteration = (word.transliteration1 ?? '').trim();

    final bool isSelected = (_selectedWordId == word.id);
    final Color effectiveBorderColor = isSelected
        ? _blendColor(borderColor, Colors.black, 0.18)
        : hasSelection
            ? _blendColor(borderColor, Colors.grey.shade500, 0.42)
            : borderColor;
    final Color fillColor = isSelected
        ? Color.alphaBlend(
            borderColor.withValues(alpha: 0.14),
            Colors.white,
          )
        : hasSelection
            ? Color.alphaBlend(
                borderColor.withValues(alpha: 0.04),
                Colors.white,
              )
            : Colors.white;
    final double borderWidth = isSelected
        ? _connectedNodeSelectedBorderWidth
        : hasSelection
            ? _connectedNodeMutedBorderWidth
            : _connectedNodeDefaultBorderWidth;

    return GestureDetector(
      onTap: () {
        // 1) 먼저 선택 상태를 갱신한다(강조 표시용).
        //    - 이미 선택된 노드를 다시 클릭한 경우에만 "이동"을 허용한다.
        final bool isSameTap = (_selectedWordId == word.id);

        if (!isSameTap) {
          setState(() => _selectedWordId = word.id);
        }

        // 2) 스플릿뷰 모드: 선택 이벤트 전달(화면 push는 하지 않음)
        if (widget.onSelectWord != null) {
          if (isSameTap && widget.onChangeCenterWord != null) {
            widget.onChangeCenterWord!(word);
            return;
          }

          widget.onSelectWord!(word);
          return;
        }

        // 3) 단독 화면 모드: 같은 노드를 2번 눌렀을 때만 그래프 이동
        if (isSameTap) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WordGraphScreen(centerWord: word),
            ),
          );
        }
      },
      child: Container(
        width: _connectedNodeSize,
        height: _connectedNodeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: effectiveBorderColor, width: borderWidth),
          color: fillColor,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              if (transliteration.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  transliteration,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 연결 단어들을 원형으로 자동 배치
  _GraphLayoutData _computeGraphLayout(Size canvasSize, int nodeCount) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final centerBounds = Rect.fromCenter(
      center: center,
      width: _centerNodeSize,
      height: _centerNodeSize,
    );

    if (nodeCount == 0) {
      return _GraphLayoutData(
        canvasSize: canvasSize,
        center: center,
        centerBounds: centerBounds,
        nodeLayouts: const [],
        contentBounds: centerBounds,
        fitBounds: centerBounds.inflate(_fitBoundsPadding * 0.5),
        ringRadii: const [],
      );
    }

    final availableRadiusX = max(
      0.0,
      canvasSize.width / 2 - _connectedNodeHalf - _graphViewportPadding,
    );
    final availableRadiusY = max(
      0.0,
      canvasSize.height / 2 - _connectedNodeHalf - _graphViewportPadding,
    );
    final maxRadius = max(0.0, min(availableRadiusX, availableRadiusY));

    final preferredMinimumRadius =
        _centerNodeHalf + _connectedNodeHalf + _preferredCenterGap;
    final minimumInnerRadius =
        _centerNodeHalf + _connectedNodeHalf + _minimumCenterGap;
    final preferredSpacing = _connectedNodeSize + _preferredNodeGap;
    final minimumSpacing = _connectedNodeSize + _minimumNodeGap;

    final preferredSingleRingRadius = max(
      preferredMinimumRadius,
      _requiredRingRadius(nodeCount, preferredSpacing),
    );
    final singleRingCapacity = _ringCapacity(maxRadius, minimumSpacing);

    List<double> ringRadii;
    if (maxRadius <= 0) {
      ringRadii = const [0.0];
    } else if (preferredSingleRingRadius <= maxRadius ||
        nodeCount <= singleRingCapacity) {
      final singleRingRadius = preferredSingleRingRadius <= maxRadius
          ? preferredSingleRingRadius
          : maxRadius;
      ringRadii = [singleRingRadius];
    } else {
      ringRadii = _buildRingRadii(
        nodeCount: nodeCount,
        maxRadius: maxRadius,
        innerRadiusFloor: min(maxRadius, minimumInnerRadius),
        minimumSpacing: minimumSpacing,
      );
      if (ringRadii.length == 1) {
        ringRadii = [maxRadius];
      }
    }

    final nodeCounts = _distributeNodesAcrossRings(
      nodeCount,
      ringRadii,
      minimumSpacing,
    );

    final placements = <_MutableGraphNodePlacement>[];
    var nextIndex = 0;

    for (int ringIndex = 0; ringIndex < ringRadii.length; ringIndex++) {
      final radius = ringRadii[ringIndex];
      final countOnRing = nodeCounts[ringIndex];
      if (countOnRing <= 0) continue;

      final angleStep = 2 * pi / countOnRing;
      final maxAngleShift = countOnRing <= 1
          ? 0.0
          : min(_nodeMaxAngleShift, angleStep * 0.28);
      final startAngle =
          -pi / 2 +
          ((ringIndex.isOdd && countOnRing > 1) ? angleStep / 2 : 0.0);
      final minRadius = ringIndex == 0
          ? radius
          : max(minimumInnerRadius, radius - _nodeMaxRadialShift);
      final maxRadiusForRing = min(maxRadius, radius + _nodeMaxRadialShift);

      for (
        int localIndex = 0;
        localIndex < countOnRing && nextIndex < nodeCount;
        localIndex++, nextIndex++
      ) {
        final angle = startAngle + angleStep * localIndex;
        placements.add(
          _MutableGraphNodePlacement(
            index: nextIndex,
            ringIndex: ringIndex,
            orderOnRing: localIndex,
            baseAngle: angle,
            baseRadius: radius,
            minRadius: minRadius,
            maxRadius: maxRadiusForRing,
            maxAngleShift: maxAngleShift,
          ),
        );
      }
    }

    _applyNodeOverlapReduction(center: center, placements: placements);

    final nodeLayouts = placements
        .map(
          (placement) => _buildNodeLayout(center: center, placement: placement),
        )
        .toList(growable: false);

    Rect contentBounds = centerBounds;
    for (final nodeLayout in nodeLayouts) {
      contentBounds = contentBounds.expandToInclude(nodeLayout.nodeBounds);
    }

    final fitPadding = _fitBoundsPadding + (ringRadii.length > 1 ? 12.0 : 0.0);

    return _GraphLayoutData(
      canvasSize: canvasSize,
      center: center,
      centerBounds: centerBounds,
      nodeLayouts: nodeLayouts,
      contentBounds: contentBounds,
      fitBounds: contentBounds.inflate(fitPadding),
      ringRadii: ringRadii,
    );
  }

  List<double> _buildRingRadii({
    required int nodeCount,
    required double maxRadius,
    required double innerRadiusFloor,
    required double minimumSpacing,
  }) {
    final radiiDescending = <double>[maxRadius];
    var totalCapacity = _ringCapacity(maxRadius, minimumSpacing);
    var nextRadius = maxRadius - _ringSpacing;

    while (totalCapacity < nodeCount && nextRadius >= innerRadiusFloor) {
      radiiDescending.add(nextRadius);
      totalCapacity += _ringCapacity(nextRadius, minimumSpacing);
      nextRadius -= _ringSpacing;
    }

    if (totalCapacity < nodeCount) {
      return [maxRadius];
    }

    return radiiDescending.reversed.toList();
  }

  List<int> _distributeNodesAcrossRings(
    int nodeCount,
    List<double> ringRadii,
    double minimumSpacing,
  ) {
    if (ringRadii.isEmpty) return const [];
    if (ringRadii.length == 1) return [nodeCount];

    final capacities = ringRadii
        .map((radius) => max(1, _ringCapacity(radius, minimumSpacing)))
        .toList();
    final counts = List<int>.filled(ringRadii.length, 0);

    for (int nodeIndex = 0; nodeIndex < nodeCount; nodeIndex++) {
      int targetRing = 0;
      double targetLoad = double.infinity;

      for (int ringIndex = 0; ringIndex < capacities.length; ringIndex++) {
        final load = counts[ringIndex] / capacities[ringIndex];
        if (load < targetLoad) {
          targetLoad = load;
          targetRing = ringIndex;
        }
      }

      counts[targetRing]++;
    }

    return counts;
  }

  int _ringCapacity(double radius, double spacingPerNode) {
    if (radius <= 0 || spacingPerNode <= 0) return 1;
    return max(1, (2 * pi * radius / spacingPerNode).floor());
  }

  double _requiredRingRadius(int nodeCount, double spacingPerNode) {
    if (nodeCount <= 0 || spacingPerNode <= 0) return 0;
    return nodeCount * spacingPerNode / (2 * pi);
  }

  _GraphNodeLayout _buildNodeLayout({
    required Offset center,
    required _MutableGraphNodePlacement placement,
  }) {
    final nodeCenter = _polarOffset(
      center: center,
      radius: placement.radius,
      angle: placement.angle,
    );
    final vx = nodeCenter.dx - center.dx;
    final vy = nodeCenter.dy - center.dy;
    final vectorLength = sqrt(vx * vx + vy * vy);
    final safeLength = vectorLength == 0 ? 1.0 : vectorLength;

    return _GraphNodeLayout(
      index: placement.index,
      center: nodeCenter,
      nodeBounds: Rect.fromCenter(
        center: nodeCenter,
        width: _connectedNodeSize,
        height: _connectedNodeSize,
      ),
      labelAnchor: Offset(
        center.dx + vx * _labelAnchorFactor,
        center.dy + vy * _labelAnchorFactor,
      ),
      labelNormal: Offset(-vy / safeLength, vx / safeLength),
      radius: placement.radius,
      angle: placement.angle,
      ringIndex: placement.ringIndex,
    );
  }

  void _applyNodeOverlapReduction({
    required Offset center,
    required List<_MutableGraphNodePlacement> placements,
  }) {
    if (placements.length < 2) return;

    for (int pass = 0; pass < _nodeOverlapAdjustmentPasses; pass++) {
      final angleDelta = List<double>.filled(placements.length, 0.0);
      final radiusDelta = List<double>.filled(placements.length, 0.0);
      final positions = placements
          .map(
            (placement) => _polarOffset(
              center: center,
              radius: placement.radius,
              angle: placement.angle,
            ),
          )
          .toList(growable: false);

      var foundOverlap = false;

      for (int i = 0; i < placements.length; i++) {
        final a = placements[i];

        for (int j = i + 1; j < placements.length; j++) {
          final b = placements[j];
          if ((a.ringIndex - b.ringIndex).abs() > 1) continue;

          final desiredDistance = _desiredNodeDistance(a, b);
          final dx = positions[j].dx - positions[i].dx;
          final dy = positions[j].dy - positions[i].dy;
          final distance = sqrt(dx * dx + dy * dy);
          if (distance >= desiredDistance) continue;

          foundOverlap = true;
          final safeDistance = distance <= 0.001 ? 0.001 : distance;
          final pushDistance = (desiredDistance - safeDistance) * 0.5;
          final direction = Offset(dx / safeDistance, dy / safeDistance);
          final sameRing = a.ringIndex == b.ringIndex;

          _accumulateNodeRepulsion(
            center: center,
            placement: a,
            currentPosition: positions[i],
            pushDirection: Offset(-direction.dx, -direction.dy),
            pushDistance: pushDistance,
            sameRing: sameRing,
            angleDelta: angleDelta,
            radiusDelta: radiusDelta,
            targetIndex: i,
          );
          _accumulateNodeRepulsion(
            center: center,
            placement: b,
            currentPosition: positions[j],
            pushDirection: direction,
            pushDistance: pushDistance,
            sameRing: sameRing,
            angleDelta: angleDelta,
            radiusDelta: radiusDelta,
            targetIndex: j,
          );
        }
      }

      if (!foundOverlap) {
        break;
      }

      for (int i = 0; i < placements.length; i++) {
        final placement = placements[i];
        final nextRadius = (placement.radius + radiusDelta[i].clamp(-4.0, 4.0))
            .clamp(placement.minRadius, placement.maxRadius)
            .toDouble();
        final nextAngle = (placement.angle + angleDelta[i].clamp(-0.045, 0.045))
            .clamp(placement.minAngle, placement.maxAngle)
            .toDouble();

        placement.radius = nextRadius;
        placement.angle = nextAngle;
      }

      _enforceRingOrder(placements);
    }
  }

  double _desiredNodeDistance(
    _MutableGraphNodePlacement a,
    _MutableGraphNodePlacement b,
  ) {
    final gap = a.ringIndex == b.ringIndex
        ? _minimumNodeGap
        : _crossRingNodeGap;
    return _connectedNodeSize + gap;
  }

  void _accumulateNodeRepulsion({
    required Offset center,
    required _MutableGraphNodePlacement placement,
    required Offset currentPosition,
    required Offset pushDirection,
    required double pushDistance,
    required bool sameRing,
    required List<double> angleDelta,
    required List<double> radiusDelta,
    required int targetIndex,
  }) {
    final vx = currentPosition.dx - center.dx;
    final vy = currentPosition.dy - center.dy;
    final vectorLength = sqrt(vx * vx + vy * vy);
    final safeLength = vectorLength <= 0.001 ? 1.0 : vectorLength;
    final radial = Offset(vx / safeLength, vy / safeLength);
    final tangential = Offset(-radial.dy, radial.dx);
    final radialComponent =
        pushDirection.dx * radial.dx + pushDirection.dy * radial.dy;
    final tangentialComponent =
        pushDirection.dx * tangential.dx + pushDirection.dy * tangential.dy;
    final radialWeight = sameRing ? 0.28 : 0.48;
    final angularWeight = sameRing ? 0.82 : 0.45;

    radiusDelta[targetIndex] += radialComponent * pushDistance * radialWeight;
    angleDelta[targetIndex] +=
        tangentialComponent *
        pushDistance *
        angularWeight /
        max(placement.radius, 1.0);
  }

  void _enforceRingOrder(List<_MutableGraphNodePlacement> placements) {
    final placementsByRing = <int, List<_MutableGraphNodePlacement>>{};
    for (final placement in placements) {
      placementsByRing
          .putIfAbsent(
            placement.ringIndex,
            () => <_MutableGraphNodePlacement>[],
          )
          .add(placement);
    }

    for (final ringPlacements in placementsByRing.values) {
      ringPlacements.sort((a, b) => a.orderOnRing.compareTo(b.orderOnRing));

      double previousAngle = -double.infinity;
      for (final placement in ringPlacements) {
        final minAngle = max(placement.minAngle, previousAngle + 0.001);
        final maxAngle = placement.maxAngle;
        placement.angle =
            (minAngle > maxAngle
                    ? maxAngle
                    : placement.angle.clamp(minAngle, maxAngle))
                .toDouble();
        previousAngle = placement.angle;
      }

      double nextAngle = double.infinity;
      for (final placement in ringPlacements.reversed) {
        final minAngle = placement.minAngle;
        final maxAngle = min(placement.maxAngle, nextAngle - 0.001);
        placement.angle =
            (minAngle > maxAngle
                    ? minAngle
                    : placement.angle.clamp(minAngle, maxAngle))
                .toDouble();
        nextAngle = placement.angle;
      }
    }
  }

  Offset _polarOffset({
    required Offset center,
    required double radius,
    required double angle,
  }) {
    return Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );
  }

  List<Widget> _buildWordNodes(
    _GraphLayoutData layout,
    List<Word> words, {
    required bool hasSelection,
  }) {
    if (words.isEmpty) return [];

    final List<Widget> widgets = [];

    for (final nodeLayout in layout.nodeLayouts) {
      final index = nodeLayout.index;
      widgets.add(
        Positioned(
          left: nodeLayout.nodeBounds.left,
          top: nodeLayout.nodeBounds.top,
          child: _buildWordNode(
            words[index],
            _colorForCategory(
              _edgeInfoByOtherId[words[index].id]?.categoryCode,
            ),
            hasSelection: hasSelection,
          ),
        ),
      );
    }

    return widgets;
  }

  /// 엣지 태그(라벨)를 "클릭 가능한 위젯"으로 렌더링한다.
  /// - Painter는 선만 그리고, 태그는 위젯으로 올려서 클릭 이벤트를 처리한다.
  List<Widget> _buildEdgeLabelWidgets(
    _GraphLayoutData layout,
    List<Word> nodes,
    List<String> edgeLabels,
    List<Color> edgeColors, {
    required int? selectedIndex,
  }) {
    // 줌이 작으면 태그 숨김(기존 정책 유지)
    if (_currentScale < _labelVisibleScaleThreshold) return [];
    if (nodes.isEmpty) return [];

    // 태그가 선 위에 겹치지 않도록 약간 수직 방향 오프셋(줌 역보정)

    final List<Widget> widgets = [];
    final placedLabelBounds = <Rect>[];
    final nodeObstacles = <Rect>[
      layout.centerBounds.inflate(_labelCollisionPadding),
      for (final nodeLayout in layout.nodeLayouts)
        nodeLayout.nodeBounds.inflate(_labelCollisionPadding),
    ];

    for (final nodeLayout in layout.nodeLayouts) {
      final index = nodeLayout.index;
      final label = edgeLabels[index].trim();
      if (label.isEmpty) continue;

      // 중심 -> 주변 방향 벡터

      // 태그는 중심에서 멀어지게(주변 노드 쪽)

      // 수직 단위벡터

      final placement = _resolveEdgeLabelPlacement(
        layout: layout,
        nodeLayout: nodeLayout,
        label: label,
        nodeObstacles: nodeObstacles,
        placedLabelBounds: placedLabelBounds,
      );
      final pos = placement.center;
      placedLabelBounds.add(placement.bounds);

      final otherWord = nodes[index];
      final edgeInfo = _edgeInfoByOtherId[otherWord.id];
      final bool hasSelection = selectedIndex != null;
      final bool isSelectedEdge = selectedIndex == index;
      final Color labelBorderColor = isSelectedEdge
          ? _blendColor(edgeColors[index], Colors.black, 0.08)
          : edgeColors[index].withValues(
              alpha: hasSelection
                  ? _mutedEdgeLabelBorderOpacity
                  : _defaultEdgeLabelBorderOpacity,
            );
      final Color labelBackgroundColor = isSelectedEdge
          ? Color.alphaBlend(
              edgeColors[index].withValues(alpha: 0.12),
              Colors.white,
            )
          : Colors.white;
      final double labelBorderWidth = isSelectedEdge
          ? _selectedEdgeLabelBorderWidth
          : _defaultEdgeLabelBorderWidth;

      widgets.add(
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: GestureDetector(
              onTap: () {
                if (edgeInfo == null) return;
                _showEdgeDetailDialog(otherWord, edgeInfo);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _edgeLabelHorizontalPadding,
                  vertical: _edgeLabelVerticalPadding,
                ),
                decoration: BoxDecoration(
                  color: labelBackgroundColor,
                  border: Border.all(
                    color: labelBorderColor,
                    width: labelBorderWidth,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: _edgeLabelFontSize,
                    fontWeight: isSelectedEdge
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  /// 엣지(관계) 상세/편집 팝업
  /// - 기본은 읽기 전용
  /// - [편집] 버튼을 눌러야 입력 컨트롤이 활성화된다(실수 방지)
  ({Offset center, Rect bounds}) _resolveEdgeLabelPlacement({
    required _GraphLayoutData layout,
    required _GraphNodeLayout nodeLayout,
    required String label,
    required List<Rect> nodeObstacles,
    required List<Rect> placedLabelBounds,
  }) {
    final baseCenter = nodeLayout.labelCenter(_currentScale);
    final radial = _unitVector(
      Offset(
        nodeLayout.center.dx - layout.center.dx,
        nodeLayout.center.dy - layout.center.dy,
      ),
    );

    Offset bestCenter = baseCenter;
    Rect bestBounds = _measureEdgeLabelBounds(label: label, center: baseCenter);
    double bestScore = double.infinity;

    for (int attempt = 0; attempt < _labelPlacementMaxAttempts; attempt++) {
      final candidateCenter = _candidateEdgeLabelCenter(
        baseCenter: baseCenter,
        normal: nodeLayout.labelNormal,
        radial: radial,
        attempt: attempt,
      );
      final shiftDistance = (candidateCenter - baseCenter).distance;
      if (shiftDistance > _labelMaxShiftDistance) continue;

      final candidateBounds = _measureEdgeLabelBounds(
        label: label,
        center: candidateCenter,
      );
      final collisionScore = _edgeLabelCollisionScore(
        bounds: candidateBounds,
        nodeObstacles: nodeObstacles,
        placedLabelBounds: placedLabelBounds,
      );

      if (collisionScore < bestScore) {
        bestScore = collisionScore;
        bestCenter = candidateCenter;
        bestBounds = candidateBounds;
      }

      if (collisionScore == 0.0) {
        break;
      }
    }

    return (center: bestCenter, bounds: bestBounds);
  }

  Offset _candidateEdgeLabelCenter({
    required Offset baseCenter,
    required Offset normal,
    required Offset radial,
    required int attempt,
  }) {
    if (attempt == 0) return baseCenter;

    final tier = ((attempt + 1) / 2).ceil();
    final normalSign = attempt.isOdd ? 1.0 : -1.0;
    final lateralShift = min(
      _labelPlacementStep * tier,
      _labelMaxShiftDistance,
    );
    final radialShift = min(
      _labelPlacementRadialStep * max(0, tier - 1),
      _labelMaxShiftDistance,
    );

    return Offset(
      baseCenter.dx +
          normal.dx * lateralShift * normalSign +
          radial.dx * radialShift,
      baseCenter.dy +
          normal.dy * lateralShift * normalSign +
          radial.dy * radialShift,
    );
  }

  Rect _measureEdgeLabelBounds({
    required String label,
    required Offset center,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: _edgeLabelFontSize,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    return Rect.fromCenter(
      center: center,
      width: textPainter.width + _edgeLabelHorizontalPadding * 2,
      height: textPainter.height + _edgeLabelVerticalPadding * 2,
    );
  }

  double _edgeLabelCollisionScore({
    required Rect bounds,
    required List<Rect> nodeObstacles,
    required List<Rect> placedLabelBounds,
  }) {
    final paddedBounds = bounds.inflate(_labelCollisionPadding);
    double score = 0.0;

    for (final obstacle in nodeObstacles) {
      score += _intersectionArea(paddedBounds, obstacle);
    }

    for (final placedBounds in placedLabelBounds) {
      score += _intersectionArea(paddedBounds, placedBounds);
    }

    return score;
  }

  double _intersectionArea(Rect a, Rect b) {
    final overlap = a.intersect(b);
    if (overlap.isEmpty) return 0.0;
    return overlap.width * overlap.height;
  }

  Offset _unitVector(Offset vector) {
    final length = vector.distance;
    if (length <= 0.001) return const Offset(0, -1);
    return Offset(vector.dx / length, vector.dy / length);
  }

  void _showEdgeDetailDialog(Word otherWord, WordRelationEdgeInfo info) {
    showDialog(
      context: context,
      builder: (context) {
        bool isEditing = false;
        bool isSaving = false;

        // 초기값(읽기용)
        String? selectedCategoryCode = info.categoryCode;
        String? selectedRelationType = info.relationType;
        // 'unspecified' 같은 표시용 값이 들어오면 드롭다운 value 규칙 위반이므로 null 처리
        if ((selectedCategoryCode ?? '').toLowerCase() == 'unspecified')
          selectedCategoryCode = null;
        if ((selectedRelationType ?? '').toLowerCase() == 'unspecified')
          selectedRelationType = null;

        final noteController = TextEditingController(text: info.note ?? '');
        final sourceController = TextEditingController(text: info.source ?? '');

        // 드롭다운 옵션(편집 눌렀을 때 로딩)
        List<Map<String, dynamic>> categories = [];
        List<Map<String, dynamic>> types = [];
        bool isOptionsLoading = false;

        bool hasChanges() {
          final note = noteController.text.trim();
          final src = sourceController.text.trim();

          final originalNote = (info.note ?? '').trim();
          final originalSrc = (info.source ?? '').trim();

          return selectedCategoryCode != info.categoryCode ||
              selectedRelationType != info.relationType ||
              note != originalNote ||
              src != originalSrc;
        }

        Future<void> loadOptionsIfNeeded(StateSetter setState) async {
          if (categories.isNotEmpty && types.isNotEmpty) return;

          setState(() => isOptionsLoading = true);
          try {
            final c = await _repository.getRelationCategories();
            final t = await _repository.getRelationTypes();
            setState(() {
              categories = c;
              types = t;
              isOptionsLoading = false;

              // 현재 선택값이 실제 items에 없으면 null로 보정(드롭다운 assert 방지)
              final categoryCodes = categories
                  .map((m) => (m['code'] as String?) ?? '')
                  .where((s) => s.isNotEmpty)
                  .toSet();
              final typeCodes = types
                  .map((m) => (m['code'] as String?) ?? '')
                  .where((s) => s.isNotEmpty)
                  .toSet();

              if (selectedCategoryCode != null &&
                  !categoryCodes.contains(selectedCategoryCode)) {
                selectedCategoryCode = null;
              }
              if (selectedRelationType != null &&
                  !typeCodes.contains(selectedRelationType)) {
                selectedRelationType = null;
              }
            });
          } catch (e) {
            setState(() => isOptionsLoading = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('코드표 로딩 실패: $e')));
          }
        }

        Future<void> save(StateSetter setState) async {
          if (!hasChanges()) return;

          setState(() => isSaving = true);
          try {
            await _repository.updateRelation(
              relationId: info.relationId,
              categoryCode: selectedCategoryCode,
              relationType: selectedRelationType,
              note: noteController.text.trim(),
              source: sourceController.text.trim(),
            );

            // 그래프 갱신(색/라벨/팝업 내용 반영)
            WordGraphDataCache.invalidateMany([_centerWord.id, otherWord.id]);
            await _loadConnectedWords();

            if (!mounted) return;
            Navigator.pop(context);

            ScaffoldMessenger.of(
              this.context,
            ).showSnackBar(const SnackBar(content: Text('관계가 저장되었습니다.')));
          } catch (e) {
            setState(() => isSaving = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
          }
        }

        Future<void> deleteEdge(StateSetter setState) async {
          setState(() => isSaving = true);

          try {
            await _repository.deleteRelation(info.relationId);

            // 그래프 갱신(엣지/라벨/색 반영)
            WordGraphDataCache.invalidateMany([_centerWord.id, otherWord.id]);
            await _loadConnectedWords();

            if (!mounted) return;
            Navigator.pop(context);

            ScaffoldMessenger.of(
              this.context,
            ).showSnackBar(const SnackBar(content: Text('관계가 삭제되었습니다.')));
          } catch (e) {
            setState(() => isSaving = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
          }
        }

        return StatefulBuilder(
          builder: (context, setState) {
            final categoryText =
                (info.categoryLabel?.trim().isNotEmpty ?? false)
                ? info.categoryLabel!.trim()
                : (info.categoryCode?.trim().isNotEmpty ?? false)
                ? info.categoryCode!.trim()
                : 'unspecified';

            final typeText =
                (info.relationTypeLabel?.trim().isNotEmpty ?? false)
                ? info.relationTypeLabel!.trim()
                : (info.relationType?.trim().isNotEmpty ?? false)
                ? info.relationType!.trim()
                : 'unspecified';

            final canSave = isEditing && !isSaving && hasChanges();

            return AlertDialog(
              title: Text('관계: ${otherWord.spelling1 ?? otherWord.id}'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 카테고리 ---
                      const Text(
                        '카테고리',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (!isEditing)
                        Text(categoryText)
                      else if (isOptionsLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: selectedCategoryCode,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('(없음)'),
                            ),
                            ...categories.map((m) {
                              final code = (m['code'] as String?) ?? '';
                              final label = (m['label'] as String?) ?? '';
                              final text = label.isNotEmpty
                                  ? '$label ($code)'
                                  : code;
                              return DropdownMenuItem<String>(
                                value: code,
                                child: Text(text),
                              );
                            }).toList(),
                          ],
                          onChanged: (v) =>
                              setState(() => selectedCategoryCode = v),
                        ),

                      const SizedBox(height: 14),

                      // --- 타입 ---
                      const Text(
                        '타입',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (!isEditing)
                        Text(typeText)
                      else if (isOptionsLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: selectedRelationType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('(없음)'),
                            ),
                            ...types.map((m) {
                              final code = (m['code'] as String?) ?? '';
                              final label = (m['label'] as String?) ?? '';
                              final text = label.isNotEmpty
                                  ? '$label ($code)'
                                  : code;
                              return DropdownMenuItem<String>(
                                value: code,
                                child: Text(text),
                              );
                            }).toList(),
                          ],
                          onChanged: (v) =>
                              setState(() => selectedRelationType = v),
                        ),

                      const SizedBox(height: 14),

                      // --- 노트 ---
                      const Text(
                        '노트',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: noteController,
                        enabled: isEditing && !isSaving,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '(없음)',
                        ),
                      ),

                      const SizedBox(height: 14),

                      // --- 소스 ---
                      const Text(
                        '소스',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: sourceController,
                        enabled: isEditing && !isSaving,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '(없음)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
                if (!isEditing)
                  TextButton(
                    onPressed: () async {
                      setState(() => isEditing = true);
                      await loadOptionsIfNeeded(setState);
                    },
                    child: const Text('편집'),
                  )
                else ...[
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            setState(() {
                              isEditing = false;
                              // 편집 취소 시 값을 원래대로 되돌리기
                              selectedCategoryCode = info.categoryCode;
                              selectedRelationType = info.relationType;
                              noteController.text = info.note ?? '';
                              sourceController.text = info.source ?? '';
                            });
                          },
                    child: const Text('취소'),
                  ),

                  // ✅ 삭제(편집 모드에서만, 확인 후 실행)
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('관계 삭제'),
                                content: const Text(
                                  '이 관계를 삭제할까요?\n이 작업은 되돌리기 어렵습니다.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('삭제'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await deleteEdge(setState);
                            }
                          },
                    child: const Text('삭제'),
                  ),

                  ElevatedButton(
                    onPressed: canSave ? () => save(setState) : null,
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('저장'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  /// 관계 카테고리 코드에 따른 색상 매핑
  /// - RELATION_CATEGORY.code 값 기준
  /// - WORD_RELATION에 code 테이블에 없는 값(예: unspecified)이 있을 수 있으므로 기본값을 둔다.
  Color _colorForCategory(String? categoryCode) {
    switch (categoryCode) {
      case 'semantic':
        return Colors.green;
      case 'lexical':
        return Colors.blue;
      case 'morphological':
        return Colors.orange;
      case 'etymological':
        return Colors.purple;
      case 'phonological':
        return Colors.teal;
      case 'transliteration':
        return Colors.brown;
      case 'translation':
        return Colors.indigo;

      // DB에 'unspecified'가 존재하지만 RELATION_CATEGORY엔 없어서 fallback 필요
      case 'unspecified':
        return Colors.grey;

      default:
        return Colors.grey;
    }
  }

  /// 엣지(관계) 라벨 텍스트 생성
  /// - 우선순위: relationTypeLabel(코드 테이블 라벨) > relationType(코드) > 빈 문자열
  /// - 내부적으로 코드/영문 라벨을 사람이 읽기 좋은 짧은 라벨로 정리한다.
  String _labelForEdge(WordRelationEdgeInfo? info) {
    final raw = (info?.relationTypeLabel?.trim().isNotEmpty ?? false)
        ? info!.relationTypeLabel!.trim()
        : (info?.relationType ?? '').trim();

    if (raw.isEmpty) return '';

    final normalized = _normalizeRelationLabel(raw);

    // 너무 길면 잘라서 표시(가독성)
    const maxLen = 10; // 태그가 잘린다고 했으니 여기서 조금 더 짧게
    if (normalized.length <= maxLen) return normalized;
    return '${normalized.substring(0, maxLen)}…';
  }

  /// 관계 라벨 정리
  /// - DB에 코드 테이블에 없는 값이 들어올 수 있어(예: unspecified, related, root-related)
  /// - 그래프 태그는 짧고 명확해야 하므로 사용자 친화 라벨로 바꾼다.
  String _normalizeRelationLabel(String raw) {
    final v = raw.trim();

    // 이미 한글이면 그대로 사용(불필요 변환 방지)
    final hasKorean = RegExp(r'[가-힣]').hasMatch(v);
    if (hasKorean) return v;

    switch (v) {
      case 'unspecified':
        return '미분류';
      case 'related':
        return '관련';
      case 'root-related':
        return '어근관련';
      case 'synonym':
        return '동의어';
      case 'antonym':
        return '반의어';
      default:
        // 기타 영문 라벨/코드는 보기 좋게 정리
        return v.replaceAll('-', ' ');
    }
  }

  /// 마우스 휠(스크롤)로 마우스 위치를 기준으로 확대/축소한다.
  /// - Windows 데스크탑에서 "마우스 중심 줌"을 구현하기 위함.
  void _handlePointerScroll(PointerScrollEvent event) {
    // 휠 아래로: 확대, 위로: 축소(감각은 취향이지만 이게 일반적)
    final scrollDelta = event.scrollDelta.dy;

    // 스케일 변화량(너무 크지 않게)
    final scaleFactor = (scrollDelta > 0) ? 0.92 : 1.08;

    final matrix = _transformController.value;

    // 현재 스케일
    final currentScale = matrix.getMaxScaleOnAxis();
    final nextScale = (currentScale * scaleFactor).clamp(0.6, 3.5);

    // 실제 적용될 비율
    final effective = nextScale / currentScale;

    // 마우스 위치(로컬 좌표) 기준으로 줌
    final focalPoint = event.localPosition;

    final next = Matrix4.identity()
      ..translate(focalPoint.dx, focalPoint.dy)
      ..scale(effective)
      ..translate(-focalPoint.dx, -focalPoint.dy)
      ..multiply(matrix);

    _transformController.value = next;

    // 줌 값 갱신(태그 표시/숨김을 위해)
    if (nextScale != _currentScale) {
      setState(() => _currentScale = nextScale);
    }
  }

  /// [단어 추가] 전체 흐름
  /// 1) 단어 입력
  /// 2) 중복 후보 경고
  /// 3) 단어 저장
  /// 4) (옵션) 현재 중심 단어와 관계 추가
  /// 5) 그래프 갱신
  Future<void> _showCreateWordFlow() async {
    final payload = await _showCreateWordDialog();
    if (payload == null) return;

    final duplicates = await _repository.findDuplicateCandidates(
      language: payload.language,
      strongNumber: payload.strongNumber,
      spelling1: payload.spelling1,
    );

    if (duplicates.isNotEmpty) {
      final shouldContinue = await _showDuplicateWarningDialog(
        language: payload.language,
        strongNumber: payload.strongNumber,
        spelling1: payload.spelling1,
        candidates: duplicates,
      );

      if (shouldContinue != true) return;
    }

    final newId = await _repository.generateNextWordId(
      language: payload.language,
      strongNumber: payload.strongNumber,
    );

    await _repository.createWord(
      id: newId,
      language: payload.language,
      strongNumber: payload.strongNumber,
      spelling1: payload.spelling1,
      pronunciation1: payload.pronunciation1,
      meaning1: payload.meaning1,
      note: payload.note,
    );

    final createdWord = await _repository.getWordById(newId);
    bool didCreateRelation = false;

    // 저장 후 관계 추가 옵션
    if (payload.createRelationAfterSave) {
      if (createdWord != null) {
        final relationPayload = await _showCreateRelationDialog(createdWord);

        if (relationPayload != null) {
          final existing = await _repository.findExistingRelationId(
            _centerWord.id,
            createdWord.id,
          );

          if (existing == null) {
            await _repository.createRelation(
              wordId1: _centerWord.id,
              wordId2: createdWord.id,
              categoryCode: relationPayload.categoryCode,
              relationType: relationPayload.relationType,
              note: relationPayload.note,
              source: relationPayload.source,
            );
            didCreateRelation = true;
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('이미 관계가 존재합니다.')));
          }
        }
      }

      if (didCreateRelation && createdWord != null) {
        WordGraphDataCache.invalidateMany([_centerWord.id, createdWord.id]);
      }

      await _loadConnectedWords();

      if (!mounted) return;
      setState(() => _selectedWordId = newId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('단어가 추가되었습니다: $newId')));
      return;
    }

    // 관계를 만들지 않은 경우:
    // 새로 만든 단어를 중심으로 하는 그래프 화면으로 즉시 전환
    if (!mounted) return;

    if (createdWord != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WordGraphScreen(centerWord: createdWord),
        ),
      );
      return;
    }

    // 혹시 단어 조회가 실패하면, 현재 화면만 갱신하고 알림
    await _loadConnectedWords();

    if (!mounted) return;
    setState(() => _selectedWordId = newId);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('단어가 추가되었습니다: $newId')));
  }

  /// 신규 단어 생성 다이얼로그
  Future<CreateWordPayload?> _showCreateWordDialog() async {
    final strongController = TextEditingController();
    final spellingController = TextEditingController();
    final pronunciationController = TextEditingController();
    final meaningController = TextEditingController();
    final noteController = TextEditingController();

    String selectedLanguageGroup = '헬라어';
    final customLanguageController = TextEditingController();
    bool createRelationAfterSave = false;

    const languages = ['히브리어/아람어', '헬라어', '라틴어', '영어', '기타'];

    return showDialog<CreateWordPayload?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('신규 단어 생성'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedLanguageGroup,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: '언어 그룹'),
                        items: languages
                            .map(
                              (lang) => DropdownMenuItem<String>(
                                value: lang,
                                child: Text(lang),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              selectedLanguageGroup = v;
                              if (v != '히브리어/아람어' && v != '기타') {
                                customLanguageController.clear();
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (selectedLanguageGroup == '히브리어/아람어' ||
                          selectedLanguageGroup == '기타') ...[
                        TextField(
                          controller: customLanguageController,
                          decoration: InputDecoration(
                            labelText: selectedLanguageGroup == '히브리어/아람어'
                                ? '실제 언어명 (예: 히브리어, 아람어)'
                                : '실제 언어명 입력',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: strongController,
                        decoration: const InputDecoration(
                          labelText: '스트롱넘버 (없으면 비워둠)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: spellingController,
                        decoration: const InputDecoration(labelText: '표기1'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pronunciationController,
                        decoration: const InputDecoration(labelText: '발음1'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: meaningController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: '의미1'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: '비고'),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: createRelationAfterSave,
                        onChanged: (v) => setState(
                          () => createRelationAfterSave = v ?? false,
                        ),
                        title: const Text('저장 후 현재 중심 단어와 관계 추가'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final spelling = spellingController.text.trim();
                    if (spelling.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('표기1은 필수입니다.')),
                      );
                      return;
                    }

                    String resolvedLanguage;
                    if (selectedLanguageGroup == '히브리어/아람어' ||
                        selectedLanguageGroup == '기타') {
                      resolvedLanguage = customLanguageController.text.trim();
                      if (resolvedLanguage.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('실제 언어명을 입력해주세요.')),
                        );
                        return;
                      }
                    } else {
                      resolvedLanguage = selectedLanguageGroup;
                    }

                    Navigator.pop(
                      context,
                      CreateWordPayload(
                        language: resolvedLanguage,
                        strongNumber: strongController.text.trim().isEmpty
                            ? null
                            : strongController.text.trim().toUpperCase(),
                        spelling1: spelling,
                        pronunciation1:
                            pronunciationController.text.trim().isEmpty
                            ? null
                            : pronunciationController.text.trim(),
                        meaning1: meaningController.text.trim().isEmpty
                            ? null
                            : meaningController.text.trim(),
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                        createRelationAfterSave: createRelationAfterSave,
                      ),
                    );
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 중복 후보 경고 다이얼로그
  Future<bool?> _showDuplicateWarningDialog({
    required String language,
    String? strongNumber,
    required String spelling1,
    required List<Map<String, dynamic>> candidates,
  }) async {
    final isStrongCase = (strongNumber ?? '').trim().isNotEmpty;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('중복 가능성 경고'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isStrongCase
                        ? '같은 스트롱넘버를 가진 기존 단어가 있습니다.'
                        : '같은 언어/표기1을 가진 기존 단어가 있습니다.',
                  ),
                  const SizedBox(height: 12),
                  ...candidates.map((c) {
                    final id = (c['id'] ?? '').toString();
                    final lang = (c['언어'] ?? '').toString();
                    final strong = (c['스트롱넘버'] ?? '').toString();
                    final spelling = (c['표기1'] ?? '').toString();
                    final meaning = (c['의미1'] ?? '').toString();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'id: $id\n언어: $lang\n스트롱: $strong\n표기1: $spelling\n의미1: $meaning',
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('계속 추가'),
            ),
          ],
        );
      },
    );
  }

  /// 새로 만든 단어와 현재 중심 단어 사이의 관계 생성 정보 입력
  Future<CreateRelationPayload?> _showCreateRelationDialog(Word other) async {
    final categories = await _repository.getRelationCategories();
    final types = await _repository.getRelationTypes();

    String? selectedCategoryCode;
    String? selectedRelationType;
    final noteController = TextEditingController();
    final sourceController = TextEditingController();

    return showDialog<CreateRelationPayload?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('관계 추가: ${other.spelling1 ?? other.id}'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategoryCode,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '카테고리'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('없음'),
                        ),
                        ...categories.map((c) {
                          final code = c['code'] as String;
                          final label = (c['label'] as String?) ?? code;
                          return DropdownMenuItem<String>(
                            value: code,
                            child: Text('$label ($code)'),
                          );
                        }),
                      ],
                      onChanged: (v) =>
                          setState(() => selectedCategoryCode = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRelationType,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '타입'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('없음'),
                        ),
                        ...types.map((t) {
                          final code = t['code'] as String;
                          final label = (t['label'] as String?) ?? code;
                          return DropdownMenuItem<String>(
                            value: code,
                            child: Text('$label ($code)'),
                          );
                        }),
                      ],
                      onChanged: (v) =>
                          setState(() => selectedRelationType = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(labelText: '노트'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sourceController,
                      decoration: const InputDecoration(labelText: '소스'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      CreateRelationPayload(
                        categoryCode: selectedCategoryCode,
                        relationType: selectedRelationType,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                        source: sourceController.text.trim().isEmpty
                            ? null
                            : sourceController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 현재 그래프(중심 노드 + 연결 노드들)가 화면에 잘 들어오도록 자동으로 줌/팬을 맞춘다.
  void _fitToView(_GraphLayoutData layout) {
    // 노드 배치 반지름(현재 GraphLinePainter와 _buildWordNodes에서 쓰는 값과 맞춰야 함)
    final bounds = layout.fitBounds;

    // 중심 노드/주변 노드 크기(현재 위젯 크기와 맞춰야 함)
    final bboxW = max(bounds.width, 1.0);
    final bboxH = max(bounds.height, 1.0);

    // 여백(태그/선 고려)

    // 스케일 계산
    final sx = layout.canvasSize.width / bboxW;
    final sy = layout.canvasSize.height / bboxH;
    final scale = min(sx, sy).clamp(0.6, 3.5);

    // 바운딩 박스 중심
    final bboxCenter = bounds.center;

    // bbox 중심이 화면 중앙에 오도록 변환 설정
    final m = Matrix4.identity()
      ..translate(layout.canvasSize.width / 2, layout.canvasSize.height / 2)
      ..scale(scale)
      ..translate(-bboxCenter.dx, -bboxCenter.dy);

    _transformController.value = m;
    setState(() => _currentScale = scale);
  }

  /// [관계 추가] 전체 흐름
  /// 1) 상대 단어 검색/선택
  /// 2) 관계 정보(카테고리/타입/노트/소스) 입력
  /// 3) 중복 관계 검사 후 INSERT
  /// 4) 그래프 갱신
  Future<void> _showAddRelationFlow() async {
    // 1) 상대 단어 선택
    final other = await _showSelectWordDialog();
    if (other == null) return;

    // 자기 자신 선택 방지
    if (other.id == _centerWord.id) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('자기 자신과의 관계는 추가할 수 없습니다.')));
      return;
    }

    // 2) 관계 입력
    final payload = await _showCreateRelationDialog(other);
    if (payload == null) return;

    // 3) 중복 검사
    final existingId = await _repository.findExistingRelationId(
      _centerWord.id,
      other.id,
    );

    if (existingId != null) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('이미 존재하는 관계'),
          content: const Text('이 두 단어 사이의 관계가 이미 DB에 존재합니다.\n중복 생성은 막았습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    // 4) INSERT
    await _repository.createRelation(
      wordId1: _centerWord.id,
      wordId2: other.id,
      categoryCode: payload.categoryCode,
      relationType: payload.relationType,
      note: payload.note,
      source: payload.source,
    );

    // 5) 갱신
    WordGraphDataCache.invalidateMany([_centerWord.id, other.id]);
    await _loadConnectedWords();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('관계를 추가했습니다.')));
  }

  /// 상대 단어를 검색해서 고르는 다이얼로그
  Future<Word?> _showSelectWordDialog() async {
    final controller = TextEditingController();
    List<Word> results = [];

    return showDialog<Word?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> doSearch(String q) async {
              final r = await _repository.searchWords(q, limit: 200);
              // 중심 단어는 결과에서 제외(혼동 방지)
              final filtered = r.where((w) => w.id != _centerWord.id).toList();
              setState(() => results = filtered);
            }

            return AlertDialog(
              title: const Text('관계 추가: 상대 단어 선택'),
              content: SizedBox(
                width: 520,
                height: 520,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: '검색 (표기/의미/스트롱넘버)',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) {
                        // 너무 잦은 쿼리를 피하려면 debounce가 좋지만,
                        // 지금은 단순 onChanged로 시작(안정 우선)
                        if (v.trim().length >= 2) {
                          doSearch(v);
                        } else {
                          setState(() => results = []);
                        }
                      },
                      onSubmitted: (v) => doSearch(v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: results.isEmpty
                          ? const Center(child: Text('검색어를 입력하세요.'))
                          : ListView.separated(
                              itemCount: results.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final w = results[i];
                                return ListTile(
                                  title: Text(w.spelling1 ?? w.id),
                                  subtitle: Text(
                                    [
                                      if ((w.meaning1 ?? '').trim().isNotEmpty)
                                        w.meaning1!,
                                      if ((w.strongNumber ?? '')
                                          .trim()
                                          .isNotEmpty)
                                        '스트롱: ${w.strongNumber}',
                                    ].join(' / '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => Navigator.pop(context, w),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// 연결선(엣지) 렌더러
class LegacyGraphLinePainter extends CustomPainter {
  final double centerX;
  final double centerY;

  final List<Color> edgeColors;
  final List<String> edgeLabels;

  /// 줌 레벨에 따라 라벨 표시/숨김
  final bool showLabels;

  /// 현재 씬(그래프) 줌 배율
  /// - 태그 텍스트/패딩을 1/scale로 보정하여 “거의 고정 크기”처럼 보이게 한다.
  final double sceneScale;

  /// 선택된 연결 노드 인덱스(없으면 null)
  final int? selectedIndex;

  LegacyGraphLinePainter(
    this.centerX,
    this.centerY,
    this.edgeColors,
    this.edgeLabels, {
    required this.showLabels,
    required this.sceneScale,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double radius = 160;
    final center = Offset(centerX, centerY);

    final nodeCount = edgeColors.length;
    if (nodeCount == 0) return;

    for (int i = 0; i < nodeCount; i++) {
      final angle = (2 * pi / nodeCount) * i;

      final dx = centerX + radius * cos(angle);
      final dy = centerY + radius * sin(angle);

      final bool hasSelection = (selectedIndex != null);
      final bool isSelectedEdge = (selectedIndex == i);

      final paint = Paint()
        ..color = hasSelection && !isSelectedEdge
            ? edgeColors[i].withOpacity(0.35)
            : edgeColors[i]
        ..strokeWidth = isSelectedEdge ? 4.0 : 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(center, Offset(dx, dy), paint);

      // 라벨(관계 타입) 태그 표시: 선 중간 근처(약간 중심 쪽)
      final label = (i < edgeLabels.length) ? edgeLabels[i] : '';
      if (showLabels && label.isNotEmpty) {
        // 중심 -> 주변 노드 방향 벡터
        final vx = dx - center.dx;
        final vy = dy - center.dy;

        // 태그는 선의 "중간"이 아니라, 중심에서 더 멀리(주변 노드 쪽) 배치한다.
        // t가 클수록 주변 노드에 가까워진다. (0.5 = 중간)
        const t = 0.68;

        // 태그 기준점(중앙에서 멀어진 지점)
        final anchor = Offset(center.dx + vx * t, center.dy + vy * t);

        // 선 벡터의 수직 방향으로 약간 이동(선/태그 겹침 완화)
        final len = sqrt(vx * vx + vy * vy);
        final nx = (len == 0) ? 0.0 : -vy / len; // 수직 단위벡터 x
        final ny = (len == 0) ? 0.0 : vx / len; // 수직 단위벡터 y

        final scale = sceneScale <= 0 ? 1.0 : sceneScale;
        // 줌과 관계없이 적당한 오프셋(역스케일) 유지
        final offset = (12.0 / scale).clamp(6.0, 14.0);

        final shifted = Offset(
          anchor.dx + nx * offset,
          anchor.dy + ny * offset,
        );

        _drawEdgeLabel(canvas, shifted, label, edgeColors[i]);
      }
    }
  }

  void _drawEdgeLabel(Canvas canvas, Offset pos, String text, Color edgeColor) {
    final scale = sceneScale <= 0 ? 1.0 : sceneScale;
    final fontSize = (11.0 / scale).clamp(9.0, 12.0);
    final padX = (6.0 / scale).clamp(4.0, 7.0);
    final padY = (3.0 / scale).clamp(2.0, 4.0);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout();

    final rect = Rect.fromCenter(
      center: pos,
      width: textPainter.width + padX * 2,
      height: textPainter.height + padY * 2,
    );

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    final bgPaint = Paint()..color = Colors.white.withOpacity(0.92);
    final borderPaint = Paint()
      ..color = edgeColor.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // 텍스트는 중앙 배치
    final textOffset = Offset(rect.left + padX, rect.top + padY);
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant LegacyGraphLinePainter oldDelegate) {
    // node 수나 색상이 변하면 다시 그리기
    return oldDelegate.edgeColors.length != edgeColors.length ||
        oldDelegate.edgeColors != edgeColors ||
        oldDelegate.edgeLabels.length != edgeLabels.length ||
        oldDelegate.edgeLabels != edgeLabels ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class GraphLinePainter extends CustomPainter {
  final _GraphLayoutData layout;
  final List<Color> edgeColors;
  final List<String> edgeLabels;
  final bool showLabels;
  final double sceneScale;
  final int? selectedIndex;

  GraphLinePainter({
    required this.layout,
    required this.edgeColors,
    required this.edgeLabels,
    required this.showLabels,
    required this.sceneScale,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.nodeLayouts.isEmpty) return;

    for (final nodeLayout in layout.nodeLayouts) {
      final index = nodeLayout.index;
      final bool hasSelection = selectedIndex != null;
      final bool isSelectedEdge = selectedIndex == index;
      final double strokeWidth = hasSelection
          ? isSelectedEdge
              ? _selectedEdgeStrokeWidth
              : _mutedEdgeStrokeWidth
          : _defaultEdgeStrokeWidth;
      final Color strokeColor = hasSelection && !isSelectedEdge
          ? edgeColors[index].withValues(alpha: _mutedEdgeOpacity)
          : edgeColors[index];

      final paint = Paint()
        ..color = strokeColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(layout.center, nodeLayout.center, paint);

      final label = (index < edgeLabels.length) ? edgeLabels[index] : '';
      if (showLabels && label.isNotEmpty) {
        _drawEdgeLabel(
          canvas,
          nodeLayout.labelCenter(sceneScale),
          label,
          edgeColors[index],
        );
      }
    }
  }

  void _drawEdgeLabel(Canvas canvas, Offset pos, String text, Color edgeColor) {
    final scale = sceneScale <= 0 ? 1.0 : sceneScale;
    final fontSize = (11.0 / scale).clamp(9.0, 12.0);
    final padX = (6.0 / scale).clamp(4.0, 7.0);
    final padY = (3.0 / scale).clamp(2.0, 4.0);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout();

    final rect = Rect.fromCenter(
      center: pos,
      width: textPainter.width + padX * 2,
      height: textPainter.height + padY * 2,
    );

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    final bgPaint = Paint()..color = Colors.white.withOpacity(0.92);
    final borderPaint = Paint()
      ..color = edgeColor.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    final textOffset = Offset(rect.left + padX, rect.top + padY);
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant GraphLinePainter oldDelegate) {
    return oldDelegate.layout.contentBounds != layout.contentBounds ||
        oldDelegate.layout.ringRadii.length != layout.ringRadii.length ||
        oldDelegate.edgeColors.length != edgeColors.length ||
        oldDelegate.edgeColors != edgeColors ||
        oldDelegate.edgeLabels.length != edgeLabels.length ||
        oldDelegate.edgeLabels != edgeLabels ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.sceneScale != sceneScale ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
