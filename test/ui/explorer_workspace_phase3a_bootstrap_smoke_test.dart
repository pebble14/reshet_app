import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace_contract.dart';

void main() {
  group('Phase 3-A ExplorerWorkspace bootstrap smoke', () {
    testWidgets('renders explorer entry placeholders without route wiring', (
      tester,
    ) async {
      await _pumpWorkspace(
        tester,
        state: ExplorerWorkspaceState.forExplorerEntry(
          '  W_PHASE3A_ENTRY_001  ',
        ),
      );

      expect(find.text('StrongRail'), findsOneWidget);
      expect(find.text('GlobalSearch'), findsOneWidget);
      expect(find.text('GraphPanel'), findsOneWidget);
      expect(find.text('DetailPane'), findsOneWidget);
      expect(find.text('AddWordFixedAction'), findsOneWidget);
      expect(find.text('center: none'), findsOneWidget);
      expect(find.text('target: W_PHASE3A_ENTRY_001'), findsOneWidget);
    });

    testWidgets('renders graph route alias as graph-focused placeholder', (
      tester,
    ) async {
      await _pumpWorkspace(
        tester,
        state: ExplorerWorkspaceState.forGraphRouteAlias(
          '  W_PHASE3A_GRAPH_001  ',
        ),
      );

      expect(find.text('GraphPanel'), findsOneWidget);
      expect(find.text('DetailPane'), findsOneWidget);
      expect(find.text('center: W_PHASE3A_GRAPH_001'), findsOneWidget);
      expect(find.text('target: none'), findsOneWidget);
    });

    testWidgets('renders detail route alias as detail-focused placeholder', (
      tester,
    ) async {
      await _pumpWorkspace(
        tester,
        state: ExplorerWorkspaceState.forDetailRouteAlias(
          '  W_PHASE3A_DETAIL_001  ',
        ),
      );

      expect(find.text('GraphPanel'), findsOneWidget);
      expect(find.text('DetailPane'), findsOneWidget);
      expect(find.text('center: none'), findsOneWidget);
      expect(find.text('target: W_PHASE3A_DETAIL_001'), findsOneWidget);
    });

    testWidgets('renders passive graph and detail override widgets', (
      tester,
    ) async {
      await _pumpWorkspace(
        tester,
        state: ExplorerWorkspaceState.forExplorerEntry(
          'W_PHASE3A_OVERRIDE_001',
        ),
        graphPanelOverride: const Center(
          child: Text('Phase 3-A passive graph override'),
        ),
        detailPaneOverride: const Center(
          child: Text('Phase 3-A passive detail override'),
        ),
      );

      expect(find.text('Phase 3-A passive graph override'), findsOneWidget);
      expect(find.text('Phase 3-A passive detail override'), findsOneWidget);
      expect(find.text('GraphPanel'), findsNothing);
      expect(find.text('DetailPane'), findsNothing);
    });

    testWidgets('invokes add word callback from placeholder tap', (
      tester,
    ) async {
      var addRequested = false;

      await _pumpWorkspace(
        tester,
        state: ExplorerWorkspaceState.forExplorerEntry('W_PHASE3A_ADD_001'),
        onAddWordRequested: () {
          addRequested = true;
        },
      );

      await tester.tap(find.text('AddWordFixedAction'));
      await tester.pump();

      expect(addRequested, isTrue);
    });
  });
}

Future<void> _pumpWorkspace(
  WidgetTester tester, {
  required ExplorerWorkspaceState state,
  Widget? graphPanelOverride,
  Widget? detailPaneOverride,
  VoidCallback? onAddWordRequested,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        textTheme: const TextTheme(
          titleMedium: TextStyle(fontSize: 9),
          bodySmall: TextStyle(fontSize: 7),
          labelLarge: TextStyle(fontSize: 8),
        ),
      ),
      home: ExplorerWorkspace(
        state: state,
        graphPanelOverride: graphPanelOverride,
        detailPaneOverride: detailPaneOverride,
        onAddWordRequested: onAddWordRequested,
      ),
    ),
  );
}
