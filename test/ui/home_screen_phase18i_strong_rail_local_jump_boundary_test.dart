import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 18-I HomeScreen strong rail local jump boundary', () {
    const homeSourcePath = 'lib/ui/home_screen.dart';

    late String homeSource;
    late String homeStateFieldSource;
    late String searchChangedSource;
    late String railSearchJumpSource;
    late String railScrollSource;
    late String railJumpSource;
    late String retargetRailSource;
    late String railTapSource;
    late String homeWordListSurfaceSource;
    late String homeLeftControlListSurfaceSource;
    late String smallWidthBranch;

    setUpAll(() {
      homeSource = _readText(homeSourcePath);
      homeStateFieldSource = _sourceBetween(
        homeSource,
        'class _HomeScreenState extends State<HomeScreen> {',
        'Future<List<HomeDefaultStrongListItem>> _createDefaultStrongListFuture()',
      );
      searchChangedSource = _sourceBetween(
        homeSource,
        'void _handleSearchChanged(String value) {',
        'void _jumpToStrongInDefaultList(',
      );
      railSearchJumpSource = _sourceBetween(
        searchChangedSource,
        'if (_canRunAutoStrongRailJump(currentInput)) {',
        'if (_canRunAutoDefaultStrongJump(currentInput)) {',
      );
      railScrollSource = _sourceBetween(
        homeSource,
        'double _calculateStrongRailOffset(int targetIndex) {',
        'void _cancelPendingStrongJump() {',
      );
      railJumpSource = _sourceBetween(
        homeSource,
        'void _jumpToStrongInRail(',
        'String _buildDefaultStrongListTitle(HomeDefaultStrongListItem item)',
      );
      retargetRailSource = _sourceBetween(
        homeSource,
        'Widget _buildStrongLevelOneRetargetRail()',
        'Widget _buildDefaultStrongListView()',
      );
      railTapSource = _sourceBetween(
        retargetRailSource,
        'onTap: () {',
        'child: DecoratedBox(',
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
    });

    test('rail local jump owns only rail controller and rail index cache', () {
      expect(
        homeStateFieldSource,
        contains('static const double _strongRailListItemExtent = 46.0;'),
      );
      expect(
        homeStateFieldSource,
        contains(
          'final ScrollController _strongRailScrollController = ScrollController();',
        ),
      );
      expect(
        homeStateFieldSource,
        contains(
          'List<HomeDefaultStrongListItem> _currentStrongRailItems = const [];',
        ),
      );
      expect(homeSource, contains('_strongRailScrollController.dispose();'));
      expect(homeSource, isNot(contains('class StrongRail')));
      expect(homeSource, isNot(contains('StrongRailController')));
    });

    test('strong input routes large-screen auto jump to rail local helper', () {
      expect(
        searchChangedSource,
        contains('_canRunAutoStrongRailJump(currentInput)'),
      );
      expect(
        searchChangedSource,
        contains(
          '_jumpToStrongInRail(normalizedStrong, showNotFoundFeedback: false);',
        ),
      );
      expect(
        searchChangedSource,
        contains('_canRunAutoDefaultStrongJump(currentInput)'),
      );
      expect(searchChangedSource, contains('_jumpToStrongInDefaultList('));

      expect(
        railSearchJumpSource,
        contains(
          '_jumpToStrongInRail(normalizedStrong, showNotFoundFeedback: false);',
        ),
      );
      expect(
        railSearchJumpSource,
        isNot(contains('_jumpToStrongInDefaultList')),
      );

      for (final forbiddenRailJumpAction in [
        '_setVisibleWordListFuture',
        '_searchWordsFuture',
        '_isShowingDefaultStrongList =',
        '_largeScreenExplorerWordId',
        '_showWordInLargeScreenExplorerPane',
        'WordExplorerScreen(',
        'Navigator.push',
        '_repository.',
      ]) {
        expect(railSearchJumpSource, isNot(contains(forbiddenRailJumpAction)));
      }
    });

    test('rail local helper does not reuse default list scroll helper', () {
      expect(railScrollSource, contains('_calculateStrongRailOffset'));
      expect(railScrollSource, contains('_strongRailScrollController'));
      expect(railScrollSource, contains('animateTo('));
      expect(railJumpSource, contains('_currentStrongRailItems'));
      expect(railJumpSource, contains('_findStrongIndex('));
      expect(
        railJumpSource,
        contains('_scrollToStrongRailIndex(targetIndex);'),
      );

      for (final forbiddenRailLocalSource in [
        '_listScrollController',
        '_scrollToDefaultStrongIndex',
        '_jumpToStrongInDefaultList',
        '_setVisibleWordListFuture',
        '_searchWordsFuture',
        '_isShowingDefaultStrongList =',
        '_largeScreenExplorerWordId',
        '_showWordInLargeScreenExplorerPane',
        'WordExplorerScreen(',
        'Navigator.push',
        '_repository.',
        'DatabaseService.',
        'DataSource',
        'DTO',
        'typedef ',
        'class ',
      ]) {
        expect(railScrollSource, isNot(contains(forbiddenRailLocalSource)));
        expect(railJumpSource, isNot(contains(forbiddenRailLocalSource)));
      }
    });

    test(
      'rail builder keeps retarget tap boundary and local jump cache separate',
      () {
        expect(
          retargetRailSource,
          contains('future: _defaultStrongListFuture'),
        );
        expect(
          retargetRailSource,
          contains('_currentStrongRailItems = items;'),
        );
        expect(
          retargetRailSource,
          contains('controller: _strongRailScrollController'),
        );
        expect(
          retargetRailSource,
          contains('itemExtent: _strongRailListItemExtent'),
        );
        expect(
          retargetRailSource,
          contains('item.wordId == _largeScreenExplorerWordId'),
        );
        expect(
          railTapSource,
          contains('_showWordInLargeScreenExplorerPane(item.wordId);'),
        );

        for (final forbiddenRailBuilderAction in [
          '_listScrollController',
          '_jumpToStrongInDefaultList',
          '_scrollToDefaultStrongIndex',
          '_setVisibleWordListFuture',
          '_searchWordsFuture =',
          '_isShowingDefaultStrongList =',
          '_repository.',
          'DatabaseService.',
          'Navigator.push',
          'WordExplorerScreen(',
        ]) {
          expect(
            retargetRailSource,
            isNot(contains(forbiddenRailBuilderAction)),
          );
        }

        expect(railTapSource, isNot(contains('_jumpToStrongInRail')));
        expect(railTapSource, isNot(contains('_strongRailScrollController')));
      },
    );

    test(
      'search and small-screen list surfaces remain unchanged by rail jump',
      () {
        expect(
          homeWordListSurfaceSource,
          contains(
            'final Widget homeWordListSurface = _isShowingDefaultStrongList',
          ),
        );
        expect(
          homeWordListSurfaceSource,
          contains('? _buildDefaultStrongListView()'),
        );
        expect(
          homeWordListSurfaceSource,
          contains(': FutureBuilder<List<HomeSearchResultDisplayItem>>'),
        );
        expect(
          homeWordListSurfaceSource,
          contains('future: _searchWordsFuture'),
        );
        expect(
          homeLeftControlListSurfaceSource,
          contains('Expanded(child: homeWordListSurface)'),
        );

        for (final forbiddenListSurfaceMutation in [
          '_setVisibleWordListFuture',
          '_searchWordsFuture = null',
          '_searchWordsFuture = _createSearchWordsFuture',
          '_isShowingDefaultStrongList =',
        ]) {
          expect(
            homeLeftControlListSurfaceSource,
            isNot(contains(forbiddenListSurfaceMutation)),
          );
        }

        expect(smallWidthBranch, contains('return homePane;'));
        expect(
          smallWidthBranch,
          isNot(contains('_buildStrongLevelOneRetargetRail()')),
        );
        expect(smallWidthBranch, isNot(contains('WordExplorerScreen(')));
        expect(smallWidthBranch, isNot(contains('ExplorerWorkspace(')));
      },
    );
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
