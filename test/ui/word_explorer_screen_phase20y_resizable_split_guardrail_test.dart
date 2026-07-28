import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20-Y WordExplorer resizable split guardrail', () {
    late String explorerSource;
    late String splitBodySource;
    late String dividerSource;
    late String persistenceSource;
    late String focusSelectedWordDetailPaneSource;

    setUpAll(() {
      explorerSource = File(
        'lib/ui/word_explorer_screen.dart',
      ).readAsStringSync();
      splitBodySource = _sourceBetween(
        explorerSource,
        'Widget _buildResizableExplorerBody() {',
        '_GraphDetailSplitMetrics _resolveGraphDetailSplitMetrics(',
      );
      dividerSource = _sourceBetween(
        explorerSource,
        'Widget _buildGraphDetailSplitDivider(double usableWidth) {',
        'void _updateGraphPaneFraction({',
      );
      persistenceSource = _sourceBetween(
        explorerSource,
        'Future<void> _restoreGraphPaneFraction() async {',
        'Widget _buildDetailPane({required double usableWidth}) {',
      );
      focusSelectedWordDetailPaneSource = _sourceBetween(
        explorerSource,
        'void _focusSelectedWordDetailPane(double usableWidth) {',
        'void _showWordNavigationUnavailableSnackBar() {',
      );
    });

    test('keeps the default split ratio and explicit persistence key', () {
      expect(
        explorerSource,
        contains('const double _defaultGraphPaneFraction = 0.60;'),
      );
      expect(
        explorerSource,
        contains('const String _graphDetailSplitFractionPreferenceKey ='),
      );
      expect(
        explorerSource,
        contains("'explorer_graph_detail_split_fraction';"),
      );
      expect(
        explorerSource,
        contains('double _graphPaneFraction = _defaultGraphPaneFraction;'),
      );
    });

    test('uses LayoutBuilder and width-based panes instead of flex panes', () {
      expect(explorerSource, contains('body: _buildResizableExplorerBody()'));
      expect(splitBodySource, contains('LayoutBuilder('));
      expect(splitBodySource, contains('_resolveGraphDetailSplitMetrics('));
      expect(splitBodySource, contains('width: splitMetrics.graphWidth'));
      expect(splitBodySource, contains('child: WordGraphScreen('));
      expect(
        splitBodySource,
        contains('_buildGraphDetailSplitDivider(splitMetrics.usableWidth)'),
      );
      expect(splitBodySource, contains('width: splitMetrics.detailWidth'));
      expect(splitBodySource, contains('child: _buildDetailPane('));
      expect(
        splitBodySource,
        contains('usableWidth: splitMetrics.usableWidth'),
      );
      expect(splitBodySource, isNot(contains('Expanded(')));
      expect(splitBodySource, isNot(contains('VerticalDivider(')));
    });

    test('keeps graph callbacks and moves detail action to local focus', () {
      expect(splitBodySource, contains('centerWordId: _centerWordId'));
      expect(splitBodySource, contains('selectedWordId: _selectedWordId'));
      expect(splitBodySource, contains('onSelectWordId: (selectedWordId)'));
      expect(
        splitBodySource,
        contains('onClearSelection: _clearSelectedWordPanel'),
      );
      expect(
        splitBodySource,
        contains('onDeletedSelectedWord: _handleGraphDeletedSelectedWord'),
      );
      expect(splitBodySource, contains('onChangeCenterWordId: (centerWordId)'));
      expect(
        focusSelectedWordDetailPaneSource,
        contains('_clampGraphPaneFractionForWidth(usableWidth, 0.0)'),
      );
      expect(
        focusSelectedWordDetailPaneSource,
        contains('_graphPaneFraction = focusedFraction'),
      );
      expect(focusSelectedWordDetailPaneSource, isNot(contains('Navigator.')));
      expect(explorerSource, isNot(contains('DeleteWordCommand')));
      expect(explorerSource, isNot(contains('WordWriteService')));
    });

    test(
      'focus is idempotent and does not persist or mutate explorer owners',
      () {
        expect(
          focusSelectedWordDetailPaneSource,
          contains('(focusedFraction - _graphPaneFraction).abs() < 0.0001'),
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
            reason: '$ownerField must not change during pane focus.',
          );
        }
      },
    );

    test('uses a draggable vertical divider and saves only on drag end', () {
      expect(dividerSource, contains('MouseRegion('));
      expect(dividerSource, contains('SystemMouseCursors.resizeColumn'));
      expect(dividerSource, contains('GestureDetector('));
      expect(dividerSource, contains('onHorizontalDragUpdate:'));
      expect(dividerSource, contains('_updateGraphPaneFraction('));
      expect(dividerSource, contains('onHorizontalDragEnd:'));
      expect(dividerSource, contains('onHorizontalDragCancel:'));
      expect(dividerSource, contains('_persistGraphPaneFractionForWidth'));

      final updateBeforePersist = dividerSource.indexOf(
        '_updateGraphPaneFraction(',
      );
      final persistIndex = dividerSource.indexOf(
        '_persistGraphPaneFractionForWidth',
      );

      expect(updateBeforePersist, greaterThanOrEqualTo(0));
      expect(persistIndex, greaterThan(updateBeforePersist));
      expect(
        _sourceBetween(
          explorerSource,
          'void _updateGraphPaneFraction({',
          'Future<void> _restoreGraphPaneFraction() async {',
        ),
        isNot(contains('SharedPreferences')),
      );
    });

    test('persists the split fraction through existing SharedPreferences', () {
      expect(
        explorerSource,
        contains(
          "import 'package:shared_preferences/shared_preferences.dart';",
        ),
      );
      expect(explorerSource, contains('_restoreGraphPaneFraction();'));
      expect(persistenceSource, contains('SharedPreferences.getInstance()'));
      expect(persistenceSource, contains('preferences.getDouble('));
      expect(
        persistenceSource,
        contains('_graphDetailSplitFractionPreferenceKey'),
      );
      expect(persistenceSource, contains('preferences.setDouble('));
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
