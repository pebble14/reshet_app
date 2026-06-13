import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace_contract.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace_preview_screen.dart';

void main() {
  group('Phase 4-C ExplorerWorkspace passive synchronization boundary', () {
    testWidgets('projects distinct ids without merging or inferred ownership', (
      tester,
    ) async {
      await _pumpPreview(
        tester,
        ExplorerWorkspacePreviewScreen.fromInput(
          input: ExplorerWorkspacePreviewInput(
            selectedWordId: '  W_PHASE4C_SELECTED_001  ',
            graphCenterWordId: '  W_PHASE4C_CENTER_002  ',
            detailTargetWordId: '  W_PHASE4C_DETAIL_003  ',
            layoutPreset: ExplorerWorkspaceLayoutPreset.graphFocused,
            origin: ExplorerWorkspaceTransitionOrigin.graphNode,
          ),
        ),
      );

      expect(find.text('center: W_PHASE4C_CENTER_002'), findsOneWidget);
      expect(find.text('target: W_PHASE4C_DETAIL_003'), findsOneWidget);
      expect(find.text('selected: W_PHASE4C_SELECTED_001'), findsNWidgets(2));
      expect(find.text('preset: graphFocused'), findsOneWidget);
      expect(find.text('origin: graphNode'), findsOneWidget);
    });

    test('preserves projection fields without inferred synchronization', () {
      final input = ExplorerWorkspacePreviewInput(
        selectedWordId: 'W_PHASE4C_SELECTED_SHAPE',
        graphCenterWordId: 'W_PHASE4C_CENTER_SHAPE',
        detailTargetWordId: 'W_PHASE4C_DETAIL_SHAPE',
        layoutPreset: ExplorerWorkspaceLayoutPreset.detailFocused,
        origin: ExplorerWorkspaceTransitionOrigin.detailPane,
      );

      final state = ExplorerWorkspaceState.fromPreviewInput(input);

      expect(state.selectedWordId, 'W_PHASE4C_SELECTED_SHAPE');
      expect(state.graphCenterWordId, 'W_PHASE4C_CENTER_SHAPE');
      expect(state.detailTargetWordId, 'W_PHASE4C_DETAIL_SHAPE');
      expect(state.layoutPreset, ExplorerWorkspaceLayoutPreset.detailFocused);
      expect(state.origin, ExplorerWorkspaceTransitionOrigin.detailPane);
      expect(state.selectedWordId, isNot(state.graphCenterWordId));
      expect(state.selectedWordId, isNot(state.detailTargetWordId));
      expect(state.graphCenterWordId, isNot(state.detailTargetWordId));
    });
  });

  group('Phase 4-C source-level passive boundary regression', () {
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

    test('preview input stays a read-only id projection contract', () {
      expect(inputSource, contains('final String? selectedWordId'));
      expect(inputSource, contains('final String? graphCenterWordId'));
      expect(inputSource, contains('final String? detailTargetWordId'));
      expect(inputSource, contains('ExplorerWorkspaceLayoutPreset'));
      expect(inputSource, contains('ExplorerWorkspaceTransitionOrigin'));

      const forbiddenInputOwnerMarkers = <String>[
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
        'callback',
      ];

      for (final forbiddenMarker in forbiddenInputOwnerMarkers) {
        expect(
          inputSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'Passive projection input must not become an owner boundary: '
              '$forbiddenMarker.',
        );
      }
    });

    test('preview wrapper does not become an orchestration owner', () {
      expect(
        previewSource,
        contains('ExplorerWorkspaceState.fromPreviewInput(input)'),
      );
      expect(previewSource, contains('ExplorerWorkspace(state: state)'));

      const forbiddenWrapperOwnerMarkers = <String>[
        'onStrongSelected',
        'onSearchResultSelected',
        'onGraphNodeSelected',
        'onGraphCenterRequested',
        'onDetailRelationSelected',
        'onAddWordRequested',
        'ValueChanged',
        'VoidCallback',
        'Function',
        'setState',
        'StatefulWidget',
        'State<',
        'Navigator',
        'MaterialPageRoute',
        'WordRepository',
        'WordNavigationHistory',
        'ExplorerWorkspaceHistoryEntry',
      ];

      for (final forbiddenMarker in forbiddenWrapperOwnerMarkers) {
        expect(
          previewSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'Preview wrapper must stay a read-only adapter, not an '
              'orchestration owner: $forbiddenMarker.',
        );
      }
    });

    test('does not connect postponed projection surfaces', () {
      for (final source in [inputSource, previewSource]) {
        const postponedMarkers = <String>[
          'SearchResult',
          'searchResult',
          'HomeSearchResultDisplayItem',
          'DisplayItem',
          'displayItem',
          'WordDetailLikeDisplayItem',
          'GraphCenterWordDisplayItem',
          'WordNavigationHistory',
          'ExplorerWorkspaceHistoryEntry',
          'history',
          'Map<String, dynamic>',
        ];

        for (final postponedMarker in postponedMarkers) {
          expect(
            source,
            isNot(contains(postponedMarker)),
            reason:
                'Phase 4-C must not connect postponed projection surface: '
                '$postponedMarker.',
          );
        }
      }
    });

    test('workspace preview boundary does not own reads or routes', () {
      for (final source in [workspaceSource, previewSource]) {
        const forbiddenReadOrRouteMarkers = <String>[
          'WordRepository',
          '../data/repositories/',
          'data/repositories',
          'word_repository.dart',
          'getVisibleGraphData',
          'getWordDetailLikeDisplayItem',
          'getGraphCenterWordDisplayItem',
          'wordExistsForGraphNavigation',
          'probeExistingWordIds',
          'Navigator',
          'MaterialPageRoute',
          'pushReplacement',
          'pushNamed',
          'pushAndRemoveUntil',
          'onGenerateRoute',
          'routes:',
        ];

        for (final forbiddenMarker in forbiddenReadOrRouteMarkers) {
          expect(
            source,
            isNot(contains(forbiddenMarker)),
            reason:
                'Preview boundary must not own repository/read source or '
                'Navigator history: $forbiddenMarker.',
          );
        }
      }
    });

    test('production app home and owner remain unchanged', () {
      expect(mainSource, contains('home: const HomeScreen()'));
      expect(mainSource, isNot(contains('ExplorerWorkspacePreviewScreen')));
      expect(mainSource, isNot(contains('explorer_workspace_preview_screen')));

      expect(homeSource, isNot(contains('ExplorerWorkspacePreviewScreen')));
      expect(homeSource, isNot(contains('explorer_workspace_preview_screen')));

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

    test('direct production screen embedding remains blocked', () {
      for (final source in [workspaceSource, previewSource]) {
        const forbiddenEmbedMarkers = <String>[
          'WordExplorerScreen',
          'WordGraphScreen',
          'WordDetailScreen',
          'WordInfoPanel',
        ];

        for (final forbiddenMarker in forbiddenEmbedMarkers) {
          expect(
            source,
            isNot(contains(forbiddenMarker)),
            reason:
                'ExplorerWorkspace preview boundary must not directly embed '
                'production screens or panels: $forbiddenMarker.',
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
