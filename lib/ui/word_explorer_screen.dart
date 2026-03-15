/*
  word_explorer_screen.dart

  이 파일은 데스크탑/태블릿 등 넓은 화면에서 사용하는 "스플릿뷰" 화면이다.

  - 왼쪽: 단어 관계 그래프(WordGraphScreen)
  - 오른쪽: 선택된 단어의 상세 정보 패널

  목표:
  - 그래프와 상세를 동시에 보며 탐색(Obsidian 스타일)
*/

import 'package:flutter/material.dart';
import '../database/database_service.dart';
import '../data/models/word.dart';
import 'word_detail_screen.dart';
import 'word_edit_screen.dart';
import 'word_graph_screen.dart';
import 'word_info_panel.dart';

/// WordExplorerScreen
/// - 초기 단어(Map)를 받아서:
///   1) 중심 단어(Word)로 그래프 표시
///   2) 상세 패널에는 Map 전체 컬럼을 표시
class WordExplorerScreen extends StatefulWidget {
  /// 상세 패널을 위해 WORD_TABLE 행(Map)을 그대로 받는다.
  final Map<String, dynamic> initialWordMap;

  const WordExplorerScreen({super.key, required this.initialWordMap});

  @override
  State<WordExplorerScreen> createState() => _WordExplorerScreenState();
}

class _WordExplorerScreenState extends State<WordExplorerScreen> {
  /// 현재 그래프의 중심 단어
  late Word _centerWord;

  /// 오른쪽 상세 패널에 표시할 단어(Map)
  Map<String, dynamic>? _selectedWordMap;

  /// 같은 중심 단어 id에서도 그래프를 다시 생성하기 위한 revision 값
  int _graphRevision = 0;

  /// 상세 로딩 상태
  bool _isDetailLoading = false;

  /// 상세 로딩 에러 메시지
  String? _detailError;

  @override
  void initState() {
    super.initState();
    _centerWord = Word.fromMap(widget.initialWordMap);
    _selectedWordMap = widget.initialWordMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reshet - 탐색')),
      body: Row(
        children: [
          // ✅ 왼쪽(그래프)
          Expanded(
            flex: 3,
            child: WordGraphScreen(
              key: ValueKey('${_centerWord.id}-$_graphRevision'),
              centerWord: _centerWord,
              // 스플릿뷰에서는 push 탐색 대신 "선택 콜백"을 사용
              onSelectWord: (word) async {
                await _selectWord(word);
              },
              onChangeCenterWord: (word) async {
                await _selectWord(word, changeCenterWord: true);
              },
            ),
          ),

          // ✅ 구분선
          const VerticalDivider(width: 1),

          // ✅ 오른쪽(상세 패널)
          Expanded(flex: 2, child: _buildDetailPanel()),
        ],
      ),
    );
  }

  /// 그래프에서 선택된 단어를 오른쪽 상세 패널에 반영한다.
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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailError = '상세 정보 로딩 실패: $e';
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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailError = '상세 정보 로딩 실패: $e';
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
