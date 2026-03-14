class WordRelation {
  final int id;
  final String wordId1;
  final String wordId2;
  final String? relationType;

  WordRelation({
    required this.id,
    required this.wordId1,
    required this.wordId2,
    this.relationType,
  });

  factory WordRelation.fromMap(Map<String, dynamic> map) {
    return WordRelation(
      id: map['id'] as int,
      wordId1: map['word_id_1'] as String,
      wordId2: map['word_id_2'] as String,
      relationType: map['relation_type'] as String?,
    );
  }
}
