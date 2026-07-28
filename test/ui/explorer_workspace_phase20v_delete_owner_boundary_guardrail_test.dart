import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20-V delete owner boundary guardrail', () {
    late String confirmDeleteSource;
    late String detailSource;
    late String graphDeleteCallbackSource;
    late String explorerSource;
    late String homeDetailRouteSource;
    late String productionSource;
    late String routeResultSource;

    setUpAll(() {
      detailSource = File('lib/ui/word_detail_screen.dart').readAsStringSync();
      confirmDeleteSource = _sourceBetween(
        detailSource,
        'Future<void> _confirmDelete() async {',
        'void _showWordNavigationUnavailableSnackBar() {',
      );

      routeResultSource = File(
        'lib/ui/word_detail_route_result.dart',
      ).readAsStringSync();

      explorerSource = File(
        'lib/ui/word_explorer_screen.dart',
      ).readAsStringSync();
      graphDeleteCallbackSource = _sourceBetween(
        explorerSource,
        'Future<void> _handleGraphDeletedSelectedWord(',
        'Future<void> _handleDeletedSelectedWord({required bool wasCenterWord})',
      );

      final homeSource = File('lib/ui/home_screen.dart').readAsStringSync();
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

    test('keeps completed delete execution in detail confirm flow', () {
      final relationCountIndex = confirmDeleteSource.indexOf(
        '_repository.countRelationsForWord(_wordId)',
      );
      final deleteCommandIndex = confirmDeleteSource.indexOf(
        'DeleteWordCommand(wordId: _wordId)',
      );
      final cacheClearIndex = confirmDeleteSource.indexOf(
        'WordGraphDataCache.clear()',
      );
      final completedResultIndex = confirmDeleteSource.indexOf(
        'WordDetailDeletedResult(wordId: _wordId)',
      );

      expect(relationCountIndex, greaterThanOrEqualTo(0));
      expect(deleteCommandIndex, greaterThan(relationCountIndex));
      expect(cacheClearIndex, greaterThan(deleteCommandIndex));
      expect(completedResultIndex, greaterThan(cacheClearIndex));
    });

    test('does not define delete caller request mode or requested result', () {
      expect(productionSource, isNot(contains('WordDetailDeleteActionMode')));
      expect(productionSource, isNot(contains('deleteActionMode')));
      expect(
        productionSource,
        isNot(contains('WordDetailDeleteRequestedResult')),
      );
      expect(
        routeResultSource,
        contains(
          'final class WordDetailDeletedResult extends WordDetailRouteResult',
        ),
      );
    });

    test(
      'removes the detail route and keeps graph delete callback in explorer',
      () {
        expect(explorerSource, isNot(contains('WordDetailScreen(')));
        expect(
          explorerSource,
          contains('onDeletedSelectedWord: _handleGraphDeletedSelectedWord'),
        );
      },
    );

    test('keeps explorer as embedded graph delete callback interpreter', () {
      final deletedWordIdIndex = graphDeleteCallbackSource.indexOf(
        'final normalizedDeletedWordId = deletedWordId.trim();',
      );
      final expectedDeletedWordIdIndex = graphDeleteCallbackSource.indexOf(
        'final expectedDeletedWordId = selectedWordId.trim();',
      );
      final mismatchIndex = graphDeleteCallbackSource.indexOf(
        'if (normalizedDeletedWordId != expectedDeletedWordId)',
      );
      final mismatchReturnIndex = graphDeleteCallbackSource.indexOf(
        'return;',
        mismatchIndex,
      );
      final recoveryIndex = graphDeleteCallbackSource.indexOf(
        'await _handleDeletedSelectedWord(wasCenterWord: wasCenterWord);',
      );

      expect(deletedWordIdIndex, greaterThanOrEqualTo(0));
      expect(expectedDeletedWordIdIndex, greaterThan(deletedWordIdIndex));
      expect(mismatchIndex, greaterThan(expectedDeletedWordIdIndex));
      expect(mismatchReturnIndex, greaterThan(mismatchIndex));
      expect(recoveryIndex, greaterThan(mismatchReturnIndex));
    });

    test('refreshes mismatch without running delete recovery', () {
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

    test('does not make explorer a delete executor or cache clear owner', () {
      expect(explorerSource, isNot(contains('DeleteWordCommand')));
      expect(explorerSource, isNot(contains('WordWriteService')));
      expect(explorerSource, isNot(contains('WordGraphDataCache.clear()')));
    });

    test('keeps home default detail route without delete mode', () {
      expect(
        homeDetailRouteSource,
        contains('Navigator.push<WordDetailRouteResult>('),
      );
      expect(homeDetailRouteSource, contains('WordDetailScreen('));
      expect(homeDetailRouteSource, contains('_refreshWords();'));
      expect(homeDetailRouteSource, isNot(contains('deleteActionMode:')));
      expect(
        homeDetailRouteSource,
        isNot(contains('WordDetailDeleteActionMode')),
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
