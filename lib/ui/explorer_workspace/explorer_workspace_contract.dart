enum ExplorerWorkspaceLayoutPreset { balanced, graphFocused, detailFocused }

enum ExplorerWorkspaceTransitionOrigin {
  initialEntry,
  strongRail,
  globalSearch,
  graphNode,
  detailPane,
  addWordFlow,
  editReturn,
  snapshotRestore,
}

class ExplorerWorkspaceState {
  final String? selectedWordId;
  final String? graphCenterWordId;
  final String? detailTargetWordId;
  final ExplorerWorkspaceLayoutPreset layoutPreset;
  final ExplorerWorkspaceTransitionOrigin origin;

  const ExplorerWorkspaceState({
    required this.layoutPreset,
    required this.origin,
    this.selectedWordId,
    this.graphCenterWordId,
    this.detailTargetWordId,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExplorerWorkspaceState &&
            selectedWordId == other.selectedWordId &&
            graphCenterWordId == other.graphCenterWordId &&
            detailTargetWordId == other.detailTargetWordId &&
            layoutPreset == other.layoutPreset &&
            origin == other.origin;
  }

  @override
  int get hashCode => Object.hash(
    selectedWordId,
    graphCenterWordId,
    detailTargetWordId,
    layoutPreset,
    origin,
  );
}

class ExplorerWorkspaceHistoryEntry {
  final ExplorerWorkspaceState snapshot;

  const ExplorerWorkspaceHistoryEntry({required this.snapshot});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExplorerWorkspaceHistoryEntry && snapshot == other.snapshot;
  }

  @override
  int get hashCode => snapshot.hashCode;
}
