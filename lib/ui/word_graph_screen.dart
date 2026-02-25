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

          return Stack(
            children: [
              Positioned(
                left: centerX - 90,
                top: centerY - 90,
                child: _buildCenterNode(),
              ),
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
}
