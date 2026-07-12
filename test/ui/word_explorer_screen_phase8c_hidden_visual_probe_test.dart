import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 8-C hidden visual probe boundary', () {
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';
    const mainSourcePath = 'lib/main.dart';
    const homeSourcePath = 'lib/ui/home_screen.dart';
    late String wordExplorerSource;
    late String helperSource;
    late String buildAssertSource;
    late String fieldSource;
    late String mainSource;
    late String homeSource;

    setUpAll(() {
      wordExplorerSource = File(wordExplorerSourcePath).readAsStringSync();
      helperSource = _extractBetween(
        wordExplorerSource,
        'bool _debugValidateHiddenVisualProbe(',
        '  @override',
      );
      buildAssertSource = _extractBetween(
        wordExplorerSource,
        '  Widget build(BuildContext context) {',
        '    return Scaffold(',
      );
      fieldSource = _extractBetween(
        wordExplorerSource,
        'class _WordExplorerScreenState extends State<WordExplorerScreen> {',
        '  void initState() {',
      );
      mainSource = File(mainSourcePath).readAsStringSync();
      homeSource = File(homeSourcePath).readAsStringSync();
    });

    test('adds a private helper under the existing assert-only read', () {
      expect(
        wordExplorerSource,
        contains(
          'bool _debugValidateHiddenVisualProbe('
          'ExplorerWorkspaceState projection)',
        ),
      );
      expect(buildAssertSource, contains('assert(() {'));
      expect(
        buildAssertSource,
        contains('final projection = workspaceProjection;'),
      );
      expect(
        buildAssertSource,
        contains('_debugValidateHiddenVisualProbe(projection)'),
      );
      expect(
        buildAssertSource.indexOf(
          '_debugValidateHiddenVisualProbe(projection)',
        ),
        greaterThan(buildAssertSource.indexOf('assert(() {')),
      );
    });

    test('consumes the projection as read-only visual candidate input', () {
      expect(helperSource, contains('final candidateSlots = <String>['));
      expect(helperSource, contains('final candidateLabels = <String>['));
      expect(helperSource, contains('projection.selectedWordId'));
      expect(helperSource, contains('projection.graphCenterWordId'));
      expect(helperSource, contains('projection.detailTargetWordId'));
      expect(helperSource, contains('projection.layoutPreset.name'));
      expect(helperSource, contains('projection.origin.name'));
      expect(
        helperSource,
        contains('candidateLabels.every((label) => label.trim().isNotEmpty)'),
      );
    });

    test('keeps the helper side-effect free and non-owner', () {
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
        'WordNavigationHistory',
        'debugPrint',
        'print(',
        'async',
        'await',
        'Future<',
        'Stream<',
        'File(',
        'openDatabase',
        'SharedPreferences',
      ];

      for (final forbiddenMarker in forbiddenMarkers) {
        expect(
          helperSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'hidden visual probe must stay assert-only and non-owner: '
              '$forbiddenMarker.',
        );
      }
    });

    test('does not persist projection results as field, cache, or history', () {
      expect(fieldSource, isNot(contains('ExplorerWorkspaceState')));
      expect(fieldSource, isNot(contains('_debugValidateHiddenVisualProbe')));
      expect(
        wordExplorerSource,
        isNot(
          contains('WordNavigationHistoryController<ExplorerWorkspaceState>'),
        ),
      );
      expect(wordExplorerSource, isNot(contains('_hiddenVisualProbe')));
      expect(
        wordExplorerSource,
        isNot(contains('payload: workspaceProjection')),
      );
      expect(
        wordExplorerSource,
        isNot(contains('payload: _readOnlyWorkspaceProjection')),
      );
      expect(
        wordExplorerSource,
        isNot(contains('_history.push(workspaceProjection')),
      );
      expect(
        wordExplorerSource,
        isNot(contains('_history.replaceCurrent(workspaceProjection')),
      );
    });

    test('does not mount shell or change production route entry points', () {
      expect(
        wordExplorerSource,
        isNot(contains("import 'explorer_workspace/explorer_workspace.dart';")),
      );
      expect(wordExplorerSource, isNot(contains('ExplorerWorkspace(')));
      expect(mainSource, isNot(contains('_debugValidateHiddenVisualProbe')));
      expect(homeSource, isNot(contains('_debugValidateHiddenVisualProbe')));
      expect(mainSource, matches(RegExp(r'home:\s*HomeScreen\s*\(')));
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
