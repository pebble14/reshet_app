import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace_contract.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace_preview_interaction_host.dart';

void main() {
  group('Phase 5-A ExplorerWorkspace preview-only layout orchestration', () {
    testWidgets(
      'switches preset without changing semantic ids or preview targets',
      (tester) async {
        await _pumpPreviewInteractionHost(
          tester,
          ExplorerWorkspacePreviewInput(
            selectedWordId: 'W_PHASE5A_SELECTED_001',
            graphCenterWordId: 'W_PHASE5A_CENTER_002',
            detailTargetWordId: 'W_PHASE5A_DETAIL_003',
            layoutPreset: ExplorerWorkspaceLayoutPreset.balanced,
            origin: ExplorerWorkspaceTransitionOrigin.initialEntry,
          ),
        );

        expect(
          find.text('selected word: W_PHASE5A_SELECTED_001'),
          findsOneWidget,
        );
        expect(
          find.text('graph center word: W_PHASE5A_CENTER_002'),
          findsOneWidget,
        );
        expect(
          find.text('detail target word: W_PHASE5A_DETAIL_003'),
          findsOneWidget,
        );
        expect(find.text('preset 상태: balanced'), findsOneWidget);
        expect(find.text('origin 상태: initialEntry'), findsOneWidget);
        expect(find.text('visibility 상태: graph + detail'), findsOneWidget);
        expect(_slotFlex(tester, 'explorer_workspace_graph_slot'), equals(3));
        expect(_slotFlex(tester, 'explorer_workspace_detail_slot'), equals(2));

        await tester.ensureVisible(find.text('프리셋: graphFocused'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('프리셋: graphFocused'));
        await tester.pump();

        expect(
          find.text('selected word: W_PHASE5A_SELECTED_001'),
          findsOneWidget,
        );
        expect(
          find.text('graph center word: W_PHASE5A_CENTER_002'),
          findsOneWidget,
        );
        expect(
          find.text('detail target word: W_PHASE5A_DETAIL_003'),
          findsOneWidget,
        );
        expect(find.text('preset 상태: graphFocused'), findsOneWidget);
        expect(find.text('origin 상태: initialEntry'), findsOneWidget);
        expect(find.text('visibility 상태: graph + detail'), findsOneWidget);
        expect(_slotFlex(tester, 'explorer_workspace_graph_slot'), equals(5));
        expect(_slotFlex(tester, 'explorer_workspace_detail_slot'), equals(2));

        await tester.ensureVisible(find.text('프리셋: detailFocused'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('프리셋: detailFocused'));
        await tester.pump();

        expect(
          find.text('selected word: W_PHASE5A_SELECTED_001'),
          findsOneWidget,
        );
        expect(
          find.text('graph center word: W_PHASE5A_CENTER_002'),
          findsOneWidget,
        );
        expect(
          find.text('detail target word: W_PHASE5A_DETAIL_003'),
          findsOneWidget,
        );
        expect(find.text('preset 상태: detailFocused'), findsOneWidget);
        expect(find.text('origin 상태: initialEntry'), findsOneWidget);
        expect(find.text('visibility 상태: graph + detail'), findsOneWidget);
        expect(_slotFlex(tester, 'explorer_workspace_graph_slot'), equals(2));
        expect(_slotFlex(tester, 'explorer_workspace_detail_slot'), equals(5));
      },
    );

    testWidgets(
      'orchestrates panel visibility inside preview host local state only',
      (tester) async {
        await _pumpPreviewInteractionHost(
          tester,
          ExplorerWorkspacePreviewInput(
            selectedWordId: 'W_PHASE5A_SELECTED_011',
            graphCenterWordId: 'W_PHASE5A_CENTER_012',
            detailTargetWordId: 'W_PHASE5A_DETAIL_013',
            layoutPreset: ExplorerWorkspaceLayoutPreset.graphFocused,
            origin: ExplorerWorkspaceTransitionOrigin.globalSearch,
          ),
        );

        expect(
          find.byKey(const ValueKey('explorer_workspace_graph_slot')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('explorer_workspace_detail_slot')),
          findsOneWidget,
        );
        expect(find.text('visibility 상태: graph + detail'), findsOneWidget);

        await tester.ensureVisible(find.text('상세 패널 숨기기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('상세 패널 숨기기'));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('explorer_workspace_graph_slot')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('explorer_workspace_detail_slot')),
          findsNothing,
        );
        expect(find.text('visibility 상태: graph only'), findsOneWidget);
        expect(
          find.text('selected word: W_PHASE5A_SELECTED_011'),
          findsOneWidget,
        );
        expect(
          find.text('graph center word: W_PHASE5A_CENTER_012'),
          findsOneWidget,
        );
        expect(_slotFlex(tester, 'explorer_workspace_graph_slot'), equals(1));

        await tester.ensureVisible(find.text('상세 패널 표시'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('상세 패널 표시'));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('explorer_workspace_graph_slot')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('explorer_workspace_detail_slot')),
          findsOneWidget,
        );
        expect(find.text('visibility 상태: graph + detail'), findsOneWidget);
        expect(_slotFlex(tester, 'explorer_workspace_graph_slot'), equals(5));
        expect(_slotFlex(tester, 'explorer_workspace_detail_slot'), equals(2));

        await tester.ensureVisible(find.text('그래프 패널 숨기기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('그래프 패널 숨기기'));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('explorer_workspace_graph_slot')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('explorer_workspace_detail_slot')),
          findsOneWidget,
        );
        expect(find.text('visibility 상태: detail only'), findsOneWidget);
        expect(_slotFlex(tester, 'explorer_workspace_detail_slot'), equals(1));
      },
    );

    testWidgets('disables hiding the last visible panel', (tester) async {
      await _pumpPreviewInteractionHost(
        tester,
        ExplorerWorkspacePreviewInput(
          selectedWordId: 'W_PHASE5A_SELECTED_021',
          graphCenterWordId: 'W_PHASE5A_CENTER_022',
          detailTargetWordId: 'W_PHASE5A_DETAIL_023',
          layoutPreset: ExplorerWorkspaceLayoutPreset.detailFocused,
          origin: ExplorerWorkspaceTransitionOrigin.detailPane,
        ),
      );

      await tester.ensureVisible(find.text('그래프 패널 숨기기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('그래프 패널 숨기기'));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('explorer_workspace_graph_slot')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('explorer_workspace_detail_slot')),
        findsOneWidget,
      );
      expect(find.text('visibility 상태: detail only'), findsOneWidget);
      expect(_isTextButtonEnabled(tester, '상세 패널 숨기기'), isFalse);
      expect(_isTextButtonEnabled(tester, '그래프 패널 표시'), isTrue);

      expect(
        find.byKey(const ValueKey('explorer_workspace_graph_slot')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('explorer_workspace_detail_slot')),
        findsOneWidget,
      );
      expect(find.text('visibility 상태: detail only'), findsOneWidget);
    });
  });

  group('Phase 5-A source-level layout orchestration boundary', () {
    late String contractSource;
    late String workspaceSource;
    late String hostSource;
    late String mainSource;
    late String homeSource;
    late String wordExplorerSource;
    late String constitutionDocument;
    late String uxDocument;
    late String changelog;

    setUpAll(() {
      contractSource = _readText(
        'lib/ui/explorer_workspace/explorer_workspace_contract.dart',
      );
      workspaceSource = _readText(
        'lib/ui/explorer_workspace/explorer_workspace.dart',
      );
      hostSource = _readText(
        'lib/ui/explorer_workspace/explorer_workspace_preview_interaction_host.dart',
      );
      mainSource = _readText('lib/main.dart');
      homeSource = _readText('lib/ui/home_screen.dart');
      wordExplorerSource = _readText('lib/ui/word_explorer_screen.dart');
      constitutionDocument = _readText(
        'docs/architecture/explorer_workspace_constitution.md',
      );
      uxDocument = _readText('docs/ux/explorer_workspace_unification.md');
      changelog = _readText('docs/logs/CHANGELOG.md');
    });

    test('keeps layout visibility state outside semantic contract', () {
      expect(contractSource, isNot(contains('showGraphPanel')));
      expect(contractSource, isNot(contains('showDetailPane')));
      expect(hostSource, contains('_PreviewPanelVisibilityState'));
      expect(
        hostSource,
        contains(
          '_PreviewPanelVisibilityState _panelVisibilityState =',
        ),
      );
      expect(
        hostSource,
        contains('_PreviewPanelVisibilityState.graphAndDetail'),
      );
      expect(hostSource, contains('_setLayoutPreset'));
      expect(hostSource, contains('_toggleGraphPanel'));
      expect(hostSource, contains('_toggleDetailPane'));
      expect(workspaceSource, contains('final bool showGraphPanel;'));
      expect(workspaceSource, contains('final bool showDetailPane;'));
      expect(workspaceSource, contains('최소 하나의 semantic panel'));
    });

    test('preview layout orchestration does not own repository or routes', () {
      for (final source in [workspaceSource, hostSource]) {
        const forbiddenMarkers = <String>[
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
          'WordNavigationHistory',
          'RestorationMixin',
          'Restorable',
        ];

        for (final forbiddenMarker in forbiddenMarkers) {
          expect(
            source,
            isNot(contains(forbiddenMarker)),
            reason:
                'Phase 5-A preview layout orchestration must stay outside '
                'repository and route ownership: $forbiddenMarker.',
          );
        }
      }
    });

    test('preview layout orchestration does not synthesize dummy data', () {
      for (final source in [workspaceSource, hostSource]) {
        const forbiddenMarkers = <String>[
          'dummy',
          'fallback',
          'DisplayItem',
          'displayItem',
          'WordDetailLikeDisplayItem',
          'GraphCenterWordDisplayItem',
          'HomeSearchResultDisplayItem',
          'Map<String, dynamic>',
        ];

        for (final forbiddenMarker in forbiddenMarkers) {
          expect(
            source,
            isNot(contains(forbiddenMarker)),
            reason:
                'Phase 5-A preview layout orchestration must not create '
                'dummy or fallback data carriers: $forbiddenMarker.',
          );
        }
      }
    });

    test('production owner and route default remain unchanged', () {
      expect(mainSource, contains('home: const HomeScreen()'));
      expect(homeSource, contains('WordExplorerScreen('));
      expect(homeSource, contains('Navigator.push'));
      expect(
        wordExplorerSource,
        contains('class WordExplorerScreen extends StatefulWidget'),
      );
      expect(wordExplorerSource, contains('WordRepository'));

      for (final source in [mainSource, homeSource, wordExplorerSource]) {
        expect(
          source,
          isNot(contains('ExplorerWorkspacePreviewInteractionHost')),
        );
        expect(source, isNot(contains('프리셋: graphFocused')));
        expect(source, isNot(contains('그래프 패널 숨기기')));
        expect(source, isNot(contains('상세 패널 숨기기')));
      }
    });

    test('documents record preview-only layout orchestration boundary', () {
      expect(changelog, contains('2026-05-19 Phase 5-A'));
      expect(changelog, contains('preview-only layout orchestration'));
      expect(changelog, contains('production replacement가 아니다'));

      expect(
        constitutionDocument,
        contains('Phase 5-A preview-only layout orchestration 보강'),
      );
      expect(constitutionDocument, contains('layout coordinator'));
      expect(constitutionDocument, contains('ownership boundary 유지'));

      expect(
        uxDocument,
        contains('### 17.20 Phase 5-A preview-only layout orchestration 기준'),
      );
      expect(uxDocument, contains('layout coordination만 수행한다'));
      expect(uxDocument, contains('semantic id와 canonical item은 유지'));
      expect(uxDocument, contains('production replacement 단계가 아니다'));
    });
  });
}

bool _isTextButtonEnabled(WidgetTester tester, String label) {
  final button = tester.widget<TextButton>(
    find.widgetWithText(TextButton, label),
  );
  return button.onPressed != null;
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
          titleSmall: TextStyle(fontSize: 9),
          bodySmall: TextStyle(fontSize: 7),
          labelLarge: TextStyle(fontSize: 8),
        ),
      ),
      home: ExplorerWorkspacePreviewInteractionHost.fromInput(input: input),
    ),
  );
}

int _slotFlex(WidgetTester tester, String keyValue) {
  final slot = tester.widget<Expanded>(find.byKey(ValueKey(keyValue)));
  return slot.flex;
}

String _readText(String path) {
  return File(path).readAsStringSync();
}
