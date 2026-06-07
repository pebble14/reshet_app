import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 18-K graph selection Strong Rail passive sync boundary', () {
    const homeSourcePath = 'lib/ui/home_screen.dart';
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';

    late String homeSource;
    late String wordExplorerSource;
    late String homeStateFieldSource;
    late String passiveCallbackHandlerSource;
    late String retargetRailSource;
    late String railForegroundFeedbackSource;
    late String railBorderFeedbackSource;
    late String railBackgroundFeedbackSource;
    late String largeRetargetRequestSource;
    late String largeSplitShellSource;
    late String wordExplorerWidgetContractSource;
    late String wordExplorerFieldSource;
    late String selectWordSource;
    late String notifySelectedStrongSource;
    late String clearSelectionSource;

    setUpAll(() {
      homeSource = _readText(homeSourcePath);
      wordExplorerSource = _readText(wordExplorerSourcePath);

      homeStateFieldSource = _sourceBetween(
        homeSource,
        'class _HomeScreenState extends State<HomeScreen> {',
        'Future<List<HomeDefaultStrongListItem>> _createDefaultStrongListFuture()',
      );
      passiveCallbackHandlerSource = _sourceBetween(
        homeSource,
        'void _handleExplorerSelectedStrongWordChanged(',
        'String _buildDefaultStrongListTitle(HomeDefaultStrongListItem item)',
      );
      retargetRailSource = _sourceBetween(
        homeSource,
        'Widget _buildStrongLevelOneRetargetRail()',
        'Widget _buildDefaultStrongListView()',
      );
      railForegroundFeedbackSource = _sourceBetween(
        retargetRailSource,
        'final foregroundColor =',
        'final borderColor =',
      );
      railBorderFeedbackSource = _sourceBetween(
        retargetRailSource,
        'final borderColor =',
        'final backgroundColor =',
      );
      railBackgroundFeedbackSource = _sourceBetween(
        retargetRailSource,
        'final backgroundColor =',
        'return Padding(',
      );
      largeRetargetRequestSource = _sourceBetween(
        homeSource,
        'void _showWordInLargeScreenExplorerPane(String wordId) {',
        'void _showWordNavigationUnavailableSnackBar() {',
      );
      largeSplitShellSource = _sourceBetween(
        homeSource,
        'return Row(',
        'void _runSearch() {',
      );
      wordExplorerWidgetContractSource = _sourceBetween(
        wordExplorerSource,
        'class WordExplorerScreen extends StatefulWidget {',
        'class _WordExplorerScreenState extends State<WordExplorerScreen> {',
      );
      wordExplorerFieldSource = _sourceBetween(
        wordExplorerSource,
        'class _WordExplorerScreenState extends State<WordExplorerScreen> {',
        'void initState() {',
      );
      selectWordSource = _sourceBetween(
        wordExplorerSource,
        'Future<void> _selectWord(',
        'Future<WordDetailLikeDisplayItem?> _loadSplitViewDisplayItem(',
      );
      notifySelectedStrongSource = _sourceBetween(
        wordExplorerSource,
        'void _notifySelectedStrongWordChanged({',
        'Future<WordDetailLikeDisplayItem?> _loadSplitViewDisplayItem(',
      );
      clearSelectionSource = _sourceBetween(
        wordExplorerSource,
        'void _clearSelectedWordPanel({bool refreshGraph = false})',
        'List<Widget> _buildHistoryActions()',
      );
    });

    test('WordExplorerScreen exposes only an optional passive callback', () {
      expect(
        wordExplorerWidgetContractSource,
        contains(
          'final void Function(String wordId, String displayStrongNumber)?',
        ),
      );
      expect(
        wordExplorerWidgetContractSource,
        contains('onSelectedStrongWordChanged;'),
      );
      expect(
        wordExplorerWidgetContractSource,
        contains('this.onSelectedStrongWordChanged,'),
      );
      expect(
        homeSource,
        contains('WordExplorerScreen(initialWordId: normalizedWordId)'),
      );
      expect(wordExplorerWidgetContractSource, isNot(contains('DTO')));
      expect(wordExplorerWidgetContractSource, isNot(contains('typedef ')));
    });

    test('HomeScreen large-screen Explorer mount passes callback only', () {
      expect(largeSplitShellSource, contains('key: ValueKey('));
      expect(largeSplitShellSource, contains('initialWordId:'));
      expect(largeSplitShellSource, contains('_largeScreenExplorerWordId'));
      expect(largeSplitShellSource, contains('onSelectedStrongWordChanged:'));
      expect(
        largeSplitShellSource,
        contains('_handleExplorerSelectedStrongWordChanged'),
      );
      expect(_countOccurrences(largeSplitShellSource, 'ValueKey('), 1);
      expect(_countOccurrences(largeSplitShellSource, 'initialWordId:'), 1);
    });

    test('callback handler owns only rail-local passive state and jump', () {
      expect(
        homeStateFieldSource,
        contains('String? _passiveSelectedStrongWordId;'),
      );
      expect(
        homeStateFieldSource,
        contains('String? _passiveSelectedDisplayStrongNumber;'),
      );
      expect(
        passiveCallbackHandlerSource,
        contains('final normalizedWordId = wordId.trim();'),
      );
      expect(
        passiveCallbackHandlerSource,
        contains(
          'final normalizedDisplayStrong = _formatDisplayStrong(displayStrongNumber);',
        ),
      );
      expect(
        passiveCallbackHandlerSource,
        contains(
          '_jumpToStrongInRail(normalizedDisplayStrong, showNotFoundFeedback: false);',
        ),
      );

      for (final forbiddenHandlerSource in [
        '_largeScreenExplorerWordId =',
        '_showWordInLargeScreenExplorerPane',
        '_repository.',
        'DatabaseService',
        'Navigator.push',
        'ExplorerWorkspaceState',
        'WordExplorerScreen(',
        '_setVisibleWordListFuture',
        '_searchWordsFuture',
        '_isShowingDefaultStrongList =',
        'DTO',
        'typedef ',
        'class ',
      ]) {
        expect(
          passiveCallbackHandlerSource,
          isNot(contains(forbiddenHandlerSource)),
        );
      }
    });

    test(
      'empty Strong selection clears passive feedback without retargeting',
      () {
        expect(
          passiveCallbackHandlerSource,
          contains('if (normalizedDisplayStrong.isEmpty) {'),
        );
        expect(
          passiveCallbackHandlerSource,
          contains('_passiveSelectedStrongWordId = null;'),
        );
        expect(
          passiveCallbackHandlerSource,
          contains('_passiveSelectedDisplayStrongNumber = null;'),
        );
        expect(
          notifySelectedStrongSource,
          contains("(selectedDisplayItem?.displayStrongNumber ?? '').trim()"),
        );
        expect(
          notifySelectedStrongSource,
          contains('callback(normalizedSelectedWordId, displayStrongNumber);'),
        );
        expect(
          passiveCallbackHandlerSource,
          isNot(contains('_largeScreenExplorerWordId =')),
        );
        expect(
          passiveCallbackHandlerSource,
          isNot(contains('_showWordInLargeScreenExplorerPane')),
        );
      },
    );

    test('target feedback and passive selected feedback stay separated', () {
      expect(
        retargetRailSource,
        contains('item.wordId == _largeScreenExplorerWordId'),
      );
      expect(
        retargetRailSource,
        contains('displayStrong == _passiveSelectedDisplayStrongNumber'),
      );
      expect(retargetRailSource, contains('final isCurrentLargeScreenTarget'));
      expect(retargetRailSource, contains('final isPassiveSelectedStrong'));
      expect(retargetRailSource, contains('if (isPassiveSelectedStrong)'));
      expect(
        retargetRailSource,
        contains('theme.colorScheme.primaryContainer'),
      );
      expect(
        retargetRailSource,
        contains('theme.colorScheme.secondaryContainer'),
      );
      expect(retargetRailSource, contains('theme.colorScheme.secondary'));

      for (final feedbackSource in [
        railForegroundFeedbackSource,
        railBorderFeedbackSource,
        railBackgroundFeedbackSource,
      ]) {
        expect(
          _appearsBefore(
            feedbackSource,
            'isCurrentLargeScreenTarget',
            'isPassiveSelectedStrong',
          ),
          isTrue,
        );
      }

      for (final forbiddenRailSource in [
        '_repository.',
        'DatabaseService',
        'DataSource',
        'DTO',
        'typedef ',
        'class ',
        'Navigator.push',
        'ExplorerWorkspaceState',
      ]) {
        expect(retargetRailSource, isNot(contains(forbiddenRailSource)));
      }
    });

    test('graph passive sync does not retarget or remount Explorer', () {
      for (final graphSelectionSource in [
        passiveCallbackHandlerSource,
        selectWordSource,
      ]) {
        expect(
          graphSelectionSource,
          isNot(contains('_largeScreenExplorerWordId =')),
        );
        expect(
          graphSelectionSource,
          isNot(contains('_showWordInLargeScreenExplorerPane')),
        );
        expect(graphSelectionSource, isNot(contains('WordExplorerScreen(')));
        expect(graphSelectionSource, isNot(contains('Navigator.push')));
        expect(graphSelectionSource, isNot(contains('ExplorerWorkspaceState')));
        expect(graphSelectionSource, isNot(contains('DatabaseService')));
      }

      expect(
        largeRetargetRequestSource,
        contains('_largeScreenExplorerWordId = normalizedWordId;'),
      );
      expect(largeSplitShellSource, contains('key: ValueKey('));
      expect(largeSplitShellSource, contains('initialWordId:'));
      expect(largeSplitShellSource, contains('_largeScreenExplorerWordId'));
    });

    test(
      'selection stale guard blocks older async callback and state update',
      () {
        expect(
          wordExplorerFieldSource,
          contains('int _selectionRequestToken = 0;'),
        );
        expect(
          selectWordSource,
          contains('final selectionRequestToken = ++_selectionRequestToken;'),
        );
        expect(
          _countOccurrences(
            selectWordSource,
            'selectionRequestToken != _selectionRequestToken',
          ),
          2,
        );
        expect(
          _appearsBefore(
            selectWordSource,
            'selectionRequestToken != _selectionRequestToken',
            '_selectedWordId = resolvedSelectedWordId;',
          ),
          isTrue,
        );
        expect(
          _appearsBefore(
            selectWordSource,
            'selectionRequestToken != _selectionRequestToken',
            '_notifySelectedStrongWordChanged(',
          ),
          isTrue,
        );
        expect(clearSelectionSource, contains('_selectionRequestToken++;'));
        expect(clearSelectionSource, contains("selectedWordId: '',"));
        expect(clearSelectionSource, contains('selectedDisplayItem: null,'));
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
