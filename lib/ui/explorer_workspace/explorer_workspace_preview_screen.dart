import 'package:flutter/material.dart';

import 'explorer_workspace.dart';
import 'explorer_workspace_contract.dart';

class ExplorerWorkspacePreviewScreen extends StatelessWidget {
  final ExplorerWorkspaceState state;

  const ExplorerWorkspacePreviewScreen.fromState({
    super.key,
    required this.state,
  });

  factory ExplorerWorkspacePreviewScreen.forExplorerEntry({
    Key? key,
    required String initialWordId,
  }) {
    return ExplorerWorkspacePreviewScreen.fromState(
      key: key,
      state: ExplorerWorkspaceState.forExplorerEntry(initialWordId),
    );
  }

  factory ExplorerWorkspacePreviewScreen.forGraphRouteAlias({
    Key? key,
    required String centerWordId,
  }) {
    return ExplorerWorkspacePreviewScreen.fromState(
      key: key,
      state: ExplorerWorkspaceState.forGraphRouteAlias(centerWordId),
    );
  }

  factory ExplorerWorkspacePreviewScreen.forDetailRouteAlias({
    Key? key,
    required String wordId,
  }) {
    return ExplorerWorkspacePreviewScreen.fromState(
      key: key,
      state: ExplorerWorkspaceState.forDetailRouteAlias(wordId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: ExplorerWorkspace(state: state)),
    );
  }
}
