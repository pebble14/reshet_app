import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 18-M HomeScreen search and strong jump role separation', () {
    const homeSourcePath = 'lib/ui/home_screen.dart';

    late String homeSource;
    late String homeStateFieldSource;
    late String strongJumpHandlerSource;
    late String passiveSelectedHandlerSource;
    late String searchControlAreaSource;
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
        'void _jumpToStrongInDefaultList(',
      );
      passiveSelectedHandlerSource = _sourceBetween(
        homeSource,
        'void _handleExplorerSelectedStrongWordChanged(',
        'String _buildDefaultStrongListTitle(HomeDefaultStrongListItem item)',
      );
      searchControlAreaSource = _sourceBetween(
        homeSource,
        'final homeSearchControlArea = Padding(',
        'final Widget homeWordListSurface =',
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
      'large-screen control surface separates search field and strong field',
      () {
        expect(searchControlAreaSource, contains('child: isLargeScreen'));
        expect(
          searchControlAreaSource,
          contains('controller: _searchController'),
        );
        expect(
          searchControlAreaSource,
          contains('controller: _strongJumpController'),
        );
        expect(searchControlAreaSource, contains("labelText: 'Strong/스트롱'"));
        expect(searchControlAreaSource, contains("hintText: 'H1 또는 G26'"));
        expect(searchControlAreaSource, contains('onChanged: (_) =>'));
        expect(
          searchControlAreaSource,
          contains('_cancelPendingStrongJump(),'),
        );
        expect(
          searchControlAreaSource,
          contains('onChanged: _handleStrongRailJumpChanged'),
        );
        expect(
          searchControlAreaSource,
          contains('onSubmitted: _handleStrongRailJumpSubmitted'),
        );
        expect(
          searchControlAreaSource,
          contains('onSubmitted: (_) => _runSearch()'),
        );
        expect(searchControlAreaSource, contains('onPressed: _runSearch'));
        expect(searchControlAreaSource, contains('onPressed: _clearSearch'));
      },
    );

    test('strong field handler remains rail-local and search-independent', () {
      expect(
        strongJumpHandlerSource,
        contains('_strongJumpController.text.trim()'),
      );
      expect(strongJumpHandlerSource, contains('_jumpToStrongInRail('));
      expect(strongJumpHandlerSource, isNot(contains('_searchController')));

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
        expect(
          strongJumpHandlerSource,
          isNot(contains(forbiddenStrongHandlerSource)),
        );
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
      expect(searchControlAreaSource, contains(': Row('));
      expect(
        searchControlAreaSource,
        contains('onChanged: _handleSearchChanged'),
      );
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
