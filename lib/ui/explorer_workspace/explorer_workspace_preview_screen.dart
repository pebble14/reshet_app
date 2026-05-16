import 'package:flutter/material.dart';

import 'explorer_workspace.dart';
import 'explorer_workspace_contract.dart';

class ExplorerWorkspacePreviewScreen extends StatelessWidget {
  final ExplorerWorkspacePreviewInput input;

  const ExplorerWorkspacePreviewScreen.fromInput({
    super.key,
    required this.input,
  });

  factory ExplorerWorkspacePreviewScreen.forExplorerEntry({
    Key? key,
    required String initialWordId,
  }) {
    return ExplorerWorkspacePreviewScreen.fromInput(
      key: key,
      input: ExplorerWorkspacePreviewInput.forExplorerEntry(initialWordId),
    );
  }

  factory ExplorerWorkspacePreviewScreen.forGraphRouteAlias({
    Key? key,
    required String centerWordId,
  }) {
    return ExplorerWorkspacePreviewScreen.fromInput(
      key: key,
      input: ExplorerWorkspacePreviewInput.forGraphRouteAlias(centerWordId),
    );
  }

  factory ExplorerWorkspacePreviewScreen.forDetailRouteAlias({
    Key? key,
    required String wordId,
  }) {
    return ExplorerWorkspacePreviewScreen.fromInput(
      key: key,
      input: ExplorerWorkspacePreviewInput.forDetailRouteAlias(wordId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ExplorerWorkspaceState.fromPreviewInput(input);

    return Scaffold(
      body: SafeArea(child: ExplorerWorkspace(state: state)),
    );
  }
}
