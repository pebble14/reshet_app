import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 19-C top search surface guardrail hardening', () {
    const mainSourcePath = 'lib/main.dart';
    const homeSourcePath = 'lib/ui/home_screen.dart';
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';

    late String mainSource;
    late String homeSource;
    late String wordExplorerSource;
    late String homeStateFieldSource;
    late String homeSearchControlAreaSource;
    late String homeStrongControlAreaSource;
    late String homeWorkspaceSearchSurfaceSource;
    late String homeWordListSurfaceSource;
    late String homeLeftControlListSurfaceSource;
    late String largeHomePaneHeaderSource;
    late String smallWidthBranch;
    late String largeWorkspaceSource;
    late String runSearchSource;
    late String strongChangedHandlerSource;
    late String strongSubmittedHandlerSource;
    late String runStrongRailJumpSource;
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
      homeSearchControlAreaSource = _sourceBetween(
        homeSource,
        'final homeSearchControlArea = Padding(',
        'final homeStrongControlArea = Padding(',
      );
      homeStrongControlAreaSource = _sourceBetween(
        homeSource,
        'final homeStrongControlArea = Padding(',
        'final homeWorkspaceSearchSurface = DecoratedBox(',
      );
      homeWorkspaceSearchSurfaceSource = _sourceBetween(
        homeSource,
        'final homeWorkspaceSearchSurface = DecoratedBox(',
        'final Widget homeWordListSurface =',
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
      final homePaneSource = _sourceBetween(
        homeSource,
        'final homePane = Column(',
        'if (!isLargeScreen) {',
      );
      largeHomePaneHeaderSource = _sourceBetween(
        homePaneSource,
        'if (isLargeScreen)',
        'else',
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
      strongChangedHandlerSource = _sourceBetween(
        homeSource,
        'void _handleStrongRailJumpChanged(String value) {',
        'void _handleStrongRailJumpSubmitted(String value) {',
      );
      strongSubmittedHandlerSource = _sourceBetween(
        homeSource,
        'void _handleStrongRailJumpSubmitted(String value) {',
        'void _runStrongRailJump(String input, {required bool showNotFoundFeedback}) {',
      );
      runStrongRailJumpSource = _sourceBetween(
        homeSource,
        'void _runStrongRailJump(String input, {required bool showNotFoundFeedback}) {',
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

    test('large-screen keeps general search on the workspace top surface', () {
      expect(
        homeSearchControlAreaSource,
        contains('controller: _searchController'),
      );
      expect(
        homeSearchControlAreaSource,
        isNot(contains('controller: _strongJumpController')),
      );
      expect(
        homeWorkspaceSearchSurfaceSource,
        contains('child: homeSearchControlArea'),
      );
      expect(largeWorkspaceSource, contains('homeWorkspaceSearchSurface'));
      expect(
        _appearsBefore(
          largeWorkspaceSource,
          'homeWorkspaceSearchSurface',
          '_largeScreenStrongControlSurfaceWidth',
        ),
        isTrue,
      );
      expect(
        _appearsBefore(
          largeWorkspaceSource,
          'homeWorkspaceSearchSurface',
          'WordExplorerScreen(',
        ),
        isTrue,
      );
    });

    test('large-screen left control keeps Strong and compact Rail only', () {
      expect(
        homeStrongControlAreaSource,
        contains('controller: _strongJumpController'),
      );
      expect(
        homeStrongControlAreaSource,
        isNot(contains('controller: _searchController')),
      );
      expect(
        largeHomePaneHeaderSource,
        contains('child: homeStrongControlArea'),
      );
      expect(
        largeHomePaneHeaderSource,
        isNot(contains('homeSearchControlArea')),
      );
      expect(
        homeLeftControlListSurfaceSource,
        contains('child: _buildStrongLevelOneRetargetRail()'),
      );
      expect(
        homeLeftControlListSurfaceSource,
        isNot(contains('Expanded(child: homeWordListSurface)')),
      );
      expect(
        homeLeftControlListSurfaceSource,
        isNot(contains('_isShowingDefaultStrongList')),
      );
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
    });

    test('small-screen keeps general search in the existing homePane flow', () {
      expect(smallWidthBranch, contains('return homePane;'));
      expect(smallWidthBranch, isNot(contains('homeWorkspaceSearchSurface')));
      expect(smallWidthBranch, isNot(contains('homeStrongControlArea')));
      expect(smallWidthBranch, isNot(contains('WordExplorerScreen(')));
      expect(smallWidthBranch, isNot(contains('ExplorerWorkspace(')));
      expect(
        homeSearchControlAreaSource,
        contains('onChanged: _handleSearchChanged'),
      );
      expect(homeSource, contains('await _openWordDetail(wordId);'));
    });

    test(
      'general search submit changes list state without Explorer retarget',
      () {
        expect(runSearchSource, contains('_searchController.text.trim()'));
        expect(
          runSearchSource,
          contains('_isShowingDefaultStrongList = false;'),
        );
        expect(runSearchSource, contains('_setVisibleWordListFuture();'));

        for (final forbiddenSubmitAction in [
          '_showWordInLargeScreenExplorerPane',
          '_largeScreenExplorerWordId =',
          'WordExplorerScreen(',
          'Navigator.push',
          'ExplorerWorkspaceState',
        ]) {
          expect(runSearchSource, isNot(contains(forbiddenSubmitAction)));
        }
      },
    );

    test(
      'Strong input remains rail-local and cannot change search list state',
      () {
        expect(
          homeStrongControlAreaSource,
          contains('onChanged: _handleStrongRailJumpChanged'),
        );
        expect(
          homeStrongControlAreaSource,
          contains('onSubmitted: _handleStrongRailJumpSubmitted'),
        );
        expect(strongChangedHandlerSource, contains('_runStrongRailJump('));
        expect(strongSubmittedHandlerSource, contains('_runStrongRailJump('));
        expect(runStrongRailJumpSource, contains('_jumpToStrongInRail('));

        for (final source in [
          homeStrongControlAreaSource,
          strongChangedHandlerSource,
          strongSubmittedHandlerSource,
          runStrongRailJumpSource,
        ]) {
          for (final forbiddenAction in [
            '_runSearch',
            '_setVisibleWordListFuture',
            '_searchWordsFuture',
            '_isShowingDefaultStrongList =',
            '_showWordInLargeScreenExplorerPane',
            '_largeScreenExplorerWordId =',
            'WordExplorerScreen(',
            'Navigator.push',
            '_repository.',
          ]) {
            expect(source, isNot(contains(forbiddenAction)));
          }
        }
      },
    );

    test('graph passive sync cannot retarget the Explorer', () {
      expect(
        passiveSelectedHandlerSource,
        contains(
          '_jumpToStrongInRail(normalizedDisplayStrong, showNotFoundFeedback: false);',
        ),
      );

      for (final forbiddenAction in [
        '_showWordInLargeScreenExplorerPane',
        '_largeScreenExplorerWordId =',
        '_runSearch',
        '_setVisibleWordListFuture',
        '_searchWordsFuture',
        '_isShowingDefaultStrongList =',
        'WordExplorerScreen(',
        'Navigator.push',
        '_repository.',
      ]) {
        expect(passiveSelectedHandlerSource, isNot(contains(forbiddenAction)));
      }
    });

    test('keeps WordExplorer owner and workspace production prohibitions', () {
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
      expect(wordExplorerFieldSource, contains('late String _centerWordId;'));
      expect(wordExplorerFieldSource, contains('String? _selectedWordId;'));
      expect(
        wordExplorerFieldSource,
        contains('WordDetailLikeDisplayItem? _selectedWordDisplayItem;'),
      );
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
      expect(
        wordExplorerFieldSource,
        isNot(contains('ExplorerWorkspaceState')),
      );
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
