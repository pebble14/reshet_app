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
  bool _showGraphPanel = true;
  bool _showDetailPane = true;

  @override
  void initState() {
    super.initState();
    _syncPreviewInput(widget.input);
  }

  @override
  void didUpdateWidget(
    covariant ExplorerWorkspacePreviewInteractionHost oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.input == widget.input) {
      return;
    }

    _syncPreviewInput(widget.input);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ExplorerWorkspace(
          state: _state,
          showGraphPanel: _showGraphPanel,
          showDetailPane: _showDetailPane,
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
        ),
        Positioned(
          top: 16,
          right: 16,
          child: _PreviewLayoutOrchestrationCard(
            state: _state,
            showGraphPanel: _showGraphPanel,
            showDetailPane: _showDetailPane,
            onPresetSelected: _setLayoutPreset,
            onToggleGraphPanel: _toggleGraphPanel,
            onToggleDetailPane: _toggleDetailPane,
          ),
        ),
      ],
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

  void _setLayoutPreset(ExplorerWorkspaceLayoutPreset preset) {
    if (_state.layoutPreset == preset) {
      return;
    }

    setState(() {
      _state = ExplorerWorkspaceState(
        selectedWordId: _state.selectedWordId,
        graphCenterWordId: _state.graphCenterWordId,
        detailTargetWordId: _state.detailTargetWordId,
        layoutPreset: preset,
        origin: _state.origin,
      );
    });
  }

  void _toggleGraphPanel() {
    if (_showGraphPanel && !_showDetailPane) {
      return;
    }

    setState(() {
      _showGraphPanel = !_showGraphPanel;
    });
  }

  void _toggleDetailPane() {
    if (_showDetailPane && !_showGraphPanel) {
      return;
    }

    setState(() {
      _showDetailPane = !_showDetailPane;
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

  void _syncPreviewInput(ExplorerWorkspacePreviewInput input) {
    _state = ExplorerWorkspaceState.fromPreviewInput(input);
    _availableWordIds = _collectAvailableWordIds(input);
    _showGraphPanel = true;
    _showDetailPane = true;
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

class _PreviewLayoutOrchestrationCard extends StatelessWidget {
  final ExplorerWorkspaceState state;
  final bool showGraphPanel;
  final bool showDetailPane;
  final ValueChanged<ExplorerWorkspaceLayoutPreset> onPresetSelected;
  final VoidCallback onToggleGraphPanel;
  final VoidCallback onToggleDetailPane;

  const _PreviewLayoutOrchestrationCard({
    required this.state,
    required this.showGraphPanel,
    required this.showDetailPane,
    required this.onPresetSelected,
    required this.onToggleGraphPanel,
    required this.onToggleDetailPane,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260, maxHeight: 280),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PreviewLayoutOrchestration',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text('selected word: ${state.selectedWordId ?? 'none'}'),
                Text('graph center word: ${state.graphCenterWordId ?? 'none'}'),
                Text(
                  'detail target word: ${state.detailTargetWordId ?? 'none'}',
                ),
                Text('active preset: ${state.layoutPreset.name}'),
                Text('active origin: ${state.origin.name}'),
                Text(
                  'graph panel visibility: ${showGraphPanel ? 'visible' : 'hidden'}',
                ),
                Text(
                  'detail panel visibility: ${showDetailPane ? 'visible' : 'hidden'}',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final preset in ExplorerWorkspaceLayoutPreset.values)
                      TextButton(
                        onPressed: () => onPresetSelected(preset),
                        child: Text('UsePreset:${preset.name}'),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    TextButton(
                      onPressed: onToggleGraphPanel,
                      child: const Text('ToggleGraphPanel'),
                    ),
                    TextButton(
                      onPressed: onToggleDetailPane,
                      child: const Text('ToggleDetailPane'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
