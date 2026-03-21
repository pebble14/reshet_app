import 'dart:math';
import 'dart:ui';

import '../graph_layout_result.dart';
import '../graph_node.dart';
import '../graph_view_data.dart';
import 'graph_layout_strategy.dart';

class _MutableNodePlacement {
  final int index;
  final int ringIndex;
  final int orderOnRing;
  final double baseAngle;
  final double baseRadius;
  final double minRadius;
  final double maxRadius;
  final double maxAngleShift;
  double angle;
  double radius;

  _MutableNodePlacement({
    required this.index,
    required this.ringIndex,
    required this.orderOnRing,
    required this.baseAngle,
    required this.baseRadius,
    required this.minRadius,
    required this.maxRadius,
    required this.maxAngleShift,
  }) : angle = baseAngle,
       radius = baseRadius;

  double get minAngle => baseAngle - maxAngleShift;

  double get maxAngle => baseAngle + maxAngleShift;
}

/// radial_layout_strategy.dart
///
/// 중심 노드를 화면 중앙에 두고, 화면 크기와 노드 수에 따라
/// 방사형 배치를 안정적으로 계산하는 기본 레이아웃 전략이다.
class RadialLayoutStrategy implements GraphLayoutStrategy {
  final double centerNodeDiameter;
  final double nodeDiameter;
  final double viewportPadding;
  final double preferredNodeGap;
  final double minimumNodeGap;
  final double preferredCenterGap;
  final double minimumCenterGap;
  final double ringSpacing;
  final int overlapAdjustmentPasses;
  final double maxAngleShift;
  final double maxRadialShift;
  final double crossRingNodeGap;

  const RadialLayoutStrategy({
    this.centerNodeDiameter = 180.0,
    this.nodeDiameter = 80.0,
    this.viewportPadding = 28.0,
    this.preferredNodeGap = 28.0,
    this.minimumNodeGap = 12.0,
    this.preferredCenterGap = 18.0,
    this.minimumCenterGap = 8.0,
    this.ringSpacing = 92.0,
    this.overlapAdjustmentPasses = 6,
    this.maxAngleShift = pi / 18,
    this.maxRadialShift = 12.0,
    this.crossRingNodeGap = 6.0,
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
    final availableRadiusX = max(
      0.0,
      viewportSize.width / 2 - nodeHalf - viewportPadding,
    );
    final availableRadiusY = max(
      0.0,
      viewportSize.height / 2 - nodeHalf - viewportPadding,
    );
    final maxRadius = max(0.0, min(availableRadiusX, availableRadiusY));
    final preferredMinimumRadius = centerHalf + nodeHalf + preferredCenterGap;
    final minimumInnerRadius = centerHalf + nodeHalf + minimumCenterGap;
    final preferredSpacing = nodeDiameter + preferredNodeGap;
    final minimumSpacing = nodeDiameter + minimumNodeGap;
    final preferredSingleRingRadius = max(
      preferredMinimumRadius,
      _requiredRingRadius(peripheralNodes.length, preferredSpacing),
    );
    final singleRingCapacity = _ringCapacity(maxRadius, minimumSpacing);

    List<double> ringRadii;
    if (maxRadius <= 0) {
      ringRadii = const [0.0];
    } else if (preferredSingleRingRadius <= maxRadius ||
        peripheralNodes.length <= singleRingCapacity) {
      ringRadii = [
        preferredSingleRingRadius <= maxRadius
            ? preferredSingleRingRadius
            : maxRadius,
      ];
    } else {
      ringRadii = _buildRingRadii(
        nodeCount: peripheralNodes.length,
        maxRadius: maxRadius,
        innerRadiusFloor: min(maxRadius, minimumInnerRadius),
        minimumSpacing: minimumSpacing,
      );
      if (ringRadii.length == 1) {
        ringRadii = [maxRadius];
      }
    }

    final nodeCounts = _distributeNodesAcrossRings(
      peripheralNodes.length,
      ringRadii,
      minimumSpacing,
    );
    final placements = <_MutableNodePlacement>[];
    var nextIndex = 0;

    for (var ringIndex = 0; ringIndex < ringRadii.length; ringIndex++) {
      final radius = ringRadii[ringIndex];
      final countOnRing = nodeCounts[ringIndex];
      if (countOnRing <= 0) continue;

      final angleStep = 2 * pi / countOnRing;
      final ringSeedOffset = _seedAngleOffset(
        layoutSeed: layoutSeed,
        ringIndex: ringIndex,
      );
      final ringStartAngle =
          -pi / 2 +
          ringSeedOffset +
          ((ringIndex.isOdd && countOnRing > 1) ? angleStep / 2 : 0.0);
      final ringMaxAngleShift = countOnRing <= 1
          ? 0.0
          : min(maxAngleShift, angleStep * 0.28);
      final minRadius = ringIndex == 0
          ? radius
          : max(minimumInnerRadius, radius - maxRadialShift);
      final maxRadiusForRing = min(maxRadius, radius + maxRadialShift);

      for (
        var localIndex = 0;
        localIndex < countOnRing && nextIndex < peripheralNodes.length;
        localIndex++, nextIndex++
      ) {
        placements.add(
          _MutableNodePlacement(
            index: nextIndex,
            ringIndex: ringIndex,
            orderOnRing: localIndex,
            baseAngle: ringStartAngle + angleStep * localIndex,
            baseRadius: radius,
            minRadius: minRadius,
            maxRadius: maxRadiusForRing,
            maxAngleShift: ringMaxAngleShift,
          ),
        );
      }
    }

    _applyNodeOverlapReduction(center: center, placements: placements);

    for (final placement in placements) {
      final node = peripheralNodes[placement.index];
      positionedNodes[node.id] = _polarOffset(
        center: center,
        radius: placement.radius,
        angle: placement.angle,
      );
    }

    return GraphLayoutResult(
      positionedNodes: positionedNodes,
      edges: viewData.edges,
      bounds: _computeBounds(positionedNodes.values),
    );
  }

  List<double> _buildRingRadii({
    required int nodeCount,
    required double maxRadius,
    required double innerRadiusFloor,
    required double minimumSpacing,
  }) {
    final radiiDescending = <double>[maxRadius];
    var totalCapacity = _ringCapacity(maxRadius, minimumSpacing);
    var nextRadius = maxRadius - ringSpacing;

    while (totalCapacity < nodeCount && nextRadius >= innerRadiusFloor) {
      radiiDescending.add(nextRadius);
      totalCapacity += _ringCapacity(nextRadius, minimumSpacing);
      nextRadius -= ringSpacing;
    }

    if (totalCapacity < nodeCount) {
      return [maxRadius];
    }

    return radiiDescending.reversed.toList(growable: false);
  }

  List<int> _distributeNodesAcrossRings(
    int nodeCount,
    List<double> ringRadii,
    double minimumSpacing,
  ) {
    if (ringRadii.isEmpty) return const [];
    if (ringRadii.length == 1) return [nodeCount];

    final capacities = ringRadii
        .map((radius) => max(1, _ringCapacity(radius, minimumSpacing)))
        .toList(growable: false);
    final counts = List<int>.filled(ringRadii.length, 0);

    for (var nodeIndex = 0; nodeIndex < nodeCount; nodeIndex++) {
      var targetRing = 0;
      var targetLoad = double.infinity;

      for (var ringIndex = 0; ringIndex < capacities.length; ringIndex++) {
        final load = counts[ringIndex] / capacities[ringIndex];
        if (load < targetLoad) {
          targetLoad = load;
          targetRing = ringIndex;
        }
      }

      counts[targetRing]++;
    }

    return counts;
  }

  int _ringCapacity(double radius, double spacingPerNode) {
    if (radius <= 0 || spacingPerNode <= 0) return 1;
    return max(1, (2 * pi * radius / spacingPerNode).floor());
  }

  double _requiredRingRadius(int nodeCount, double spacingPerNode) {
    if (nodeCount <= 0 || spacingPerNode <= 0) return 0.0;
    return nodeCount * spacingPerNode / (2 * pi);
  }

  void _applyNodeOverlapReduction({
    required Offset center,
    required List<_MutableNodePlacement> placements,
  }) {
    if (placements.length < 2) return;

    for (var pass = 0; pass < overlapAdjustmentPasses; pass++) {
      final angleDelta = List<double>.filled(placements.length, 0.0);
      final radiusDelta = List<double>.filled(placements.length, 0.0);
      final positions = placements
          .map(
            (placement) => _polarOffset(
              center: center,
              radius: placement.radius,
              angle: placement.angle,
            ),
          )
          .toList(growable: false);

      var foundOverlap = false;

      for (var i = 0; i < placements.length; i++) {
        final leftPlacement = placements[i];

        for (var j = i + 1; j < placements.length; j++) {
          final rightPlacement = placements[j];
          if ((leftPlacement.ringIndex - rightPlacement.ringIndex).abs() > 1) {
            continue;
          }

          final desiredDistance = _desiredNodeDistance(
            leftPlacement,
            rightPlacement,
          );
          final dx = positions[j].dx - positions[i].dx;
          final dy = positions[j].dy - positions[i].dy;
          final distance = sqrt(dx * dx + dy * dy);
          if (distance >= desiredDistance) continue;

          foundOverlap = true;
          final safeDistance = distance <= 0.001 ? 0.001 : distance;
          final pushDistance = (desiredDistance - safeDistance) * 0.5;
          final direction = Offset(dx / safeDistance, dy / safeDistance);
          final sameRing = leftPlacement.ringIndex == rightPlacement.ringIndex;

          _accumulateNodeRepulsion(
            center: center,
            placement: leftPlacement,
            currentPosition: positions[i],
            pushDirection: Offset(-direction.dx, -direction.dy),
            pushDistance: pushDistance,
            sameRing: sameRing,
            angleDelta: angleDelta,
            radiusDelta: radiusDelta,
            targetIndex: i,
          );
          _accumulateNodeRepulsion(
            center: center,
            placement: rightPlacement,
            currentPosition: positions[j],
            pushDirection: direction,
            pushDistance: pushDistance,
            sameRing: sameRing,
            angleDelta: angleDelta,
            radiusDelta: radiusDelta,
            targetIndex: j,
          );
        }
      }

      if (!foundOverlap) {
        break;
      }

      for (var i = 0; i < placements.length; i++) {
        final placement = placements[i];
        placement.radius = (placement.radius + radiusDelta[i].clamp(-4.0, 4.0))
            .clamp(placement.minRadius, placement.maxRadius)
            .toDouble();
        placement.angle = (placement.angle + angleDelta[i].clamp(-0.045, 0.045))
            .clamp(placement.minAngle, placement.maxAngle)
            .toDouble();
      }

      _enforceRingOrder(placements);
    }
  }

  double _desiredNodeDistance(
    _MutableNodePlacement leftPlacement,
    _MutableNodePlacement rightPlacement,
  ) {
    final gap = leftPlacement.ringIndex == rightPlacement.ringIndex
        ? minimumNodeGap
        : crossRingNodeGap;
    return nodeDiameter + gap;
  }

  void _accumulateNodeRepulsion({
    required Offset center,
    required _MutableNodePlacement placement,
    required Offset currentPosition,
    required Offset pushDirection,
    required double pushDistance,
    required bool sameRing,
    required List<double> angleDelta,
    required List<double> radiusDelta,
    required int targetIndex,
  }) {
    final vx = currentPosition.dx - center.dx;
    final vy = currentPosition.dy - center.dy;
    final vectorLength = sqrt(vx * vx + vy * vy);
    final safeLength = vectorLength <= 0.001 ? 1.0 : vectorLength;
    final radial = Offset(vx / safeLength, vy / safeLength);
    final tangential = Offset(-radial.dy, radial.dx);
    final radialComponent =
        pushDirection.dx * radial.dx + pushDirection.dy * radial.dy;
    final tangentialComponent =
        pushDirection.dx * tangential.dx + pushDirection.dy * tangential.dy;
    final radialWeight = sameRing ? 0.28 : 0.48;
    final angularWeight = sameRing ? 0.82 : 0.45;

    radiusDelta[targetIndex] += radialComponent * pushDistance * radialWeight;
    angleDelta[targetIndex] +=
        tangentialComponent *
        pushDistance *
        angularWeight /
        max(placement.radius, 1.0);
  }

  void _enforceRingOrder(List<_MutableNodePlacement> placements) {
    final placementsByRing = <int, List<_MutableNodePlacement>>{};
    for (final placement in placements) {
      placementsByRing
          .putIfAbsent(placement.ringIndex, () => <_MutableNodePlacement>[])
          .add(placement);
    }

    for (final ringPlacements in placementsByRing.values) {
      ringPlacements.sort((left, right) {
        return left.orderOnRing.compareTo(right.orderOnRing);
      });

      var previousAngle = -double.infinity;
      for (final placement in ringPlacements) {
        final minAllowedAngle = max(placement.minAngle, previousAngle + 0.001);
        placement.angle =
            (minAllowedAngle > placement.maxAngle
                    ? placement.maxAngle
                    : placement.angle.clamp(
                        minAllowedAngle,
                        placement.maxAngle,
                      ))
                .toDouble();
        previousAngle = placement.angle;
      }

      var nextAngle = double.infinity;
      for (final placement in ringPlacements.reversed) {
        final maxAllowedAngle = min(placement.maxAngle, nextAngle - 0.001);
        placement.angle =
            (placement.minAngle > maxAllowedAngle
                    ? placement.minAngle
                    : placement.angle.clamp(
                        placement.minAngle,
                        maxAllowedAngle,
                      ))
                .toDouble();
        nextAngle = placement.angle;
      }
    }
  }

  Offset _polarOffset({
    required Offset center,
    required double radius,
    required double angle,
  }) {
    return Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );
  }

  double _seedAngleOffset({required int? layoutSeed, required int ringIndex}) {
    if (layoutSeed == null) return 0.0;

    final mixedSeed =
        (layoutSeed ^ ((ringIndex + 1) * 0x9E3779B9)) & 0x7fffffff;
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
