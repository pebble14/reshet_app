import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../data/models/word.dart';
import '../data/repositories/word_repository.dart';

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

  const WordGraphScreen({
    super.key,
    required this.centerWord,
    this.onSelectWord,
  });

  @override
  State<WordGraphScreen> createState() => _WordGraphScreenState();
}

class _WordGraphScreenState extends State<WordGraphScreen> {
  final WordRepository _repository = WordRepository();

  /// 그래프 줌/팬 상태를 관리하는 컨트롤러
  final TransformationController _transformController = TransformationController();

  /// 현재 줌 배율(태그 표시/숨김 등에 사용)
  double _currentScale = 1.0;

  /// 이 배율보다 작아지면 엣지 태그를 숨긴다(가독성/겹침 감소)
  static const double _labelVisibleScaleThreshold = 1.15;

  late final Word _centerWord;

  bool _isLoading = true;
  String? _errorMessage;

  /// 중심 단어와 연결된 단어 목록
  List<Word> _connectedWords = [];

  /// 상대 단어 id 기준으로 관계(엣지) 메타를 보관한다.
  /// - 여러 관계가 있을 수 있으나, 현재는 “표시용 1개”만 선택(마지막으로 덮어씀)
  final Map<String, WordRelationEdgeInfo> _edgeInfoByOtherId = {};

  @override
  void initState() {
    super.initState();
    _centerWord = widget.centerWord;
    _loadConnectedWords();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadConnectedWords() async {
    try {
      final words = await _repository.getConnectedWords(_centerWord.id);
      final edges = await _repository.getRelationEdges(_centerWord.id);

      if (!mounted) return;
      setState(() {
        _connectedWords = words;

        _edgeInfoByOtherId.clear();
        for (final e in edges) {
          _edgeInfoByOtherId[e.otherWordId] = e;
        }

        _isLoading = false;
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
        final centerX = constraints.maxWidth / 2;
        final centerY = constraints.maxHeight / 2;

        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        final nodes = _connectedWords;

        // 노드 배치 순서와 동일한 순서로 엣지 색상/라벨 생성
        final edgeColors = nodes.map((w) {
          final info = _edgeInfoByOtherId[w.id];
          return _colorForCategory(info?.categoryCode);
        }).toList();
        final edgeLabels = nodes.map((w) {
          final info = _edgeInfoByOtherId[w.id];
          return _labelForEdge(info);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Word Graph'),
            actions: [
              IconButton(
                tooltip: '전체보기',
                icon: const Icon(Icons.fit_screen),
                onPressed: () => _fitToView(canvasSize, centerX, centerY, nodes),
              ),
              IconButton(
                tooltip: '보기 초기화',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _transformController.value = Matrix4.identity();
                  setState(() => _currentScale = 1.0);
                },
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
                  children: [
                    if (nodes.isNotEmpty)
                      CustomPaint(
                        size: canvasSize,
                        painter: GraphLinePainter(
                          centerX,
                          centerY,
                          edgeColors,
                          edgeLabels,
                          showLabels: _currentScale >= _labelVisibleScaleThreshold,
                          sceneScale: _currentScale,
                        ),
                      ),
                    Positioned(
                      left: centerX - 90,
                      top: centerY - 90,
                      child: _buildCenterNode(_centerWord),
                    ),
                    ..._buildWordNodes(centerX, centerY, nodes),
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
  Widget _buildCenterNode(Word word) {
    return Container(
      width: 180,
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.shade100,
        border: Border.all(color: Colors.blue, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(word.language ?? '', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(word.strongNumber ?? '', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            word.spelling1 ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(word.pronunciation1 ?? '', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            word.meaning1 ?? '',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 연결 단어 노드(원형)
  Widget _buildWordNode(Word word, Color borderColor) {
    final label = (word.spelling1 != null && word.spelling1!.trim().isNotEmpty)
        ? word.spelling1!
        : word.id;

    return GestureDetector(
      onTap: () {
        // ✅ 콜백이 있으면(스플릿뷰) 우측 패널 갱신용으로 전달
        if (widget.onSelectWord != null) {
          widget.onSelectWord!(word);
          return;
        }

        // ✅ 콜백이 없으면(기존 방식) push 탐색 유지
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WordGraphScreen(centerWord: word),
          ),
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
          color: Colors.white,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  /// 연결 단어들을 원형으로 자동 배치
  List<Widget> _buildWordNodes(
    double centerX,
    double centerY,
    List<Word> words,
  ) {
    if (words.isEmpty) return [];

    const double radius = 160;
    const double nodeRadius = 40;

    final List<Widget> widgets = [];

    for (int i = 0; i < words.length; i++) {
      final angle = (2 * pi / words.length) * i;

      final dx = centerX + radius * cos(angle);
      final dy = centerY + radius * sin(angle);

      widgets.add(
        Positioned(
          left: dx - nodeRadius,
          top: dy - nodeRadius,
          child: _buildWordNode(
            words[i],
            _colorForCategory(_edgeInfoByOtherId[words[i].id]?.categoryCode),
          ),
        ),
      );
    }

    return widgets;
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

  /// 현재 그래프(중심 노드 + 연결 노드들)가 화면에 잘 들어오도록 자동으로 줌/팬을 맞춘다.
  void _fitToView(Size canvasSize, double centerX, double centerY, List<Word> nodes) {
    // 노드 배치 반지름(현재 GraphLinePainter와 _buildWordNodes에서 쓰는 값과 맞춰야 함)
    const radius = 160.0;

    // 중심 노드/주변 노드 크기(현재 위젯 크기와 맞춰야 함)
    const centerHalf = 90.0; // 180 / 2
    const nodeHalf = 40.0;   // 80 / 2

    double minX = centerX - centerHalf;
    double maxX = centerX + centerHalf;
    double minY = centerY - centerHalf;
    double maxY = centerY + centerHalf;

    final n = nodes.length;
    if (n > 0) {
      for (int i = 0; i < n; i++) {
        final angle = (2 * pi / n) * i;
        final x = centerX + radius * cos(angle);
        final y = centerY + radius * sin(angle);

        minX = min(minX, x - nodeHalf);
        maxX = max(maxX, x + nodeHalf);
        minY = min(minY, y - nodeHalf);
        maxY = max(maxY, y + nodeHalf);
      }
    }

    // 여백(태그/선 고려)
    const margin = 60.0;
    final bboxW = (maxX - minX) + margin * 2;
    final bboxH = (maxY - minY) + margin * 2;

    // 스케일 계산
    final sx = canvasSize.width / bboxW;
    final sy = canvasSize.height / bboxH;
    final scale = min(sx, sy).clamp(0.6, 3.5);

    // 바운딩 박스 중심
    final bboxCenterX = (minX + maxX) / 2;
    final bboxCenterY = (minY + maxY) / 2;

    // bbox 중심이 화면 중앙에 오도록 변환 설정
    final m = Matrix4.identity()
      ..translate(canvasSize.width / 2, canvasSize.height / 2)
      ..scale(scale)
      ..translate(-bboxCenterX, -bboxCenterY);

    _transformController.value = m;
    setState(() => _currentScale = scale);
  }
}

/// 연결선(엣지) 렌더러
class GraphLinePainter extends CustomPainter {
  final double centerX;
  final double centerY;

  final List<Color> edgeColors;
  final List<String> edgeLabels;

  /// 줌 레벨에 따라 라벨 표시/숨김
  final bool showLabels;
  /// 현재 씬(그래프) 줌 배율
  /// - 태그 텍스트/패딩을 1/scale로 보정하여 “거의 고정 크기”처럼 보이게 한다.
  final double sceneScale;

  GraphLinePainter(
    this.centerX,
    this.centerY,
    this.edgeColors,
    this.edgeLabels, {
    required this.showLabels,
    required this.sceneScale,
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

      final paint = Paint()
        ..color = edgeColors[i]
        ..strokeWidth = 2;

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
        final anchor = Offset(
          center.dx + vx * t,
          center.dy + vy * t,
        );

        // 선 벡터의 수직 방향으로 약간 이동(선/태그 겹침 완화)
        final len = sqrt(vx * vx + vy * vy);
        final nx = (len == 0) ? 0.0 : -vy / len; // 수직 단위벡터 x
        final ny = (len == 0) ? 0.0 : vx / len;  // 수직 단위벡터 y

        final scale = sceneScale <= 0 ? 1.0 : sceneScale;
        // 줌과 관계없이 적당한 오프셋(역스케일) 유지
        final offset = (12.0 / scale).clamp(6.0, 14.0);

        final shifted = Offset(anchor.dx + nx * offset, anchor.dy + ny * offset);

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
    final textOffset = Offset(
      rect.left + padX,
      rect.top + padY,
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant GraphLinePainter oldDelegate) {
    // node 수나 색상이 변하면 다시 그리기
    return oldDelegate.edgeColors.length != edgeColors.length ||
        oldDelegate.edgeColors != edgeColors ||
        oldDelegate.edgeLabels.length != edgeLabels.length ||
        oldDelegate.edgeLabels != edgeLabels ||
        oldDelegate.showLabels != showLabels;
  }
}