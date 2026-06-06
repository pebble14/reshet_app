import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 19-B HomeScreen top search surface presentation boundary', () {
    const homeSourcePath = 'lib/ui/home_screen.dart';
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';

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
    late String strongJumpHandlerSource;
    late String passiveSelectedHandlerSource;
    late String searchResultTapSource;
    late String wordExplorerFieldSource;

    setUpAll(() {
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
      searchResultTapSource = _sourceBetween(
        homeWordListSurfaceSource,
        'onTap: () async {',
        'return ListView.builder(',
      );
      wordExplorerFieldSource = _sourceBetween(
        wordExplorerSource,
        'class _WordExplorerScreenState extends State<WordExplorerScreen> {',
        'void initState() {',
      );
    });

    test(
      'large-screen mounts general search above the full split workspace',
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
          homeWorkspaceSearchSurfaceSource,
          contains('child: homeSearchControlArea'),
        );
        expect(largeWorkspaceSource, contains('return Row('));
        expect(largeWorkspaceSource, contains('child: Column('));
        expect(largeWorkspaceSource, contains('homeWorkspaceSearchSurface'));
        expect(largeWorkspaceSource, contains('child: Row('));
        expect(
          _appearsBefore(
            largeWorkspaceSource,
            'homeWorkspaceSearchSurface',
            'Expanded(flex: 2, child: homePane)',
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
      },
    );

    test('left control surface keeps Strong input, Rail, and word lists', () {
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
        contains('Expanded(child: homeWordListSurface)'),
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
    });

    test('top search preserves HomeScreen owner and submit-only boundary', () {
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
      expect(runSearchSource, contains('_searchController.text.trim()'));
      expect(runSearchSource, contains('_isShowingDefaultStrongList = false;'));
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
    });

    test(
      'explicit candidate tap keeps the existing Explorer retarget path',
      () {
        expect(
          searchResultTapSource,
          contains('_showWordInLargeScreenExplorerPane(wordId);'),
        );
        expect(
          searchResultTapSource,
          contains('await _openWordDetail(wordId);'),
        );
      },
    );

    test('Strong jump and graph passive sync paths remain unchanged', () {
      expect(
        strongJumpHandlerSource,
        contains('_strongJumpController.text.trim()'),
      );
      expect(strongJumpHandlerSource, contains('_jumpToStrongInRail('));
      expect(
        passiveSelectedHandlerSource,
        contains(
          '_jumpToStrongInRail(normalizedDisplayStrong, showNotFoundFeedback: false);',
        ),
      );

      for (final source in [
        strongJumpHandlerSource,
        passiveSelectedHandlerSource,
      ]) {
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
          expect(source, isNot(contains(forbiddenAction)));
        }
      }
    });

    test('small-screen keeps the existing search and detail route flow', () {
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

    test('does not promote workspace, Explorer, data, or write ownership', () {
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

      for (final presentationSource in [
        homeSearchControlAreaSource,
        homeStrongControlAreaSource,
        homeWorkspaceSearchSurfaceSource,
        largeWorkspaceSource,
      ]) {
        for (final forbiddenBoundary in [
          '_repository.',
          'DatabaseService.',
          'DataSource',
          'DTO',
          'typedef ',
          'class ',
          'WordEditScreen.fromSeed',
          'Icons.note_add',
          'KeyboardListener',
          'RawKeyboardListener',
          'Shortcuts(',
          'Actions(',
        ]) {
          expect(presentationSource, isNot(contains(forbiddenBoundary)));
        }
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
