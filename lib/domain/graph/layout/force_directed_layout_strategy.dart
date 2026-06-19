import 'dart:math';
import 'dart:ui';

import '../graph_edge.dart';
import '../graph_layout_result.dart';
import '../graph_node.dart';
import '../graph_view_data.dart';
import 'graph_layout_options.dart';
import 'graph_layout_strategy.dart';

class _ForceNodePlacement {
  final int index;
  final GraphNode node;
  final double targetRadius;
  final Offset? seedPosition;
  final double seedAnchorStrength;
  Offset position;

  _ForceNodePlacement({
    required this.index,
    required this.node,
    required this.targetRadius,
    required this.seedPosition,
    required this.seedAnchorStrength,
    required this.position,
  });
}

class ForceDirectedLayoutStrategy implements GraphLayoutStrategy {
  final double centerNodeDiameter;
  final double nodeDiameter;
  final double layoutSpacePadding;
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
  final double seedAnchorStrength;

  const ForceDirectedLayoutStrategy({
    this.centerNodeDiameter = 180.0,
    this.nodeDiameter = 80.0,
    this.layoutSpacePadding = 28.0,
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
    this.seedAnchorStrength = 0.16,
  });

  @override
  GraphLayoutResult layout(
    GraphViewData viewData, {
    GraphLayoutOptions options = const GraphLayoutOptions(),
    int? layoutSeed,
    Map<String, Offset> seedPositions = const <String, Offset>{},
  }) {
    final layoutSpaceSize = options.layoutSpaceSize;
    final center = Offset(
      layoutSpaceSize.width / 2,
      layoutSpaceSize.height / 2,
    );
    final positionedNodes = <String, Offset>{viewData.centerNodeId: center};
    final peripheralNodes =
        viewData.nodes
            .where((node) => node.id != viewData.centerNodeId)
            .toList(growable: false)
          ..sort(_compareNodes);
    final peripheralNodeCount = peripheralNodes.length;

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
    final maxLayoutSpaceRadius = _maxLayoutSpaceRadius(
      layoutSpaceSize: layoutSpaceSize,
      nodeHalf: nodeHalf,
    );
    final baseMaxCenterDistance = max(
      minCenterDistance,
      min(maximumCenterDistance, maxLayoutSpaceRadius),
    );
    final crowdingFactor = _crowdingFactor(peripheralNodeCount);
    final effectiveBaseCenterDistance =
        baseCenterDistance * (1.0 + crowdingFactor * 0.45);
    final effectiveShellSpacing = shellSpacing * (1.0 + crowdingFactor * 0.85);
    final baseShellCapacity = max(
      6,
      _ringCapacity(
        radius: min(effectiveBaseCenterDistance, baseMaxCenterDistance),
        spacingPerNode: nodeDiameter + minimumNodeGap,
      ),
    );
    final additionalRadius = crowdingFactor <= 0
        ? 0.0
        : min(
            maxLayoutSpaceRadius * crowdingFactor * 1.8,
            effectiveShellSpacing *
                (2.0 + peripheralNodeCount / max(baseShellCapacity, 1)),
          );
    final maxCenterDistance = baseMaxCenterDistance + additionalRadius;
    final shellCapacityRadius = crowdingFactor <= 0
        ? min(baseCenterDistance, maxCenterDistance)
        : min(
            maxCenterDistance,
            effectiveBaseCenterDistance + effectiveShellSpacing * 3.0,
          );
    final shellCapacity = max(
      6,
      _ringCapacity(
        radius: shellCapacityRadius,
        spacingPerNode: nodeDiameter + minimumNodeGap,
      ),
    );
    final effectiveLayoutSpaceOverflow =
        maxLayoutSpaceRadius * crowdingFactor * 1.8;
    final effectiveIterationCount =
        iterationCount + (crowdingFactor * 120).round();
    final effectiveRepulsionStrength =
        repulsionStrength * (1.0 + crowdingFactor * 1.4);
    final effectiveOverlapRepulsionStrength =
        overlapRepulsionStrength * (1.0 + crowdingFactor * 2.0);
    final effectiveEdgeSpringStrength =
        edgeSpringStrength * (1.0 - crowdingFactor * 0.25);
    final effectiveNonCenterDesiredDistance =
        nodeDiameter + minimumNodeGap + 36.0 + effectiveShellSpacing * 0.28;
    final effectiveMaxStepDistance =
        maxStepDistance * (1.0 + crowdingFactor * 0.45);
    final effectiveMinimumSeparation =
        (nodeDiameter + minimumNodeGap) * (1.0 + crowdingFactor * 0.16);
    final deOverlapPassCount = 1 + (crowdingFactor * 4).round();
    final placements = <_ForceNodePlacement>[];
    final depthCounts = <int, int>{};

    for (var index = 0; index < peripheralNodes.length; index++) {
      final node = peripheralNodes[index];
      final depthOrderIndex = depthCounts.update(
        node.depth,
        (count) => count + 1,
        ifAbsent: () => 0,
      );
      final targetRadius = _targetRadiusForNode(
        node: node,
        depthOrderIndex: depthOrderIndex,
        shellCapacity: shellCapacity,
        minCenterDistance: minCenterDistance,
        maxCenterDistance: maxCenterDistance,
        baseCenterDistance: effectiveBaseCenterDistance,
        shellSpacing: effectiveShellSpacing,
      );
      final seedPosition = seedPositions[node.id];
      placements.add(
        _ForceNodePlacement(
          index: index,
          node: node,
          targetRadius: targetRadius,
          seedPosition: seedPosition,
          seedAnchorStrength: seedPosition == null
              ? 0.0
              : (node.depth <= 1
                    ? seedAnchorStrength
                    : seedAnchorStrength * 0.72),
          position: _stabilizePosition(
            center: center,
            candidate: _initialPositionForNode(
              center: center,
              targetRadius: targetRadius,
              node: node,
              index: index,
              depthOrderIndex: depthOrderIndex,
              totalNodeCount: peripheralNodes.length,
              shellCapacity: shellCapacity,
              layoutSeed: layoutSeed,
              seedPositions: seedPositions,
              shellSpacing: effectiveShellSpacing,
              crowdingFactor: crowdingFactor,
            ),
            minCenterDistance: minCenterDistance,
            maxCenterDistance: maxCenterDistance,
            layoutSpaceSize: layoutSpaceSize,
            nodeHalf: nodeHalf,
            layoutSeed: layoutSeed,
            index: index,
            layoutSpaceOverflow: effectiveLayoutSpaceOverflow,
          ),
        ),
      );
    }

    final placementIndexByNodeId = <String, int>{
      for (var index = 0; index < placements.length; index++)
        placements[index].node.id: index,
    };

    for (var iteration = 0; iteration < effectiveIterationCount; iteration++) {
      final deltas = List<Offset>.filled(placements.length, Offset.zero);
      final cooling = 1.0 - (iteration / max(effectiveIterationCount, 1));
      final stepLimit = max(
        1.2,
        effectiveMaxStepDistance * (0.38 + cooling * 0.62),
      );

      _applyCenterBias(
        center: center,
        placements: placements,
        deltas: deltas,
        minCenterDistance: minCenterDistance,
        maxCenterDistance: maxCenterDistance,
        layoutSeed: layoutSeed,
      );
      _applySeedBias(placements: placements, deltas: deltas);
      _applyNodeRepulsion(
        placements: placements,
        deltas: deltas,
        minimumSeparation: effectiveMinimumSeparation,
        repulsionStrength: effectiveRepulsionStrength,
        overlapRepulsionStrength: effectiveOverlapRepulsionStrength,
        layoutSeed: layoutSeed,
      );
      _applyEdgeForces(
        center: center,
        centerNodeId: viewData.centerNodeId,
        edges: viewData.edges,
        placements: placements,
        placementIndexByNodeId: placementIndexByNodeId,
        deltas: deltas,
        nonCenterDesiredDistance: effectiveNonCenterDesiredDistance,
        edgeSpringStrength: effectiveEdgeSpringStrength,
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
          layoutSpaceSize: layoutSpaceSize,
          nodeHalf: nodeHalf,
          layoutSeed: layoutSeed,
          index: placements[index].index,
          layoutSpaceOverflow: effectiveLayoutSpaceOverflow,
        );
      }

      if (!moved) {
        break;
      }
    }

    _applyPostLayoutDeOverlap(
      center: center,
      placements: placements,
      minimumSeparation: effectiveMinimumSeparation,
      passCount: deOverlapPassCount,
      minCenterDistance: minCenterDistance,
      maxCenterDistance: maxCenterDistance,
      layoutSpaceSize: layoutSpaceSize,
      nodeHalf: nodeHalf,
      layoutSeed: layoutSeed,
      layoutSpaceOverflow: effectiveLayoutSpaceOverflow,
      stepLimit: max(4.0, effectiveMaxStepDistance * 0.82),
    );

    for (final placement in placements) {
      positionedNodes[placement.node.id] = placement.position;
    }

    return GraphLayoutResult(
      positionedNodes: positionedNodes,
      edges: viewData.edges,
      bounds: _computeBounds(positionedNodes.values),
    );
  }

  void _applySeedBias({
    required List<_ForceNodePlacement> placements,
    required List<Offset> deltas,
  }) {
    for (var index = 0; index < placements.length; index++) {
      final placement = placements[index];
      final seedPosition = placement.seedPosition;
      if (seedPosition == null || placement.seedAnchorStrength <= 0) {
        continue;
      }

      final vector = seedPosition - placement.position;
      deltas[index] += vector * placement.seedAnchorStrength;
    }
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
    required double minimumSeparation,
    required double repulsionStrength,
    required double overlapRepulsionStrength,
    required int? layoutSeed,
  }) {
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

        final direction = distance <= 0.001
            ? _pairDirection(
                leftPlacement: leftPlacement,
                rightPlacement: rightPlacement,
                layoutSeed: layoutSeed,
              )
            : Offset(delta.dx / distance, delta.dy / distance);
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
    required double nonCenterDesiredDistance,
    required double edgeSpringStrength,
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
      final adjustment =
          direction *
          ((distance - nonCenterDesiredDistance) * edgeSpringStrength * 0.5);

      deltas[sourceIndex] += adjustment;
      deltas[targetIndex] -= adjustment;
    }
  }

  Offset _stabilizePosition({
    required Offset center,
    required Offset candidate,
    required double minCenterDistance,
    required double maxCenterDistance,
    required Size layoutSpaceSize,
    required double nodeHalf,
    required int? layoutSeed,
    required int index,
    required double layoutSpaceOverflow,
  }) {
    final minX = nodeHalf + layoutSpacePadding - layoutSpaceOverflow;
    final maxX = max(
      minX,
      layoutSpaceSize.width -
          nodeHalf -
          layoutSpacePadding +
          layoutSpaceOverflow,
    );
    final minY = nodeHalf + layoutSpacePadding - layoutSpaceOverflow;
    final maxY = max(
      minY,
      layoutSpaceSize.height -
          nodeHalf -
          layoutSpacePadding +
          layoutSpaceOverflow,
    );
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

  Offset _initialPositionForNode({
    required Offset center,
    required double targetRadius,
    required GraphNode node,
    required int index,
    required int depthOrderIndex,
    required int totalNodeCount,
    required int shellCapacity,
    required int? layoutSeed,
    required Map<String, Offset> seedPositions,
    required double shellSpacing,
    required double crowdingFactor,
  }) {
    final seededPosition = seedPositions[node.id];
    if (seededPosition != null) {
      return seededPosition;
    }

    if (node.depth >= 2) {
      final sourceId = node.expansionSourceId;
      final sourcePosition = sourceId == null ? null : seedPositions[sourceId];
      if (sourcePosition != null) {
        final sourceVector = sourcePosition - center;
        final sourceDistance = sourceVector.distance;
        final radialDirection = sourceDistance <= 0.001
            ? _seedDirection(layoutSeed: layoutSeed, index: index)
            : Offset(
                sourceVector.dx / sourceDistance,
                sourceVector.dy / sourceDistance,
              );
        final tangentialDirection = Offset(
          -radialDirection.dy,
          radialDirection.dx,
        );
        final crowdedOrbitLayout =
            crowdingFactor > 0.18 ||
            totalNodeCount > max(shellCapacity, 24) ||
            depthOrderIndex >= 6;
        if (crowdedOrbitLayout) {
          final orbitCapacity = max(8, min(shellCapacity, 18));
          final orbitShellIndex = depthOrderIndex ~/ orbitCapacity;
          final orbitSlotIndex = depthOrderIndex % orbitCapacity;
          final orbitDistance =
              max(nodeDiameter + minimumNodeGap + 18.0, shellSpacing * 0.92) +
              orbitShellIndex * max(nodeDiameter * 0.9, shellSpacing * 0.74);
          final orbitAngle =
              atan2(radialDirection.dy, radialDirection.dx) +
              _seedAngleOffset(
                layoutSeed: layoutSeed,
                shellIndex: orbitShellIndex,
              ) +
              (2 * pi / orbitCapacity) * orbitSlotIndex;
          return sourcePosition +
              Offset(cos(orbitAngle), sin(orbitAngle)) * orbitDistance;
        }

        final orbitDistance = max(
          nodeDiameter + minimumNodeGap + 18.0,
          shellSpacing * 0.92,
        );
        final lateralTier = (depthOrderIndex / 2).floor();
        final lateralDistance = min(
          nodeDiameter * 1.15,
          lateralTier * (nodeDiameter * 0.55),
        );
        final lateralSign = depthOrderIndex.isEven ? 1.0 : -1.0;
        return sourcePosition +
            radialDirection * orbitDistance +
            tangentialDirection * lateralDistance * lateralSign;
      }
    }

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

  double _targetRadiusForNode({
    required GraphNode node,
    required int depthOrderIndex,
    required int shellCapacity,
    required double minCenterDistance,
    required double maxCenterDistance,
    required double baseCenterDistance,
    required double shellSpacing,
  }) {
    final baseShellIndex = max(0, node.depth - 1);
    final shellIndex = depthOrderIndex ~/ shellCapacity;
    final targetRadius =
        baseCenterDistance + shellSpacing * (baseShellIndex + shellIndex);
    return targetRadius.clamp(minCenterDistance, maxCenterDistance).toDouble();
  }

  int _ringCapacity({required double radius, required double spacingPerNode}) {
    if (radius <= 0 || spacingPerNode <= 0) {
      return 1;
    }

    return max(1, (2 * pi * radius / spacingPerNode).floor());
  }

  double _maxLayoutSpaceRadius({
    required Size layoutSpaceSize,
    required double nodeHalf,
  }) {
    final maxX = max(
      0.0,
      layoutSpaceSize.width / 2 - nodeHalf - layoutSpacePadding,
    );
    final maxY = max(
      0.0,
      layoutSpaceSize.height / 2 - nodeHalf - layoutSpacePadding,
    );
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

  Offset _pairDirection({
    required _ForceNodePlacement leftPlacement,
    required _ForceNodePlacement rightPlacement,
    required int? layoutSeed,
  }) {
    final mixedIndex =
        leftPlacement.index * 131 + rightPlacement.index * 17 + 0x9e3779;
    return _seedDirection(layoutSeed: layoutSeed, index: mixedIndex);
  }

  void _applyPostLayoutDeOverlap({
    required Offset center,
    required List<_ForceNodePlacement> placements,
    required double minimumSeparation,
    required int passCount,
    required double minCenterDistance,
    required double maxCenterDistance,
    required Size layoutSpaceSize,
    required double nodeHalf,
    required int? layoutSeed,
    required double layoutSpaceOverflow,
    required double stepLimit,
  }) {
    if (placements.length < 2 || passCount <= 0) {
      return;
    }

    for (var pass = 0; pass < passCount; pass++) {
      final deltas = List<Offset>.filled(placements.length, Offset.zero);
      var moved = false;

      for (var leftIndex = 0; leftIndex < placements.length; leftIndex++) {
        final leftPlacement = placements[leftIndex];
        for (
          var rightIndex = leftIndex + 1;
          rightIndex < placements.length;
          rightIndex++
        ) {
          final rightPlacement = placements[rightIndex];
          final delta = rightPlacement.position - leftPlacement.position;
          final distance = delta.distance;
          if (distance >= minimumSeparation) {
            continue;
          }

          final direction = distance <= 0.001
              ? _pairDirection(
                  leftPlacement: leftPlacement,
                  rightPlacement: rightPlacement,
                  layoutSeed: layoutSeed,
                )
              : Offset(delta.dx / distance, delta.dy / distance);
          final pushDistance = (minimumSeparation - distance) * 0.52;
          final adjustment = direction * pushDistance;
          deltas[leftIndex] -= adjustment;
          deltas[rightIndex] += adjustment;
          moved = true;
        }
      }

      if (!moved) {
        break;
      }

      for (var index = 0; index < placements.length; index++) {
        placements[index].position = _stabilizePosition(
          center: center,
          candidate:
              placements[index].position +
              _clampOffset(deltas[index], stepLimit),
          minCenterDistance: minCenterDistance,
          maxCenterDistance: maxCenterDistance,
          layoutSpaceSize: layoutSpaceSize,
          nodeHalf: nodeHalf,
          layoutSeed: layoutSeed,
          index: placements[index].index,
          layoutSpaceOverflow: layoutSpaceOverflow,
        );
      }
    }
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

  double _crowdingFactor(int peripheralNodeCount) {
    if (peripheralNodeCount <= 18) {
      return 0.0;
    }

    return ((peripheralNodeCount - 18) / 96).clamp(0.0, 1.0);
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
}
