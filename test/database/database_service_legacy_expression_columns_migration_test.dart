import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/database/database_snapshot_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _legacyExpressionColumns = [
  '표기1',
  '표기2',
  '표기3',
  '표기4',
  '표기5',
  '표기6',
  '음역1',
  '음역2',
  '음역3',
  '음역4',
  '음역5',
  '음역6',
  '발음1',
  '발음2',
  '발음3',
  '발음4',
  '발음5',
  '발음6',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUpAll(() async {
    await DatabaseService.closeDatabase();
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    root = await Directory.systemTemp.createTemp(
      'reshet_legacy_expression_migration_',
    );
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test(
    'full legacy schema를 exact raw archive와 canonical-only schema로 이관한다',
    () async {
      final db = await _createFixtureDatabase(
        p.join(root.path, 'full_legacy.db'),
        expressionColumns: _legacyExpressionColumns,
      );
      try {
        final canonicalBefore = await _canonicalSnapshot(db);
        final coreRowsBefore = await _wordCoreRows(db);
        final remainingContractBefore = await _remainingWordColumnContract(db);
        final ownedSchemaBefore = await _ownedWordSchema(db);

        await DatabaseService.ensureRuntimeSchema(db);

        expect(await _presentLegacyExpressionColumns(db), isEmpty);
        expect(await _canonicalSnapshot(db), canonicalBefore);
        expect(await _wordCoreRows(db), coreRowsBefore);
        expect(await _remainingWordColumnContract(db), remainingContractBefore);
        expect(await _ownedWordSchema(db), ownedSchemaBefore);
        expect(await _archiveRows(db), [
          {
            'source_word_id': 'W1',
            'expression_type': 'pronunciation',
            'source_slot': 1,
            'raw_value': 'alpha-pron ',
            'preservation_reason': 'trailing_space_only',
            'source_table': 'WORD_TABLE',
          },
        ]);

        final archiveColumns = await db.rawQuery(
          "PRAGMA table_info('WORD_LEGACY_EXPRESSION_VALUE')",
        );
        expect(
          archiveColumns.map((row) => row['name']).toList(growable: false),
          [
            'source_word_id',
            'expression_type',
            'source_slot',
            'raw_value',
            'preservation_reason',
            'source_table',
          ],
        );
        expect(await db.rawQuery('PRAGMA integrity_check'), [
          {'integrity_check': 'ok'},
        ]);
        expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);

        final schemaVersionBeforeSecondRun = (await db.rawQuery(
          'PRAGMA schema_version',
        )).single['schema_version'];
        final archiveBeforeSecondRun = await _archiveRows(db);
        final canonicalBeforeSecondRun = await _canonicalSnapshot(db);
        final wordRowsBeforeSecondRun = await _wordCoreRows(db);

        await DatabaseService.ensureRuntimeSchema(db);

        expect(
          (await db.rawQuery('PRAGMA schema_version')).single['schema_version'],
          schemaVersionBeforeSecondRun,
        );
        expect(await _archiveRows(db), archiveBeforeSecondRun);
        expect(await _canonicalSnapshot(db), canonicalBeforeSecondRun);
        expect(await _wordCoreRows(db), wordRowsBeforeSecondRun);
      } finally {
        await db.close();
      }
    },
  );

  test('이미 canonical-only인 schema의 재실행은 archive와 schema를 바꾸지 않는다', () async {
    final db = await _createFixtureDatabase(
      p.join(root.path, 'canonical_only.db'),
      expressionColumns: const [],
      createExpressionArchive: true,
      prepopulateExpressionArchive: true,
    );
    try {
      await DatabaseService.ensureRuntimeSchema(db);
      final schemaVersionBefore = (await db.rawQuery(
        'PRAGMA schema_version',
      )).single['schema_version'];
      final schemaBefore = await _databaseSchema(db);
      final archiveBefore = await _archiveRows(db);
      final canonicalBefore = await _canonicalSnapshot(db);

      await DatabaseService.ensureRuntimeSchema(db);

      expect(
        (await db.rawQuery('PRAGMA schema_version')).single['schema_version'],
        schemaVersionBefore,
      );
      expect(await _databaseSchema(db), schemaBefore);
      expect(await _archiveRows(db), archiveBefore);
      expect(await _canonicalSnapshot(db), canonicalBefore);
    } finally {
      await db.close();
    }
  });

  test('표현 컬럼 일부만 존재하면 다른 schema나 data를 쓰기 전에 fail-closed한다', () async {
    final db = await _createFixtureDatabase(
      p.join(root.path, 'partial_legacy.db'),
      expressionColumns: _legacyExpressionColumns.sublist(0, 17),
    );
    try {
      final schemaVersionBefore = (await db.rawQuery(
        'PRAGMA schema_version',
      )).single['schema_version'];
      final schemaBefore = await _databaseSchema(db);
      final wordRowsBefore = await _wordCoreRows(db);
      final canonicalBefore = await _canonicalSnapshot(db);

      await expectLater(
        DatabaseService.ensureRuntimeSchema(db),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            contains('일부만 존재'),
          ),
        ),
      );

      expect(
        (await db.rawQuery('PRAGMA schema_version')).single['schema_version'],
        schemaVersionBefore,
      );
      expect(await _databaseSchema(db), schemaBefore);
      expect(await _wordCoreRows(db), wordRowsBefore);
      expect(await _canonicalSnapshot(db), canonicalBefore);
      expect(await _tableExists(db, 'WORD_LEGACY_EXPRESSION_VALUE'), isFalse);
    } finally {
      await db.close();
    }
  });

  test('비공백 값·legacy-only·canonical-only 불일치는 archive하지 않고 거부한다', () async {
    final cases = <({String name, FixtureMutation mutation})>[
      (
        name: 'non_space',
        mutation: (db) => db.update(
          'WORD_TABLE',
          {'발음1': 'different'},
          where: 'id = ?',
          whereArgs: ['W1'],
        ),
      ),
      (
        name: 'legacy_only',
        mutation: (db) => db.update(
          'WORD_TABLE',
          {'표기3': 'legacy-only'},
          where: 'id = ?',
          whereArgs: ['W1'],
        ),
      ),
      (
        name: 'canonical_only',
        mutation: (db) => db.insert('word_expression_set', {
          'word_id': 'W1',
          'seq': 3,
          'is_representative': 0,
          'spelling': 'canonical-only',
          'pronunciation_notation': null,
        }),
      ),
    ];

    for (final testCase in cases) {
      final db = await _createFixtureDatabase(
        p.join(root.path, '${testCase.name}.db'),
        expressionColumns: _legacyExpressionColumns,
      );
      try {
        await testCase.mutation(db);
        final canonicalBefore = await _canonicalSnapshot(db);

        await expectLater(
          DatabaseService.ensureRuntimeSchema(db),
          throwsA(isA<StateError>()),
          reason: testCase.name,
        );

        expect(
          await _presentLegacyExpressionColumns(db),
          _legacyExpressionColumns.toSet(),
          reason: testCase.name,
        );
        expect(
          await _tableExists(db, 'WORD_LEGACY_EXPRESSION_VALUE'),
          isFalse,
          reason: testCase.name,
        );
        expect(
          await _canonicalSnapshot(db),
          canonicalBefore,
          reason: testCase.name,
        );
      } finally {
        await db.close();
      }
    }
  });

  test('호환되지 않는 기존 archive schema는 migration 쓰기 전에 거부한다', () async {
    final db = await _createFixtureDatabase(
      p.join(root.path, 'invalid_archive.db'),
      expressionColumns: _legacyExpressionColumns,
      createIncompatibleExpressionArchive: true,
    );
    try {
      final schemaBefore = await _databaseSchema(db);
      final wordRowsBefore = await _wordCoreRows(db);

      await expectLater(
        DatabaseService.ensureRuntimeSchema(db),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            contains('DDL 계약'),
          ),
        ),
      );

      expect(await _databaseSchema(db), schemaBefore);
      expect(await _wordCoreRows(db), wordRowsBefore);
      expect(
        await _presentLegacyExpressionColumns(db),
        _legacyExpressionColumns.toSet(),
      );
    } finally {
      await db.close();
    }
  });

  test('중간 DROP COLUMN 실패 시 archive와 앞선 DROP을 모두 rollback한다', () async {
    final db = await _createFixtureDatabase(
      p.join(root.path, 'drop_failure.db'),
      expressionColumns: _legacyExpressionColumns,
      addBlockingPronunciationIndex: true,
    );
    try {
      final canonicalBefore = await _canonicalSnapshot(db);
      final wordRowsBefore = await _wordRowsIncludingLegacy(db);

      await expectLater(
        DatabaseService.ensureRuntimeSchema(db),
        throwsA(isA<StateError>()),
      );

      expect(
        await _presentLegacyExpressionColumns(db),
        _legacyExpressionColumns.toSet(),
      );
      expect(await _tableExists(db, 'WORD_LEGACY_EXPRESSION_VALUE'), isFalse);
      expect(await _canonicalSnapshot(db), canonicalBefore);
      expect(await _wordRowsIncludingLegacy(db), wordRowsBefore);
    } finally {
      await db.close();
    }
  });

  test('restore validator는 full/none만 허용하고 runtime은 none만 허용한다', () async {
    final validator = const DatabaseRestoreSchemaValidator();
    final full = await _createFixtureDatabase(
      p.join(root.path, 'validator_full.db'),
      expressionColumns: _legacyExpressionColumns,
    );
    final none = await _createFixtureDatabase(
      p.join(root.path, 'validator_none.db'),
      expressionColumns: const [],
      createExpressionArchive: true,
      prepopulateExpressionArchive: true,
    );
    final partial = await _createFixtureDatabase(
      p.join(root.path, 'validator_partial.db'),
      expressionColumns: _legacyExpressionColumns.sublist(1),
    );
    try {
      await validator.validateConnection(full);
      await validator.validateConnection(none);
      await validator.validateRuntimeConnection(none);

      await expectLater(
        validator.validateRuntimeConnection(full),
        throwsA(
          isA<DatabaseValidationException>().having(
            (error) => error.failure,
            'failure',
            DatabaseValidationFailure.schemaIncompatible,
          ),
        ),
      );
      await expectLater(
        validator.validateConnection(partial),
        throwsA(
          isA<DatabaseValidationException>().having(
            (error) => error.failure,
            'failure',
            DatabaseValidationFailure.schemaIncompatible,
          ),
        ),
      );
    } finally {
      await full.close();
      await none.close();
      await partial.close();
    }
  });
}

typedef FixtureMutation = Future<Object?> Function(Database database);

Future<Database> _createFixtureDatabase(
  String path, {
  required List<String> expressionColumns,
  bool createExpressionArchive = false,
  bool prepopulateExpressionArchive = false,
  bool createIncompatibleExpressionArchive = false,
  bool addBlockingPronunciationIndex = false,
}) async {
  final db = await databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await db.execute('PRAGMA foreign_keys = ON');

  final expressionColumnSql = expressionColumns
      .map((column) => '${_quoteIdentifier(column)} TEXT')
      .join(',\n');
  await db.execute('''
    CREATE TABLE WORD_TABLE (
      id TEXT PRIMARY KEY,
      언어 TEXT,
      스트롱넘버 TEXT,
      ${expressionColumnSql.isEmpty ? '' : '$expressionColumnSql,'}
      비고 TEXT,
      graph_expand_mode TEXT NOT NULL DEFAULT 'default'
    )
  ''');
  await db.execute('CREATE INDEX idx_word_table_strong ON WORD_TABLE(스트롱넘버)');
  await db.execute('''
    CREATE TRIGGER trg_word_table_note_noop
    AFTER UPDATE OF 비고 ON WORD_TABLE
    BEGIN
      SELECT NEW.id;
    END
  ''');
  if (addBlockingPronunciationIndex) {
    await db.execute('CREATE INDEX idx_block_drop ON WORD_TABLE(발음1)');
  }

  await db.execute(_legacyRelatedArchiveDdl);
  if (createExpressionArchive) {
    await db.execute(_legacyExpressionArchiveDdl);
  } else if (createIncompatibleExpressionArchive) {
    await db.execute('''
      CREATE TABLE WORD_LEGACY_EXPRESSION_VALUE (
        source_word_id TEXT PRIMARY KEY,
        raw_value TEXT
      )
    ''');
  }

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
      relation_group_id TEXT,
      note TEXT,
      source TEXT,
      created_at TEXT,
      updated_at TEXT
    )
  ''');
  await db.execute('''
    CREATE INDEX idx_word_relation_signature_lookup
    ON WORD_RELATION(
      word_id_1,
      word_id_2,
      COALESCE(relation_type, ''),
      COALESCE(direction_code, 'unknown')
    )
  ''');
  await db.execute('''
    CREATE UNIQUE INDEX idx_word_relation_pair_type_direction_unique
    ON WORD_RELATION(
      word_id_1,
      word_id_2,
      COALESCE(relation_type, ''),
      COALESCE(direction_code, 'unknown')
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
  await db.execute('''
    CREATE UNIQUE INDEX ux_word_expression_set_word_seq
    ON word_expression_set(word_id, seq)
  ''');
  await db.execute('''
    CREATE UNIQUE INDEX ux_word_expression_set_one_representative
    ON word_expression_set(word_id)
    WHERE is_representative = 1
  ''');
  await db.execute('''
    CREATE TABLE word_meaning_set (
      id INTEGER PRIMARY KEY,
      word_id TEXT NOT NULL,
      seq INTEGER NOT NULL,
      meaning TEXT NOT NULL,
      FOREIGN KEY (word_id) REFERENCES WORD_TABLE(id) ON DELETE CASCADE
    )
  ''');
  await db.execute('''
    CREATE UNIQUE INDEX ux_word_meaning_set_word_seq
    ON word_meaning_set(word_id, seq)
  ''');
  await db.execute('''
    CREATE TABLE CHANGE_HISTORY (
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
  await db.execute(_rmacTableDdl('RMAC_TABLE'));
  await db.execute(_rmacTableDdl('RMAC_TABLE_KR'));

  final w1 = <String, Object?>{
    'id': 'W1',
    '언어': 'test',
    '스트롱넘버': 'H1',
    '비고': 'first',
    '표기1': 'alpha',
    '음역1': '알파',
    '발음1': 'alpha-pron ',
    '표기2': 'beta',
    '음역2': null,
    '발음2': 'beta-pron',
  };
  final w2 = <String, Object?>{
    'id': 'W2',
    '언어': 'test',
    '스트롱넘버': 'G2',
    '비고': 'second',
    '표기1': 'gamma',
    '음역1': '감마',
    '발음1': null,
  };
  await db.insert('WORD_TABLE', _filterWordRow(w1, expressionColumns));
  await db.insert('WORD_TABLE', _filterWordRow(w2, expressionColumns));

  await _insertExpression(
    db,
    wordId: 'W1',
    seq: 1,
    representative: 1,
    spelling: 'alpha',
    transliteration: '알파',
    pronunciation: 'alpha-pron',
  );
  await _insertExpression(
    db,
    wordId: 'W1',
    seq: 2,
    representative: 0,
    spelling: 'beta',
    pronunciation: 'beta-pron',
  );
  await _insertExpression(
    db,
    wordId: 'W2',
    seq: 1,
    representative: 1,
    spelling: 'gamma',
    transliteration: '감마',
  );
  await db.insert('word_meaning_set', {
    'word_id': 'W1',
    'seq': 1,
    'meaning': 'first meaning',
  });

  if (prepopulateExpressionArchive) {
    await db.insert('WORD_LEGACY_EXPRESSION_VALUE', {
      'source_word_id': 'W1',
      'expression_type': 'pronunciation',
      'source_slot': 1,
      'raw_value': 'alpha-pron ',
      'preservation_reason': 'trailing_space_only',
      'source_table': 'WORD_TABLE',
    });
  }

  return db;
}

Map<String, Object?> _filterWordRow(
  Map<String, Object?> source,
  List<String> expressionColumns,
) {
  final allowed = {'id', '언어', '스트롱넘버', '비고', ...expressionColumns};
  return {
    for (final entry in source.entries)
      if (allowed.contains(entry.key)) entry.key: entry.value,
  };
}

Future<void> _insertExpression(
  Database db, {
  required String wordId,
  required int seq,
  required int representative,
  required String spelling,
  String? transliteration,
  String? pronunciation,
}) async {
  await db.insert('word_expression_set', {
    'word_id': wordId,
    'seq': seq,
    'is_representative': representative,
    'spelling': spelling,
    'transliteration': transliteration,
    'pronunciation': pronunciation,
    'pronunciation_notation': pronunciation == null ? null : 'unknown',
    'pronunciation_notation_name': null,
  });
}

Future<Set<String>> _presentLegacyExpressionColumns(Database db) async {
  final rows = await db.rawQuery("PRAGMA table_info('WORD_TABLE')");
  final names = rows.map((row) => row['name']).whereType<String>().toSet();
  return _legacyExpressionColumns.where(names.contains).toSet();
}

Future<List<Map<String, Object?>>> _archiveRows(Database db) {
  return db.query(
    'WORD_LEGACY_EXPRESSION_VALUE',
    orderBy: 'source_word_id ASC, expression_type ASC, source_slot ASC',
  );
}

Future<String> _canonicalSnapshot(Database db) async {
  return jsonEncode(
    await db.query(
      'word_expression_set',
      orderBy: 'word_id ASC, seq ASC, id ASC',
    ),
  );
}

Future<String> _wordCoreRows(Database db) async {
  return jsonEncode(
    await db.query(
      'WORD_TABLE',
      columns: const ['id', '언어', '스트롱넘버', '비고', 'graph_expand_mode'],
      orderBy: 'id ASC',
    ),
  );
}

Future<String> _wordRowsIncludingLegacy(Database db) async {
  return jsonEncode(await db.query('WORD_TABLE', orderBy: 'id ASC'));
}

Future<String> _remainingWordColumnContract(Database db) async {
  final rows = await db.rawQuery("PRAGMA table_info('WORD_TABLE')");
  return jsonEncode([
    for (final row in rows)
      if (!_legacyExpressionColumns.contains(row['name']))
        {
          'name': row['name'],
          'type': row['type'],
          'notnull': row['notnull'],
          'dflt_value': row['dflt_value'],
          'pk': row['pk'],
        },
  ]);
}

Future<String> _ownedWordSchema(Database db) async {
  return jsonEncode(
    await db.rawQuery('''
      SELECT type, name, sql
      FROM sqlite_master
      WHERE tbl_name = 'WORD_TABLE'
        AND type IN ('index', 'trigger')
      ORDER BY type ASC, name ASC
    '''),
  );
}

Future<String> _databaseSchema(Database db) async {
  return jsonEncode(
    await db.rawQuery('''
      SELECT type, name, tbl_name, sql
      FROM sqlite_master
      WHERE name NOT LIKE 'sqlite_stat%'
      ORDER BY type ASC, name ASC
    '''),
  );
}

Future<bool> _tableExists(Database db, String tableName) async {
  final rows = await db.rawQuery(
    '''
    SELECT name
    FROM sqlite_master
    WHERE type = 'table'
      AND name = ?
    ''',
    [tableName],
  );
  return rows.isNotEmpty;
}

String _quoteIdentifier(String value) {
  return '"${value.replaceAll('"', '""')}"';
}

String _rmacTableDdl(String tableName) =>
    '''
  CREATE TABLE $tableName (
    RMAC TEXT PRIMARY KEY,
    Part_of_Speech TEXT,
    Tense TEXT,
    Voice TEXT,
    Mood TEXT,
    Person TEXT,
    "Case" TEXT,
    Number TEXT,
    Gender TEXT,
    Degree TEXT,
    Form TEXT
  )
''';

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
