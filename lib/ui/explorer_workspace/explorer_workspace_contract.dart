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

class ExplorerWorkspacePreviewInput {
  final String? selectedWordId;
  final String? graphCenterWordId;
  final String? detailTargetWordId;
  final ExplorerWorkspaceLayoutPreset layoutPreset;
  final ExplorerWorkspaceTransitionOrigin origin;

  factory ExplorerWorkspacePreviewInput({
    String? selectedWordId,
    String? graphCenterWordId,
    String? detailTargetWordId,
    required ExplorerWorkspaceLayoutPreset layoutPreset,
    required ExplorerWorkspaceTransitionOrigin origin,
  }) {
    return ExplorerWorkspacePreviewInput._(
      selectedWordId: _optionalProjectionWordId(
        selectedWordId,
        'selectedWordId',
      ),
      graphCenterWordId: _optionalProjectionWordId(
        graphCenterWordId,
        'graphCenterWordId',
      ),
      detailTargetWordId: _optionalProjectionWordId(
        detailTargetWordId,
        'detailTargetWordId',
      ),
      layoutPreset: layoutPreset,
      origin: origin,
    );
  }

  factory ExplorerWorkspacePreviewInput.forExplorerEntry(String wordId) {
    final normalizedWordId = _requiredProjectionWordId(wordId, 'wordId');

    return ExplorerWorkspacePreviewInput._(
      selectedWordId: normalizedWordId,
      detailTargetWordId: normalizedWordId,
      layoutPreset: ExplorerWorkspaceLayoutPreset.balanced,
      origin: ExplorerWorkspaceTransitionOrigin.routeAlias,
    );
  }

  factory ExplorerWorkspacePreviewInput.forGraphRouteAlias(String wordId) {
    final normalizedWordId = _requiredProjectionWordId(wordId, 'wordId');

    return ExplorerWorkspacePreviewInput._(
      graphCenterWordId: normalizedWordId,
      layoutPreset: ExplorerWorkspaceLayoutPreset.graphFocused,
      origin: ExplorerWorkspaceTransitionOrigin.routeAlias,
    );
  }

  factory ExplorerWorkspacePreviewInput.forDetailRouteAlias(String wordId) {
    final normalizedWordId = _requiredProjectionWordId(wordId, 'wordId');

    return ExplorerWorkspacePreviewInput._(
      selectedWordId: normalizedWordId,
      detailTargetWordId: normalizedWordId,
      layoutPreset: ExplorerWorkspaceLayoutPreset.detailFocused,
      origin: ExplorerWorkspaceTransitionOrigin.routeAlias,
    );
  }

  const ExplorerWorkspacePreviewInput._({
    required this.layoutPreset,
    required this.origin,
    this.selectedWordId,
    this.graphCenterWordId,
    this.detailTargetWordId,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExplorerWorkspacePreviewInput &&
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

  factory ExplorerWorkspaceState.fromPreviewInput(
    ExplorerWorkspacePreviewInput input,
  ) {
    return ExplorerWorkspaceState(
      selectedWordId: input.selectedWordId,
      graphCenterWordId: input.graphCenterWordId,
      detailTargetWordId: input.detailTargetWordId,
      layoutPreset: input.layoutPreset,
      origin: input.origin,
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

String _requiredProjectionWordId(String wordId, String fieldName) {
  final normalizedWordId = wordId.trim();
  if (normalizedWordId.isEmpty) {
    throw ArgumentError.value(
      wordId,
      fieldName,
      'projection word id must not be empty.',
    );
  }

  return normalizedWordId;
}

String? _optionalProjectionWordId(String? wordId, String fieldName) {
  if (wordId == null) return null;

  return _requiredProjectionWordId(wordId, fieldName);
}
