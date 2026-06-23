import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String repoRootPath;
  Directory? isolatedRoot;

  setUpAll(() async {
    repoRootPath = Directory.current.path;

    await DatabaseService.closeDatabase();
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    isolatedRoot = await _createIsolatedWorkspace(repoRootPath);
    Directory.current = isolatedRoot!.path;
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    Directory.current = repoRootPath;

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await isolatedRoot!.delete(recursive: true);
    }
  });

  test(
    'keeps existing word_expression_set rows when opening a seed DB',
    () async {
      final db = await DatabaseService.openDatabaseFile();

      final counts = await db.rawQuery(
        'SELECT COUNT(*) AS row_count FROM word_expression_set',
      );
      expect(counts.single['row_count'], 2);
    },
  );

  test('backfills word_expression_set when opening a legacy seed DB', () async {
    await DatabaseService.closeDatabase();
    await _stripWordExpressionSetFromSeedCopy(isolatedRoot!.path);

    final db = await DatabaseService.openDatabaseFile();

    final tableRows = await db.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name = 'word_expression_set'
      ''');
    expect(tableRows, isNotEmpty);

    final counts = await db.rawQuery('''
      WITH legacy_slots AS (
        SELECT
          id AS word_id,
          1 AS source_slot,
          TRIM(COALESCE([표기1], '')) AS spelling,
          TRIM(COALESCE([음역1], '')) AS transliteration,
          TRIM(COALESCE([발음1], '')) AS pronunciation
        FROM WORD_TABLE
        UNION ALL
        SELECT
          id,
          2,
          TRIM(COALESCE([표기2], '')),
          TRIM(COALESCE([음역2], '')),
          TRIM(COALESCE([발음2], ''))
        FROM WORD_TABLE
        UNION ALL
        SELECT
          id,
          3,
          TRIM(COALESCE([표기3], '')),
          TRIM(COALESCE([음역3], '')),
          TRIM(COALESCE([발음3], ''))
        FROM WORD_TABLE
        UNION ALL
        SELECT
          id,
          4,
          TRIM(COALESCE([표기4], '')),
          TRIM(COALESCE([음역4], '')),
          TRIM(COALESCE([발음4], ''))
        FROM WORD_TABLE
        UNION ALL
        SELECT
          id,
          5,
          TRIM(COALESCE([표기5], '')),
          TRIM(COALESCE([음역5], '')),
          TRIM(COALESCE([발음5], ''))
        FROM WORD_TABLE
        UNION ALL
        SELECT
          id,
          6,
          TRIM(COALESCE([표기6], '')),
          TRIM(COALESCE([음역6], '')),
          TRIM(COALESCE([발음6], ''))
        FROM WORD_TABLE
      ),
      expected_expression_set AS (
        SELECT
          word_id,
          ROW_NUMBER() OVER (PARTITION BY word_id ORDER BY source_slot)
            AS seq,
          spelling,
          NULLIF(transliteration, '') AS transliteration,
          NULLIF(pronunciation, '') AS pronunciation
        FROM legacy_slots
        WHERE spelling <> ''
      ),
      expected_expression_set_with_representative AS (
        SELECT
          word_id,
          seq,
          CASE WHEN seq = 1 THEN 1 ELSE 0 END AS is_representative,
          spelling,
          transliteration,
          pronunciation
        FROM expected_expression_set
      ),
      expected_minus_actual AS (
        SELECT
          word_id,
          seq,
          is_representative,
          spelling,
          transliteration,
          pronunciation
        FROM expected_expression_set_with_representative
        EXCEPT
        SELECT
          word_id,
          seq,
          is_representative,
          spelling,
          transliteration,
          pronunciation
        FROM word_expression_set
      ),
      actual_minus_expected AS (
        SELECT
          word_id,
          seq,
          is_representative,
          spelling,
          transliteration,
          pronunciation
        FROM word_expression_set
        EXCEPT
        SELECT
          word_id,
          seq,
          is_representative,
          spelling,
          transliteration,
          pronunciation
        FROM expected_expression_set_with_representative
      )
      SELECT
        (SELECT COUNT(*) FROM expected_expression_set_with_representative)
          AS expected_row_count,
        (SELECT COUNT(*) FROM word_expression_set) AS actual_row_count,
        (SELECT COUNT(*) FROM expected_minus_actual)
          AS expected_minus_actual_count,
        (SELECT COUNT(*) FROM actual_minus_expected)
          AS actual_minus_expected_count
      ''');

    final row = counts.single;
    expect(row['actual_row_count'], row['expected_row_count']);
    expect(row['expected_row_count'], 3);
    expect(row['expected_minus_actual_count'], 0);
    expect(row['actual_minus_expected_count'], 0);
  });

  test('backfills word_meaning_set preserving raw slot seq', () async {
    final db = await DatabaseService.openDatabaseFile();

    final rows = await db.query(
      'word_meaning_set',
      columns: const ['word_id', 'seq', 'meaning'],
      orderBy: 'word_id ASC, seq ASC',
    );

    expect(rows, [
      {'word_id': 'W1', 'seq': 1, 'meaning': ' first '},
      {'word_id': 'W1', 'seq': 7, 'meaning': ' seventh '},
      {'word_id': 'W2', 'seq': 3, 'meaning': '  '},
    ]);

    await DatabaseService.closeDatabase();
    final reopenedDb = await DatabaseService.openDatabaseFile();
    final reopenedCounts = await reopenedDb.rawQuery(
      'SELECT COUNT(*) AS row_count FROM word_meaning_set',
    );
    expect(reopenedCounts.single['row_count'], 3);
  });
}

Future<Directory> _createIsolatedWorkspace(String repoRootPath) async {
  final tmpRoot = Directory(
    p.join(repoRootPath, '.tmp_android_db_baseline_tests'),
  );
  if (!tmpRoot.existsSync()) {
    await tmpRoot.create(recursive: true);
  }

  final isolatedRoot = Directory(
    p.join(tmpRoot.path, 'case_${DateTime.now().microsecondsSinceEpoch}'),
  );
  await isolatedRoot.create(recursive: true);

  final dataDir = Directory(p.join(isolatedRoot.path, 'data'));
  await dataDir.create(recursive: true);

  await _createSyntheticSeedDb(p.join(dataDir.path, 'reshet_seed.db'));

  return isolatedRoot;
}

Future<void> _createSyntheticSeedDb(String path) async {
  final db = await databaseFactory.openDatabase(path);
  try {
    await db.execute('''
      CREATE TABLE WORD_TABLE (
        id TEXT PRIMARY KEY,
        [표기1] TEXT,
        [표기2] TEXT,
        [표기3] TEXT,
        [표기4] TEXT,
        [표기5] TEXT,
        [표기6] TEXT,
        [음역1] TEXT,
        [음역2] TEXT,
        [음역3] TEXT,
        [음역4] TEXT,
        [음역5] TEXT,
        [음역6] TEXT,
        [발음1] TEXT,
        [발음2] TEXT,
        [발음3] TEXT,
        [발음4] TEXT,
        [발음5] TEXT,
        [발음6] TEXT,
        [의미1] TEXT,
        [의미2] TEXT,
        [의미3] TEXT,
        [의미4] TEXT,
        [의미5] TEXT,
        [의미6] TEXT,
        [의미7] TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE WORD_RELATION (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id_1 TEXT NOT NULL,
        word_id_2 TEXT NOT NULL,
        relation_type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE RELATION_CATEGORY (
        code TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        description TEXT NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE RELATION_TYPE (
        code TEXT PRIMARY KEY,
        category_code TEXT NOT NULL,
        label TEXT NOT NULL,
        description TEXT NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE word_expression_set (
        id INTEGER PRIMARY KEY,
        word_id TEXT NOT NULL,
        seq INTEGER NOT NULL,
        is_representative INTEGER NOT NULL,
        spelling TEXT NOT NULL,
        transliteration TEXT,
        pronunciation TEXT
      )
    ''');

    await db.insert('WORD_TABLE', {
      'id': 'W1',
      '표기1': ' alpha ',
      '표기2': 'beta',
      '음역1': ' a ',
      '발음1': ' ah ',
      '의미1': ' first ',
      '의미7': ' seventh ',
    });
    await db.insert('WORD_TABLE', {
      'id': 'W2',
      '표기1': 'gamma',
      '음역1': 'g',
      '발음1': 'ga',
      '의미1': '',
      '의미3': '  ',
    });

    await db.insert('word_expression_set', {
      'word_id': 'W1',
      'seq': 1,
      'is_representative': 1,
      'spelling': 'alpha',
      'transliteration': 'a',
      'pronunciation': 'ah',
    });
    await db.insert('word_expression_set', {
      'word_id': 'W2',
      'seq': 1,
      'is_representative': 1,
      'spelling': 'gamma',
      'transliteration': 'g',
      'pronunciation': 'ga',
    });
  } finally {
    await db.close();
  }
}

Future<void> _stripWordExpressionSetFromSeedCopy(
  String isolatedRootPath,
) async {
  final seedCopyPath = p.join(isolatedRootPath, 'data', 'reshet_seed.db');
  final db = await databaseFactory.openDatabase(seedCopyPath);
  try {
    await db.execute('DROP TABLE IF EXISTS word_expression_set');
  } finally {
    await db.close();
  }
}
