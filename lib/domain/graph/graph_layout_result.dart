import 'dart:ui';

import 'graph_edge.dart';

/// graph_layout_result.dart
///
/// 레이아웃 전략이 계산한 좌표 결과다.
/// positionedNodes는 nodeId를 키로 사용한다.
class GraphLayoutResult {
  final Map<String, Offset> positionedNodes;
  final List<GraphEdge> edges;
  final Rect bounds;

  GraphLayoutResult({
    required Map<String, Offset> positionedNodes,
    required Iterable<GraphEdge> edges,
    required this.bounds,
  }) : positionedNodes = Map.unmodifiable(positionedNodes),
       edges = List.unmodifiable(edges);

  Offset? positionFor(String nodeId) => positionedNodes[nodeId];
}
