import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace_contract.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace_preview_interaction_host.dart';

void main() {
  group('Phase 4-D ExplorerWorkspace preview-local interaction boundary', () {
    testWidgets('updates graph and detail targets inside preview host only', (
      tester,
    ) async {
      await _pumpPreviewInteractionHost(
        tester,
        ExplorerWorkspacePreviewInput(
          selectedWordId: '  W_PHASE4D_SELECTED_001  ',
          graphCenterWordId: '  W_PHASE4D_CENTER_002  ',
          detailTargetWordId: '  W_PHASE4D_DETAIL_003  ',
          layoutPreset: ExplorerWorkspaceLayoutPreset.balanced,
          origin: ExplorerWorkspaceTransitionOrigin.initialEntry,
        ),
      );

      expect(
        find.text('preview graph center: W_PHASE4D_CENTER_002'),
        findsOneWidget,
      );
      expect(
        find.text('preview detail target: W_PHASE4D_DETAIL_003'),
        findsOneWidget,
      );

      await tester.tap(find.text('GraphFocus:W_PHASE4D_SELECTED_001'));
      await tester.pump();

      expect(
        find.text('preview graph center: W_PHASE4D_SELECTED_001'),
        findsOneWidget,
      );
      expect(
        find.text('preview detail target: W_PHASE4D_DETAIL_003'),
        findsOneWidget,
      );

      await tester.tap(find.text('DetailTarget:W_PHASE4D_CENTER_002'));
      await tester.pump();

      expect(
        find.text('preview graph center: W_PHASE4D_SELECTED_001'),
        findsOneWidget,
      );
      expect(
        find.text('preview detail target: W_PHASE4D_CENTER_002'),
        findsOneWidget,
      );
    });

    testWidgets('uses only caller-provided projection ids', (tester) async {
      await _pumpPreviewInteractionHost(
        tester,
        ExplorerWorkspacePreviewInput(
          selectedWordId: '  W_PHASE4D_ONLY_001  ',
          detailTargetWordId: 'W_PHASE4D_ONLY_001',
          layoutPreset: ExplorerWorkspaceLayoutPreset.detailFocused,
          origin: ExplorerWorkspaceTransitionOrigin.globalSearch,
        ),
      );

      expect(find.text('GraphFocus:W_PHASE4D_ONLY_001'), findsOneWidget);
      expect(find.text('DetailTarget:W_PHASE4D_ONLY_001'), findsOneWidget);
      expect(find.textContaining('W_PHASE4D_MISSING'), findsNothing);
    });

    testWidgets('does not create preview actions when input has no ids', (
      tester,
    ) async {
      await _pumpPreviewInteractionHost(
        tester,
        ExplorerWorkspacePreviewInput(
          layoutPreset: ExplorerWorkspaceLayoutPreset.balanced,
          origin: ExplorerWorkspaceTransitionOrigin.initialEntry,
        ),
      );

      expect(find.text('preview graph center: none'), findsOneWidget);
      expect(find.text('preview detail target: none'), findsOneWidget);
      expect(find.textContaining('GraphFocus:'), findsNothing);
      expect(find.textContaining('DetailTarget:'), findsNothing);
    });
  });

  group('Phase 4-D source-level boundary regression', () {
    const hostSourcePath =
        'lib/ui/explorer_workspace/explorer_workspace_preview_interaction_host.dart';
    const previewSourcePath =
        'lib/ui/explorer_workspace/explorer_workspace_preview_screen.dart';
    const mainSourcePath = 'lib/main.dart';
    const homeSourcePath = 'lib/ui/home_screen.dart';
    late String hostSource;
    late String previewSource;
    late String mainSource;
    late String homeSource;

    setUpAll(() {
      hostSource = File(hostSourcePath).readAsStringSync();
      previewSource = File(previewSourcePath).readAsStringSync();
      mainSource = File(mainSourcePath).readAsStringSync();
      homeSource = File(homeSourcePath).readAsStringSync();
    });

    test('preview interaction host stays separated from production owners', () {
      const forbiddenProductionReferences = <String>[
        'WordExplorerScreen',
        'WordGraphScreen',
        'WordDetailScreen',
        'WordInfoPanel',
        'WordRepository',
        '../data/repositories/',
        'data/repositories',
        'word_repository.dart',
      ];

      for (final forbiddenReference in forbiddenProductionReferences) {
        expect(
          hostSource,
          isNot(contains(forbiddenReference)),
          reason:
              'Phase 4-D preview interaction host must not reference '
              'production owner: $forbiddenReference.',
        );
      }
    });

    test('preview interaction host does not own reads or routes', () {
      const forbiddenReadOrRouteMarkers = <String>[
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
          hostSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'Phase 4-D preview interaction must not own read or route '
              'boundary: $forbiddenMarker.',
        );
      }
    });

    test('preview interaction host does not synthesize data carriers', () {
      const forbiddenDataMarkers = <String>[
        'dummy',
        'fallback',
        'DisplayItem',
        'displayItem',
        'WordDetailLikeDisplayItem',
        'GraphCenterWordDisplayItem',
        'Map<String, dynamic>',
      ];

      for (final forbiddenMarker in forbiddenDataMarkers) {
        expect(
          hostSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'Phase 4-D preview interaction must use projection ids only: '
              '$forbiddenMarker.',
        );
      }
    });

    test('preview interaction does not use route alias factories', () {
      const forbiddenRouteAliasMarkers = <String>[
        'ExplorerWorkspaceState.forExplorerEntry',
        'ExplorerWorkspaceState.forGraphRouteAlias',
        'ExplorerWorkspaceState.forDetailRouteAlias',
        'ExplorerWorkspacePreviewInput.forExplorerEntry',
        'ExplorerWorkspacePreviewInput.forGraphRouteAlias',
        'ExplorerWorkspacePreviewInput.forDetailRouteAlias',
      ];

      for (final forbiddenMarker in forbiddenRouteAliasMarkers) {
        expect(
          hostSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'Phase 4-D preview-local interaction must not be route alias '
              'based: $forbiddenMarker.',
        );
      }
    });

    test('passive preview wrapper and production entry stay unchanged', () {
      expect(
        previewSource,
        isNot(contains('ExplorerWorkspacePreviewInteractionHost')),
      );
      expect(mainSource, matches(RegExp(r'home:\s*HomeScreen\s*\(')));
      expect(mainSource, isNot(contains('ExplorerWorkspacePreviewScreen')));
      expect(
        mainSource,
        isNot(contains('ExplorerWorkspacePreviewInteractionHost')),
      );

      expect(homeSource, isNot(contains('ExplorerWorkspacePreviewScreen')));
      expect(
        homeSource,
        isNot(contains('ExplorerWorkspacePreviewInteractionHost')),
      );
    });
  });
}

Future<void> _pumpPreviewInteractionHost(
  WidgetTester tester,
  ExplorerWorkspacePreviewInput input,
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
      home: ExplorerWorkspacePreviewInteractionHost.fromInput(input: input),
    ),
  );
}
