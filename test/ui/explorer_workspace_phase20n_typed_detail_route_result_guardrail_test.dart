import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20-N typed detail route result guardrail', () {
    late String routeResultSource;
    late String confirmDeleteSource;
    late String openGraphSource;
    late String openSelectedWordDetailSource;
    late String embeddedDetailPanelSource;
    late String homeDetailRouteSource;

    setUpAll(() {
      routeResultSource = File(
        'lib/ui/word_detail_route_result.dart',
      ).readAsStringSync();

      final detailSource = File(
        'lib/ui/word_detail_screen.dart',
      ).readAsStringSync();
      confirmDeleteSource = _sourceBetween(
        detailSource,
        'Future<void> _confirmDelete() async {',
        'void _showWordNavigationUnavailableSnackBar() {',
      );
      openGraphSource = _sourceBetween(
        detailSource,
        'Future<void> _openGraph() async {',
        'Future<void> _confirmDelete() async {',
      );

      final explorerSource = File(
        'lib/ui/word_explorer_screen.dart',
      ).readAsStringSync();
      openSelectedWordDetailSource = _sourceBetween(
        explorerSource,
        'Future<void> _openSelectedWordDetail() async {',
        'void _showWordNavigationUnavailableSnackBar() {',
      );
      embeddedDetailPanelSource = _sourceBetween(
        explorerSource,
        'Widget _buildDetailPanel() {',
        'Widget _buildNoSelectionDetailPanel() {',
      );

      final homeSource = File('lib/ui/home_screen.dart').readAsStringSync();
      homeDetailRouteSource = _sourceBetween(
        homeSource,
        'Future<void> _openDefaultStrongWordDetail(String wordId) async {',
        'Future<void> _openDefaultStrongWordGraph(String wordId) async {',
      );
    });

    test('defines an explicit deleted detail route result with word id', () {
      expect(routeResultSource, contains('sealed class WordDetailRouteResult'));
      expect(
        routeResultSource,
        contains(
          'final class WordDetailDeletedResult extends WordDetailRouteResult',
        ),
      );
      expect(routeResultSource, contains('final String wordId;'));
    });

    test('returns typed delete result while keeping dialog bool contract', () {
      expect(confirmDeleteSource, contains('showDialog<bool>('));
      expect(
        'Navigator.pop(context, true)'.allMatches(confirmDeleteSource),
        hasLength(1),
      );
      expect(
        confirmDeleteSource,
        contains(
          'Navigator.pop(context, WordDetailDeletedResult(wordId: _wordId))',
        ),
      );
    });

    test('keeps explorer delete and ordinary refresh paths', () {
      expect(
        openSelectedWordDetailSource,
        contains('Navigator.push<WordDetailRouteResult>('),
      );
      expect(
        openSelectedWordDetailSource,
        contains('if (detailResult is WordDetailDeletedResult)'),
      );
      expect(
        openSelectedWordDetailSource,
        contains('_handleDeletedSelectedWord(wasCenterWord: wasCenterWord)'),
      );
      expect(openSelectedWordDetailSource, contains('_refreshSelectedWord('));
      expect(
        openSelectedWordDetailSource,
        contains('refreshGraphIfChanged: true'),
      );
      expect(
        openSelectedWordDetailSource,
        isNot(contains('Navigator.push<bool?>(')),
      );
    });

    test('keeps home detail route typed and refresh behavior unchanged', () {
      expect(
        homeDetailRouteSource,
        contains('Navigator.push<WordDetailRouteResult>('),
      );
      expect(homeDetailRouteSource, contains('WordDetailScreen('));
      expect(homeDetailRouteSource, contains('_refreshWords();'));
    });

    test('keeps embedded detail actions limited to edit and full-detail', () {
      expect(
        embeddedDetailPanelSource,
        contains('onEdit: _openEditSelectedWord'),
      );
      expect(
        embeddedDetailPanelSource,
        contains('onOpenDetail: _openSelectedWordDetail'),
      );
      expect(embeddedDetailPanelSource, isNot(contains('onDelete:')));
      expect(embeddedDetailPanelSource, isNot(contains('onShowGraph:')));
    });

    test('keeps detail graph action on standalone graph route', () {
      expect(openGraphSource, contains('Navigator.push('));
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
