import 'package:flutter/material.dart';
import 'dart:math';

class WordGraphScreen extends StatelessWidget {
  final Map<String, dynamic> word;

  const WordGraphScreen({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word Graph')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;
          final centerY = constraints.maxHeight / 2;
          final dummyNodes = [
            'A',
            'B',
            'C',
            'D',
            'E',
            'F',
            'G',
          ]; // 나중에 실제 데이터로 대체 가능

          return Stack(
            children: [
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: GraphLinePainter(centerX, centerY, dummyNodes.length),
              ),

              // 중앙 노드
              Positioned(
                left: centerX - 90,
                top: centerY - 90,
                child: _buildCenterNode(),
              ),

              // 자동 배치 노드들
              ..._buildDummyNodes(centerX, centerY, dummyNodes),
            ],
          );
        },
      ),
    );
  }

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
          Text(word['언어'] ?? '', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(word['스트롱넘버'] ?? '', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            word['표기1'] ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(word['발음1'] ?? '', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            word['의미1'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

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

  List<Widget> _buildDummyNodes(
    double centerX,
    double centerY,
    List<String> nodes,
  ) {
    const double radius = 160;
    const double nodeRadius = 40;

    List<Widget> widgets = [];

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

      final nodeCenter = Offset(dx, dy);

      canvas.drawLine(center, nodeCenter, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
