/*
  home_screen.dart

  이 파일은 Reshet 앱의 메인 화면을 정의한다.
  현재는 기본 구조만 구성하고,
  이후 데이터베이스 연결 및 기능을 점진적으로 추가할 예정이다.
*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/expression/home_word_display_summary.dart';
import '../domain/home/home_default_strong_list_item.dart';
import '../domain/home/home_search_result_display_item.dart';
import '../database/database_service.dart';
import 'word_detail_route_result.dart';
import 'word_detail_screen.dart';
import '../data/repositories/word_repository.dart';
import 'responsive_layout.dart';
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
  String? _dbErrorMessage;

  /// 홈 화면에서 사용할 Repository
  final WordRepository _repository = WordRepository();

  /// 검색 입력 컨트롤러
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _strongJumpController = TextEditingController();
  final FocusNode _largeScreenSearchFocusNode = FocusNode(
    debugLabel: 'large-screen-search',
  );

  static const double _defaultStrongListItemExtent = 56.0;
  static const double _strongRailListItemExtent = 46.0;
  static const double _largeScreenStrongControlSurfaceWidth = 160.0;
  static const double _largeScreenStrongControlHorizontalPadding = 12.0;
  static const String _largeScreenDefaultExplorerWordId = 'H0001_0000';
  static const Duration _strongJumpDebounceDuration = Duration(
    milliseconds: 300,
  );
  static const String _aboutVersion = '1.0.0+1';
  static const String _firstRunBrandIntroSeenKey = 'first_run_brand_intro_seen';

  final ScrollController _listScrollController = ScrollController();
  final ScrollController _strongRailScrollController = ScrollController();
  Timer? _strongJumpDebounceTimer;

  Future<List<HomeDefaultStrongListItem>>? _defaultStrongListFuture;
  Future<List<HomeSearchResultDisplayItem>>? _searchWordsFuture;
  List<HomeDefaultStrongListItem> _currentDefaultStrongItems = const [];
  List<HomeDefaultStrongListItem> _currentStrongRailItems = const [];
  bool _isShowingDefaultStrongList = true;
  bool _isLargeScreenTransientSearchResultVisible = false;
  String _largeScreenExplorerWordId = _largeScreenDefaultExplorerWordId;
  String? _passiveSelectedStrongWordId;
  String? _passiveSelectedDisplayStrongNumber;

  Future<List<HomeDefaultStrongListItem>> _createDefaultStrongListFuture() {
    return _repository.getStrongWordsMap();
  }

  Future<List<HomeSearchResultDisplayItem>> _createSearchWordsFuture() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      return const [];
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
    List<HomeDefaultStrongListItem> words,
    String normalizedStrong,
  ) {
    for (var index = 0; index < words.length; index++) {
      final displayStrong = words[index].displayStrongNumber;
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

  double _calculateStrongRailOffset(int targetIndex) {
    return targetIndex * _strongRailListItemExtent;
  }

  void _scrollToStrongRailIndex(int targetIndex) {
    void animateToIndex() {
      if (!_strongRailScrollController.hasClients) {
        return;
      }

      final maxScrollExtent =
          _strongRailScrollController.position.maxScrollExtent;
      final targetOffset = _calculateStrongRailOffset(targetIndex);
      final clampedOffset = targetOffset.clamp(0.0, maxScrollExtent).toDouble();

      _strongRailScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
      );
    }

    if (_strongRailScrollController.hasClients) {
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

  bool _isCurrentLayoutLargeScreen() {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      return false;
    }

    return isExplorerLargeScreenWidth(mediaQuery.size.width);
  }

  bool _canRunAutoStrongRailJump(String input) {
    return _isCurrentLayoutLargeScreen() &&
        _currentStrongRailItems.isNotEmpty &&
        _isStrongJumpInput(input);
  }

  bool _canRunAutoDefaultStrongJump(String input) {
    return !_isCurrentLayoutLargeScreen() &&
        _isShowingDefaultStrongList &&
        _currentDefaultStrongItems.isNotEmpty &&
        _isStrongJumpInput(input);
  }

  void _handleSearchChanged(String value) {
    _cancelPendingStrongJump();

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

      final normalizedStrong = _normalizeStrongInput(currentInput);
      if (_canRunAutoStrongRailJump(currentInput)) {
        _jumpToStrongInRail(normalizedStrong, showNotFoundFeedback: false);
        return;
      }

      if (_canRunAutoDefaultStrongJump(currentInput)) {
        _jumpToStrongInDefaultList(
          normalizedStrong,
          showNotFoundFeedback: false,
        );
      }
    });
  }

  void _handleStrongRailJumpChanged(String value) {
    _cancelPendingStrongJump();

    final scheduledInput = value.trim();
    if (!_isStrongJumpInput(scheduledInput)) {
      return;
    }

    _strongJumpDebounceTimer = Timer(_strongJumpDebounceDuration, () {
      _strongJumpDebounceTimer = null;

      if (!mounted) {
        return;
      }

      final currentInput = _strongJumpController.text.trim();
      if (currentInput != scheduledInput) {
        return;
      }

      _runStrongRailJump(currentInput, showNotFoundFeedback: false);
    });
  }

  void _handleStrongRailJumpSubmitted(String value) {
    _cancelPendingStrongJump();
    _runStrongRailJump(value, showNotFoundFeedback: true);
  }

  void _runStrongRailJump(String input, {required bool showNotFoundFeedback}) {
    final trimmedInput = input.trim();
    if (!_canRunAutoStrongRailJump(trimmedInput)) {
      return;
    }

    final normalizedStrong = _normalizeStrongInput(trimmedInput);
    _jumpToStrongInRail(
      normalizedStrong,
      showNotFoundFeedback: showNotFoundFeedback,
    );
  }

  void _jumpToStrongInDefaultList(
    String normalizedStrong, {
    bool showNotFoundFeedback = true,
  }) {
    final targetIndex = _findStrongIndex(
      _currentDefaultStrongItems,
      normalizedStrong,
    );
    if (targetIndex < 0) {
      if (showNotFoundFeedback) {
        _showStrongJumpNotFoundSnackBar(normalizedStrong);
      }
      return;
    }

    _scrollToDefaultStrongIndex(targetIndex);
  }

  void _jumpToStrongInRail(
    String normalizedStrong, {
    bool showNotFoundFeedback = true,
  }) {
    final targetIndex = _findStrongIndex(
      _currentStrongRailItems,
      normalizedStrong,
    );
    if (targetIndex < 0) {
      if (showNotFoundFeedback) {
        _showStrongJumpNotFoundSnackBar(normalizedStrong);
      }
      return;
    }

    _scrollToStrongRailIndex(targetIndex);
  }

  void _handleExplorerSelectedStrongWordChanged(
    String wordId,
    String displayStrongNumber,
  ) {
    final normalizedWordId = wordId.trim();
    final normalizedDisplayStrong = _formatDisplayStrong(displayStrongNumber);

    if (normalizedDisplayStrong.isEmpty) {
      if (_passiveSelectedStrongWordId == null &&
          _passiveSelectedDisplayStrongNumber == null) {
        return;
      }

      setState(() {
        _passiveSelectedStrongWordId = null;
        _passiveSelectedDisplayStrongNumber = null;
      });
      return;
    }

    if (_passiveSelectedStrongWordId != normalizedWordId ||
        _passiveSelectedDisplayStrongNumber != normalizedDisplayStrong) {
      setState(() {
        _passiveSelectedStrongWordId = normalizedWordId.isEmpty
            ? null
            : normalizedWordId;
        _passiveSelectedDisplayStrongNumber = normalizedDisplayStrong;
      });
    }

    _jumpToStrongInRail(normalizedDisplayStrong, showNotFoundFeedback: false);
  }

  String _buildDefaultStrongListTitle(HomeDefaultStrongListItem item) {
    return buildStrongListTitle(
      strong: item.displayStrongNumber,
      summary: HomeWordDisplaySummary(
        representativeSpelling: item.representativeSpelling,
      ),
    );
  }

  InlineSpan _buildWordTitle({
    required String strong,
    required HomeWordDisplaySummary summary,
  }) {
    return TextSpan(
      text: buildSearchResultTitle(strong: strong, summary: summary),
    );
  }

  HomeWordDisplaySummary _buildSearchResultSummary(
    HomeSearchResultDisplayItem item,
  ) {
    return HomeWordDisplaySummary(
      representativeSpelling: item.representativeSpelling ?? '',
      representativeTransliteration: item.representativeTransliteration ?? '',
      representativePronunciation: item.representativePronunciation ?? '',
    );
  }

  void _setVisibleWordListFuture() {
    if (_isShowingDefaultStrongList) {
      _searchWordsFuture = null;
      _defaultStrongListFuture = _createDefaultStrongListFuture();
      return;
    }

    _currentDefaultStrongItems = const [];
    _searchWordsFuture = _createSearchWordsFuture();
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
        _dbErrorMessage = null;
        _setVisibleWordListFuture();
      });

      print('데이터베이스 연결 성공');
    } catch (e) {
      print('데이터베이스 연결 실패: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _dbErrorMessage = '데이터베이스 초기화 실패: $e';
      });
    }
  }

  void _retryInitializeDatabase() {
    setState(() {
      _isLoading = true;
      _dbErrorMessage = null;
    });
    unawaited(_initializeDatabase());
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
        _setVisibleWordListFuture();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('데이터베이스가 초기 상태로 되돌아갔습니다.')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _setVisibleWordListFuture();
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
        _setVisibleWordListFuture();
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
                  Text('히브리어로 “그물”을 뜻합니다.', style: theme.textTheme.bodyMedium),
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
                Text('히브리어로 "그물"을 뜻합니다.', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                Text(
                  'Reshet은 성서 단어와 단어의 관계를 그물처럼 연결해 탐색하는 도구입니다.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text('버전 $_aboutVersion', style: theme.textTheme.bodySmall),
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

  Widget _buildStrongLevelOneRetargetRail() {
    final theme = Theme.of(context);

    return FutureBuilder<List<HomeDefaultStrongListItem>>(
      future: _defaultStrongListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 20,
            ),
          );
        }

        final items = snapshot.data ?? const <HomeDefaultStrongListItem>[];
        _currentStrongRailItems = items;
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.builder(
          controller: _strongRailScrollController,
          itemExtent: _strongRailListItemExtent,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final displayStrong = _formatDisplayStrong(
              item.displayStrongNumber,
            );
            final isCurrentLargeScreenTarget =
                item.wordId == _largeScreenExplorerWordId;
            final isPassiveSelectedStrong =
                _passiveSelectedDisplayStrongNumber != null &&
                displayStrong == _passiveSelectedDisplayStrongNumber;
            final foregroundColor = isCurrentLargeScreenTarget
                ? theme.colorScheme.onPrimaryContainer
                : isPassiveSelectedStrong
                ? theme.colorScheme.secondary
                : theme.colorScheme.onSurfaceVariant;
            final borderColor = isCurrentLargeScreenTarget
                ? theme.colorScheme.primary
                : isPassiveSelectedStrong
                ? theme.colorScheme.secondary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.55);
            final backgroundColor = isCurrentLargeScreenTarget
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
                : isPassiveSelectedStrong
                ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.28)
                : Colors.transparent;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _largeScreenStrongControlHorizontalPadding,
                vertical: 4,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  _showWordInLargeScreenExplorerPane(item.wordId);
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SizedBox(
                    height: 38,
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            displayStrong,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: foregroundColor,
                              fontWeight: isCurrentLargeScreenTarget
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isPassiveSelectedStrong)
                          Positioned(
                            right: 5,
                            bottom: 5,
                            child: SizedBox(
                              width: 6,
                              height: 6,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 화면을 그리는 메서드
  /// _isLoading 값에 따라 로딩 화면 또는 본문 화면 표시
  Widget _buildDefaultStrongListView() {
    return FutureBuilder<List<HomeDefaultStrongListItem>>(
      future: _defaultStrongListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('에러 발생: ${snapshot.error}'));
        }

        final items = snapshot.data ?? const <HomeDefaultStrongListItem>[];
        _currentDefaultStrongItems = items;

        if (items.isEmpty) {
          return const Center(child: Text('검색 결과 없음'));
        }

        return ListView.builder(
          controller: _listScrollController,
          itemExtent: _defaultStrongListItemExtent,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final showLargeScreenTargetFeedback = isExplorerLargeScreenWidth(
              MediaQuery.of(context).size.width,
            );
            final isCurrentLargeScreenTarget =
                showLargeScreenTargetFeedback &&
                item.wordId == _largeScreenExplorerWordId;

            return ListTile(
              selected: isCurrentLargeScreenTarget,
              selectedTileColor: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.35),
              title: Text(
                _buildDefaultStrongListTitle(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.article_outlined),
                    tooltip: '상세',
                    onPressed: () => _openDefaultStrongWordDetail(item.wordId),
                  ),
                  IconButton(
                    icon: const Icon(Icons.hub_outlined),
                    tooltip: '그래프',
                    onPressed: () => _openDefaultStrongWordGraph(item.wordId),
                  ),
                ],
              ),
              onTap: () async {
                final width = MediaQuery.of(context).size.width;
                if (isExplorerLargeScreenWidth(width)) {
                  _showWordInLargeScreenExplorerPane(item.wordId);
                  return;
                }

                await _openDefaultStrongWordDetail(item.wordId);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDatabaseErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36),
            const SizedBox(height: 12),
            const Text('데이터베이스를 준비하지 못했습니다.', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _retryInitializeDatabase,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWordInLargeScreenExplorerPane(String wordId) {
    final normalizedWordId = wordId.trim();
    if (normalizedWordId.isEmpty) {
      _showWordNavigationUnavailableSnackBar();
      return;
    }

    if (_largeScreenExplorerWordId == normalizedWordId) return;

    setState(() {
      _largeScreenExplorerWordId = normalizedWordId;
      _passiveSelectedStrongWordId = null;
      _passiveSelectedDisplayStrongNumber = null;
    });
  }

  void _showWordNavigationUnavailableSnackBar() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('단어 정보를 찾을 수 없습니다.')));
  }

  Future<void> _openDefaultStrongWordDetail(String wordId) async {
    final detailWord = await _repository
        .getWordDetailLikeDisplayItemByIdForDetailScreen(wordId);
    if (!mounted) return;
    if (detailWord == null) {
      _showWordNavigationUnavailableSnackBar();
      return;
    }

    await Navigator.push<WordDetailRouteResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            WordDetailScreen(wordId: wordId, initialDisplayItem: detailWord),
      ),
    );

    if (!mounted) return;
    _refreshWords();
  }

  Future<void> _openDefaultStrongWordGraph(String wordId) async {
    final centerWordExists = await _repository.wordExistsForGraphNavigation(
      wordId,
    );
    if (!mounted) return;
    if (!centerWordExists) {
      _showWordNavigationUnavailableSnackBar();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WordGraphScreen(centerWordId: wordId)),
    );

    if (!mounted) return;
    _refreshWords();
  }

  Widget _buildLargeScreenTransientSearchResultSurface() {
    final theme = Theme.of(context);

    return Material(
      key: const Key('large-screen-transient-search-result-surface'),
      color: theme.colorScheme.surfaceContainer,
      elevation: 8,
      shadowColor: theme.shadowColor.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.72)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('검색 결과', style: theme.textTheme.titleSmall),
                  ),
                  IconButton(
                    key: const Key(
                      'dismiss-large-screen-transient-search-result-surface',
                    ),
                    onPressed: _dismissLargeScreenTransientSearchResultSurface,
                    icon: const Icon(Icons.close),
                    tooltip: '검색 결과 닫기',
                  ),
                ],
              ),
            ),
            Flexible(
              child: FutureBuilder<List<HomeSearchResultDisplayItem>>(
                future: _searchWordsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      key: Key('large-screen-transient-search-result-loading'),
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('에러 발생: ${snapshot.error}'));
                  }

                  final words =
                      snapshot.data ?? const <HomeSearchResultDisplayItem>[];
                  if (words.isEmpty) {
                    return const Center(
                      key: Key('large-screen-transient-search-result-empty'),
                      child: Text('검색 결과 없음'),
                    );
                  }

                  return ListView.builder(
                    key: const Key('large-screen-transient-search-result-list'),
                    shrinkWrap: true,
                    itemCount: words.length,
                    itemBuilder: (context, index) {
                      final item = words[index];
                      final wordId = item.wordId;
                      final displaySummary = _buildSearchResultSummary(item);
                      final subtitleText = item.subtitleMeaning ?? '';

                      return ListTile(
                        key: ValueKey(
                          'large-screen-transient-search-result-$wordId',
                        ),
                        title: Text.rich(
                          _buildWordTitle(
                            strong: item.displayStrongNumber ?? '',
                            summary: displaySummary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: subtitleText.isEmpty
                            ? null
                            : Text(
                                subtitleText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                        onTap: () {
                          _showWordInLargeScreenExplorerPane(wordId);
                          _dismissLargeScreenTransientSearchResultSurface();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _dismissLargeScreenTransientSearchResultSurface() {
    if (!_isLargeScreenTransientSearchResultVisible) {
      return;
    }

    setState(() {
      _isLargeScreenTransientSearchResultVisible = false;
    });
  }

  void _handleLargeScreenSearchChanged(String value) {
    _cancelPendingStrongJump();

    if (value.trim().isEmpty) {
      _dismissLargeScreenTransientSearchResultSurface();
    }
  }

  void _runLargeScreenSearch() {
    _runSearch();

    if (!_isLargeScreenTransientSearchResultVisible) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_isLargeScreenTransientSearchResultVisible ||
          !_isCurrentLayoutLargeScreen()) {
        return;
      }

      _largeScreenSearchFocusNode.requestFocus();
    });
  }

  KeyEventResult _handleLargeScreenTransientSearchResultKeyEvent(
    FocusNode node,
    KeyEvent event,
  ) {
    if (!_isLargeScreenTransientSearchResultVisible ||
        event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }

    _dismissLargeScreenTransientSearchResultSurface();
    return KeyEventResult.handled;
  }

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
          : _dbErrorMessage != null
          ? _buildDatabaseErrorView(_dbErrorMessage!)
          : LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = isExplorerLargeScreenWidth(
                  constraints.maxWidth,
                );
                final homeSearchControlArea = Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: isLargeScreen
                      ? Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _largeScreenSearchFocusNode,
                                decoration: const InputDecoration(
                                  labelText: '검색 (표기/의미/스트롱 번호)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: _handleLargeScreenSearchChanged,
                                onSubmitted: (_) => _runLargeScreenSearch(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _runLargeScreenSearch,
                              icon: const Icon(Icons.search),
                              tooltip: '검색',
                            ),
                            IconButton(
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.clear),
                              tooltip: '초기화',
                            ),
                          ],
                        )
                      : Row(
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
                );

                final homeStrongControlArea = Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _largeScreenStrongControlHorizontalPadding,
                    12,
                    _largeScreenStrongControlHorizontalPadding,
                    8,
                  ),
                  child: TextField(
                    controller: _strongJumpController,
                    decoration: const InputDecoration(
                      labelText: 'Strong/스트롱',
                      hintText: 'H1 또는 G26',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: _handleStrongRailJumpChanged,
                    onSubmitted: _handleStrongRailJumpSubmitted,
                  ),
                );

                final homeWorkspaceSearchSurface = DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.35),
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: homeSearchControlArea,
                );

                final Widget homeWordListSurface = _isShowingDefaultStrongList
                    ? _buildDefaultStrongListView()
                    : FutureBuilder<List<HomeSearchResultDisplayItem>>(
                        future: _searchWordsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('에러 발생: ${snapshot.error}'),
                            );
                          }

                          final words = snapshot.data ?? [];

                          if (words.isEmpty) {
                            return const Center(child: Text('검색 결과 없음'));
                          }

                          Widget buildWordTile(
                            BuildContext context,
                            int index,
                          ) {
                            final item = words[index];
                            final wordId = item.wordId;
                            final displayStrong =
                                item.displayStrongNumber ?? '';
                            final displaySummary = _buildSearchResultSummary(
                              item,
                            );
                            final subtitleText = item.subtitleMeaning ?? '';
                            final isCurrentLargeScreenTarget =
                                isLargeScreen &&
                                wordId == _largeScreenExplorerWordId;

                            return ListTile(
                              selected: isCurrentLargeScreenTarget,
                              selectedTileColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.35),
                              title: Text.rich(
                                _buildWordTitle(
                                  strong: displayStrong,
                                  summary: displaySummary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: subtitleText.isEmpty
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
                                    onPressed: () => _openWordDetail(wordId),
                                  ),
                                  // 그래프
                                  IconButton(
                                    icon: const Icon(Icons.hub_outlined),
                                    tooltip: '그래프',
                                    onPressed: () => _openWordGraph(wordId),
                                  ),
                                ],
                              ),
                              // 탭은 기본적으로 상세로
                              onTap: () async {
                                final width = MediaQuery.of(context).size.width;

                                // 넓은 화면(데스크탑/태블릿)에서는 스플릿뷰
                                if (isExplorerLargeScreenWidth(width)) {
                                  _showWordInLargeScreenExplorerPane(wordId);
                                  return;
                                }

                                await _openWordDetail(wordId);
                              },
                            );
                          }

                          return ListView.builder(
                            controller: _listScrollController,
                            itemCount: words.length,
                            itemBuilder: buildWordTile,
                          );
                        },
                      );

                final Widget homeLeftControlListSurface = isLargeScreen
                    ? SizedBox.expand(child: _buildStrongLevelOneRetargetRail())
                    : homeWordListSurface;

                final homePane = Column(
                  children: [
                    // ✅ 좌측 Strong rail-local jump 입력
                    if (isLargeScreen)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        child: homeStrongControlArea,
                      )
                    else
                      homeSearchControlArea,

                    // ✅ 결과 리스트
                    Expanded(child: homeLeftControlListSurface),
                  ],
                );

                if (!isLargeScreen) {
                  return SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    child: homePane,
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Focus(
                        canRequestFocus: false,
                        onKeyEvent:
                            _handleLargeScreenTransientSearchResultKeyEvent,
                        child: Column(
                          children: [
                            homeWorkspaceSearchSurface,
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        SizedBox(
                                          width:
                                              _largeScreenStrongControlSurfaceWidth,
                                          child: homePane,
                                        ),
                                        const VerticalDivider(width: 1),
                                        Expanded(
                                          flex: 6,
                                          child: WordExplorerScreen(
                                            key: ValueKey(
                                              _largeScreenExplorerWordId,
                                            ),
                                            initialWordId:
                                                _largeScreenExplorerWordId,
                                            onSelectedStrongWordChanged:
                                                _handleExplorerSelectedStrongWordChanged,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_isLargeScreenTransientSearchResultVisible)
                                    Positioned.fill(
                                      child: GestureDetector(
                                        key: const Key(
                                          'large-screen-transient-search-result-outside-dismiss-layer',
                                        ),
                                        behavior: HitTestBehavior.opaque,
                                        onTap:
                                            _dismissLargeScreenTransientSearchResultSurface,
                                      ),
                                    ),
                                  if (_isLargeScreenTransientSearchResultVisible)
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      child:
                                          _buildLargeScreenTransientSearchResultSurface(),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
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
        _isLargeScreenTransientSearchResultVisible = false;
        _setVisibleWordListFuture();
      });
      return;
    }

    setState(() {
      _isShowingDefaultStrongList = false;
      _isLargeScreenTransientSearchResultVisible =
          _isCurrentLayoutLargeScreen();
      _setVisibleWordListFuture();
    });
  }

  /// 검색어를 지우고 기본 목록으로 되돌린다.
  void _clearSearch() {
    _cancelPendingStrongJump();
    _searchController.clear();
    setState(() {
      _isShowingDefaultStrongList = true;
      _isLargeScreenTransientSearchResultVisible = false;
      _setVisibleWordListFuture();
    });
  }

  /// 현재 검색 상태에 맞춰 홈 리스트 Future를 다시 만든다.
  void _refreshWords() {
    setState(() {
      _setVisibleWordListFuture();
    });
  }

  Future<void> _openWordDetail(String wordId) {
    return _openDefaultStrongWordDetail(wordId);
  }

  Future<void> _openWordGraph(String wordId) {
    return _openDefaultStrongWordGraph(wordId);
  }

  @override
  void dispose() {
    _cancelPendingStrongJump();
    _strongRailScrollController.dispose();
    _listScrollController.dispose();
    _strongJumpController.dispose();
    _largeScreenSearchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
