import '../../data/models/word.dart';
import '../../data/repositories/word_repository.dart';
import 'graph_build_options.dart';
import 'graph_edge.dart';
import 'graph_node.dart';
import 'graph_view_data.dart';

typedef GraphVisibleDataBuildResult = ({
  GraphViewData viewData,
  List<Word> connectedWords,
  List<WordRelationEdgeInfo> relationEdges,
});

/// graph_builder.dart
///
/// Repository가 조회한 단어/관계 데이터를 그래프 도메인 모델로 조립한다.
/// 이번 단계에서는 1-hop 그래프와 기본 필터링만 구현한다.
class GraphBuilder {
  static const int _defaultOutgoingLimit = 12;

  const GraphBuilder();

  GraphViewData buildFromVisibleGraphData({
    required GraphBuildOptions options,
    required Word centerWord,
    required Iterable<Word> connectedWords,
    required Iterable<WordRelationEdgeInfo> relationEdges,
  }) {
    return buildMergedVisibleGraphData(
      options: options,
      centerWord: centerWord,
      baseWords: connectedWords,
      baseRelationEdges: relationEdges,
    ).viewData;
  }

  GraphVisibleDataBuildResult buildMergedVisibleGraphData({
    required GraphBuildOptions options,
    required Word centerWord,
    required Iterable<Word> baseWords,
    required Iterable<WordRelationEdgeInfo> baseRelationEdges,
    Map<String, VisibleWordGraphData> expansionDataBySourceId =
        const <String, VisibleWordGraphData>{},
  }) {
    final wordsById = <String, Word>{centerWord.id: centerWord};
    final depthByWordId = <String, int>{centerWord.id: 0};
    final expansionSourceIdByWordId = <String, String?>{};
    final relationCountsByWordId = <String, int>{};
    final mergedRelationEdges = <WordRelationEdgeInfo>[];
    final edgeKeys = <String>{};
    final baseWordIds = <String>{};

    void registerWord(
      Word word, {
      required int depth,
      String? expansionSourceId,
    }) {
      wordsById[word.id] ??= word;
      final nextDepth = depth.clamp(0, options.maxDepth).toInt();
      final existingDepth = depthByWordId[word.id];
      if (existingDepth == null || nextDepth < existingDepth) {
        depthByWordId[word.id] = nextDepth;
      }

      if (word.id == centerWord.id || nextDepth <= 1) {
        expansionSourceIdByWordId[word.id] = null;
        return;
      }

      expansionSourceIdByWordId[word.id] ??= expansionSourceId;
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

    for (final word in baseWords) {
      baseWordIds.add(word.id);
      registerWord(word, depth: 1);
    }

    for (final edgeInfo in baseRelationEdges) {
      registerEdgeInfo(edgeInfo);
    }

    for (final entry in expansionDataBySourceId.entries) {
      final sourceWordId = entry.key;
      final sourceDepth = depthByWordId[sourceWordId];
      if (sourceDepth == null || sourceDepth != 1) {
        continue;
      }

      for (final word in entry.value.connectedWords) {
        final depth = word.id == centerWord.id
            ? 0
            : (baseWordIds.contains(word.id) ? 1 : 2);
        registerWord(
          word,
          depth: depth,
          expansionSourceId: depth >= 2 ? sourceWordId : null,
        );
      }

      for (final edgeInfo in entry.value.relationEdges) {
        registerEdgeInfo(edgeInfo);
      }
    }

    final centerNode = _buildGraphNode(
      word: centerWord,
      depth: 0,
      isCenter: true,
      expansionSourceId: null,
      weight: relationCountsByWordId[centerWord.id]?.toDouble() ?? 1.0,
    );
    final nodes = wordsById.values
        .where((word) => word.id != centerWord.id)
        .map(
          (word) => _buildGraphNode(
            word: word,
            depth: depthByWordId[word.id] ?? 2,
            isCenter: false,
            expansionSourceId: expansionSourceIdByWordId[word.id],
            weight: relationCountsByWordId[word.id]?.toDouble() ?? 1.0,
          ),
        )
        .toList(growable: false);
    final edges = mergedRelationEdges
        .map(_buildGraphEdgeFromEdgeInfo)
        .toList(growable: false);

    final viewData = build(
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
        .map((wordId) => wordsById[wordId])
        .whereType<Word>()
        .toList(growable: false);

    return (
      viewData: viewData,
      connectedWords: List<Word>.unmodifiable(normalizedWords),
      relationEdges: List<WordRelationEdgeInfo>.unmodifiable(
        normalizedRelationEdges,
      ),
    );
  }

  Future<GraphViewData> buildFromRepository({
    required WordRepository repository,
    required GraphBuildOptions options,
  }) async {
    final centerWordRow = await repository.getWordMapById(options.centerWordId);
    if (centerWordRow == null) {
      throw StateError(
        'GraphBuilder center word not found: ${options.centerWordId}',
      );
    }

    final centerWord = Word.fromMap(centerWordRow);
    final allRelationRows = await repository.getRelationsForWord(
      options.centerWordId,
    );
    final visibleRelationRows = _selectVisibleRelationRows(
      centerWord: centerWord,
      centerWordId: options.centerWordId,
      relationRows: allRelationRows,
      options: options,
    );
    final relatedWordIds = _collectRelatedWordIds(
      centerWordId: options.centerWordId,
      relationRows: visibleRelationRows,
    );
    final relatedWordRows = relatedWordIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await repository.getWordsByIds(relatedWordIds);
    final relatedWords = relatedWordRows
        .map(Word.fromMap)
        .toList(growable: false);
    final relationCountsByWordId = _countRelationsByOtherWordId(
      centerWordId: options.centerWordId,
      relationRows: visibleRelationRows,
    );

    final centerNode = _buildGraphNode(
      word: centerWord,
      depth: 0,
      isCenter: true,
      expansionSourceId: null,
      weight: visibleRelationRows.isEmpty
          ? 1.0
          : visibleRelationRows.length.toDouble(),
    );
    final nodes = relatedWords
        .map(
          (word) => _buildGraphNode(
            word: word,
            depth: 1,
            isCenter: false,
            expansionSourceId: null,
            weight: relationCountsByWordId[word.id]?.toDouble() ?? 1.0,
          ),
        )
        .toList(growable: false);
    final edges = visibleRelationRows
        .map(_buildGraphEdgeFromRow)
        .toList(growable: false);

    return build(
      options: options,
      centerNode: centerNode,
      nodes: nodes,
      edges: edges,
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

  List<Map<String, dynamic>> _selectVisibleRelationRows({
    required Word centerWord,
    required String centerWordId,
    required List<Map<String, dynamic>> relationRows,
    required GraphBuildOptions options,
  }) {
    if (options.maxDepth < 1 || relationRows.isEmpty) {
      return const [];
    }

    final graphExpandMode = _normalizeGraphExpandMode(
      centerWord.graphExpandMode,
    );
    final visibleRows = <Map<String, dynamic>>[];
    var outgoingCount = 0;

    for (final row in relationRows) {
      final relationType = _stringOrNull(row['relation_type']);
      if (!options.allowsRelationType(relationType)) {
        continue;
      }

      final statusCode = _stringOrNull(row['status_code']);
      if (!options.allowsStatusCode(statusCode)) {
        continue;
      }

      final centerRelativeDirection = _resolveCenterRelativeDirection(
        centerWordId: centerWordId,
        wordId1: row['word_id_1'] as String,
        wordId2: row['word_id_2'] as String,
        directionCode: row['direction_code'] as String?,
      );

      final include = _shouldIncludeByGraphExpandMode(
        graphExpandMode: graphExpandMode,
        centerRelativeDirection: centerRelativeDirection,
        outgoingLimit: _defaultOutgoingLimit,
        currentOutgoingCount: outgoingCount,
      );
      if (!include) {
        continue;
      }

      visibleRows.add(row);
      if (centerRelativeDirection == 'outgoing') {
        outgoingCount++;
      }
    }

    return List.unmodifiable(visibleRows);
  }

  List<String> _collectRelatedWordIds({
    required String centerWordId,
    required List<Map<String, dynamic>> relationRows,
  }) {
    final relatedWordIds = <String>[];
    final seenIds = <String>{};

    for (final row in relationRows) {
      final otherWordId = _otherWordId(
        centerWordId: centerWordId,
        wordId1: row['word_id_1'] as String,
        wordId2: row['word_id_2'] as String,
      );
      if (seenIds.add(otherWordId)) {
        relatedWordIds.add(otherWordId);
      }
    }

    return List.unmodifiable(relatedWordIds);
  }

  Map<String, int> _countRelationsByOtherWordId({
    required String centerWordId,
    required List<Map<String, dynamic>> relationRows,
  }) {
    final counts = <String, int>{};

    for (final row in relationRows) {
      final otherWordId = _otherWordId(
        centerWordId: centerWordId,
        wordId1: row['word_id_1'] as String,
        wordId2: row['word_id_2'] as String,
      );
      counts.update(otherWordId, (count) => count + 1, ifAbsent: () => 1);
    }

    return counts;
  }

  GraphNode _buildGraphNode({
    required Word word,
    required int depth,
    required bool isCenter,
    required String? expansionSourceId,
    required double weight,
  }) {
    return GraphNode(
      wordId: word.id,
      label: _labelForWord(word),
      depth: depth,
      isCenter: isCenter,
      expansionSourceId: depth <= 1 ? null : expansionSourceId,
      languageCode: _languageCodeForWord(word),
      weight: weight,
      isPinned: false,
    );
  }

  GraphEdge _buildGraphEdgeFromRow(Map<String, dynamic> row) {
    return GraphEdge(
      sourceId: row['word_id_1'] as String,
      targetId: row['word_id_2'] as String,
      relationId: _intOrNull(row['id']),
      relationType: _stringOrNull(row['relation_type']),
      categoryCode: _stringOrNull(row['category_code']),
      statusCode: _stringOrNull(row['status_code']),
      directionCode: _stringOrNull(row['direction_code']),
      description: _stringOrNull(row['description']),
      weight: 1.0,
      isHighlighted: false,
    );
  }

  GraphEdge _buildGraphEdgeFromEdgeInfo(WordRelationEdgeInfo info) {
    return GraphEdge(
      sourceId: info.wordId1,
      targetId: info.wordId2,
      relationId: info.relationId,
      relationType: info.relationType,
      categoryCode: info.categoryCode,
      statusCode: null,
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

  String _labelForWord(Word word) {
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

  String? _languageCodeForWord(Word word) {
    final trimmedId = word.id.trim();
    if (trimmedId.isEmpty) {
      return null;
    }

    return trimmedId.substring(0, 1).toUpperCase();
  }

  String _otherWordId({
    required String centerWordId,
    required String wordId1,
    required String wordId2,
  }) {
    return wordId1 == centerWordId ? wordId2 : wordId1;
  }

  String? _stringOrNull(Object? value) {
    final trimmed = (value ?? '').toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _intOrNull(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString().trim());
  }

  String _normalizeGraphExpandMode(String? value) {
    switch ((value ?? '').trim()) {
      case 'incoming_only':
      case 'outgoing_limited':
      case 'full':
        return (value ?? '').trim();
      case 'default':
      default:
        return 'default';
    }
  }

  String _normalizeDirectionCode(String? value) {
    switch ((value ?? '').trim()) {
      case 'w1_to_w2':
      case 'w2_to_w1':
      case 'undirected':
      case 'unknown':
        return (value ?? '').trim();
      default:
        return 'unknown';
    }
  }

  String _resolveCenterRelativeDirection({
    required String centerWordId,
    required String wordId1,
    required String wordId2,
    required String? directionCode,
  }) {
    final normalizedDirectionCode = _normalizeDirectionCode(directionCode);

    switch (normalizedDirectionCode) {
      case 'w1_to_w2':
        return centerWordId == wordId1 ? 'outgoing' : 'incoming';
      case 'w2_to_w1':
        return centerWordId == wordId1 ? 'incoming' : 'outgoing';
      case 'undirected':
        return 'undirected';
      default:
        return 'unknown';
    }
  }

  bool _shouldIncludeByGraphExpandMode({
    required String graphExpandMode,
    required String centerRelativeDirection,
    required int outgoingLimit,
    required int currentOutgoingCount,
  }) {
    switch (graphExpandMode) {
      case 'incoming_only':
        return centerRelativeDirection != 'outgoing';
      case 'outgoing_limited':
        if (centerRelativeDirection != 'outgoing') return true;
        return currentOutgoingCount < outgoingLimit;
      case 'full':
      case 'default':
      default:
        return true;
    }
  }

  int _compareNodes(GraphNode left, GraphNode right) {
    final byDepth = left.depth.compareTo(right.depth);
    if (byDepth != 0) {
      return byDepth;
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
