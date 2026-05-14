import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace_contract.dart';

void main() {
  group('ExplorerWorkspaceState route alias factories', () {
    test('creates explorer entry state without graph center ownership', () {
      final state = ExplorerWorkspaceState.forExplorerEntry('  W_ENTRY_001  ');

      expect(state.selectedWordId, 'W_ENTRY_001');
      expect(state.detailTargetWordId, 'W_ENTRY_001');
      expect(state.graphCenterWordId, isNull);
      expect(state.layoutPreset, ExplorerWorkspaceLayoutPreset.balanced);
      expect(state.origin, ExplorerWorkspaceTransitionOrigin.routeAlias);
    });

    test('creates graph route alias with graph center only', () {
      final state = ExplorerWorkspaceState.forGraphRouteAlias(
        '  W_GRAPH_001  ',
      );

      expect(state.graphCenterWordId, 'W_GRAPH_001');
      expect(state.selectedWordId, isNull);
      expect(state.detailTargetWordId, isNull);
      expect(state.layoutPreset, ExplorerWorkspaceLayoutPreset.graphFocused);
      expect(state.origin, ExplorerWorkspaceTransitionOrigin.routeAlias);
    });

    test('creates detail route alias without changing graph center', () {
      final state = ExplorerWorkspaceState.forDetailRouteAlias(
        '  W_DETAIL_001  ',
      );

      expect(state.selectedWordId, 'W_DETAIL_001');
      expect(state.detailTargetWordId, 'W_DETAIL_001');
      expect(state.graphCenterWordId, isNull);
      expect(state.layoutPreset, ExplorerWorkspaceLayoutPreset.detailFocused);
      expect(state.origin, ExplorerWorkspaceTransitionOrigin.routeAlias);
    });

    test('restores the exact workspace snapshot state', () {
      const snapshot = ExplorerWorkspaceState(
        selectedWordId: 'W_SELECTED_001',
        graphCenterWordId: 'W_CENTER_001',
        detailTargetWordId: 'W_DETAIL_001',
        layoutPreset: ExplorerWorkspaceLayoutPreset.graphFocused,
        origin: ExplorerWorkspaceTransitionOrigin.snapshotRestore,
      );
      const entry = ExplorerWorkspaceHistoryEntry(snapshot: snapshot);

      final restored = ExplorerWorkspaceState.fromSnapshot(entry);

      expect(identical(restored, snapshot), isTrue);
      expect(restored, snapshot);
    });

    test('rejects empty route alias word ids', () {
      expect(
        () => ExplorerWorkspaceState.forExplorerEntry('   '),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ExplorerWorkspaceState.forGraphRouteAlias(''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ExplorerWorkspaceState.forDetailRouteAlias('\t'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
