import 'package:flutter/material.dart';

import '../database/database_service.dart';
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
  late Word _centerWord;
  Map<String, dynamic>? _selectedWordMap;
  int _graphRevision = 0;
  bool _isDetailLoading = false;
  String? _detailError;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reshet - 탐색')),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: WordGraphScreen(
              key: ValueKey('${_centerWord.id}-$_graphRevision'),
              centerWord: _centerWord,
              selectedWordId: _selectedWordId,
              appBarActionPrefix: _buildHistoryActions(),
              onSelectWord: (word) async {
                await _selectWord(word);
              },
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
    });

    try {
      final selectedWordMap = await _loadWordMap(word.id);

      if (!mounted) return;

      setState(() {
        _selectedWordMap = selectedWordMap;
        _isDetailLoading = false;
        _pushHistoryEntry(
          centerWord: _centerWord,
          selectedWordMap: selectedWordMap,
        );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _detailError = '상세 정보를 불러오지 못했습니다: $e';
        _isDetailLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _loadWordMap(String wordId) async {
    final db = await DatabaseService.openDatabaseFile();
    final rows = await db.query(
      'WORD_TABLE',
      where: 'id = ?',
      whereArgs: [wordId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(rows.first);
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
    });

    try {
      final refreshedWordMap = await _loadWordMap(wordId);
      final hasChanged = !_wordMapsEqual(previousWordMap, refreshedWordMap);

      if (!mounted) return;

      setState(() {
        _selectedWordMap = refreshedWordMap;
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

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WordDetailScreen(word: wordMap)),
    );

    if (!mounted || selectedWordId.isEmpty) return;

    await _refreshSelectedWord(
      wordId: selectedWordId,
      syncCenterWord: _centerWord.id == selectedWordId,
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

  List<Widget> _buildHistoryActions() {
    return [
      IconButton(
        tooltip: _buildHistoryTooltip('뒤로', _history.previousEntry),
        onPressed: _history.canGoBack ? _goBackInHistory : null,
        icon: const Icon(Icons.arrow_back),
      ),
      IconButton(
        tooltip: _buildHistoryTooltip('앞으로', _history.nextEntry),
        onPressed: _history.canGoForward ? _goForwardInHistory : null,
        icon: const Icon(Icons.arrow_forward),
      ),
    ];
  }

  void _goBackInHistory() {
    final entry = _history.goBack();
    if (entry == null) return;
    _applyHistoryEntry(entry);
  }

  void _goForwardInHistory() {
    final entry = _history.goForward();
    if (entry == null) return;
    _applyHistoryEntry(entry);
  }

  void _applyHistoryEntry(
    WordNavigationHistoryEntry<_ExplorerHistorySnapshot> entry,
  ) {
    final snapshot = entry.payload;
    final centerChanged = _centerWord.id != snapshot.centerWord.id;

    setState(() {
      _centerWord = snapshot.centerWord;
      _selectedWordMap = _cloneWordMap(snapshot.selectedWordMap);
      _detailError = null;
      _isDetailLoading = false;

      if (centerChanged) {
        _graphRevision++;
      }
    });
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
      return;
    }

    _history.push(entry);
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
  }

  WordNavigationHistoryEntry<_ExplorerHistorySnapshot> _createHistoryEntry({
    required Word centerWord,
    required Map<String, dynamic>? selectedWordMap,
  }) {
    final fallbackSpelling = (centerWord.spelling1 ?? '').trim();
    final representativeSpelling = selectedWordMap == null
        ? (fallbackSpelling.isNotEmpty ? fallbackSpelling : centerWord.id)
        : buildWordRepresentativeSpelling(
            selectedWordMap,
            fallback: fallbackSpelling.isNotEmpty
                ? fallbackSpelling
                : centerWord.id,
          );
    final strongNumber = selectedWordMap == null
        ? formatWordDisplayStrong((centerWord.strongNumber ?? '').trim())
        : buildWordDisplayStrong(selectedWordMap);

    return WordNavigationHistoryEntry<_ExplorerHistorySnapshot>(
      wordId: (selectedWordMap?['id'] ?? centerWord.id).toString(),
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

    final parts = <String>[
      if (entry.representativeSpelling.trim().isNotEmpty)
        entry.representativeSpelling,
      if (entry.strongNumber.trim().isNotEmpty) entry.strongNumber,
      if (entry.wordId.trim().isNotEmpty) entry.wordId,
    ];

    return '$label: ${parts.join(' / ')}';
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
      return const Center(child: Text('상세 정보가 없습니다.'));
    }

    return WordInfoPanel(
      wordMap: wordMap,
      onEdit: _openEditSelectedWord,
      onOpenDetail: _openSelectedWordDetail,
    );
  }
}
