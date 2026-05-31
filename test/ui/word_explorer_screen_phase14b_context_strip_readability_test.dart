import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 14-B WordExplorer context strip readability', () {
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';

    late String wordExplorerSource;
    late String contextHelpersSource;
    late String contextStripSource;
    late String selectedLabelSource;
    late String wordLabelSource;
    late String firstNonEmptySource;

    setUpAll(() {
      wordExplorerSource = File(wordExplorerSourcePath).readAsStringSync();
      contextHelpersSource = _extractBetween(
        wordExplorerSource,
        '  Widget _buildDetailPaneContextStrip() {',
        '  Future<void> _selectWord(',
      );
      contextStripSource = _extractBetween(
        wordExplorerSource,
        '  Widget _buildDetailPaneContextStrip() {',
        '  String _buildDetailPaneContextSelectedLabel() {',
      );
      selectedLabelSource = _extractBetween(
        wordExplorerSource,
        '  String _buildDetailPaneContextSelectedLabel() {',
        '  String _buildDetailPaneContextWordLabel({',
      );
      wordLabelSource = _extractBetween(
        wordExplorerSource,
        '  String _buildDetailPaneContextWordLabel({',
        '  String _firstNonEmptyText(List<String> values) {',
      );
      firstNonEmptySource = _extractBetween(
        wordExplorerSource,
        '  String _firstNonEmptyText(List<String> values) {',
        '  Future<void> _selectWord(',
      );
    });

    test('builds center label from existing display seed fields', () {
      expect(contextStripSource, contains('final centerLabel ='));
      expect(contextStripSource, contains('_buildDetailPaneContextWordLabel('));
      expect(contextStripSource, contains('fallbackWordId: _centerWordId'));
      expect(
        contextStripSource,
        contains('_centerDisplaySeed.representativeSpelling'),
      );
      expect(
        contextStripSource,
        contains('_centerDisplaySeed.displayStrongNumber'),
      );
      expect(
        contextStripSource,
        contains('_centerDisplaySeed.representativeTransliteration'),
      );
      expect(
        contextStripSource,
        contains("'중심 단어: \$centerLabel · \$selectedLabel'"),
      );
    });

    test('builds selected label from selected display item when available', () {
      expect(
        selectedLabelSource,
        contains('final selectedWordId = _selectedWordId?.trim();'),
      );
      expect(
        selectedLabelSource,
        contains('final displayItem = _selectedWordDisplayItem;'),
      );
      expect(
        selectedLabelSource,
        contains('representativeSpelling: displayItem.representativeSpelling'),
      );
      expect(
        selectedLabelSource,
        contains('displayStrongNumber: displayItem.displayStrongNumber'),
      );
      expect(selectedLabelSource, contains('_firstNonEmptyText('));
      expect(selectedLabelSource, contains('displayItem.transliterations'));
    });

    test('preserves selected none and selected word id fallback states', () {
      expect(selectedLabelSource, contains("return '선택 없음';"));
      expect(selectedLabelSource, contains("return '선택: \$selectedWordId';"));
      expect(selectedLabelSource, contains('fallbackWordId: selectedWordId'));
    });

    test('omits empty optional segments without adding blank separators', () {
      expect(
        wordLabelSource,
        contains('final normalizedRepresentativeSpelling ='),
      );
      expect(wordLabelSource, contains('final normalizedStrongNumber ='));
      expect(wordLabelSource, contains('formatWordDisplayStrong('));
      expect(wordLabelSource, contains('final normalizedTransliteration ='));
      expect(
        wordLabelSource,
        contains('final primaryLabel = normalizedRepresentativeSpelling'),
      );
      expect(wordLabelSource, contains('? normalizedRepresentativeSpelling'));
      expect(wordLabelSource, contains(': normalizedFallbackWordId'));
      expect(
        wordLabelSource,
        contains(
          'if (normalizedStrongNumber.isNotEmpty) normalizedStrongNumber',
        ),
      );
      expect(
        wordLabelSource,
        contains(
          'if (normalizedTransliteration.isNotEmpty) normalizedTransliteration',
        ),
      );
      expect(
        wordLabelSource,
        contains('.where((segment) => segment.isNotEmpty)'),
      );
      expect(wordLabelSource, contains("join(' · ')"));
      expect(firstNonEmptySource, contains('if (normalizedValue.isNotEmpty)'));
      expect(firstNonEmptySource, contains("return '';"));
    });

    test('keeps context strip local read-only guardrails', () {
      const forbiddenMarkers = <String>[
        'ExplorerWorkspaceState',
        '_readOnlyWorkspaceProjection',
        'workspaceProjection',
        'WordExplorerWorkspaceProjectionAdapter',
        'projection.',
        'detailTargetWordId',
        'layoutPreset',
        'origin',
        'Navigator',
        'MaterialPageRoute',
        'Provider',
        'Repository',
        'WordRepository',
        'SharedPreferences',
        'ExplorerWorkspace(',
        'routes:',
        'onGenerateRoute',
        'setState',
        'async',
        'await',
        'Future<',
      ];

      for (final forbiddenMarker in forbiddenMarkers) {
        expect(
          contextHelpersSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'Phase 14-B context strip must not change route, shell, owner, '
              'projection, repository, or persistence authority: '
              '$forbiddenMarker.',
        );
      }
    });
  });
}

String _extractBetween(String source, String startMarker, String endMarker) {
  final start = source.indexOf(startMarker);
  final end = source.indexOf(endMarker, start + startMarker.length);

  expect(start, isNonNegative);
  expect(end, greaterThan(start));

  return source.substring(start, end);
}
