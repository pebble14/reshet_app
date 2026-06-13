import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 10-D candidate representation reader source-level guardrail', () {
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
    late String readerSource;
    late String readerExternalHelperSource;
    late Map<String, String> productionBoundarySources;
    late Map<String, String> libPublicSurfaceSources;

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
      readerSource = _extractBetween(
        helperSource,
        '    bool readCandidateRepresentation() {',
        '    final detailTargetWordId = projection.detailTargetWordId;',
      );
      readerExternalHelperSource = _removeBetween(
        helperSource,
        '    bool readCandidateRepresentation() {',
        '    final detailTargetWordId = projection.detailTargetWordId;',
      );
      productionBoundarySources = <String, String>{
        workspaceContractSourcePath: File(
          workspaceContractSourcePath,
        ).readAsStringSync(),
        workspaceShellSourcePath: File(
          workspaceShellSourcePath,
        ).readAsStringSync(),
        mainSourcePath: File(mainSourcePath).readAsStringSync(),
        homeSourcePath: File(homeSourcePath).readAsStringSync(),
      };
      libPublicSurfaceSources = <String, String>{
        wordExplorerSourcePath: helperExternalSource,
        ..._dartSourcesUnder(
          'lib',
          excludedPaths: <String>{wordExplorerSourcePath},
        ),
      };
    });

    test('keeps the source-level reader inside the hidden probe helper', () {
      expect(helperSource, contains('bool readCandidateRepresentation()'));
      expect(
        helperExternalSource,
        isNot(contains('readCandidateRepresentation')),
      );
      expect(
        _occurrences(wordExplorerSource, 'readCandidateRepresentation'),
        2,
      );
      expect(readerExternalHelperSource, contains('candidateSlots'));
      expect(readerExternalHelperSource, contains('candidateLabels'));
      expect(
        readerExternalHelperSource,
        isNot(contains('return candidateSlots')),
      );
    });

    test('reads helper-local candidate structures without exposing output', () {
      expect(readerSource, contains('candidateSlots.isNotEmpty'));
      expect(
        readerSource,
        contains('candidateLabels.every((label) => label.trim().isNotEmpty)'),
      );
      expect(_occurrences(wordExplorerSource, 'candidateSlots'), 2);
      expect(_occurrences(wordExplorerSource, 'candidateLabels'), 2);
      expect(helperExternalSource, isNot(contains('candidateSlots')));
      expect(helperExternalSource, isNot(contains('candidateLabels')));
    });

    test(
      'keeps the reader free of route shell owner and persistence references',
      () {
        const forbiddenReaderMarkers = <String>[
          'Navigator',
          'Provider',
          'Repository',
          'WordRepository',
          'DatabaseService',
          'openDatabase',
          'SharedPreferences',
          'ExplorerWorkspace(',
          'routes:',
          'onGenerateRoute',
          'MaterialPageRoute',
          'shell',
          'persistence',
          'history',
          'sourceOfTruth',
          'setState',
          'async',
          'await',
          'Future<',
          'Stream<',
        ];

        for (final forbiddenMarker in forbiddenReaderMarkers) {
          expect(
            readerSource,
            isNot(contains(forbiddenMarker)),
            reason:
                'candidate representation reader must stay source-level, '
                'read-only, unmounted, non-route, non-owner, and non-persistent: '
                '$forbiddenMarker.',
          );
        }
      },
    );

    test('does not add DTO model public API route or shell contracts', () {
      const forbiddenPublicMarkers = <String>[
        'class CandidateRepresentation',
        'class CandidateRepresentationReader',
        'class CandidateSlots',
        'class CandidateLabels',
        'class HiddenProbeModel',
        'class VisualProbeModel',
        'typedef CandidateRepresentation',
        'typedef CandidateRepresentationReader',
        'List<String> get candidateSlots',
        'List<String> get candidateLabels',
        'get candidateSlots',
        'get candidateLabels',
        'candidateSlots:',
        'candidateLabels:',
        'readCandidateRepresentation:',
      ];

      for (final entry in libPublicSurfaceSources.entries) {
        for (final forbiddenMarker in forbiddenPublicMarkers) {
          expect(
            entry.value,
            isNot(contains(forbiddenMarker)),
            reason:
                '${entry.key} must not expose candidate representation as a '
                'public API, DTO/model, route contract, or shell contract: '
                '$forbiddenMarker.',
          );
        }
      }
    });

    test(
      'does not mount production UI or change production route entry points',
      () {
        for (final entry in productionBoundarySources.entries) {
          expect(
            entry.value,
            isNot(contains('readCandidateRepresentation')),
            reason:
                '${entry.key} must not expose the candidate representation reader.',
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

        expect(wordExplorerSource, isNot(contains('ExplorerWorkspace(')));
        expect(
          wordExplorerSource,
          isNot(
            contains("import 'explorer_workspace/explorer_workspace.dart';"),
          ),
        );
        expect(
          productionBoundarySources[mainSourcePath],
          contains('home: const HomeScreen()'),
        );
        expect(
          productionBoundarySources[mainSourcePath],
          isNot(contains('routes:')),
        );
        expect(
          productionBoundarySources[mainSourcePath],
          isNot(contains('onGenerateRoute')),
        );
      },
    );
  });
}

Map<String, String> _dartSourcesUnder(
  String rootPath, {
  Set<String> excludedPaths = const <String>{},
}) {
  final excluded = excludedPaths.map(_normalizePath).toSet();
  final sources = <String, String>{};

  for (final entity in Directory(rootPath).listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }

    final normalizedPath = _normalizePath(entity.path);
    if (excluded.contains(normalizedPath)) {
      continue;
    }

    sources[normalizedPath] = entity.readAsStringSync();
  }

  return sources;
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

String _normalizePath(String path) => path.replaceAll('\\', '/');

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
