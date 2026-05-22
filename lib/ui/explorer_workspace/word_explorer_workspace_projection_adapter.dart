import 'explorer_workspace_contract.dart';

class WordExplorerWorkspaceProjectionAdapter {
  const WordExplorerWorkspaceProjectionAdapter._();

  static ExplorerWorkspaceState project({
    String? selectedWordId,
    String? graphCenterWordId,
    String? detailTargetWordId,
    required ExplorerWorkspaceLayoutPreset layoutPreset,
    required ExplorerWorkspaceTransitionOrigin origin,
  }) {
    return ExplorerWorkspaceState(
      selectedWordId: _normalizeOptionalProjectionWordId(
        selectedWordId,
        'selectedWordId',
      ),
      graphCenterWordId: _normalizeOptionalProjectionWordId(
        graphCenterWordId,
        'graphCenterWordId',
      ),
      detailTargetWordId: _normalizeOptionalProjectionWordId(
        detailTargetWordId,
        'detailTargetWordId',
      ),
      layoutPreset: layoutPreset,
      origin: origin,
    );
  }

  static String? _normalizeOptionalProjectionWordId(
    String? wordId,
    String fieldName,
  ) {
    if (wordId == null) {
      return null;
    }

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
}
