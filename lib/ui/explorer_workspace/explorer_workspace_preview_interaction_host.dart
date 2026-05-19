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
  _PreviewPanelVisibilityState _panelVisibilityState =
      _PreviewPanelVisibilityState.graphAndDetail;

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
          showGraphPanel: _panelVisibilityState.showGraphPanel,
          showDetailPane: _panelVisibilityState.showDetailPane,
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
            panelVisibilityState: _panelVisibilityState,
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
    final nextState = _panelVisibilityState.toggleGraphPanel();
    if (nextState == _panelVisibilityState) {
      return;
    }

    setState(() {
      _panelVisibilityState = nextState;
    });
  }

  void _toggleDetailPane() {
    final nextState = _panelVisibilityState.toggleDetailPane();
    if (nextState == _panelVisibilityState) {
      return;
    }

    setState(() {
      _panelVisibilityState = nextState;
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
    _panelVisibilityState = _PreviewPanelVisibilityState.graphAndDetail;
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
  final _PreviewPanelVisibilityState panelVisibilityState;
  final ValueChanged<ExplorerWorkspaceLayoutPreset> onPresetSelected;
  final VoidCallback onToggleGraphPanel;
  final VoidCallback onToggleDetailPane;

  const _PreviewLayoutOrchestrationCard({
    required this.state,
    required this.panelVisibilityState,
    required this.onPresetSelected,
    required this.onToggleGraphPanel,
    required this.onToggleDetailPane,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320, maxHeight: 360),
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
                  'PreviewLayoutStatePolicy',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text('selected word: ${state.selectedWordId ?? 'none'}'),
                Text('graph center word: ${state.graphCenterWordId ?? 'none'}'),
                Text(
                  'detail target word: ${state.detailTargetWordId ?? 'none'}',
                ),
                Text('preset 상태: ${state.layoutPreset.name}'),
                Text(
                  'preset 의미: ${_presetDescription(state.layoutPreset)}',
                ),
                Text('origin 상태: ${state.origin.name}'),
                Text(
                  'visibility 상태: ${panelVisibilityState.semanticLabel}',
                ),
                Text(
                  'preset 역할: 권장 orchestration snapshot',
                ),
                Text(
                  'visibility 역할: 현재 local workspace state',
                ),
                const SizedBox(height: 4),
                Text('기본 진입 정책: balanced default'),
                Text('허용 상태: graph + detail / graph only / detail only'),
                Text('금지 상태: graph hidden + detail hidden'),
                Text('정책: 최소 1개 semantic panel visible 유지'),
                const SizedBox(height: 10),
                Text(
                  'preview-only orchestration boundary 안에서만 검증한다.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final preset in ExplorerWorkspaceLayoutPreset.values)
                      TextButton(
                        onPressed: () => onPresetSelected(preset),
                        child: Text(_presetButtonLabel(preset)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    TextButton(
                      onPressed: panelVisibilityState.canToggleGraphPanel
                          ? onToggleGraphPanel
                          : null,
                      child: Text(panelVisibilityState.graphToggleLabel),
                    ),
                    TextButton(
                      onPressed: panelVisibilityState.canToggleDetailPane
                          ? onToggleDetailPane
                          : null,
                      child: Text(panelVisibilityState.detailToggleLabel),
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

String _presetDescription(ExplorerWorkspaceLayoutPreset preset) {
  switch (preset) {
    case ExplorerWorkspaceLayoutPreset.balanced:
      return 'graph/detail 균형 상태';
    case ExplorerWorkspaceLayoutPreset.graphFocused:
      return 'graph 탐색 집중 상태';
    case ExplorerWorkspaceLayoutPreset.detailFocused:
      return 'detail 해석 집중 상태';
  }
}

String _presetButtonLabel(ExplorerWorkspaceLayoutPreset preset) {
  switch (preset) {
    case ExplorerWorkspaceLayoutPreset.balanced:
      return '프리셋: balanced';
    case ExplorerWorkspaceLayoutPreset.graphFocused:
      return '프리셋: graphFocused';
    case ExplorerWorkspaceLayoutPreset.detailFocused:
      return '프리셋: detailFocused';
  }
}

// Preset과 분리된 preview-local visibility state다.
// empty workspace를 타입 수준에서 허용하지 않도록 세 상태만 둔다.
enum _PreviewPanelVisibilityState {
  graphAndDetail,
  graphOnly,
  detailOnly;

  bool get showGraphPanel => this != _PreviewPanelVisibilityState.detailOnly;

  bool get showDetailPane => this != _PreviewPanelVisibilityState.graphOnly;

  bool get canToggleGraphPanel => this != _PreviewPanelVisibilityState.graphOnly;

  bool get canToggleDetailPane =>
      this != _PreviewPanelVisibilityState.detailOnly;

  String get semanticLabel {
    switch (this) {
      case _PreviewPanelVisibilityState.graphAndDetail:
        return 'graph + detail';
      case _PreviewPanelVisibilityState.graphOnly:
        return 'graph only';
      case _PreviewPanelVisibilityState.detailOnly:
        return 'detail only';
    }
  }

  String get graphToggleLabel {
    switch (this) {
      case _PreviewPanelVisibilityState.graphAndDetail:
      case _PreviewPanelVisibilityState.graphOnly:
        return '그래프 패널 숨기기';
      case _PreviewPanelVisibilityState.detailOnly:
        return '그래프 패널 표시';
    }
  }

  String get detailToggleLabel {
    switch (this) {
      case _PreviewPanelVisibilityState.graphAndDetail:
      case _PreviewPanelVisibilityState.detailOnly:
        return '상세 패널 숨기기';
      case _PreviewPanelVisibilityState.graphOnly:
        return '상세 패널 표시';
    }
  }

  _PreviewPanelVisibilityState toggleGraphPanel() {
    switch (this) {
      case _PreviewPanelVisibilityState.graphAndDetail:
        return _PreviewPanelVisibilityState.detailOnly;
      case _PreviewPanelVisibilityState.graphOnly:
        return _PreviewPanelVisibilityState.graphOnly;
      case _PreviewPanelVisibilityState.detailOnly:
        return _PreviewPanelVisibilityState.graphAndDetail;
    }
  }

  _PreviewPanelVisibilityState toggleDetailPane() {
    switch (this) {
      case _PreviewPanelVisibilityState.graphAndDetail:
        return _PreviewPanelVisibilityState.graphOnly;
      case _PreviewPanelVisibilityState.graphOnly:
        return _PreviewPanelVisibilityState.graphAndDetail;
      case _PreviewPanelVisibilityState.detailOnly:
        return _PreviewPanelVisibilityState.detailOnly;
    }
  }
}
