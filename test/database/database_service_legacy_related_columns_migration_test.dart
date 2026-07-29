import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

typedef _LegacyCell = ({
  String sourceWordId,
  String sourceColumn,
  String targetRawValue,
});

const _legacyColumns = ['관련1', '관련2', '관련3', '관련4', '관련5', '관련6', '관련7'];

const _archiveTableDdl = '''
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
    source_table TEXT NOT NULL CHECK (
      source_table = 'WORD_TABLE'
    ),
    PRIMARY KEY (source_word_id, source_column)
  )
''';

const _approvedDiscards = <_LegacyCell>[
  (
    sourceWordId: 'G1589_0000',
    sourceColumn: '관련1',
    targetRawValue: 'G1589_0000',
  ),
  (
    sourceWordId: 'G1696_0000',
    sourceColumn: '관련1',
    targetRawValue: 'G1696_0000',
  ),
  (
    sourceWordId: 'G2538_0000',
    sourceColumn: '관련1',
    targetRawValue: 'G2538_0000',
  ),
  (
    sourceWordId: 'G4173_0000',
    sourceColumn: '관련2',
    targetRawValue: 'G4173_0000',
  ),
  (
    sourceWordId: 'G4449_0000',
    sourceColumn: '관련1',
    targetRawValue: 'G4449_0000',
  ),
];

const _knownUnresolved = <_LegacyCell>[
  (
    sourceWordId: 'G1606_0000',
    sourceColumn: '관련3',
    targetRawValue: 'H5301_0000',
  ),
  (
    sourceWordId: 'H5397_0000',
    sourceColumn: '관련1',
    targetRawValue: 'H5315_0000',
  ),
  (
    sourceWordId: 'H4320_0000',
    sourceColumn: '관련1',
    targetRawValue: 'H0410_0000',
  ),
  (
    sourceWordId: 'H4976_0000',
    sourceColumn: '관련1',
    targetRawValue: 'H5414_0000',
  ),
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
      'reshet_legacy_related_migration_',
    );
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('알려진 9셀에서 폐기 5건을 제외하고 미대응 4건만 원문 보존한다', () async {
    final db = await _createFixtureDatabase(
      p.join(root.path, 'known_nine.db'),
      legacyColumns: _legacyColumns,
    );
    try {
      for (final cell in [..._approvedDiscards, ..._knownUnresolved]) {
        await _insertWord(
          db,
          cell.sourceWordId,
          relatedValues: {cell.sourceColumn: cell.targetRawValue},
        );
      }

      final remainingColumnContractBefore = await _wordTableColumnContract(
        db,
        excludeLegacyColumns: true,
      );
      final remainingRowsBefore = await _wordTableRemainingRows(db);
      final incomingForeignKeysBefore = await _incomingForeignKeys(db);
      final relationRowsBefore = await _relationRows(db);

      await DatabaseService.ensureRuntimeSchema(db);

      expect(await _presentLegacyColumns(db), isEmpty);
      expect(await _archiveRows(db), _expectedArchiveRows(_knownUnresolved));
      expect(await _relationRows(db), relationRowsBefore);
      expect(
        await _wordTableColumnContract(db, excludeLegacyColumns: false),
        remainingColumnContractBefore,
      );
      expect(await _wordTableRemainingRows(db), remainingRowsBefore);
      expect(await _incomingForeignKeys(db), incomingForeignKeysBefore);

      final archiveColumns = await db.rawQuery(
        "PRAGMA table_info('WORD_LEGACY_RELATED_VALUE')",
      );
      expect(archiveColumns.map((row) => row['name']).toList(growable: false), [
        'source_word_id',
        'source_column',
        'target_raw_value',
        'preservation_state',
        'source_table',
      ]);
      expect(
        archiveColumns.map((row) => row['name']),
        isNot(
          contains(
            anyOf(
              'category_code',
              'relation_type',
              'status_code',
              'direction_code',
            ),
          ),
        ),
      );
      expect(await db.rawQuery('PRAGMA integrity_check'), [
        {'integrity_check': 'ok'},
      ]);
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);

      final schemaVersionBeforeSecondEnsure = (await db.rawQuery(
        'PRAGMA schema_version',
      )).single['schema_version'];
      final archiveBeforeSecondEnsure = await _archiveRows(db);
      await DatabaseService.ensureRuntimeSchema(db);
      expect(
        (await db.rawQuery('PRAGMA schema_version')).single['schema_version'],
        schemaVersionBeforeSecondEnsure,
      );
      expect(await _archiveRows(db), archiveBeforeSecondEnsure);
      expect(await _relationRows(db), relationRowsBefore);
    } finally {
      await db.close();
    }
  });

  test('양방향 pair 대응값은 제외하고 예상 밖 값·빈 문자열·exact value 변형은 보존한다', () async {
    final db = await _createFixtureDatabase(
      p.join(root.path, 'classification.db'),
      legacyColumns: _legacyColumns,
    );
    try {
      await _insertWord(
        db,
        'A_SOURCE',
        relatedValues: const {'관련1': 'B_TARGET'},
      );
      await _insertWord(db, 'B_TARGET');
      await _insertWord(db, 'C_TARGET');
      await _insertWord(
        db,
        'D_SOURCE',
        relatedValues: const {'관련2': 'C_TARGET'},
      );
      await _insertWord(
        db,
        'G1589_0000',
        relatedValues: const {'관련1': 'G1589_DIFFERENT'},
      );
      await _insertWord(
        db,
        'G1696_0000',
        relatedValues: const {'관련1': 'G1696_0000'},
      );
      await _insertWord(db, 'T_BLANK', relatedValues: const {'관련4': ''});
      await _insertWord(
        db,
        'T_UNRESOLVED',
        relatedValues: const {'관련7': 'RAW_TARGET'},
      );
      await db.insert('WORD_RELATION', {
        'word_id_1': 'A_SOURCE',
        'word_id_2': 'B_TARGET',
        'relation_type': 'related',
        'direction_code': 'unknown',
      });
      await db.insert('WORD_RELATION', {
        'word_id_1': 'C_TARGET',
        'word_id_2': 'D_SOURCE',
        'relation_type': 'related',
        'direction_code': 'unknown',
      });
      final relationRowsBefore = await _relationRows(db);

      await DatabaseService.ensureRuntimeSchema(db);

      expect(await _relationRows(db), relationRowsBefore);
      expect(
        await _archiveRows(db),
        _expectedArchiveRows(const [
          (
            sourceWordId: 'G1589_0000',
            sourceColumn: '관련1',
            targetRawValue: 'G1589_DIFFERENT',
          ),
          (sourceWordId: 'T_BLANK', sourceColumn: '관련4', targetRawValue: ''),
          (
            sourceWordId: 'T_UNRESOLVED',
            sourceColumn: '관련7',
            targetRawValue: 'RAW_TARGET',
          ),
        ]),
      );
    } finally {
      await db.close();
    }
  });

  test('이미 migration된 유효 DB는 archive를 유지하며 no-op 처리한다', () async {
    final db = await _createFixtureDatabase(
      p.join(root.path, 'current.db'),
      legacyColumns: const [],
      createArchive: true,
    );
    try {
      await _insertWord(db, 'CURRENT_SOURCE');
      await _insertArchiveRow(db, const (
        sourceWordId: 'CURRENT_SOURCE',
        sourceColumn: '관련6',
        targetRawValue: 'CURRENT_RAW',
      ));

      await DatabaseService.ensureRuntimeSchema(db);
      final archiveAfterFirstEnsure = await _archiveRows(db);
      final schemaVersionAfterFirstEnsure = (await db.rawQuery(
        'PRAGMA schema_version',
      )).single['schema_version'];

      await DatabaseService.ensureRuntimeSchema(db);

      expect(await _presentLegacyColumns(db), isEmpty);
      expect(await _archiveRows(db), archiveAfterFirstEnsure);
      expect(
        (await db.rawQuery('PRAGMA schema_version')).single['schema_version'],
        schemaVersionAfterFirstEnsure,
      );
    } finally {
      await db.close();
    }
  });

  test('legacy 컬럼이 일부만 존재하면 변경 없이 fail-closed한다', () async {
    final db = await _createFixtureDatabase(
      p.join(root.path, 'partial.db'),
      legacyColumns: _legacyColumns.take(3).toList(growable: false),
    );
    try {
      await expectLater(
        DatabaseService.ensureRuntimeSchema(db),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('일부만 존재'),
          ),
        ),
      );
      expect(await _presentLegacyColumns(db), _legacyColumns.take(3).toSet());
      expect(await _tableExists(db, 'WORD_LEGACY_RELATED_VALUE'), isFalse);
    } finally {
      await db.close();
    }
  });

  test('legacy 컬럼과 archive가 모두 없으면 fail-closed한다', () async {
    final db = await _createFixtureDatabase(
      p.join(root.path, 'missing_both.db'),
      legacyColumns: const [],
    );
    try {
      await expectLater(
        DatabaseService.ensureRuntimeSchema(db),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('모두 없습니다'),
          ),
        ),
      );
    } finally {
      await db.close();
    }
  });

  test('잘못된 archive DDL 또는 저장 상태는 fail-closed한다', () async {
    final invalidSchemaDb = await _createFixtureDatabase(
      p.join(root.path, 'invalid_schema.db'),
      legacyColumns: const [],
    );
    try {
      await invalidSchemaDb.execute('''
        CREATE TABLE WORD_LEGACY_RELATED_VALUE (
          source_word_id TEXT NOT NULL,
          source_column TEXT NOT NULL,
          target_raw_value TEXT NOT NULL,
          preservation_state TEXT NOT NULL,
          source_table TEXT NOT NULL,
          PRIMARY KEY (source_word_id, source_column)
        )
      ''');
      await expectLater(
        DatabaseService.ensureRuntimeSchema(invalidSchemaDb),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('DDL 계약'),
          ),
        ),
      );
    } finally {
      await invalidSchemaDb.close();
    }

    final invalidStateDb = await _createFixtureDatabase(
      p.join(root.path, 'invalid_state.db'),
      legacyColumns: const [],
      createArchive: true,
    );
    try {
      await invalidStateDb.execute('PRAGMA ignore_check_constraints = ON');
      await invalidStateDb.insert('WORD_LEGACY_RELATED_VALUE', {
        'source_word_id': 'INVALID_STATE_SOURCE',
        'source_column': '관련1',
        'target_raw_value': 'RAW',
        'preservation_state': 'invalid_state',
        'source_table': 'WORD_TABLE',
      });
      await invalidStateDb.execute('PRAGMA ignore_check_constraints = OFF');

      await expectLater(
        DatabaseService.ensureRuntimeSchema(invalidStateDb),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('preservation state'),
          ),
        ),
      );
    } finally {
      await invalidStateDb.close();
    }
  });

  test('동일 source·slot의 archive 값이 원본과 다르면 전체 rollback한다', () async {
    final db = await _createFixtureDatabase(
      p.join(root.path, 'archive_conflict.db'),
      legacyColumns: _legacyColumns,
      createArchive: true,
    );
    try {
      await _insertWord(
        db,
        'CONFLICT_SOURCE',
        relatedValues: const {'관련1': 'ORIGINAL_RAW'},
      );
      await _insertArchiveRow(db, const (
        sourceWordId: 'CONFLICT_SOURCE',
        sourceColumn: '관련1',
        targetRawValue: 'CONFLICTING_RAW',
      ));

      await expectLater(
        DatabaseService.ensureRuntimeSchema(db),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('원본과 충돌'),
          ),
        ),
      );

      expect(await _presentLegacyColumns(db), _legacyColumns.toSet());
      expect(
        await _archiveRows(db),
        _expectedArchiveRows(const [
          (
            sourceWordId: 'CONFLICT_SOURCE',
            sourceColumn: '관련1',
            targetRawValue: 'CONFLICTING_RAW',
          ),
        ]),
      );
      final sourceRows = await db.query(
        'WORD_TABLE',
        columns: const ['관련1'],
        where: 'id = ?',
        whereArgs: ['CONFLICT_SOURCE'],
      );
      expect(sourceRows.single['관련1'], 'ORIGINAL_RAW');
    } finally {
      await db.close();
    }
  });

  test('일부 DROP COLUMN 뒤 실패해도 archive와 schema를 전체 rollback한다', () async {
    final db = await _createFixtureDatabase(
      p.join(root.path, 'drop_column_rollback.db'),
      legacyColumns: _legacyColumns,
    );
    try {
      await _insertWord(
        db,
        'ROLLBACK_SOURCE',
        relatedValues: const {'관련1': 'UNRESOLVED_RAW'},
      );
      await db.execute(
        'CREATE INDEX legacy_related4_dependency ON WORD_TABLE("관련4")',
      );

      await expectLater(
        DatabaseService.ensureRuntimeSchema(db),
        throwsA(isA<StateError>()),
      );

      expect(await _presentLegacyColumns(db), _legacyColumns.toSet());
      expect(await _tableExists(db, 'WORD_LEGACY_RELATED_VALUE'), isFalse);
      expect(
        await db.query(
          'WORD_TABLE',
          columns: const ['관련1'],
          where: 'id = ?',
          whereArgs: ['ROLLBACK_SOURCE'],
        ),
        [
          {'관련1': 'UNRESOLVED_RAW'},
        ],
      );
      expect(
        await db.rawQuery(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'index' AND name = 'legacy_related4_dependency'",
        ),
        [
          {'name': 'legacy_related4_dependency'},
        ],
      );
    } finally {
      await db.close();
    }
  });

  test('현행 seed-copy 신규 runtime DB는 legacy 컬럼 없이 열린다', () async {
    final dataRoot = Directory(p.join(root.path, 'fresh_data'));
    await dataRoot.create(recursive: true);
    final seed = await _createFixtureDatabase(
      p.join(dataRoot.path, 'reshet_seed.db'),
      legacyColumns: const [],
      createArchive: true,
    );
    await seed.close();

    DatabaseService.setDataRootOverrideForTest(dataRoot.path);
    final opened = await DatabaseService.openDatabaseFile();

    expect(await _presentLegacyColumns(opened), isEmpty);
    expect(await _tableExists(opened, 'WORD_LEGACY_RELATED_VALUE'), isTrue);
    expect(await DatabaseService.openDatabaseFile(), same(opened));
    await DatabaseService.ensureRuntimeSchema(opened);
  });
}

Future<Database> _createFixtureDatabase(
  String path, {
  required List<String> legacyColumns,
  bool createArchive = false,
}) async {
  final db = await databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await db.execute('PRAGMA foreign_keys = ON');
  final legacyColumnSql = legacyColumns
      .map((column) => '"$column" TEXT')
      .join(',\n');
  final optionalLegacyColumns = legacyColumnSql.isEmpty
      ? ''
      : '$legacyColumnSql,';
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
      $optionalLegacyColumns
      의미1 TEXT,
      의미2 TEXT,
      의미3 TEXT,
      의미4 TEXT,
      의미5 TEXT,
      의미6 TEXT,
      의미7 TEXT,
      비고 TEXT,
      retained_value TEXT NOT NULL DEFAULT 'kept',
      graph_expand_mode TEXT NOT NULL DEFAULT 'default'
    )
  ''');
  await db.execute('''
    CREATE TABLE WORD_RELATION (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      word_id_1 TEXT NOT NULL,
      word_id_2 TEXT NOT NULL,
      category_code TEXT,
      relation_type TEXT,
      status_code TEXT DEFAULT 'asserted',
      note TEXT,
      source TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
      direction_code TEXT NOT NULL DEFAULT 'unknown',
      description TEXT,
      relation_group_id TEXT,
      FOREIGN KEY (word_id_1) REFERENCES WORD_TABLE(id),
      FOREIGN KEY (word_id_2) REFERENCES WORD_TABLE(id),
      CHECK (word_id_1 < word_id_2)
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
    CREATE TABLE word_meaning_set (
      id INTEGER PRIMARY KEY,
      word_id TEXT NOT NULL,
      seq INTEGER NOT NULL,
      meaning TEXT NOT NULL,
      FOREIGN KEY (word_id) REFERENCES WORD_TABLE(id) ON DELETE CASCADE
    )
  ''');
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
  if (createArchive) {
    await db.execute(_archiveTableDdl);
  }
  return db;
}

Future<void> _insertWord(
  Database db,
  String id, {
  Map<String, Object?> relatedValues = const {},
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '언어': '테스트언어',
    '표기1': 'spelling-$id',
    '의미1': 'meaning-$id',
    '비고': 'note-$id',
    ...relatedValues,
  });
}

Future<void> _insertArchiveRow(Database db, _LegacyCell cell) async {
  await db.insert('WORD_LEGACY_RELATED_VALUE', {
    'source_word_id': cell.sourceWordId,
    'source_column': cell.sourceColumn,
    'target_raw_value': cell.targetRawValue,
    'preservation_state': 'unresolved_legacy',
    'source_table': 'WORD_TABLE',
  });
}

Future<Set<String>> _presentLegacyColumns(DatabaseExecutor db) async {
  final columns = await db.rawQuery("PRAGMA table_info('WORD_TABLE')");
  final names = columns.map((row) => row['name']).whereType<String>().toSet();
  return _legacyColumns.where(names.contains).toSet();
}

Future<bool> _tableExists(DatabaseExecutor db, String tableName) async {
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

Future<List<Map<String, Object?>>> _archiveRows(DatabaseExecutor db) {
  return db.query(
    'WORD_LEGACY_RELATED_VALUE',
    columns: const [
      'source_word_id',
      'source_column',
      'target_raw_value',
      'preservation_state',
      'source_table',
    ],
    orderBy: 'source_word_id ASC, source_column ASC',
  );
}

List<Map<String, Object?>> _expectedArchiveRows(List<_LegacyCell> cells) {
  final sorted = [...cells]
    ..sort((left, right) {
      final sourceCompare = left.sourceWordId.compareTo(right.sourceWordId);
      return sourceCompare != 0
          ? sourceCompare
          : left.sourceColumn.compareTo(right.sourceColumn);
    });
  return [
    for (final cell in sorted)
      {
        'source_word_id': cell.sourceWordId,
        'source_column': cell.sourceColumn,
        'target_raw_value': cell.targetRawValue,
        'preservation_state': 'unresolved_legacy',
        'source_table': 'WORD_TABLE',
      },
  ];
}

Future<List<Map<String, Object?>>> _wordTableColumnContract(
  DatabaseExecutor db, {
  required bool excludeLegacyColumns,
}) async {
  final rows = await db.rawQuery("PRAGMA table_info('WORD_TABLE')");
  return [
    for (final row in rows)
      if (!excludeLegacyColumns ||
          !_legacyColumns.contains((row['name'] ?? '').toString()))
        {
          'name': row['name'],
          'type': row['type'],
          'notnull': row['notnull'],
          'dflt_value': row['dflt_value'],
          'pk': row['pk'],
        },
  ];
}

Future<List<Map<String, Object?>>> _wordTableRemainingRows(
  DatabaseExecutor db,
) async {
  final columns = (await db.rawQuery("PRAGMA table_info('WORD_TABLE')"))
      .map((row) => row['name'])
      .whereType<String>()
      .where((name) => !_legacyColumns.contains(name))
      .toList(growable: false);
  return db.query('WORD_TABLE', columns: columns, orderBy: 'id ASC');
}

Future<String> _incomingForeignKeys(DatabaseExecutor db) async {
  final result = <String, Object?>{};
  for (final table in const [
    'WORD_RELATION',
    'word_expression_set',
    'word_meaning_set',
  ]) {
    result[table] = await db.rawQuery("PRAGMA foreign_key_list('$table')");
  }
  return jsonEncode(result);
}

Future<List<Map<String, Object?>>> _relationRows(DatabaseExecutor db) {
  return db.query('WORD_RELATION', orderBy: 'id ASC');
}
