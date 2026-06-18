import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20-Q detail edit request result guardrail', () {
    late String routeResultSource;
    late String detailSource;
    late String detailWidgetSource;
    late String openEditSource;
    late String openSelectedWordDetailSource;
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

      final explorerSource = File(
        'lib/ui/word_explorer_screen.dart',
      ).readAsStringSync();
      openEditSelectedWordSource = _sourceBetween(
        explorerSource,
        'Future<void> _openEditSelectedWord() async {',
        'Future<void> _openSelectedWordDetail() async {',
      );
      openSelectedWordDetailSource = _sourceBetween(
        explorerSource,
        'Future<void> _openSelectedWordDetail() async {',
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

    test('uses edit caller mode only for explorer full-detail route', () {
      expect(
        openSelectedWordDetailSource,
        contains('editActionMode: WordDetailEditActionMode.returnToCaller'),
      );
      expect(
        openSelectedWordDetailSource,
        contains('graphActionMode: WordDetailGraphActionMode.returnToCaller'),
      );
      expect(openSelectedWordDetailSource, contains('showEditAction: false'));
      expect(
        detailSource,
        contains('onEdit: widget.showEditAction ? _openEdit : null'),
      );
      expect(homeDetailRouteSource, isNot(contains('editActionMode:')));
    });

    test('reuses explorer direct edit for edit request result', () {
      expect(
        openSelectedWordDetailSource,
        contains('if (detailResult is WordDetailEditRequestedResult)'),
      );
      expect(
        openSelectedWordDetailSource,
        contains('await _openEditSelectedWord()'),
      );
      expect(
        openSelectedWordDetailSource,
        isNot(contains('WordEditScreen.fromSeed')),
      );
      expect(
        openEditSelectedWordSource,
        contains('_repository.getWordEditSeedForExplorerEdit('),
      );
      expect(
        openEditSelectedWordSource,
        contains('refreshGraphIfChanged: true'),
      );
    });

    test('keeps delete edit graph and ordinary refresh result order', () {
      final deleteIndex = openSelectedWordDetailSource.indexOf(
        'if (detailResult is WordDetailDeletedResult)',
      );
      final editIndex = openSelectedWordDetailSource.indexOf(
        'if (detailResult is WordDetailEditRequestedResult)',
      );
      final graphIndex = openSelectedWordDetailSource.indexOf(
        'if (detailResult is WordDetailGraphRequestedResult)',
      );
      final refreshIndex = openSelectedWordDetailSource.lastIndexOf(
        'await _refreshSelectedWord(',
      );

      expect(deleteIndex, greaterThanOrEqualTo(0));
      expect(editIndex, greaterThan(deleteIndex));
      expect(graphIndex, greaterThan(editIndex));
      expect(refreshIndex, greaterThan(graphIndex));
      expect(
        openSelectedWordDetailSource,
        contains('_handleDeletedSelectedWord(wasCenterWord: wasCenterWord)'),
      );
      expect(
        openSelectedWordDetailSource,
        contains(
          'await _selectWord(detailResult.wordId, changeCenterWord: true)',
        ),
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
        contains('WordGraphScreen(centerWordId: _wordId)'),
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
