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

  const WordGraphScreen({super.key, required this.centerWord});

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

  @override
  void initState() {
    super.initState();
    _centerWord = widget.centerWord;
    _loadConnectedWords();
  }

  Future<void> _loadConnectedWords() async {
    try {
      final words = await _repository.getConnectedWords(_centerWord.id);

      if (!mounted) return;
      setState(() {
        _connectedWords = words;
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

          return Stack(
            children: [
              // nodeCount가 0이면 painter에서 0으로 나누는 문제가 생길 수 있으므로 조건 처리
              if (nodes.isNotEmpty)
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: GraphLinePainter(centerX, centerY, nodes.length),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 연결 단어 노드(원형)
  Widget _buildWordNode(Word word) {
    final label = (word.spelling1 != null && word.spelling1!.trim().isNotEmpty)
        ? word.spelling1!
        : word.id;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WordGraphScreen(centerWord: word),
          ),
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey, width: 2),
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
          child: _buildWordNode(words[i]),
        ),
      );
    }

    return widgets;
  }
}

/// 연결선(엣지) 렌더러
class GraphLinePainter extends CustomPainter {
  final double centerX;
  final double centerY;
  final int nodeCount;

  GraphLinePainter(this.centerX, this.centerY, this.nodeCount);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;

    const double radius = 160;
    final center = Offset(centerX, centerY);

    for (int i = 0; i < nodeCount; i++) {
      final angle = (2 * pi / nodeCount) * i;

      final dx = centerX + radius * cos(angle);
      final dy = centerY + radius * sin(angle);

      canvas.drawLine(center, Offset(dx, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}