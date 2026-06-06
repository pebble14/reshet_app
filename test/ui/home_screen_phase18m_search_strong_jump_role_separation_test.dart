import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 18-M HomeScreen search and strong jump role separation', () {
    const homeSourcePath = 'lib/ui/home_screen.dart';

    late String homeSource;
    late String homeStateFieldSource;
    late String strongJumpHandlerSource;
    late String strongJumpSubmittedHandlerSource;
    late String runStrongRailJumpSource;
    late String passiveSelectedHandlerSource;
    late String homeSearchControlAreaSource;
    late String homeStrongControlAreaSource;
    late String homeWorkspaceSearchSurfaceSource;
    late String homePaneSource;
    late String runSearchSource;
    late String smallWidthBranch;

    setUpAll(() {
      homeSource = _readText(homeSourcePath);
      homeStateFieldSource = _sourceBetween(
        homeSource,
        'class _HomeScreenState extends State<HomeScreen> {',
        'Future<List<HomeDefaultStrongListItem>> _createDefaultStrongListFuture()',
      );
      strongJumpHandlerSource = _sourceBetween(
        homeSource,
        'void _handleStrongRailJumpChanged(String value) {',
        'void _handleStrongRailJumpSubmitted(String value) {',
      );
      strongJumpSubmittedHandlerSource = _sourceBetween(
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
      homePaneSource = _sourceBetween(
        homeSource,
        'final homePane = Column(',
        'if (!isLargeScreen) {',
      );
      runSearchSource = _sourceBetween(
        homeSource,
        'void _runSearch() {',
        'void _clearSearch() {',
      );
      smallWidthBranch = _sourceBetween(
        homeSource,
        'if (!isLargeScreen) {',
        'return Row(',
      );
    });

    test('search and strong jump use separate controllers', () {
      expect(
        homeStateFieldSource,
        contains(
          'final TextEditingController _searchController = TextEditingController();',
        ),
      );
      expect(
        homeStateFieldSource,
        contains(
          'final TextEditingController _strongJumpController = TextEditingController();',
        ),
      );
      expect(homeSource, contains('_searchController.dispose();'));
      expect(homeSource, contains('_strongJumpController.dispose();'));
    });

    test(
      'large-screen mounts search above workspace and Strong on the left',
      () {
        expect(
          homeSearchControlAreaSource,
          contains('controller: _searchController'),
        );
        expect(
          homeSearchControlAreaSource,
          isNot(contains('controller: _strongJumpController')),
        );
        expect(
          homeSearchControlAreaSource,
          contains('_cancelPendingStrongJump(),'),
        );
        expect(
          homeSearchControlAreaSource,
          contains('onSubmitted: (_) => _runSearch()'),
        );
        expect(homeSearchControlAreaSource, contains('onPressed: _runSearch'));
        expect(
          homeSearchControlAreaSource,
          contains('onPressed: _clearSearch'),
        );

        expect(
          homeStrongControlAreaSource,
          contains('controller: _strongJumpController'),
        );
        expect(
          homeStrongControlAreaSource,
          isNot(contains('controller: _searchController')),
        );
        expect(
          homeStrongControlAreaSource,
          contains("labelText: 'Strong/스트롱'"),
        );
        expect(homeStrongControlAreaSource, contains("hintText: 'H1 또는 G26'"));
        expect(
          homeStrongControlAreaSource,
          contains('onChanged: _handleStrongRailJumpChanged'),
        );
        expect(
          homeStrongControlAreaSource,
          contains('onSubmitted: _handleStrongRailJumpSubmitted'),
        );
        expect(homeStrongControlAreaSource, isNot(contains('_runSearch')));
        expect(
          homeWorkspaceSearchSurfaceSource,
          contains('child: homeSearchControlArea'),
        );
        expect(
          _appearsBefore(
            homePaneSource,
            'if (isLargeScreen)',
            'child: homeStrongControlArea',
          ),
          isTrue,
        );
        expect(
          _appearsBefore(
            homePaneSource,
            'child: homeStrongControlArea',
            'else',
          ),
          isTrue,
        );
        expect(
          _appearsBefore(homePaneSource, 'else', 'homeSearchControlArea'),
          isTrue,
        );
      },
    );

    test('Strong handlers remain rail-local and search-independent', () {
      expect(
        strongJumpHandlerSource,
        contains('_strongJumpController.text.trim()'),
      );
      expect(strongJumpHandlerSource, contains('_runStrongRailJump('));
      expect(strongJumpHandlerSource, isNot(contains('_searchController')));
      expect(
        strongJumpSubmittedHandlerSource,
        contains('_runStrongRailJump(value, showNotFoundFeedback: true);'),
      );
      expect(runStrongRailJumpSource, contains('_jumpToStrongInRail('));

      for (final source in [
        strongJumpHandlerSource,
        strongJumpSubmittedHandlerSource,
        runStrongRailJumpSource,
      ]) {
        for (final forbiddenStrongHandlerSource in [
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
          expect(source, isNot(contains(forbiddenStrongHandlerSource)));
        }
      }
    });

    test('general search submit does not read strong jump controller', () {
      expect(runSearchSource, contains('_searchController.text.trim()'));
      expect(runSearchSource, isNot(contains('_strongJumpController')));
      expect(runSearchSource, isNot(contains('_jumpToStrongInRail')));
    });

    test('small-screen search branch keeps the existing home pane flow', () {
      expect(smallWidthBranch, contains('return homePane;'));
      expect(smallWidthBranch, isNot(contains('WordExplorerScreen(')));
      expect(smallWidthBranch, isNot(contains('ExplorerWorkspace(')));
      expect(homeSearchControlAreaSource, contains('child: isLargeScreen'));
      expect(
        homeSearchControlAreaSource,
        contains('onChanged: _handleSearchChanged'),
      );
      expect(smallWidthBranch, isNot(contains('homeWorkspaceSearchSurface')));
      expect(smallWidthBranch, isNot(contains('homeStrongControlArea')));
    });

    test('graph selection passive sync does not become retarget navigation', () {
      expect(
        passiveSelectedHandlerSource,
        contains(
          '_jumpToStrongInRail(normalizedDisplayStrong, showNotFoundFeedback: false);',
        ),
      );

      for (final forbiddenPassiveSelectionSource in [
        '_showWordInLargeScreenExplorerPane',
        '_largeScreenExplorerWordId =',
        'WordExplorerScreen(',
        'Navigator.push',
        '_repository.',
      ]) {
        expect(
          passiveSelectedHandlerSource,
          isNot(contains(forbiddenPassiveSelectionSource)),
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
