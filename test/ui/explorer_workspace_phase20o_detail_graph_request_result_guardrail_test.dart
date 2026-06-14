import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20-O detail graph request result guardrail', () {
    late String routeResultSource;
    late String detailSource;
    late String detailWidgetSource;
    late String openGraphSource;
    late String openSelectedWordDetailSource;
    late String embeddedDetailPanelSource;
    late String homeDetailRouteSource;
    late String wordGraphSource;

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

      wordGraphSource = File(
        'lib/ui/word_graph_screen.dart',
      ).readAsStringSync();
    });

    test('defines a typed graph request result with word id', () {
      expect(
        routeResultSource,
        contains(
          'final class WordDetailGraphRequestedResult '
          'extends WordDetailRouteResult',
        ),
      );
      expect(
        routeResultSource,
        contains(
          'const WordDetailGraphRequestedResult({required this.wordId})',
        ),
      );
    });

    test('keeps standalone graph route as the detail screen default', () {
      expect(
        detailSource,
        contains(
          'enum WordDetailGraphActionMode { standaloneRoute, returnToCaller }',
        ),
      );
      expect(
        detailWidgetSource,
        contains('final WordDetailGraphActionMode graphActionMode;'),
      );
      expect(
        detailWidgetSource,
        contains(
          'this.graphActionMode = WordDetailGraphActionMode.standaloneRoute',
        ),
      );
      expect(
        openGraphSource,
        contains('WordGraphScreen(centerWordId: _wordId)'),
      );
    });

    test('returns graph request only after existing availability guard', () {
      final availabilityIndex = openGraphSource.indexOf(
        '_repository.wordExistsForGraphNavigation',
      );
      final unavailableIndex = openGraphSource.indexOf(
        '_showWordNavigationUnavailableSnackBar()',
      );
      final returnModeIndex = openGraphSource.indexOf(
        'WordDetailGraphActionMode.returnToCaller',
      );
      final resultIndex = openGraphSource.indexOf(
        'WordDetailGraphRequestedResult(wordId: _wordId)',
      );
      final standalonePushIndex = openGraphSource.indexOf('Navigator.push(');

      expect(availabilityIndex, greaterThanOrEqualTo(0));
      expect(unavailableIndex, greaterThan(availabilityIndex));
      expect(returnModeIndex, greaterThan(unavailableIndex));
      expect(resultIndex, greaterThan(returnModeIndex));
      expect(standalonePushIndex, greaterThan(resultIndex));
    });

    test('uses return-to-caller mode only for explorer full-detail route', () {
      expect(
        openSelectedWordDetailSource,
        contains('graphActionMode: WordDetailGraphActionMode.returnToCaller'),
      );
      expect(homeDetailRouteSource, isNot(contains('graphActionMode:')));
      expect(homeDetailRouteSource, contains('WordDetailScreen('));
      expect(homeDetailRouteSource, contains('_refreshWords();'));
    });

    test('retargets explorer center for graph request result', () {
      expect(
        openSelectedWordDetailSource,
        contains('if (detailResult is WordDetailGraphRequestedResult)'),
      );
      expect(
        openSelectedWordDetailSource,
        contains(
          'await _selectWord(detailResult.wordId, changeCenterWord: true)',
        ),
      );
    });

    test('keeps explorer delete and ordinary refresh paths', () {
      final deleteIndex = openSelectedWordDetailSource.indexOf(
        'if (detailResult is WordDetailDeletedResult)',
      );
      final graphRequestIndex = openSelectedWordDetailSource.indexOf(
        'if (detailResult is WordDetailGraphRequestedResult)',
      );
      final refreshIndex = openSelectedWordDetailSource.lastIndexOf(
        'await _refreshSelectedWord(',
      );

      expect(deleteIndex, greaterThanOrEqualTo(0));
      expect(
        openSelectedWordDetailSource,
        contains('_handleDeletedSelectedWord(wasCenterWord: wasCenterWord)'),
      );
      expect(graphRequestIndex, greaterThan(deleteIndex));
      expect(refreshIndex, greaterThan(graphRequestIndex));
      expect(
        openSelectedWordDetailSource,
        contains('refreshGraphIfChanged: true'),
      );
    });

    test('keeps embedded pane actions limited to edit and full-detail', () {
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

    test('does not couple WordGraphScreen to detail graph request result', () {
      expect(
        wordGraphSource,
        isNot(contains('WordDetailGraphRequestedResult')),
      );
      expect(wordGraphSource, isNot(contains('WordDetailGraphActionMode')));
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
