import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace_contract.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace_preview_interaction_host.dart';

void main() {
  group('Phase 5-B ExplorerWorkspace layout state policy', () {
    testWidgets(
      'keeps preset recommendation separate from current visibility state',
      (tester) async {
        await _pumpPreviewInteractionHost(
          tester,
          ExplorerWorkspacePreviewInput(
            selectedWordId: 'W_PHASE5B_SELECTED_001',
            graphCenterWordId: 'W_PHASE5B_CENTER_002',
            detailTargetWordId: 'W_PHASE5B_DETAIL_003',
            layoutPreset: ExplorerWorkspaceLayoutPreset.balanced,
            origin: ExplorerWorkspaceTransitionOrigin.initialEntry,
          ),
        );

        expect(find.text('preset 상태: balanced'), findsOneWidget);
        expect(find.text('visibility 상태: graph + detail'), findsOneWidget);

        await tester.ensureVisible(find.text('상세 패널 숨기기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('상세 패널 숨기기'));
        await tester.pump();

        expect(find.text('preset 상태: balanced'), findsOneWidget);
        expect(find.text('visibility 상태: graph only'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('explorer_workspace_detail_slot')),
          findsNothing,
        );

        await tester.ensureVisible(find.text('프리셋: detailFocused'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('프리셋: detailFocused'));
        await tester.pump();

        expect(find.text('preset 상태: detailFocused'), findsOneWidget);
        expect(find.text('preset 의미: detail 해석 집중 상태'), findsOneWidget);
        expect(find.text('visibility 상태: graph only'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('explorer_workspace_detail_slot')),
          findsNothing,
        );
        expect(_slotFlex(tester, 'explorer_workspace_graph_slot'), equals(1));

        await tester.ensureVisible(find.text('상세 패널 표시'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('상세 패널 표시'));
        await tester.pump();

        expect(find.text('preset 상태: detailFocused'), findsOneWidget);
        expect(find.text('visibility 상태: graph + detail'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('explorer_workspace_detail_slot')),
          findsOneWidget,
        );
        expect(_slotFlex(tester, 'explorer_workspace_graph_slot'), equals(2));
        expect(_slotFlex(tester, 'explorer_workspace_detail_slot'), equals(5));
      },
    );

    testWidgets(
      'guards against empty workspace through constructor and local policy',
      (tester) async {
        final state = ExplorerWorkspaceState(
          selectedWordId: 'W_PHASE5B_SELECTED_011',
          graphCenterWordId: 'W_PHASE5B_CENTER_012',
          detailTargetWordId: 'W_PHASE5B_DETAIL_013',
          layoutPreset: ExplorerWorkspaceLayoutPreset.balanced,
          origin: ExplorerWorkspaceTransitionOrigin.initialEntry,
        );

        expect(
          () => ExplorerWorkspace(
            state: state,
            showGraphPanel: false,
            showDetailPane: false,
          ),
          throwsA(isA<AssertionError>()),
        );

        await _pumpPreviewInteractionHost(
          tester,
          ExplorerWorkspacePreviewInput(
            selectedWordId: state.selectedWordId,
            graphCenterWordId: state.graphCenterWordId,
            detailTargetWordId: state.detailTargetWordId,
            layoutPreset: state.layoutPreset,
            origin: state.origin,
          ),
        );

        await tester.ensureVisible(find.text('그래프 패널 숨기기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('그래프 패널 숨기기'));
        await tester.pump();

        expect(find.text('visibility 상태: detail only'), findsOneWidget);
        expect(_isTextButtonEnabled(tester, '상세 패널 숨기기'), isFalse);
        expect(_isTextButtonEnabled(tester, '그래프 패널 표시'), isTrue);
      },
    );
  });

  group('Phase 5-B source and documentation boundary', () {
    late String workspaceSource;
    late String hostSource;
    late String uxDocument;
    late String constitutionDocument;
    late String changelog;

    setUpAll(() {
      workspaceSource = _readText('lib/ui/explorer_workspace/explorer_workspace.dart');
      hostSource = _readText(
        'lib/ui/explorer_workspace/explorer_workspace_preview_interaction_host.dart',
      );
      uxDocument = _readText('docs/ux/explorer_workspace_unification.md');
      constitutionDocument = _readText(
        'docs/architecture/explorer_workspace_constitution.md',
      );
      changelog = _readText('docs/logs/CHANGELOG.md');
    });

    test('documents record Phase 5-B layout state policy boundary', () {
      expect(
        uxDocument,
        contains('### 17.22 Phase 5-B layout state policy / preset UX refinement 기준'),
      );
      expect(uxDocument, contains('preset은 canonical authority가 아니다'));
      expect(uxDocument, contains('preset은 persistence authority가 아니다'));
      expect(
        uxDocument,
        contains('preset은 preview orchestration state일 뿐이다'),
      );
      expect(uxDocument, contains('graph hidden + detail hidden'));
      expect(uxDocument, contains('balanced default'));
      expect(
        constitutionDocument,
        contains('## 8. Phase 5-B layout state policy / preset UX refinement 보강'),
      );
      expect(
        constitutionDocument,
        contains('recommended orchestration snapshot'),
      );
      expect(constitutionDocument, contains('current local workspace state'));
      expect(changelog, contains('2026-05-19 Phase 5-B'));
      expect(changelog, contains('layout state policy'));
      expect(changelog, contains('preset UX semantics'));
    });

    test('source keeps preset state and visibility state separate', () {
      expect(hostSource, contains('preset 역할: 권장 orchestration snapshot'));
      expect(hostSource, contains('visibility 역할: 현재 local workspace state'));
      expect(hostSource, contains('enum _PreviewPanelVisibilityState'));
      expect(hostSource, contains('graphAndDetail'));
      expect(hostSource, contains('graphOnly'));
      expect(hostSource, contains('detailOnly'));
      expect(
        workspaceSource,
        contains('ExplorerWorkspace preview는 최소 하나의 semantic panel을 표시해야 합니다.'),
      );
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
