class RelationCategoryLookup {
  final String code;
  final String label;
  final String? description;
  final int sortOrder;

  const RelationCategoryLookup({
    required this.code,
    required this.label,
    this.description,
    required this.sortOrder,
  });

  String get displayLabel {
    final trimmedLabel = label.trim();
    return trimmedLabel.isEmpty ? code : trimmedLabel;
  }

  factory RelationCategoryLookup.fromMap(Map<String, dynamic> map) {
    return RelationCategoryLookup(
      code: ((map['code'] as String?) ?? '').trim(),
      label: ((map['label'] as String?) ?? '').trim(),
      description: (map['description'] as String?)?.trim(),
      sortOrder: _parseSortOrder(map['sort_order']),
    );
  }

  static int _parseSortOrder(Object? rawValue) {
    if (rawValue is int) return rawValue;
    if (rawValue is num) return rawValue.toInt();
    return int.tryParse(rawValue?.toString() ?? '') ?? 0;
  }
}
