import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/database_test_isolation_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String repoRootPath;
  late File sourceSeedFile;
  late List<Map<String, Object?>> expectedMeaningRows;
  Directory? tempRoot;

  setUpAll(() async {
    repoRootPath = Directory.current.path;
    sourceSeedFile = File(p.join(repoRootPath, 'data', 'reshet_seed.db'));

    expect(sourceSeedFile.existsSync(), isTrue);
    await DatabaseService.initialize();
    expectedMeaningRows = await _readMeaningRowsFromPath(sourceSeedFile.path);
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    tempRoot = await Directory.systemTemp.createTemp(
      'reshet_phase43a_meaning_seed_',
    );
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    Directory.current = repoRootPath;

    final root = tempRoot;
    tempRoot = null;
    if (root != null && root.existsSync()) {
      await root.delete(recursive: true);
    }
  });

  test(
    'source seed contains canonical meanings without physical meaning columns',
    () async {
      await _withReadOnlyDb(sourceSeedFile.path, (db) async {
        await _expectMeaningCanonicalState(
          db,
          expectedRows: expectedMeaningRows,
        );
        await _expectInferredRelationStatus(db);
      });
    },
  );

  test(
    'seed-only startup and reset preserve meaning baseline and status data',
    () async {
      final dataDir = Directory(p.join(tempRoot!.path, 'data'));
      await dataDir.create(recursive: true);
      final seedPath = p.join(dataDir.path, 'reshet_seed.db');
      final workPath = p.join(dataDir.path, 'reshet_work.db');
      ensureSystemTempDatabaseTargets(
        dataRootPath: dataDir.path,
        actualWorkDbPath: p.join(repoRootPath, 'data', 'reshet_work.db'),
        actualSeedDbPath: sourceSeedFile.path,
      );
      await sourceSeedFile.copy(seedPath);

      final expectedDistribution =
          await _readRelationStatusDistributionFromPath(sourceSeedFile.path);
      DatabaseService.setDataRootOverrideForTest(dataDir.path);

      final startupDb = await DatabaseService.openDatabaseFile();
      await _expectMeaningCanonicalState(
        startupDb,
        expectedRows: expectedMeaningRows,
      );
      await _expectInferredRelationStatus(startupDb);
      await _expectRelationStatusDistribution(startupDb, expectedDistribution);
      expect(File(workPath).existsSync(), isTrue);

      await startupDb.execute(
        'CREATE TABLE __phase43a_reset_marker(value TEXT)',
      );
      await DatabaseService.closeDatabase();

      await DatabaseService.resetToSeed(backup: false);

      final resetDb = await DatabaseService.openDatabaseFile();
      final markerRows = await resetDb.rawQuery('''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
          AND name = '__phase43a_reset_marker'
      ''');
      expect(markerRows, isEmpty);
      await _expectMeaningCanonicalState(
        resetDb,
        expectedRows: expectedMeaningRows,
      );
      await _expectInferredRelationStatus(resetDb);
      await _expectRelationStatusDistribution(resetDb, expectedDistribution);
      expect(File(p.join(dataDir.path, 'backups')).existsSync(), isFalse);
    },
  );
}

Future<T> _withReadOnlyDb<T>(
  String dbPath,
  Future<T> Function(Database db) read,
) async {
  final db = await databaseFactoryFfi.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(readOnly: true),
  );
  try {
    return await read(db);
  } finally {
    await db.close();
  }
}

Future<Map<String, int>> _readRelationStatusDistributionFromPath(
  String dbPath,
) async {
  return _withReadOnlyDb(dbPath, _readRelationStatusDistribution);
}

Future<List<Map<String, Object?>>> _readMeaningRowsFromPath(
  String dbPath,
) async {
  return _withReadOnlyDb(dbPath, _readMeaningRows);
}

Future<List<Map<String, Object?>>> _readMeaningRows(DatabaseExecutor db) async {
  return db.query(
    'word_meaning_set',
    columns: const ['id', 'word_id', 'seq', 'meaning'],
    orderBy: 'word_id ASC, seq ASC, id ASC',
  );
}

Future<Map<String, Object?>> _readRelationStatusRow(
  DatabaseExecutor db,
  String code,
) async {
  final rows = await db.rawQuery(
    '''
    SELECT code, label, description, sort_order
    FROM RELATION_STATUS
    WHERE code = ?
    ''',
    [code],
  );
  expect(rows, hasLength(1));
  return rows.single;
}

Future<Map<String, int>> _readRelationStatusDistribution(
  DatabaseExecutor db,
) async {
  final rows = await db.rawQuery('''
    SELECT status_code, COUNT(*) AS status_count
    FROM WORD_RELATION
    GROUP BY status_code
    ORDER BY status_code
  ''');

  return {
    for (final row in rows)
      (row['status_code'] ?? '').toString(): row['status_count'] as int,
  };
}

Future<void> _expectInferredRelationStatus(DatabaseExecutor db) async {
  final row = await _readRelationStatusRow(db, 'inferred');

  expect(row['code'], 'inferred');
  expect(row['label'], '기존 데이터 기반');
  expect(
    row['description'],
    '기존 데이터와 기존 처리 경로에서 보존된 관계 상태다. 이 값은 관계 유형·방향·근거가 현재 기준에서 독립적으로 확정·검증되었음을 뜻하지 않는다.',
  );
  expect(row['sort_order'], 7);
}

Future<void> _expectRelationStatusDistribution(
  DatabaseExecutor db,
  Map<String, int> expected,
) async {
  final actual = await _readRelationStatusDistribution(db);

  expect(actual, expected);
}

Future<void> _expectMeaningCanonicalState(
  DatabaseExecutor db, {
  required List<Map<String, Object?>> expectedRows,
}) async {
  final wordColumns = await db.rawQuery("PRAGMA table_info('WORD_TABLE')");
  final legacyMeaningColumns = wordColumns
      .map((row) => row['name'])
      .whereType<String>()
      .where(const {'의미1', '의미2', '의미3', '의미4', '의미5', '의미6', '의미7'}.contains)
      .toList(growable: false);
  expect(legacyMeaningColumns, isEmpty);

  final tableRows = await db.rawQuery('''
    SELECT COUNT(*) AS table_count
    FROM sqlite_master
    WHERE type = 'table'
      AND name = 'word_meaning_set'
  ''');
  expect(tableRows.single['table_count'], 1);

  final indexRows = await db.rawQuery('''
    SELECT COUNT(*) AS index_count
    FROM sqlite_master
    WHERE type = 'index'
      AND tbl_name = 'word_meaning_set'
      AND name = 'ux_word_meaning_set_word_seq'
  ''');
  expect(indexRows.single['index_count'], 1);

  final schemaRows = await db.rawQuery('''
    SELECT sql
    FROM sqlite_master
    WHERE type = 'table'
      AND name = 'word_meaning_set'
  ''');
  final tableSql = (schemaRows.single['sql'] ?? '').toString();
  expect(tableSql, contains('CHECK (seq >= 1)'));
  expect(tableSql, contains("CHECK (meaning <> '')"));
  expect(tableSql, isNot(contains('seq <= 7')));

  final actualRows = await _readMeaningRows(db);
  expect(actualRows, expectedRows);
}
