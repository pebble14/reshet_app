import 'package:flutter/material.dart';

import 'explorer_workspace_contract.dart';

class ExplorerWorkspace extends StatelessWidget {
  final ExplorerWorkspaceState state;
  final ValueChanged<String>? onStrongSelected;
  final ValueChanged<String>? onSearchResultSelected;
  final ValueChanged<String>? onGraphNodeSelected;
  final ValueChanged<String>? onGraphCenterRequested;
  final ValueChanged<String>? onDetailRelationSelected;
  final VoidCallback? onAddWordRequested;
  final Widget? graphPanelOverride;
  final Widget? detailPaneOverride;

  const ExplorerWorkspace({
    super.key,
    required this.state,
    this.onStrongSelected,
    this.onSearchResultSelected,
    this.onGraphNodeSelected,
    this.onGraphCenterRequested,
    this.onDetailRelationSelected,
    this.onAddWordRequested,
    this.graphPanelOverride,
    this.detailPaneOverride,
  });

  @override
  Widget build(BuildContext context) {
    final layout = _ExplorerWorkspaceLayout.fromPreset(state.layoutPreset);

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: layout.railWidth,
                child: const _ExplorerWorkspacePlaceholder(
                  title: 'StrongRail',
                  description: 'semantic navigation spine',
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: layout.searchHeight,
                      child: const _ExplorerWorkspacePlaceholder(
                        title: 'GlobalSearch',
                        description: 'global semantic entry',
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: layout.graphFlex,
                            child:
                                graphPanelOverride ??
                                _ExplorerWorkspacePlaceholder(
                                  title: 'GraphPanel',
                                  description: _graphDescription(state),
                                  isEmphasized:
                                      state.layoutPreset ==
                                      ExplorerWorkspaceLayoutPreset
                                          .graphFocused,
                                ),
                          ),
                          Expanded(
                            flex: layout.detailFlex,
                            child:
                                detailPaneOverride ??
                                _ExplorerWorkspacePlaceholder(
                                  title: 'DetailPane',
                                  description: _detailDescription(state),
                                  isEmphasized:
                                      state.layoutPreset ==
                                      ExplorerWorkspaceLayoutPreset
                                          .detailFocused,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: _ExplorerWorkspaceActionPlaceholder(
              isEmphasized:
                  state.layoutPreset == ExplorerWorkspaceLayoutPreset.balanced,
              onPressed: onAddWordRequested,
            ),
          ),
        ],
      ),
    );
  }

  String _graphDescription(ExplorerWorkspaceState state) {
    final centerWordId = state.graphCenterWordId ?? 'none';
    return 'center: $centerWordId';
  }

  String _detailDescription(ExplorerWorkspaceState state) {
    final detailTargetWordId = state.detailTargetWordId ?? 'none';
    return 'target: $detailTargetWordId';
  }
}

class _ExplorerWorkspaceLayout {
  final double railWidth;
  final double searchHeight;
  final int graphFlex;
  final int detailFlex;

  const _ExplorerWorkspaceLayout({
    required this.railWidth,
    required this.searchHeight,
    required this.graphFlex,
    required this.detailFlex,
  });

  factory _ExplorerWorkspaceLayout.fromPreset(
    ExplorerWorkspaceLayoutPreset preset,
  ) {
    switch (preset) {
      case ExplorerWorkspaceLayoutPreset.balanced:
        return const _ExplorerWorkspaceLayout(
          railWidth: 96,
          searchHeight: 72,
          graphFlex: 3,
          detailFlex: 2,
        );
      case ExplorerWorkspaceLayoutPreset.graphFocused:
        return const _ExplorerWorkspaceLayout(
          railWidth: 80,
          searchHeight: 64,
          graphFlex: 5,
          detailFlex: 2,
        );
      case ExplorerWorkspaceLayoutPreset.detailFocused:
        return const _ExplorerWorkspaceLayout(
          railWidth: 80,
          searchHeight: 64,
          graphFlex: 2,
          detailFlex: 5,
        );
    }
  }
}

class _ExplorerWorkspacePlaceholder extends StatelessWidget {
  final String title;
  final String description;
  final bool isEmphasized;

  const _ExplorerWorkspacePlaceholder({
    required this.title,
    required this.description,
    this.isEmphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isEmphasized
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = isEmphasized
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: foregroundColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplorerWorkspaceActionPlaceholder extends StatelessWidget {
  final bool isEmphasized;
  final VoidCallback? onPressed;

  const _ExplorerWorkspaceActionPlaceholder({
    required this.isEmphasized,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isEmphasized
        ? colorScheme.primary
        : colorScheme.secondaryContainer;
    final foregroundColor = isEmphasized
        ? colorScheme.onPrimary
        : colorScheme.onSecondaryContainer;

    return GestureDetector(
      onTap: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Text(
            'AddWordFixedAction',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
