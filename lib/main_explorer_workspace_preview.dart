import 'package:flutter/material.dart';

import 'ui/explorer_workspace/explorer_workspace_contract.dart';
import 'ui/explorer_workspace/explorer_workspace_preview_interaction_host.dart';

final ExplorerWorkspacePreviewInput explorerWorkspacePreviewAccessInput =
    ExplorerWorkspacePreviewInput(
      selectedWordId: 'PREVIEW_SELECTED_ALPHA',
      graphCenterWordId: 'PREVIEW_CENTER_BETA',
      detailTargetWordId: 'PREVIEW_DETAIL_GAMMA',
      layoutPreset: ExplorerWorkspaceLayoutPreset.balanced,
      origin: ExplorerWorkspaceTransitionOrigin.initialEntry,
    );

void main() {
  runApp(const ExplorerWorkspacePreviewAccessApp());
}

class ExplorerWorkspacePreviewAccessApp extends StatelessWidget {
  const ExplorerWorkspacePreviewAccessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reshet ExplorerWorkspace Preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const ExplorerWorkspacePreviewAccessRoot(),
    );
  }
}

class ExplorerWorkspacePreviewAccessRoot extends StatelessWidget {
  const ExplorerWorkspacePreviewAccessRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ExplorerWorkspacePreviewInteractionHost.fromInput(
          input: explorerWorkspacePreviewAccessInput,
        ),
      ),
    );
  }
}
