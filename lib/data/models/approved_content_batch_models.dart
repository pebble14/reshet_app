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

final class ApprovedContentWordNoteReplacement {
  const ApprovedContentWordNoteReplacement({
    required this.wordId,
    required this.before,
    required this.after,
  });

  final String wordId;
  final String? before;
  final String? after;
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

final class ApprovedContentRelationProjection {
  const ApprovedContentRelationProjection({
    required this.categoryCode,
    required this.relationType,
    required this.statusCode,
    required this.directionCode,
    required this.description,
    required this.relationGroupId,
    required this.note,
    required this.source,
  });

  final String? categoryCode;
  final String? relationType;
  final String statusCode;
  final String directionCode;
  final String? description;
  final String? relationGroupId;
  final String? note;
  final String source;

  Map<String, Object?> toDatabaseFields() => {
    'category_code': categoryCode,
    'relation_type': relationType,
    'status_code': statusCode,
    'direction_code': directionCode,
    'description': description,
    'relation_group_id': relationGroupId,
    'note': note,
    'source': source,
  };

  bool matchesDatabaseRow(Map<String, Object?> row) {
    for (final entry in toDatabaseFields().entries) {
      if (row[entry.key] != entry.value) return false;
    }
    return true;
  }

  bool hasSameValues(ApprovedContentRelationProjection other) {
    return matchesDatabaseRow(other.toDatabaseFields());
  }
}

final class ApprovedContentRelationReplacement {
  const ApprovedContentRelationReplacement({
    required this.relationId,
    required this.wordId1,
    required this.wordId2,
    required this.before,
    required this.after,
  });

  final int relationId;
  final String wordId1;
  final String wordId2;
  final ApprovedContentRelationProjection before;
  final ApprovedContentRelationProjection after;
}

final class ApprovedContentBatchWriteRequest {
  const ApprovedContentBatchWriteRequest({
    required this.batchId,
    required this.meaningReplacements,
    required this.wordNoteReplacements,
    required this.relationCreates,
    required this.relationReplacements,
  });

  final String batchId;
  final List<ApprovedContentMeaningReplacement> meaningReplacements;
  final List<ApprovedContentWordNoteReplacement> wordNoteReplacements;
  final List<ApprovedContentRelationCreate> relationCreates;
  final List<ApprovedContentRelationReplacement> relationReplacements;

  int get operationCount =>
      meaningReplacements.length +
      wordNoteReplacements.length +
      relationCreates.length +
      relationReplacements.length;
}

final class ApprovedContentCreatedRelation {
  const ApprovedContentCreatedRelation({required this.id, required this.row});

  final int id;
  final Map<String, Object?> row;
}

final class ApprovedContentReplacedRelation {
  const ApprovedContentReplacedRelation({
    required this.id,
    required this.before,
    required this.after,
  });

  final int id;
  final Map<String, Object?> before;
  final Map<String, Object?> after;
}

final class ApprovedContentBatchWriteResult {
  const ApprovedContentBatchWriteResult({
    required this.groupId,
    required this.createdRelations,
    required this.replacedRelations,
    required this.historyRowCount,
  });

  final String groupId;
  final List<ApprovedContentCreatedRelation> createdRelations;
  final List<ApprovedContentReplacedRelation> replacedRelations;
  final int historyRowCount;
}
