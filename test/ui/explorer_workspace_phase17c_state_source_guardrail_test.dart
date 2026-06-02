import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 17-C ExplorerWorkspaceState source boundary guardrail', () {
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';
    const contractSourcePath =
        'lib/ui/explorer_workspace/explorer_workspace_contract.dart';
    const projectionAdapterSourcePath =
        'lib/ui/explorer_workspace/word_explorer_workspace_projection_adapter.dart';

    late String wordExplorerSource;
    late String contractSource;
    late String projectionAdapterSource;
    late String wordExplorerFieldSource;
    late String projectionGetterSource;
    late String hiddenProbeSource;
    late String buildProjectionPreludeSource;
    late String explorerWorkspaceStateSource;
    late String explorerHistorySnapshotSource;

    setUpAll(() {
      wordExplorerSource = _readText(wordExplorerSourcePath);
      contractSource = _readText(contractSourcePath);
      projectionAdapterSource = _readText(projectionAdapterSourcePath);
      wordExplorerFieldSource = _extractBetween(
        wordExplorerSource,
        'class _WordExplorerScreenState extends State<WordExplorerScreen> {',
        'void initState() {',
      );
      projectionGetterSource = _extractBetween(
        wordExplorerSource,
        'ExplorerWorkspaceState? get _readOnlyWorkspaceProjection {',
        'bool _debugValidateHiddenVisualProbe(ExplorerWorkspaceState projection) {',
      );
      hiddenProbeSource = _extractBetween(
        wordExplorerSource,
        'bool _debugValidateHiddenVisualProbe(ExplorerWorkspaceState projection) {',
        '@override',
      );
      buildProjectionPreludeSource = _extractBetween(
        wordExplorerSource,
        'Widget build(BuildContext context) {',
        'return Scaffold(',
      );
      explorerWorkspaceStateSource = _extractBetween(
        contractSource,
        'class ExplorerWorkspaceState {',
        'class ExplorerWorkspaceHistoryEntry {',
      );
      explorerHistorySnapshotSource = _extractBetween(
        wordExplorerSource,
        'class _ExplorerHistorySnapshot {',
        'class _ExplorerCenterDisplaySeed {',
      );
    });

    test('keeps WordExplorerScreen owner fields for production state', () {
      expect(wordExplorerFieldSource, contains('late String _centerWordId;'));
      expect(wordExplorerFieldSource, contains('String? _selectedWordId;'));
      expect(
        wordExplorerFieldSource,
        contains('WordDetailLikeDisplayItem? _selectedWordDisplayItem;'),
      );
      expect(
        wordExplorerFieldSource,
        contains('bool _isDetailLoading = false;'),
      );
      expect(wordExplorerFieldSource, contains('String? _detailError;'));
      expect(
        wordExplorerFieldSource,
        contains('String? _detailUnavailableMessage;'),
      );
      expect(
        wordExplorerFieldSource,
        contains(
          'final WordNavigationHistoryController<_ExplorerHistorySnapshot> _history',
        ),
      );
    });

    test(
      'keeps visible production reads on WordExplorerScreen owner fields',
      () {
        expect(wordExplorerSource, contains('centerWordId: _centerWordId'));
        expect(wordExplorerSource, contains('selectedWordId: _selectedWordId'));
        expect(wordExplorerSource, contains('if (_isDetailLoading)'));
        expect(wordExplorerSource, contains('if (_detailError != null)'));
        expect(
          wordExplorerSource,
          contains('final displayItem = _selectedWordDisplayItem;'),
        );
        expect(
          wordExplorerSource,
          contains(
            'final detailUnavailableMessage = _detailUnavailableMessage;',
          ),
        );
      },
    );

    test(
      'limits ExplorerWorkspaceState usage to read-only projection probes',
      () {
        expect(
          _trimmedLinesContaining(wordExplorerSource, 'ExplorerWorkspaceState'),
          equals(<String>[
            'ExplorerWorkspaceState? get _readOnlyWorkspaceProjection {',
            'bool _debugValidateHiddenVisualProbe(ExplorerWorkspaceState projection) {',
          ]),
        );
        expect(
          projectionGetterSource,
          contains('WordExplorerWorkspaceProjectionAdapter.project('),
        );
        expect(
          buildProjectionPreludeSource,
          contains('final workspaceProjection = _readOnlyWorkspaceProjection;'),
        );
        expect(
          buildProjectionPreludeSource,
          contains('final projection = workspaceProjection;'),
        );
        expect(
          buildProjectionPreludeSource,
          contains('_debugValidateHiddenVisualProbe(projection)'),
        );
      },
    );

    test('does not store ExplorerWorkspaceState as production owner state', () {
      expect(
        wordExplorerFieldSource,
        isNot(contains('ExplorerWorkspaceState')),
      );
      expect(
        wordExplorerFieldSource,
        isNot(contains('WordExplorerWorkspaceProjectionAdapter')),
      );
      expect(
        wordExplorerSource,
        isNot(
          contains('WordNavigationHistoryController<ExplorerWorkspaceState>'),
        ),
      );
      expect(
        explorerHistorySnapshotSource,
        isNot(contains('ExplorerWorkspace')),
      );
      expect(
        wordExplorerSource,
        isNot(contains('payload: _readOnlyWorkspaceProjection')),
      );
      expect(
        wordExplorerSource,
        isNot(contains('_history.push(_readOnlyWorkspaceProjection')),
      );
      expect(
        wordExplorerSource,
        isNot(contains('_history.replaceCurrent(_readOnlyWorkspaceProjection')),
      );
      expect(
        wordExplorerSource,
        isNot(contains('_history.reset(_readOnlyWorkspaceProjection')),
      );
    });

    test('keeps ExplorerWorkspaceState as immutable projection contract', () {
      expect(
        explorerWorkspaceStateSource,
        contains('final String? selectedWordId;'),
      );
      expect(
        explorerWorkspaceStateSource,
        contains('final String? graphCenterWordId;'),
      );
      expect(
        explorerWorkspaceStateSource,
        contains('final String? detailTargetWordId;'),
      );
      expect(
        explorerWorkspaceStateSource,
        contains('final ExplorerWorkspaceLayoutPreset layoutPreset;'),
      );
      expect(
        explorerWorkspaceStateSource,
        contains('final ExplorerWorkspaceTransitionOrigin origin;'),
      );

      final code = _sourceWithoutCommentsAndStrings(
        explorerWorkspaceStateSource,
      );
      expect(code, isNot(matches(RegExp(r'\blate\s+'))));
      expect(code, isNot(matches(RegExp(r'\bvar\s+'))));
      expect(code, isNot(matches(RegExp(r'\bset\s+\w+'))));
      expect(code, isNot(contains('ChangeNotifier')));
      expect(code, isNot(contains('ValueNotifier')));
      expect(code, isNot(contains('StreamController')));
    });

    test('does not give projection contract authority dependencies', () {
      expect(_importLines(contractSource), isEmpty);
      expect(
        _importLines(projectionAdapterSource),
        equals(<String>["import 'explorer_workspace_contract.dart';"]),
      );
    });

    test(
      'keeps projection boundary free of read, mutation, and persistence calls',
      () {
        final projectionBoundaryCode = _sourceWithoutCommentsAndStrings(
          [
            projectionGetterSource,
            hiddenProbeSource,
            buildProjectionPreludeSource,
            contractSource,
            projectionAdapterSource,
          ].join('\n'),
        );

        final forbiddenAuthorityCallPatterns = <String, RegExp>{
          'repository read': RegExp(r'\bWordRepository\b|\b_repository\.'),
          'database query': RegExp(
            r'\b(?:DatabaseService|openDatabase|rawQuery|query|execute)\s*\(',
          ),
          'database mutation': RegExp(r'\b(?:insert|update|delete)\s*\('),
          'persistence': RegExp(
            r'\b(?:SharedPreferences|File|Directory|readAsString|writeAsString)\b',
          ),
          'production mutation': RegExp(
            r'\b(?:setState|notifyListeners|Navigator|MaterialPageRoute)\b',
          ),
          'production history authority': RegExp(
            r'\b(?:WordNavigationHistoryController|_history\.|goBack|goForward)\b',
          ),
        };

        for (final entry in forbiddenAuthorityCallPatterns.entries) {
          expect(
            projectionBoundaryCode,
            isNot(matches(entry.value)),
            reason:
                'ExplorerWorkspaceState projection boundary must not gain '
                '${entry.key} authority.',
          );
        }
      },
    );

    test(
      'does not use projection result for production restore or rollback',
      () {
        final wordExplorerCode = _sourceWithoutCommentsAndStrings(
          wordExplorerSource,
        );

        expect(
          wordExplorerCode,
          isNot(contains('ExplorerWorkspaceState.fromSnapshot')),
        );
        expect(
          wordExplorerCode,
          isNot(contains('ExplorerWorkspaceHistoryEntry')),
        );
        expect(
          wordExplorerCode,
          isNot(contains('snapshot: _readOnlyWorkspaceProjection')),
        );
        expect(
          wordExplorerCode,
          isNot(contains('snapshot: workspaceProjection')),
        );
        expect(wordExplorerCode, isNot(contains('snapshot: projection')));
      },
    );
  });
}

String _readText(String path) {
  return File(path).readAsStringSync();
}

String _extractBetween(String source, String startMarker, String endMarker) {
  final start = source.indexOf(startMarker);
  expect(start, isNonNegative);

  final end = source.indexOf(endMarker, start + startMarker.length);
  expect(end, greaterThan(start));

  return source.substring(start, end);
}

List<String> _trimmedLinesContaining(String source, String marker) {
  return source
      .split('\n')
      .where((line) => line.contains(marker))
      .map((line) => line.trim())
      .toList();
}

List<String> _importLines(String source) {
  return source
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.startsWith('import '))
      .toList();
}

String _sourceWithoutCommentsAndStrings(String source) {
  final buffer = StringBuffer();
  var index = 0;

  while (index < source.length) {
    final current = source[index];
    final next = index + 1 < source.length ? source[index + 1] : '';

    if (current == '/' && next == '/') {
      index += 2;
      while (index < source.length && source[index] != '\n') {
        index++;
      }
      if (index < source.length) {
        buffer.write('\n');
        index++;
      }
      continue;
    }

    if (current == '/' && next == '*') {
      index += 2;
      while (index + 1 < source.length &&
          !(source[index] == '*' && source[index + 1] == '/')) {
        if (source[index] == '\n') {
          buffer.write('\n');
        }
        index++;
      }
      index = index + 1 < source.length ? index + 2 : source.length;
      continue;
    }

    if (current == '\'' || current == '"') {
      index = _skipDartStringLiteral(source, index);
      buffer.write(' ');
      continue;
    }

    buffer.write(current);
    index++;
  }

  return buffer.toString();
}

int _skipDartStringLiteral(String source, int start) {
  final quote = source[start];
  final isTriple =
      start + 2 < source.length &&
      source[start + 1] == quote &&
      source[start + 2] == quote;
  var index = start + (isTriple ? 3 : 1);

  while (index < source.length) {
    if (!isTriple && source[index] == '\\') {
      index += 2;
      continue;
    }

    if (isTriple &&
        index + 2 < source.length &&
        source[index] == quote &&
        source[index + 1] == quote &&
        source[index + 2] == quote) {
      return index + 3;
    }

    if (!isTriple && source[index] == quote) {
      return index + 1;
    }

    index++;
  }

  return source.length;
}
