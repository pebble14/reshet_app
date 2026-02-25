import 'package:flutter/material.dart';

class WordGraphScreen extends StatelessWidget {
  final Map<String, dynamic> word;

  const WordGraphScreen({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word Graph')),
      body: Center(
        child: Text(
          'Graph for: ${word['표기1'] ?? 'Unknown'}',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
