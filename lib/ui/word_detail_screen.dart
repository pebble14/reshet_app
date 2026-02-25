import 'package:flutter/material.dart';
import 'word_graph_screen.dart';

class WordDetailScreen extends StatelessWidget {
  final Map<String, dynamic> word;

  const WordDetailScreen({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(word['표기1'] ?? '상세 정보')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...word.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(child: Text(entry.value?.toString() ?? '')),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WordGraphScreen(word: word),
                ),
              );
            },
            child: const Text('그래프 보기'),
          ),
        ],
      ),
    );
  }
}
