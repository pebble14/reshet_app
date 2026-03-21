/// graph_build_options.dart
///
/// 그래프 빌드 단계에서 사용하는 입력 옵션이다.
/// foundation 단계에서는 1-hop 그래프를 기본값으로 둔다.
enum GraphLayoutMode { radial }

class GraphBuildOptions {
  final String centerWordId;
  final int maxDepth;
  final int maxNodes;
  final GraphLayoutMode layoutMode;
  final List<String>? includeRelationTypes;
  final List<String>? includeStatusCodes;

  GraphBuildOptions({
    required this.centerWordId,
    this.maxDepth = 1,
    this.maxNodes = 30,
    this.layoutMode = GraphLayoutMode.radial,
    Iterable<String>? includeRelationTypes,
    Iterable<String>? includeStatusCodes,
  }) : assert(maxDepth >= 0),
       assert(maxNodes > 0),
       includeRelationTypes = _normalizeFilterValues(includeRelationTypes),
       includeStatusCodes = _normalizeFilterValues(includeStatusCodes);

  static List<String>? _normalizeFilterValues(Iterable<String>? values) {
    if (values == null) return null;

    final normalized =
        values
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    if (normalized.isEmpty) {
      return null;
    }

    return List.unmodifiable(normalized);
  }

  bool allowsRelationType(String? relationType) {
    final filters = includeRelationTypes;
    if (filters == null || filters.isEmpty) return true;
    return filters.contains((relationType ?? '').trim());
  }

  bool allowsStatusCode(String? statusCode) {
    final filters = includeStatusCodes;
    if (filters == null || filters.isEmpty) return true;
    return filters.contains((statusCode ?? '').trim());
  }

  GraphBuildOptions copyWith({
    String? centerWordId,
    int? maxDepth,
    int? maxNodes,
    GraphLayoutMode? layoutMode,
    Iterable<String>? includeRelationTypes,
    bool clearRelationTypes = false,
    Iterable<String>? includeStatusCodes,
    bool clearStatusCodes = false,
  }) {
    return GraphBuildOptions(
      centerWordId: centerWordId ?? this.centerWordId,
      maxDepth: maxDepth ?? this.maxDepth,
      maxNodes: maxNodes ?? this.maxNodes,
      layoutMode: layoutMode ?? this.layoutMode,
      includeRelationTypes: clearRelationTypes
          ? null
          : (includeRelationTypes ?? this.includeRelationTypes),
      includeStatusCodes: clearStatusCodes
          ? null
          : (includeStatusCodes ?? this.includeStatusCodes),
    );
  }
}
