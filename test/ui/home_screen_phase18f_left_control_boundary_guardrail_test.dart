import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 18-F HomeScreen left control boundary guardrail', () {
    const homeSourcePath = 'lib/ui/home_screen.dart';
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';
    const wordGraphSourcePath = 'lib/ui/word_graph_screen.dart';
    const explorerWorkspaceSourcePath =
        'lib/ui/explorer_workspace/explorer_workspace.dart';

    late String homeSource;
    late String wordExplorerSource;
    late String wordGraphSource;
    late String explorerWorkspaceSource;
    late String homeStateFieldSource;
    late String wordExplorerFieldSource;
    late String defaultStrongListSource;
    late String leftPaneControlSource;
    late String leftPaneAndSplitSource;
    late String searchResultListSource;
    late String largeRetargetRequestSource;
    late String smallWidthBranch;
    late String largeSplitShellSource;
    late String strongJumpHelperSource;

    setUpAll(() {
      homeSource = _readText(homeSourcePath);
      wordExplorerSource = _readText(wordExplorerSourcePath);
      wordGraphSource = _readText(wordGraphSourcePath);
      explorerWorkspaceSource = _readText(explorerWorkspaceSourcePath);

      homeStateFieldSource = _sourceBetween(
        homeSource,
        'class _HomeScreenState extends State<HomeScreen> {',
        'Future<List<HomeDefaultStrongListItem>> _createDefaultStrongListFuture()',
      );
      wordExplorerFieldSource = _sourceBetween(
        wordExplorerSource,
        'class _WordExplorerScreenState extends State<WordExplorerScreen> {',
        'void initState() {',
      );
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
      leftPaneAndSplitSource = _sourceBetween(
        homeSource,
        'final isLargeScreen = _isLargeScreenWidth(',
        'void _runSearch() {',
      );
      searchResultListSource = _sourceBetween(
        leftPaneAndSplitSource,
        'FutureBuilder<List<HomeSearchResultDisplayItem>>',
        'return ListView.builder(',
      );
      largeRetargetRequestSource = _sourceBetween(
        homeSource,
        'void _showWordInLargeScreenExplorerPane(String wordId) {',
        'void _showWordNavigationUnavailableSnackBar() {',
      );
      smallWidthBranch = _sourceBetween(
        homeSource,
        'if (!isLargeScreen) {',
        'return Row(',
      );
      largeSplitShellSource = _sourceBetween(
        homeSource,
        'return Row(',
        'void _runSearch() {',
      );
      strongJumpHelperSource = _sourceBetween(
        homeSource,
        'void _handleSearchChanged(String value) {',
        'String _buildDefaultStrongListTitle(HomeDefaultStrongListItem item)',
      );
    });

    test(
      'large-screen left control surface only retargets and shows current target feedback',
      () {
        expect(
          homeSource,
          contains(
            'String _largeScreenExplorerWordId = _largeScreenDefaultExplorerWordId;',
          ),
        );
        expect(
          largeRetargetRequestSource,
          contains('final normalizedWordId = wordId.trim();'),
        );
        expect(
          largeRetargetRequestSource,
          contains('_largeScreenExplorerWordId == normalizedWordId'),
        );
        expect(
          largeRetargetRequestSource,
          contains('_largeScreenExplorerWordId = normalizedWordId;'),
        );
        expect(
          defaultStrongListSource,
          contains('item.wordId == _largeScreenExplorerWordId'),
        );
        expect(
          searchResultListSource,
          contains('wordId == _largeScreenExplorerWordId'),
        );
        expect(
          defaultStrongListSource,
          contains('selected: isCurrentLargeScreenTarget'),
        );
        expect(
          searchResultListSource,
          contains('selected: isCurrentLargeScreenTarget'),
        );
        expect(largeRetargetRequestSource, isNot(contains('Navigator.push')));
        expect(largeRetargetRequestSource, isNot(contains('_repository.')));
        expect(
          largeRetargetRequestSource,
          isNot(contains('WordExplorerScreen(')),
        );
        expect(
          largeRetargetRequestSource,
          isNot(contains('ExplorerWorkspaceState')),
        );
      },
    );

    test('HomeScreen does not own WordExplorerScreen internal owner state', () {
      expect(wordExplorerFieldSource, contains('late String _centerWordId;'));
      expect(wordExplorerFieldSource, contains('String? _selectedWordId;'));
      expect(
        wordExplorerFieldSource,
        contains('WordDetailLikeDisplayItem? _selectedWordDisplayItem;'),
      );
      expect(
        wordExplorerFieldSource,
        contains('bool _isDetailLoading = false;'),
      );
      expect(wordExplorerFieldSource, contains('String? _detailError;'));
      expect(
        wordExplorerFieldSource,
        contains('String? _detailUnavailableMessage;'),
      );
      expect(
        wordExplorerFieldSource,
        contains('WordNavigationHistoryController<_ExplorerHistorySnapshot>'),
      );

      for (final forbiddenOwnerField in [
        'late String _centerWordId;',
        'String? _selectedWordId;',
        'WordDetailLikeDisplayItem? _selectedWordDisplayItem;',
        'bool _isDetailLoading',
        'String? _detailError',
        'String? _detailUnavailableMessage',
        'WordNavigationHistoryController<_ExplorerHistorySnapshot>',
      ]) {
        expect(homeStateFieldSource, isNot(contains(forbiddenOwnerField)));
      }
    });

    test(
      'ExplorerWorkspaceState is not used as HomeScreen production source of truth',
      () {
        expect(homeSource, isNot(contains('ExplorerWorkspace(')));
        expect(homeSource, isNot(contains('ExplorerWorkspaceState')));
        expect(homeSource, isNot(contains('ExplorerWorkspacePreviewScreen')));
        expect(
          homeSource,
          isNot(contains('ExplorerWorkspacePreviewInteractionHost')),
        );
        expect(largeSplitShellSource, contains('WordExplorerScreen('));
        expect(
          largeSplitShellSource,
          contains('key: ValueKey(_largeScreenExplorerWordId)'),
        );
        expect(
          largeSplitShellSource,
          contains('initialWordId: _largeScreenExplorerWordId'),
        );
      },
    );

    test('small-screen route detail flow remains unchanged', () {
      expect(smallWidthBranch, contains('return homePane;'));
      expect(smallWidthBranch, isNot(contains('WordExplorerScreen(')));
      expect(smallWidthBranch, isNot(contains('ExplorerWorkspace(')));
      expect(
        smallWidthBranch,
        isNot(contains('ValueKey(_largeScreenExplorerWordId)')),
      );
      expect(
        homeSource,
        contains('await _openDefaultStrongWordDetail(item.wordId);'),
      );
      expect(homeSource, contains('await _openWordDetail(wordId);'));
      expect(
        homeSource,
        contains('WordExplorerScreen(initialWordId: normalizedWordId)'),
      );
    });

    test(
      'default Strong and search result lists do not become selection or repository owners',
      () {
        for (final listSource in [
          defaultStrongListSource,
          searchResultListSource,
        ]) {
          expect(listSource, isNot(contains('late String _centerWordId')));
          expect(listSource, isNot(contains('String? _selectedWordId')));
          expect(
            listSource,
            isNot(
              contains('WordDetailLikeDisplayItem? _selectedWordDisplayItem'),
            ),
          );
          expect(listSource, isNot(contains('_history')));
          expect(listSource, isNot(contains('ExplorerWorkspaceState')));
          expect(listSource, isNot(contains('_repository.')));
          expect(listSource, isNot(contains('DatabaseService.')));
          expect(listSource, isNot(contains('DataSource')));
          expect(listSource, isNot(contains('DTO')));
        }
      },
    );

    test('left surface does not open create edit write entries directly', () {
      expect(wordGraphSource, contains('Future<void> _showCreateWordFlow()'));
      expect(wordGraphSource, contains('onPressed: _showCreateWordFlow'));
      expect(wordGraphSource, contains('WordEditScreen.fromSeed'));
      expect(wordGraphSource, contains('Icons.note_add'));

      for (final leftSurfaceSource in [
        leftPaneControlSource,
        leftPaneAndSplitSource,
        defaultStrongListSource,
        searchResultListSource,
      ]) {
        expect(leftSurfaceSource, isNot(contains('_showCreateWordFlow')));
        expect(leftSurfaceSource, isNot(contains('WordEditScreen.fromSeed')));
        expect(leftSurfaceSource, isNot(contains('Icons.note_add')));
        expect(leftSurfaceSource, isNot(contains('onAddWordRequested')));
        expect(leftSurfaceSource, isNot(contains('createWord')));
        expect(leftSurfaceSource, isNot(contains('updateWord')));
        expect(leftSurfaceSource, isNot(contains('insertWord')));
      }
    });

    test(
      'strong jump helper stays within default list scroll helper scope',
      () {
        expect(
          strongJumpHelperSource,
          contains('_jumpToStrongInDefaultList(normalizedStrong'),
        );
        expect(
          strongJumpHelperSource,
          contains('_scrollToDefaultStrongIndex(targetIndex);'),
        );
        expect(
          strongJumpHelperSource,
          contains('_showStrongJumpNotFoundSnackBar(normalizedStrong);'),
        );
        expect(
          strongJumpHelperSource,
          isNot(contains('_showWordInLargeScreenExplorerPane')),
        );
        expect(
          strongJumpHelperSource,
          isNot(contains('_largeScreenExplorerWordId')),
        );
        expect(strongJumpHelperSource, isNot(contains('Navigator.push')));
        expect(strongJumpHelperSource, isNot(contains('_repository.')));
        expect(strongJumpHelperSource, isNot(contains('WordExplorerScreen(')));
        expect(
          strongJumpHelperSource,
          isNot(contains('ExplorerWorkspaceState')),
        );
      },
    );

    test(
      'Strong Rail keyboard and search continuity remain outside production HomeScreen implementation',
      () {
        expect(homeSource, isNot(contains('StrongRail')));
        expect(homeSource, isNot(contains('Strong Rail')));
        expect(explorerWorkspaceSource, contains("title: 'StrongRail'"));
        expect(explorerWorkspaceSource, isNot(contains('class StrongRail')));
        expect(explorerWorkspaceSource, isNot(contains('StrongRail(')));
        expect(
          explorerWorkspaceSource,
          isNot(contains('StrongRailController')),
        );

        for (final productionSurfaceSource in [
          leftPaneAndSplitSource,
          explorerWorkspaceSource,
        ]) {
          expect(productionSurfaceSource, isNot(contains('KeyboardListener')));
          expect(
            productionSurfaceSource,
            isNot(contains('RawKeyboardListener')),
          );
          expect(productionSurfaceSource, isNot(contains('Shortcuts(')));
          expect(productionSurfaceSource, isNot(contains('Actions(')));
          expect(
            productionSurfaceSource,
            isNot(contains('FocusTraversalGroup')),
          );
          expect(
            productionSurfaceSource,
            isNot(contains('SearchListContinuity')),
          );
          expect(
            productionSurfaceSource,
            isNot(contains('searchListContinuity')),
          );
          expect(productionSurfaceSource, isNot(contains('continuity')));
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
