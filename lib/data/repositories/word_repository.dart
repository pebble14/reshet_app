import '../../database/database_service.dart';
import '../models/word.dart';

/// 단어(WORD_TABLE) 및 관계(WORD_RELATION) 조회 전용 Repository
/// 그래프 엣지(관계선) 표시를 위한 관계 메타 정보
/// - otherWordId: 중심 단어 기준으로 연결된 “상대 단어 id”
/// - categoryCode/categoryLabel: RELATION_CATEGORY 기반(없으면 null)
/// - relationType/relationTypeLabel: RELATION_TYPE 기반(없으면 null)
class WordRelationEdgeInfo {
  final String otherWordId;
  final String? categoryCode;
  final String? categoryLabel;
  final String? relationType;
  final String? relationTypeLabel;

  WordRelationEdgeInfo({
    required this.otherWordId,
    this.categoryCode,
    this.categoryLabel,
    this.relationType,
    this.relationTypeLabel,
  });

  factory WordRelationEdgeInfo.fromMap(Map<String, dynamic> map) {
    return WordRelationEdgeInfo(
      otherWordId: map['other_word_id'] as String,
      categoryCode: map['category_code'] as String?,
      categoryLabel: map['category_label'] as String?,
      relationType: map['relation_type'] as String?,
      relationTypeLabel: map['relation_type_label'] as String?,
    );
  }
}

class WordRepository {
  /// id로 단어 1건 조회
  Future<Word?> getWordById(String id) async {
    final db = await DatabaseService.openDatabaseFile();

    final result = await db.query(
      'WORD_TABLE',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return Word.fromMap(result.first);
  }

  /// 특정 단어와 연결된 단어 목록 조회 (WORD_RELATION 기반)
  Future<List<Word>> getConnectedWords(String wordId) async {
    final db = await DatabaseService.openDatabaseFile();

    final result = await db.rawQuery(
      '''
      SELECT * FROM WORD_TABLE
      WHERE id IN (
        SELECT CASE
          WHEN word_id_1 = ?
            THEN word_id_2
          ELSE word_id_1
        END
        FROM WORD_RELATION
        WHERE word_id_1 = ?
           OR word_id_2 = ?
      )
    ''',
      [wordId, wordId, wordId],
    );

    return result.map((map) => Word.fromMap(map)).toList();
  }

  /// 특정 단어(wordId)와 연결된 관계(엣지) 메타 정보 조회
  /// - WORD_RELATION + RELATION_TYPE + RELATION_CATEGORY를 조인한다.
  /// - WORD_RELATION에 존재하지만 코드 테이블에 없는 값(예: unspecified, related)은
  ///   조인 결과가 null이 될 수 있으므로 UI에서 fallback 처리한다.
  Future<List<WordRelationEdgeInfo>> getRelationEdges(String wordId) async {
    final db = await DatabaseService.openDatabaseFile();

    final rows = await db.rawQuery(
      '''
      SELECT
        CASE
          WHEN wr.word_id_1 = ? THEN wr.word_id_2
          ELSE wr.word_id_1
        END AS other_word_id,
        wr.category_code AS category_code,
        rc.label AS category_label,
        wr.relation_type AS relation_type,
        rt.label AS relation_type_label
      FROM WORD_RELATION wr
      LEFT JOIN RELATION_CATEGORY rc
        ON rc.code = wr.category_code
      LEFT JOIN RELATION_TYPE rt
        ON rt.code = wr.relation_type
      WHERE wr.word_id_1 = ?
         OR wr.word_id_2 = ?
      ''',
      [wordId, wordId, wordId],
    );

    return rows.map((m) => WordRelationEdgeInfo.fromMap(m)).toList();
  }

  /// WORD_TABLE에서 단어 목록을 일부 조회한다 (홈 화면 기본 리스트용)
  /// - 상세 화면에서 모든 컬럼을 보여주기 위해 Map 그대로 반환한다.
  Future<List<Map<String, dynamic>>> getWordsMap({int limit = 50}) async {
    final db = await DatabaseService.openDatabaseFile();
    return await db.query('WORD_TABLE', limit: limit);
  }

  /// 키워드로 단어 검색 (홈 검색용)
  /// - 표기1, 의미1, 스트롱넘버를 대상으로 부분일치 검색한다.
  /// - 결과는 Map 그대로 반환하여 상세 화면에서 컬럼 손실이 없게 한다.
  Future<List<Map<String, dynamic>>> searchWordsMap(
    String keyword, {
    int limit = 200,
  }) async {
    final db = await DatabaseService.openDatabaseFile();

    final q = keyword.trim();
    if (q.isEmpty) {
      return getWordsMap(limit: limit);
    }

    final like = '%$q%';

    // NOTE: 컬럼명은 네 DB 기준(한글 컬럼) 사용
    return await db.query(
      'WORD_TABLE',
      where: '표기1 LIKE ? OR 의미1 LIKE ? OR 스트롱넘버 LIKE ?',
      whereArgs: [like, like, like],
      limit: limit,
    );
  }
}
