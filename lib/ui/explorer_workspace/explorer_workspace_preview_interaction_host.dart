import 'package:flutter/material.dart';

import 'explorer_workspace.dart';
import 'explorer_workspace_contract.dart';

class ExplorerWorkspacePreviewInteractionHost extends StatefulWidget {
  final ExplorerWorkspacePreviewInput input;

  const ExplorerWorkspacePreviewInteractionHost.fromInput({
    super.key,
    required this.input,
  });

  @override
  State<ExplorerWorkspacePreviewInteractionHost> createState() =>
      _ExplorerWorkspacePreviewInteractionHostState();
}

class _ExplorerWorkspacePreviewInteractionHostState
    extends State<ExplorerWorkspacePreviewInteractionHost> {
  late ExplorerWorkspaceState _state;
  late List<String> _availableWordIds;

  @override
  void initState() {
    super.initState();
    _state = ExplorerWorkspaceState.fromPreviewInput(widget.input);
    _availableWordIds = _collectAvailableWordIds(widget.input);
  }

  @override
  void didUpdateWidget(
    covariant ExplorerWorkspacePreviewInteractionHost oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.input == widget.input) {
      return;
    }

    _state = ExplorerWorkspaceState.fromPreviewInput(widget.input);
    _availableWordIds = _collectAvailableWordIds(widget.input);
  }

  @override
  Widget build(BuildContext context) {
    return ExplorerWorkspace(
      state: _state,
      graphPanelOverride: _PreviewGraphPanel(
        state: _state,
        availableWordIds: _availableWordIds,
        onGraphTargetSelected: _setPreviewGraphTarget,
      ),
      detailPaneOverride: _PreviewDetailPane(
        state: _state,
        availableWordIds: _availableWordIds,
        onDetailTargetSelected: _setPreviewDetailTarget,
      ),
    );
  }

  void _setPreviewGraphTarget(String wordId) {
    setState(() {
      _state = ExplorerWorkspaceState(
        selectedWordId: _state.selectedWordId,
        graphCenterWordId: wordId,
        detailTargetWordId: _state.detailTargetWordId,
        layoutPreset: ExplorerWorkspaceLayoutPreset.graphFocused,
        origin: ExplorerWorkspaceTransitionOrigin.graphNode,
      );
    });
  }

  void _setPreviewDetailTarget(String wordId) {
    setState(() {
      _state = ExplorerWorkspaceState(
        selectedWordId: wordId,
        graphCenterWordId: _state.graphCenterWordId,
        detailTargetWordId: wordId,
        layoutPreset: ExplorerWorkspaceLayoutPreset.detailFocused,
        origin: ExplorerWorkspaceTransitionOrigin.detailPane,
      );
    });
  }

  List<String> _collectAvailableWordIds(ExplorerWorkspacePreviewInput input) {
    final uniqueWordIds = <String>{};

    for (final wordId in [
      input.selectedWordId,
      input.graphCenterWordId,
      input.detailTargetWordId,
    ]) {
      if (wordId == null) {
        continue;
      }
      uniqueWordIds.add(wordId);
    }

    return List<String>.unmodifiable(uniqueWordIds);
  }
}

class _PreviewGraphPanel extends StatelessWidget {
  final ExplorerWorkspaceState state;
  final List<String> availableWordIds;
  final ValueChanged<String> onGraphTargetSelected;

  const _PreviewGraphPanel({
    required this.state,
    required this.availableWordIds,
    required this.onGraphTargetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _PreviewInteractionPanel(
      title: 'PreviewGraphPanel',
      currentLabel:
          'preview graph center: ${state.graphCenterWordId ?? 'none'}',
      availableWordIds: availableWordIds,
      actionPrefix: 'GraphFocus',
      onSelected: onGraphTargetSelected,
    );
  }
}

class _PreviewDetailPane extends StatelessWidget {
  final ExplorerWorkspaceState state;
  final List<String> availableWordIds;
  final ValueChanged<String> onDetailTargetSelected;

  const _PreviewDetailPane({
    required this.state,
    required this.availableWordIds,
    required this.onDetailTargetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _PreviewInteractionPanel(
      title: 'PreviewDetailPane',
      currentLabel:
          'preview detail target: ${state.detailTargetWordId ?? 'none'}',
      availableWordIds: availableWordIds,
      actionPrefix: 'DetailTarget',
      onSelected: onDetailTargetSelected,
    );
  }
}

class _PreviewInteractionPanel extends StatelessWidget {
  final String title;
  final String currentLabel;
  final List<String> availableWordIds;
  final String actionPrefix;
  final ValueChanged<String> onSelected;

  const _PreviewInteractionPanel({
    required this.title,
    required this.currentLabel,
    required this.availableWordIds,
    required this.actionPrefix,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  currentLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                for (final wordId in availableWordIds) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => onSelected(wordId),
                    child: Text(
                      '$actionPrefix:$wordId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
