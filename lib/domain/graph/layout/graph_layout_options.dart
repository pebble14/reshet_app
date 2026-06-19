import 'dart:ui';

/// 실제 화면 크기와 독립적인 graph layout coordinate 계산 옵션이다.
class GraphLayoutOptions {
  static const Size defaultLayoutSpaceSize = Size(800, 600);

  final Size layoutSpaceSize;

  const GraphLayoutOptions({this.layoutSpaceSize = defaultLayoutSpaceSize});
}
