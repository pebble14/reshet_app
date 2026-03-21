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
const double _centerNodeBorderWidth = 4.6;
const double _centerNodeHaloBlur = 16.0;
const double _centerNodeHaloSpread = 1.8;
const double _centerNodeMainShadowBlur = 20.0;
const double _centerNodeMainShadowSpread = 1.1;
const double _centerNodeMainShadowOffsetY = 5.5;
const double _connectedNodeDefaultBorderWidth = 2.0;
const double _connectedNodeSelectedBorderWidth = 4.0;
const double _connectedNodeMutedBorderWidth = 1.6;
const double _selectedEdgeStrokeWidth = 3.4;
const double _defaultEdgeStrokeWidth = 2.0;
const double _mutedEdgeStrokeWidth = 1.8;
const double _connectedEdgeOpacity = 0.80;
const double _mutedEdgeOpacity = 0.40;
const double _defaultEdgeLabelBorderWidth = 1.5;
const double _selectedEdgeLabelBorderWidth = 1.8;
const double _defaultEdgeLabelBorderOpacity = 0.9;
const double _mutedEdgeLabelBorderOpacity = 0.72;
const double _centerNodeLanguageTintFactor = 0.08;
const double _connectedNodeLanguageTintAlpha = 0.22;
const double _selectedNodeLanguageTintAlpha = 0.26;
const double _mutedNodeLanguageTintAlpha = 0.14;
const String _languageGroupHebrewAramaic = 'hebrew_aramaic';
const String _languageGroupGreek = 'greek';
const String _languageGroupLatin = 'latin';
const String _languageGroupEnglish = 'english';
const String _languageGroupOther = 'other';
const String _languageGroupFallback = 'fallback';
const Color _languageGroupHebrewAramaicColor = Color(0xFFFFD700);
const Color _languageGroupGreekColor = Color(0xFF4AC7D4);
const Color _languageGroupLatinColor = Color(0xFF9F0807);
const Color _languageGroupEnglishColor = Color(0xFF8B5FD3);
const Color _languageGroupOtherColor = Color(0xFF9CA3AF);
const Color _languageGroupFallbackColor = Color(0xFFC0C0C0);
const Duration _visualStateAnimationDuration = Duration(milliseconds: 150);
const double _dimmedNodeOpacity = 0.54;
const double _dimmedNodeTextOpacity = 0.75;
const double _connectedCenterOpacity = 0.94;
const double _connectedEdgeLabelOpacity = 0.80;
const double _dimmedEdgeLabelOpacity = 0.40;
const double _selectedEdgeLabelTintAlpha = 0.18;
const double _connectedEdgeLabelTintAlpha = 0.06;
const double _dimmedEdgeLabelTintAlpha = 0.03;
const double _dashedEdgeDashLength = 14.0;
const double _dashedEdgeGapLength = 9.0;
const double _dottedEdgeDotLength = 1.0;
const double _dottedEdgeGapLength = 7.0;
const int _graphOutgoingLimit = 12;

enum _GraphVisualState { selected, connected, dimmed }

enum _GraphEdgeSemanticStyle { solid, dashed, dotted }

enum _GraphEdgeDirectionSummary {
  outgoing,
  incoming,
  undirected,
  unknown,
  mixed,
}

_GraphEdgeSemanticStyle _edgeSemanticStyleForRelationType(
  String? relationType,
) {
  final normalized = (relationType ?? '').trim().toLowerCase();

  switch (normalized) {
    case 'semantic':
      return _GraphEdgeSemanticStyle.dashed;
    case 'related':
    case 'root-related':
      return _GraphEdgeSemanticStyle.dotted;
    default:
      return _GraphEdgeSemanticStyle.solid;
  }
}

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
  final String directionCode;
  final String? description;
  final String? relationGroupId;
  final String? note;
  final String? source;

  CreateRelationPayload({
    required this.categoryCode,
    required this.relationType,
    required this.directionCode,
    required this.description,
    required this.relationGroupId,
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
  final String? selectedWordId;
  final List<Widget> appBarActionPrefix;
  final ValueChanged<Word>? onSelectWord;

  /// 스플릿뷰에서 이미 선택된 노드를 다시 클릭했을 때
  /// 부모가 중심 단어를 바꾸도록 알린다.
  final ValueChanged<Word>? onChangeCenterWord;

  const WordGraphScreen({
    super.key,
    required this.centerWord,
    this.selectedWordId,
    this.appBarActionPrefix = const [],
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

  late Word _centerWord;

  bool _isLoading = true;
  String? _errorMessage;

  /// 중심 단어와 연결된 단어 목록
  List<Word> _connectedWords = [];

  /// 사용자가 클릭(선택)한 주변 노드 id
  /// - 같은 노드를 다시 클릭하면 이동(push)하는 트리거로 사용
  String? _selectedWordId;

  /// 상대 단어 id 기준으로 관계(엣지) 메타를 보관한다.
  /// - 여러 관계가 있을 수 있으나, 현재는 “표시용 1개”만 선택(마지막으로 덮어씀)
  final Map<String, List<WordRelationEdgeInfo>> _edgeInfosByOtherId = {};
  final Map<String, WordRelationEdgeInfo> _primaryEdgeInfoByOtherId = {};

  String _normalizedGraphExpandMode(String? graphExpandMode) {
    switch ((graphExpandMode ?? '').trim().toLowerCase()) {
      case 'incoming_only':
        return 'incoming_only';
      case 'outgoing_limited':
        return 'outgoing_limited';
      case 'full':
        return 'full';
      default:
        return 'default';
    }
  }

  String? _nullIfBlank(String? value) {
    final trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  void initState() {
    super.initState();
    _centerWord = widget.centerWord;
    _selectedWordId = widget.selectedWordId;
    final cachedGraph = WordGraphDataCache.get(
      centerWordId: _centerWord.id,
      graphExpandMode: _centerWord.graphExpandMode,
    );
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
  void didUpdateWidget(covariant WordGraphScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final didCenterWordChange = widget.centerWord.id != oldWidget.centerWord.id;
    final didGraphExpandModeChange =
        widget.centerWord.id == oldWidget.centerWord.id &&
        _normalizedGraphExpandMode(widget.centerWord.graphExpandMode) !=
            _normalizedGraphExpandMode(oldWidget.centerWord.graphExpandMode);

    if (didCenterWordChange) {
      setState(() {
        _centerWord = widget.centerWord;
        _selectedWordId = widget.selectedWordId;
        _isLoading = true;
        _errorMessage = null;
      });
      _loadConnectedWords();
      return;
    }

    if (didGraphExpandModeChange) {
      setState(() {
        _centerWord = widget.centerWord;
        _selectedWordId = widget.selectedWordId;
        _isLoading = true;
        _errorMessage = null;
      });
      _loadConnectedWords();
      return;
    }

    if (widget.selectedWordId != oldWidget.selectedWordId) {
      setState(() {
        _selectedWordId = widget.selectedWordId;
      });
    }
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

    _edgeInfosByOtherId.clear();
    _primaryEdgeInfoByOtherId.clear();
    for (final e in edges) {
      _edgeInfosByOtherId
          .putIfAbsent(e.otherWordId, () => <WordRelationEdgeInfo>[])
          .add(e);
    }

    for (final entry in _edgeInfosByOtherId.entries) {
      if (entry.value.isNotEmpty) {
        _primaryEdgeInfoByOtherId[entry.key] = entry.value.first;
      }
    }

    _errorMessage = null;
    _isLoading = false;
  }

  Future<void> _loadConnectedWords() async {
    final cachedGraph = WordGraphDataCache.get(
      centerWordId: _centerWord.id,
      graphExpandMode: _centerWord.graphExpandMode,
    );
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
      final results = await Future.wait([
        _repository.getVisibleConnectedWordsForGraph(
          _centerWord.id,
          outgoingLimit: _graphOutgoingLimit,
        ),
        _repository.getVisibleRelationEdgesForGraph(
          _centerWord.id,
          outgoingLimit: _graphOutgoingLimit,
        ),
      ]);
      final words = results[0] as List<Word>;
      final edges = results[1] as List<WordRelationEdgeInfo>;
      WordGraphDataCache.put(
        centerWordId: _centerWord.id,
        graphExpandMode: _centerWord.graphExpandMode,
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
        appBar: _buildAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 에러
    if (_errorMessage != null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        final nodes = _connectedWords;
        final layout = _computeGraphLayout(canvasSize, nodes.length);

        // 노드 배치 순서와 동일한 순서로 엣지 색상/라벨 생성
        final edgeInfoGroups = nodes
            .map((word) => _edgeInfosForOtherWord(word.id))
            .toList(growable: false);
        final edgeInfos = nodes
            .map((word) => _primaryEdgeInfoForOtherWord(word.id))
            .toList(growable: false);
        final edgeColors = edgeInfos
            .map((info) => _colorForCategory(info?.categoryCode))
            .toList(growable: false);
        final edgeLabels = edgeInfoGroups
            .map((infos) => _labelForEdgeGroup(infos))
            .toList(growable: false);
        final edgeRelationTypes = edgeInfos
            .map((info) => info?.relationType)
            .toList(growable: false);
        final edgeDirectionSummaries = edgeInfoGroups
            .map((infos) => _directionSummaryForEdges(infos))
            .toList(growable: false);

        // 선택된 노드가 연결 노드 목록에서 몇 번째인지(없으면 null)
        final int selectedIndexRaw = nodes.indexWhere(
          (w) => w.id == _selectedWordId,
        );
        final int? selectedIndex = (selectedIndexRaw >= 0)
            ? selectedIndexRaw
            : null;
        final centerVisualState = _centerVisualState(selectedIndex);

        return Scaffold(
          appBar: _buildAppBar(
            title: const Text('단어 그래프'),
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
                      AnimatedSwitcher(
                        duration: _visualStateAnimationDuration,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        child: SizedBox(
                          key: ValueKey<int?>(selectedIndex),
                          width: canvasSize.width,
                          height: canvasSize.height,
                          child: CustomPaint(
                            size: canvasSize,
                            painter: _GraphLinePainter(
                              layout: layout,
                              edgeColors: edgeColors,
                              edgeLabels: edgeLabels,
                              edgeRelationTypes: edgeRelationTypes,
                              edgeDirectionSummaries: edgeDirectionSummaries,
                              showLabels: false,
                              sceneScale: _currentScale,
                              selectedIndex: selectedIndex,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: layout.centerBounds.left,
                      top: layout.centerBounds.top,
                      child: _buildCenterNode(
                        _centerWord,
                        visualState: centerVisualState,
                      ),
                    ),
                    ..._buildEdgeLabelWidgets(
                      layout,
                      nodes,
                      edgeInfoGroups,
                      edgeLabels,
                      edgeColors,
                      selectedIndex: selectedIndex,
                    ),

                    ..._buildWordNodes(
                      layout,
                      nodes,
                      selectedIndex: selectedIndex,
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
  PreferredSizeWidget _buildAppBar({Widget? title, List<Widget>? actions}) {
    final mergedActions = <Widget>[...widget.appBarActionPrefix, ...?actions];

    return AppBar(
      title: title ?? const Text('단어 그래프'),
      actions: mergedActions.isEmpty ? null : mergedActions,
    );
  }

  Color _blendColor(Color color, Color target, double amount) {
    return Color.lerp(color, target, amount) ?? color;
  }

  Color _surfaceTint(Color baseColor, double alpha) {
    return Color.alphaBlend(baseColor.withValues(alpha: alpha), Colors.white);
  }

  String _wordIdPrefix(String wordId) {
    final normalized = wordId.trim().toUpperCase();
    if (normalized.isEmpty) return '';
    return normalized.substring(0, 1);
  }

  String _languageGroupFromWordId(String wordId) {
    switch (_wordIdPrefix(wordId)) {
      case 'H':
        return _languageGroupHebrewAramaic;
      case 'G':
        return _languageGroupGreek;
      case 'L':
        return _languageGroupLatin;
      case 'E':
        return _languageGroupEnglish;
      case 'U':
        return _languageGroupOther;
      default:
        return _languageGroupFallback;
    }
  }

  Color _colorForLanguageGroup(String languageGroup) {
    switch (languageGroup) {
      case _languageGroupHebrewAramaic:
        return _languageGroupHebrewAramaicColor;
      case _languageGroupGreek:
        return _languageGroupGreekColor;
      case _languageGroupLatin:
        return _languageGroupLatinColor;
      case _languageGroupEnglish:
        return _languageGroupEnglishColor;
      case _languageGroupOther:
        return _languageGroupOtherColor;
      default:
        return _languageGroupFallbackColor;
    }
  }

  Color _colorForWordLanguageGroup(String wordId) {
    return _colorForLanguageGroup(_languageGroupFromWordId(wordId));
  }

  _GraphVisualState _centerVisualState(int? selectedIndex) {
    return selectedIndex == null
        ? _GraphVisualState.selected
        : _GraphVisualState.connected;
  }

  _GraphVisualState _connectedNodeVisualState({
    required int nodeIndex,
    required int? selectedIndex,
  }) {
    if (selectedIndex == null) {
      return _GraphVisualState.connected;
    }

    return selectedIndex == nodeIndex
        ? _GraphVisualState.selected
        : _GraphVisualState.dimmed;
  }

  double _nodeOpacityForState(
    _GraphVisualState visualState, {
    required bool isCenter,
  }) {
    switch (visualState) {
      case _GraphVisualState.selected:
        return 1.0;
      case _GraphVisualState.connected:
        return isCenter ? _connectedCenterOpacity : 1.0;
      case _GraphVisualState.dimmed:
        return _dimmedNodeOpacity;
    }
  }

  double _nodeTextOpacityForState(_GraphVisualState visualState) {
    switch (visualState) {
      case _GraphVisualState.selected:
      case _GraphVisualState.connected:
        return 1.0;
      case _GraphVisualState.dimmed:
        return _dimmedNodeTextOpacity;
    }
  }

  Widget _buildCenterNode(Word word, {required _GraphVisualState visualState}) {
    final language = (word.language ?? '').trim();
    final strongNumber = (word.strongNumber ?? '').trim();
    final spelling = (word.spelling1 ?? '').trim();
    final pronunciation = (word.pronunciation1 ?? '').trim();
    final transliteration = (word.transliteration1 ?? '').trim();
    final meaning = (word.meaning1 ?? '').trim();
    final languageTintColor = _colorForWordLanguageGroup(word.id);
    final centerInnerColor = _surfaceTint(
      languageTintColor,
      _centerNodeLanguageTintFactor * 0.8,
    );
    final centerMidColor = _surfaceTint(
      languageTintColor,
      _centerNodeLanguageTintFactor * 0.92,
    );
    final centerOuterColor = _surfaceTint(
      languageTintColor,
      _centerNodeLanguageTintFactor,
    );
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

    final bool isSelected = visualState == _GraphVisualState.selected;
    final backgroundOpacity = _nodeOpacityForState(visualState, isCenter: true);
    final textOpacity = _nodeTextOpacityForState(visualState);
    final List<BoxShadow> boxShadows = isSelected
        ? [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.27),
              blurRadius: _centerNodeHaloBlur,
              spreadRadius: _centerNodeHaloSpread,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: _centerNodeMainShadowBlur,
              spreadRadius: _centerNodeMainShadowSpread,
              offset: const Offset(0, _centerNodeMainShadowOffsetY),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 14,
              spreadRadius: 0.6,
              offset: const Offset(0, 4),
            ),
          ];

    return SizedBox(
      width: _centerNodeSize,
      height: _centerNodeSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            duration: _visualStateAnimationDuration,
            curve: Curves.easeOutCubic,
            opacity: backgroundOpacity,
            child: AnimatedContainer(
              duration: _visualStateAnimationDuration,
              curve: Curves.easeOutCubic,
              width: _centerNodeSize,
              height: _centerNodeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [centerInnerColor, centerMidColor, centerOuterColor],
                  stops: const [0.0, 0.72, 1.0],
                ),
                border: Border.all(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.66 : 0.48,
                  ),
                  width: isSelected
                      ? _centerNodeBorderWidth
                      : _centerNodeBorderWidth - 0.8,
                ),
                boxShadow: boxShadows,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: AnimatedOpacity(
              duration: _visualStateAnimationDuration,
              curve: Curves.easeOutCubic,
              opacity: textOpacity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 연결 단어 노드(원형)
  Widget _buildWordNode(
    Word word,
    Color accentColor, {
    required _GraphVisualState visualState,
  }) {
    final label = (word.spelling1 != null && word.spelling1!.trim().isNotEmpty)
        ? word.spelling1!.trim()
        : word.id;
    final transliteration = (word.transliteration1 ?? '').trim();

    final bool isSelected = visualState == _GraphVisualState.selected;
    final bool isDimmed = visualState == _GraphVisualState.dimmed;
    final languageColor = _colorForWordLanguageGroup(word.id);
    final Color effectiveAccentColor = isSelected
        ? _blendColor(accentColor, Colors.black, 0.18)
        : isDimmed
        ? _blendColor(accentColor, Colors.grey.shade500, 0.42)
        : accentColor;
    final double fillTintAlpha = isSelected
        ? _selectedNodeLanguageTintAlpha
        : isDimmed
        ? _mutedNodeLanguageTintAlpha
        : _connectedNodeLanguageTintAlpha;
    final Color fillColor = _surfaceTint(languageColor, fillTintAlpha);
    final Color innerFillColor = _surfaceTint(
      languageColor,
      (fillTintAlpha * 0.82).clamp(0.10, 0.22),
    );
    final Color midFillColor = _surfaceTint(
      languageColor,
      (fillTintAlpha * 0.92).clamp(0.12, 0.24),
    );
    final double borderWidth = isSelected
        ? _connectedNodeSelectedBorderWidth
        : isDimmed
        ? _connectedNodeMutedBorderWidth
        : _connectedNodeDefaultBorderWidth;
    final double backgroundOpacity = _nodeOpacityForState(
      visualState,
      isCenter: false,
    );
    final double textOpacity = _nodeTextOpacityForState(visualState);
    final List<BoxShadow> boxShadows = isSelected
        ? [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.22),
              blurRadius: 14,
              spreadRadius: 1.2,
            ),
            BoxShadow(
              color: accentColor.withValues(alpha: 0.16),
              blurRadius: 10,
              spreadRadius: 0.6,
              offset: const Offset(0, 3),
            ),
          ]
        : const [];

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
      child: SizedBox(
        width: _connectedNodeSize,
        height: _connectedNodeSize,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: _visualStateAnimationDuration,
              curve: Curves.easeOutCubic,
              opacity: backgroundOpacity,
              child: AnimatedContainer(
                duration: _visualStateAnimationDuration,
                curve: Curves.easeOutCubic,
                width: _connectedNodeSize,
                height: _connectedNodeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [innerFillColor, midFillColor, fillColor],
                    stops: const [0.0, 0.74, 1.0],
                  ),
                  border: Border.all(
                    color: effectiveAccentColor,
                    width: borderWidth,
                  ),
                  boxShadow: boxShadows,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AnimatedOpacity(
                duration: _visualStateAnimationDuration,
                curve: Curves.easeOutCubic,
                opacity: textOpacity,
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
          ],
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
    required int? selectedIndex,
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
              _primaryEdgeInfoByOtherId[words[index].id]?.categoryCode,
            ),
            visualState: _connectedNodeVisualState(
              nodeIndex: index,
              selectedIndex: selectedIndex,
            ),
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
    List<List<WordRelationEdgeInfo>> edgeInfoGroups,
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
      final edgeInfos = edgeInfoGroups[index];
      final bool hasFocusedNode = selectedIndex != null;
      final bool isFocusedEdge = selectedIndex == index;
      final Color labelBorderColor;
      final Color labelBackgroundColor;
      final double labelBorderWidth;
      final double labelOpacity;
      final FontWeight labelFontWeight;

      if (isFocusedEdge) {
        labelBorderColor = _blendColor(edgeColors[index], Colors.black, 0.08);
        labelBackgroundColor = Color.alphaBlend(
          edgeColors[index].withValues(alpha: _selectedEdgeLabelTintAlpha),
          Colors.white,
        );
        labelBorderWidth = _selectedEdgeLabelBorderWidth;
        labelOpacity = 1.0;
        labelFontWeight = FontWeight.bold;
      } else if (hasFocusedNode) {
        labelBorderColor = edgeColors[index].withValues(
          alpha: _mutedEdgeLabelBorderOpacity,
        );
        labelBackgroundColor = Color.alphaBlend(
          edgeColors[index].withValues(alpha: _dimmedEdgeLabelTintAlpha),
          Colors.white,
        );
        labelBorderWidth = _defaultEdgeLabelBorderWidth;
        labelOpacity = _dimmedEdgeLabelOpacity;
        labelFontWeight = FontWeight.w500;
      } else {
        labelBorderColor = edgeColors[index].withValues(
          alpha: _defaultEdgeLabelBorderOpacity,
        );
        labelBackgroundColor = Color.alphaBlend(
          edgeColors[index].withValues(alpha: _connectedEdgeLabelTintAlpha),
          Colors.white,
        );
        labelBorderWidth = _defaultEdgeLabelBorderWidth;
        labelOpacity = _connectedEdgeLabelOpacity;
        labelFontWeight = FontWeight.w600;
      }

      widgets.add(
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: GestureDetector(
              onTap: () {
                if (edgeInfos.isEmpty) return;
                _showEdgeDetailDialog(otherWord, edgeInfos);
              },
              child: AnimatedOpacity(
                duration: _visualStateAnimationDuration,
                curve: Curves.easeOutCubic,
                opacity: labelOpacity,
                child: AnimatedContainer(
                  duration: _visualStateAnimationDuration,
                  curve: Curves.easeOutCubic,
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
                      fontWeight: labelFontWeight,
                    ),
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

  List<WordRelationEdgeInfo> _edgeInfosForOtherWord(String otherWordId) {
    return List<WordRelationEdgeInfo>.unmodifiable(
      _edgeInfosByOtherId[otherWordId] ?? const <WordRelationEdgeInfo>[],
    );
  }

  WordRelationEdgeInfo? _primaryEdgeInfoForOtherWord(String otherWordId) {
    return _primaryEdgeInfoByOtherId[otherWordId];
  }

  _GraphEdgeDirectionSummary _directionSummaryForEdges(
    List<WordRelationEdgeInfo> infos,
  ) {
    if (infos.isEmpty) return _GraphEdgeDirectionSummary.unknown;

    final directions = infos
        .map((info) => info.centerRelativeDirection.trim())
        .where((direction) => direction.isNotEmpty)
        .toSet();

    if (directions.length != 1) {
      return _GraphEdgeDirectionSummary.mixed;
    }

    switch (directions.first) {
      case 'outgoing':
        return _GraphEdgeDirectionSummary.outgoing;
      case 'incoming':
        return _GraphEdgeDirectionSummary.incoming;
      case 'undirected':
        return _GraphEdgeDirectionSummary.undirected;
      default:
        return _GraphEdgeDirectionSummary.unknown;
    }
  }

  String _directionTagForSummary(_GraphEdgeDirectionSummary summary) {
    switch (summary) {
      case _GraphEdgeDirectionSummary.outgoing:
        return 'OUT';
      case _GraphEdgeDirectionSummary.incoming:
        return 'IN';
      case _GraphEdgeDirectionSummary.undirected:
        return 'UNDIR';
      case _GraphEdgeDirectionSummary.mixed:
        return 'MIX';
      case _GraphEdgeDirectionSummary.unknown:
        return 'UNK';
    }
  }

  String _relationLabelForDetails(WordRelationEdgeInfo info) {
    final raw = (info.relationTypeLabel?.trim().isNotEmpty ?? false)
        ? info.relationTypeLabel!.trim()
        : (info.relationType?.trim().isNotEmpty ?? false)
        ? info.relationType!.trim()
        : 'unspecified';

    return _normalizeRelationLabel(raw);
  }

  String _labelForEdgeGroup(List<WordRelationEdgeInfo> infos) {
    if (infos.isEmpty) return '';

    final directionTag = _directionTagForSummary(
      _directionSummaryForEdges(infos),
    );
    final relationLabel = _labelForEdge(infos.first);
    final countSuffix = infos.length > 1 ? ' x${infos.length}' : '';

    if (relationLabel.isEmpty) {
      return '$directionTag$countSuffix';
    }

    return '$directionTag $relationLabel$countSuffix';
  }

  String _directionTextForRawCode({
    required String directionCode,
    required String centerWordId,
    required String wordId1,
    required String wordId2,
  }) {
    switch (directionCode.trim()) {
      case 'w1_to_w2':
        return centerWordId == wordId1 ? '중심 -> 상대' : '상대 -> 중심';
      case 'w2_to_w1':
        return centerWordId == wordId1 ? '상대 -> 중심' : '중심 -> 상대';
      case 'undirected':
        return '방향 없음';
      default:
        return '방향 미정';
    }
  }

  List<DropdownMenuItem<String>> _directionDropdownItems({
    required String centerWordId,
    required String wordId1,
    required String wordId2,
  }) {
    const directionCodes = <String>[
      'unknown',
      'w1_to_w2',
      'w2_to_w1',
      'undirected',
    ];

    return directionCodes
        .map(
          (code) => DropdownMenuItem<String>(
            value: code,
            child: Text(
              _directionTextForRawCode(
                directionCode: code,
                centerWordId: centerWordId,
                wordId1: wordId1,
                wordId2: wordId2,
              ),
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<void> _showEdgeDetailDialog(
    Word otherWord,
    List<WordRelationEdgeInfo> infos,
  ) async {
    if (infos.isEmpty) return;
    if (infos.length == 1) {
      await _showSingleEdgeDetailDialog(otherWord, infos.first);
      return;
    }

    final selectedInfo = await showDialog<WordRelationEdgeInfo>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('관계 목록 ${otherWord.spelling1 ?? otherWord.id}'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: infos
                    .map((info) {
                      final directionTag = _directionTagForSummary(
                        _directionSummaryForEdges([info]),
                      );
                      final relationLabel = _relationLabelForDetails(info);
                      final metaParts = <String>[
                        directionTag,
                        if ((info.categoryLabel?.trim().isNotEmpty ?? false))
                          info.categoryLabel!.trim()
                        else if ((info.categoryCode?.trim().isNotEmpty ??
                            false))
                          info.categoryCode!.trim(),
                        'ID ${info.relationId}',
                      ];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => Navigator.pop(context, info),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  relationLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  metaParts.join(' | '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );

    if (!mounted || selectedInfo == null) return;
    await _showSingleEdgeDetailDialog(otherWord, selectedInfo);
  }

  Future<void> _showSingleEdgeDetailDialog(
    Word otherWord,
    WordRelationEdgeInfo info,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        bool isEditing = false;
        bool isSaving = false;

        // 초기값(읽기용)
        String? selectedCategoryCode = info.categoryCode;
        String? selectedRelationType = info.relationType;
        String selectedDirectionCode = info.directionCode;
        // 'unspecified' 같은 표시용 값이 들어오면 드롭다운 value 규칙 위반이므로 null 처리
        if ((selectedCategoryCode ?? '').toLowerCase() == 'unspecified') {
          selectedCategoryCode = null;
        }
        if ((selectedRelationType ?? '').toLowerCase() == 'unspecified') {
          selectedRelationType = null;
        }

        final descriptionController = TextEditingController(
          text: info.description ?? '',
        );
        final relationGroupIdController = TextEditingController(
          text: info.relationGroupId ?? '',
        );
        final noteController = TextEditingController(text: info.note ?? '');
        final sourceController = TextEditingController(text: info.source ?? '');

        // 드롭다운 옵션(편집 눌렀을 때 로딩)
        List<Map<String, dynamic>> categories = [];
        List<Map<String, dynamic>> types = [];
        bool isOptionsLoading = false;

        bool hasChanges() {
          final description = descriptionController.text.trim();
          final relationGroupId = relationGroupIdController.text.trim();
          final note = noteController.text.trim();
          final src = sourceController.text.trim();

          final originalDescription = (info.description ?? '').trim();
          final originalRelationGroupId = (info.relationGroupId ?? '').trim();
          final originalNote = (info.note ?? '').trim();
          final originalSrc = (info.source ?? '').trim();

          return selectedCategoryCode != info.categoryCode ||
              selectedRelationType != info.relationType ||
              selectedDirectionCode != info.directionCode ||
              description != originalDescription ||
              relationGroupId != originalRelationGroupId ||
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
              directionCode: selectedDirectionCode,
              description: _nullIfBlank(descriptionController.text),
              relationGroupId: _nullIfBlank(relationGroupIdController.text),
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
                : '(없음)';

            final typeText =
                (info.relationTypeLabel?.trim().isNotEmpty ?? false)
                ? info.relationTypeLabel!.trim()
                : (info.relationType?.trim().isNotEmpty ?? false)
                ? info.relationType!.trim()
                : '(없음)';
            final directionText = _directionTextForRawCode(
              directionCode: selectedDirectionCode,
              centerWordId: _centerWord.id,
              wordId1: info.wordId1,
              wordId2: info.wordId2,
            );
            final descriptionText = _nullIfBlank(descriptionController.text);
            final relationGroupIdText = _nullIfBlank(
              relationGroupIdController.text,
            );

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
                      const Text(
                        '방향',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (!isEditing)
                        Text(directionText)
                      else
                        DropdownButtonFormField<String>(
                          value: selectedDirectionCode,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: _directionDropdownItems(
                            centerWordId: _centerWord.id,
                            wordId1: info.wordId1,
                            wordId2: info.wordId2,
                          ),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => selectedDirectionCode = value);
                          },
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
                        onChanged: (_) => setState(() {}),
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
                        onChanged: (_) => setState(() {}),
                        maxLines: 2,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '(없음)',
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '설명',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (!isEditing)
                        Text(descriptionText ?? '(없음)')
                      else
                        TextField(
                          controller: descriptionController,
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
                          maxLines: 3,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '(없음)',
                          ),
                        ),
                      const SizedBox(height: 14),
                      const Text(
                        '관계 그룹 ID',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (!isEditing)
                        Text(relationGroupIdText ?? '(없음)')
                      else
                        TextField(
                          controller: relationGroupIdController,
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
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
                              selectedDirectionCode = info.directionCode;
                              descriptionController.text =
                                  info.description ?? '';
                              relationGroupIdController.text =
                                  info.relationGroupId ?? '';
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
          final existing = await _repository.findExistingRelationIdBySignature(
            _centerWord.id,
            createdWord.id,
            relationType: relationPayload.relationType,
            directionCode: relationPayload.directionCode,
          );

          if (existing == null) {
            await _repository.createRelation(
              wordId1: _centerWord.id,
              wordId2: createdWord.id,
              categoryCode: relationPayload.categoryCode,
              relationType: relationPayload.relationType,
              directionCode: relationPayload.directionCode,
              description: relationPayload.description,
              relationGroupId: relationPayload.relationGroupId,
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
                          labelText: '스트롱 번호 (없으면 비워둠)',
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
                        ? '같은 스트롱 번호를 가진 기존 단어가 있습니다.'
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
                          'ID: $id\n언어: $lang\n스트롱 번호: $strong\n표기1: $spelling\n의미1: $meaning',
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
    if (!mounted) return null;

    String? selectedCategoryCode;
    String? selectedRelationType;
    String selectedDirectionCode = 'unknown';
    final descriptionController = TextEditingController();
    final relationGroupIdController = TextEditingController();
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
                child: SingleChildScrollView(
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
                      DropdownButtonFormField<String>(
                        value: selectedDirectionCode,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: '방향'),
                        items: _directionDropdownItems(
                          centerWordId: _centerWord.id,
                          wordId1: _centerWord.id,
                          wordId2: other.id,
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => selectedDirectionCode = value);
                        },
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
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: '설명'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: relationGroupIdController,
                        decoration: const InputDecoration(
                          labelText: '관계 그룹 ID',
                        ),
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
                    Navigator.pop(
                      context,
                      CreateRelationPayload(
                        categoryCode: selectedCategoryCode,
                        relationType: selectedRelationType,
                        directionCode: selectedDirectionCode,
                        description: _nullIfBlank(descriptionController.text),
                        relationGroupId: _nullIfBlank(
                          relationGroupIdController.text,
                        ),
                        note: _nullIfBlank(noteController.text),
                        source: _nullIfBlank(sourceController.text),
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
    final existingId = await _repository.findExistingRelationIdBySignature(
      _centerWord.id,
      other.id,
      relationType: payload.relationType,
      directionCode: payload.directionCode,
    );

    if (existingId != null) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('이미 존재하는 관계'),
          content: const Text(
            '이 두 단어 사이의 관계가 이미 데이터베이스에 존재합니다.\n중복 생성은 막았습니다.',
          ),
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
      directionCode: payload.directionCode,
      description: payload.description,
      relationGroupId: payload.relationGroupId,
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
                        labelText: '검색 (표기/의미/스트롱 번호)',
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
                                        '스트롱 번호: ${w.strongNumber}',
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

class _GraphLinePainter extends CustomPainter {
  final _GraphLayoutData layout;
  final List<Color> edgeColors;
  final List<String> edgeLabels;
  final List<String?> edgeRelationTypes;
  final List<_GraphEdgeDirectionSummary> edgeDirectionSummaries;
  final bool showLabels;
  final double sceneScale;
  final int? selectedIndex;

  _GraphLinePainter({
    required this.layout,
    required this.edgeColors,
    required this.edgeLabels,
    required this.edgeRelationTypes,
    required this.edgeDirectionSummaries,
    required this.showLabels,
    required this.sceneScale,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.nodeLayouts.isEmpty) return;

    for (final nodeLayout in layout.nodeLayouts) {
      final index = nodeLayout.index;
      final bool hasFocusedNode = selectedIndex != null;
      final bool isFocusedEdge = selectedIndex == index;
      final edgeStyle = (index < edgeRelationTypes.length)
          ? _edgeSemanticStyleForRelationType(edgeRelationTypes[index])
          : _GraphEdgeSemanticStyle.solid;
      final directionSummary = (index < edgeDirectionSummaries.length)
          ? edgeDirectionSummaries[index]
          : _GraphEdgeDirectionSummary.unknown;
      final double strokeWidth = hasFocusedNode
          ? isFocusedEdge
                ? _selectedEdgeStrokeWidth
                : _mutedEdgeStrokeWidth
          : _defaultEdgeStrokeWidth;
      final Color strokeColor = hasFocusedNode
          ? edgeColors[index].withValues(
              alpha: isFocusedEdge ? 1.0 : _mutedEdgeOpacity,
            )
          : edgeColors[index].withValues(alpha: _connectedEdgeOpacity);

      final paint = Paint()
        ..color = strokeColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      _drawStyledEdge(
        canvas,
        layout.center,
        nodeLayout.center,
        paint,
        edgeStyle,
      );
      _drawDirectionIndicator(
        canvas,
        layout.center,
        nodeLayout.center,
        paint,
        directionSummary,
      );

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

  void _drawStyledEdge(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    _GraphEdgeSemanticStyle edgeStyle,
  ) {
    switch (edgeStyle) {
      case _GraphEdgeSemanticStyle.solid:
        canvas.drawLine(start, end, paint);
        return;
      case _GraphEdgeSemanticStyle.dashed:
        _drawSegmentedEdge(
          canvas,
          start,
          end,
          paint,
          segmentLength: _dashedEdgeDashLength,
          gapLength: _dashedEdgeGapLength,
        );
        return;
      case _GraphEdgeSemanticStyle.dotted:
        _drawSegmentedEdge(
          canvas,
          start,
          end,
          paint,
          segmentLength: _dottedEdgeDotLength,
          gapLength: _dottedEdgeGapLength,
        );
        return;
    }
  }

  void _drawSegmentedEdge(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    required double segmentLength,
    required double gapLength,
  }) {
    final delta = end - start;
    final totalLength = delta.distance;
    if (totalLength <= 0 || segmentLength <= 0) return;

    final direction = Offset(delta.dx / totalLength, delta.dy / totalLength);
    var drawnLength = 0.0;

    while (drawnLength < totalLength) {
      final segmentStart = start + direction * drawnLength;
      final segmentEndLength = min(drawnLength + segmentLength, totalLength);
      final segmentEnd = start + direction * segmentEndLength;
      canvas.drawLine(segmentStart, segmentEnd, paint);
      drawnLength += segmentLength + gapLength;
    }
  }

  void _drawDirectionIndicator(
    Canvas canvas,
    Offset center,
    Offset nodeCenter,
    Paint paint,
    _GraphEdgeDirectionSummary directionSummary,
  ) {
    final delta = nodeCenter - center;
    final totalLength = delta.distance;
    if (totalLength <= 0.001) return;

    final direction = Offset(delta.dx / totalLength, delta.dy / totalLength);
    const edgeInset = 8.0;
    const arrowLength = 14.0;

    switch (directionSummary) {
      case _GraphEdgeDirectionSummary.outgoing:
        final tip = nodeCenter - direction * (_connectedNodeHalf + edgeInset);
        final tailReference = tip - direction * arrowLength;
        _drawArrowHead(canvas, tip, tailReference, paint);
        return;
      case _GraphEdgeDirectionSummary.incoming:
        final tip = center + direction * (_centerNodeHalf + edgeInset);
        final tailReference = tip + direction * arrowLength;
        _drawArrowHead(canvas, tip, tailReference, paint);
        return;
      case _GraphEdgeDirectionSummary.undirected:
      case _GraphEdgeDirectionSummary.unknown:
      case _GraphEdgeDirectionSummary.mixed:
        return;
    }
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    Offset tailReference,
    Paint paint,
  ) {
    final vector = tip - tailReference;
    final length = vector.distance;
    if (length <= 0.001) return;

    final direction = Offset(vector.dx / length, vector.dy / length);
    final perpendicular = Offset(-direction.dy, direction.dx);
    final wingLength = 8.0 + paint.strokeWidth;
    final wingWidth = wingLength * 0.56;
    final base = tip - direction * wingLength;
    final wingA = base + perpendicular * wingWidth;
    final wingB = base - perpendicular * wingWidth;
    final arrowPaint = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(tip, wingA, arrowPaint);
    canvas.drawLine(tip, wingB, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _GraphLinePainter oldDelegate) {
    return oldDelegate.layout.contentBounds != layout.contentBounds ||
        oldDelegate.layout.ringRadii.length != layout.ringRadii.length ||
        oldDelegate.edgeColors.length != edgeColors.length ||
        oldDelegate.edgeColors != edgeColors ||
        oldDelegate.edgeLabels.length != edgeLabels.length ||
        oldDelegate.edgeLabels != edgeLabels ||
        oldDelegate.edgeRelationTypes.length != edgeRelationTypes.length ||
        oldDelegate.edgeRelationTypes != edgeRelationTypes ||
        oldDelegate.edgeDirectionSummaries.length !=
            edgeDirectionSummaries.length ||
        oldDelegate.edgeDirectionSummaries != edgeDirectionSummaries ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.sceneScale != sceneScale ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
