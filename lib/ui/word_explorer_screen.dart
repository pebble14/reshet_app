import 'package:flutter/material.dart';

import '../data/repositories/word_repository.dart';
import '../data/models/word.dart';
import 'word_detail_screen.dart';
import 'word_edit_screen.dart';
import 'word_graph_screen.dart';
import 'word_info_panel.dart';
import 'word_navigation_history.dart';

class _ExplorerHistorySnapshot {
  final Word centerWord;
  final Map<String, dynamic>? selectedWordMap;

  const _ExplorerHistorySnapshot({
    required this.centerWord,
    required this.selectedWordMap,
  });
}

class WordExplorerScreen extends StatefulWidget {
  final Map<String, dynamic> initialWordMap;

  const WordExplorerScreen({super.key, required this.initialWordMap});

  @override
  State<WordExplorerScreen> createState() => _WordExplorerScreenState();
}

class _WordExplorerScreenState extends State<WordExplorerScreen> {
  final WordRepository _repository = WordRepository();

  late Word _centerWord;
  Map<String, dynamic>? _selectedWordMap;
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
    _centerWord = Word.fromMap(widget.initialWordMap);
    _selectedWordMap = Map<String, dynamic>.from(widget.initialWordMap);
    _history.reset(
      _createHistoryEntry(
        centerWord: _centerWord,
        selectedWordMap: _selectedWordMap,
      ),
    );
    _refreshHistoryNavigationAvailability();
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
      final selectedWordMap = await _loadSplitViewWordMap(word.id);

      if (!mounted) return;

      setState(() {
        _selectedWordMap = selectedWordMap;
        _isDetailLoading = false;
        _detailUnavailableMessage = selectedWordMap == null
            ? '선택한 단어의 상세 정보를 찾을 수 없습니다.'
            : null;
        if (changeCenterWord) {
          _pushHistoryEntry(
            centerWord: _centerWord,
            selectedWordMap: selectedWordMap,
          );
        } else {
          _replaceCurrentHistoryEntry(
            centerWord: _centerWord,
            selectedWordMap: selectedWordMap,
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

  Future<Map<String, dynamic>?> _loadSplitViewWordMap(String wordId) async {
    return _repository.getWordMapByIdForSplitViewSingleWord(wordId);
  }

  Future<void> _refreshSelectedWord({
    required String wordId,
    bool syncCenterWord = false,
    bool refreshGraphIfChanged = false,
  }) async {
    final previousWordMap = _selectedWordMap == null
        ? null
        : Map<String, dynamic>.from(_selectedWordMap!);

    setState(() {
      _isDetailLoading = true;
      _detailError = null;
      _detailUnavailableMessage = null;
    });

    try {
      final refreshedWordMap = await _loadSplitViewWordMap(wordId);
      final hasChanged = !_wordMapsEqual(previousWordMap, refreshedWordMap);

      if (!mounted) return;

      setState(() {
        _selectedWordMap = refreshedWordMap;
        _detailUnavailableMessage = refreshedWordMap == null
            ? '선택한 단어의 상세 정보를 찾을 수 없습니다.'
            : null;
        if (syncCenterWord && refreshedWordMap != null) {
          _centerWord = Word.fromMap(refreshedWordMap);
        }
        if (refreshGraphIfChanged && hasChanged) {
          _graphRevision++;
        }
        _isDetailLoading = false;
        _replaceCurrentHistoryEntry(
          centerWord: _centerWord,
          selectedWordMap: _selectedWordMap,
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
    final wordMap = _selectedWordMap;
    if (wordMap == null) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => WordEditScreen(word: wordMap)),
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedWordMap = Map<String, dynamic>.from(result);
      _detailError = null;
      _detailUnavailableMessage = null;

      if (_centerWord.id == result['id'].toString()) {
        _centerWord = Word.fromMap(result);
      }
      _graphRevision++;
      _replaceCurrentHistoryEntry(
        centerWord: _centerWord,
        selectedWordMap: _selectedWordMap,
      );
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('단어 정보가 수정되었습니다.')));
  }

  Future<void> _openSelectedWordDetail() async {
    final wordMap = _selectedWordMap;
    if (wordMap == null) return;

    final selectedWordId = (wordMap['id'] ?? '').toString();
    final wasCenterWord = _centerWord.id == selectedWordId;

    final wasDeleted = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(builder: (_) => WordDetailScreen(word: wordMap)),
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

  String? get _selectedWordId {
    final wordId = (_selectedWordMap?['id'] ?? '').toString().trim();
    if (wordId.isEmpty) {
      return null;
    }
    return wordId;
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
    if (_selectedWordMap == null &&
        !_isDetailLoading &&
        _detailError == null &&
        _detailUnavailableMessage == null &&
        !refreshGraph) {
      return;
    }

    setState(() {
      _selectedWordMap = null;
      _isDetailLoading = false;
      _detailError = null;
      _detailUnavailableMessage = null;
      if (refreshGraph) {
        _graphRevision++;
      }
      _replaceCurrentHistoryEntry(
        centerWord: _centerWord,
        selectedWordMap: null,
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
      _selectedWordMap = null;
      _detailError = null;
      _isDetailLoading = false;
      _detailUnavailableMessage = null;
    });
    _refreshHistoryNavigationAvailability();
  }

  void _pushHistoryEntry({
    required Word centerWord,
    required Map<String, dynamic>? selectedWordMap,
  }) {
    final entry = _createHistoryEntry(
      centerWord: centerWord,
      selectedWordMap: selectedWordMap,
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
    required Map<String, dynamic>? selectedWordMap,
  }) {
    _history.replaceCurrent(
      _createHistoryEntry(
        centerWord: centerWord,
        selectedWordMap: selectedWordMap,
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

    final rows = await _repository.getWordsByIds(candidateIds);
    return rows
        .map((row) => (row['id'] ?? '').toString().trim())
        .where((wordId) => wordId.isNotEmpty)
        .toSet();
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

    final wordMap = await _repository.getWordMapByIdForExplorerSingleWord(
      wordId,
    );
    return wordMap != null;
  }

  WordNavigationHistoryEntry<_ExplorerHistorySnapshot> _createHistoryEntry({
    required Word centerWord,
    required Map<String, dynamic>? selectedWordMap,
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
        selectedWordMap: _cloneWordMap(selectedWordMap),
      ),
    );
  }

  Map<String, dynamic>? _cloneWordMap(Map<String, dynamic>? wordMap) {
    if (wordMap == null) {
      return null;
    }

    return Map<String, dynamic>.from(wordMap);
  }

  bool _isSameHistoryLocation(
    _ExplorerHistorySnapshot left,
    _ExplorerHistorySnapshot right,
  ) {
    return left.centerWord.id == right.centerWord.id &&
        _historyWordId(left.selectedWordMap) ==
            _historyWordId(right.selectedWordMap);
  }

  String _historyWordId(Map<String, dynamic>? wordMap) {
    return (wordMap?['id'] ?? '').toString().trim();
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

  bool _wordMapsEqual(Map<String, dynamic>? left, Map<String, dynamic>? right) {
    if (identical(left, right)) {
      return true;
    }

    if (left == null || right == null) {
      return left == right;
    }

    if (left.length != right.length) {
      return false;
    }

    for (final key in left.keys) {
      if (!right.containsKey(key) || left[key] != right[key]) {
        return false;
      }
    }

    return true;
  }

  Widget _buildDetailPanel() {
    if (_isDetailLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_detailError != null) {
      return Center(child: Text(_detailError!));
    }

    final wordMap = _selectedWordMap;
    if (wordMap == null) {
      final detailUnavailableMessage = _detailUnavailableMessage;
      if (detailUnavailableMessage != null) {
        return Center(child: Text(detailUnavailableMessage));
      }
      return _buildNoSelectionDetailPanel();
    }

    return WordInfoPanel(
      wordMap: wordMap,
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
