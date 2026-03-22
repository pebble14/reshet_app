import 'dart:math';
import 'dart:ui';

import '../graph_edge.dart';
import '../graph_layout_result.dart';
import '../graph_node.dart';
import '../graph_view_data.dart';
import 'graph_layout_strategy.dart';

class _ForceNodePlacement {
  final int index;
  final GraphNode node;
  final double targetRadius;
  Offset position;

  _ForceNodePlacement({
    required this.index,
    required this.node,
    required this.targetRadius,
    required this.position,
  });
}

class ForceDirectedLayoutStrategy implements GraphLayoutStrategy {
  final double centerNodeDiameter;
  final double nodeDiameter;
  final double viewportPadding;
  final double minimumNodeGap;
  final double minimumCenterGap;
  final double baseCenterDistance;
  final double shellSpacing;
  final double maximumCenterDistance;
  final int iterationCount;
  final double repulsionStrength;
  final double overlapRepulsionStrength;
  final double edgeSpringStrength;
  final double centerBiasStrength;
  final double boundaryStrength;
  final double maxStepDistance;

  const ForceDirectedLayoutStrategy({
    this.centerNodeDiameter = 180.0,
    this.nodeDiameter = 80.0,
    this.viewportPadding = 28.0,
    this.minimumNodeGap = 14.0,
    this.minimumCenterGap = 12.0,
    this.baseCenterDistance = 190.0,
    this.shellSpacing = 68.0,
    this.maximumCenterDistance = 320.0,
    this.iterationCount = 90,
    this.repulsionStrength = 5200.0,
    this.overlapRepulsionStrength = 0.72,
    this.edgeSpringStrength = 0.06,
    this.centerBiasStrength = 0.085,
    this.boundaryStrength = 0.2,
    this.maxStepDistance = 15.0,
  });

  @override
  GraphLayoutResult layout(
    GraphViewData viewData,
    Size viewportSize, {
    int? layoutSeed,
  }) {
    final center = Offset(viewportSize.width / 2, viewportSize.height / 2);
    final positionedNodes = <String, Offset>{viewData.centerNodeId: center};
    final peripheralNodes =
        viewData.nodes
            .where((node) => node.id != viewData.centerNodeId)
            .toList(growable: false)
          ..sort(_compareNodes);

    if (peripheralNodes.isEmpty) {
      return GraphLayoutResult(
        positionedNodes: positionedNodes,
        edges: viewData.edges,
        bounds: Rect.fromCenter(center: center, width: 1, height: 1),
      );
    }

    final nodeHalf = nodeDiameter / 2;
    final centerHalf = centerNodeDiameter / 2;
    final minCenterDistance = centerHalf + nodeHalf + minimumCenterGap;
    final maxViewportRadius = _maxViewportRadius(
      viewportSize: viewportSize,
      nodeHalf: nodeHalf,
    );
    final maxCenterDistance = max(
      minCenterDistance,
      min(maximumCenterDistance, maxViewportRadius),
    );
    final shellCapacity = max(
      6,
      _ringCapacity(
        radius: min(baseCenterDistance, maxCenterDistance),
        spacingPerNode: nodeDiameter + minimumNodeGap,
      ),
    );
    final placements = <_ForceNodePlacement>[];

    for (var index = 0; index < peripheralNodes.length; index++) {
      final targetRadius = _targetRadiusForIndex(
        index: index,
        shellCapacity: shellCapacity,
        minCenterDistance: minCenterDistance,
        maxCenterDistance: maxCenterDistance,
      );
      placements.add(
        _ForceNodePlacement(
          index: index,
          node: peripheralNodes[index],
          targetRadius: targetRadius,
          position: _initialPositionForIndex(
            center: center,
            targetRadius: targetRadius,
            index: index,
            totalNodeCount: peripheralNodes.length,
            shellCapacity: shellCapacity,
            layoutSeed: layoutSeed,
          ),
        ),
      );
    }

    final placementIndexByNodeId = <String, int>{
      for (var index = 0; index < placements.length; index++)
        placements[index].node.id: index,
    };

    for (var iteration = 0; iteration < iterationCount; iteration++) {
      final deltas = List<Offset>.filled(placements.length, Offset.zero);
      final cooling = 1.0 - (iteration / max(iterationCount, 1));
      final stepLimit = max(1.2, maxStepDistance * (0.38 + cooling * 0.62));

      _applyCenterBias(
        center: center,
        placements: placements,
        deltas: deltas,
        minCenterDistance: minCenterDistance,
        maxCenterDistance: maxCenterDistance,
        layoutSeed: layoutSeed,
      );
      _applyNodeRepulsion(placements: placements, deltas: deltas);
      _applyEdgeForces(
        center: center,
        centerNodeId: viewData.centerNodeId,
        edges: viewData.edges,
        placements: placements,
        placementIndexByNodeId: placementIndexByNodeId,
        deltas: deltas,
      );

      var moved = false;
      for (var index = 0; index < placements.length; index++) {
        final movement = _clampOffset(deltas[index], stepLimit);
        if (movement.distanceSquared > 0.0001) {
          moved = true;
        }

        placements[index].position = _stabilizePosition(
          center: center,
          candidate: placements[index].position + movement,
          minCenterDistance: minCenterDistance,
          maxCenterDistance: maxCenterDistance,
          viewportSize: viewportSize,
          nodeHalf: nodeHalf,
          layoutSeed: layoutSeed,
          index: placements[index].index,
        );
      }

      if (!moved) {
        break;
      }
    }

    for (final placement in placements) {
      positionedNodes[placement.node.id] = placement.position;
    }

    return GraphLayoutResult(
      positionedNodes: positionedNodes,
      edges: viewData.edges,
      bounds: _computeBounds(positionedNodes.values),
    );
  }

  void _applyCenterBias({
    required Offset center,
    required List<_ForceNodePlacement> placements,
    required List<Offset> deltas,
    required double minCenterDistance,
    required double maxCenterDistance,
    required int? layoutSeed,
  }) {
    for (var index = 0; index < placements.length; index++) {
      final placement = placements[index];
      final vector = placement.position - center;
      final distance = vector.distance;
      final direction = distance <= 0.001
          ? _seedDirection(layoutSeed: layoutSeed, index: placement.index)
          : Offset(vector.dx / distance, vector.dy / distance);
      final targetDistance = placement.targetRadius.clamp(
        minCenterDistance,
        maxCenterDistance,
      );
      final radialError = distance - targetDistance;
      var delta = direction * (-radialError * centerBiasStrength);

      if (distance < minCenterDistance) {
        delta +=
            direction * ((minCenterDistance - distance) * boundaryStrength);
      } else if (distance > maxCenterDistance) {
        delta +=
            direction * (-(distance - maxCenterDistance) * boundaryStrength);
      }

      deltas[index] += delta;
    }
  }

  void _applyNodeRepulsion({
    required List<_ForceNodePlacement> placements,
    required List<Offset> deltas,
  }) {
    final minimumSeparation = nodeDiameter + minimumNodeGap;
    final interactionRange = minimumSeparation * 2.3;

    for (var leftIndex = 0; leftIndex < placements.length; leftIndex++) {
      final leftPlacement = placements[leftIndex];

      for (
        var rightIndex = leftIndex + 1;
        rightIndex < placements.length;
        rightIndex++
      ) {
        final rightPlacement = placements[rightIndex];
        final delta = rightPlacement.position - leftPlacement.position;
        final distance = max(delta.distance, 0.001);
        if (distance > interactionRange) {
          continue;
        }

        final direction = Offset(delta.dx / distance, delta.dy / distance);
        var strength = repulsionStrength / (distance * distance);
        if (distance < minimumSeparation) {
          strength += (minimumSeparation - distance) * overlapRepulsionStrength;
        }

        final adjustment = direction * strength;
        deltas[leftIndex] -= adjustment;
        deltas[rightIndex] += adjustment;
      }
    }
  }

  void _applyEdgeForces({
    required Offset center,
    required String centerNodeId,
    required List<GraphEdge> edges,
    required List<_ForceNodePlacement> placements,
    required Map<String, int> placementIndexByNodeId,
    required List<Offset> deltas,
  }) {
    for (final edge in edges) {
      final sourceIndex = placementIndexByNodeId[edge.sourceId];
      final targetIndex = placementIndexByNodeId[edge.targetId];
      final touchesCenter =
          edge.sourceId == centerNodeId || edge.targetId == centerNodeId;

      if (touchesCenter) {
        final nodeIndex = sourceIndex ?? targetIndex;
        if (nodeIndex == null) {
          continue;
        }

        final placement = placements[nodeIndex];
        final vector = placement.position - center;
        final desiredDistance = placement.targetRadius;
        final distance = vector.distance;
        if (distance <= 0.001) {
          continue;
        }

        final direction = Offset(vector.dx / distance, vector.dy / distance);
        final springDelta =
            direction * ((desiredDistance - distance) * edgeSpringStrength);
        deltas[nodeIndex] += springDelta;
        continue;
      }

      if (sourceIndex == null || targetIndex == null) {
        continue;
      }

      final sourcePlacement = placements[sourceIndex];
      final targetPlacement = placements[targetIndex];
      final delta = targetPlacement.position - sourcePlacement.position;
      final distance = max(delta.distance, 0.001);
      final direction = Offset(delta.dx / distance, delta.dy / distance);
      final desiredDistance = nodeDiameter + minimumNodeGap + 36.0;
      final adjustment =
          direction * ((distance - desiredDistance) * edgeSpringStrength * 0.5);

      deltas[sourceIndex] += adjustment;
      deltas[targetIndex] -= adjustment;
    }
  }

  Offset _stabilizePosition({
    required Offset center,
    required Offset candidate,
    required double minCenterDistance,
    required double maxCenterDistance,
    required Size viewportSize,
    required double nodeHalf,
    required int? layoutSeed,
    required int index,
  }) {
    final minX = nodeHalf + viewportPadding;
    final maxX = max(minX, viewportSize.width - nodeHalf - viewportPadding);
    final minY = nodeHalf + viewportPadding;
    final maxY = max(minY, viewportSize.height - nodeHalf - viewportPadding);
    var stabilized = Offset(
      candidate.dx.clamp(minX, maxX).toDouble(),
      candidate.dy.clamp(minY, maxY).toDouble(),
    );
    final vector = stabilized - center;
    var distance = vector.distance;
    var direction = distance <= 0.001
        ? _seedDirection(layoutSeed: layoutSeed, index: index)
        : Offset(vector.dx / distance, vector.dy / distance);

    if (distance < minCenterDistance) {
      stabilized = center + direction * minCenterDistance;
    } else if (distance > maxCenterDistance) {
      stabilized = center + direction * maxCenterDistance;
    }

    stabilized = Offset(
      stabilized.dx.clamp(minX, maxX).toDouble(),
      stabilized.dy.clamp(minY, maxY).toDouble(),
    );
    distance = (stabilized - center).distance;
    if (distance <= 0.001) {
      direction = _seedDirection(layoutSeed: layoutSeed, index: index);
      stabilized = center + direction * minCenterDistance;
    }

    return stabilized;
  }

  Offset _initialPositionForIndex({
    required Offset center,
    required double targetRadius,
    required int index,
    required int totalNodeCount,
    required int shellCapacity,
    required int? layoutSeed,
  }) {
    final shellIndex = index ~/ shellCapacity;
    final orderOnShell = index % shellCapacity;
    final countOnShell = min(
      shellCapacity,
      totalNodeCount - shellIndex * shellCapacity,
    );
    final angleStep = 2 * pi / max(countOnShell, 1);
    final startAngle =
        _seedAngleOffset(layoutSeed: layoutSeed, shellIndex: shellIndex) -
        pi / 2;
    final angle = startAngle + angleStep * orderOnShell;

    return Offset(
      center.dx + targetRadius * cos(angle),
      center.dy + targetRadius * sin(angle),
    );
  }

  double _targetRadiusForIndex({
    required int index,
    required int shellCapacity,
    required double minCenterDistance,
    required double maxCenterDistance,
  }) {
    final shellIndex = index ~/ shellCapacity;
    final targetRadius = baseCenterDistance + shellSpacing * shellIndex;
    return targetRadius.clamp(minCenterDistance, maxCenterDistance).toDouble();
  }

  int _ringCapacity({required double radius, required double spacingPerNode}) {
    if (radius <= 0 || spacingPerNode <= 0) {
      return 1;
    }

    return max(1, (2 * pi * radius / spacingPerNode).floor());
  }

  double _maxViewportRadius({
    required Size viewportSize,
    required double nodeHalf,
  }) {
    final maxX = max(0.0, viewportSize.width / 2 - nodeHalf - viewportPadding);
    final maxY = max(0.0, viewportSize.height / 2 - nodeHalf - viewportPadding);
    return min(maxX, maxY);
  }

  Offset _clampOffset(Offset value, double maxDistance) {
    final distance = value.distance;
    if (distance <= maxDistance || distance <= 0.001) {
      return value;
    }

    final scale = maxDistance / distance;
    return Offset(value.dx * scale, value.dy * scale);
  }

  Offset _seedDirection({required int? layoutSeed, required int index}) {
    final angle = _seedAngleOffset(layoutSeed: layoutSeed, shellIndex: index);
    return Offset(cos(angle), sin(angle));
  }

  double _seedAngleOffset({required int? layoutSeed, required int shellIndex}) {
    if (layoutSeed == null) {
      return 0.0;
    }

    final mixedSeed =
        (layoutSeed ^ ((shellIndex + 1) * 0x9E3779B9)) & 0x7fffffff;
    if (mixedSeed == 0) {
      return 0.0;
    }

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
