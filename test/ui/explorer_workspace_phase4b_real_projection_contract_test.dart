import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace_contract.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace_preview_screen.dart';

void main() {
  group('Phase 4-B ExplorerWorkspace real projection input contract', () {
    testWidgets('accepts real id projection shape without owning reads', (
      tester,
    ) async {
      await _pumpPreview(
        tester,
        ExplorerWorkspacePreviewScreen.fromInput(
          input: ExplorerWorkspacePreviewInput(
            selectedWordId: '  W_PHASE4B_SELECTED_001  ',
            graphCenterWordId: '  W_PHASE4B_CENTER_001  ',
            detailTargetWordId: '  W_PHASE4B_DETAIL_001  ',
            layoutPreset: ExplorerWorkspaceLayoutPreset.detailFocused,
            origin: ExplorerWorkspaceTransitionOrigin.routeAlias,
          ),
        ),
      );

      expect(find.text('StrongRail'), findsOneWidget);
      expect(find.text('GlobalSearch'), findsOneWidget);
      expect(find.text('GraphPanel'), findsOneWidget);
      expect(find.text('DetailPane'), findsOneWidget);
      expect(find.text('AddWordFixedAction'), findsOneWidget);
      expect(find.text('center: W_PHASE4B_CENTER_001'), findsOneWidget);
      expect(find.text('target: W_PHASE4B_DETAIL_001'), findsOneWidget);
      expect(find.text('selected: W_PHASE4B_SELECTED_001'), findsNWidgets(2));
      expect(find.text('preset: detailFocused'), findsOneWidget);
      expect(find.text('origin: routeAlias'), findsOneWidget);
    });

    test('keeps projection input as id-only read shape', () {
      final input = ExplorerWorkspacePreviewInput(
        selectedWordId: 'W_PHASE4B_SELECTED_SHAPE',
        graphCenterWordId: 'W_PHASE4B_CENTER_SHAPE',
        detailTargetWordId: 'W_PHASE4B_DETAIL_SHAPE',
        layoutPreset: ExplorerWorkspaceLayoutPreset.balanced,
        origin: ExplorerWorkspaceTransitionOrigin.initialEntry,
      );

      final state = ExplorerWorkspaceState.fromPreviewInput(input);

      expect(state.selectedWordId, 'W_PHASE4B_SELECTED_SHAPE');
      expect(state.graphCenterWordId, 'W_PHASE4B_CENTER_SHAPE');
      expect(state.detailTargetWordId, 'W_PHASE4B_DETAIL_SHAPE');
      expect(state.layoutPreset, ExplorerWorkspaceLayoutPreset.balanced);
      expect(state.origin, ExplorerWorkspaceTransitionOrigin.initialEntry);
    });

    test('rejects empty projected ids instead of creating dummy input', () {
      expect(
        () => ExplorerWorkspacePreviewInput(
          selectedWordId: '   ',
          layoutPreset: ExplorerWorkspaceLayoutPreset.balanced,
          origin: ExplorerWorkspaceTransitionOrigin.initialEntry,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ExplorerWorkspacePreviewInput(
          graphCenterWordId: '',
          layoutPreset: ExplorerWorkspaceLayoutPreset.graphFocused,
          origin: ExplorerWorkspaceTransitionOrigin.routeAlias,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ExplorerWorkspacePreviewInput(
          detailTargetWordId: '\t',
          layoutPreset: ExplorerWorkspaceLayoutPreset.detailFocused,
          origin: ExplorerWorkspaceTransitionOrigin.routeAlias,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Phase 4-B source-level ownership boundary', () {
    const contractSourcePath =
        'lib/ui/explorer_workspace/explorer_workspace_contract.dart';
    const workspaceSourcePath =
        'lib/ui/explorer_workspace/explorer_workspace.dart';
    const previewSourcePath =
        'lib/ui/explorer_workspace/explorer_workspace_preview_screen.dart';
    const mainSourcePath = 'lib/main.dart';
    const homeSourcePath = 'lib/ui/home_screen.dart';
    const explorerSourcePath = 'lib/ui/word_explorer_screen.dart';
    late String contractSource;
    late String inputSource;
    late String workspaceSource;
    late String previewSource;
    late String mainSource;
    late String homeSource;
    late String explorerSource;

    setUpAll(() {
      contractSource = File(contractSourcePath).readAsStringSync();
      inputSource = _extractPreviewInputSource(contractSource);
      workspaceSource = File(workspaceSourcePath).readAsStringSync();
      previewSource = File(previewSourcePath).readAsStringSync();
      mainSource = File(mainSourcePath).readAsStringSync();
      homeSource = File(homeSourcePath).readAsStringSync();
      explorerSource = File(explorerSourcePath).readAsStringSync();
    });

    test('projection input has fields but no owner callbacks or mutations', () {
      expect(inputSource, contains('final String? selectedWordId'));
      expect(inputSource, contains('final String? graphCenterWordId'));
      expect(inputSource, contains('final String? detailTargetWordId'));
      expect(inputSource, contains('final ExplorerWorkspaceLayoutPreset'));

      const forbiddenOwnerMarkers = <String>[
        'ValueChanged',
        'VoidCallback',
        'Function',
        'setState',
        'StatefulWidget',
        'State<',
        'ChangeNotifier',
        'ValueNotifier',
        'StreamController',
        'Navigator',
        'MaterialPageRoute',
        'WordRepository',
      ];

      for (final forbiddenMarker in forbiddenOwnerMarkers) {
        expect(
          inputSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'Projection input must not become an owner boundary: '
              '$forbiddenMarker.',
        );
      }
    });

    test('projection input excludes postponed data and history surfaces', () {
      const postponedMarkers = <String>[
        'SearchResult',
        'searchResult',
        'DisplayItem',
        'displayItem',
        'HistoryEntry',
        'history',
        'Map<String, dynamic>',
      ];

      for (final postponedMarker in postponedMarkers) {
        expect(
          inputSource,
          isNot(contains(postponedMarker)),
          reason:
              'Phase 4-B projection input must not include postponed surface: '
              '$postponedMarker.',
        );
      }
    });

    test('preview wrapper consumes input without production ownership', () {
      expect(
        previewSource,
        contains('final ExplorerWorkspacePreviewInput input'),
      );
      expect(
        previewSource,
        contains('ExplorerWorkspaceState.fromPreviewInput(input)'),
      );

      const forbiddenPreviewOwnerMarkers = <String>[
        'WordExplorerScreen',
        'WordGraphScreen',
        'WordDetailScreen',
        'WordRepository',
        'Navigator',
        'MaterialPageRoute',
        'StatefulWidget',
        'setState',
        'initState',
        'dispose',
        'routes:',
        'onGenerateRoute',
      ];

      for (final forbiddenMarker in forbiddenPreviewOwnerMarkers) {
        expect(
          previewSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'Preview wrapper must stay a projection consumer: '
              '$forbiddenMarker.',
        );
      }
    });

    test('does not create dummy ids, fallback data, or display items', () {
      for (final source in [inputSource, previewSource]) {
        const forbiddenDataMarkers = <String>[
          'dummy',
          'fallback',
          'DisplayItem',
          'displayItem',
          'WordDetailLikeDisplayItem',
          'GraphCenterWordDisplayItem',
        ];

        for (final forbiddenMarker in forbiddenDataMarkers) {
          expect(
            source,
            isNot(contains(forbiddenMarker)),
            reason:
                'Phase 4-B may pass real id strings but must not synthesize '
                'data: $forbiddenMarker.',
          );
        }
      }
    });

    test('production import tree stays independent from preview surfaces', () {
      expect(mainSource, matches(RegExp(r'home:\s*HomeScreen\s*\(')));
      expect(mainSource, isNot(contains('ExplorerWorkspacePreviewScreen')));
      expect(mainSource, isNot(contains('explorer_workspace_preview_screen')));

      expect(homeSource, isNot(contains('ExplorerWorkspacePreviewScreen')));
      expect(homeSource, isNot(contains('explorer_workspace_preview_screen')));
    });

    test('WordExplorerScreen remains the production owner', () {
      expect(
        explorerSource,
        contains('class WordExplorerScreen extends StatefulWidget'),
      );
      expect(explorerSource, contains('final WordRepository _repository'));
      expect(explorerSource, contains('late String _centerWordId'));
      expect(explorerSource, contains('String? _selectedWordId'));
      expect(
        explorerSource,
        contains('WordDetailLikeDisplayItem? _selectedWordDisplayItem'),
      );
      expect(explorerSource, contains('WordGraphScreen('));
      expect(explorerSource, contains('WordDetailScreen('));
      expect(explorerSource, contains('Navigator.push'));
    });

    test('direct embed and route collapse remain blocked', () {
      for (final source in [workspaceSource, previewSource]) {
        const forbiddenEmbedMarkers = <String>[
          'WordGraphScreen',
          'WordDetailScreen',
          'WordExplorerScreen',
          'MaterialPageRoute',
          'pushReplacement',
          'pushNamed',
          'pushAndRemoveUntil',
          'onGenerateRoute',
          'routes:',
        ];

        for (final forbiddenMarker in forbiddenEmbedMarkers) {
          expect(
            source,
            isNot(contains(forbiddenMarker)),
            reason:
                'ExplorerWorkspace preview boundary must not collapse route '
                'or embed production screens: $forbiddenMarker.',
          );
        }
      }
    });
  });
}

String _extractPreviewInputSource(String contractSource) {
  final start = contractSource.indexOf('class ExplorerWorkspacePreviewInput');
  final end = contractSource.indexOf('class ExplorerWorkspaceState');

  expect(start, isNonNegative);
  expect(end, greaterThan(start));

  return contractSource.substring(start, end);
}

Future<void> _pumpPreview(
  WidgetTester tester,
  ExplorerWorkspacePreviewScreen previewScreen,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        textTheme: const TextTheme(
          titleMedium: TextStyle(fontSize: 9),
          bodySmall: TextStyle(fontSize: 7),
          labelLarge: TextStyle(fontSize: 8),
        ),
      ),
      home: previewScreen,
    ),
  );
}
