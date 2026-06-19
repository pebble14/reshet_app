import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/domain/graph/graph_build_options.dart';
import 'package:reshet_app/domain/graph/graph_edge.dart';
import 'package:reshet_app/domain/graph/graph_node.dart';
import 'package:reshet_app/domain/graph/graph_view_data.dart';
import 'package:reshet_app/domain/graph/layout/graph_layout_cache.dart';
import 'package:reshet_app/domain/graph/layout/graph_layout_options.dart';
import 'package:reshet_app/domain/graph/layout/graph_layout_strategy_resolver.dart';

void main() {
  const layoutOptions = GraphLayoutOptions(layoutSpaceSize: Size(1200, 900));
  final viewData = GraphViewData(
    centerNodeId: 'center',
    nodes: [
      GraphNode(wordId: 'center', label: '중심', depth: 0, isCenter: true),
      GraphNode(
        wordId: 'alpha',
        label: '알파',
        depth: 1,
        isCenter: false,
        weight: 2,
      ),
      GraphNode(wordId: 'beta', label: '베타', depth: 1, isCenter: false),
      GraphNode(
        wordId: 'gamma',
        label: '감마',
        depth: 2,
        isCenter: false,
        expansionSourceId: 'alpha',
      ),
    ],
    edges: [
      GraphEdge(sourceId: 'center', targetId: 'alpha', relationId: 1),
      GraphEdge(sourceId: 'center', targetId: 'beta', relationId: 2),
      GraphEdge(sourceId: 'alpha', targetId: 'gamma', relationId: 3),
    ],
  );
  const seedPositions = <String, Offset>{
    'alpha': Offset(760, 370),
    'gamma': Offset(880, 430),
  };

  setUp(GraphLayoutCache.clear);

  for (final layoutMode in GraphLayoutMode.values) {
    test('$layoutMode layout은 같은 canonical 입력에서 같은 좌표를 계산한다', () {
      final first = GraphLayoutStrategyResolver.layout(
        layoutMode: layoutMode,
        viewData: viewData,
        options: layoutOptions,
        layoutSeed: 2303,
        seedPositions: seedPositions,
      );

      GraphLayoutCache.clear();

      final second = GraphLayoutStrategyResolver.layout(
        layoutMode: layoutMode,
        viewData: viewData,
        options: layoutOptions,
        layoutSeed: 2303,
        seedPositions: seedPositions,
      );

      expect(second.positionedNodes, equals(first.positionedNodes));
      expect(second.bounds, first.bounds);
      expect(
        second.positionFor(viewData.centerNodeId),
        layoutOptions.layoutSpaceSize.center(Offset.zero),
      );
    });
  }

  test('layout cache는 actual viewport가 아닌 canonical layout identity를 사용한다', () {
    final first = GraphLayoutStrategyResolver.layout(
      layoutMode: GraphLayoutMode.forceDirected,
      viewData: viewData,
      options: layoutOptions,
      layoutSeed: 2303,
      seedPositions: seedPositions,
    );
    final cached = GraphLayoutStrategyResolver.layout(
      layoutMode: GraphLayoutMode.forceDirected,
      viewData: viewData,
      options: layoutOptions,
      layoutSeed: 2303,
      seedPositions: seedPositions,
    );
    final differentCanonicalSpace = GraphLayoutStrategyResolver.layout(
      layoutMode: GraphLayoutMode.forceDirected,
      viewData: viewData,
      options: const GraphLayoutOptions(layoutSpaceSize: Size(1000, 700)),
      layoutSeed: 2303,
      seedPositions: seedPositions,
    );

    expect(identical(cached, first), isTrue);
    expect(identical(differentCanonicalSpace, first), isFalse);
  });
}
