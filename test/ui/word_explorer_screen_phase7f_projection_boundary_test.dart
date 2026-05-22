import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 7-F WordExplorer read-only projection boundary', () {
    const sourcePath = 'lib/ui/word_explorer_screen.dart';
    late String source;
    late String fieldSource;
    late String projectionSource;

    setUpAll(() {
      source = File(sourcePath).readAsStringSync();
      fieldSource = _extractBetween(
        source,
        'class _WordExplorerScreenState extends State<WordExplorerScreen> {',
        'void initState() {',
      );
      projectionSource = _extractBetween(
        source,
        'String? _normalizeReadOnlyProjectionWordId(String? wordId) {',
        'Widget build(BuildContext context) {',
      );
    });

    test('adds a private projection getter and build-local read', () {
      expect(
        source,
        contains('ExplorerWorkspaceState? get _readOnlyWorkspaceProjection'),
      );
      expect(
        source,
        contains('final workspaceProjection = _readOnlyWorkspaceProjection;'),
      );
      expect(
        projectionSource,
        contains('WordExplorerWorkspaceProjectionAdapter.project('),
      );
      expect(
        source,
        contains('final projection = workspaceProjection;'),
      );
    });

    test('keeps layout preset and origin as local projection metadata', () {
      expect(
        projectionSource,
        contains('layoutPreset: ExplorerWorkspaceLayoutPreset.balanced'),
      );
      expect(
        projectionSource,
        contains('origin: ExplorerWorkspaceTransitionOrigin.routeAlias'),
      );
      expect(fieldSource, isNot(contains('ExplorerWorkspaceLayoutPreset')));
      expect(fieldSource, isNot(contains('ExplorerWorkspaceTransitionOrigin')));
    });

    test('guards blank center and optional ids before adapter input', () {
      expect(
        projectionSource,
        contains('final normalizedCenterWordId = _centerWordId.trim();'),
      );
      expect(
        projectionSource,
        contains('if (normalizedCenterWordId.isEmpty) {'),
      );
      expect(
        projectionSource,
        contains(
          'final normalizedSelectedWordId = _normalizeReadOnlyProjectionWordId(',
        ),
      );
      expect(
        projectionSource,
        contains('final normalizedWordId = wordId.trim();'),
      );
      expect(projectionSource, contains('if (normalizedWordId.isEmpty) {'));
      expect(projectionSource, contains('return null;'));
    });

    test('projects detail target only when current owner has detail payload', () {
      expect(
        projectionSource,
        matches(
          RegExp(
            r'final detailTargetWordId = _selectedWordDisplayItem != null\s*\?\s*normalizedSelectedWordId\s*:\s*null;',
            multiLine: true,
          ),
        ),
      );
      expect(
        projectionSource,
        contains('detailTargetWordId: detailTargetWordId'),
      );
      expect(
        projectionSource,
        isNot(contains('detailTargetWordId: _selectedWordId')),
      );
    });

    test('keeps workspace projection out of fields and history payload', () {
      expect(fieldSource, isNot(contains('ExplorerWorkspaceState')));
      expect(
        source,
        isNot(contains('WordNavigationHistoryController<ExplorerWorkspaceState>')),
      );
      expect(source, contains('payload: _ExplorerHistorySnapshot('));
      expect(
        source,
        isNot(contains('payload: _readOnlyWorkspaceProjection')),
      );
      expect(
        source,
        isNot(contains('_history.push(_readOnlyWorkspaceProjection')),
      );
      expect(
        source,
        isNot(contains('_history.replaceCurrent(_readOnlyWorkspaceProjection')),
      );
    });

    test('keeps the projection boundary read-only and non-visual', () {
      expect(
        source,
        contains(
          "import 'explorer_workspace/explorer_workspace_contract.dart';",
        ),
      );
      expect(
        source,
        contains(
          "import 'explorer_workspace/word_explorer_workspace_projection_adapter.dart';",
        ),
      );

      const forbiddenMarkers = <String>[
        'setState',
        'Navigator',
        'MaterialPageRoute',
        'WordRepository',
        'DatabaseService',
        'Provider',
        'ChangeNotifierProvider',
        'MultiProvider',
        'ExplorerWorkspace(',
        'ExplorerWorkspacePreviewScreen',
        'WordGraphScreen(',
        'WordDetailScreen(',
        'async',
        'await',
      ];

      for (final forbiddenMarker in forbiddenMarkers) {
        expect(
          projectionSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'Projection boundary must stay derived and non-visual: '
              '$forbiddenMarker.',
        );
      }

      expect(source, isNot(contains("database_service.dart")));
      expect(source, isNot(contains("package:provider/")));
      expect(
        source,
        isNot(contains("import 'explorer_workspace/explorer_workspace.dart';")),
      );
      expect(source, isNot(contains('ExplorerWorkspace(')));
    });
  });
}

String _extractBetween(
  String source,
  String startMarker,
  String endMarker,
) {
  final start = source.indexOf(startMarker);
  final end = source.indexOf(endMarker);

  expect(start, isNonNegative);
  expect(end, greaterThan(start));

  return source.substring(start, end);
}
