import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories/word_repository.dart';
import '../domain/word/word_detail_like_display_item.dart';
import '../domain/word/word_edit_save_result.dart';
import '../domain/word/word_write_models.dart';
import '../domain/word/word_write_service.dart';
import 'mobile_word_search_screen.dart';
import 'responsive_layout.dart';
import 'word_detail_route_result.dart';
import 'word_edit_screen.dart';
import 'word_graph_cache.dart';
import 'word_graph_screen.dart';
import 'word_info_panel.dart';
import 'word_search_query.dart';

class WordDetailScreen extends StatefulWidget {
  final String wordId;
  final WordDetailLikeDisplayItem initialDisplayItem;
  final bool showEditAction;
  final WordMutationImpactCollector? mutationImpactCollector;

  const WordDetailScreen({
    super.key,
    required this.wordId,
    required this.initialDisplayItem,
    this.showEditAction = true,
    this.mutationImpactCollector,
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
      widget.mutationImpactCollector?.recordChangedWord(result.wordId);
      await _refreshDetailScreenDisplayItem();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('단어 정보가 수정되었습니다.')));
    }
  }

  Future<void> _openGraph() async {
    final centerWordExists = await _repository.wordExistsForGraphNavigation(
      _wordId,
    );
    if (!mounted) return;
    if (!centerWordExists) {
      _showWordNavigationUnavailableSnackBar();
      return;
    }

    final collector = widget.mutationImpactCollector;
    final checkpoint = collector?.checkpoint;
    final graphResult = await Navigator.push<WordDetailRouteResult>(
      context,
      MaterialPageRoute(
        builder: (context) => WordGraphScreen(
          centerWordId: _wordId,
          mutationImpactCollector: widget.mutationImpactCollector,
        ),
      ),
    );

    if (!mounted) return;
    if (collector != null && checkpoint != null) {
      await _handleMobileSearchTargetResult(
        mutationImpactSince(
          collector: collector,
          checkpoint: checkpoint,
          routeResult: graphResult,
        ),
      );
      return;
    }
    if (graphResult is WordDetailDeletedResult &&
        graphResult.wordId.trim() == _wordId) {
      Navigator.pop(context, graphResult);
    }
  }

  Future<void> _openMobileSearch() async {
    final selection = await Navigator.push<WordSearchSelection>(
      context,
      MaterialPageRoute(builder: (_) => const MobileWordSearchScreen()),
    );
    if (!mounted || selection == null) {
      return;
    }

    switch (selection.destination) {
      case WordSearchDestination.detail:
        await _openMobileSearchDetail(selection.wordId);
      case WordSearchDestination.graph:
        await _openMobileSearchGraph(selection.wordId);
    }
  }

  Future<void> _openMobileSearchDetail(String wordId) async {
    final detailWord = await _repository
        .getWordDetailLikeDisplayItemByIdForDetailScreen(wordId);
    if (!mounted) return;
    if (detailWord == null) {
      _showWordNavigationUnavailableSnackBar();
      return;
    }

    final collector =
        widget.mutationImpactCollector ?? WordMutationImpactCollector();
    final checkpoint = collector.checkpoint;
    final result = await Navigator.push<WordDetailRouteResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WordDetailScreen(
          wordId: wordId,
          initialDisplayItem: detailWord,
          mutationImpactCollector: collector,
        ),
      ),
    );
    if (!mounted) return;
    await _handleMobileSearchTargetResult(
      mutationImpactSince(
        collector: collector,
        checkpoint: checkpoint,
        routeResult: result,
      ),
    );
  }

  Future<void> _openMobileSearchGraph(String wordId) async {
    final centerWordExists = await _repository.wordExistsForGraphNavigation(
      wordId,
    );
    if (!mounted) return;
    if (!centerWordExists) {
      _showWordNavigationUnavailableSnackBar();
      return;
    }

    final collector =
        widget.mutationImpactCollector ?? WordMutationImpactCollector();
    final checkpoint = collector.checkpoint;
    final result = await Navigator.push<WordDetailRouteResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WordGraphScreen(
          centerWordId: wordId,
          mutationImpactCollector: collector,
        ),
      ),
    );
    if (!mounted) return;
    await _handleMobileSearchTargetResult(
      mutationImpactSince(
        collector: collector,
        checkpoint: checkpoint,
        routeResult: result,
      ),
    );
  }

  Future<void> _handleMobileSearchTargetResult(
    WordMutationImpact impact,
  ) async {
    switch (resolveDetailMutationOriginAction(
      impact: impact,
      originWordId: _wordId,
    )) {
      case DetailMutationOriginAction.none:
        return;
      case DetailMutationOriginAction.refresh:
        await _refreshDetailScreenDisplayItem();
      case DetailMutationOriginAction.close:
        Navigator.pop(context, WordDetailDeletedResult(wordId: _wordId));
    }
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
      widget.mutationImpactCollector?.recordDeletedWord(_wordId);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('단어가 삭제되었습니다.')));

      Navigator.pop(context, WordDetailDeletedResult(wordId: _wordId));
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
    final isMobile = !isExplorerLargeScreenWidth(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_buildTitle()),
        actions: isMobile
            ? [
                IconButton(
                  key: const Key('mobile-global-search-action'),
                  tooltip: '검색',
                  icon: const Icon(Icons.search),
                  onPressed: _openMobileSearch,
                ),
              ]
            : null,
      ),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: WordInfoPanel(
          displayItem: _displayItem,
          onEdit: widget.showEditAction ? _openEdit : null,
          onShowGraph: _openGraph,
          onDelete: _confirmDelete,
          isDeleting: _isDeleting,
          showItemCopyActions: isMobile,
        ),
      ),
    );
  }
}
