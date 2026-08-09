final class ApprovedContentMeaningRow {
  const ApprovedContentMeaningRow({required this.seq, required this.meaning});

  final int seq;
  final String meaning;

  Map<String, Object?> toDatabaseRow(String wordId) => {
    'word_id': wordId,
    'seq': seq,
    'meaning': meaning,
  };

  Map<String, Object?> toJson() => {'seq': seq, 'meaning': meaning};
}

final class ApprovedContentMeaningReplacement {
  const ApprovedContentMeaningReplacement({
    required this.wordId,
    required this.before,
    required this.after,
  });

  final String wordId;
  final List<ApprovedContentMeaningRow> before;
  final List<ApprovedContentMeaningRow> after;
}

final class ApprovedContentRelationCreate {
  const ApprovedContentRelationCreate({
    required this.wordId1,
    required this.wordId2,
    required this.categoryCode,
    required this.relationType,
    required this.statusCode,
    required this.directionCode,
    required this.description,
    required this.relationGroupId,
    required this.note,
    required this.source,
  });

  final String wordId1;
  final String wordId2;
  final String categoryCode;
  final String relationType;
  final String statusCode;
  final String directionCode;
  final String? description;
  final String? relationGroupId;
  final String? note;
  final String source;

  Map<String, Object?> toDatabaseRow({required String updatedAt}) => {
    'word_id_1': wordId1,
    'word_id_2': wordId2,
    'category_code': categoryCode,
    'relation_type': relationType,
    'status_code': statusCode,
    'direction_code': directionCode,
    'description': description,
    'relation_group_id': relationGroupId,
    'note': note,
    'source': source,
    'updated_at': updatedAt,
  };
}

final class ApprovedContentBatchWriteRequest {
  const ApprovedContentBatchWriteRequest({
    required this.batchId,
    required this.meaningReplacements,
    required this.relationCreates,
  });

  final String batchId;
  final List<ApprovedContentMeaningReplacement> meaningReplacements;
  final List<ApprovedContentRelationCreate> relationCreates;

  int get operationCount => meaningReplacements.length + relationCreates.length;
}

final class ApprovedContentCreatedRelation {
  const ApprovedContentCreatedRelation({required this.id, required this.row});

  final int id;
  final Map<String, Object?> row;
}

final class ApprovedContentBatchWriteResult {
  const ApprovedContentBatchWriteResult({
    required this.groupId,
    required this.createdRelations,
    required this.historyRowCount,
  });

  final String groupId;
  final List<ApprovedContentCreatedRelation> createdRelations;
  final int historyRowCount;
}
