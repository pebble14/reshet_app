import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20-M embedded detail action clarity guardrail', () {
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';

    late String embeddedDetailPanelSource;
    late String openSelectedWordDetailSource;

    setUpAll(() {
      final wordExplorerSource = File(
        wordExplorerSourcePath,
      ).readAsStringSync();
      embeddedDetailPanelSource = _sourceBetween(
        wordExplorerSource,
        'Widget _buildDetailPanel() {',
        'Widget _buildNoSelectionDetailPanel() {',
      );
      openSelectedWordDetailSource = _sourceBetween(
        wordExplorerSource,
        'Future<void> _openSelectedWordDetail() async {',
        'void _showWordNavigationUnavailableSnackBar() {',
      );
    });

    test('keeps embedded detail actions limited to edit and full-detail', () {
      expect(embeddedDetailPanelSource, contains('return WordInfoPanel('));
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

    test('keeps full-detail route result and refresh contracts unchanged', () {
      expect(
        openSelectedWordDetailSource,
        contains('Navigator.push<WordDetailRouteResult>('),
      );
      expect(openSelectedWordDetailSource, contains('WordDetailScreen('));
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
