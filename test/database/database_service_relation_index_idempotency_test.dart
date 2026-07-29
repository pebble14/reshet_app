import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/database_test_isolation_guard.dart';

const _expectedIndexSql = <String, String>{
  'idx_word_relation_signature_lookup': '''
    CREATE INDEX idx_word_relation_signature_lookup
    ON WORD_RELATION(
      word_id_1,
      word_id_2,
      COALESCE(relation_type, ''),
      COALESCE(direction_code, 'unknown')
    )
  ''',
  'idx_word_relation_pair_type_direction_unique': '''
    CREATE UNIQUE INDEX idx_word_relation_pair_type_direction_unique
    ON WORD_RELATION(
      word_id_1,
      word_id_2,
      COALESCE(relation_type, ''),
      COALESCE(direction_code, 'unknown')
    )
  ''',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late File sourceWorkDatabase;
  late List<int> sourceBytes;
  Directory? tempRoot;
  File? testDatabase;

  setUpAll(() async {
    sourceWorkDatabase = File(
      p.join(Directory.current.path, 'data', 'reshet_work.db'),
    );
    expect(sourceWorkDatabase.existsSync(), isTrue);
    sourceBytes = await sourceWorkDatabase.readAsBytes();
    await DatabaseService.initialize();
  });

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp(
      'reshet_relation_index_idempotency_',
    );
    ensureSystemTempDatabaseTargets(
      dataRootPath: tempRoot!.path,
      actualWorkDbPath: sourceWorkDatabase.path,
      actualSeedDbPath: p.join(
        Directory.current.path,
        'data',
        'reshet_seed.db',
      ),
    );
    testDatabase = await sourceWorkDatabase.copy(
      p.join(tempRoot!.path, 'reshet_work.db'),
    );
    final database = await _openTestDatabase(testDatabase!);
    await DatabaseService.ensureRuntimeSchema(database);
    await database.close();
  });

  tearDown(() async {
    final root = tempRoot;
    tempRoot = null;
    testDatabase = null;
    if (root != null && root.existsSync()) {
      await root.delete(recursive: true);
    }
  });

  tearDownAll(() async {
    expect(
      await sourceWorkDatabase.readAsBytes(),
      orderedEquals(sourceBytes),
      reason: 'repository work DB 원본은 테스트 전후 동일해야 한다.',
    );
  });

  test('A. 두 관계 인덱스가 없으면 기대 정의로 생성한다', () async {
    final db = await _openTestDatabase(testDatabase!);
    try {
      await _dropTargetIndexes(db);

      await DatabaseService.ensureRuntimeSchema(db);

      await _expectTargetIndexes(db);
    } finally {
      await db.close();
    }
  });

  test('B. 두 관계 인덱스 정의가 다르면 기대 정의로 교체한다', () async {
    final db = await _openTestDatabase(testDatabase!);
    try {
      await _dropTargetIndexes(db);
      await db.execute('''
        CREATE INDEX idx_word_relation_signature_lookup
        ON WORD_RELATION(word_id_1)
      ''');
      await db.execute('''
        CREATE UNIQUE INDEX idx_word_relation_pair_type_direction_unique
        ON WORD_RELATION(id)
      ''');

      await DatabaseService.ensureRuntimeSchema(db);

      await _expectTargetIndexes(db);
    } finally {
      await db.close();
    }
  });

  test('C. 의미가 같은 정의에는 인덱스 DDL과 물리 변경이 없다', () async {
    var db = await _openTestDatabase(testDatabase!);
    await _dropTargetIndexes(db);
    await db.execute('''
      create index idx_word_relation_signature_lookup on word_relation (
        WORD_ID_1, WORD_ID_2,
        coalesce(RELATION_TYPE, ''),
        coalesce(DIRECTION_CODE, 'unknown')
      )
    ''');
    await db.execute('''
      create unique index idx_word_relation_pair_type_direction_unique
      on word_relation (
        WORD_ID_1, WORD_ID_2,
        coalesce(RELATION_TYPE, ''),
        coalesce(DIRECTION_CODE, 'unknown')
      )
    ''');
    final sqlBefore = await _readTargetIndexSql(db);
    await db.close();
    final bytesBefore = await testDatabase!.readAsBytes();

    db = await _openTestDatabase(testDatabase!);
    final schemaVersionBefore = await _readSchemaVersion(db);
    await DatabaseService.ensureRuntimeSchema(db);
    final schemaVersionAfter = await _readSchemaVersion(db);
    final sqlAfter = await _readTargetIndexSql(db);
    await db.close();

    expect(schemaVersionAfter, schemaVersionBefore);
    expect(sqlAfter, sqlBefore);
    expect(await testDatabase!.readAsBytes(), orderedEquals(bytesBefore));
  });

  test('D. repository work DB 복사본의 runtime 보정은 물리적으로 멱등이다', () async {
    final bytesBefore = await testDatabase!.readAsBytes();

    final db = await _openTestDatabase(testDatabase!);
    await DatabaseService.ensureRuntimeSchema(db);
    await db.close();

    expect(await testDatabase!.readAsBytes(), orderedEquals(bytesBefore));
  });

  test('E. 충돌이 없을 때만 signature UNIQUE 인덱스를 보장한다', () async {
    final db = await _openTestDatabase(testDatabase!);
    try {
      await db.execute(
        'DROP INDEX idx_word_relation_pair_type_direction_unique',
      );
      await DatabaseService.ensureRuntimeSchema(db);
      expect(
        await _readIndexSql(db, 'idx_word_relation_pair_type_direction_unique'),
        isNotNull,
      );

      await db.execute(
        'DROP INDEX idx_word_relation_pair_type_direction_unique',
      );
      await db.insert('WORD_RELATION', {
        'word_id_1': '__index_collision_source__',
        'word_id_2': '__index_collision_target__',
        'relation_type': 'related',
        'direction_code': 'forward',
      });
      await db.insert('WORD_RELATION', {
        'word_id_1': '__index_collision_source__',
        'word_id_2': '__index_collision_target__',
        'relation_type': 'related',
        'direction_code': 'forward',
      });

      await DatabaseService.ensureRuntimeSchema(db);

      expect(
        await _readIndexSql(db, 'idx_word_relation_pair_type_direction_unique'),
        isNull,
      );
    } finally {
      await db.close();
    }
  });
}

Future<Database> _openTestDatabase(File databaseFile) {
  return databaseFactory.openDatabase(
    databaseFile.path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
}

Future<void> _dropTargetIndexes(DatabaseExecutor db) async {
  for (final indexName in _expectedIndexSql.keys) {
    await db.execute('DROP INDEX IF EXISTS $indexName');
  }
}

Future<void> _expectTargetIndexes(DatabaseExecutor db) async {
  for (final entry in _expectedIndexSql.entries) {
    expect(
      _normalizeSql(await _readIndexSql(db, entry.key)),
      _normalizeSql(entry.value),
      reason: '${entry.key} 정의가 기대값과 일치해야 한다.',
    );
  }
}

Future<Map<String, String?>> _readTargetIndexSql(DatabaseExecutor db) async {
  return {
    for (final indexName in _expectedIndexSql.keys)
      indexName: await _readIndexSql(db, indexName),
  };
}

Future<String?> _readIndexSql(DatabaseExecutor db, String indexName) async {
  final rows = await db.rawQuery(
    '''
    SELECT sql
    FROM sqlite_master
    WHERE type = 'index'
      AND name = ?
    ''',
    [indexName],
  );
  return rows.isEmpty ? null : rows.single['sql'] as String?;
}

Future<int> _readSchemaVersion(DatabaseExecutor db) async {
  final rows = await db.rawQuery('PRAGMA schema_version');
  return rows.single['schema_version'] as int;
}

String? _normalizeSql(String? sql) {
  return sql?.replaceAll(RegExp(r'\s+'), '').toLowerCase();
}
