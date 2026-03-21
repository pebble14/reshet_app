import 'graph_build_options.dart';
import 'graph_edge.dart';
import 'graph_node.dart';
import 'graph_view_data.dart';

/// graph_builder.dart
///
/// Repository가 준비한 단어/관계 데이터를 그래프 도메인 모델로 정리한다.
/// foundation 단계에서는 정렬, 중복 제거, 필터 적용 기준을 먼저 고정한다.
class GraphBuilder {
  const GraphBuilder();

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
      nodesById[node.id] = node.copyWith(isCenter: false);
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
}
