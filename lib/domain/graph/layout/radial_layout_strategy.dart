import 'dart:math';
import 'dart:ui';

import '../graph_layout_result.dart';
import '../graph_node.dart';
import '../graph_view_data.dart';
import 'graph_layout_strategy.dart';

/// radial_layout_strategy.dart
///
/// 중심 노드를 화면 중앙에 두고 depth별로 원형 링에 배치하는 기본 전략이다.
/// foundation 단계에서는 depth 1을 기본으로 사용하고, depth 2 이상도 같은 방식으로
/// 확장 가능하도록 구조를 열어 둔다.
class RadialLayoutStrategy implements GraphLayoutStrategy {
  final double firstRingRadius;
  final double ringSpacing;

  const RadialLayoutStrategy({
    this.firstRingRadius = 160.0,
    this.ringSpacing = 120.0,
  });

  @override
  GraphLayoutResult layout(
    GraphViewData viewData,
    Size viewportSize, {
    int? layoutSeed,
  }) {
    final center = Offset(viewportSize.width / 2, viewportSize.height / 2);
    final positionedNodes = <String, Offset>{};
    positionedNodes[viewData.centerNodeId] = center;

    final nodesByDepth = <int, List<GraphNode>>{};
    for (final node in viewData.nodes) {
      if (node.id == viewData.centerNodeId) {
        continue;
      }
      nodesByDepth.putIfAbsent(node.depth, () => <GraphNode>[]).add(node);
    }

    final depthKeys = nodesByDepth.keys.toList()..sort();
    for (final depth in depthKeys) {
      final ringNodes = nodesByDepth[depth]!..sort(_compareNodes);
      final radius = _radiusForDepth(depth);
      final startAngle = -pi / 2 + _seedAngleOffset(layoutSeed, depth);
      final angleStep = ringNodes.isEmpty ? 0.0 : (2 * pi / ringNodes.length);

      for (var index = 0; index < ringNodes.length; index++) {
        final node = ringNodes[index];
        final angle = startAngle + (angleStep * index);
        positionedNodes[node.id] = Offset(
          center.dx + radius * cos(angle),
          center.dy + radius * sin(angle),
        );
      }
    }

    final bounds = _computeBounds(positionedNodes.values);
    return GraphLayoutResult(
      positionedNodes: positionedNodes,
      edges: viewData.edges,
      bounds: bounds,
    );
  }

  double _radiusForDepth(int depth) {
    if (depth <= 0) return 0.0;
    return firstRingRadius + (max(0, depth - 1) * ringSpacing);
  }

  double _seedAngleOffset(int? layoutSeed, int depth) {
    if (layoutSeed == null) return 0.0;

    final mixedSeed = (layoutSeed ^ (depth * 0x9E3779B9)) & 0x7fffffff;
    if (mixedSeed == 0) return 0.0;

    return (mixedSeed / 0x7fffffff) * 2 * pi;
  }

  Rect _computeBounds(Iterable<Offset> positions) {
    final iterator = positions.iterator;
    if (!iterator.moveNext()) {
      return Rect.zero;
    }

    var minX = iterator.current.dx;
    var maxX = iterator.current.dx;
    var minY = iterator.current.dy;
    var maxY = iterator.current.dy;

    while (iterator.moveNext()) {
      final point = iterator.current;
      minX = min(minX, point.dx);
      maxX = max(maxX, point.dx);
      minY = min(minY, point.dy);
      maxY = max(maxY, point.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  int _compareNodes(GraphNode left, GraphNode right) {
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
}
