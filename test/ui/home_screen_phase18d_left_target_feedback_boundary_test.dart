import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 18-D HomeScreen left target feedback boundary', () {
    const homeSourcePath = 'lib/ui/home_screen.dart';
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';

    late String homeSource;
    late String wordExplorerSource;
    late String defaultStrongListSource;
    late String leftPaneControlSource;
    late String searchResultListSource;
    late String smallWidthBranch;
    late String homeScreenWidgetSource;
    late String wordExplorerFieldSource;
    late String retargetRailSource;

    setUpAll(() {
      homeSource = _readText(homeSourcePath);
      wordExplorerSource = _readText(wordExplorerSourcePath);
      defaultStrongListSource = _sourceBetween(
        homeSource,
        'Widget _buildDefaultStrongListView()',
        'bool _isLargeScreenWidth(double width) {',
      );
      leftPaneControlSource = _sourceBetween(
        homeSource,
        'final isLargeScreen = _isLargeScreenWidth(',
        'if (!isLargeScreen) {',
      );
      searchResultListSource = _sourceBetween(
        leftPaneControlSource,
        'FutureBuilder<List<HomeSearchResultDisplayItem>>',
        'return ListView.builder(',
      );
      smallWidthBranch = _sourceBetween(
        homeSource,
        'if (!isLargeScreen) {',
        'return Row(',
      );
      homeScreenWidgetSource = _sourceBetween(
        homeSource,
        'class HomeScreen extends StatefulWidget {',
        '/// HomeScreen',
      );
      wordExplorerFieldSource = _sourceBetween(
        wordExplorerSource,
        'class _WordExplorerScreenState extends State<WordExplorerScreen> {',
        'void initState() {',
      );
      retargetRailSource = _sourceBetween(
        homeSource,
        'Widget _buildStrongLevelOneRetargetRail()',
        'Widget _buildDefaultStrongListView()',
      );
    });

    test('uses the private large-screen explorer target as feedback input', () {
      expect(
        homeSource,
        contains(
          'String _largeScreenExplorerWordId = _largeScreenDefaultExplorerWordId;',
        ),
      );
      expect(defaultStrongListSource, contains('isCurrentLargeScreenTarget'));
      expect(
        defaultStrongListSource,
        contains('item.wordId == _largeScreenExplorerWordId'),
      );
      expect(searchResultListSource, contains('isCurrentLargeScreenTarget'));
      expect(
        searchResultListSource,
        contains('wordId == _largeScreenExplorerWordId'),
      );
    });

    test('keeps default Strong list target feedback large-screen gated', () {
      expect(leftPaneControlSource, contains('_buildDefaultStrongListView()'));
      expect(
        defaultStrongListSource,
        contains('final showLargeScreenTargetFeedback = _isLargeScreenWidth('),
      );
      expect(
        defaultStrongListSource,
        contains('MediaQuery.of(context).size.width'),
      );
      expect(
        defaultStrongListSource,
        contains('showLargeScreenTargetFeedback &&'),
      );
      expect(
        defaultStrongListSource,
        contains('selected: isCurrentLargeScreenTarget'),
      );
      expect(defaultStrongListSource, contains('selectedTileColor'));
    });

    test('keeps search result target feedback large-screen gated', () {
      expect(searchResultListSource, contains('isLargeScreen &&'));
      expect(
        searchResultListSource,
        contains('selected: isCurrentLargeScreenTarget'),
      );
      expect(searchResultListSource, contains('selectedTileColor'));
      expect(
        searchResultListSource,
        contains('_showWordInLargeScreenExplorerPane('),
      );
      expect(
        searchResultListSource,
        contains('await _openWordDetail(wordId);'),
      );
    });

    test('keeps small-screen route flow without embedded explorer pane', () {
      expect(smallWidthBranch, contains('return homePane;'));
      expect(smallWidthBranch, isNot(contains('WordExplorerScreen(')));
      expect(
        smallWidthBranch,
        isNot(contains('ValueKey(_largeScreenExplorerWordId)')),
      );
      expect(smallWidthBranch, isNot(contains('ExplorerWorkspace(')));
    });

    test('does not promote workspace, explorer, or repository ownership', () {
      expect(homeSource, contains('Widget _buildStrongLevelOneRetargetRail()'));
      expect(homeSource, isNot(contains('ExplorerWorkspace(')));
      expect(homeSource, isNot(contains('ExplorerWorkspaceState')));
      expect(homeSource, isNot(contains('_showCreateWordFlow')));
      expect(homeSource, isNot(contains('Icons.note_add')));
      expect(wordExplorerFieldSource, contains('late String _centerWordId;'));
      expect(wordExplorerFieldSource, contains('String? _selectedWordId;'));
      expect(
        wordExplorerFieldSource,
        contains('final WordRepository _repository'),
      );
      expect(homeSource, isNot(contains('late String _centerWordId;')));
      expect(homeSource, isNot(contains('String? _selectedWordId;')));
      expect(
        homeSource,
        isNot(contains('WordDetailLikeDisplayItem? _selectedWordDisplayItem')),
      );
      expect(homeSource, isNot(contains('bool _isDetailLoading')));
      expect(homeSource, isNot(contains('String? _detailError')));
      expect(homeSource, isNot(contains('String? _detailUnavailableMessage')));
      expect(
        homeSource,
        isNot(
          contains('WordNavigationHistoryController<_ExplorerHistorySnapshot>'),
        ),
      );

      for (final forbiddenRailBoundary in [
        '_repository.',
        'DatabaseService.',
        'DataSource',
        'DTO',
        'typedef ',
        'class ',
        'WordExplorerScreen(',
        'ExplorerWorkspaceState',
        'late String _centerWordId',
        'String? _selectedWordId',
        'WordDetailLikeDisplayItem? _selectedWordDisplayItem',
        '_history',
      ]) {
        expect(retargetRailSource, isNot(contains(forbiddenRailBoundary)));
      }
    });

    test('does not add reads, queries, DTOs, models, or public API', () {
      for (final source in [defaultStrongListSource, leftPaneControlSource]) {
        expect(source, isNot(contains('_repository.')));
        expect(source, isNot(contains('DatabaseService.')));
        expect(source, isNot(contains('DataSource')));
        expect(source, isNot(contains('DTO')));
      }
      expect(homeSource, isNot(contains('class HomeTargetFeedback')));
      expect(homeSource, isNot(contains('DisplayItem currentTarget')));
      expect(
        homeScreenWidgetSource,
        equalsIgnoringWhitespace('''
        class HomeScreen extends StatefulWidget {
          const HomeScreen({super.key});

          @override
          State<HomeScreen> createState() => _HomeScreenState();
        }
        '''),
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
