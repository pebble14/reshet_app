/// graph_node.dart
///
/// 그래프 엔진에서 단어 노드를 표현하는 도메인 모델이다.
/// v2 foundation 단계에서는 `id`를 항상 `wordId`와 동일하게 유지한다.
class GraphNode {
  final String id;
  final String wordId;
  final String label;
  final int depth;
  final bool isCenter;
  final String? languageCode;
  final double weight;
  final bool isPinned;

  GraphNode({
    required this.wordId,
    required this.label,
    required this.depth,
    required this.isCenter,
    this.languageCode,
    this.weight = 1.0,
    this.isPinned = false,
  }) : assert(depth >= 0),
       id = wordId;

  GraphNode copyWith({
    String? wordId,
    String? label,
    int? depth,
    bool? isCenter,
    String? languageCode,
    double? weight,
    bool? isPinned,
  }) {
    return GraphNode(
      wordId: wordId ?? this.wordId,
      label: label ?? this.label,
      depth: depth ?? this.depth,
      isCenter: isCenter ?? this.isCenter,
      languageCode: languageCode ?? this.languageCode,
      weight: weight ?? this.weight,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GraphNode &&
        other.id == id &&
        other.wordId == wordId &&
        other.label == label &&
        other.depth == depth &&
        other.isCenter == isCenter &&
        other.languageCode == languageCode &&
        other.weight == weight &&
        other.isPinned == isPinned;
  }

  @override
  int get hashCode => Object.hash(
    id,
    wordId,
    label,
    depth,
    isCenter,
    languageCode,
    weight,
    isPinned,
  );

  @override
  String toString() {
    return 'GraphNode('
        'id: $id, '
        'label: $label, '
        'depth: $depth, '
        'isCenter: $isCenter'
        ')';
  }
}
