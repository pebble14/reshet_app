import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20-C transient search result surface guardrail', () {
    const mainSourcePath = 'lib/main.dart';
    const homeSourcePath = 'lib/ui/home_screen.dart';
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';

    late String mainSource;
    late String homeSource;
    late String wordExplorerSource;
    late String homeStateFieldSource;
    late String transientSurfaceSource;
    late String dismissSource;
    late String homeWordListSurfaceSource;
    late String homeLeftControlListSurfaceSource;
    late String smallWidthBranch;
    late String largeWorkspaceSource;
    late String runSearchSource;
    late String clearSearchSource;
    late String strongJumpSource;
    late String passiveSelectedHandlerSource;
    late String wordExplorerFieldSource;

    setUpAll(() {
      mainSource = _readText(mainSourcePath);
      homeSource = _readText(homeSourcePath);
      wordExplorerSource = _readText(wordExplorerSourcePath);
      homeStateFieldSource = _sourceBetween(
        homeSource,
        'class _HomeScreenState extends State<HomeScreen> {',
        'Future<List<HomeDefaultStrongListItem>> _createDefaultStrongListFuture()',
      );
      transientSurfaceSource = _sourceBetween(
        homeSource,
        'Widget _buildLargeScreenTransientSearchResultSurface() {',
        'void _dismissLargeScreenTransientSearchResultSurface() {',
      );
      dismissSource = _sourceBetween(
        homeSource,
        'void _dismissLargeScreenTransientSearchResultSurface() {',
        'Widget build(BuildContext context) {',
      );
      homeWordListSurfaceSource = _sourceBetween(
        homeSource,
        'final Widget homeWordListSurface =',
        'final Widget homeLeftControlListSurface =',
      );
      homeLeftControlListSurfaceSource = _sourceBetween(
        homeSource,
        'final Widget homeLeftControlListSurface =',
        'final homePane = Column(',
      );
      smallWidthBranch = _sourceBetween(
        homeSource,
        'if (!isLargeScreen) {',
        'return Row(',
      );
      largeWorkspaceSource = _sourceBetween(
        homeSource,
        'return Row(',
        'void _runSearch() {',
      );
      runSearchSource = _sourceBetween(
        homeSource,
        'void _runSearch() {',
        'void _clearSearch() {',
      );
      clearSearchSource = _sourceBetween(
        homeSource,
        'void _clearSearch() {',
        'void _refreshWords() {',
      );
      strongJumpSource = _sourceBetween(
        homeSource,
        'void _handleStrongRailJumpChanged(String value) {',
        'void _jumpToStrongInDefaultList(',
      );
      passiveSelectedHandlerSource = _sourceBetween(
        homeSource,
        'void _handleExplorerSelectedStrongWordChanged(',
        'String _buildDefaultStrongListTitle(HomeDefaultStrongListItem item)',
      );
      wordExplorerFieldSource = _sourceBetween(
        wordExplorerSource,
        'class _WordExplorerScreenState extends State<WordExplorerScreen> {',
        'void initState() {',
      );
    });

    test('mounts a local floating result panel only in large workspace', () {
      expect(
        largeWorkspaceSource,
        contains('if (_isLargeScreenTransientSearchResultVisible)'),
      );
      expect(
        largeWorkspaceSource,
        contains('_buildLargeScreenTransientSearchResultSurface()'),
      );
      expect(
        _appearsBefore(
          largeWorkspaceSource,
          'homeWorkspaceSearchSurface',
          'Stack(',
        ),
        isTrue,
      );
      expect(
        _appearsBefore(
          largeWorkspaceSource,
          'Positioned.fill(',
          'WordExplorerScreen(',
        ),
        isTrue,
      );
      expect(
        _appearsBefore(
          largeWorkspaceSource,
          'WordExplorerScreen(',
          '_buildLargeScreenTransientSearchResultSurface()',
        ),
        isTrue,
      );
      expect(largeWorkspaceSource, contains('top: 0'));
      expect(largeWorkspaceSource, contains('left: 0'));
      expect(largeWorkspaceSource, contains('right: 0'));
      expect(
        smallWidthBranch,
        isNot(contains('_buildLargeScreenTransientSearchResultSurface()')),
      );

      for (final forbiddenPresentation in [
        'OverlayEntry',
        'Overlay.of',
        'Portal',
        'showDialog',
        'showModalBottomSheet',
        'Navigator.push',
      ]) {
        expect(transientSurfaceSource, isNot(contains(forbiddenPresentation)));
      }
    });

    test('keeps search state ownership in HomeScreen private state', () {
      expect(
        homeStateFieldSource,
        contains(
          'final TextEditingController _searchController = TextEditingController();',
        ),
      );
      expect(
        homeStateFieldSource,
        contains(
          'Future<List<HomeSearchResultDisplayItem>>? _searchWordsFuture;',
        ),
      );
      expect(
        homeStateFieldSource,
        contains('bool _isShowingDefaultStrongList = true;'),
      );
      expect(
        homeStateFieldSource,
        contains('bool _isLargeScreenTransientSearchResultVisible = false;'),
      );
      expect(transientSurfaceSource, contains('future: _searchWordsFuture'));
      expect(transientSurfaceSource, isNot(contains('_repository.')));
      expect(transientSurfaceSource, isNot(contains('DatabaseService.')));
    });

    test('shows loading and no-result states inside the transient panel', () {
      expect(
        transientSurfaceSource,
        contains('snapshot.connectionState == ConnectionState.waiting'),
      );
      expect(
        transientSurfaceSource,
        contains("'large-screen-transient-search-result-loading'"),
      );
      expect(
        transientSurfaceSource,
        contains("'large-screen-transient-search-result-empty'"),
      );
      expect(transientSurfaceSource, contains("Text('검색 결과 없음')"));
    });

    test('search submit opens presentation without Explorer retarget', () {
      expect(runSearchSource, contains('_searchController.text.trim()'));
      expect(runSearchSource, contains('_isShowingDefaultStrongList = false;'));
      expect(runSearchSource, contains('_setVisibleWordListFuture();'));
      expect(
        runSearchSource,
        contains('_isLargeScreenTransientSearchResultVisible ='),
      );
      expect(runSearchSource, contains('_isCurrentLayoutLargeScreen();'));

      for (final forbiddenSubmitAction in [
        '_showWordInLargeScreenExplorerPane',
        '_largeScreenExplorerWordId =',
        'WordExplorerScreen(',
        'Navigator.push',
        'ExplorerWorkspaceState',
      ]) {
        expect(runSearchSource, isNot(contains(forbiddenSubmitAction)));
      }
    });

    test(
      'explicit candidate tap retargets through the existing path then closes',
      () {
        expect(
          transientSurfaceSource,
          contains('_showWordInLargeScreenExplorerPane(wordId);'),
        );
        expect(
          transientSurfaceSource,
          contains('_dismissLargeScreenTransientSearchResultSurface();'),
        );
        expect(
          _appearsBefore(
            transientSurfaceSource,
            '_showWordInLargeScreenExplorerPane(wordId);',
            '_dismissLargeScreenTransientSearchResultSurface();',
          ),
          isTrue,
        );
        expect(
          transientSurfaceSource,
          isNot(contains('_largeScreenExplorerWordId =')),
        );
      },
    );

    test('dismiss and clear close presentation without Explorer retarget', () {
      expect(
        dismissSource,
        contains('_isLargeScreenTransientSearchResultVisible = false;'),
      );
      expect(clearSearchSource, contains('_searchController.clear();'));
      expect(
        clearSearchSource,
        contains('_isShowingDefaultStrongList = true;'),
      );
      expect(
        clearSearchSource,
        contains('_isLargeScreenTransientSearchResultVisible = false;'),
      );
      expect(clearSearchSource, contains('_setVisibleWordListFuture();'));

      for (final source in [dismissSource, clearSearchSource]) {
        expect(source, isNot(contains('_showWordInLargeScreenExplorerPane')));
        expect(source, isNot(contains('_largeScreenExplorerWordId =')));
      }
    });

    test(
      'keeps Strong jump and graph passive sync outside panel lifecycle',
      () {
        for (final source in [strongJumpSource, passiveSelectedHandlerSource]) {
          for (final forbiddenAction in [
            '_isLargeScreenTransientSearchResultVisible',
            '_buildLargeScreenTransientSearchResultSurface',
            '_dismissLargeScreenTransientSearchResultSurface',
            '_showWordInLargeScreenExplorerPane',
            '_largeScreenExplorerWordId =',
            '_runSearch',
            '_setVisibleWordListFuture',
            '_searchWordsFuture',
            '_isShowingDefaultStrongList =',
            'Navigator.push',
          ]) {
            expect(source, isNot(contains(forbiddenAction)));
          }
        }
      },
    );

    test('keeps large-screen Rail-only and shared small-screen list flow', () {
      expect(
        homeWordListSurfaceSource,
        contains(
          'final Widget homeWordListSurface = _isShowingDefaultStrongList',
        ),
      );
      expect(
        homeWordListSurfaceSource,
        contains('_buildDefaultStrongListView()'),
      );
      expect(
        homeWordListSurfaceSource,
        contains('FutureBuilder<List<HomeSearchResultDisplayItem>>'),
      );
      expect(
        homeWordListSurfaceSource,
        contains('_showWordInLargeScreenExplorerPane(wordId);'),
      );
      expect(
        homeWordListSurfaceSource,
        contains('await _openWordDetail(wordId);'),
      );
      expect(
        homeLeftControlListSurfaceSource,
        contains('child: _buildStrongLevelOneRetargetRail()'),
      );
      expect(
        homeLeftControlListSurfaceSource,
        isNot(contains('if (_isShowingDefaultStrongList) ...[')),
      );
      expect(
        homeLeftControlListSurfaceSource,
        isNot(contains('Expanded(child: homeWordListSurface)')),
      );
      expect(
        homeLeftControlListSurfaceSource,
        contains(': homeWordListSurface;'),
      );
      expect(smallWidthBranch, contains('return homePane;'));
      expect(smallWidthBranch, isNot(contains('WordExplorerScreen(')));
    });

    test('keeps WordExplorer and ExplorerWorkspace production boundaries', () {
      expect(wordExplorerFieldSource, contains('late String _centerWordId;'));
      expect(wordExplorerFieldSource, contains('String? _selectedWordId;'));
      expect(
        wordExplorerFieldSource,
        contains(
          'final WordNavigationHistoryController<_ExplorerHistorySnapshot> _history',
        ),
      );

      for (final productionEntrySource in [mainSource, homeSource]) {
        expect(productionEntrySource, isNot(contains('ExplorerWorkspace(')));
        expect(
          productionEntrySource,
          isNot(contains('ExplorerWorkspaceState')),
        );
      }
    });
  });
}

String _readText(String path) {
  return File(path).readAsStringSync();
}

String _sourceBetween(String source, String startMarker, String endMarker) {
  final start = source.indexOf(startMarker);
  expect(start, greaterThanOrEqualTo(0), reason: 'Missing $startMarker');

  final end = source.indexOf(endMarker, start);
  expect(end, greaterThan(start), reason: 'Missing $endMarker after marker.');

  return source.substring(start, end);
}

bool _appearsBefore(String source, String firstPattern, String secondPattern) {
  final firstIndex = source.indexOf(firstPattern);
  final secondIndex = source.indexOf(secondPattern);

  expect(firstIndex, greaterThanOrEqualTo(0), reason: 'Missing $firstPattern');
  expect(
    secondIndex,
    greaterThanOrEqualTo(0),
    reason: 'Missing $secondPattern',
  );

  return firstIndex < secondIndex;
}
