import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20-Q detail edit request result guardrail', () {
    late String routeResultSource;
    late String detailSource;
    late String detailWidgetSource;
    late String openEditSource;
    late String explorerSource;
    late String focusSelectedWordDetailPaneSource;
    late String openEditSelectedWordSource;
    late String confirmDeleteSource;
    late String openGraphSource;
    late String homeDetailRouteSource;

    setUpAll(() {
      routeResultSource = File(
        'lib/ui/word_detail_route_result.dart',
      ).readAsStringSync();

      detailSource = File('lib/ui/word_detail_screen.dart').readAsStringSync();
      detailWidgetSource = _sourceBetween(
        detailSource,
        'class WordDetailScreen extends StatefulWidget {',
        'class _WordDetailScreenState extends State<WordDetailScreen> {',
      );
      openEditSource = _sourceBetween(
        detailSource,
        'Future<void> _openEdit() async {',
        'Future<void> _openGraph() async {',
      );
      openGraphSource = _sourceBetween(
        detailSource,
        'Future<void> _openGraph() async {',
        'Future<void> _confirmDelete() async {',
      );
      confirmDeleteSource = _sourceBetween(
        detailSource,
        'Future<void> _confirmDelete() async {',
        'void _showWordNavigationUnavailableSnackBar() {',
      );

      explorerSource = File(
        'lib/ui/word_explorer_screen.dart',
      ).readAsStringSync();
      openEditSelectedWordSource = _sourceBetween(
        explorerSource,
        'Future<void> _openEditSelectedWord() async {',
        'void _focusSelectedWordDetailPane(double usableWidth) {',
      );
      focusSelectedWordDetailPaneSource = _sourceBetween(
        explorerSource,
        'void _focusSelectedWordDetailPane(double usableWidth) {',
        'void _showWordNavigationUnavailableSnackBar() {',
      );

      final homeSource = File('lib/ui/home_screen.dart').readAsStringSync();
      homeDetailRouteSource = _sourceBetween(
        homeSource,
        'Future<void> _openDefaultStrongWordDetail(String wordId) async {',
        'Future<void> _openDefaultStrongWordGraph(String wordId) async {',
      );
    });

    test('defines a typed edit request result with word id', () {
      expect(
        routeResultSource,
        contains(
          'final class WordDetailEditRequestedResult '
          'extends WordDetailRouteResult',
        ),
      );
      expect(
        routeResultSource,
        contains('const WordDetailEditRequestedResult({required this.wordId})'),
      );
    });

    test('keeps local detail edit route as the default', () {
      expect(
        detailWidgetSource,
        contains('final WordDetailEditActionMode editActionMode;'),
      );
      expect(
        detailWidgetSource,
        contains('this.editActionMode = WordDetailEditActionMode.localRoute'),
      );
      expect(detailWidgetSource, contains('this.showEditAction = true'));
      expect(homeDetailRouteSource, isNot(contains('editActionMode:')));
      expect(homeDetailRouteSource, isNot(contains('showEditAction:')));
      expect(homeDetailRouteSource, contains('WordDetailScreen('));
    });

    test('returns edit request before reading the detail edit seed', () {
      final returnModeIndex = openEditSource.indexOf(
        'WordDetailEditActionMode.returnToCaller',
      );
      final resultIndex = openEditSource.indexOf(
        'WordDetailEditRequestedResult(wordId: _wordId)',
      );
      final detailSeedIndex = openEditSource.indexOf(
        '_repository.getWordEditSeedForDetailEdit(_wordId)',
      );

      expect(returnModeIndex, greaterThanOrEqualTo(0));
      expect(resultIndex, greaterThan(returnModeIndex));
      expect(detailSeedIndex, greaterThan(resultIndex));
      expect(
        openEditSource,
        contains('WordEditScreen.fromSeed(seed: editSeed)'),
      );
      expect(openEditSource, contains('_refreshDetailScreenDisplayItem()'));
    });

    test('keeps caller edit mode contract but removes it from explorer', () {
      expect(detailSource, contains('WordDetailEditActionMode.returnToCaller'));
      expect(explorerSource, isNot(contains('WordDetailEditRequestedResult')));
      expect(
        explorerSource,
        isNot(
          contains('editActionMode: WordDetailEditActionMode.returnToCaller'),
        ),
      );
      expect(explorerSource, isNot(contains('WordDetailScreen(')));
      expect(
        detailSource,
        contains('onEdit: widget.showEditAction ? _openEdit : null'),
      );
      expect(homeDetailRouteSource, isNot(contains('editActionMode:')));
    });

    test('keeps explorer direct edit and graph refresh ownership', () {
      expect(explorerSource, contains('onEdit: _openEditSelectedWord'));
      expect(
        openEditSelectedWordSource,
        contains('_repository.getWordEditSeedForExplorerEdit('),
      );
      expect(
        openEditSelectedWordSource,
        contains('refreshGraphIfChanged: true'),
      );
    });

    test('focus action changes only the explorer split fraction', () {
      expect(
        focusSelectedWordDetailPaneSource,
        contains('_graphPaneFraction = focusedFraction'),
      );
      for (final ownerField in [
        '_selectedWordId',
        '_centerWordId',
        '_history',
        '_graphRevision',
      ]) {
        expect(
          focusSelectedWordDetailPaneSource,
          isNot(contains(ownerField)),
          reason: '$ownerField must not change during pane focus.',
        );
      }
      expect(focusSelectedWordDetailPaneSource, isNot(contains('Navigator.')));
      expect(
        focusSelectedWordDetailPaneSource,
        isNot(contains('_persistGraphPaneFractionForWidth')),
      );
    });

    test('keeps delete and graph action contracts unchanged', () {
      expect(
        confirmDeleteSource,
        contains(
          'Navigator.pop(context, WordDetailDeletedResult(wordId: _wordId))',
        ),
      );
      expect(
        openGraphSource,
        contains('WordDetailGraphRequestedResult(wordId: _wordId)'),
      );
      expect(
        openGraphSource,
        contains('builder: (context) => WordGraphScreen('),
      );
      expect(openGraphSource, contains('centerWordId: _wordId'));
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
