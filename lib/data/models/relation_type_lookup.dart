class RelationTypeLookup {
  final String code;
  final String categoryCode;
  final String label;
  final String? description;
  final int sortOrder;

  const RelationTypeLookup({
    required this.code,
    required this.categoryCode,
    required this.label,
    this.description,
    required this.sortOrder,
  });

  String get displayLabel {
    final trimmedLabel = label.trim();
    return trimmedLabel.isEmpty ? code : trimmedLabel;
  }

  bool belongsToCategory(String? targetCategoryCode) {
    final normalizedCategoryCode = (targetCategoryCode ?? '').trim();
    if (normalizedCategoryCode.isEmpty) return false;
    return categoryCode == normalizedCategoryCode;
  }

  factory RelationTypeLookup.fromMap(Map<String, dynamic> map) {
    return RelationTypeLookup(
      code: ((map['code'] as String?) ?? '').trim(),
      categoryCode: ((map['category_code'] as String?) ?? '').trim(),
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
