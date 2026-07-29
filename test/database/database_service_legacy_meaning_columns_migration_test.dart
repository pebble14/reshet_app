import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/database_test_isolation_guard.dart';

const _legacyMeaningColumns = ['의미1', '의미2', '의미3', '의미4', '의미5', '의미6', '의미7'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String repositoryRoot;
  late Directory dataRoot;
  late String workPath;

  setUpAll(() async {
    repositoryRoot = Directory.current.path;
    await DatabaseService.closeDatabase();
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    dataRoot = await Directory.systemTemp.createTemp(
      'reshet_legacy_meaning_migration_',
    );
    ensureSystemTempDatabaseTargets(
      dataRootPath: dataRoot.path,
      actualWorkDbPath: p.join(repositoryRoot, 'data', 'reshet_work.db'),
      actualSeedDbPath: p.join(repositoryRoot, 'data', 'reshet_seed.db'),
    );
    workPath = p.join(dataRoot.path, 'reshet_work.db');
    DatabaseService.setDataRootOverrideForTest(dataRoot.path);
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    if (await dataRoot.exists()) {
      await dataRoot.delete(recursive: true);
    }
  });

  test(
    'legacy-only startup은 raw slot seq를 materialize하고 물리 컬럼을 제거한다',
    () async {
      final fixture = await _createFixture(
        workPath,
        meaningColumns: _legacyMeaningColumns,
        legacyMeanings: const {
          'W1': {'의미1': ' first ', '의미2': '', '의미7': ' seventh '},
          'W2': {'의미3': '  '},
        },
        createCanonicalTable: false,
      );
      final schemaVersionBefore = await _schemaVersion(fixture);
      final columnContractBefore = await _wordTableColumnContract(
        fixture,
        excludeMeaningColumns: true,
      );
      final wordRowsBefore = await _wordRowsWithoutMeaningColumns(fixture);
      final schemaObjectsBefore = await _wordTableSchemaObjects(fixture);
      await fixture.close();

      final opened = await DatabaseService.openDatabaseFile();

      expect(await _presentMeaningColumns(opened), isEmpty);
      expect(
        await opened.query(
          'word_meaning_set',
          columns: const ['word_id', 'seq', 'meaning'],
          orderBy: 'word_id ASC, seq ASC',
        ),
        [
          {'word_id': 'W1', 'seq': 1, 'meaning': ' first '},
          {'word_id': 'W1', 'seq': 7, 'meaning': ' seventh '},
          {'word_id': 'W2', 'seq': 3, 'meaning': '  '},
        ],
      );
      expect(
        await _wordTableColumnContract(opened, excludeMeaningColumns: false),
        columnContractBefore,
      );
      expect(await _wordRowsWithoutMeaningColumns(opened), wordRowsBefore);
      expect(await _wordTableSchemaObjects(opened), schemaObjectsBefore);
      expect(await opened.rawQuery('PRAGMA integrity_check'), [
        {'integrity_check': 'ok'},
      ]);
      expect(await opened.rawQuery('PRAGMA foreign_key_check'), isEmpty);

      final schemaVersionAfterFirstEnsure = await _schemaVersion(opened);
      expect(schemaVersionAfterFirstEnsure, greaterThan(schemaVersionBefore));
      final canonicalRowsBeforeSecondEnsure = await opened.query(
        'word_meaning_set',
        orderBy: 'word_id ASC, seq ASC, id ASC',
      );

      await DatabaseService.ensureRuntimeSchema(opened);

      expect(await _schemaVersion(opened), schemaVersionAfterFirstEnsure);
      expect(
        await opened.query(
          'word_meaning_set',
          orderBy: 'word_id ASC, seq ASC, id ASC',
        ),
        canonicalRowsBeforeSecondEnsure,
      );
    },
  );

  test('기존 canonical과 seq 8 이상은 변경 없이 보존한다', () async {
    final db = await _createFixture(
      workPath,
      meaningColumns: _legacyMeaningColumns,
      legacyMeanings: const {
        'W1': {'의미1': 'canonical first'},
      },
      canonicalRows: const [
        {'id': 10, 'word_id': 'W1', 'seq': 1, 'meaning': 'canonical first'},
        {'id': 11, 'word_id': 'W1', 'seq': 8, 'meaning': 'canonical eighth'},
      ],
    );
    final canonicalRowsBefore = await db.query(
      'word_meaning_set',
      orderBy: 'word_id ASC, seq ASC, id ASC',
    );

    await DatabaseService.ensureRuntimeSchema(db);

    expect(await _presentMeaningColumns(db), isEmpty);
    expect(
      await db.query(
        'word_meaning_set',
        orderBy: 'word_id ASC, seq ASC, id ASC',
      ),
      canonicalRowsBefore,
    );
    expect(
      await db.rawQuery(
        'SELECT COUNT(*) AS row_count '
        'FROM word_meaning_set WHERE seq > 7',
      ),
      [
        {'row_count': 1},
      ],
    );
    await db.close();
  });

  test('canonical과 충돌하는 legacy-only 값은 fail-closed한다', () async {
    final db = await _createFixture(
      workPath,
      meaningColumns: _legacyMeaningColumns,
      legacyMeanings: const {
        'W1': {'의미1': 'legacy conflict'},
      },
      canonicalRows: const [
        {'id': 20, 'word_id': 'W1', 'seq': 1, 'meaning': 'canonical value'},
      ],
    );
    final canonicalRowsBefore = await db.query('word_meaning_set');

    await expectLater(
      DatabaseService.ensureRuntimeSchema(db),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          contains('canonical meaning으로 보존되지 않은 legacy 의미'),
        ),
      ),
    );

    expect(await _presentMeaningColumns(db), _legacyMeaningColumns.toSet());
    expect(await db.query('word_meaning_set'), canonicalRowsBefore);
    await db.close();
  });

  test('일부 meaning 컬럼만 있는 schema는 변경하지 않고 거절한다', () async {
    final db = await _createFixture(
      workPath,
      meaningColumns: _legacyMeaningColumns.take(3).toList(growable: false),
      legacyMeanings: const {
        'W1': {'의미1': 'partial'},
      },
      createCanonicalTable: false,
    );

    await expectLater(
      DatabaseService.ensureRuntimeSchema(db),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          contains('legacy 의미 컬럼이 일부만 존재합니다'),
        ),
      ),
    );

    expect(
      await _presentMeaningColumns(db),
      _legacyMeaningColumns.take(3).toSet(),
    );
    await db.close();
  });

  test('meaning 물리 컬럼이 없는 신규 schema는 조회 없이 멱등적으로 열린다', () async {
    final db = await _createFixture(
      workPath,
      meaningColumns: const [],
      canonicalRows: const [
        {'id': 30, 'word_id': 'W1', 'seq': 8, 'meaning': 'current eighth'},
      ],
    );

    await DatabaseService.ensureRuntimeSchema(db);
    final schemaVersionAfterFirstEnsure = await _schemaVersion(db);
    final canonicalRowsAfterFirstEnsure = await db.query('word_meaning_set');

    await DatabaseService.ensureRuntimeSchema(db);

    expect(await _presentMeaningColumns(db), isEmpty);
    expect(await _schemaVersion(db), schemaVersionAfterFirstEnsure);
    expect(await db.query('word_meaning_set'), canonicalRowsAfterFirstEnsure);
    await db.close();
  });
}

Future<Database> _createFixture(
  String path, {
  required List<String> meaningColumns,
  Map<String, Map<String, Object?>> legacyMeanings = const {},
  bool createCanonicalTable = true,
  List<Map<String, Object?>> canonicalRows = const [],
}) async {
  final db = await databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await db.execute('PRAGMA foreign_keys = ON');
  final meaningColumnSql = meaningColumns
      .map((column) => '"$column" TEXT')
      .join(',\n');
  final optionalMeaningColumns = meaningColumnSql.isEmpty
      ? ''
      : '$meaningColumnSql,';
  await db.execute('''
    CREATE TABLE WORD_TABLE (
      id TEXT PRIMARY KEY,
      언어 TEXT,
      스트롱넘버 TEXT,
      표기1 TEXT,
      표기2 TEXT,
      표기3 TEXT,
      표기4 TEXT,
      표기5 TEXT,
      표기6 TEXT,
      음역1 TEXT,
      음역2 TEXT,
      음역3 TEXT,
      음역4 TEXT,
      음역5 TEXT,
      음역6 TEXT,
      발음1 TEXT,
      발음2 TEXT,
      발음3 TEXT,
      발음4 TEXT,
      발음5 TEXT,
      발음6 TEXT,
      $optionalMeaningColumns
      비고 TEXT,
      retained_value TEXT NOT NULL DEFAULT 'kept',
      graph_expand_mode TEXT NOT NULL DEFAULT 'default'
    )
  ''');
  await db.execute(_legacyRelatedArchiveDdl);
  await db.execute('''
    CREATE TABLE WORD_RELATION (
      id INTEGER PRIMARY KEY,
      word_id_1 TEXT NOT NULL,
      word_id_2 TEXT NOT NULL,
      category_code TEXT,
      relation_type TEXT,
      status_code TEXT DEFAULT 'asserted',
      direction_code TEXT NOT NULL DEFAULT 'unknown',
      description TEXT,
      relation_group_id TEXT
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
      pronunciation TEXT,
      pronunciation_notation TEXT,
      pronunciation_notation_name TEXT,
      FOREIGN KEY (word_id) REFERENCES WORD_TABLE(id) ON DELETE CASCADE
    )
  ''');
  if (createCanonicalTable) {
    await db.execute('''
      CREATE TABLE word_meaning_set (
        id INTEGER PRIMARY KEY,
        word_id TEXT NOT NULL,
        seq INTEGER NOT NULL,
        meaning TEXT NOT NULL,
        FOREIGN KEY (word_id) REFERENCES WORD_TABLE(id) ON DELETE CASCADE,
        CHECK (seq >= 1),
        CHECK (meaning <> '')
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX ux_word_meaning_set_word_seq
      ON word_meaning_set(word_id, seq)
    ''');
  }
  await db.execute('''
    CREATE TABLE RELATION_CATEGORY (
      code TEXT PRIMARY KEY,
      label TEXT NOT NULL,
      description TEXT,
      sort_order INTEGER DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE RELATION_TYPE (
      code TEXT PRIMARY KEY,
      category_code TEXT NOT NULL,
      label TEXT NOT NULL,
      description TEXT,
      sort_order INTEGER DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE RELATION_STATUS (
      code TEXT PRIMARY KEY,
      label TEXT NOT NULL,
      description TEXT,
      sort_order INTEGER DEFAULT 0
    )
  ''');

  for (final wordId in const ['W1', 'W2']) {
    await db.insert('WORD_TABLE', {
      'id': wordId,
      '언어': '테스트언어',
      '스트롱넘버': wordId,
      '표기1': 'spelling-$wordId',
      '비고': 'note-$wordId',
      ...?legacyMeanings[wordId],
    });
  }
  for (final row in canonicalRows) {
    await db.insert('word_meaning_set', row);
  }

  await db.execute(
    'CREATE INDEX idx_word_table_retained_value '
    'ON WORD_TABLE(retained_value)',
  );
  await db.execute('''
    CREATE TRIGGER trg_word_table_retained_insert
    AFTER INSERT ON WORD_TABLE
    WHEN NEW.retained_value = ''
    BEGIN
      UPDATE WORD_TABLE
      SET retained_value = 'kept'
      WHERE id = NEW.id;
    END
  ''');
  return db;
}

Future<Set<String>> _presentMeaningColumns(DatabaseExecutor db) async {
  final columns = await db.rawQuery("PRAGMA table_info('WORD_TABLE')");
  final names = columns.map((row) => row['name']).whereType<String>().toSet();
  return _legacyMeaningColumns.where(names.contains).toSet();
}

Future<int> _schemaVersion(DatabaseExecutor db) async {
  final rows = await db.rawQuery('PRAGMA schema_version');
  return rows.single['schema_version'] as int;
}

Future<List<Map<String, Object?>>> _wordTableColumnContract(
  DatabaseExecutor db, {
  required bool excludeMeaningColumns,
}) async {
  final rows = await db.rawQuery("PRAGMA table_info('WORD_TABLE')");
  return [
    for (final row in rows)
      if (!excludeMeaningColumns ||
          !_legacyMeaningColumns.contains((row['name'] ?? '').toString()))
        {
          'name': row['name'],
          'type': row['type'],
          'notnull': row['notnull'],
          'dflt_value': row['dflt_value'],
          'pk': row['pk'],
        },
  ];
}

Future<List<Map<String, Object?>>> _wordRowsWithoutMeaningColumns(
  DatabaseExecutor db,
) async {
  final columns = (await db.rawQuery("PRAGMA table_info('WORD_TABLE')"))
      .map((row) => row['name'])
      .whereType<String>()
      .where((column) => !_legacyMeaningColumns.contains(column))
      .toList(growable: false);
  return db.query('WORD_TABLE', columns: columns, orderBy: 'id ASC');
}

Future<List<Map<String, Object?>>> _wordTableSchemaObjects(
  DatabaseExecutor db,
) {
  return db.rawQuery('''
    SELECT type, name, sql
    FROM sqlite_master
    WHERE tbl_name = 'WORD_TABLE'
      AND type IN ('index', 'trigger')
    ORDER BY type ASC, name ASC
  ''');
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
