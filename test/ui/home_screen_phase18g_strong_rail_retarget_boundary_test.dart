import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 18-G HomeScreen strong rail retarget boundary', () {
    const homeSourcePath = 'lib/ui/home_screen.dart';

    late String homeSource;
    late String retargetRailSource;
    late String railTapSource;
    late String visibleListFutureSource;
    late String homeWordListSurfaceSource;
    late String homeLeftControlListSurfaceSource;
    late String smallWidthBranch;

    setUpAll(() {
      homeSource = _readText(homeSourcePath);
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
      visibleListFutureSource = _sourceBetween(
        homeSource,
        'void _setVisibleWordListFuture() {',
        '/// 위젯이 처음 생성될 때',
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

    test('rail reuses the existing default Strong list future only', () {
      expect(
        homeSource,
        contains(
          'static const double _largeScreenStrongControlHorizontalPadding = 12.0;',
        ),
      );
      expect(
        retargetRailSource,
        contains('horizontal: _largeScreenStrongControlHorizontalPadding'),
      );
      expect(retargetRailSource, contains('future: _defaultStrongListFuture'));
      expect(
        retargetRailSource,
        contains('FutureBuilder<List<HomeDefaultStrongListItem>>'),
      );

      for (final forbiddenReadOrBoundary in [
        '_repository.',
        'DatabaseService.',
        'DataSource',
        'DTO',
        'typedef ',
        'class ',
        'Navigator.push',
        'WordExplorerScreen(',
        'ExplorerWorkspaceState',
        '_defaultStrongListFuture = _createDefaultStrongListFuture',
      ]) {
        expect(retargetRailSource, isNot(contains(forbiddenReadOrBoundary)));
      }
    });

    test('rail mounts only through the large-screen left control surface', () {
      expect(
        homeLeftControlListSurfaceSource,
        contains('final Widget homeLeftControlListSurface = isLargeScreen'),
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
        contains(': homeWordListSurface'),
      );
      expect(smallWidthBranch, contains('return homePane;'));
      expect(
        smallWidthBranch,
        isNot(contains('_buildStrongLevelOneRetargetRail()')),
      );
      expect(smallWidthBranch, isNot(contains('WordExplorerScreen(')));
      expect(smallWidthBranch, isNot(contains('ExplorerWorkspace(')));
    });

    test(
      'rail tap only requests the existing large-screen Explorer retarget',
      () {
        expect(
          railTapSource,
          contains('_showWordInLargeScreenExplorerPane(item.wordId);'),
        );
        expect(
          _countOccurrences(
            railTapSource,
            '_showWordInLargeScreenExplorerPane',
          ),
          1,
        );

        for (final forbiddenTapAction in [
          '_scrollToDefaultStrongIndex',
          '_jumpToStrongInDefaultList',
          '_listScrollController',
          '_runSearch',
          '_clearSearch',
          '_setVisibleWordListFuture',
          '_isShowingDefaultStrongList =',
          '_searchWordsFuture',
          '_defaultStrongListFuture =',
          'Navigator.push',
          '_repository.',
          'DatabaseService.',
          'ExplorerWorkspaceState',
        ]) {
          expect(railTapSource, isNot(contains(forbiddenTapAction)));
        }
      },
    );

    test(
      'shared small-screen flow keeps the existing search result surface',
      () {
        expect(
          visibleListFutureSource,
          contains('_searchWordsFuture = _createSearchWordsFuture();'),
        );
        expect(
          visibleListFutureSource,
          isNot(contains('_defaultStrongListFuture = null;')),
        );
        expect(
          visibleListFutureSource,
          isNot(contains('_isShowingDefaultStrongList = true')),
        );
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
          homeLeftControlListSurfaceSource,
          isNot(contains('Expanded(child: homeWordListSurface)')),
        );
        expect(
          homeLeftControlListSurfaceSource,
          isNot(contains('_isShowingDefaultStrongList =')),
        );
        expect(
          homeLeftControlListSurfaceSource,
          isNot(contains('_setVisibleWordListFuture')),
        );
      },
    );

    test(
      'rail current feedback is visual and based only on Explorer target id',
      () {
        expect(
          retargetRailSource,
          contains('item.wordId == _largeScreenExplorerWordId'),
        );
        expect(retargetRailSource, contains('primaryContainer'));
        expect(retargetRailSource, contains('onPrimaryContainer'));
        expect(retargetRailSource, isNot(contains('selected:')));
        expect(
          retargetRailSource,
          isNot(contains('late String _centerWordId')),
        );
        expect(retargetRailSource, isNot(contains('String? _selectedWordId')));
        expect(retargetRailSource, isNot(contains('_history')));
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

int _countOccurrences(String source, String pattern) {
  var count = 0;
  var offset = 0;

  while (true) {
    final index = source.indexOf(pattern, offset);
    if (index < 0) {
      return count;
    }
    count += 1;
    offset = index + pattern.length;
  }
}
