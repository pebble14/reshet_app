import 'graph_edge.dart';
import 'graph_node.dart';

/// graph_view_data.dart
///
/// 그래프 빌더가 만든 화면용 중간 데이터 모델이다.
/// 이후 레이아웃 전략은 이 모델만 받아 좌표를 계산한다.
class GraphViewData {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final String centerNodeId;

  GraphViewData({
    required Iterable<GraphNode> nodes,
    required Iterable<GraphEdge> edges,
    required this.centerNodeId,
  }) : nodes = List.unmodifiable(nodes),
       edges = List.unmodifiable(edges);

  GraphNode? get centerNode {
    for (final node in nodes) {
      if (node.id == centerNodeId) {
        return node;
      }
    }
    return null;
  }

  GraphNode? nodeById(String nodeId) {
    for (final node in nodes) {
      if (node.id == nodeId) {
        return node;
      }
    }
    return null;
  }
}
