sealed class WordDetailRouteResult {
  const WordDetailRouteResult();
}

final class WordMutationImpact {
  final Set<String> changedWordIds;
  final Set<String> deletedWordIds;
  final Set<String> graphAffectedWordIds;

  WordMutationImpact({
    Iterable<String> changedWordIds = const [],
    Iterable<String> deletedWordIds = const [],
    Iterable<String> graphAffectedWordIds = const [],
  }) : changedWordIds = Set<String>.unmodifiable(
         _normalizedWordIds(changedWordIds),
       ),
       deletedWordIds = Set<String>.unmodifiable(
         _normalizedWordIds(deletedWordIds),
       ),
       graphAffectedWordIds = Set<String>.unmodifiable(
         _normalizedWordIds(graphAffectedWordIds),
       );

  bool get isEmpty =>
      changedWordIds.isEmpty &&
      deletedWordIds.isEmpty &&
      graphAffectedWordIds.isEmpty;

  WordMutationImpact merge(WordMutationImpact other) {
    return WordMutationImpact(
      changedWordIds: {...changedWordIds, ...other.changedWordIds},
      deletedWordIds: {...deletedWordIds, ...other.deletedWordIds},
      graphAffectedWordIds: {
        ...graphAffectedWordIds,
        ...other.graphAffectedWordIds,
      },
    );
  }

  bool affectsGraphWordIds(Iterable<String> activeWordIds) {
    final activeIds = _normalizedWordIds(activeWordIds);
    return changedWordIds.any(activeIds.contains) ||
        deletedWordIds.any(activeIds.contains) ||
        graphAffectedWordIds.any(activeIds.contains);
  }

  static Set<String> _normalizedWordIds(Iterable<String> wordIds) {
    return wordIds.map((wordId) => wordId.trim()).where((wordId) {
      return wordId.isNotEmpty;
    }).toSet();
  }
}

final class WordMutationImpactCollector {
  final Set<String> _changedWordIds = <String>{};
  final Set<String> _deletedWordIds = <String>{};
  final Set<String> _graphAffectedWordIds = <String>{};
  final List<WordMutationImpact> _events = <WordMutationImpact>[];

  int get checkpoint => _events.length;

  WordMutationImpact get snapshot => WordMutationImpact(
    changedWordIds: _changedWordIds,
    deletedWordIds: _deletedWordIds,
    graphAffectedWordIds: _graphAffectedWordIds,
  );

  void recordChangedWord(String wordId) {
    final normalizedWordId = _normalizeWordId(wordId);
    if (normalizedWordId == null) {
      return;
    }
    _changedWordIds.add(normalizedWordId);
    _events.add(WordMutationImpact(changedWordIds: [normalizedWordId]));
  }

  void recordDeletedWord(
    String wordId, {
    Iterable<String> graphAffectedWordIds = const [],
  }) {
    final normalizedWordId = _normalizeWordId(wordId);
    if (normalizedWordId == null) {
      return;
    }
    final affectedWordIds = <String>{normalizedWordId};
    for (final affectedWordId in graphAffectedWordIds) {
      final normalizedAffectedWordId = _normalizeWordId(affectedWordId);
      if (normalizedAffectedWordId != null) {
        affectedWordIds.add(normalizedAffectedWordId);
      }
    }
    _deletedWordIds.add(normalizedWordId);
    _graphAffectedWordIds.addAll(affectedWordIds);
    _events.add(
      WordMutationImpact(
        deletedWordIds: [normalizedWordId],
        graphAffectedWordIds: affectedWordIds,
      ),
    );
  }

  void recordGraphAffectedWords(Iterable<String> wordIds) {
    final affectedWordIds = <String>{};
    for (final wordId in wordIds) {
      final normalizedWordId = _normalizeWordId(wordId);
      if (normalizedWordId != null) {
        affectedWordIds.add(normalizedWordId);
      }
    }
    if (affectedWordIds.isEmpty) {
      return;
    }
    _graphAffectedWordIds.addAll(affectedWordIds);
    _events.add(WordMutationImpact(graphAffectedWordIds: affectedWordIds));
  }

  WordMutationImpact impactSince(int checkpoint) {
    final safeCheckpoint = checkpoint.clamp(0, _events.length);
    var impact = WordMutationImpact();
    for (final event in _events.skip(safeCheckpoint)) {
      impact = impact.merge(event);
    }
    return impact;
  }

  String? _normalizeWordId(String wordId) {
    final normalizedWordId = wordId.trim();
    return normalizedWordId.isEmpty ? null : normalizedWordId;
  }
}

enum DetailMutationOriginAction { none, refresh, close }

DetailMutationOriginAction resolveDetailMutationOriginAction({
  required WordMutationImpact impact,
  required String originWordId,
}) {
  final normalizedOriginWordId = originWordId.trim();
  if (normalizedOriginWordId.isEmpty) {
    return DetailMutationOriginAction.none;
  }
  if (impact.deletedWordIds.contains(normalizedOriginWordId)) {
    return DetailMutationOriginAction.close;
  }
  if (impact.changedWordIds.contains(normalizedOriginWordId)) {
    return DetailMutationOriginAction.refresh;
  }
  return DetailMutationOriginAction.none;
}

final class GraphMutationOriginDecision {
  final bool shouldClose;
  final bool shouldClearSelection;
  final bool shouldRefresh;

  const GraphMutationOriginDecision({
    required this.shouldClose,
    required this.shouldClearSelection,
    required this.shouldRefresh,
  });
}

GraphMutationOriginDecision resolveGraphMutationOriginDecision({
  required WordMutationImpact impact,
  required String centerWordId,
  required String? selectedWordId,
  required Iterable<String> activeWordIds,
}) {
  final normalizedCenterWordId = centerWordId.trim();
  final normalizedSelectedWordId = (selectedWordId ?? '').trim();
  final shouldClose =
      normalizedCenterWordId.isNotEmpty &&
      impact.deletedWordIds.contains(normalizedCenterWordId);
  final shouldClearSelection =
      normalizedSelectedWordId.isNotEmpty &&
      impact.deletedWordIds.contains(normalizedSelectedWordId);
  return GraphMutationOriginDecision(
    shouldClose: shouldClose,
    shouldClearSelection: shouldClearSelection,
    shouldRefresh: !shouldClose && impact.affectsGraphWordIds(activeWordIds),
  );
}

WordMutationImpact mutationImpactSince({
  required WordMutationImpactCollector collector,
  required int checkpoint,
  WordDetailRouteResult? routeResult,
}) {
  final collectedImpact = collector.impactSince(checkpoint);
  if (routeResult case WordDetailDeletedResult(:final wordId)) {
    return collectedImpact.merge(
      WordMutationImpact(
        deletedWordIds: [wordId],
        graphAffectedWordIds: [wordId],
      ),
    );
  }
  return collectedImpact;
}

final class WordDetailDeletedResult extends WordDetailRouteResult {
  final String wordId;

  const WordDetailDeletedResult({required this.wordId});
}

final class WordDetailEditRequestedResult extends WordDetailRouteResult {
  final String wordId;

  const WordDetailEditRequestedResult({required this.wordId});
}

final class WordDetailGraphRequestedResult extends WordDetailRouteResult {
  final String wordId;

  const WordDetailGraphRequestedResult({required this.wordId});
}
