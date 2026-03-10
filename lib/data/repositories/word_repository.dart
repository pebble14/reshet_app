import '../../database/database_service.dart';
import '../models/word.dart';

/// 단어(WORD_TABLE) 및 관계(WORD_RELATION) 조회 전용 Repository
/// 그래프 엣지(관계선) 표시를 위한 관계 메타 정보
/// - otherWordId: 중심 단어 기준으로 연결된 “상대 단어 id”
/// - categoryCode/categoryLabel: RELATION_CATEGORY 기반(없으면 null)
/// - relationType/relationTypeLabel: RELATION_TYPE 기반(없으면 null)
class WordRelationEdgeInfo {
  final int relationId;
  final String otherWordId;
  final String? categoryCode;
  final String? categoryLabel;
  final String? relationType;
  final String? relationTypeLabel;
  final String? note;
  final String? source;

  WordRelationEdgeInfo({
    required this.relationId,
    required this.otherWordId,
    this.categoryCode,
    this.categoryLabel,
    this.relationType,
    this.relationTypeLabel,
    this.note,
    this.source,
  });

  factory WordRelationEdgeInfo.fromMap(Map<String, dynamic> map) {
    return WordRelationEdgeInfo(
      relationId: map['relation_id'] as int,
      otherWordId: map['other_word_id'] as String,
      categoryCode: map['category_code'] as String?,
      categoryLabel: map['category_label'] as String?,
      relationType: map['relation_type'] as String?,
      relationTypeLabel: map['relation_type_label'] as String?,
      note: map['note'] as String?,
      source: map['source'] as String?,
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
        wr.id AS relation_id,
        CASE
          WHEN wr.word_id_1 = ? THEN wr.word_id_2
          ELSE wr.word_id_1
        END AS other_word_id,
        wr.category_code AS category_code,
        rc.label AS category_label,
        wr.relation_type AS relation_type,
        rt.label AS relation_type_label,
        wr.note AS note,
        wr.source AS source
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

  /// WORD_RELATION 1건 삭제(트랜잭션)
  Future<void> deleteRelation(int relationId) async {
    final db = await DatabaseService.openDatabaseFile();

    await db.transaction((txn) async {
      await txn.delete(
        'WORD_RELATION',
        where: 'id = ?',
        whereArgs: [relationId],
      );
    });
  }

  /// RELATION_CATEGORY 코드/라벨 목록
  Future<List<Map<String, dynamic>>> getRelationCategories() async {
    final db = await DatabaseService.openDatabaseFile();
    return await db.query(
      'RELATION_CATEGORY',
      columns: ['code', 'label'],
      orderBy: 'code',
    );
  }

  /// RELATION_TYPE 코드/라벨 목록
  Future<List<Map<String, dynamic>>> getRelationTypes() async {
    final db = await DatabaseService.openDatabaseFile();
    return await db.query(
      'RELATION_TYPE',
      columns: ['code', 'label'],
      orderBy: 'code',
    );
  }

  /// WORD_RELATION 1건 수정(트랜잭션)
  Future<void> updateRelation({
    required int relationId,
    required String? categoryCode,
    required String? relationType,
    required String? note,
    required String? source,
  }) async {
    final db = await DatabaseService.openDatabaseFile();

    await db.transaction((txn) async {
      await txn.update(
        'WORD_RELATION',
        {
          'category_code': categoryCode,
          'relation_type': relationType,
          'note': note,
          'source': source,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [relationId],
      );
    });
  }

  /// 키워드로 단어 검색 (그래프에서 "관계 추가" 대상 단어 선택용)
  /// - 표기1, 의미1, 스트롱넘버 부분일치 검색
  /// - 결과를 Word 모델로 반환한다(그래프 노드에서 사용하기 쉬움)
  Future<List<Word>> searchWords(String keyword, {int limit = 200}) async {
    final db = await DatabaseService.openDatabaseFile();

    final q = keyword.trim();
    if (q.isEmpty) return [];

    final like = '%$q%';

    final rows = await db.query(
      'WORD_TABLE',
      where: '표기1 LIKE ? OR 의미1 LIKE ? OR 스트롱넘버 LIKE ?',
      whereArgs: [like, like, like],
      limit: limit,
    );

    return rows.map((m) => Word.fromMap(m)).toList();
  }

  /// 두 단어 사이에 이미 관계(WORD_RELATION)가 존재하는지 검사한다.
  /// - (A,B)와 (B,A)를 동일 관계로 본다.
  /// - 있으면 relation id를 반환하고, 없으면 null
  Future<int?> findExistingRelationId(String wordIdA, String wordIdB) async {
    final db = await DatabaseService.openDatabaseFile();

    // DB CHECK 제약(word_id_1 < word_id_2)에 맞게 정렬
    final a = wordIdA.compareTo(wordIdB) <= 0 ? wordIdA : wordIdB;
    final b = wordIdA.compareTo(wordIdB) <= 0 ? wordIdB : wordIdA;

    final rows = await db.rawQuery(
      '''
      SELECT id
      FROM WORD_RELATION
      WHERE word_id_1 = ? AND word_id_2 = ?
      LIMIT 1
      ''',
      [a, b],
    );

    if (rows.isEmpty) return null;
    return rows.first['id'] as int;
  }

  /// WORD_RELATION에 관계 1건을 추가한다(트랜잭션)
  /// - status_code/created_at/updated_at은 DB default를 활용하되,
  ///   updated_at은 명시적으로 ISO 문자열로 넣어준다.
  Future<int> createRelation({
    required String wordId1,
    required String wordId2,
    required String? categoryCode,
    required String? relationType,
    required String? note,
    required String? source,
  }) async {
    final db = await DatabaseService.openDatabaseFile();

    // DB CHECK 제약: word_id_1 < word_id_2 를 만족시키기 위해 정렬
    final a = wordId1.compareTo(wordId2) <= 0 ? wordId1 : wordId2;
    final b = wordId1.compareTo(wordId2) <= 0 ? wordId2 : wordId1;

    return await db.transaction((txn) async {
      final id = await txn.insert('WORD_RELATION', {
        'word_id_1': a,
        'word_id_2': b,
        'category_code': categoryCode,
        'relation_type': relationType,
        'note': note,
        'source': source,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return id;
    });
  }

  /// 언어명을 Reshet 내부 id prefix로 변환한다.
  /// - 히브리어/아람어 -> H
  /// - 헬라어 -> G
  /// - 라틴어 -> L
  /// - 영어 -> E
  /// - 그 외 -> X
  String _languageCodeFromLanguage(String language) {
    if (language.contains('히브리')) return 'H';
    if (language.contains('아람')) return 'H';
    if (language.contains('헬라')) return 'G';
    if (language.contains('라틴')) return 'L';
    if (language.contains('영어')) return 'E';
    return 'X';
  }

  /// 중복 검사 비교용 표기 정규화
  /// - trim
  /// - NFC 수준 전체 정규화까지는 라이브러리 추가가 필요하므로,
  ///   현재 단계에서는 히브리어/아람어의 모음부호(niqqud) 제거 + 공백 정리만 적용
  String _normalizeSpellingForDuplicateCheck(String value) {
    final trimmed = value.trim();

    // 히브리어 결합부호/모음부호 제거 (U+0591 ~ U+05C7)
    final withoutHebrewMarks = trimmed.replaceAll(
      RegExp(r'[\u0591-\u05C7]'),
      '',
    );

    // 연속 공백 정리
    return withoutHebrewMarks.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 다음 WORD_TABLE.id 생성
  /// - Strong가 있으면: <STRONG>_<SEQ4>
  /// - Strong가 없으면: <LANGCODE>0000_<SEQ4>
  Future<String> generateNextWordId({
    required String language,
    String? strongNumber,
  }) async {
    final db = await DatabaseService.openDatabaseFile();

    final strong = (strongNumber ?? '').trim().toUpperCase();

    // 1) Strong가 있는 경우
    if (strong.isNotEmpty) {
      final rows = await db.rawQuery(
        '''
        SELECT id
        FROM WORD_TABLE
        WHERE id GLOB ?
        ''',
        ['${strong}_[0-9][0-9][0-9][0-9]'],
      );

      int maxSeq = -1;
      final re = RegExp('^${RegExp.escape(strong)}_(\\d{4})\$');

      for (final row in rows) {
        final id = row['id'] as String;
        final m = re.firstMatch(id);
        if (m != null) {
          final seq = int.tryParse(m.group(1)!) ?? 0;
          if (seq > maxSeq) maxSeq = seq;
        }
      }

      final nextSeq = maxSeq + 1;
      final seqText = nextSeq.toString().padLeft(4, '0');
      return '${strong}_$seqText';
    }

    // 2) Strong가 없는 경우
    final langCode = _languageCodeFromLanguage(language);
    final base = '${langCode}0000';

    final rows = await db.rawQuery(
      '''
      SELECT id
      FROM WORD_TABLE
      WHERE id GLOB ?
      ''',
      ['${base}_[0-9][0-9][0-9][0-9]'],
    );

    int maxSeq = 0;
    final re = RegExp('^${RegExp.escape(base)}_(\\d{4})\$');

    for (final row in rows) {
      final id = row['id'] as String;
      final m = re.firstMatch(id);
      if (m != null) {
        final seq = int.tryParse(m.group(1)!) ?? 0;
        if (seq > maxSeq) maxSeq = seq;
      }
    }

    final nextSeq = maxSeq + 1;
    final seqText = nextSeq.toString().padLeft(4, '0');
    return '${base}_$seqText';
  }

  /// 신규 단어 생성 전 중복 후보 검색
  /// - Strong가 있으면: 스트롱넘버 기준
  /// - Strong가 없으면: (언어, 표기1) 기준
  Future<List<Map<String, dynamic>>> findDuplicateCandidates({
    required String language,
    String? strongNumber,
    required String spelling1,
    String? excludeId,
  }) async {
    final db = await DatabaseService.openDatabaseFile();

    final strong = (strongNumber ?? '').trim();
    final spelling = spelling1.trim();

    if (strong.isNotEmpty) {
      final rows = await db.query(
        'WORD_TABLE',
        columns: ['id', '언어', '스트롱넘버', '표기1', '의미1'],
        where: '스트롱넘버 = ?',
        whereArgs: [strong],
        limit: 20,
      );

      return rows.where((row) {
        final id = (row['id'] ?? '').toString();
        return excludeId == null || id != excludeId;
      }).toList();
    }

    final rows = await db.query(
      'WORD_TABLE',
      columns: ['id', '언어', '스트롱넘버', '표기1', '의미1'],
      where: '언어 = ?',
      whereArgs: [language],
      limit: 200,
    );

    final target = _normalizeSpellingForDuplicateCheck(spelling);

    return rows.where((row) {
      final id = (row['id'] ?? '').toString();
      if (excludeId != null && id == excludeId) return false;

      final existingSpelling = (row['표기1'] ?? '').toString();
      final normalizedExisting = _normalizeSpellingForDuplicateCheck(
        existingSpelling,
      );

      return normalizedExisting == target;
    }).toList();
  }

  /// WORD_TABLE에 신규 단어를 추가한다.
  /// - 현재 단계에서는 핵심 컬럼만 입력하고, 나머지는 null로 둔다.
  Future<void> createWord({
    required String id,
    required String language,
    String? strongNumber,
    required String spelling1,
    String? pronunciation1,
    String? meaning1,
    String? note,
  }) async {
    final db = await DatabaseService.openDatabaseFile();

    await db.transaction((txn) async {
      await txn.insert('WORD_TABLE', {
        'id': id,
        '언어': language,
        '스트롱넘버': (strongNumber ?? '').trim().isEmpty
            ? null
            : strongNumber!.trim(),
        '표기1': spelling1.trim(),
        '발음1': (pronunciation1 ?? '').trim().isEmpty
            ? null
            : pronunciation1!.trim(),
        '의미1': (meaning1 ?? '').trim().isEmpty ? null : meaning1!.trim(),
        '비고': (note ?? '').trim().isEmpty ? null : note!.trim(),
      });
    });
  }

  /// WORD_TABLE의 기존 단어 1건 수정
  /// - 현재 단계에서는 핵심 편집 필드만 수정한다.
  /// - id는 수정하지 않는다.
  Future<void> updateWord({
    required String id,
    required String language,
    String? strongNumber,
    required String spelling1,
    String? pronunciation1,
    String? meaning1,
    String? note,
  }) async {
    final db = await DatabaseService.openDatabaseFile();

    await db.transaction((txn) async {
      await txn.update(
        'WORD_TABLE',
        {
          '언어': language,
          '스트롱넘버': (strongNumber ?? '').trim().isEmpty
              ? null
              : strongNumber!.trim(),
          '표기1': spelling1.trim(),
          '발음1': (pronunciation1 ?? '').trim().isEmpty
              ? null
              : pronunciation1!.trim(),
          '의미1': (meaning1 ?? '').trim().isEmpty ? null : meaning1!.trim(),
          '비고': (note ?? '').trim().isEmpty ? null : note!.trim(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }
}
