import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories/word_repository.dart';
import '../domain/word/word_detail_like_display_item.dart';
import '../domain/word/word_edit_save_result.dart';
import '../domain/word/word_write_models.dart';
import '../domain/word/word_write_service.dart';
import 'word_edit_screen.dart';
import 'word_graph_cache.dart';
import 'word_graph_screen.dart';
import 'word_info_panel.dart';

class WordDetailScreen extends StatefulWidget {
  final String wordId;
  final WordDetailLikeDisplayItem initialDisplayItem;

  const WordDetailScreen({
    super.key,
    required this.wordId,
    required this.initialDisplayItem,
  });

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final WordRepository _repository = WordRepository();
  final WordWriteService _wordWriteService = WordWriteService();

  late final String _wordId;
  late WordDetailLikeDisplayItem _displayItem;
  bool _isDeleting = false;
  int _detailReloadToken = 0;

  @override
  void initState() {
    super.initState();
    _wordId = widget.wordId.trim();
    _displayItem = widget.initialDisplayItem;
    unawaited(_refreshDetailScreenDisplayItem());
  }

  Future<void> _refreshDetailScreenDisplayItem() async {
    if (_wordId.isEmpty) {
      return;
    }

    final requestToken = ++_detailReloadToken;

    try {
      final reloadedWord = await _repository
          .getWordDetailLikeDisplayItemByIdForDetailScreen(_wordId);
      if (!mounted ||
          requestToken != _detailReloadToken ||
          reloadedWord == null) {
        return;
      }

      setState(() {
        _displayItem = reloadedWord;
      });
    } catch (_) {
      // Keep the initial display visible so fallback and reload errors stay silent.
    }
  }

  Future<void> _openEdit() async {
    final editSeed = await _repository.getWordEditSeedForDetailEdit(_wordId);
    if (!mounted) return;
    if (editSeed == null) {
      _showWordNavigationUnavailableSnackBar();
      return;
    }

    final result = await Navigator.push<WordEditSaveResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WordEditScreen.fromSeed(seed: editSeed),
      ),
    );

    if (result != null) {
      unawaited(_refreshDetailScreenDisplayItem());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('단어 정보가 수정되었습니다.')));
    }
  }

  Future<void> _openGraph() async {
    final centerWordMap = await _repository
        .getWordMapByIdForGraphCenterSingleWord(_wordId);
    if (!mounted) return;
    if (centerWordMap == null) {
      _showWordNavigationUnavailableSnackBar();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordGraphScreen(centerWordId: _wordId),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (_wordId.isEmpty) return;

    final relationCount = await _repository.countRelationsForWord(_wordId);

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
      await _wordWriteService.execute(DeleteWordCommand(wordId: _wordId));
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

  void _showWordNavigationUnavailableSnackBar() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('단어 정보를 찾을 수 없습니다.')));
  }

  String _buildTitle() {
    final title = _displayItem.representativeSpelling?.trim() ?? '';
    if (title.isEmpty) {
      return '상세 정보';
    }

    return title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_buildTitle())),
      body: WordInfoPanel(
        displayItem: _displayItem,
        onEdit: _openEdit,
        onShowGraph: _openGraph,
        onDelete: _confirmDelete,
        isDeleting: _isDeleting,
      ),
    );
  }
}
