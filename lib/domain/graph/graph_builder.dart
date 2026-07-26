import 'dart:math';

import '../../data/models/word.dart';
import '../../data/repositories/word_repository.dart';
import 'graph_build_options.dart';
import 'graph_edge.dart';
import 'graph_node.dart';
import 'graph_view_data.dart';
import 'graph_visible_word.dart';
import 'graph_word_label_display_item.dart';

typedef GraphVisibleDataBuildResult = ({
  GraphViewData viewData,
  List<Word> connectedWords,
  List<GraphWordLabelDisplayItem> wordLabels,
  List<WordRelationEdgeInfo> relationEdges,
});

enum _BranchPriorityBucket {
  coreMust,
  protectedMust,
  preferred,
  semiPreferred,
  fallback,
}

typedef _BranchPriorityCounts = ({
  int coreMustCount,
  int protectedMustCount,
  int preferredCount,
  int semiPreferredCount,
});

/// graph_builder.dart
///
/// Repository가 조회한 단어/관계 데이터를 그래프 도메인 모델로 조립한다.
/// 이번 단계에서는 1-hop 그래프와 기본 필터링만 구현한다.
class GraphBuilder {
  static const int _defaultDepthTwoSoftLimitPerSource = 6;
  static const String _morePlaceholderNodePrefix = '__graph_more__';
  static const Set<String> _preferredCategoryCodes = {
    'translation',
    'transliteration',
  };
  static const Set<String> _preferredRelationTypes = {
    'translation',
    'literal_translation',
    'semantic_translation',
    'interpretive_translation',
    'loan_translation',
    'transliteration',
    'direct_transliteration',
    'conventional_transliteration',
    'approx_transliteration',
    'inflected',
    'variant',
  };
  static const Set<String> _semiPreferredRelationTypes = {
    'derived',
    'derived_from',
  };

  const GraphBuilder();

  /// Dormant compatibility wrapper retained for older callers that already
  /// provide repository-shaped visible graph data. Production graph assembly
  /// uses [buildMergedVisibleGraphData].
  @Deprecated(
    'Dormant compatibility path. Use buildMergedVisibleGraphData instead.',
  )
  GraphViewData buildFromVisibleGraphData({
    required GraphBuildOptions options,
    required Word centerWord,
    required Iterable<GraphVisibleWord> connectedWords,
    Iterable<GraphWordLabelDisplayItem> wordLabels =
        const <GraphWordLabelDisplayItem>[],
    required Iterable<WordRelationEdgeInfo> relationEdges,
    Iterable<WordRelationEdgeInfo> supplementalRelationEdges =
        const <WordRelationEdgeInfo>[],
    int? centerDepthOneSoftLimit,
    bool fullyRevealCenterDepthOne = false,
  }) {
    return buildMergedVisibleGraphData(
      options: options,
      centerWord: centerWord,
      baseWords: connectedWords,
      wordLabels: wordLabels,
      baseRelationEdges: relationEdges,
      supplementalRelationEdges: supplementalRelationEdges,
      centerDepthOneSoftLimit: centerDepthOneSoftLimit,
      fullyRevealCenterDepthOne: fullyRevealCenterDepthOne,
    ).viewData;
  }

  GraphVisibleDataBuildResult buildMergedVisibleGraphData({
    required GraphBuildOptions options,
    required Word centerWord,
    required Iterable<GraphVisibleWord> baseWords,
    Iterable<GraphWordLabelDisplayItem> wordLabels =
        const <GraphWordLabelDisplayItem>[],
    required Iterable<WordRelationEdgeInfo> baseRelationEdges,
    Iterable<WordRelationEdgeInfo> supplementalRelationEdges =
        const <WordRelationEdgeInfo>[],
    Map<String, VisibleWordGraphData> expansionDataBySourceId =
        const <String, VisibleWordGraphData>{},
    Set<String> fullyRevealedExpansionSourceIds = const <String>{},
    int? centerDepthOneSoftLimit,
    bool fullyRevealCenterDepthOne = false,
  }) {
    final visibleWordsById = <String, GraphVisibleWord>{};
    final depthByWordId = <String, int>{centerWord.id: 0};
    final expansionSourceIdByWordId = <String, String?>{};
    final relationCountsByWordId = <String, int>{};
    final mergedRelationEdges = <WordRelationEdgeInfo>[];
    final placeholderNodes = <GraphNode>[];
    final syntheticEdges = <GraphEdge>[];
    final edgeKeys = <String>{};
    final labelDisplaysByWordId = <String, GraphWordLabelDisplayItem>{};
    final allBaseWordIds = <String>{};
    final visibleBaseWordIds = <String>{};
    final normalizedRevealedSourceIds = fullyRevealedExpansionSourceIds
        .map((sourceWordId) => sourceWordId.trim())
        .where((sourceWordId) => sourceWordId.isNotEmpty)
        .toSet();
    final baseRelationEdgeList = baseRelationEdges.toList(growable: false);

    void registerLabel(GraphWordLabelDisplayItem labelDisplay) {
      final wordId = labelDisplay.wordId.trim();
      if (wordId.isEmpty) return;
      labelDisplaysByWordId[wordId] = labelDisplay;
    }

    void registerWord(
      GraphVisibleWord word, {
      required int depth,
      String? expansionSourceId,
    }) {
      final wordId = word.wordId;
      visibleWordsById[wordId] ??= word;
      final nextDepth = depth.clamp(0, options.maxDepth).toInt();
      final existingDepth = depthByWordId[wordId];
      if (existingDepth == null || nextDepth < existingDepth) {
        depthByWordId[wordId] = nextDepth;
      }

      if (wordId == centerWord.id || nextDepth <= 1) {
        expansionSourceIdByWordId[wordId] = null;
        return;
      }

      expansionSourceIdByWordId[wordId] ??= expansionSourceId;
    }

    void registerEdgeInfo(WordRelationEdgeInfo edgeInfo) {
      final edgeKey = _edgeDedupeKeyForRelationInfo(edgeInfo);
      if (!edgeKeys.add(edgeKey)) {
        return;
      }

      mergedRelationEdges.add(edgeInfo);
      relationCountsByWordId.update(
        edgeInfo.wordId1,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      relationCountsByWordId.update(
        edgeInfo.wordId2,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    for (final labelDisplay in wordLabels) {
      registerLabel(labelDisplay);
    }

    for (final edgeInfo in baseRelationEdgeList) {
      registerEdgeInfo(edgeInfo);
    }

    final prioritizedBaseWords = _prioritizeCenterDepthOneWords(
      centerWordId: centerWord.id,
      baseWords: baseWords,
      relationEdges: baseRelationEdgeList,
      relationCountsByWordId: relationCountsByWordId,
      labelDisplaysByWordId: labelDisplaysByWordId,
    );
    final normalizedCenterDepthOneSoftLimit = centerDepthOneSoftLimit == null
        ? null
        : max(0, centerDepthOneSoftLimit);
    final effectiveCenterDepthOneSoftLimit =
        normalizedCenterDepthOneSoftLimit ?? 0;
    final shouldLimitCenterDepthOne =
        !fullyRevealCenterDepthOne &&
        normalizedCenterDepthOneSoftLimit != null &&
        prioritizedBaseWords.length > normalizedCenterDepthOneSoftLimit;
    final visibleBaseWords = shouldLimitCenterDepthOne
        ? prioritizedBaseWords
              .take(effectiveCenterDepthOneSoftLimit)
              .toList(growable: false)
        : prioritizedBaseWords;
    final hiddenCenterDepthOneWords = shouldLimitCenterDepthOne
        ? prioritizedBaseWords
              .skip(effectiveCenterDepthOneSoftLimit)
              .toList(growable: false)
        : const <GraphVisibleWord>[];
    final hiddenCenterDepthOneWordIds = hiddenCenterDepthOneWords
        .map((word) => word.wordId)
        .toSet();

    for (final word in prioritizedBaseWords) {
      allBaseWordIds.add(word.wordId);
    }
    for (final word in visibleBaseWords) {
      visibleBaseWordIds.add(word.wordId);
      registerWord(word, depth: 1);
    }

    final hiddenCenterDepthOneCount = hiddenCenterDepthOneWords.length;
    if (hiddenCenterDepthOneCount > 0) {
      final placeholderNode = _buildCenterDepthOnePlaceholderMoreNode(
        centerWordId: centerWord.id,
        hiddenCount: hiddenCenterDepthOneCount,
      );
      placeholderNodes.add(placeholderNode);
      syntheticEdges.add(
        _buildPlaceholderEdge(
          sourceWordId: centerWord.id,
          placeholderNodeId: placeholderNode.id,
        ),
      );
    }

    for (final entry in expansionDataBySourceId.entries) {
      final sourceWordId = entry.key.trim();
      final sourceDepth = depthByWordId[sourceWordId];
      if (sourceWordId.isEmpty || sourceDepth == null || sourceDepth != 1) {
        continue;
      }

      for (final labelDisplay in entry.value.wordLabels) {
        registerLabel(labelDisplay);
      }

      final ownedDepthTwoWords = <GraphVisibleWord>[];
      final visibleNeighborIds = <String>{
        centerWord.id,
        sourceWordId,
        ...visibleBaseWordIds,
      };

      for (final word in entry.value.connectedWords) {
        final wordId = word.wordId;
        final depth = wordId == centerWord.id
            ? 0
            : (allBaseWordIds.contains(wordId) ? 1 : 2);
        if (depth <= 1) {
          if (depth == 1 && hiddenCenterDepthOneWordIds.contains(wordId)) {
            continue;
          }
          registerWord(word, depth: depth, expansionSourceId: null);
          visibleNeighborIds.add(wordId);
          continue;
        }

        final existingDepth = depthByWordId[wordId];
        if (existingDepth != null ||
            expansionSourceIdByWordId[wordId] != null) {
          continue;
        }

        expansionSourceIdByWordId[wordId] = sourceWordId;
        ownedDepthTwoWords.add(word);
      }

      final revealAll = normalizedRevealedSourceIds.contains(sourceWordId);
      final prioritizedDepthTwoWords = _prioritizeOwnedDepthTwoWords(
        sourceWordId: sourceWordId,
        ownedDepthTwoWords: ownedDepthTwoWords,
        relationEdges: entry.value.relationEdges,
        visibleNeighborIds: visibleNeighborIds,
        labelDisplaysByWordId: labelDisplaysByWordId,
      );
      final visibleDepthTwoCount = revealAll
          ? prioritizedDepthTwoWords.length
          : min(
              prioritizedDepthTwoWords.length,
              _defaultDepthTwoSoftLimitPerSource,
            );
      final visibleDepthTwoWords = prioritizedDepthTwoWords
          .take(visibleDepthTwoCount)
          .toList(growable: false);

      for (final word in visibleDepthTwoWords) {
        registerWord(word, depth: 2, expansionSourceId: sourceWordId);
        visibleNeighborIds.add(word.wordId);
      }

      final hiddenCount = ownedDepthTwoWords.length - visibleDepthTwoCount;
      if (hiddenCount > 0) {
        final placeholderNode = _buildPlaceholderMoreNode(
          sourceWordId: sourceWordId,
          hiddenCount: hiddenCount,
        );
        placeholderNodes.add(placeholderNode);
        syntheticEdges.add(
          _buildPlaceholderEdge(
            sourceWordId: sourceWordId,
            placeholderNodeId: placeholderNode.id,
          ),
        );
      }

      for (final edgeInfo in entry.value.relationEdges) {
        if (!visibleNeighborIds.contains(edgeInfo.wordId1) ||
            !visibleNeighborIds.contains(edgeInfo.wordId2)) {
          continue;
        }
        registerEdgeInfo(edgeInfo);
      }
    }

    final centerNode = _buildGraphNodeForWord(
      word: centerWord,
      depth: 0,
      isCenter: true,
      expansionSourceId: null,
      weight: relationCountsByWordId[centerWord.id]?.toDouble() ?? 1.0,
      labelDisplaysByWordId: labelDisplaysByWordId,
    );
    final nodes = visibleWordsById.values
        .where((word) => word.wordId != centerWord.id)
        .map(
          (word) => _buildGraphNodeForVisibleWord(
            word: word,
            depth: depthByWordId[word.wordId] ?? 2,
            isCenter: false,
            expansionSourceId: expansionSourceIdByWordId[word.wordId],
            weight: relationCountsByWordId[word.wordId]?.toDouble() ?? 1.0,
            labelDisplaysByWordId: labelDisplaysByWordId,
          ),
        )
        .followedBy(placeholderNodes)
        .toList(growable: false);
    final initialEdges = mergedRelationEdges
        .map(_buildGraphEdgeFromEdgeInfo)
        .followedBy(syntheticEdges)
        .toList(growable: false);

    var viewData = build(
      options: options,
      centerNode: centerNode,
      nodes: nodes,
      edges: initialEdges,
    );
    final visibleRegularNodeIds = viewData.nodes
        .where((node) => !node.isPlaceholderMoreNode)
        .map((node) => node.wordId)
        .toSet();

    for (final edgeInfo in supplementalRelationEdges) {
      if (!visibleRegularNodeIds.contains(edgeInfo.wordId1) ||
          !visibleRegularNodeIds.contains(edgeInfo.wordId2)) {
        continue;
      }
      registerEdgeInfo(edgeInfo);
    }

    final edges = mergedRelationEdges
        .map(_buildGraphEdgeFromEdgeInfo)
        .followedBy(syntheticEdges)
        .toList(growable: false);
    viewData = build(
      options: options,
      centerNode: centerNode,
      nodes: nodes,
      edges: edges,
    );
    final visibleWordIds = viewData.nodes
        .map((node) => node.id)
        .where((nodeId) => nodeId != viewData.centerNodeId)
        .toList(growable: false);
    final visibleEdgeIds = viewData.edges.map((edge) => edge.id).toSet();
    final normalizedRelationEdges =
        mergedRelationEdges
            .where(
              (edgeInfo) => visibleEdgeIds.contains(
                _edgeDedupeKeyForRelationInfo(edgeInfo),
              ),
            )
            .toList(growable: false)
          ..sort(_compareRelationEdgeInfos);
    final normalizedWords = visibleWordIds
        .map((wordId) => visibleWordsById[wordId])
        .whereType<GraphVisibleWord>()
        .map(_fallbackWordForGraphVisibleWord)
        .toList(growable: false);
    final normalizedWordLabels = [viewData.centerNodeId, ...visibleWordIds]
        .map(
          (wordId) =>
              labelDisplaysByWordId[wordId] ??
              (wordId == centerWord.id
                  ? _labelDisplayForWord(centerWord)
                  : _labelDisplayForGraphVisibleWord(visibleWordsById[wordId])),
        )
        .whereType<GraphWordLabelDisplayItem>()
        .toList(growable: false);

    return (
      viewData: viewData,
      connectedWords: List<Word>.unmodifiable(normalizedWords),
      wordLabels: List<GraphWordLabelDisplayItem>.unmodifiable(
        normalizedWordLabels,
      ),
      relationEdges: List<WordRelationEdgeInfo>.unmodifiable(
        normalizedRelationEdges,
      ),
    );
  }

  GraphViewData build({
    required GraphBuildOptions options,
    required GraphNode centerNode,
    Iterable<GraphNode> nodes = const <GraphNode>[],
    Iterable<GraphEdge> edges = const <GraphEdge>[],
  }) {
    final normalizedCenter = centerNode.copyWith(depth: 0, isCenter: true);
    final normalizedNodes = _normalizeNodes(
      options: options,
      centerNode: normalizedCenter,
      nodes: nodes,
    );
    final visibleNodeIds = normalizedNodes.map((node) => node.id).toSet();
    final normalizedEdges = _normalizeEdges(
      options: options,
      edges: edges,
      visibleNodeIds: visibleNodeIds,
    );

    return GraphViewData(
      nodes: normalizedNodes,
      edges: normalizedEdges,
      centerNodeId: normalizedCenter.id,
    );
  }

  List<GraphNode> _normalizeNodes({
    required GraphBuildOptions options,
    required GraphNode centerNode,
    required Iterable<GraphNode> nodes,
  }) {
    final nodesById = <String, GraphNode>{centerNode.id: centerNode};

    for (final node in nodes) {
      if (node.id == centerNode.id) {
        continue;
      }
      if (node.depth > options.maxDepth) {
        continue;
      }
      final normalizedNode = node.copyWith(
        isCenter: false,
        clearExpansionSourceId: node.depth <= 1,
        hiddenCount: node.hiddenCount,
        placeholderSourceWordId: node.placeholderSourceWordId,
        clearPlaceholderSourceWordId:
            !node.isPlaceholderMoreNode && node.placeholderSourceWordId == null,
      );
      final existingNode = nodesById[node.id];
      if (existingNode == null) {
        nodesById[node.id] = normalizedNode;
        continue;
      }

      final mergedDepth = existingNode.depth <= normalizedNode.depth
          ? existingNode.depth
          : normalizedNode.depth;
      nodesById[node.id] = existingNode.copyWith(
        label: existingNode.label.trim().isNotEmpty
            ? existingNode.label
            : normalizedNode.label,
        depth: mergedDepth,
        isCenter: false,
        expansionSourceId: mergedDepth <= 1
            ? null
            : (existingNode.expansionSourceId ??
                  normalizedNode.expansionSourceId),
        clearExpansionSourceId: mergedDepth <= 1,
        isPlaceholderMoreNode:
            existingNode.isPlaceholderMoreNode ||
            normalizedNode.isPlaceholderMoreNode,
        hiddenCount: existingNode.hiddenCount >= normalizedNode.hiddenCount
            ? existingNode.hiddenCount
            : normalizedNode.hiddenCount,
        placeholderSourceWordId:
            existingNode.placeholderSourceWordId ??
            normalizedNode.placeholderSourceWordId,
        clearPlaceholderSourceWordId:
            existingNode.placeholderSourceWordId == null &&
            normalizedNode.placeholderSourceWordId == null,
        languageCode: existingNode.languageCode ?? normalizedNode.languageCode,
        weight: existingNode.weight >= normalizedNode.weight
            ? existingNode.weight
            : normalizedNode.weight,
        isPinned: existingNode.isPinned || normalizedNode.isPinned,
      );
    }

    final peripheralNodes =
        nodesById.values
            .where((node) => node.id != centerNode.id)
            .toList(growable: false)
          ..sort(_compareNodes);

    final limitedNodes = peripheralNodes.take(options.maxNodes - 1);

    return List<GraphNode>.unmodifiable([centerNode, ...limitedNodes]);
  }

  List<GraphEdge> _normalizeEdges({
    required GraphBuildOptions options,
    required Iterable<GraphEdge> edges,
    required Set<String> visibleNodeIds,
  }) {
    final edgesById = <String, GraphEdge>{};

    for (final edge in edges) {
      if (!visibleNodeIds.contains(edge.sourceId) ||
          !visibleNodeIds.contains(edge.targetId)) {
        continue;
      }
      if (!options.allowsRelationType(edge.relationType)) {
        continue;
      }
      if (!options.allowsStatusCode(edge.statusCode)) {
        continue;
      }
      edgesById[edge.id] = edge;
    }

    final normalizedEdges = edgesById.values.toList(growable: false)
      ..sort(_compareEdges);

    return List<GraphEdge>.unmodifiable(normalizedEdges);
  }

  bool _isCoreMust(WordRelationEdgeInfo edgeInfo) {
    switch (edgeInfo.centerRelativeDirection.trim()) {
      case 'incoming':
      case 'undirected':
        return true;
      default:
        return false;
    }
  }

  bool _isProtectedMust(WordRelationEdgeInfo edgeInfo) {
    return edgeInfo.centerRelativeDirection.trim() == 'unknown';
  }

  bool _isPreferred(WordRelationEdgeInfo edgeInfo) {
    final relationType = (edgeInfo.relationType ?? '').trim().toLowerCase();
    final categoryCode = (edgeInfo.categoryCode ?? '').trim().toLowerCase();
    return _preferredCategoryCodes.contains(categoryCode) ||
        _preferredRelationTypes.contains(relationType);
  }

  bool _isSemiPreferred(WordRelationEdgeInfo edgeInfo) {
    final relationType = (edgeInfo.relationType ?? '').trim().toLowerCase();
    return _semiPreferredRelationTypes.contains(relationType);
  }

  _BranchPriorityCounts _computeBranchPriorityCounts({
    required String candidateWordId,
    required Iterable<WordRelationEdgeInfo> relationEdges,
    required Set<String> contextWordIds,
  }) {
    var coreMustCount = 0;
    var protectedMustCount = 0;
    var preferredCount = 0;
    var semiPreferredCount = 0;

    for (final edgeInfo in relationEdges) {
      final isCandidateToContextEdge =
          (edgeInfo.wordId1 == candidateWordId &&
              contextWordIds.contains(edgeInfo.wordId2)) ||
          (edgeInfo.wordId2 == candidateWordId &&
              contextWordIds.contains(edgeInfo.wordId1));
      if (!isCandidateToContextEdge) {
        continue;
      }

      // A branch edge contributes to exactly one highest-priority bucket.
      switch (_priorityBucketForEdge(edgeInfo)) {
        case _BranchPriorityBucket.coreMust:
          coreMustCount++;
          break;
        case _BranchPriorityBucket.protectedMust:
          protectedMustCount++;
          break;
        case _BranchPriorityBucket.preferred:
          preferredCount++;
          break;
        case _BranchPriorityBucket.semiPreferred:
          semiPreferredCount++;
          break;
        case _BranchPriorityBucket.fallback:
          break;
      }
    }

    return (
      coreMustCount: coreMustCount,
      protectedMustCount: protectedMustCount,
      preferredCount: preferredCount,
      semiPreferredCount: semiPreferredCount,
    );
  }

  int _compareBranchPriority({
    required _BranchPriorityCounts leftCounts,
    required _BranchPriorityCounts rightCounts,
    required int leftExistingScore,
    required int rightExistingScore,
    required String leftLabel,
    required String rightLabel,
    required String leftId,
    required String rightId,
  }) {
    final byCoreMust = rightCounts.coreMustCount.compareTo(
      leftCounts.coreMustCount,
    );
    if (byCoreMust != 0) {
      return byCoreMust;
    }

    final byProtectedMust = rightCounts.protectedMustCount.compareTo(
      leftCounts.protectedMustCount,
    );
    if (byProtectedMust != 0) {
      return byProtectedMust;
    }

    final byPreferred = rightCounts.preferredCount.compareTo(
      leftCounts.preferredCount,
    );
    if (byPreferred != 0) {
      return byPreferred;
    }

    final bySemiPreferred = rightCounts.semiPreferredCount.compareTo(
      leftCounts.semiPreferredCount,
    );
    if (bySemiPreferred != 0) {
      return bySemiPreferred;
    }

    final byExistingScore = rightExistingScore.compareTo(leftExistingScore);
    if (byExistingScore != 0) {
      return byExistingScore;
    }

    final byLabel = leftLabel.compareTo(rightLabel);
    if (byLabel != 0) {
      return byLabel;
    }

    return leftId.compareTo(rightId);
  }

  _BranchPriorityBucket _priorityBucketForEdge(WordRelationEdgeInfo edgeInfo) {
    if (_isCoreMust(edgeInfo)) {
      return _BranchPriorityBucket.coreMust;
    }
    if (_isProtectedMust(edgeInfo)) {
      return _BranchPriorityBucket.protectedMust;
    }
    if (_isPreferred(edgeInfo)) {
      return _BranchPriorityBucket.preferred;
    }
    if (_isSemiPreferred(edgeInfo)) {
      return _BranchPriorityBucket.semiPreferred;
    }
    return _BranchPriorityBucket.fallback;
  }

  List<GraphVisibleWord> _prioritizeCenterDepthOneWords({
    required String centerWordId,
    required Iterable<GraphVisibleWord> baseWords,
    required Iterable<WordRelationEdgeInfo> relationEdges,
    required Map<String, int> relationCountsByWordId,
    required Map<String, GraphWordLabelDisplayItem> labelDisplaysByWordId,
  }) {
    final prioritizedWords = baseWords.toList(growable: false);
    if (prioritizedWords.length < 2) {
      return List<GraphVisibleWord>.unmodifiable(prioritizedWords);
    }

    final relationEdgeList = relationEdges.toList(growable: false);
    final labelsByWordId = <String, String>{
      for (final word in prioritizedWords)
        word.wordId: _labelForGraphVisibleWord(word, labelDisplaysByWordId),
    };
    final priorityCountsByWordId = <String, _BranchPriorityCounts>{
      for (final word in prioritizedWords)
        word.wordId: _computeBranchPriorityCounts(
          candidateWordId: word.wordId,
          relationEdges: relationEdgeList,
          contextWordIds: {centerWordId},
        ),
    };
    prioritizedWords.sort((left, right) {
      return _compareBranchPriority(
        leftCounts:
            priorityCountsByWordId[left.wordId] ??
            (
              coreMustCount: 0,
              protectedMustCount: 0,
              preferredCount: 0,
              semiPreferredCount: 0,
            ),
        rightCounts:
            priorityCountsByWordId[right.wordId] ??
            (
              coreMustCount: 0,
              protectedMustCount: 0,
              preferredCount: 0,
              semiPreferredCount: 0,
            ),
        leftExistingScore: relationCountsByWordId[left.wordId] ?? 0,
        rightExistingScore: relationCountsByWordId[right.wordId] ?? 0,
        leftLabel: labelsByWordId[left.wordId] ?? left.wordId,
        rightLabel: labelsByWordId[right.wordId] ?? right.wordId,
        leftId: left.wordId,
        rightId: right.wordId,
      );
    });

    return List<GraphVisibleWord>.unmodifiable(prioritizedWords);
  }

  List<GraphVisibleWord> _prioritizeOwnedDepthTwoWords({
    required String sourceWordId,
    required Iterable<GraphVisibleWord> ownedDepthTwoWords,
    required Iterable<WordRelationEdgeInfo> relationEdges,
    required Set<String> visibleNeighborIds,
    required Map<String, GraphWordLabelDisplayItem> labelDisplaysByWordId,
  }) {
    final prioritizedWords = ownedDepthTwoWords.toList(growable: false);
    if (prioritizedWords.length < 2) {
      return List<GraphVisibleWord>.unmodifiable(prioritizedWords);
    }

    final sourceContextNeighborIds = <String>{
      sourceWordId,
      ...visibleNeighborIds,
    };
    final relationEdgeList = relationEdges.toList(growable: false);
    final proxyScoresByWordId = <String, int>{
      for (final word in prioritizedWords) word.wordId: 0,
    };
    final labelsByWordId = <String, String>{
      for (final word in prioritizedWords)
        word.wordId: _labelForGraphVisibleWord(word, labelDisplaysByWordId),
    };
    final priorityCountsByWordId = <String, _BranchPriorityCounts>{
      for (final word in prioritizedWords)
        word.wordId: _computeBranchPriorityCounts(
          candidateWordId: word.wordId,
          relationEdges: relationEdgeList,
          contextWordIds: sourceContextNeighborIds,
        ),
    };

    for (final edgeInfo in relationEdgeList) {
      String? candidateWordId;
      String? contextWordId;

      if (proxyScoresByWordId.containsKey(edgeInfo.wordId1)) {
        candidateWordId = edgeInfo.wordId1;
        contextWordId = edgeInfo.wordId2;
      } else if (proxyScoresByWordId.containsKey(edgeInfo.wordId2)) {
        candidateWordId = edgeInfo.wordId2;
        contextWordId = edgeInfo.wordId1;
      }

      if (candidateWordId == null || contextWordId == null) {
        continue;
      }
      if (!sourceContextNeighborIds.contains(contextWordId)) {
        continue;
      }

      proxyScoresByWordId.update(candidateWordId, (score) => score + 1);
    }

    prioritizedWords.sort((left, right) {
      return _compareBranchPriority(
        leftCounts:
            priorityCountsByWordId[left.wordId] ??
            (
              coreMustCount: 0,
              protectedMustCount: 0,
              preferredCount: 0,
              semiPreferredCount: 0,
            ),
        rightCounts:
            priorityCountsByWordId[right.wordId] ??
            (
              coreMustCount: 0,
              protectedMustCount: 0,
              preferredCount: 0,
              semiPreferredCount: 0,
            ),
        leftExistingScore: proxyScoresByWordId[left.wordId] ?? 0,
        rightExistingScore: proxyScoresByWordId[right.wordId] ?? 0,
        leftLabel: labelsByWordId[left.wordId] ?? left.wordId,
        rightLabel: labelsByWordId[right.wordId] ?? right.wordId,
        leftId: left.wordId,
        rightId: right.wordId,
      );
    });

    return List<GraphVisibleWord>.unmodifiable(prioritizedWords);
  }

  GraphNode _buildGraphNodeForWord({
    required Word word,
    required int depth,
    required bool isCenter,
    required String? expansionSourceId,
    required double weight,
    required Map<String, GraphWordLabelDisplayItem> labelDisplaysByWordId,
  }) {
    return GraphNode(
      wordId: word.id,
      label: _labelForWord(word, labelDisplaysByWordId),
      depth: depth,
      isCenter: isCenter,
      expansionSourceId: depth <= 1 ? null : expansionSourceId,
      isPlaceholderMoreNode: false,
      hiddenCount: 0,
      placeholderSourceWordId: null,
      languageCode: _languageCodeForWord(word),
      weight: weight,
      isPinned: false,
    );
  }

  GraphNode _buildGraphNodeForVisibleWord({
    required GraphVisibleWord word,
    required int depth,
    required bool isCenter,
    required String? expansionSourceId,
    required double weight,
    required Map<String, GraphWordLabelDisplayItem> labelDisplaysByWordId,
  }) {
    return GraphNode(
      wordId: word.wordId,
      label: _labelForGraphVisibleWord(word, labelDisplaysByWordId),
      depth: depth,
      isCenter: isCenter,
      expansionSourceId: depth <= 1 ? null : expansionSourceId,
      isPlaceholderMoreNode: false,
      hiddenCount: 0,
      placeholderSourceWordId: null,
      languageCode: _languageCodeForWordId(word.wordId),
      weight: weight,
      isPinned: false,
    );
  }

  GraphNode _buildPlaceholderMoreNode({
    required String sourceWordId,
    required int hiddenCount,
  }) {
    final nodeId = _placeholderNodeIdForSource(sourceWordId);
    return GraphNode(
      wordId: nodeId,
      label: '+$hiddenCount more',
      depth: 2,
      isCenter: false,
      expansionSourceId: sourceWordId,
      isPlaceholderMoreNode: true,
      hiddenCount: hiddenCount,
      placeholderSourceWordId: sourceWordId,
      languageCode: null,
      weight: 1000.0 + hiddenCount,
      isPinned: false,
    );
  }

  GraphNode _buildCenterDepthOnePlaceholderMoreNode({
    required String centerWordId,
    required int hiddenCount,
  }) {
    final nodeId = _centerDepthOnePlaceholderNodeId(centerWordId);
    return GraphNode(
      wordId: nodeId,
      label: '+$hiddenCount more',
      depth: 1,
      isCenter: false,
      expansionSourceId: null,
      isPlaceholderMoreNode: true,
      hiddenCount: hiddenCount,
      placeholderSourceWordId: centerWordId,
      languageCode: null,
      weight: 1000.0 + hiddenCount,
      isPinned: false,
    );
  }

  GraphEdge _buildPlaceholderEdge({
    required String sourceWordId,
    required String placeholderNodeId,
  }) {
    return GraphEdge(
      sourceId: sourceWordId,
      targetId: placeholderNodeId,
      relationId: null,
      relationType: null,
      categoryCode: null,
      statusCode: null,
      directionCode: 'unknown',
      description: null,
      weight: 1.0,
      isHighlighted: false,
    );
  }

  String _placeholderNodeIdForSource(String sourceWordId) {
    return '$_morePlaceholderNodePrefix::$sourceWordId';
  }

  String _centerDepthOnePlaceholderNodeId(String centerWordId) {
    return '$_morePlaceholderNodePrefix::center::$centerWordId';
  }

  GraphEdge _buildGraphEdgeFromEdgeInfo(WordRelationEdgeInfo info) {
    return GraphEdge(
      sourceId: info.wordId1,
      targetId: info.wordId2,
      relationId: info.relationId,
      relationType: info.relationType,
      categoryCode: info.categoryCode,
      statusCode: info.statusCode,
      directionCode: info.directionCode,
      description: info.description,
      weight: 1.0,
      isHighlighted: false,
    );
  }

  String _edgeDedupeKeyForRelationInfo(WordRelationEdgeInfo info) {
    final relationId = info.relationId;
    if (relationId > 0) {
      return relationId.toString();
    }

    final minWordId = info.wordId1.compareTo(info.wordId2) <= 0
        ? info.wordId1
        : info.wordId2;
    final maxWordId = info.wordId1.compareTo(info.wordId2) <= 0
        ? info.wordId2
        : info.wordId1;
    final relationType = (info.relationType ?? '').trim();
    final categoryCode = (info.categoryCode ?? '').trim();
    return '$minWordId::$maxWordId::$relationType::$categoryCode';
  }

  String _labelForWord(
    Word word,
    Map<String, GraphWordLabelDisplayItem> labelDisplaysByWordId,
  ) {
    final labelDisplay = labelDisplaysByWordId[word.id];
    if (labelDisplay != null) {
      return labelDisplay.graphBuilderLabel;
    }

    final spelling = (word.spelling1 ?? '').trim();
    if (spelling.isNotEmpty) {
      return spelling;
    }

    final strongNumber = (word.strongNumber ?? '').trim();
    if (strongNumber.isNotEmpty) {
      return strongNumber;
    }

    return word.id;
  }

  String _labelForGraphVisibleWord(
    GraphVisibleWord word,
    Map<String, GraphWordLabelDisplayItem> labelDisplaysByWordId,
  ) {
    final labelDisplay = labelDisplaysByWordId[word.wordId];
    if (labelDisplay != null) {
      return labelDisplay.graphBuilderLabel;
    }

    return word.graphBuilderFallbackLabel;
  }

  Word _fallbackWordForGraphVisibleWord(GraphVisibleWord word) {
    return Word(
      id: word.wordId,
      spelling1: _nullIfBlank(word.fallbackSpelling),
      strongNumber: _nullIfBlank(word.fallbackStrongNumber),
      transliteration1: _nullIfBlank(word.fallbackTransliteration),
    );
  }

  String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  GraphWordLabelDisplayItem? _labelDisplayForWord(Word? word) {
    if (word == null) {
      return null;
    }

    return GraphWordLabelDisplayItem(
      wordId: word.id,
      representativeSpelling: (word.spelling1 ?? '').trim(),
      representativeTransliteration: (word.transliteration1 ?? '').trim(),
      displayStrongNumber: (word.strongNumber ?? '').trim(),
      language: '',
      primaryMeaning: '',
    );
  }

  GraphWordLabelDisplayItem? _labelDisplayForGraphVisibleWord(
    GraphVisibleWord? word,
  ) {
    if (word == null) {
      return null;
    }

    return GraphWordLabelDisplayItem(
      wordId: word.wordId,
      representativeSpelling: word.fallbackSpelling.trim(),
      representativeTransliteration: word.fallbackTransliteration.trim(),
      displayStrongNumber: word.fallbackStrongNumber.trim(),
      language: '',
      primaryMeaning: '',
    );
  }

  String? _languageCodeForWord(Word word) {
    return _languageCodeForWordId(word.id);
  }

  String? _languageCodeForWordId(String wordId) {
    final trimmedId = wordId.trim();
    if (trimmedId.isEmpty) {
      return null;
    }

    return trimmedId.substring(0, 1).toUpperCase();
  }

  int _compareNodes(GraphNode left, GraphNode right) {
    final byDepth = left.depth.compareTo(right.depth);
    if (byDepth != 0) {
      return byDepth;
    }

    if (left.isPlaceholderMoreNode != right.isPlaceholderMoreNode) {
      return left.isPlaceholderMoreNode ? -1 : 1;
    }

    if (left.isPlaceholderMoreNode && right.isPlaceholderMoreNode) {
      final byHiddenCount = right.hiddenCount.compareTo(left.hiddenCount);
      if (byHiddenCount != 0) {
        return byHiddenCount;
      }
    }

    final byWeight = right.weight.compareTo(left.weight);
    if (byWeight != 0) {
      return byWeight;
    }

    final byLabel = left.label.compareTo(right.label);
    if (byLabel != 0) {
      return byLabel;
    }

    return left.wordId.compareTo(right.wordId);
  }

  int _compareEdges(GraphEdge left, GraphEdge right) {
    final leftRelationId = left.relationId;
    final rightRelationId = right.relationId;

    if (leftRelationId != null && rightRelationId != null) {
      final byRelationId = leftRelationId.compareTo(rightRelationId);
      if (byRelationId != 0) {
        return byRelationId;
      }
    } else if (leftRelationId != null) {
      return -1;
    } else if (rightRelationId != null) {
      return 1;
    }

    final bySource = left.sourceId.compareTo(right.sourceId);
    if (bySource != 0) {
      return bySource;
    }

    final byTarget = left.targetId.compareTo(right.targetId);
    if (byTarget != 0) {
      return byTarget;
    }

    return left.id.compareTo(right.id);
  }

  int _compareRelationEdgeInfos(
    WordRelationEdgeInfo left,
    WordRelationEdgeInfo right,
  ) {
    final byRelationId = left.relationId.compareTo(right.relationId);
    if (byRelationId != 0) {
      return byRelationId;
    }

    final byWord1 = left.wordId1.compareTo(right.wordId1);
    if (byWord1 != 0) {
      return byWord1;
    }

    final byWord2 = left.wordId2.compareTo(right.wordId2);
    if (byWord2 != 0) {
      return byWord2;
    }

    final byRelationType = (left.relationType ?? '').compareTo(
      right.relationType ?? '',
    );
    if (byRelationType != 0) {
      return byRelationType;
    }

    return (left.categoryCode ?? '').compareTo(right.categoryCode ?? '');
  }
}
