import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 18-C HomeScreen left control surface boundary', () {
    const homeSourcePath = 'lib/ui/home_screen.dart';
    const wordGraphSourcePath = 'lib/ui/word_graph_screen.dart';
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';

    late String homeSource;
    late String wordGraphSource;
    late String wordExplorerSource;
    late String leftPaneControlSource;
    late String smallWidthBranch;
    late String largeWidthBranch;
    late String wordExplorerFieldSource;

    setUpAll(() {
      homeSource = _readText(homeSourcePath);
      wordGraphSource = _readText(wordGraphSourcePath);
      wordExplorerSource = _readText(wordExplorerSourcePath);
      leftPaneControlSource = _sourceBetween(
        homeSource,
        'final isLargeScreen = _isLargeScreenWidth(',
        'if (!isLargeScreen) {',
      );
      smallWidthBranch = _sourceBetween(
        homeSource,
        'if (!isLargeScreen) {',
        'return Row(',
      );
      largeWidthBranch = _sourceBetween(
        homeSource,
        'return Row(',
        '              },',
      );
      wordExplorerFieldSource = _sourceBetween(
        wordExplorerSource,
        'class _WordExplorerScreenState extends State<WordExplorerScreen> {',
        'void initState() {',
      );
    });

    test('separates search controls as a persistent large-screen surface', () {
      expect(leftPaneControlSource, contains('final homeSearchControlArea'));
      expect(leftPaneControlSource, contains('if (isLargeScreen)'));
      expect(leftPaneControlSource, contains('DecoratedBox('));
      expect(leftPaneControlSource, contains('surfaceContainerHighest'));
      expect(leftPaneControlSource, contains('BorderSide('));
      expect(
        leftPaneControlSource,
        contains('color: Theme.of(context).dividerColor'),
      );
      expect(leftPaneControlSource, contains('child: homeSearchControlArea'));
      expect(leftPaneControlSource, contains('else'));
      expect(leftPaneControlSource, contains('homeSearchControlArea'));
    });

    test('keeps existing search and list responsibilities in HomeScreen', () {
      expect(leftPaneControlSource, contains('controller: _searchController'));
      expect(
        leftPaneControlSource,
        contains('onChanged: _handleSearchChanged'),
      );
      expect(
        leftPaneControlSource,
        contains('onSubmitted: (_) => _runSearch()'),
      );
      expect(leftPaneControlSource, contains('onPressed: _runSearch'));
      expect(leftPaneControlSource, contains('onPressed: _clearSearch'));
      expect(leftPaneControlSource, contains('_buildDefaultStrongListView()'));
      expect(
        leftPaneControlSource,
        contains('FutureBuilder<List<HomeSearchResultDisplayItem>>'),
      );
    });

    test('keeps small-screen route flow without embedded explorer panes', () {
      expect(smallWidthBranch, contains('return homePane;'));
      expect(smallWidthBranch, isNot(contains('WordExplorerScreen(')));
      expect(smallWidthBranch, isNot(contains('ExplorerWorkspace(')));
      expect(smallWidthBranch, isNot(contains('DecoratedBox(')));
    });

    test('keeps Phase 18-B large-screen pane proportions and remount key', () {
      expect(largeWidthBranch, contains('Expanded(flex: 2, child: homePane)'));
      expect(largeWidthBranch, contains('flex: 6'));
      expect(
        largeWidthBranch,
        contains('key: ValueKey(_largeScreenExplorerWordId)'),
      );
      expect(
        largeWidthBranch,
        contains('initialWordId: _largeScreenExplorerWordId'),
      );
    });

    test('does not move graph create flow into the left Home pane', () {
      expect(homeSource, isNot(contains('_showCreateWordFlow')));
      expect(homeSource, isNot(contains('Icons.note_add')));
      expect(homeSource, isNot(contains('WordEditScreen.fromSeed')));
      expect(wordGraphSource, contains('onPressed: _showCreateWordFlow'));
      expect(wordGraphSource, contains('Future<void> _showCreateWordFlow()'));
      expect(wordGraphSource, contains('WordEditScreen.fromSeed'));
    });

    test('does not implement Strong Rail or promote workspace state', () {
      expect(homeSource, isNot(contains('StrongRail')));
      expect(homeSource, isNot(contains('Strong Rail')));
      expect(homeSource, isNot(contains('ExplorerWorkspace(')));
      expect(homeSource, isNot(contains('ExplorerWorkspaceState')));
      expect(wordExplorerFieldSource, contains('late String _centerWordId;'));
      expect(wordExplorerFieldSource, contains('String? _selectedWordId;'));
      expect(
        wordExplorerFieldSource,
        contains('final WordRepository _repository'),
      );
    });

    test('does not add reads, queries, DTOs, models, or public API', () {
      expect(leftPaneControlSource, isNot(contains('_repository.')));
      expect(leftPaneControlSource, isNot(contains('DatabaseService.')));
      expect(leftPaneControlSource, isNot(contains('DataSource')));
      expect(leftPaneControlSource, isNot(contains('DTO')));
      expect(leftPaneControlSource, isNot(contains('class ')));
      expect(homeSource, isNot(contains('final String defaultExplorerWordId')));
      expect(
        homeSource,
        contains(
          "static const String _largeScreenDefaultExplorerWordId = 'H0001_0000';",
        ),
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
