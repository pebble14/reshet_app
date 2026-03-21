class WordRelation {
  final int id;
  final String wordId1;
  final String wordId2;
  final String? relationType;
  final String directionCode;
  final String? description;
  final String? relationGroupId;
  final String? statusCode;

  WordRelation({
    required this.id,
    required this.wordId1,
    required this.wordId2,
    this.relationType,
    this.directionCode = 'unknown',
    this.description,
    this.relationGroupId,
    this.statusCode,
  });

  factory WordRelation.fromMap(Map<String, dynamic> map) {
    return WordRelation(
      id: map['id'] as int,
      wordId1: map['word_id_1'] as String,
      wordId2: map['word_id_2'] as String,
      relationType: map['relation_type'] as String?,
      directionCode: (map['direction_code'] as String?) ?? 'unknown',
      description: map['description'] as String?,
      relationGroupId: map['relation_group_id'] as String?,
      statusCode: map['status_code'] as String?,
    );
  }
}
