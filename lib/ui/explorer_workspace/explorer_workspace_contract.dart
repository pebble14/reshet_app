enum ExplorerWorkspaceLayoutPreset { balanced, graphFocused, detailFocused }

enum ExplorerWorkspaceTransitionOrigin {
  initialEntry,
  routeAlias,
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

  factory ExplorerWorkspaceState.forExplorerEntry(String wordId) {
    final normalizedWordId = _requiredRouteAliasWordId(wordId);

    return ExplorerWorkspaceState(
      selectedWordId: normalizedWordId,
      detailTargetWordId: normalizedWordId,
      layoutPreset: ExplorerWorkspaceLayoutPreset.balanced,
      origin: ExplorerWorkspaceTransitionOrigin.routeAlias,
    );
  }

  factory ExplorerWorkspaceState.forGraphRouteAlias(String wordId) {
    final normalizedWordId = _requiredRouteAliasWordId(wordId);

    return ExplorerWorkspaceState(
      graphCenterWordId: normalizedWordId,
      layoutPreset: ExplorerWorkspaceLayoutPreset.graphFocused,
      origin: ExplorerWorkspaceTransitionOrigin.routeAlias,
    );
  }

  factory ExplorerWorkspaceState.forDetailRouteAlias(String wordId) {
    final normalizedWordId = _requiredRouteAliasWordId(wordId);

    return ExplorerWorkspaceState(
      selectedWordId: normalizedWordId,
      detailTargetWordId: normalizedWordId,
      layoutPreset: ExplorerWorkspaceLayoutPreset.detailFocused,
      origin: ExplorerWorkspaceTransitionOrigin.routeAlias,
    );
  }

  factory ExplorerWorkspaceState.fromSnapshot(
    ExplorerWorkspaceHistoryEntry entry,
  ) {
    return entry.snapshot;
  }

  static String _requiredRouteAliasWordId(String wordId) {
    final normalizedWordId = wordId.trim();
    if (normalizedWordId.isEmpty) {
      throw ArgumentError.value(
        wordId,
        'wordId',
        'route alias wordId는 비어 있을 수 없습니다.',
      );
    }

    return normalizedWordId;
  }

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
