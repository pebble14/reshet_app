/*
  database_service.dart

  이 파일은 SQLite 데이터베이스 연결을 담당한다.

  역할:
  1. Windows 환경에서 SQLite 초기화
  2. 지정된 경로의 DB 파일 열기
  3. 이후 CRUD 기능 확장 가능

  현재 단계 목표:
  - DB 연결 성공 여부 확인
*/

import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static Database? _database;

  /// 초기 상태(골든) DB 파일명
  static const String _seedDbFileName = 'reshet_seed.db';

  /// 앱이 실제로 수정하는 작업용 DB 파일명
  static const String _workDbFileName = 'reshet_work.db';

  /// 과거 파일명 호환(기존 사용 중인 DB)
  static const String _legacySeedFileName = 'bbwdb_20260106.db';

  static const List<
    ({String code, String label, String description, int sortOrder})
  >
  _relationCategoryDefinitions = [
    (
      code: 'semantic',
      label: '개념 관계',
      description: '의미상의 유사, 대조, 포함 관계를 나타내는 상위 분류',
      sortOrder: 1,
    ),
    (
      code: 'lexical',
      label: '어휘 관계',
      description: '단어 간 어휘 대응 관계를 나타내는 상위 분류',
      sortOrder: 2,
    ),
    (
      code: 'morphological',
      label: '형태 관계',
      description: '형태 변화와 단어 형성 관계를 나타내는 상위 분류',
      sortOrder: 3,
    ),
    (
      code: 'etymological',
      label: '어원 관계',
      description: '기원, 어근, 차용 관계를 나타내는 상위 분류',
      sortOrder: 4,
    ),
    (
      code: 'phonological',
      label: '음운 관계',
      description: '발음과 음운 변동 관계를 나타내는 상위 분류',
      sortOrder: 5,
    ),
    (
      code: 'transliteration',
      label: '음역 관계',
      description: '문자 체계 사이의 음역 관계를 나타내는 상위 분류',
      sortOrder: 6,
    ),
    (
      code: 'translation',
      label: '번역 관계',
      description: '의미 전달을 위한 번역 관계를 나타내는 상위 분류',
      sortOrder: 7,
    ),
    (
      code: 'unspecified',
      label: '미분류 관계',
      description: '기존 데이터 호환을 위해 유지하는 분류되지 않은 관계',
      sortOrder: 999,
    ),
  ];

  static const List<
    ({
      String code,
      String categoryCode,
      String label,
      String description,
      int sortOrder,
    })
  >
  _relationTypeDefinitions = [
    (
      code: 'similar',
      categoryCode: 'semantic',
      label: '의미 유사',
      description: '의미가 비슷하게 대응되는 관계',
      sortOrder: 1,
    ),
    (
      code: 'contrast',
      categoryCode: 'semantic',
      label: '의미 대조',
      description: '의미가 서로 대조되는 관계',
      sortOrder: 2,
    ),
    (
      code: 'broader',
      categoryCode: 'semantic',
      label: '상위 개념',
      description: '더 넓은 범주의 의미를 가리키는 관계',
      sortOrder: 3,
    ),
    (
      code: 'narrower',
      categoryCode: 'semantic',
      label: '하위 개념',
      description: '더 좁은 범주의 의미를 가리키는 관계',
      sortOrder: 4,
    ),
    (
      code: 'synonym',
      categoryCode: 'lexical',
      label: '동의어',
      description: '서로 바꾸어 쓸 수 있을 정도로 뜻이 가까운 관계',
      sortOrder: 1,
    ),
    (
      code: 'antonym',
      categoryCode: 'lexical',
      label: '반의어',
      description: '뜻이 서로 반대되는 관계',
      sortOrder: 2,
    ),
    (
      code: 'hypernym',
      categoryCode: 'lexical',
      label: '상위어',
      description: '더 넓은 어휘 범주에 속하는 관계',
      sortOrder: 3,
    ),
    (
      code: 'hyponym',
      categoryCode: 'lexical',
      label: '하위어',
      description: '더 구체적인 어휘 범주에 속하는 관계',
      sortOrder: 4,
    ),
    (
      code: 'derived',
      categoryCode: 'morphological',
      label: '파생어',
      description: '파생에 의해 연결되는 단어 형성 관계',
      sortOrder: 1,
    ),
    (
      code: 'inflected',
      categoryCode: 'morphological',
      label: '굴절형',
      description: '활용이나 굴절에 의해 연결되는 형태 관계',
      sortOrder: 2,
    ),
    (
      code: 'variant',
      categoryCode: 'morphological',
      label: '형태 변이',
      description: '철자나 형태가 달라진 이형 관계',
      sortOrder: 3,
    ),
    (
      code: 'compound',
      categoryCode: 'morphological',
      label: '합성',
      description: '둘 이상의 어휘 요소가 결합해 이루어진 단어 형성 관계',
      sortOrder: 4,
    ),
    (
      code: 'root_shared',
      categoryCode: 'etymological',
      label: '공통 어근',
      description: '공통된 어근을 공유하는 관계',
      sortOrder: 1,
    ),
    (
      code: 'borrowed_from',
      categoryCode: 'etymological',
      label: '차용어 관계',
      description: '언어 간 차용으로 연결되는 관계',
      sortOrder: 2,
    ),
    (
      code: 'loan_translation',
      categoryCode: 'etymological',
      label: '번역 차용',
      description: '표현 요소를 번역해 받아들인 차용 관계',
      sortOrder: 3,
    ),
    (
      code: 'root-related',
      categoryCode: 'etymological',
      label: '어근 관련',
      description: '레거시 데이터 호환을 위해 유지하는 어근 관련 관계',
      sortOrder: 999,
    ),
    (
      code: 'sound_similar',
      categoryCode: 'phonological',
      label: '발음 유사',
      description: '발음이 서로 유사하게 들리는 관계',
      sortOrder: 1,
    ),
    (
      code: 'sound_shift',
      categoryCode: 'phonological',
      label: '음운 변화',
      description: '음운 변동으로 이어지는 관계',
      sortOrder: 2,
    ),
    (
      code: 'direct_transliteration',
      categoryCode: 'transliteration',
      label: '직접 음역',
      description: '원어의 음을 직접 대응해 옮긴 관계',
      sortOrder: 1,
    ),
    (
      code: 'approx_transliteration',
      categoryCode: 'transliteration',
      label: '근사 음역',
      description: '음운 차이를 반영해 가깝게 옮긴 관계',
      sortOrder: 2,
    ),
    (
      code: 'conventional_transliteration',
      categoryCode: 'transliteration',
      label: '관용 음역',
      description: '관용적으로 굳어진 음역 관계',
      sortOrder: 3,
    ),
    (
      code: 'literal_translation',
      categoryCode: 'translation',
      label: '직역',
      description: '표현을 가능한 한 문자 그대로 옮긴 번역 관계',
      sortOrder: 1,
    ),
    (
      code: 'semantic_translation',
      categoryCode: 'translation',
      label: '의역',
      description: '의미 대응을 중심으로 옮긴 번역 관계',
      sortOrder: 2,
    ),
    (
      code: 'interpretive_translation',
      categoryCode: 'translation',
      label: '풀이 번역',
      description: '의미 풀이를 보완해 옮긴 번역 관계',
      sortOrder: 3,
    ),
    (
      code: 'related',
      categoryCode: 'unspecified',
      label: '일반 관련',
      description: '레거시 데이터 호환을 위해 유지하는 일반 관련 관계',
      sortOrder: 1,
    ),
  ];

  /// data 폴더 경로 (현재는 Windows/데스크탑 기준)
  static String _dataDirPath() {
    final currentPath = Directory.current.path;
    return join(currentPath, 'data');
  }

  static String _seedDbPath() {
    final dataDir = _dataDirPath();
    final seed = join(dataDir, _seedDbFileName);
    final legacy = join(dataDir, _legacySeedFileName);

    // seed가 없고 legacy가 있으면 legacy를 seed로 취급(rename 없이도 동작)
    if (!File(seed).existsSync() && File(legacy).existsSync()) {
      return legacy;
    }
    return seed;
  }

  static String _workDbPath() {
    return join(_dataDirPath(), _workDbFileName);
  }

  /*
    initialize()

    Windows 환경에서 SQLite FFI를 초기화한다.
    반드시 DB 열기 전에 호출해야 한다.
  */
  static Future<void> initialize() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  /*
    openDatabaseFile()

    프로젝트 루트의 data 폴더에 있는
    reshet.db 파일을 연다.
  */
  static Future<Database> openDatabaseFile() async {
    if (_database != null) {
      return _database!;
    }

    final seedPath = _seedDbPath();
    final workPath = _workDbPath();

    // work DB가 없으면 seed를 복사하여 work 생성
    if (!File(workPath).existsSync()) {
      final seedFile = File(seedPath);
      if (!seedFile.existsSync()) {
        throw Exception('초기 DB(seed)를 찾을 수 없습니다: $seedPath');
      }
      await File(workPath).create(recursive: true);
      await seedFile.copy(workPath);
    }

    _database = await databaseFactory.openDatabase(workPath);

    await _ensureWordRelationV2Columns(_database!);
    await _ensureWordRelationIndexes(_database!);
    await _ensureHistoryTable(_database!);
    await _ensureRelationLookupMetadata(_database!);

    return _database!;
  }

  /// 테스트용 DB 연결 확인 메서드
  /// 실제 테이블 없이 간단한 문자열을 반환한다.
  static Future<String> getTestData() async {
    return "DB 연결 확인 완료";
  }

  /// 현재 연결된 DB의 모든 테이블 목록을 조회한다.
  static Future<List<String>> getTableList() async {
    final db = _database;

    if (db == null) {
      throw Exception("데이터베이스가 초기화되지 않았습니다.");
    }

    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;",
    );

    return result.map((row) => row['name'] as String).toList();
  }

  /// WORD_TABLE 데이터 일부 조회 (테스트용)
  static Future<List<Map<String, dynamic>>> getWords() async {
    final db = _database;

    if (db == null) {
      throw Exception("데이터베이스가 초기화되지 않았습니다.");
    }

    return await db.query('WORD_TABLE', limit: 50);
  }

  /// 현재 열려있는 DB를 닫는다.
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// 작업용 DB를 초기(seed) 상태로 되돌린다.
  /// - backup=true면 data/backups에 현재 작업용 DB를 복사해 둔다.
  static Future<void> resetToSeed({bool backup = true}) async {
    final seedPath = _seedDbPath();
    final workPath = _workDbPath();

    final seedFile = File(seedPath);
    if (!seedFile.existsSync()) {
      throw Exception('초기 DB(seed)를 찾을 수 없습니다: $seedPath');
    }

    // 열려있으면 닫기
    await closeDatabase();

    // 백업
    final workFile = File(workPath);
    if (backup && workFile.existsSync()) {
      final backupsDir = Directory(join(_dataDirPath(), 'backups'));
      if (!backupsDir.existsSync()) {
        backupsDir.createSync(recursive: true);
      }
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('-', '')
          .replaceAll('.', '');
      final backupPath = join(backupsDir.path, 'reshet_backup_$ts.db');
      await workFile.copy(backupPath);
    }

    // work를 seed로 덮어쓰기
    if (workFile.existsSync()) {
      await workFile.delete();
    }
    await seedFile.copy(workPath);

    // 다시 열기(이후 쿼리 즉시 가능)
    _database = await databaseFactory.openDatabase(workPath);

    await _ensureWordRelationV2Columns(_database!);
    await _ensureWordRelationIndexes(_database!);
    await _ensureHistoryTable(_database!);
    await _ensureRelationLookupMetadata(_database!);
  }

  /// WORD_RELATION v2 컬럼 보장
  static Future<void> _ensureWordRelationV2Columns(Database db) async {
    final columns = await db.rawQuery("PRAGMA table_info('WORD_RELATION')");
    final names = columns.map((row) => row['name'] as String).toSet();

    if (!names.contains('direction_code')) {
      await db.execute('''
        ALTER TABLE WORD_RELATION
        ADD COLUMN direction_code TEXT NOT NULL DEFAULT 'unknown'
      ''');
    }

    if (!names.contains('description')) {
      await db.execute('''
        ALTER TABLE WORD_RELATION
        ADD COLUMN description TEXT
      ''');
    }

    if (!names.contains('relation_group_id')) {
      await db.execute('''
        ALTER TABLE WORD_RELATION
        ADD COLUMN relation_group_id TEXT
      ''');
    }
  }

  /// 새 UNIQUE 인덱스 기준과 동일한 signature 충돌 후보 조회
  static Future<List<Map<String, Object?>>> _findWordRelationSignatureConflicts(
    DatabaseExecutor db,
  ) async {
    return await db.rawQuery('''
      SELECT
        word_id_1,
        word_id_2,
        COALESCE(relation_type, '') AS relation_type_key,
        COALESCE(direction_code, 'unknown') AS direction_code_key,
        COUNT(*) AS duplicate_count
      FROM WORD_RELATION
      GROUP BY
        word_id_1,
        word_id_2,
        COALESCE(relation_type, ''),
        COALESCE(direction_code, 'unknown')
      HAVING COUNT(*) > 1
      ORDER BY duplicate_count DESC, word_id_1, word_id_2
    ''');
  }

  /// WORD_RELATION 테이블 v2 무결성/성능 보강
  /// 1) v1 pair-only 인덱스 제거
  /// 2) signature 조회용 인덱스 보장
  /// 3) 충돌이 없을 때만 v2 UNIQUE 인덱스 생성
  /// 4) 조회 성능 인덱스 추가
  static Future<void> _ensureWordRelationIndexes(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('DROP INDEX IF EXISTS idx_word_relation_pair');
      await txn.execute(
        'DROP INDEX IF EXISTS idx_word_relation_pair_type_direction_unique',
      );
      await txn.execute(
        'DROP INDEX IF EXISTS idx_word_relation_signature_lookup',
      );

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS idx_word_relation_signature_lookup
        ON WORD_RELATION(
          word_id_1,
          word_id_2,
          COALESCE(relation_type, ''),
          COALESCE(direction_code, 'unknown')
        )
      ''');

      final conflicts = await _findWordRelationSignatureConflicts(txn);

      // ignore: avoid_print
      print('[DB] WORD_RELATION v2 signature 충돌 후보: ${conflicts.length}건');

      if (conflicts.isEmpty) {
        await txn.execute('''
          CREATE UNIQUE INDEX IF NOT EXISTS idx_word_relation_pair_type_direction_unique
          ON WORD_RELATION(
            word_id_1,
            word_id_2,
            COALESCE(relation_type, ''),
            COALESCE(direction_code, 'unknown')
          )
        ''');
      }

      await txn.execute('''
        CREATE INDEX IF NOT EXISTS idx_word_relation_word1
        ON WORD_RELATION(word_id_1)
      ''');
      await txn.execute('''
        CREATE INDEX IF NOT EXISTS idx_word_relation_word2
        ON WORD_RELATION(word_id_2)
      ''');
    });
  }

  /// 변경 이력 테이블 보장
  static Future<void> _ensureHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS CHANGE_HISTORY (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id TEXT NOT NULL,
        action_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        before_json TEXT,
        after_json TEXT,
        created_at TEXT NOT NULL,
        undone_at TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_change_history_group
      ON CHANGE_HISTORY(group_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_change_history_undone
      ON CHANGE_HISTORY(undone_at, created_at)
    ''');
  }

  /// relation lookup 메타데이터 보정
  /// - 스키마 변경 없이 code 기준으로 label/description/category/sort_order를 정합화한다.
  /// - 기존 work DB와 seed에서 새로 복사한 work DB를 같은 메타데이터 체계로 맞춘다.
  static Future<void> _ensureRelationLookupMetadata(Database db) async {
    await db.transaction((txn) async {
      for (final category in _relationCategoryDefinitions) {
        await _upsertRelationCategory(
          txn,
          code: category.code,
          label: category.label,
          description: category.description,
          sortOrder: category.sortOrder,
        );
      }

      for (final relationType in _relationTypeDefinitions) {
        await _upsertRelationType(
          txn,
          code: relationType.code,
          categoryCode: relationType.categoryCode,
          label: relationType.label,
          description: relationType.description,
          sortOrder: relationType.sortOrder,
        );
      }
    });
  }

  static Future<void> _upsertRelationCategory(
    DatabaseExecutor db, {
    required String code,
    required String label,
    required String description,
    required int sortOrder,
  }) async {
    final row = {
      'label': label,
      'description': description,
      'sort_order': sortOrder,
    };

    final updated = await db.update(
      'RELATION_CATEGORY',
      row,
      where: 'code = ?',
      whereArgs: [code],
    );
    if (updated > 0) {
      return;
    }

    await db.insert('RELATION_CATEGORY', {'code': code, ...row});
  }

  static Future<void> _upsertRelationType(
    DatabaseExecutor db, {
    required String code,
    required String categoryCode,
    required String label,
    required String description,
    required int sortOrder,
  }) async {
    final row = {
      'category_code': categoryCode,
      'label': label,
      'description': description,
      'sort_order': sortOrder,
    };

    final updated = await db.update(
      'RELATION_TYPE',
      row,
      where: 'code = ?',
      whereArgs: [code],
    );
    if (updated > 0) {
      return;
    }

    await db.insert('RELATION_TYPE', {'code': code, ...row});
  }
}
