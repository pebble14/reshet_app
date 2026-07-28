import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20-O detail graph request result guardrail', () {
    late String routeResultSource;
    late String detailSource;
    late String detailWidgetSource;
    late String openGraphSource;
    late String explorerSource;
    late String splitBodySource;
    late String focusSelectedWordDetailPaneSource;
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

      explorerSource = File(
        'lib/ui/word_explorer_screen.dart',
      ).readAsStringSync();
      splitBodySource = _sourceBetween(
        explorerSource,
        'Widget _buildResizableExplorerBody() {',
        '_GraphDetailSplitMetrics _resolveGraphDetailSplitMetrics(',
      );
      focusSelectedWordDetailPaneSource = _sourceBetween(
        explorerSource,
        'void _focusSelectedWordDetailPane(double usableWidth) {',
        'void _showWordNavigationUnavailableSnackBar() {',
      );
      embeddedDetailPanelSource = _sourceBetween(
        explorerSource,
        'Widget _buildDetailPanel({required double usableWidth}) {',
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
        contains('builder: (context) => WordGraphScreen('),
      );
      expect(openGraphSource, contains('centerWordId: _wordId'));
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
      final standalonePushIndex = openGraphSource.indexOf(
        'Navigator.push<WordDetailRouteResult>(',
      );

      expect(availabilityIndex, greaterThanOrEqualTo(0));
      expect(unavailableIndex, greaterThan(availabilityIndex));
      expect(returnModeIndex, greaterThan(unavailableIndex));
      expect(resultIndex, greaterThan(returnModeIndex));
      expect(standalonePushIndex, greaterThan(resultIndex));
    });

    test('keeps return-to-caller contract dormant outside explorer', () {
      expect(explorerSource, isNot(contains('WordDetailGraphRequestedResult')));
      expect(
        explorerSource,
        isNot(
          contains('graphActionMode: WordDetailGraphActionMode.returnToCaller'),
        ),
      );
      expect(focusSelectedWordDetailPaneSource, isNot(contains('Navigator.')));
      expect(homeDetailRouteSource, isNot(contains('graphActionMode:')));
      expect(homeDetailRouteSource, contains('WordDetailScreen('));
      expect(homeDetailRouteSource, contains('_refreshWords();'));
    });

    test('keeps embedded graph center change as the center owner path', () {
      expect(
        splitBodySource,
        contains('onChangeCenterWordId: (centerWordId) async {'),
      );
      expect(
        splitBodySource,
        contains('await _selectWord(centerWordId, changeCenterWord: true)'),
      );
    });

    test('pane focus does not retarget selection, center, or graph state', () {
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
          reason: '$ownerField must remain owned by the existing graph flow.',
        );
      }
    });

    test('keeps embedded pane actions limited to edit and pane focus', () {
      expect(
        embeddedDetailPanelSource,
        contains('onEdit: _openEditSelectedWord'),
      );
      expect(
        embeddedDetailPanelSource,
        contains(
          'onFocusDetail: () => _focusSelectedWordDetailPane(usableWidth)',
        ),
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
