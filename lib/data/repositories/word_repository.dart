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
}
