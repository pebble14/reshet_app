import 'dart:ui';

import '../graph_build_options.dart';
import '../graph_layout_result.dart';
import '../graph_view_data.dart';
import 'force_directed_layout_strategy.dart';
import 'graph_layout_strategy.dart';
import 'radial_layout_strategy.dart';

class GraphLayoutStrategyResolver {
  static const GraphLayoutStrategy _radialStrategy = RadialLayoutStrategy();
  static const GraphLayoutStrategy _forceDirectedStrategy =
      _FallbackGraphLayoutStrategy(
        primary: ForceDirectedLayoutStrategy(),
        fallback: _radialStrategy,
      );
  static const Map<GraphLayoutMode, GraphLayoutStrategy> _strategies = {
    GraphLayoutMode.radial: _radialStrategy,
    GraphLayoutMode.forceDirected: _forceDirectedStrategy,
  };

  const GraphLayoutStrategyResolver._();

  static GraphLayoutStrategy resolve(GraphLayoutMode layoutMode) {
    return _strategies[layoutMode] ?? _radialStrategy;
  }
}

class _FallbackGraphLayoutStrategy implements GraphLayoutStrategy {
  final GraphLayoutStrategy primary;
  final GraphLayoutStrategy fallback;

  const _FallbackGraphLayoutStrategy({
    required this.primary,
    required this.fallback,
  });

  @override
  GraphLayoutResult layout(
    GraphViewData viewData,
    Size viewportSize, {
    int? layoutSeed,
  }) {
    try {
      final result = primary.layout(
        viewData,
        viewportSize,
        layoutSeed: layoutSeed,
      );
      if (_isUsable(result, viewData)) {
        return result;
      }
    } catch (_) {}

    return fallback.layout(viewData, viewportSize, layoutSeed: layoutSeed);
  }

  bool _isUsable(GraphLayoutResult result, GraphViewData viewData) {
    if (result.positionFor(viewData.centerNodeId) == null) {
      return false;
    }

    for (final node in viewData.nodes) {
      if (result.positionFor(node.id) == null) {
        return false;
      }
    }

    return true;
  }
}
