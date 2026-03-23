/// graph_edge.dart
///
/// 그래프 엔진에서 노드 사이의 관계선을 표현하는 도메인 모델이다.
/// `id`는 relationId를 우선 사용하고, 없을 때만 wordId 조합으로 생성한다.
class GraphEdge {
  final String id;
  final String sourceId;
  final String targetId;
  final int? relationId;
  final String? relationType;
  final String? categoryCode;
  final String? statusCode;
  final String? directionCode;
  final String? description;
  final double weight;
  final bool isHighlighted;

  GraphEdge({
    required this.sourceId,
    required this.targetId,
    this.relationId,
    this.relationType,
    this.categoryCode,
    this.statusCode,
    this.directionCode,
    this.description,
    this.weight = 1.0,
    this.isHighlighted = false,
  }) : id =
           relationId?.toString() ??
           _fallbackId(
             sourceId,
             targetId,
             relationType: relationType,
             categoryCode: categoryCode,
           );

  static String _fallbackId(
    String sourceId,
    String targetId, {
    String? relationType,
    String? categoryCode,
  }) {
    final minWordId = sourceId.compareTo(targetId) <= 0 ? sourceId : targetId;
    final maxWordId = sourceId.compareTo(targetId) <= 0 ? targetId : sourceId;
    final normalizedRelationType = (relationType ?? '').trim();
    final normalizedCategoryCode = (categoryCode ?? '').trim();
    return '$minWordId::$maxWordId::$normalizedRelationType::$normalizedCategoryCode';
  }

  GraphEdge copyWith({
    String? sourceId,
    String? targetId,
    int? relationId,
    bool clearRelationId = false,
    String? relationType,
    String? categoryCode,
    String? statusCode,
    String? directionCode,
    String? description,
    double? weight,
    bool? isHighlighted,
  }) {
    return GraphEdge(
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      relationId: clearRelationId ? null : (relationId ?? this.relationId),
      relationType: relationType ?? this.relationType,
      categoryCode: categoryCode ?? this.categoryCode,
      statusCode: statusCode ?? this.statusCode,
      directionCode: directionCode ?? this.directionCode,
      description: description ?? this.description,
      weight: weight ?? this.weight,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GraphEdge &&
        other.id == id &&
        other.sourceId == sourceId &&
        other.targetId == targetId &&
        other.relationId == relationId &&
        other.relationType == relationType &&
        other.categoryCode == categoryCode &&
        other.statusCode == statusCode &&
        other.directionCode == directionCode &&
        other.description == description &&
        other.weight == weight &&
        other.isHighlighted == isHighlighted;
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    targetId,
    relationId,
    relationType,
    categoryCode,
    statusCode,
    directionCode,
    description,
    weight,
    isHighlighted,
  );

  @override
  String toString() {
    return 'GraphEdge('
        'id: $id, '
        'sourceId: $sourceId, '
        'targetId: $targetId'
        ')';
  }
}
