import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20-S delete result contract guardrail', () {
    late String graphDeleteCallbackSource;
    late String centerDeleteFallbackSource;
    late String confirmDeleteSource;
    late String homeSource;
    late String homeDetailRouteSource;
    late String handleDeletedSelectedWordSource;
    late String productionSource;

    setUpAll(() {
      final explorerSource = File(
        'lib/ui/word_explorer_screen.dart',
      ).readAsStringSync();
      graphDeleteCallbackSource = _sourceBetween(
        explorerSource,
        'Future<void> _handleGraphDeletedSelectedWord(',
        'Future<void> _handleDeletedSelectedWord({required bool wasCenterWord})',
      );
      handleDeletedSelectedWordSource = _sourceBetween(
        explorerSource,
        'Future<void> _handleDeletedSelectedWord({required bool wasCenterWord}) '
            'async {',
        'void _clearSelectedWordPanel({bool refreshGraph = false}) {',
      );
      final nextHistoryIndex = handleDeletedSelectedWordSource.indexOf(
        'final nextEntry = _history.nextEntry;',
      );
      if (nextHistoryIndex < 0) {
        throw StateError('Cannot find center delete next history fallback');
      }
      centerDeleteFallbackSource = handleDeletedSelectedWordSource.substring(
        nextHistoryIndex,
      );

      final detailSource = File(
        'lib/ui/word_detail_screen.dart',
      ).readAsStringSync();
      confirmDeleteSource = _sourceBetween(
        detailSource,
        'Future<void> _confirmDelete() async {',
        'void _showWordNavigationUnavailableSnackBar() {',
      );

      homeSource = File('lib/ui/home_screen.dart').readAsStringSync();
      homeDetailRouteSource = _sourceBetween(
        homeSource,
        'Future<void> _openDefaultStrongWordDetail(String wordId) async {',
        'Future<void> _openDefaultStrongWordGraph(String wordId) async {',
      );

      productionSource = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.readAsStringSync())
          .join('\n');
    });

    test('compares trimmed graph deleted word id with selected word id', () {
      final deletedWordIdIndex = graphDeleteCallbackSource.indexOf(
        'final normalizedDeletedWordId = deletedWordId.trim();',
      );
      final expectedDeletedWordIdIndex = graphDeleteCallbackSource.indexOf(
        'final expectedDeletedWordId = selectedWordId.trim();',
      );
      final mismatchIndex = graphDeleteCallbackSource.indexOf(
        'if (normalizedDeletedWordId != expectedDeletedWordId)',
      );

      expect(deletedWordIdIndex, greaterThanOrEqualTo(0));
      expect(expectedDeletedWordIdIndex, greaterThan(deletedWordIdIndex));
      expect(mismatchIndex, greaterThan(expectedDeletedWordIdIndex));
    });

    test('returns from mismatch refresh before deleted selection recovery', () {
      final mismatchSource = _sourceBetween(
        graphDeleteCallbackSource,
        'if (normalizedDeletedWordId != expectedDeletedWordId) {',
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
      final mismatchIndex = graphDeleteCallbackSource.indexOf(
        'if (normalizedDeletedWordId != expectedDeletedWordId)',
      );
      final mismatchReturnIndex = graphDeleteCallbackSource.indexOf(
        'return;',
        mismatchIndex,
      );
      final handleIndex = graphDeleteCallbackSource.indexOf(
        'await _handleDeletedSelectedWord(wasCenterWord: wasCenterWord);',
      );

      expect(mismatchIndex, greaterThanOrEqualTo(0));
      expect(mismatchReturnIndex, greaterThan(mismatchIndex));
      expect(handleIndex, greaterThan(mismatchReturnIndex));
      expect(
        '_handleDeletedSelectedWord(wasCenterWord: wasCenterWord)'.allMatches(
          graphDeleteCallbackSource,
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

    test(
      'keeps home default detail route and guards embedded explorer fallback',
      () {
        expect(
          homeDetailRouteSource,
          contains('Navigator.push<WordDetailRouteResult>('),
        );
        expect(homeDetailRouteSource, contains('WordDetailScreen('));
        expect(homeDetailRouteSource, contains('_refreshWords();'));
        expect(homeDetailRouteSource, isNot(contains('editActionMode:')));
        expect(homeDetailRouteSource, isNot(contains('graphActionMode:')));
        expect(
          centerDeleteFallbackSource,
          isNot(contains('Navigator.pop(context, true)')),
        );
        expect(
          centerDeleteFallbackSource,
          contains('_clearSelectedWordPanel(refreshGraph: true);'),
        );
      },
    );

    test(
      'keeps one home embedded explorer usage with no route push caller',
      () {
        expect(
          'WordExplorerScreen('.allMatches(productionSource),
          hasLength(2),
        );
        expect('WordExplorerScreen('.allMatches(homeSource), hasLength(1));
        expect(homeSource, contains('child: WordExplorerScreen('));
      },
    );
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
