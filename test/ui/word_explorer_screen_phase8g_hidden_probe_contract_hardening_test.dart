import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 8-G hidden probe output contract hardening', () {
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';
    const workspaceContractSourcePath =
        'lib/ui/explorer_workspace/explorer_workspace_contract.dart';
    const workspaceShellSourcePath =
        'lib/ui/explorer_workspace/explorer_workspace.dart';
    const mainSourcePath = 'lib/main.dart';
    const homeSourcePath = 'lib/ui/home_screen.dart';

    late String wordExplorerSource;
    late String helperSource;
    late String helperExternalSource;
    late String fieldSource;
    late String buildAssertSource;
    late Map<String, String> publicBoundarySources;

    setUpAll(() {
      wordExplorerSource = File(wordExplorerSourcePath).readAsStringSync();
      helperSource = _extractBetween(
        wordExplorerSource,
        'bool _debugValidateHiddenVisualProbe(',
        '  @override',
      );
      helperExternalSource = _removeBetween(
        wordExplorerSource,
        'bool _debugValidateHiddenVisualProbe(',
        '  @override',
      );
      fieldSource = _extractBetween(
        wordExplorerSource,
        'class _WordExplorerScreenState extends State<WordExplorerScreen> {',
        '  void initState() {',
      );
      buildAssertSource = _extractBetween(
        wordExplorerSource,
        '  Widget build(BuildContext context) {',
        '    return Scaffold(',
      );
      publicBoundarySources = <String, String>{
        workspaceContractSourcePath: File(
          workspaceContractSourcePath,
        ).readAsStringSync(),
        workspaceShellSourcePath: File(
          workspaceShellSourcePath,
        ).readAsStringSync(),
        mainSourcePath: File(mainSourcePath).readAsStringSync(),
        homeSourcePath: File(homeSourcePath).readAsStringSync(),
      };
    });

    test('keeps candidate structures scoped to helper local variables', () {
      expect(helperSource, contains('final candidateSlots = <String>['));
      expect(helperSource, contains('final candidateLabels = <String>['));
      expect(_occurrences(wordExplorerSource, 'candidateSlots'), equals(2));
      expect(_occurrences(wordExplorerSource, 'candidateLabels'), equals(2));
      expect(helperExternalSource, isNot(contains('candidateSlots')));
      expect(helperExternalSource, isNot(contains('candidateLabels')));
      expect(fieldSource, isNot(contains('candidateSlots')));
      expect(fieldSource, isNot(contains('candidateLabels')));
    });

    test('does not expose candidate output through public API or DTO names', () {
      final publicContractSource = <String>[
        helperExternalSource,
        ...publicBoundarySources.values,
      ].join('\n');

      const forbiddenPublicMarkers = <String>[
        'class HiddenVisualProbe',
        'class HiddenProbeOutput',
        'class HiddenVisualProbeOutput',
        'class VisualProbeOutput',
        'class VisualCandidateOutput',
        'class HiddenProbeModel',
        'class VisualProbeModel',
        'class CandidateSlots',
        'class CandidateLabels',
        'typedef HiddenVisualProbe',
        'typedef HiddenProbeOutput',
        'typedef HiddenVisualProbeOutput',
        'typedef VisualProbeOutput',
        'List<String> get candidateSlots',
        'List<String> get candidateLabels',
        'get candidateSlots',
        'get candidateLabels',
        'candidateSlots:',
        'candidateLabels:',
      ];

      for (final forbiddenMarker in forbiddenPublicMarkers) {
        expect(
          publicContractSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'hidden probe output must not become a public API or DTO/model: '
              '$forbiddenMarker.',
        );
      }

      expect(
        RegExp(
          r'(^|[^_A-Za-z0-9])debugValidateHiddenVisualProbe\(',
        ).hasMatch(publicContractSource),
        isFalse,
        reason: 'hidden visual probe must stay private to WordExplorerScreen.',
      );
    });

    test('keeps route, shell, and persistence contracts disconnected', () {
      for (final entry in publicBoundarySources.entries) {
        expect(
          entry.value,
          isNot(contains('_debugValidateHiddenVisualProbe')),
          reason: '${entry.key} must not expose the hidden probe helper.',
        );
        expect(
          entry.value,
          isNot(contains('candidateSlots')),
          reason: '${entry.key} must not expose candidateSlots.',
        );
        expect(
          entry.value,
          isNot(contains('candidateLabels')),
          reason: '${entry.key} must not expose candidateLabels.',
        );
      }

      expect(
        wordExplorerSource,
        isNot(contains("import 'explorer_workspace/explorer_workspace.dart';")),
      );
      expect(wordExplorerSource, isNot(contains('ExplorerWorkspace(')));
      expect(wordExplorerSource, isNot(contains('payload: candidateSlots')));
      expect(wordExplorerSource, isNot(contains('payload: candidateLabels')));
      expect(wordExplorerSource, isNot(contains('arguments: candidateSlots')));
      expect(wordExplorerSource, isNot(contains('arguments: candidateLabels')));
      expect(wordExplorerSource, isNot(contains('state: candidateSlots')));
      expect(wordExplorerSource, isNot(contains('state: candidateLabels')));
      expect(helperSource, isNot(contains('openDatabase')));
      expect(helperSource, isNot(contains('SharedPreferences')));
    });

    test('keeps the hidden probe assert-only, read-only, and non-owner', () {
      expect(buildAssertSource, contains('assert(() {'));
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

      const forbiddenHelperMarkers = <String>[
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
      ];

      for (final forbiddenMarker in forbiddenHelperMarkers) {
        expect(
          helperSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'hidden visual probe must stay assert-only/read-only/non-owner: '
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

String _removeBetween(String source, String startMarker, String endMarker) {
  final start = source.indexOf(startMarker);
  final end = source.indexOf(endMarker, start + startMarker.length);

  expect(start, isNonNegative);
  expect(end, greaterThan(start));

  return source.substring(0, start) + source.substring(end);
}

int _occurrences(String source, String marker) {
  var count = 0;
  var start = 0;

  while (true) {
    final index = source.indexOf(marker, start);
    if (index < 0) {
      return count;
    }

    count += 1;
    start = index + marker.length;
  }
}
