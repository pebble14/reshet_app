import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace_contract.dart';

void main() {
  group('Phase 3-C ExplorerWorkspace passive projection', () {
    testWidgets('renders raw workspace state labels without production data', (
      tester,
    ) async {
      await _pumpWorkspace(tester, state: _phase3cState);

      expect(find.text('center: W_PHASE3C_CENTER_001'), findsOneWidget);
      expect(find.text('target: W_PHASE3C_DETAIL_001'), findsOneWidget);
      expect(find.text('selected: W_PHASE3C_SELECTED_001'), findsNWidgets(2));
      expect(find.text('preset: detailFocused'), findsOneWidget);
      expect(find.text('origin: globalSearch'), findsOneWidget);
    });

    testWidgets('keeps override slots separate from placeholder projection', (
      tester,
    ) async {
      await _pumpWorkspace(
        tester,
        state: _phase3cState,
        graphPanelOverride: const Center(
          child: Text('Phase 3-C graph override'),
        ),
        detailPaneOverride: const Center(
          child: Text('Phase 3-C detail override'),
        ),
      );

      expect(find.text('Phase 3-C graph override'), findsOneWidget);
      expect(find.text('Phase 3-C detail override'), findsOneWidget);
      expect(find.text('center: W_PHASE3C_CENTER_001'), findsNothing);
      expect(find.text('target: W_PHASE3C_DETAIL_001'), findsNothing);
      expect(find.text('selected: W_PHASE3C_SELECTED_001'), findsNothing);
      expect(find.text('preset: detailFocused'), findsNothing);
      expect(find.text('origin: globalSearch'), findsNothing);
    });
  });
}

const _phase3cState = ExplorerWorkspaceState(
  selectedWordId: 'W_PHASE3C_SELECTED_001',
  graphCenterWordId: 'W_PHASE3C_CENTER_001',
  detailTargetWordId: 'W_PHASE3C_DETAIL_001',
  layoutPreset: ExplorerWorkspaceLayoutPreset.detailFocused,
  origin: ExplorerWorkspaceTransitionOrigin.globalSearch,
);

Future<void> _pumpWorkspace(
  WidgetTester tester, {
  required ExplorerWorkspaceState state,
  Widget? graphPanelOverride,
  Widget? detailPaneOverride,
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
      ),
    ),
  );
}
