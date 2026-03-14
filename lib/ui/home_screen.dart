/*
  home_screen.dart

  이 파일은 Reshet 앱의 메인 화면을 정의한다.
  현재는 기본 구조만 구성하고,
  이후 데이터베이스 연결 및 기능을 점진적으로 추가할 예정이다.
*/

import 'package:flutter/material.dart';
import '../database/database_service.dart';
import 'word_detail_screen.dart';
import '../data/models/word.dart';
import '../data/repositories/word_repository.dart';
import 'word_graph_cache.dart';
import 'word_graph_screen.dart';
import 'word_explorer_screen.dart';

/*
  HomeScreen 클래스

  이 화면은 앱 실행 시 가장 먼저 보이는 메인 화면이다.
  StatefulWidget으로 만든 이유:

  - 나중에 데이터베이스 연결
  - 화면 갱신
  - 상태 변화 처리

  등을 대비하기 위함이다.
*/
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// HomeScreen 위젯의 상태(State)를 관리하는 클래스
/// - 앱 시작 시 데이터베이스 초기화 수행
/// - DB 준비 완료 전까지 로딩 화면 표시
class _HomeScreenState extends State<HomeScreen> {
  /// 데이터베이스 준비 상태를 나타내는 변수
  /// true  → 로딩 중
  /// false → 준비 완료
  bool _isLoading = true;
  String _dbMessage = '';

  /// 홈 화면에서 사용할 Repository
  final WordRepository _repository = WordRepository();

  /// 검색 입력 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  /// 홈 리스트에 표시할 단어 목록 Future
  Future<List<Map<String, dynamic>>>? _wordsFuture;

  Future<List<Map<String, dynamic>>> _createWordsFuture() {
    final keyword = _searchController.text.trim();
    return keyword.isEmpty
        ? _repository.getStrongWordsMap(limit: 50)
        : _repository.searchWordsMap(keyword, limit: 200);
  }

  /// 위젯이 처음 생성될 때 1회 호출되는 생명주기 메서드
  /// 여기서 데이터베이스 초기화를 시작한다.
  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  /// 데이터베이스 초기화 및 파일 열기 수행
  /// 비동기 작업이므로 async/await 사용
  Future<void> _initializeDatabase() async {
    try {
      await DatabaseService.initialize();
      await DatabaseService.openDatabaseFile();

      _dbMessage = await DatabaseService.getTestData();

      final tables = await DatabaseService.getTableList();
      print("테이블 목록:");
      for (var table in tables) {
        print(" - $table");
      }

      // 위젯이 여전히 화면에 존재할 때만 상태 변경
      if (!mounted) return;

      // DB 준비 완료 → 로딩 종료
      setState(() {
        _isLoading = false;
        _wordsFuture = _createWordsFuture();
      });

      print('데이터베이스 연결 성공');
    } catch (e) {
      print('데이터베이스 연결 실패: $e');
    }
  }

  /// DB 초기화를 실행하기 전에 사용자에게 확인을 받는다.
  Future<void> _confirmAndResetDb() async {
    bool backup = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('데이터베이스 초기화'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '작업용 DB를 초기 상태(Seed)로 되돌립니다.\n'
                    '편집한 관계/내용이 모두 초기화됩니다.',
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: backup,
                    onChanged: (v) => setState(() => backup = v ?? true),
                    title: const Text('초기화 전에 현재 DB 백업하기'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('초기화'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    // UX: 초기화 중 로딩 표시
    setState(() => _isLoading = true);

    try {
      await DatabaseService.resetToSeed(backup: backup);
      WordGraphDataCache.clear();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _wordsFuture = _createWordsFuture();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('DB가 초기 상태로 되돌아갔습니다.')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _wordsFuture = _createWordsFuture();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('DB 초기화 실패: $e')));
    }
  }

  Future<void> _undoLastChange() async {
    setState(() => _isLoading = true);

    try {
      final repository = WordRepository();
      final undone = await repository.undoLastChange();
      if (undone) {
        WordGraphDataCache.clear();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(undone ? '최근 변경을 되돌렸습니다.' : '되돌릴 변경이 없습니다.')),
      );

      // Home 리스트 즉시 갱신
      setState(() {
        _isLoading = false;
        _wordsFuture = _createWordsFuture();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('실행 취소 실패: $e')));
    }
  }

  /// 화면을 그리는 메서드
  /// _isLoading 값에 따라 로딩 화면 또는 본문 화면 표시
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reshet'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'reset_db') {
                await _confirmAndResetDb();
              } else if (value == 'undo_last_change') {
                await _undoLastChange();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'reset_db',
                child: Text('데이터베이스 초기화(Seed로 롤백)'),
              ),
              const PopupMenuItem<String>(
                value: 'undo_last_change',
                child: Text('실행 취소'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ✅ 검색창
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: '검색 (표기1/의미/스트롱넘버)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _runSearch(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _runSearch,
                        icon: const Icon(Icons.search),
                        tooltip: '검색',
                      ),
                      IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.clear),
                        tooltip: '초기화',
                      ),
                    ],
                  ),
                ),

                // ✅ 결과 리스트
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _wordsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('에러 발생: ${snapshot.error}'));
                      }

                      final words = snapshot.data ?? [];

                      if (words.isEmpty) {
                        return const Center(child: Text('검색 결과 없음'));
                      }

                      return ListView.builder(
                        itemCount: words.length,
                        itemBuilder: (context, index) {
                          final wordMap = words[index];
                          final spelling = (wordMap['표기1'] ?? '').toString();
                          final meaning = (wordMap['의미1'] ?? '').toString();
                          final strong = (wordMap['스트롱넘버'] ?? '').toString();
                          final displaySpelling = spelling.isNotEmpty
                              ? spelling
                              : (wordMap['표기2'] ?? '').toString();
                          final titleText = strong.isNotEmpty
                              ? displaySpelling.isNotEmpty
                                    ? '$strong $displaySpelling'
                                    : strong
                              : displaySpelling;

                          return ListTile(
                            title: Text(titleText),
                            subtitle: Text(
                              meaning,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 상세
                                IconButton(
                                  icon: const Icon(Icons.article_outlined),
                                  tooltip: '상세',
                                  onPressed: () => _openWordDetail(wordMap),
                                ),
                                // 그래프
                                IconButton(
                                  icon: const Icon(Icons.hub_outlined),
                                  tooltip: '그래프',
                                  onPressed: () => _openWordGraph(wordMap),
                                ),
                              ],
                            ),
                            // 탭은 기본적으로 상세로
                            onTap: () async {
                              final width = MediaQuery.of(context).size.width;

                              // 넓은 화면(데스크탑/태블릿)에서는 스플릿뷰
                              if (width >= 900) {
                                await _openWordExplorer(wordMap);
                                return;
                              }

                              await _openWordDetail(wordMap);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// 검색 실행: 입력값으로 Repository 검색을 수행하고 리스트를 갱신한다.
  void _runSearch() {
    setState(() {
      _wordsFuture = _createWordsFuture();
    });
  }

  /// 검색어를 지우고 기본 목록으로 되돌린다.
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _wordsFuture = _createWordsFuture();
    });
  }

  /// 현재 검색 상태에 맞춰 홈 리스트 Future를 다시 만든다.
  void _refreshWords() {
    setState(() {
      _wordsFuture = _createWordsFuture();
    });
  }

  Future<void> _openWordDetail(Map<String, dynamic> wordMap) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WordDetailScreen(word: wordMap)),
    );

    if (!mounted) return;
    _refreshWords();
  }

  Future<void> _openWordExplorer(Map<String, dynamic> wordMap) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordExplorerScreen(initialWordMap: wordMap),
      ),
    );

    if (!mounted) return;
    _refreshWords();
  }

  Future<void> _openWordGraph(Map<String, dynamic> wordMap) async {
    final centerWord = Word.fromMap(wordMap);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordGraphScreen(centerWord: centerWord),
      ),
    );

    if (!mounted) return;
    _refreshWords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
