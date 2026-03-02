import '../../database/database_service.dart';
import '../models/word.dart';

/// 단어(WORD_TABLE) 및 관계(WORD_RELATION) 조회 전용 Repository
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
