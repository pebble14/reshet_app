import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace_contract.dart';
import 'package:reshet_app/ui/explorer_workspace/word_explorer_workspace_projection_adapter.dart';

void main() {
  group('Phase 7-D read-only projection adapter', () {
    test('projects explicit current owner values into workspace state', () {
      final state = WordExplorerWorkspaceProjectionAdapter.project(
        selectedWordId: '  W_PHASE7D_SELECTED_001  ',
        graphCenterWordId: '  W_PHASE7D_CENTER_001  ',
        detailTargetWordId: '  W_PHASE7D_DETAIL_001  ',
        layoutPreset: ExplorerWorkspaceLayoutPreset.detailFocused,
        origin: ExplorerWorkspaceTransitionOrigin.graphNode,
      );

      expect(state.selectedWordId, 'W_PHASE7D_SELECTED_001');
      expect(state.graphCenterWordId, 'W_PHASE7D_CENTER_001');
      expect(state.detailTargetWordId, 'W_PHASE7D_DETAIL_001');
      expect(state.layoutPreset, ExplorerWorkspaceLayoutPreset.detailFocused);
      expect(state.origin, ExplorerWorkspaceTransitionOrigin.graphNode);
    });

    test('does not infer detail target from selected word when omitted', () {
      final state = WordExplorerWorkspaceProjectionAdapter.project(
        selectedWordId: 'W_PHASE7D_SELECTED_ONLY',
        graphCenterWordId: 'W_PHASE7D_CENTER_ONLY',
        layoutPreset: ExplorerWorkspaceLayoutPreset.balanced,
        origin: ExplorerWorkspaceTransitionOrigin.initialEntry,
      );

      expect(state.selectedWordId, 'W_PHASE7D_SELECTED_ONLY');
      expect(state.graphCenterWordId, 'W_PHASE7D_CENTER_ONLY');
      expect(state.detailTargetWordId, isNull);
      expect(state.layoutPreset, ExplorerWorkspaceLayoutPreset.balanced);
      expect(state.origin, ExplorerWorkspaceTransitionOrigin.initialEntry);
    });

    test(
      'accepts identical selected and detail values when caller passes both',
      () {
        final state = WordExplorerWorkspaceProjectionAdapter.project(
          selectedWordId: 'W_PHASE7D_SHARED_001',
          graphCenterWordId: 'W_PHASE7D_CENTER_SHARED_001',
          detailTargetWordId: 'W_PHASE7D_SHARED_001',
          layoutPreset: ExplorerWorkspaceLayoutPreset.balanced,
          origin: ExplorerWorkspaceTransitionOrigin.routeAlias,
        );

        expect(state.selectedWordId, 'W_PHASE7D_SHARED_001');
        expect(state.detailTargetWordId, 'W_PHASE7D_SHARED_001');
      },
    );

    test(
      'rejects empty projected ids instead of synthesizing fallback state',
      () {
        expect(
          () => WordExplorerWorkspaceProjectionAdapter.project(
            selectedWordId: '   ',
            layoutPreset: ExplorerWorkspaceLayoutPreset.balanced,
            origin: ExplorerWorkspaceTransitionOrigin.initialEntry,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => WordExplorerWorkspaceProjectionAdapter.project(
            graphCenterWordId: '\t',
            layoutPreset: ExplorerWorkspaceLayoutPreset.graphFocused,
            origin: ExplorerWorkspaceTransitionOrigin.routeAlias,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => WordExplorerWorkspaceProjectionAdapter.project(
            detailTargetWordId: '',
            layoutPreset: ExplorerWorkspaceLayoutPreset.detailFocused,
            origin: ExplorerWorkspaceTransitionOrigin.detailPane,
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });

  group('Phase 7-D source-level boundary', () {
    const adapterSourcePath =
        'lib/ui/explorer_workspace/word_explorer_workspace_projection_adapter.dart';
    late String adapterSource;

    setUpAll(() {
      adapterSource = File(adapterSourcePath).readAsStringSync();
    });

    test('keeps projection inputs explicit and independent', () {
      expect(adapterSource, contains('String? selectedWordId'));
      expect(adapterSource, contains('String? graphCenterWordId'));
      expect(adapterSource, contains('String? detailTargetWordId'));
      expect(
        adapterSource,
        contains('required ExplorerWorkspaceLayoutPreset layoutPreset'),
      );
      expect(
        adapterSource,
        contains('required ExplorerWorkspaceTransitionOrigin origin'),
      );
    });

    test('avoids runtime owners, data sources, and async work', () {
      const forbiddenMarkers = <String>[
        'Navigator',
        'MaterialPageRoute',
        'push(',
        'pushReplacement',
        'WordRepository',
        'DatabaseService',
        'Provider',
        'ChangeNotifierProvider',
        'MultiProvider',
        'Future<',
        'async',
        'await',
        'setState',
        'ValueChanged',
        'VoidCallback',
      ];

      for (final forbiddenMarker in forbiddenMarkers) {
        expect(
          adapterSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'Projection adapter must stay read-only and owner-preserving: '
              '$forbiddenMarker.',
        );
      }
    });
  });
}
