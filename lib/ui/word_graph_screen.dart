import 'dart:math';
import 'package:flutter/material.dart';
import '../data/models/word.dart';

/// 단어 관계 그래프 화면 (현재: 더미 노드 기반)
/// - 중앙 노드는 선택된 단어(centerWord)
/// - 주변 노드는 더미 리스트를 원형으로 자동 배치
/// - 엣지는 노드 개수에 맞춰 자동으로 연결선 렌더링
class WordGraphScreen extends StatelessWidget {
  /// 그래프의 중심이 되는 단어(모델)
  final Word centerWord;

  const WordGraphScreen({super.key, required this.centerWord});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word Graph')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;
          final centerY = constraints.maxHeight / 2;

          // TODO: 다음 단계에서 DB(WORD_RELATION) 기반 실제 연결 단어로 교체
          final dummyNodes = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

          return Stack(
            children: [
              /// 연결선(엣지) 렌더링
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: GraphLinePainter(centerX, centerY, dummyNodes.length),
              ),

              /// 중앙 노드(선택 단어)
              Positioned(
                left: centerX - 90,
                top: centerY - 90,
                child: _buildCenterNode(),
              ),

              /// 주변 노드(더미)
              ..._buildDummyNodes(centerX, centerY, dummyNodes),
            ],
          );
        },
      ),
    );
  }

  /// 중앙 노드 UI
  Widget _buildCenterNode() {
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
          Text(centerWord.language ?? '', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(centerWord.strongNumber ?? '',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            centerWord.spelling1 ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(centerWord.pronunciation1 ?? '',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            centerWord.meaning1 ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 주변(더미) 노드 UI
  Widget _buildDummyNode(String label) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey, width: 2),
        color: Colors.white,
      ),
      child: Center(child: Text(label, textAlign: TextAlign.center)),
    );
  }

  /// 더미 노드들을 원형으로 자동 배치한다.
  List<Widget> _buildDummyNodes(
    double centerX,
    double centerY,
    List<String> nodes,
  ) {
    const double radius = 160;
    const double nodeRadius = 40;

    final List<Widget> widgets = [];

    for (int i = 0; i < nodes.length; i++) {
      final angle = (2 * pi / nodes.length) * i;

      final dx = centerX + radius * cos(angle);
      final dy = centerY + radius * sin(angle);

      widgets.add(
        Positioned(
          left: dx - nodeRadius,
          top: dy - nodeRadius,
          child: _buildDummyNode(nodes[i]),
        ),
      );
    }

    return widgets;
  }
}

/// 그래프 연결선(엣지) 렌더러
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