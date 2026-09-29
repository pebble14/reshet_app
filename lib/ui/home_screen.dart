/*
  home_screen.dart

  검색과 Strong navigation, Explorer workspace를 연결하고 데이터베이스
  maintenance action을 제공하는 최상위 UI coordinator다.
*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_backup_service.dart';
import '../database/database_restore_service.dart';
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
import 'word_search_query.dart';

/// 검색·탐색 workspace와 데이터 maintenance 흐름의 최상위 화면이다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
    this.backupService = const DatabaseBackupService(),
    this.restoreService = const DatabaseRestoreService(),
    this.providedDataService = const DatabaseRestoreService(),
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final DatabaseBackupRunner backupService;
  final DatabaseRestoreRunner restoreService;
  final ProvidedDatabaseReplaceRunner providedDataService;

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
  bool _isBackingUp = false;
  bool _isRestoring = false;
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
  int _restoreGeneration = 0;

  bool get _isDatabaseMaintenanceInProgress => _isBackingUp || _isRestoring;

  Future<List<HomeDefaultStrongListItem>> _createDefaultStrongListFuture() {
    return _repository.getStrongWordsMap();
  }

  Future<List<HomeSearchResultDisplayItem>> _createSearchWordsFuture() async {
    return runWordSearchQuery(
      repository: _repository,
      query: _searchController.text,
    );
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
    return buildWordSearchResultSummary(item);
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

  Future<void> _confirmAndCreateBackup() async {
    if (_isDatabaseMaintenanceInProgress) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 백업'),
        content: const Text(
          '백업 파일에는 사용자가 입력한 단어, 관계, 메모와 변경 이력이 포함되며 '
          '암호화되지 않습니다. 신뢰할 수 있는 위치에 보관하세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('백업'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isBackingUp = true);
    BackupResult result;
    try {
      result = await widget.backupService.createBackup();
    } catch (error, stackTrace) {
      debugPrint('데이터 백업 실행 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      result = BackupFailed(
        stage: BackupFailureStage.destinationWrite,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }

    if (!mounted || result is BackupCancelled) {
      return;
    }

    final message = result is BackupSucceeded
        ? '데이터 백업이 완료되었습니다.'
        : '데이터 백업에 실패했습니다. 잠시 후 다시 시도하세요.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmAndRestoreDatabase({bool useBundledSeed = false}) async {
    if (_isDatabaseMaintenanceInProgress || _isLoading) {
      return;
    }

    var restoreStarted = false;
    RestoreResult result;
    try {
      Future<bool> confirmation() async {
        if (!mounted) return false;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(useBundledSeed ? '제공 데이터로 전체 교체' : '데이터 복원'),
            content: Text(
              useBundledSeed
                  ? '이 앱 버전에 포함된 제공 데이터로 현재 데이터를 모두 교체합니다. '
                        '내가 편집한 내용과 제공 데이터는 합쳐지지 않습니다.\n\n'
                        '먼저 현재 데이터의 백업을 원하는 위치에 저장해야 합니다. '
                        '저장을 취소하거나 실패하면 교체하지 않습니다. '
                        '백업은 교체 후에도 보관되며 데이터 복원 메뉴로 되돌릴 수 있습니다.\n\n'
                        '백업 파일은 암호화되지 않습니다. 교체 후 검색·탐색 화면이 초기화됩니다.'
                  : '선택한 백업 데이터로 현재 데이터가 교체됩니다. 복원 전에 현재 데이터를 '
                        '별도 파일로 백업하는 것을 권장합니다.\n\n'
                        '내부 rollback snapshot은 실패 복구용 임시 파일이며 사용자 백업이 아닙니다. '
                        '백업 파일은 암호화되지 않았을 수 있고, 복원 후 검색·탐색·현재 작업 화면 '
                        '상태가 초기화될 수 있습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(useBundledSeed ? '내 데이터 유지' : '취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(useBundledSeed ? '전체 교체' : '복원'),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) {
          restoreStarted = true;
          setState(() => _isRestoring = true);
          return true;
        }
        return false;
      }

      result = useBundledSeed
          ? await widget.providedDataService.replaceWithBundledSeed(
              confirmation: confirmation,
            )
          : await widget.restoreService.restore(confirmation: confirmation);
    } catch (error, stackTrace) {
      debugPrint('데이터 복원 실행 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      result = RestoreFailed(
        stage: RestoreFailureStage.sourceSelection,
        rollbackStatus: RestoreRollbackStatus.notRequired,
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (!mounted) return;

    var stateRefreshSucceeded = true;
    if (result is RestoreSucceeded) {
      try {
        await _refreshAfterRestore();
      } catch (error, stackTrace) {
        stateRefreshSucceeded = false;
        debugPrint('복원 후 화면 상태 갱신 실패: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (mounted) {
          _refreshWords();
        }
      }
    }

    if (restoreStarted && mounted) {
      setState(() => _isRestoring = false);
    }
    if (!mounted || result is RestoreCancelled) return;

    final message = switch (result) {
      RestoreSucceeded() when !stateRefreshSucceeded =>
        '데이터 복원은 완료되었지만 화면 갱신에 실패했습니다. 앱을 다시 실행하세요.',
      RestoreSucceeded() when useBundledSeed =>
        '제공 데이터로 교체했습니다. 저장한 백업은 데이터 복원 메뉴에서 사용할 수 있습니다.',
      RestoreSucceeded() => '데이터 복원이 완료되었습니다.',
      RestoreRejected() => _restoreRejectedMessage(result.reason),
      RestoreFailed()
          when result.rollbackStatus == RestoreRollbackStatus.failed =>
        '데이터 복원과 원본 복구에 실패했습니다. 앱을 종료하고 지원을 요청하세요.',
      RestoreFailed() when result.stage == RestoreFailureStage.userBackupSave =>
        '백업 저장에 실패해 교체하지 않았습니다. 앱 데이터 폴더 밖의 저장 위치를 선택하세요.',
      RestoreFailed() => '데이터 복원에 실패해 기존 데이터를 유지했습니다.',
      RestoreCancelled() => '',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _restoreRejectedMessage(RestoreRejectionReason reason) {
    return switch (reason) {
      RestoreRejectionReason.notSqlite => 'SQLite 데이터베이스 파일이 아닙니다.',
      RestoreRejectionReason.integrityInvalid => '손상된 데이터베이스 파일은 복원할 수 없습니다.',
      RestoreRejectionReason.schemaIncompatible =>
        '현재 Reshet 복원 schema와 호환되지 않는 파일입니다.',
      RestoreRejectionReason.unsupportedBackup =>
        'Reshet 전체 데이터 백업으로 확인할 수 없는 파일입니다.',
    };
  }

  Future<void> _refreshAfterRestore() async {
    WordGraphDataCache.clear();

    var nextExplorerWordId = _largeScreenExplorerWordId;
    final currentWordExists =
        nextExplorerWordId.isNotEmpty &&
        await _repository.wordExistsForGraphNavigation(nextExplorerWordId);
    if (!currentWordExists) {
      final firstItems = await _repository.getStrongWordsMap(limit: 1);
      nextExplorerWordId = firstItems.isEmpty
          ? _largeScreenDefaultExplorerWordId
          : firstItems.first.wordId;
    }
    if (!mounted) return;

    _cancelPendingStrongJump();
    _searchController.clear();
    _strongJumpController.clear();
    setState(() {
      _currentDefaultStrongItems = const [];
      _currentStrongRailItems = const [];
      _searchWordsFuture = null;
      _isShowingDefaultStrongList = true;
      _isLargeScreenTransientSearchResultVisible = false;
      _passiveSelectedStrongWordId = null;
      _passiveSelectedDisplayStrongNumber = null;
      _largeScreenExplorerWordId = nextExplorerWordId;
      _restoreGeneration++;
      _defaultStrongListFuture = _createDefaultStrongListFuture();
    });
  }

  Future<void> _undoLastChange() async {
    if (_isDatabaseMaintenanceInProgress) return;
    setState(() => _isLoading = true);

    try {
      final repository = WordRepository();
      final undoResult = await repository.undoLastChange();
      if (undoResult.didUndo) {
        WordGraphDataCache.clear();
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

  Future<void> _showThemeDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('테마'),
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          content: RadioGroup<ThemeMode>(
            groupValue: widget.themeMode,
            onChanged: (themeMode) {
              if (themeMode == null) {
                return;
              }
              Navigator.of(dialogContext).pop();
              if (themeMode != widget.themeMode) {
                widget.onThemeModeChanged?.call(themeMode);
              }
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: Text('시스템 설정 사용'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: Text('라이트'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: Text('다크'),
                ),
              ],
            ),
          ),
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

  Widget _buildBackupGuard(Widget child) {
    return Stack(
      children: [
        Positioned.fill(
          child: AbsorbPointer(
            absorbing: _isDatabaseMaintenanceInProgress,
            child: child,
          ),
        ),
        if (_isDatabaseMaintenanceInProgress) ...[
          const Positioned.fill(
            child: ModalBarrier(dismissible: false, color: Color(0x33000000)),
          ),
          Center(
            child: CircularProgressIndicator(
              key: Key(
                _isRestoring
                    ? 'database-restore-progress-indicator'
                    : 'database-backup-progress-indicator',
              ),
            ),
          ),
        ],
      ],
    );
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
            onPressed: _isRestoring ? null : _showThemeDialog,
            icon: const Icon(Icons.settings_outlined),
            tooltip: '설정',
          ),
          IconButton(
            onPressed: _isRestoring ? null : _showAboutDialog,
            icon: const Icon(Icons.info_outline),
            tooltip: '프로그램 정보',
          ),
          PopupMenuButton<String>(
            enabled:
                !_isDatabaseMaintenanceInProgress &&
                !_isLoading &&
                _dbErrorMessage == null,
            onSelected: (value) async {
              if (value == 'create_backup') {
                await _confirmAndCreateBackup();
              } else if (value == 'restore_backup') {
                await _confirmAndRestoreDatabase();
              } else if (value == 'replace_provided') {
                await _confirmAndRestoreDatabase(useBundledSeed: true);
              } else if (value == 'undo_last_change') {
                await _undoLastChange();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'create_backup',
                child: Text('데이터 백업'),
              ),
              const PopupMenuItem<String>(
                value: 'restore_backup',
                child: Text('데이터 복원'),
              ),
              const PopupMenuItem<String>(
                value: 'replace_provided',
                child: Text('제공 데이터로 전체 교체'),
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
                                  labelText: '검색 (표기·음역·의미·스트롱)',
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
                                  labelText: '검색 (표기·음역·의미·스트롱)',
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
                  final content = SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    child: homePane,
                  );
                  return _buildBackupGuard(content);
                }

                final content = Row(
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
                                              '$_restoreGeneration:'
                                              '$_largeScreenExplorerWordId',
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
                return _buildBackupGuard(content);
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
