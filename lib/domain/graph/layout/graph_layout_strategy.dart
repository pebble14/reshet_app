import 'dart:ui';

import '../graph_layout_result.dart';
import '../graph_view_data.dart';

/// graph_layout_strategy.dart
///
/// 그래프 뷰 데이터를 화면 좌표로 변환하는 레이아웃 전략 인터페이스다.
/// 같은 데이터에서 같은 seed를 주면 같은 배치가 나오도록 설계한다.
abstract interface class GraphLayoutStrategy {
  GraphLayoutResult layout(
    GraphViewData viewData,
    Size viewportSize, {
    int? layoutSeed,
  });
}
