import 'package:flutter/material.dart';

import '../data/models/word.dart';
import '../data/repositories/word_repository.dart';
import '../domain/word/word_detail_like_display_item.dart';
import 'word_detail_screen.dart';
import 'word_edit_screen.dart';
import 'word_graph_screen.dart';
import 'word_info_panel.dart';
import 'word_navigation_history.dart';

class _ExplorerHistorySnapshot {
  final Word centerWord;
  final String? selectedWordId;

  const _ExplorerHistorySnapshot({
    required this.centerWord,
    required this.selectedWordId,
  });
}

class WordExplorerScreen extends StatefulWidget {
  final String initialWordId;

  const WordExplorerScreen({super.key, required this.initialWordId});

  @override
  State<WordExplorerScreen> createState() => _WordExplorerScreenState();
}

class _WordExplorerScreenState extends State<WordExplorerScreen> {
  final WordRepository _repository = WordRepository();

  late Word _centerWord;
  String? _selectedWordId;
  WordDetailLikeDisplayItem? _selectedWordDisplayItem;
  int _graphRevision = 0;
  bool _isDetailLoading = false;
  String? _detailError;
  String? _detailUnavailableMessage;
  WordNavigationHistoryEntry<_ExplorerHistorySnapshot>?
  _availablePreviousHistoryEntry;
  WordNavigationHistoryEntry<_ExplorerHistorySnapshot>?
  _availableNextHistoryEntry;
  int _historyNavigationValidationToken = 0;

  final WordNavigationHistoryController<_ExplorerHistorySnapshot> _history =
      WordNavigationHistoryController<_ExplorerHistorySnapshot>();

  @override
  void initState() {
    super.initState();
    _centerWord = Word(id: widget.initialWordId.trim());
    _selectedWordId = null;
    _selectedWordDisplayItem = null;
    _isDetailLoading = true;
    _history.reset(
      _createHistoryEntry(centerWord: _centerWord, selectedWordId: null),
    );
    _refreshHistoryNavigationAvailability();
    _initializeExplorerBootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('탐색')),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: WordGraphScreen(
              key: ValueKey(_graphRevision),
              centerWord: _centerWord,
              selectedWordId: _selectedWordId,
              appBarActionPrefix: _buildHistoryActions(),
              onSelectWord: (word) async {
                await _selectWord(word);
              },
              onClearSelection: _clearSelectedWordPanel,
              onChangeCenterWord: (word) async {
                await _selectWord(word, changeCenterWord: true);
              },
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(flex: 2, child: _buildDetailPanel()),
        ],
      ),
    );
  }

  Future<void> _selectWord(Word word, {bool changeCenterWord = false}) async {
    setState(() {
      if (changeCenterWord) {
        _centerWord = word;
      }
      _isDetailLoading = true;
      _detailError = null;
      _detailUnavailableMessage = null;
    });

    try {
      final selectedDisplayItem = await _loadSplitViewDisplayItem(word.id);

      if (!mounted) return;

      final resolvedSelectedWordId = selectedDisplayItem == null
          ? null
          : word.id.trim();
      setState(() {
        _selectedWordId = resolvedSelectedWordId;
        _selectedWordDisplayItem = selectedDisplayItem;
        _isDetailLoading = false;
        _detailUnavailableMessage = selectedDisplayItem == null
            ? '선택한 단어의 상세 정보를 찾을 수 없습니다.'
            : null;
        if (changeCenterWord) {
          _pushHistoryEntry(
            centerWord: _centerWord,
            selectedWordId: resolvedSelectedWordId,
          );
        } else {
          _replaceCurrentHistoryEntry(
            centerWord: _centerWord,
            selectedWordId: resolvedSelectedWordId,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _detailError = '상세 정보를 불러오지 못했습니다: $e';
        _isDetailLoading = false;
        _detailUnavailableMessage = null;
      });
    }
  }

  Future<WordDetailLikeDisplayItem?> _loadSplitViewDisplayItem(
    String wordId,
  ) async {
    return _repository.getWordDetailLikeDisplayItemByIdForSplitView(wordId);
  }

  Future<void> _initializeExplorerBootstrap() async {
    final initialWordId = widget.initialWordId.trim();
    if (initialWordId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _detailError = '탐색할 단어 ID가 비어 있습니다.';
        _isDetailLoading = false;
        _detailUnavailableMessage = null;
      });
      return;
    }

    try {
      final centerWordMap = await _repository
          .getWordMapByIdForGraphCenterSingleWord(initialWordId);
      final selectedDisplayItem = await _loadSplitViewDisplayItem(
        initialWordId,
      );
      if (!mounted) return;

      final resolvedCenterWord = _resolveBootstrapCenterWord(
        wordId: initialWordId,
        centerWordMap: centerWordMap,
        selectedDisplayItem: selectedDisplayItem,
      );
      final resolvedSelectedWordId = selectedDisplayItem == null
          ? null
          : initialWordId;

      setState(() {
        _centerWord = resolvedCenterWord;
        _selectedWordId = resolvedSelectedWordId;
        _selectedWordDisplayItem = selectedDisplayItem;
        _isDetailLoading = false;
        _detailError = null;
        _detailUnavailableMessage = selectedDisplayItem == null
            ? '?좏깮???⑥뼱???곸꽭 ?뺣낫瑜?李얠쓣 ???놁뒿?덈떎.'
            : null;
      });
      _replaceCurrentHistoryEntry(
        centerWord: resolvedCenterWord,
        selectedWordId: resolvedSelectedWordId,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _detailError = '탐색 초기 정보를 불러오지 못했습니다. $e';
        _isDetailLoading = false;
        _detailUnavailableMessage = null;
      });
    }
  }

  Word _resolveBootstrapCenterWord({
    required String wordId,
    required Map<String, dynamic>? centerWordMap,
    required WordDetailLikeDisplayItem? selectedDisplayItem,
  }) {
    if (centerWordMap != null) {
      return Word.fromMap(centerWordMap);
    }

    if (selectedDisplayItem == null) {
      return Word(id: wordId);
    }

    return _buildFallbackWordFromDisplayItem(
      wordId: wordId,
      displayItem: selectedDisplayItem,
    );
  }

  Future<void> _refreshSelectedWord({
    required String wordId,
    bool syncCenterWord = false,
    bool refreshGraphIfChanged = false,
  }) async {
    final previousDisplayItem = _selectedWordDisplayItem;

    setState(() {
      _isDetailLoading = true;
      _detailError = null;
      _detailUnavailableMessage = null;
    });

    try {
      final refreshedDisplayItem = await _loadSplitViewDisplayItem(wordId);
      final resolvedSelectedWordId = refreshedDisplayItem == null
          ? null
          : wordId.trim();
      final hasChanged =
          previousDisplayItem != refreshedDisplayItem ||
          _selectedWordId != resolvedSelectedWordId;

      if (!mounted) return;

      setState(() {
        _selectedWordId = resolvedSelectedWordId;
        _selectedWordDisplayItem = refreshedDisplayItem;
        _detailUnavailableMessage = refreshedDisplayItem == null
            ? '선택한 단어의 상세 정보를 찾을 수 없습니다.'
            : null;
        if (syncCenterWord && refreshedDisplayItem != null) {
          _centerWord = _buildFallbackWordFromDisplayItem(
            wordId: wordId,
            displayItem: refreshedDisplayItem,
          );
        }
        if (refreshGraphIfChanged && hasChanged) {
          _graphRevision++;
        }
        _isDetailLoading = false;
        _replaceCurrentHistoryEntry(
          centerWord: _centerWord,
          selectedWordId: _selectedWordId,
        );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _detailError = '상세 정보를 불러오지 못했습니다: $e';
        _isDetailLoading = false;
        _detailUnavailableMessage = null;
      });
    }
  }

  Future<void> _openEditSelectedWord() async {
    final selectedWordId = _selectedWordId;
    if (selectedWordId == null) return;

    final editableWord = await _repository.getWordMapByIdForExplorerSingleWord(
      selectedWordId,
    );
    if (!mounted) return;
    if (editableWord == null) {
      _showWordNavigationUnavailableSnackBar();
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => WordEditScreen(word: editableWord)),
    );

    if (result == null || !mounted) return;

    await _refreshSelectedWord(
      wordId: selectedWordId,
      syncCenterWord: _centerWord.id == selectedWordId,
      refreshGraphIfChanged: true,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('단어 정보가 수정되었습니다.')));
  }

  Future<void> _openSelectedWordDetail() async {
    final selectedWordId = _selectedWordId;
    final selectedDisplayItem = _selectedWordDisplayItem;
    if (selectedWordId == null || selectedDisplayItem == null) return;

    final wasCenterWord = _centerWord.id == selectedWordId;

    final wasDeleted = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (_) => WordDetailScreen(
          wordId: selectedWordId,
          initialDisplayItem: selectedDisplayItem,
        ),
      ),
    );

    if (!mounted || selectedWordId.isEmpty) return;

    if (wasDeleted == true) {
      await _handleDeletedSelectedWord(wasCenterWord: wasCenterWord);
      return;
    }

    await _refreshSelectedWord(
      wordId: selectedWordId,
      syncCenterWord: wasCenterWord,
      refreshGraphIfChanged: true,
    );
  }

  void _showWordNavigationUnavailableSnackBar() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('단어 정보를 찾을 수 없습니다.')));
  }

  Future<void> _handleDeletedSelectedWord({required bool wasCenterWord}) async {
    if (!wasCenterWord) {
      _clearSelectedWordPanel(refreshGraph: true);
      return;
    }

    final previousEntry = _history.previousEntry;
    if (await _isHistoryEntryAvailable(previousEntry)) {
      final entry = _history.goBack();
      if (entry != null) {
        _applyHistoryEntry(entry);
        return;
      }
    }

    final nextEntry = _history.nextEntry;
    if (await _isHistoryEntryAvailable(nextEntry)) {
      final entry = _history.goForward();
      if (entry != null) {
        _applyHistoryEntry(entry);
        return;
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _clearSelectedWordPanel({bool refreshGraph = false}) {
    if (_selectedWordDisplayItem == null &&
        !_isDetailLoading &&
        _detailError == null &&
        _detailUnavailableMessage == null &&
        !refreshGraph) {
      return;
    }

    setState(() {
      _selectedWordId = null;
      _selectedWordDisplayItem = null;
      _isDetailLoading = false;
      _detailError = null;
      _detailUnavailableMessage = null;
      if (refreshGraph) {
        _graphRevision++;
      }
      _replaceCurrentHistoryEntry(
        centerWord: _centerWord,
        selectedWordId: null,
      );
    });
  }

  List<Widget> _buildHistoryActions() {
    return [
      IconButton(
        tooltip: _buildHistoryTooltip('뒤로', _availablePreviousHistoryEntry),
        onPressed: _availablePreviousHistoryEntry != null
            ? _goBackInHistory
            : null,
        icon: const Icon(Icons.arrow_back),
      ),
      IconButton(
        tooltip: _buildHistoryTooltip('앞으로', _availableNextHistoryEntry),
        onPressed: _availableNextHistoryEntry != null
            ? _goForwardInHistory
            : null,
        icon: const Icon(Icons.arrow_forward),
      ),
    ];
  }

  Future<void> _goBackInHistory() async {
    final previousEntry = _history.previousEntry;
    if (!await _isHistoryEntryAvailable(previousEntry)) {
      await _refreshHistoryNavigationAvailability();
      return;
    }

    final entry = _history.goBack();
    if (entry == null) {
      await _refreshHistoryNavigationAvailability();
      return;
    }

    _applyHistoryEntry(entry);
  }

  Future<void> _goForwardInHistory() async {
    final nextEntry = _history.nextEntry;
    if (!await _isHistoryEntryAvailable(nextEntry)) {
      await _refreshHistoryNavigationAvailability();
      return;
    }

    final entry = _history.goForward();
    if (entry == null) {
      await _refreshHistoryNavigationAvailability();
      return;
    }

    _applyHistoryEntry(entry);
  }

  void _applyHistoryEntry(
    WordNavigationHistoryEntry<_ExplorerHistorySnapshot> entry,
  ) {
    final snapshot = entry.payload;

    setState(() {
      _centerWord = snapshot.centerWord;
      _selectedWordId = null;
      _selectedWordDisplayItem = null;
      _detailError = null;
      _isDetailLoading = false;
      _detailUnavailableMessage = null;
    });
    _refreshHistoryNavigationAvailability();
  }

  void _pushHistoryEntry({
    required Word centerWord,
    required String? selectedWordId,
  }) {
    final entry = _createHistoryEntry(
      centerWord: centerWord,
      selectedWordId: selectedWordId,
    );
    final currentEntry = _history.currentEntry;

    if (currentEntry != null &&
        _isSameHistoryLocation(currentEntry.payload, entry.payload)) {
      _history.replaceCurrent(entry);
      _refreshHistoryNavigationAvailability();
      return;
    }

    _history.push(entry);
    _refreshHistoryNavigationAvailability();
  }

  void _replaceCurrentHistoryEntry({
    required Word centerWord,
    required String? selectedWordId,
  }) {
    _history.replaceCurrent(
      _createHistoryEntry(
        centerWord: centerWord,
        selectedWordId: selectedWordId,
      ),
    );
    _refreshHistoryNavigationAvailability();
  }

  Future<void> _refreshHistoryNavigationAvailability() async {
    final previousEntry = _history.previousEntry;
    final nextEntry = _history.nextEntry;
    final validationToken = ++_historyNavigationValidationToken;

    try {
      final existingWordIds = await _loadExistingHistoryWordIds([
        previousEntry,
        nextEntry,
      ]);

      if (!mounted || validationToken != _historyNavigationValidationToken) {
        return;
      }

      final resolvedPreviousEntry = _resolveAvailableHistoryEntry(
        previousEntry,
        existingWordIds,
      );
      final resolvedNextEntry = _resolveAvailableHistoryEntry(
        nextEntry,
        existingWordIds,
      );

      if (_availablePreviousHistoryEntry == resolvedPreviousEntry &&
          _availableNextHistoryEntry == resolvedNextEntry) {
        return;
      }

      setState(() {
        _availablePreviousHistoryEntry = resolvedPreviousEntry;
        _availableNextHistoryEntry = resolvedNextEntry;
      });
    } catch (_) {
      if (!mounted || validationToken != _historyNavigationValidationToken) {
        return;
      }

      setState(() {
        _availablePreviousHistoryEntry = null;
        _availableNextHistoryEntry = null;
      });
    }
  }

  Future<Set<String>> _loadExistingHistoryWordIds(
    Iterable<WordNavigationHistoryEntry<_ExplorerHistorySnapshot>?> entries,
  ) async {
    final candidateIds = <String>[];
    final seenIds = <String>{};

    for (final entry in entries) {
      final wordId = entry?.wordId.trim() ?? '';
      if (wordId.isEmpty || !seenIds.add(wordId)) {
        continue;
      }
      candidateIds.add(wordId);
    }

    if (candidateIds.isEmpty) {
      return const <String>{};
    }

    return _repository.probeExistingWordIdsForExplorerHistory(candidateIds);
  }

  WordNavigationHistoryEntry<_ExplorerHistorySnapshot>?
  _resolveAvailableHistoryEntry(
    WordNavigationHistoryEntry<_ExplorerHistorySnapshot>? entry,
    Set<String> existingWordIds,
  ) {
    if (entry == null) {
      return null;
    }

    final wordId = entry.wordId.trim();
    if (wordId.isEmpty || !existingWordIds.contains(wordId)) {
      return null;
    }

    return entry;
  }

  Future<bool> _isHistoryEntryAvailable(
    WordNavigationHistoryEntry<_ExplorerHistorySnapshot>? entry,
  ) async {
    final wordId = entry?.wordId.trim() ?? '';
    if (wordId.isEmpty) {
      return false;
    }

    final existingWordIds = await _repository
        .probeExistingWordIdsForExplorerHistory([wordId]);
    return existingWordIds.contains(wordId);
  }

  WordNavigationHistoryEntry<_ExplorerHistorySnapshot> _createHistoryEntry({
    required Word centerWord,
    required String? selectedWordId,
  }) {
    final centerWordId = centerWord.id.trim();
    final fallbackSpelling = (centerWord.spelling1 ?? '').trim();
    final representativeSpelling = fallbackSpelling.isNotEmpty
        ? fallbackSpelling
        : centerWordId;
    final strongNumber = formatWordDisplayStrong(
      (centerWord.strongNumber ?? '').trim(),
    );

    return WordNavigationHistoryEntry<_ExplorerHistorySnapshot>(
      wordId: centerWordId,
      representativeSpelling: representativeSpelling,
      strongNumber: strongNumber,
      payload: _ExplorerHistorySnapshot(
        centerWord: centerWord,
        selectedWordId: selectedWordId,
      ),
    );
  }

  bool _isSameHistoryLocation(
    _ExplorerHistorySnapshot left,
    _ExplorerHistorySnapshot right,
  ) {
    return left.centerWord.id == right.centerWord.id &&
        left.selectedWordId == right.selectedWordId;
  }

  String _buildHistoryTooltip(
    String label,
    WordNavigationHistoryEntry<_ExplorerHistorySnapshot>? entry,
  ) {
    if (entry == null) {
      return '$label: 기록 없음';
    }

    final transliteration = (entry.payload.centerWord.transliteration1 ?? '')
        .trim();
    final parts = <String>[
      if (entry.representativeSpelling.trim().isNotEmpty)
        entry.representativeSpelling.trim(),
      if (transliteration.isNotEmpty) transliteration,
      if (entry.strongNumber.trim().isNotEmpty) entry.strongNumber.trim(),
    ];

    if (parts.isEmpty) {
      return '$label: 중심';
    }

    return '$label: 중심\n${parts.join('\n')}';
  }

  Word _buildFallbackWordFromDisplayItem({
    required String wordId,
    required WordDetailLikeDisplayItem displayItem,
  }) {
    return Word(
      id: wordId.trim(),
      language: displayItem.language,
      strongNumber: displayItem.displayStrongNumber,
      spelling1: displayItem.representativeSpelling,
      transliteration1: displayItem.transliterations.isEmpty
          ? null
          : displayItem.transliterations.first,
      pronunciation1: displayItem.pronunciations.isEmpty
          ? null
          : displayItem.pronunciations.first,
      meaning1: displayItem.meanings.isEmpty
          ? null
          : displayItem.meanings.first,
    );
  }

  Widget _buildDetailPanel() {
    if (_isDetailLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_detailError != null) {
      return Center(child: Text(_detailError!));
    }

    final displayItem = _selectedWordDisplayItem;
    if (displayItem == null) {
      final detailUnavailableMessage = _detailUnavailableMessage;
      if (detailUnavailableMessage != null) {
        return Center(child: Text(detailUnavailableMessage));
      }
      return _buildNoSelectionDetailPanel();
    }

    return WordInfoPanel(
      displayItem: displayItem,
      onEdit: _openEditSelectedWord,
      onOpenDetail: _openSelectedWordDetail,
    );
  }

  Widget _buildNoSelectionDetailPanel() {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              '단어를 선택하세요',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '그래프에서 노드를 탭하면 상세 정보를 볼 수 있습니다',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
