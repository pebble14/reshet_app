import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String repoRootPath;
  late File sourceSeedFile;
  Directory? tempRoot;

  setUpAll(() async {
    repoRootPath = Directory.current.path;
    sourceSeedFile = File(p.join(repoRootPath, 'data', 'reshet_seed.db'));

    expect(sourceSeedFile.existsSync(), isTrue);
    await DatabaseService.initialize();
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
    'source seed contains the physical meaning canonical baseline',
    () async {
      await _withReadOnlyDb(sourceSeedFile.path, (db) async {
        await _expectMeaningCanonicalState(db);
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
      await sourceSeedFile.copy(seedPath);

      final expectedDistribution =
          await _readRelationStatusDistributionFromPath(sourceSeedFile.path);
      DatabaseService.setDataRootOverrideForTest(dataDir.path);

      final startupDb = await DatabaseService.openDatabaseFile();
      await _expectMeaningCanonicalState(startupDb);
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
      await _expectMeaningCanonicalState(resetDb);
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

Future<void> _expectMeaningCanonicalState(DatabaseExecutor db) async {
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

  final compareRows = await db.rawQuery('''
    WITH legacy_slots AS (
      SELECT id AS word_id, 1 AS seq, [의미1] AS meaning
      FROM WORD_TABLE
      UNION ALL
      SELECT id, 2, [의미2]
      FROM WORD_TABLE
      UNION ALL
      SELECT id, 3, [의미3]
      FROM WORD_TABLE
      UNION ALL
      SELECT id, 4, [의미4]
      FROM WORD_TABLE
      UNION ALL
      SELECT id, 5, [의미5]
      FROM WORD_TABLE
      UNION ALL
      SELECT id, 6, [의미6]
      FROM WORD_TABLE
      UNION ALL
      SELECT id, 7, [의미7]
      FROM WORD_TABLE
    ),
    expected_meaning_set AS (
      SELECT word_id, seq, meaning
      FROM legacy_slots
      WHERE meaning IS NOT NULL
        AND meaning <> ''
    ),
    expected_minus_actual AS (
      SELECT word_id, seq, meaning
      FROM expected_meaning_set
      EXCEPT
      SELECT word_id, seq, meaning
      FROM word_meaning_set
    ),
    actual_minus_expected AS (
      SELECT word_id, seq, meaning
      FROM word_meaning_set
      EXCEPT
      SELECT word_id, seq, meaning
      FROM expected_meaning_set
    )
    SELECT
      (SELECT COUNT(*) FROM expected_meaning_set) AS expected_row_count,
      (SELECT COUNT(*) FROM word_meaning_set) AS actual_row_count,
      (SELECT COUNT(*) FROM expected_minus_actual) AS missing_count,
      (SELECT COUNT(*) FROM actual_minus_expected) AS extra_count,
      (SELECT COUNT(*) FROM expected_meaning_set WHERE TRIM(meaning) = '')
        AS legacy_trim_empty_count,
      (SELECT COUNT(*) FROM word_meaning_set WHERE TRIM(meaning) = '')
        AS actual_trim_empty_count,
      (SELECT COUNT(*) FROM word_meaning_set WHERE seq > 7)
        AS actual_seq_gt_7_count
  ''');

  final row = compareRows.single;
  expect(row['actual_row_count'], row['expected_row_count']);
  expect(row['missing_count'], 0);
  expect(row['extra_count'], 0);
  expect(row['legacy_trim_empty_count'], 0);
  expect(row['actual_trim_empty_count'], 0);
  expect(row['actual_seq_gt_7_count'], 0);
}
