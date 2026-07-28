import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20-M embedded detail action clarity guardrail', () {
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';

    late String embeddedDetailPanelSource;
    late String focusSelectedWordDetailPaneSource;

    setUpAll(() {
      final wordExplorerSource = File(
        wordExplorerSourcePath,
      ).readAsStringSync();
      embeddedDetailPanelSource = _sourceBetween(
        wordExplorerSource,
        'Widget _buildDetailPanel({required double usableWidth}) {',
        'Widget _buildNoSelectionDetailPanel() {',
      );
      focusSelectedWordDetailPaneSource = _sourceBetween(
        wordExplorerSource,
        'void _focusSelectedWordDetailPane(double usableWidth) {',
        'void _showWordNavigationUnavailableSnackBar() {',
      );
    });

    test('keeps embedded detail actions limited to edit and pane focus', () {
      expect(embeddedDetailPanelSource, contains('return WordInfoPanel('));
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

    test(
      'focuses detail locally without route, persistence, or owner changes',
      () {
        expect(
          focusSelectedWordDetailPaneSource,
          contains('_clampGraphPaneFractionForWidth(usableWidth, 0.0)'),
        );
        expect(
          focusSelectedWordDetailPaneSource,
          contains('(focusedFraction - _graphPaneFraction).abs() < 0.0001'),
        );
        expect(
          focusSelectedWordDetailPaneSource,
          contains('_graphPaneFraction = focusedFraction'),
        );
        expect(
          focusSelectedWordDetailPaneSource,
          isNot(contains('Navigator.')),
        );
        expect(
          focusSelectedWordDetailPaneSource,
          isNot(contains('_persistGraphPaneFractionForWidth')),
        );
        expect(
          focusSelectedWordDetailPaneSource,
          isNot(contains('SharedPreferences')),
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
            reason: '$ownerField must not change during pane-local focus.',
          );
        }
        expect(
          focusSelectedWordDetailPaneSource,
          isNot(contains('WordDetailScreen')),
        );
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
