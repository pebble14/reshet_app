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
import 'word_graph_screen.dart';

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
              key: ValueKey(_centerWord.id),
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
      final db = await DatabaseService.openDatabaseFile();
      final rows = await db.query(
        'WORD_TABLE',
        where: 'id = ?',
        whereArgs: [word.id],
        limit: 1,
      );

      if (!mounted) return;

      setState(() {
        _selectedWordMap = rows.isNotEmpty ? rows.first : null;
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

    // ✅ Scaffold 없이 "패널"로만 표시
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          (wordMap['표기1'] ?? '').toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          (wordMap['의미1'] ?? '').toString(),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        const Divider(),

        ...wordMap.entries.map((entry) {
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
      ],
    );
  }
}
