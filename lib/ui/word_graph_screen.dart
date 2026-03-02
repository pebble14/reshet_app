import 'dart:math';
import 'package:flutter/material.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text('Word Graph')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;
          final centerY = constraints.maxHeight / 2;

          final nodes = _connectedWords;
          // 노드 배치 순서(원형 배치 순서)와 동일한 순서로 엣지 색상을 만든다.
          final edgeColors = nodes.map((w) {
            final info = _edgeInfoByOtherId[w.id];
            return _colorForCategory(info?.categoryCode);
          }).toList();
          // 노드 배치 순서와 동일한 순서로 엣지 라벨을 만든다.
          final edgeLabels = nodes.map((w) {
            final info = _edgeInfoByOtherId[w.id];
            return _labelForEdge(info);
          }).toList();

          return Stack(
            children: [
              // nodeCount가 0이면 painter에서 0으로 나누는 문제가 생길 수 있으므로 조건 처리
              if (nodes.isNotEmpty)
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: GraphLinePainter(centerX, centerY, edgeColors, edgeLabels),
                ),

              // 중앙 노드
              Positioned(
                left: centerX - 90,
                top: centerY - 90,
                child: _buildCenterNode(_centerWord),
              ),

              // 연결 노드들
              ..._buildWordNodes(centerX, centerY, nodes),

              // 연결이 없을 때 안내 문구
              if (nodes.isEmpty)
                Center(
                  child: Text(
                    '연결된 단어가 없습니다.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
            ],
          );
        },
      ),
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
  /// - 너무 길면 잘라서 그래프 가독성을 유지한다.
  String _labelForEdge(WordRelationEdgeInfo? info) {
    final raw = (info?.relationTypeLabel?.trim().isNotEmpty ?? false)
        ? info!.relationTypeLabel!.trim()
        : (info?.relationType ?? '').trim();

    if (raw.isEmpty) return '';

    // 너무 길면 잘라서 표시(가독성)
    const maxLen = 14;
    if (raw.length <= maxLen) return raw;
    return '${raw.substring(0, maxLen)}…';
  }
}

/// 연결선(엣지) 렌더러
class GraphLinePainter extends CustomPainter {
  final double centerX;
  final double centerY;

  /// 노드 배치 순서와 동일한 순서의 엣지 색상 리스트
  final List<Color> edgeColors;
    /// 엣지 라벨(노드 배치 순서와 동일한 순서)
  final List<String> edgeLabels;

  GraphLinePainter(this.centerX, this.centerY, this.edgeColors, this.edgeLabels);

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
      if (label.isNotEmpty) {
        // 선의 중간보다 약간 중심 쪽 위치가 보기 좋다(겹침 감소)
        final mid = Offset(
          (center.dx + dx) / 2,
          (center.dy + dy) / 2,
        );

        _drawEdgeLabel(canvas, mid, label, edgeColors[i]);
      }
    }
  }

  void _drawEdgeLabel(Canvas canvas, Offset pos, String text, Color edgeColor) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout();

    const padX = 6.0;
    const padY = 3.0;

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
        oldDelegate.edgeLabels != edgeLabels;
  }
}