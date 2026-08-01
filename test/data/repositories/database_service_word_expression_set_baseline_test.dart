import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/database_test_isolation_guard.dart';

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
    DatabaseService.setDataRootOverrideForTest(
      p.join(isolatedRoot!.path, 'data'),
    );
    Directory.current = isolatedRoot!.path;
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
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
      expect(counts.single['row_count'], 3);

      final seq7Rows = await db.query(
        'word_expression_set',
        columns: const [
          'word_id',
          'seq',
          'is_representative',
          'spelling',
          'transliteration',
          'pronunciation',
        ],
        where: 'word_id = ? AND seq = ?',
        whereArgs: ['W1', 7],
      );
      expect(seq7Rows, [
        {
          'word_id': 'W1',
          'seq': 7,
          'is_representative': 0,
          'spelling': 'eta',
          'transliteration': 'e',
          'pronunciation': 'eh',
        },
      ]);
    },
  );

  test(
    'adds pronunciation notation columns and keeps backfill idempotent',
    () async {
      final db = await DatabaseService.openDatabaseFile();

      final columns = await db.rawQuery(
        "PRAGMA table_info('word_expression_set')",
      );
      final columnNames = columns.map((row) => row['name']).toSet();
      expect(columnNames, contains('pronunciation_notation'));
      expect(columnNames, contains('pronunciation_notation_name'));

      final initialCounts = await db.rawQuery('''
        SELECT
          COUNT(*) AS total_count,
          SUM(CASE WHEN pronunciation IS NOT NULL THEN 1 ELSE 0 END)
            AS pronunciation_count,
          SUM(
            CASE
              WHEN pronunciation IS NOT NULL
               AND pronunciation_notation = 'unknown'
              THEN 1
              ELSE 0
            END
          ) AS unknown_count
        FROM word_expression_set
      ''');
      expect(
        initialCounts.single['unknown_count'],
        initialCounts.single['pronunciation_count'],
      );

      await db.update(
        'word_expression_set',
        {
          'pronunciation': 'a',
          'pronunciation_notation': 'ipa_phonemic',
          'pronunciation_notation_name': null,
        },
        where: 'word_id = ? AND seq = ?',
        whereArgs: ['W1', 1],
      );
      await db.insert('word_expression_set', {
        'word_id': 'W2',
        'seq': 2,
        'is_representative': 0,
        'spelling': 'no-pronunciation',
        'transliteration': null,
        'pronunciation': null,
        'pronunciation_notation': null,
        'pronunciation_notation_name': null,
      });

      await DatabaseService.ensureRuntimeSchema(db);
      await DatabaseService.ensureRuntimeSchema(db);

      final preservedRows = await db.query(
        'word_expression_set',
        columns: const [
          'pronunciation',
          'pronunciation_notation',
          'pronunciation_notation_name',
        ],
        where: 'word_id = ? AND seq = ?',
        whereArgs: ['W1', 1],
      );
      expect(preservedRows.single, {
        'pronunciation': 'a',
        'pronunciation_notation': 'ipa_phonemic',
        'pronunciation_notation_name': null,
      });

      final nullRows = await db.query(
        'word_expression_set',
        columns: const [
          'pronunciation',
          'pronunciation_notation',
          'pronunciation_notation_name',
        ],
        where: 'word_id = ? AND seq = ?',
        whereArgs: ['W2', 2],
      );
      expect(nullRows.single, {
        'pronunciation': null,
        'pronunciation_notation': null,
        'pronunciation_notation_name': null,
      });
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

    final wordColumns = (await db.rawQuery(
      "PRAGMA table_info('WORD_TABLE')",
    )).map((row) => row['name']).whereType<String>().toSet();
    expect(
      wordColumns.intersection({
        for (final prefix in const ['표기', '음역', '발음'])
          for (var index = 1; index <= 6; index++) '$prefix$index',
      }),
      isEmpty,
    );
    expect(
      await db.query(
        'word_expression_set',
        columns: const [
          'word_id',
          'seq',
          'is_representative',
          'spelling',
          'transliteration',
          'pronunciation',
        ],
        orderBy: 'word_id ASC, seq ASC',
      ),
      [
        {
          'word_id': 'W1',
          'seq': 1,
          'is_representative': 1,
          'spelling': 'alpha',
          'transliteration': 'a',
          'pronunciation': 'ah',
        },
        {
          'word_id': 'W1',
          'seq': 2,
          'is_representative': 0,
          'spelling': 'beta',
          'transliteration': null,
          'pronunciation': null,
        },
        {
          'word_id': 'W2',
          'seq': 1,
          'is_representative': 1,
          'spelling': 'gamma',
          'transliteration': 'g',
          'pronunciation': 'ga',
        },
      ],
    );
    expect(await db.query('WORD_LEGACY_EXPRESSION_VALUE'), isEmpty);
  });

  test(
    'backfills word_meaning_set preserving raw slot seq and removes slots',
    () async {
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
      final wordColumns = (await db.rawQuery(
        "PRAGMA table_info('WORD_TABLE')",
      )).map((row) => row['name']).whereType<String>().toSet();
      expect(
        wordColumns.intersection(const {
          '의미1',
          '의미2',
          '의미3',
          '의미4',
          '의미5',
          '의미6',
          '의미7',
        }),
        isEmpty,
      );

      await DatabaseService.closeDatabase();
      final reopenedDb = await DatabaseService.openDatabaseFile();
      final reopenedCounts = await reopenedDb.rawQuery(
        'SELECT COUNT(*) AS row_count FROM word_meaning_set',
      );
      expect(reopenedCounts.single['row_count'], 3);
    },
  );

  test(
    'rebuilds legacy word_meaning_set seq upper-bound schema preserving rows',
    () async {
      await DatabaseService.closeDatabase();
      await _installLegacyWordMeaningSetWithSeqLimit(isolatedRoot!.path);

      final db = await DatabaseService.openDatabaseFile();
      final schemaRows = await db.rawQuery('''
        SELECT sql
        FROM sqlite_master
        WHERE type = 'table'
          AND name = 'word_meaning_set'
      ''');
      expect(schemaRows, hasLength(1));
      expect(
        (schemaRows.single['sql'] ?? '').toString(),
        isNot(contains('seq <= 7')),
      );

      final preservedRows = await db.query(
        'word_meaning_set',
        columns: const ['word_id', 'seq', 'meaning'],
        orderBy: 'word_id ASC, seq ASC',
      );
      expect(preservedRows, [
        {'word_id': 'W1', 'seq': 1, 'meaning': ' first '},
        {'word_id': 'W1', 'seq': 7, 'meaning': ' seventh '},
        {'word_id': 'W2', 'seq': 3, 'meaning': '  '},
      ]);

      await db.insert('word_meaning_set', {
        'word_id': 'W1',
        'seq': 8,
        'meaning': 'legacy eighth now allowed',
      });
      final seq8Rows = await db.query(
        'word_meaning_set',
        columns: const ['word_id', 'seq', 'meaning'],
        where: 'word_id = ? AND seq = ?',
        whereArgs: ['W1', 8],
      );
      expect(seq8Rows, [
        {'word_id': 'W1', 'seq': 8, 'meaning': 'legacy eighth now allowed'},
      ]);
    },
  );
}

Future<Directory> _createIsolatedWorkspace(String repoRootPath) async {
  final isolatedRoot = await Directory.systemTemp.createTemp(
    'reshet_android_db_baseline_tests_',
  );
  final dataDir = Directory(p.join(isolatedRoot.path, 'data'));
  ensureSystemTempDatabaseTargets(
    dataRootPath: dataDir.path,
    actualWorkDbPath: p.join(repoRootPath, 'data', 'reshet_work.db'),
    actualSeedDbPath: p.join(repoRootPath, 'data', 'reshet_seed.db'),
  );
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
        [의미1] TEXT,
        [의미2] TEXT,
        [의미3] TEXT,
        [의미4] TEXT,
        [의미5] TEXT,
        [의미6] TEXT,
        [의미7] TEXT
      )
    ''');
    await db.execute(_legacyRelatedArchiveDdl);
    await db.execute(_legacyExpressionArchiveDdl);

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
      CREATE TABLE RELATION_STATUS (
        code TEXT PRIMARY KEY,
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
      '의미1': ' first ',
      '의미7': ' seventh ',
    });
    await db.insert('WORD_TABLE', {'id': 'W2', '의미1': '', '의미3': '  '});

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
    await db.insert('word_expression_set', {
      'word_id': 'W1',
      'seq': 7,
      'is_representative': 0,
      'spelling': 'eta',
      'transliteration': 'e',
      'pronunciation': 'eh',
    });
  } finally {
    await db.close();
  }
}

const _legacyRelatedArchiveDdl = '''
  CREATE TABLE WORD_LEGACY_RELATED_VALUE (
    source_word_id TEXT NOT NULL,
    source_column TEXT NOT NULL CHECK (
      source_column IN (
        '관련1',
        '관련2',
        '관련3',
        '관련4',
        '관련5',
        '관련6',
        '관련7'
      )
    ),
    target_raw_value TEXT NOT NULL,
    preservation_state TEXT NOT NULL CHECK (
      preservation_state = 'unresolved_legacy'
    ),
    source_table TEXT NOT NULL CHECK (source_table = 'WORD_TABLE'),
    PRIMARY KEY (source_word_id, source_column)
  )
''';

const _legacyExpressionArchiveDdl = '''
  CREATE TABLE WORD_LEGACY_EXPRESSION_VALUE (
    source_word_id TEXT NOT NULL,
    expression_type TEXT NOT NULL CHECK (
      expression_type IN ('spelling', 'transliteration', 'pronunciation')
    ),
    source_slot INTEGER NOT NULL CHECK (source_slot BETWEEN 1 AND 6),
    raw_value TEXT NOT NULL,
    preservation_reason TEXT NOT NULL CHECK (
      preservation_reason = 'trailing_space_only'
    ),
    source_table TEXT NOT NULL CHECK (source_table = 'WORD_TABLE'),
    PRIMARY KEY (source_word_id, expression_type, source_slot)
  )
''';

Future<void> _stripWordExpressionSetFromSeedCopy(
  String isolatedRootPath,
) async {
  final seedCopyPath = p.join(isolatedRootPath, 'data', 'reshet_seed.db');
  final db = await databaseFactory.openDatabase(seedCopyPath);
  try {
    await db.execute('DROP TABLE IF EXISTS word_expression_set');
    await db.execute('DROP TABLE WORD_LEGACY_EXPRESSION_VALUE');
    for (final prefix in const ['표기', '음역', '발음']) {
      for (var index = 1; index <= 6; index++) {
        await db.execute(
          'ALTER TABLE WORD_TABLE ADD COLUMN "$prefix$index" TEXT',
        );
      }
    }
    await db.update(
      'WORD_TABLE',
      const {'표기1': 'alpha', '음역1': 'a', '발음1': 'ah', '표기2': 'beta'},
      where: 'id = ?',
      whereArgs: ['W1'],
    );
    await db.update(
      'WORD_TABLE',
      const {'표기1': 'gamma', '음역1': 'g', '발음1': 'ga'},
      where: 'id = ?',
      whereArgs: ['W2'],
    );
  } finally {
    await db.close();
  }
}

Future<void> _installLegacyWordMeaningSetWithSeqLimit(
  String isolatedRootPath,
) async {
  final seedCopyPath = p.join(isolatedRootPath, 'data', 'reshet_seed.db');
  final db = await databaseFactory.openDatabase(seedCopyPath);
  try {
    await db.execute('''
      CREATE TABLE word_meaning_set (
        id INTEGER PRIMARY KEY,
        word_id TEXT NOT NULL,
        seq INTEGER NOT NULL,
        meaning TEXT NOT NULL,
        CHECK (seq >= 1 AND seq <= 7),
        CHECK (meaning <> '')
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX ux_word_meaning_set_word_seq
      ON word_meaning_set(word_id, seq)
    ''');
    await db.insert('word_meaning_set', {
      'word_id': 'W1',
      'seq': 1,
      'meaning': ' first ',
    });
    await db.insert('word_meaning_set', {
      'word_id': 'W1',
      'seq': 7,
      'meaning': ' seventh ',
    });
    await db.insert('word_meaning_set', {
      'word_id': 'W2',
      'seq': 3,
      'meaning': '  ',
    });
  } finally {
    await db.close();
  }
}
