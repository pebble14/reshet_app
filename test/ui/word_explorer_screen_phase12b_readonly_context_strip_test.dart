import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 12-B WordExplorer read-only context strip guardrail', () {
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';
    const homeSourcePath = 'lib/ui/home_screen.dart';

    late String wordExplorerSource;
    late String homeSource;
    late String detailPaneSource;
    late String contextStripSource;

    setUpAll(() {
      wordExplorerSource = File(wordExplorerSourcePath).readAsStringSync();
      homeSource = File(homeSourcePath).readAsStringSync();
      detailPaneSource = _extractBetween(
        wordExplorerSource,
        '  Widget _buildDetailPane() {',
        '  Future<void> _selectWord(',
      );
      contextStripSource = _extractBetween(
        wordExplorerSource,
        '  Widget _buildDetailPaneContextStrip() {',
        '  Future<void> _selectWord(',
      );
    });

    test('mounts the strip only inside the existing detail pane', () {
      expect(
        wordExplorerSource,
        contains('Expanded(flex: 2, child: _buildDetailPane())'),
      );
      expect(detailPaneSource, contains('_buildDetailPaneContextStrip()'));
      expect(
        detailPaneSource,
        contains('Expanded(child: _buildDetailPanel())'),
      );
      expect(
        wordExplorerSource,
        isNot(contains('appBar: AppBar(title: _buildDetailPaneContextStrip')),
      );
    });

    test('reads only existing WordExplorer owner state for visible text', () {
      expect(
        contextStripSource,
        contains('final centerWordId = _centerWordId.trim();'),
      );
      expect(
        contextStripSource,
        contains('final selectedWordId = _selectedWordId?.trim();'),
      );
      expect(contextStripSource, contains("'선택 없음'"));
      expect(
        contextStripSource,
        contains("'중심 단어: \$centerWordId · \$selectedLabel'"),
      );
    });

    test('does not use ExplorerWorkspace projection as visible UI input', () {
      const forbiddenProjectionMarkers = <String>[
        'ExplorerWorkspaceState',
        '_readOnlyWorkspaceProjection',
        'workspaceProjection',
        'WordExplorerWorkspaceProjectionAdapter',
        'projection.',
        'detailTargetWordId',
        'layoutPreset',
        'origin',
      ];

      for (final forbiddenMarker in forbiddenProjectionMarkers) {
        expect(
          contextStripSource,
          isNot(contains(forbiddenMarker)),
          reason: 'context strip must not use projection visible UI input.',
        );
      }
    });

    test('does not add route shell owner or authority migration hooks', () {
      const forbiddenMarkers = <String>[
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
          contextStripSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'context strip must stay read-only and must not migrate authority: '
              '$forbiddenMarker.',
        );
      }

      expect(
        homeSource,
        contains('WordExplorerScreen(initialWordId: normalizedWordId)'),
      );
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
