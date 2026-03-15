import 'package:flutter/material.dart';
import 'word_graph_screen.dart';
import 'word_graph_cache.dart';
import 'word_edit_screen.dart';
import 'word_info_panel.dart';
import '../data/models/word.dart';
import '../data/repositories/word_repository.dart';

class WordDetailScreen extends StatefulWidget {
  final Map<String, dynamic> word;

  const WordDetailScreen({super.key, required this.word});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final WordRepository _repository = WordRepository();

  late Map<String, dynamic> _word;
  bool _isDeleting = false;

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

  void _openGraph() {
    final centerWord = Word.fromMap(_word);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordGraphScreen(centerWord: centerWord),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final wordId = (_word['id'] ?? '').toString();
    if (wordId.isEmpty) return;

    final relationCount = await _repository.countRelationsForWord(wordId);

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('단어 삭제'),
          content: Text(
            relationCount > 0
                ? '이 단어를 삭제하면 연결된 관계 $relationCount개도 함께 삭제됩니다.\n정말 삭제할까요?'
                : '이 단어를 정말 삭제할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await _repository.deleteWord(wordId);
      WordGraphDataCache.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('단어가 삭제되었습니다.')));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(buildWordRepresentativeSpelling(_word, fallback: '상세 정보')),
      ),
      body: WordInfoPanel(
        wordMap: _word,
        onEdit: _openEdit,
        onShowGraph: _openGraph,
        onDelete: _confirmDelete,
        isDeleting: _isDeleting,
      ),
    );
  }
}
