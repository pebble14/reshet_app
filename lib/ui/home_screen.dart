/*
  home_screen.dart

  이 파일은 Reshet 앱의 메인 화면을 정의한다.
  현재는 기본 구조만 구성하고,
  이후 데이터베이스 연결 및 기능을 점진적으로 추가할 예정이다.
*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/expression/home_word_display_summary.dart';
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

  static const double _defaultStrongListItemExtent = 56.0;
  static const Duration _strongJumpDebounceDuration = Duration(
    milliseconds: 300,
  );
  static const String _aboutVersion = '1.0.0+1';
  static const String _firstRunBrandIntroSeenKey =
      'first_run_brand_intro_seen';

  final ScrollController _listScrollController = ScrollController();
  Timer? _strongJumpDebounceTimer;

  /// 홈 리스트에 표시할 단어 목록 Future
  Future<List<Map<String, dynamic>>>? _wordsFuture;
  List<Map<String, dynamic>> _currentWords = const [];
  bool _currentWordsAreDefaultStrongList = false;
  bool _isShowingDefaultStrongList = true;

  Future<List<Map<String, dynamic>>> _createWordsFuture() async {
    if (_isShowingDefaultStrongList) {
      return _repository.getStrongWordsMap();
    }

    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      return _repository.getStrongWordsMap();
    }

    if (_isStrongJumpInput(keyword)) {
      final exactMatches = await _repository.searchStrongExactMap(
        keyword,
        limit: 200,
      );
      if (exactMatches.isNotEmpty) {
        return exactMatches;
      }
    }

    return _repository.searchWordsMap(keyword, limit: 200);
  }

  String _readFirstNonEmptyValue(
    Map<String, dynamic> wordMap,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = (wordMap[key] ?? '').toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _formatDisplayStrong(String strong) {
    final trimmed = strong.trim();
    final match = RegExp(r'^([A-Za-z])(\d+)$').firstMatch(trimmed);
    if (match == null) {
      return trimmed;
    }

    final prefix = match.group(1)!.toUpperCase();
    final numericPart = int.tryParse(match.group(2)!);
    if (numericPart == null) {
      return trimmed;
    }
    return '$prefix$numericPart';
  }

  String _normalizeStrongInput(String input) {
    final trimmed = input.trim();
    final match = RegExp(r'^([HhGg])(\d+)$').firstMatch(trimmed);
    if (match == null) {
      return trimmed;
    }
    return _formatDisplayStrong(
      '${match.group(1)!.toUpperCase()}${match.group(2)!}',
    );
  }

  bool _isStrongJumpInput(String input) {
    return RegExp(r'^[HhGg]\d+$').hasMatch(input.trim());
  }

  int _findStrongIndex(
    List<Map<String, dynamic>> words,
    String normalizedStrong,
  ) {
    for (var index = 0; index < words.length; index++) {
      final displayStrong = _formatDisplayStrong(
        (words[index]['스트롱넘버'] ?? '').toString(),
      );
      if (displayStrong == normalizedStrong) {
        return index;
      }
    }
    return -1;
  }

  void _showStrongJumpNotFoundSnackBar(String normalizedStrong) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$normalizedStrong 항목을 찾을 수 없습니다.'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  double _calculateDefaultStrongOffset(int targetIndex) {
    return targetIndex * _defaultStrongListItemExtent;
  }

  void _scrollToDefaultStrongIndex(int targetIndex) {
    void animateToIndex() {
      if (!_listScrollController.hasClients) {
        return;
      }

      final maxScrollExtent = _listScrollController.position.maxScrollExtent;
      final targetOffset = _calculateDefaultStrongOffset(targetIndex);
      final clampedOffset = targetOffset.clamp(0.0, maxScrollExtent).toDouble();

      _listScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
      );
    }

    if (_listScrollController.hasClients) {
      animateToIndex();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      animateToIndex();
    });
  }

  void _cancelPendingStrongJump() {
    _strongJumpDebounceTimer?.cancel();
    _strongJumpDebounceTimer = null;
  }

  bool _canRunAutoStrongJump(String input) {
    return _isShowingDefaultStrongList &&
        _currentWordsAreDefaultStrongList &&
        _currentWords.isNotEmpty &&
        _isStrongJumpInput(input);
  }

  void _handleSearchChanged(String value) {
    _cancelPendingStrongJump();

    if (!_isShowingDefaultStrongList) {
      return;
    }

    final scheduledInput = value.trim();
    if (!_isStrongJumpInput(scheduledInput)) {
      return;
    }

    _strongJumpDebounceTimer = Timer(_strongJumpDebounceDuration, () {
      _strongJumpDebounceTimer = null;

      if (!mounted) {
        return;
      }

      final currentInput = _searchController.text.trim();
      if (currentInput != scheduledInput) {
        return;
      }

      if (!_canRunAutoStrongJump(currentInput)) {
        return;
      }

      final normalizedStrong = _normalizeStrongInput(currentInput);
      _jumpToStrongInDefaultList(
        normalizedStrong,
        showNotFoundFeedback: false,
      );
    });
  }

  void _jumpToStrongInDefaultList(
    String normalizedStrong, {
    bool showNotFoundFeedback = true,
  }) {
    final targetIndex = _findStrongIndex(_currentWords, normalizedStrong);
    if (targetIndex < 0) {
      if (showNotFoundFeedback) {
        _showStrongJumpNotFoundSnackBar(normalizedStrong);
      }
      return;
    }

    _scrollToDefaultStrongIndex(targetIndex);
  }

  String _buildDefaultStrongListTitle({
    required String strong,
    required HomeWordDisplaySummary summary,
  }) {
    return buildStrongListTitle(strong: strong, summary: summary);
  }

  InlineSpan _buildWordTitle({
    required String strong,
    required HomeWordDisplaySummary summary,
  }) {
    return TextSpan(
      text: buildSearchResultTitle(strong: strong, summary: summary),
    );
  }

  String _buildWordSubtitle(Map<String, dynamic> wordMap) {
    return _readFirstNonEmptyValue(wordMap, ['의미1', '의미']);
  }

  /// 위젯이 처음 생성될 때 1회 호출되는 생명주기 메서드
  /// 여기서 데이터베이스 초기화를 시작한다.
  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkAndShowFirstRunBrandIntro());
    });
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
                    '작업용 데이터베이스를 초기 상태로 되돌립니다.\n'
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
      ).showSnackBar(
        const SnackBar(content: Text('데이터베이스가 초기 상태로 되돌아갔습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _wordsFuture = _createWordsFuture();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('데이터베이스 초기화 실패: $e')));
    }
  }

  Future<void> _undoLastChange() async {
    setState(() => _isLoading = true);

    try {
      final repository = WordRepository();
      final undoResult = await repository.undoLastChange();
      if (undoResult.didUndo) {
        WordGraphDataCache.clear();
        final primaryWordId = undoResult.primaryWordId;
        if (primaryWordId != null) {
          await repository.getWordMapByIdForReadAfterUndoSingleWord(
            primaryWordId,
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            undoResult.didUndo ? '최근 변경을 되돌렸습니다.' : '되돌릴 변경이 없습니다.',
          ),
        ),
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

  Future<void> _checkAndShowFirstRunBrandIntro() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    final hasSeenBrandIntro =
        preferences.getBool(_firstRunBrandIntroSeenKey) ?? false;
    if (hasSeenBrandIntro) {
      return;
    }

    final confirmed = await _showFirstRunBrandIntroDialog();
    if (confirmed != true) {
      return;
    }

    await preferences.setBool(_firstRunBrandIntroSeenKey, true);
  }

  Future<bool?> _showFirstRunBrandIntroDialog() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'רשת',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.black87,
                    fontFamilyFallback: const [
                      'Noto Sans Hebrew',
                      'Noto Sans',
                      'Segoe UI',
                      'Arial',
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Reshet (레셰트)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '히브리어로 “그물”을 뜻합니다.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '단어와 단어의 관계를 그물처럼 탐색하는 도구입니다.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAboutDialog() async {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'רשת',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.black87,
                  fontFamilyFallback: const [
                    'Noto Sans Hebrew',
                    'Noto Sans',
                    'Segoe UI',
                    'Arial',
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Reshet (레셰트)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '히브리어로 "그물"을 뜻합니다.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Reshet은 성서 단어와 단어의 관계를 그물처럼 연결해 탐색하는 도구입니다.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  '버전 $_aboutVersion',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  /// 화면을 그리는 메서드
  /// _isLoading 값에 따라 로딩 화면 또는 본문 화면 표시
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'רשת',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.6,
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.black87,
            fontFamilyFallback: const [
              'Noto Sans Hebrew',
              'Noto Sans',
              'Segoe UI',
              'Arial',
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showAboutDialog,
            icon: const Icon(Icons.info_outline),
            tooltip: '프로그램 정보',
          ),
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
                child: Text('데이터베이스 초기화(초기 상태로 되돌리기)'),
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
                            labelText: '검색 (표기/의미/스트롱 번호)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: _handleSearchChanged,
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
                      _currentWords = words;
                      final isDefaultStrongList = _isShowingDefaultStrongList;
                      _currentWordsAreDefaultStrongList = isDefaultStrongList;

                      if (words.isEmpty) {
                        return const Center(child: Text('검색 결과 없음'));
                      }

                      Widget buildWordTile(BuildContext context, int index) {
                        final wordMap = words[index];
                        final displayStrong = _formatDisplayStrong(
                          (wordMap['스트롱넘버'] ?? '').toString(),
                        );
                        final displaySummary = buildHomeWordDisplaySummary(
                          wordMap,
                        );
                        final subtitleText = isDefaultStrongList
                            ? ''
                            : _buildWordSubtitle(wordMap);

                        return ListTile(
                          title: isDefaultStrongList
                              ? Text(
                                  _buildDefaultStrongListTitle(
                                    strong: displayStrong,
                                    summary: displaySummary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : Text.rich(
                                  _buildWordTitle(
                                    strong: displayStrong,
                                    summary: displaySummary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          subtitle: isDefaultStrongList || subtitleText.isEmpty
                              ? null
                              : Text(
                                  subtitleText,
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
                      }

                      if (isDefaultStrongList) {
                        return ListView.builder(
                          controller: _listScrollController,
                          itemExtent: _defaultStrongListItemExtent,
                          itemCount: words.length,
                          itemBuilder: buildWordTile,
                        );
                      }

                      return ListView.builder(
                        controller: _listScrollController,
                        itemCount: words.length,
                        itemBuilder: buildWordTile,
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
    _cancelPendingStrongJump();

    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _isShowingDefaultStrongList = true;
        _wordsFuture = _createWordsFuture();
      });
      return;
    }

    setState(() {
      _isShowingDefaultStrongList = false;
      _wordsFuture = _createWordsFuture();
    });
  }

  /// 검색어를 지우고 기본 목록으로 되돌린다.
  void _clearSearch() {
    _cancelPendingStrongJump();
    _searchController.clear();
    setState(() {
      _isShowingDefaultStrongList = true;
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
    _cancelPendingStrongJump();
    _listScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
