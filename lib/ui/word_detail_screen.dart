import 'package:flutter/material.dart';
import 'word_graph_screen.dart';
import 'word_edit_screen.dart';
import '../data/models/word.dart';

class WordDetailScreen extends StatefulWidget {
  final Map<String, dynamic> word;

  const WordDetailScreen({super.key, required this.word});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  late Map<String, dynamic> _word;

  @override
  void initState() {
    super.initState();
    _word = Map<String, dynamic>.from(widget.word);
  }

  Future<void> _openEdit() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => WordEditScreen(word: _word)),
    );

    if (result != null) {
      setState(() => _word = result);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('단어 정보가 수정되었습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_word['표기1'] ?? '상세 정보')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._word.entries.map((entry) {
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
          ElevatedButton(onPressed: _openEdit, child: const Text('편집')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              final Word centerWord = Word.fromMap(_word);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WordGraphScreen(centerWord: centerWord),
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
