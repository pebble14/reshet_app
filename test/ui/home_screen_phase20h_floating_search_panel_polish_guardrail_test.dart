import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20-H floating search panel polish guardrail', () {
    const homeSourcePath = 'lib/ui/home_screen.dart';

    late String homeSource;
    late String transientSurfaceSource;
    late String dismissSource;
    late String largeSearchChangedSource;
    late String largeScreenSearchSource;
    late String escapeSource;
    late String largeWorkspaceSource;
    late String runSearchSource;
    late String smallWidthBranch;

    setUpAll(() {
      homeSource = _readText(homeSourcePath);
      transientSurfaceSource = _sourceBetween(
        homeSource,
        'Widget _buildLargeScreenTransientSearchResultSurface() {',
        'void _dismissLargeScreenTransientSearchResultSurface() {',
      );
      dismissSource = _sourceBetween(
        homeSource,
        'void _dismissLargeScreenTransientSearchResultSurface() {',
        'void _handleLargeScreenSearchChanged(String value) {',
      );
      largeSearchChangedSource = _sourceBetween(
        homeSource,
        'void _handleLargeScreenSearchChanged(String value) {',
        'void _runLargeScreenSearch() {',
      );
      largeScreenSearchSource = _sourceBetween(
        homeSource,
        'void _runLargeScreenSearch() {',
        'KeyEventResult _handleLargeScreenTransientSearchResultKeyEvent(',
      );
      escapeSource = _sourceBetween(
        homeSource,
        'KeyEventResult _handleLargeScreenTransientSearchResultKeyEvent(',
        'Widget build(BuildContext context) {',
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
      smallWidthBranch = _sourceBetween(
        homeSource,
        'if (!isLargeScreen) {',
        'return Row(',
      );
    });

    test('dismisses outside clicks before the base layout receives them', () {
      expect(
        largeWorkspaceSource,
        contains(
          "'large-screen-transient-search-result-outside-dismiss-layer'",
        ),
      );
      expect(
        largeWorkspaceSource,
        contains('behavior: HitTestBehavior.opaque'),
      );
      expect(largeWorkspaceSource, contains('onTap:'));
      expect(
        largeWorkspaceSource,
        contains('_dismissLargeScreenTransientSearchResultSurface'),
      );
      expect(
        _appearsBefore(
          largeWorkspaceSource,
          "'large-screen-transient-search-result-outside-dismiss-layer'",
          '_buildLargeScreenTransientSearchResultSurface()',
        ),
        isTrue,
      );
      expect(
        _appearsBefore(
          largeWorkspaceSource,
          'child: Row(',
          "'large-screen-transient-search-result-outside-dismiss-layer'",
        ),
        isTrue,
      );
    });

    test('escape closes only the visible panel without changing focus', () {
      expect(largeWorkspaceSource, contains('child: Focus('));
      expect(largeWorkspaceSource, contains('canRequestFocus: false'));
      expect(largeWorkspaceSource, contains('onKeyEvent:'));
      expect(
        largeWorkspaceSource,
        contains('_handleLargeScreenTransientSearchResultKeyEvent'),
      );
      expect(escapeSource, contains('event is! KeyDownEvent'));
      expect(
        escapeSource,
        contains('event.logicalKey != LogicalKeyboardKey.escape'),
      );
      expect(
        escapeSource,
        contains('_dismissLargeScreenTransientSearchResultSurface();'),
      );
      expect(escapeSource, contains('return KeyEventResult.handled;'));

      for (final forbiddenFocusAction in [
        'autofocus',
        'requestFocus',
        'unfocus',
      ]) {
        expect(escapeSource, isNot(contains(forbiddenFocusAction)));
        expect(largeWorkspaceSource, isNot(contains(forbiddenFocusAction)));
      }

      for (final forbiddenEscapeAction in [
        '_searchController.clear',
        '_setVisibleWordListFuture',
        '_showWordInLargeScreenExplorerPane',
        '_jumpToStrongInRail',
        '_largeScreenExplorerWordId =',
        'Navigator',
      ]) {
        expect(escapeSource, isNot(contains(forbiddenEscapeAction)));
      }
    });

    test('large-screen submit restores search focus for immediate escape', () {
      expect(
        homeSource,
        contains('final FocusNode _largeScreenSearchFocusNode = FocusNode('),
      );
      expect(homeSource, contains("debugLabel: 'large-screen-search'"));
      expect(homeSource, contains('focusNode: _largeScreenSearchFocusNode'));
      expect(
        homeSource,
        contains('onSubmitted: (_) => _runLargeScreenSearch()'),
      );
      expect(homeSource, contains('onPressed: _runLargeScreenSearch'));
      expect(largeScreenSearchSource, contains('_runSearch();'));
      expect(
        largeScreenSearchSource,
        contains('_isLargeScreenTransientSearchResultVisible'),
      );
      expect(
        largeScreenSearchSource,
        contains('WidgetsBinding.instance.addPostFrameCallback'),
      );
      expect(
        largeScreenSearchSource,
        contains('_largeScreenSearchFocusNode.requestFocus();'),
      );
      expect(homeSource, contains('_largeScreenSearchFocusNode.dispose();'));

      for (final forbiddenFocusRestoreAction in [
        '_searchController.clear',
        '_setVisibleWordListFuture',
        '_showWordInLargeScreenExplorerPane',
        '_jumpToStrongInRail',
        '_largeScreenExplorerWordId =',
        'Navigator',
      ]) {
        expect(
          largeScreenSearchSource,
          isNot(contains(forbiddenFocusRestoreAction)),
        );
      }
    });

    test(
      'empty large-screen input closes presentation without resetting search',
      () {
        expect(
          largeSearchChangedSource,
          contains('_cancelPendingStrongJump();'),
        );
        expect(largeSearchChangedSource, contains('value.trim().isEmpty'));
        expect(
          largeSearchChangedSource,
          contains('_dismissLargeScreenTransientSearchResultSurface();'),
        );

        for (final forbiddenEmptyAction in [
          '_searchController.clear',
          '_setVisibleWordListFuture',
          '_isShowingDefaultStrongList =',
          '_showWordInLargeScreenExplorerPane',
          '_largeScreenExplorerWordId =',
        ]) {
          expect(
            largeSearchChangedSource,
            isNot(contains(forbiddenEmptyAction)),
          );
        }
      },
    );

    test(
      'keeps max height, internal scrolling, and base Row layout stable',
      () {
        expect(
          transientSurfaceSource,
          contains('constraints: const BoxConstraints(maxHeight: 320)'),
        );
        expect(transientSurfaceSource, contains('Flexible('));
        expect(transientSurfaceSource, contains('ListView.builder('));
        expect(
          transientSurfaceSource,
          contains("'large-screen-transient-search-result-list'"),
        );
        expect(largeWorkspaceSource, contains('Positioned.fill('));
        expect(largeWorkspaceSource, contains('child: Row('));
        expect(
          _appearsBefore(
            largeWorkspaceSource,
            'child: Row(',
            "'large-screen-transient-search-result-outside-dismiss-layer'",
          ),
          isTrue,
        );
        expect(
          _appearsBefore(
            largeWorkspaceSource,
            "'large-screen-transient-search-result-outside-dismiss-layer'",
            '_buildLargeScreenTransientSearchResultSurface()',
          ),
          isTrue,
        );
      },
    );

    test(
      'keeps submit, candidate tap, and small-screen contracts unchanged',
      () {
        expect(
          transientSurfaceSource,
          contains('_showWordInLargeScreenExplorerPane('),
        );
        expect(
          _appearsBefore(
            transientSurfaceSource,
            '_showWordInLargeScreenExplorerPane(',
            '_dismissLargeScreenTransientSearchResultSurface();',
          ),
          isTrue,
        );

        for (final forbiddenSubmitAction in [
          '_showWordInLargeScreenExplorerPane',
          '_largeScreenExplorerWordId =',
          'WordExplorerScreen(',
          'Navigator.push',
        ]) {
          expect(runSearchSource, isNot(contains(forbiddenSubmitAction)));
        }

        expect(smallWidthBranch, contains('return homePane;'));
        expect(smallWidthBranch, isNot(contains('Focus(')));
        expect(smallWidthBranch, isNot(contains('GestureDetector(')));
        expect(
          smallWidthBranch,
          isNot(contains('_buildLargeScreenTransientSearchResultSurface()')),
        );
        expect(homeSource, contains('await _openWordDetail(wordId);'));
      },
    );

    test(
      'keeps local widget tree and forbidden presentation structures absent',
      () {
        expect(
          dismissSource,
          isNot(contains('_showWordInLargeScreenExplorerPane')),
        );

        for (final forbiddenPresentation in [
          'OverlayEntry',
          'Overlay.of',
          'Portal',
          'showDialog',
          'showModalBottomSheet',
          'Navigator.push',
        ]) {
          expect(largeWorkspaceSource, isNot(contains(forbiddenPresentation)));
          expect(
            transientSurfaceSource,
            isNot(contains(forbiddenPresentation)),
          );
        }
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

bool _appearsBefore(String source, String before, String after) {
  final beforeIndex = source.indexOf(before);
  expect(beforeIndex, greaterThanOrEqualTo(0), reason: 'Missing $before');

  final afterIndex = source.indexOf(after);
  expect(afterIndex, greaterThanOrEqualTo(0), reason: 'Missing $after');

  return beforeIndex < afterIndex;
}
