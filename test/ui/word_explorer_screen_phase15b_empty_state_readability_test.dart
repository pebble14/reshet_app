import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 15-B WordExplorer empty state readability guardrail', () {
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';
    const homeSourcePath = 'lib/ui/home_screen.dart';

    late String wordExplorerSource;
    late String homeSource;
    late String detailPaneSource;
    late String emptyStateSource;

    setUpAll(() {
      wordExplorerSource = File(wordExplorerSourcePath).readAsStringSync();
      homeSource = File(homeSourcePath).readAsStringSync();
      detailPaneSource = _extractBetween(
        wordExplorerSource,
        '  Widget _buildDetailPane() {',
        '  Widget _buildNoSelectionDetailPanel() {',
      );
      emptyStateSource = _extractMethod(
        wordExplorerSource,
        '  Widget _buildNoSelectionDetailPanel() {',
      );
    });

    test('keeps the no selection panel inside the existing detail pane', () {
      expect(
        wordExplorerSource,
        contains('  Widget _buildNoSelectionDetailPanel() {'),
      );
      expect(
        detailPaneSource,
        contains('return _buildNoSelectionDetailPanel();'),
      );
      expect(
        detailPaneSource,
        contains('final displayItem = _selectedWordDisplayItem;'),
      );
      expect(
        wordExplorerSource,
        contains('Expanded(child: _buildDetailPanel())'),
      );
    });

    test('uses Phase 15-B user-facing empty state copy', () {
      expect(emptyStateSource, contains("'그래프에서 단어를 선택하세요'"));
      expect(emptyStateSource, contains("'선택한 단어의 상세 정보가 이 영역에 표시됩니다.'"));
      expect(emptyStateSource, contains("'중심 단어 정보는 상단 표시줄에서 확인할 수 있습니다.'"));
      expect(emptyStateSource, isNot(contains('context strip')));
    });

    test('keeps the empty state as a local read-only display refinement', () {
      expect(emptyStateSource, contains('Center('));
      expect(emptyStateSource, contains('Padding('));
      expect(emptyStateSource, contains('ConstrainedBox('));
      expect(emptyStateSource, contains('Column('));
      expect(emptyStateSource, contains('Icons.touch_app_outlined'));

      const forbiddenMarkers = <String>[
        'Navigator',
        'MaterialPageRoute',
        'Provider',
        'Repository',
        'WordRepository',
        'SharedPreferences',
        'ExplorerWorkspaceState',
        'WordExplorerWorkspaceProjectionAdapter',
        '_readOnlyWorkspaceProjection',
        'workspaceProjection',
        'projection.',
        'detailTargetWordId',
        'layoutPreset',
        'origin',
        'setState',
        'async',
        'await',
        'Future<',
        'routes:',
        'onGenerateRoute',
        'ExplorerWorkspace(',
      ];

      for (final forbiddenMarker in forbiddenMarkers) {
        expect(
          emptyStateSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'empty state must not change route, shell, owner, projection, '
              'repository, persistence, or async behavior: $forbiddenMarker.',
        );
      }
    });

    test('preserves context strip and HomeScreen entry guardrails', () {
      expect(
        wordExplorerSource,
        contains('  Widget _buildDetailPaneContextStrip() {'),
      );
      expect(wordExplorerSource, contains('_buildDetailPaneContextStrip()'));
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

String _extractMethod(String source, String signature) {
  final start = source.indexOf(signature);
  expect(start, isNonNegative);

  final bodyStart = source.indexOf('{', start);
  expect(bodyStart, isNonNegative);

  var depth = 0;
  for (var index = bodyStart; index < source.length; index += 1) {
    final character = source[index];
    if (character == '{') {
      depth += 1;
    } else if (character == '}') {
      depth -= 1;
      if (depth == 0) {
        return source.substring(start, index + 1);
      }
    }
  }

  fail('Unable to extract method for signature: $signature');
}
