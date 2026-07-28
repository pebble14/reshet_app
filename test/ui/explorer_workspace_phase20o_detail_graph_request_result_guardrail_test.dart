import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20-O detail graph request result guardrail', () {
    late String openGraphSource;
    late String explorerSource;
    late String splitBodySource;
    late String focusSelectedWordDetailPaneSource;
    late String embeddedDetailPanelSource;
    late String homeDetailRouteSource;

    setUpAll(() {
      final detailSource = File(
        'lib/ui/word_detail_screen.dart',
      ).readAsStringSync();
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
    });

    test('keeps standalone graph route as the detail screen action', () {
      expect(
        openGraphSource,
        contains('builder: (context) => WordGraphScreen('),
      );
      expect(openGraphSource, contains('centerWordId: _wordId'));
    });

    test('opens standalone graph only after existing availability guard', () {
      final availabilityIndex = openGraphSource.indexOf(
        '_repository.wordExistsForGraphNavigation',
      );
      final unavailableIndex = openGraphSource.indexOf(
        '_showWordNavigationUnavailableSnackBar()',
      );
      final standalonePushIndex = openGraphSource.indexOf(
        'Navigator.push<WordDetailRouteResult>(',
      );

      expect(availabilityIndex, greaterThanOrEqualTo(0));
      expect(unavailableIndex, greaterThan(availabilityIndex));
      expect(standalonePushIndex, greaterThan(unavailableIndex));
    });

    test('keeps pane focus local and home detail route active', () {
      expect(focusSelectedWordDetailPaneSource, isNot(contains('Navigator.')));
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
