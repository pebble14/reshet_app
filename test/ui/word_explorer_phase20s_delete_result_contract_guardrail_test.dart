import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20-S delete result contract guardrail', () {
    late String deletedResultBranchSource;
    late String confirmDeleteSource;
    late String homeDetailRouteSource;
    late String handleDeletedSelectedWordSource;

    setUpAll(() {
      final explorerSource = File(
        'lib/ui/word_explorer_screen.dart',
      ).readAsStringSync();
      final openSelectedWordDetailSource = _sourceBetween(
        explorerSource,
        'Future<void> _openSelectedWordDetail() async {',
        'void _showWordNavigationUnavailableSnackBar() {',
      );
      deletedResultBranchSource = _sourceBetween(
        openSelectedWordDetailSource,
        'if (detailResult is WordDetailDeletedResult) {',
        'if (detailResult is WordDetailEditRequestedResult) {',
      );
      handleDeletedSelectedWordSource = _sourceBetween(
        explorerSource,
        'Future<void> _handleDeletedSelectedWord({required bool wasCenterWord}) '
            'async {',
        'void _clearSelectedWordPanel({bool refreshGraph = false}) {',
      );

      final detailSource = File(
        'lib/ui/word_detail_screen.dart',
      ).readAsStringSync();
      confirmDeleteSource = _sourceBetween(
        detailSource,
        'Future<void> _confirmDelete() async {',
        'void _showWordNavigationUnavailableSnackBar() {',
      );

      final homeSource = File('lib/ui/home_screen.dart').readAsStringSync();
      homeDetailRouteSource = _sourceBetween(
        homeSource,
        'Future<void> _openDefaultStrongWordDetail(String wordId) async {',
        'Future<void> _openDefaultStrongWordGraph(String wordId) async {',
      );
    });

    test(
      'compares trimmed deleted result word id with route selected word id',
      () {
        final deletedWordIdIndex = deletedResultBranchSource.indexOf(
          'final deletedWordId = detailResult.wordId.trim();',
        );
        final expectedDeletedWordIdIndex = deletedResultBranchSource.indexOf(
          'final expectedDeletedWordId = selectedWordId.trim();',
        );
        final mismatchIndex = deletedResultBranchSource.indexOf(
          'if (deletedWordId != expectedDeletedWordId)',
        );

        expect(deletedWordIdIndex, greaterThanOrEqualTo(0));
        expect(expectedDeletedWordIdIndex, greaterThan(deletedWordIdIndex));
        expect(mismatchIndex, greaterThan(expectedDeletedWordIdIndex));
      },
    );

    test('returns from mismatch refresh before deleted selection recovery', () {
      final mismatchSource = _sourceBetween(
        deletedResultBranchSource,
        'if (deletedWordId != expectedDeletedWordId) {',
        'await _handleDeletedSelectedWord(wasCenterWord: wasCenterWord);',
      );

      expect(mismatchSource, contains('await _refreshSelectedWord('));
      expect(mismatchSource, contains('wordId: selectedWordId'));
      expect(mismatchSource, contains('syncCenterWord: wasCenterWord'));
      expect(mismatchSource, contains('refreshGraphIfChanged: true'));
      expect(mismatchSource, contains('return;'));
      expect(mismatchSource, isNot(contains('_handleDeletedSelectedWord(')));
    });

    test('keeps deleted selection recovery only after mismatch return', () {
      final mismatchIndex = deletedResultBranchSource.indexOf(
        'if (deletedWordId != expectedDeletedWordId)',
      );
      final mismatchReturnIndex = deletedResultBranchSource.indexOf(
        'return;',
        mismatchIndex,
      );
      final handleIndex = deletedResultBranchSource.indexOf(
        'await _handleDeletedSelectedWord(wasCenterWord: wasCenterWord);',
      );

      expect(mismatchIndex, greaterThanOrEqualTo(0));
      expect(mismatchReturnIndex, greaterThan(mismatchIndex));
      expect(handleIndex, greaterThan(mismatchReturnIndex));
      expect(
        '_handleDeletedSelectedWord(wasCenterWord: wasCenterWord)'.allMatches(
          deletedResultBranchSource,
        ),
        hasLength(1),
      );
    });

    test('keeps detail delete owner and typed deleted result unchanged', () {
      expect(confirmDeleteSource, contains('Future<void> _confirmDelete()'));
      expect(
        confirmDeleteSource,
        contains('DeleteWordCommand(wordId: _wordId)'),
      );
      expect(confirmDeleteSource, contains('WordGraphDataCache.clear()'));
      expect(
        confirmDeleteSource,
        contains(
          'Navigator.pop(context, WordDetailDeletedResult(wordId: _wordId))',
        ),
      );
    });

    test('keeps home default detail route and explorer host bool result', () {
      expect(
        homeDetailRouteSource,
        contains('Navigator.push<WordDetailRouteResult>('),
      );
      expect(homeDetailRouteSource, contains('WordDetailScreen('));
      expect(homeDetailRouteSource, contains('_refreshWords();'));
      expect(homeDetailRouteSource, isNot(contains('editActionMode:')));
      expect(homeDetailRouteSource, isNot(contains('graphActionMode:')));
      expect(
        handleDeletedSelectedWordSource,
        contains('Navigator.pop(context, true)'),
      );
    });
  });
}

String _sourceBetween(String source, String start, String end) {
  final startIndex = source.indexOf(start);
  final endIndex = source.indexOf(end, startIndex + start.length);

  if (startIndex < 0 || endIndex < 0) {
    throw StateError('Cannot find source boundary: $start -> $end');
  }

  return source.substring(startIndex, endIndex);
}
