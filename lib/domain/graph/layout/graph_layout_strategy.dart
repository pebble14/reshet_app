import 'dart:ui';

import '../graph_layout_result.dart';
import '../graph_view_data.dart';
import 'graph_layout_options.dart';

/// graph_layout_strategy.dart
///
/// 그래프 뷰 데이터를 viewport 독립 layout coordinate로 변환한다.
/// 같은 데이터와 options, seed를 주면 같은 배치가 나오도록 설계한다.
abstract interface class GraphLayoutStrategy {
  GraphLayoutResult layout(
    GraphViewData viewData, {
    GraphLayoutOptions options = const GraphLayoutOptions(),
    int? layoutSeed,
    Map<String, Offset> seedPositions = const <String, Offset>{},
  });
}
