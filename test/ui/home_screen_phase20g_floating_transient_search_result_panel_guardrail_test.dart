import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20-G floating transient search result panel guardrail', () {
    const homeSourcePath = 'lib/ui/home_screen.dart';

    late String homeSource;
    late String transientSurfaceSource;
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

    test('keeps base layout outside the transient panel condition', () {
      expect(largeWorkspaceSource, contains('homeWorkspaceSearchSurface'));
      expect(largeWorkspaceSource, contains('Expanded('));
      expect(largeWorkspaceSource, contains('child: Stack('));
      expect(largeWorkspaceSource, contains('Positioned.fill('));
      expect(largeWorkspaceSource, contains('child: Row('));
      expect(
        largeWorkspaceSource,
        contains('_largeScreenStrongControlSurfaceWidth'),
      );
      expect(largeWorkspaceSource, contains('WordExplorerScreen('));
      expect(
        _appearsBefore(
          largeWorkspaceSource,
          'Positioned.fill(',
          'if (_isLargeScreenTransientSearchResultVisible)',
        ),
        isTrue,
      );
      expect(
        largeWorkspaceSource,
        isNot(
          contains(
            'homeWorkspaceSearchSurface,\n'
            '                          if (_isLargeScreenTransientSearchResultVisible)',
          ),
        ),
      );
    });

    test('floats the transient panel with local Stack and Positioned only', () {
      expect(largeWorkspaceSource, contains('top: 0'));
      expect(largeWorkspaceSource, contains('left: 0'));
      expect(largeWorkspaceSource, contains('right: 0'));
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
          'Stack(',
          '_buildLargeScreenTransientSearchResultSurface()',
        ),
        isTrue,
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
        expect(transientSurfaceSource, isNot(contains(forbiddenPresentation)));
      }
    });

    test('keeps candidate tap as the only Explorer retarget path', () {
      expect(
        transientSurfaceSource,
        contains('_showWordInLargeScreenExplorerPane('),
      );
      expect(
        transientSurfaceSource,
        contains('_dismissLargeScreenTransientSearchResultSurface();'),
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
    });

    test('keeps small-screen homePane and detail route flow unchanged', () {
      expect(smallWidthBranch, contains('return homePane;'));
      expect(smallWidthBranch, isNot(contains('Stack(')));
      expect(smallWidthBranch, isNot(contains('Positioned(')));
      expect(
        smallWidthBranch,
        isNot(contains('_buildLargeScreenTransientSearchResultSurface()')),
      );
      expect(smallWidthBranch, isNot(contains('WordExplorerScreen(')));
      expect(homeSource, contains('await _openWordDetail(wordId);'));
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

bool _appearsBefore(String source, String before, String after) {
  final beforeIndex = source.indexOf(before);
  expect(beforeIndex, greaterThanOrEqualTo(0), reason: 'Missing $before');

  final afterIndex = source.indexOf(after);
  expect(afterIndex, greaterThanOrEqualTo(0), reason: 'Missing $after');

  return beforeIndex < afterIndex;
}
