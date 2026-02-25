import '../../database/database_service.dart';
import '../models/word.dart';

class WordRepository {
  Future<Word?> getWordById(String id) async {
    final db = await DatabaseService.instance.database;

    final result = await db.query(
      'WORD_TABLE',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return Word.fromMap(result.first);
  }

  Future<List<Word>> getConnectedWords(String wordId) async {
    final db = await DatabaseService.instance.database;

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
