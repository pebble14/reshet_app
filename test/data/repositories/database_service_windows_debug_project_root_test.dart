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

  const assertedRelationStatusCode = 'asserted';

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
      'reshet_windows_debug_db_root_test_',
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
    'Windows Debug uses project data when current directory is project root',
    () async {
      final projectRoot = await _createProjectRoot(tempRoot!, withWork: true);

      final resolvedPath = DatabaseService.resolveDataDirPathForTest(
        isAndroid: false,
        isWindows: true,
        isDebug: true,
        currentDirectoryPath: projectRoot.path,
        resolvedExecutablePath: p.join(
          projectRoot.path,
          'build',
          'windows',
          'x64',
          'runner',
          'Debug',
          'study.exe',
        ),
        systemTempParentPath: p.join(tempRoot!.path, 'android_parent'),
      );

      _expectSamePath(resolvedPath, p.join(projectRoot.path, 'data'));
    },
  );

  test('Windows Debug direct exe path resolves project root data', () async {
    final projectRoot = await _createProjectRoot(tempRoot!, withWork: true);
    final debugDir = Directory(
      p.join(projectRoot.path, 'build', 'windows', 'x64', 'runner', 'Debug'),
    );
    await debugDir.create(recursive: true);

    final resolvedPath = DatabaseService.resolveDataDirPathForTest(
      isAndroid: false,
      isWindows: true,
      isDebug: true,
      currentDirectoryPath: debugDir.path,
      resolvedExecutablePath: p.join(debugDir.path, 'study.exe'),
      systemTempParentPath: p.join(tempRoot!.path, 'android_parent'),
    );

    _expectSamePath(resolvedPath, p.join(projectRoot.path, 'data'));
  });

  test(
    'Windows Debug fails without creating a Debug output DB when project root is missing',
    () async {
      final debugDir = Directory(
        p.join(
          tempRoot!.path,
          'orphan',
          'build',
          'windows',
          'x64',
          'runner',
          'Debug',
        ),
      );
      final debugDataDir = Directory(p.join(debugDir.path, 'data'));
      await debugDataDir.create(recursive: true);

      expect(
        () => DatabaseService.resolveDataDirPathForTest(
          isAndroid: false,
          isWindows: true,
          isDebug: true,
          currentDirectoryPath: debugDir.path,
          resolvedExecutablePath: p.join(debugDir.path, 'study.exe'),
          systemTempParentPath: p.join(tempRoot!.path, 'android_parent'),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Windows Debug project root data directory를 찾을 수 없습니다'),
          ),
        ),
      );
      expect(
        File(p.join(debugDataDir.path, 'reshet_work.db')).existsSync(),
        isFalse,
      );
    },
  );

  test(
    'existing work DB opens without seed and has canonical meanings',
    () async {
      final dataDir = await _createDataRoot(tempRoot!);
      final workPath = p.join(dataDir.path, 'reshet_work.db');
      await sourceSeedFile.copy(workPath);
      final expectedDistribution =
          await _readRelationStatusDistributionFromPath(workPath);
      final expectedAsserted = await _readRelationStatusRowFromPath(
        workPath,
        assertedRelationStatusCode,
      );
      DatabaseService.setDataRootOverrideForTest(dataDir.path);

      final db = await DatabaseService.openDatabaseFile();
      final tableRows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' LIMIT 1",
      );

      expect(tableRows, isNotEmpty);
      await _expectMeaningCanonicalState(db);
      await _expectInferredRelationStatus(db);
      await _expectRelationStatusRow(
        db,
        assertedRelationStatusCode,
        expectedAsserted,
      );
      await _expectRelationStatusDistribution(db, expectedDistribution);
      expect(File(workPath).existsSync(), isTrue);
      expect(
        File(p.join(dataDir.path, 'reshet_seed.db')).existsSync(),
        isFalse,
      );
      expect(_isInside(tempRoot!.path, dataDir.path), isTrue);
    },
  );

  test(
    'seed DB creates canonical work DB in the project data root only',
    () async {
      final dataDir = await _createDataRoot(tempRoot!);
      final seedPath = p.join(dataDir.path, 'reshet_seed.db');
      await sourceSeedFile.copy(seedPath);
      final expectedDistribution =
          await _readRelationStatusDistributionFromPath(seedPath);
      final expectedAsserted = await _readRelationStatusRowFromPath(
        seedPath,
        assertedRelationStatusCode,
      );
      DatabaseService.setDataRootOverrideForTest(dataDir.path);

      final workPath = p.join(dataDir.path, 'reshet_work.db');
      expect(File(workPath).existsSync(), isFalse);

      final db = await DatabaseService.openDatabaseFile();
      final tableRows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' LIMIT 1",
      );

      expect(tableRows, isNotEmpty);
      await _expectMeaningCanonicalState(db);
      await _expectInferredRelationStatus(db);
      await _expectRelationStatusRow(
        db,
        assertedRelationStatusCode,
        expectedAsserted,
      );
      await _expectRelationStatusDistribution(db, expectedDistribution);
      expect(File(workPath).existsSync(), isTrue);
      expect(_isInside(tempRoot!.path, workPath), isTrue);
    },
  );

  test('resetToSeed creates canonical work DB in the data root', () async {
    final dataDir = await _createDataRoot(tempRoot!);
    final seedPath = p.join(dataDir.path, 'reshet_seed.db');
    final workPath = p.join(dataDir.path, 'reshet_work.db');
    await sourceSeedFile.copy(seedPath);
    await sourceSeedFile.copy(workPath);
    final expectedDistribution = await _readRelationStatusDistributionFromPath(
      seedPath,
    );
    final expectedAsserted = await _readRelationStatusRowFromPath(
      seedPath,
      assertedRelationStatusCode,
    );

    DatabaseService.setDataRootOverrideForTest(dataDir.path);
    final beforeResetDb = await DatabaseService.openDatabaseFile();
    await beforeResetDb.execute('CREATE TABLE __reset_marker(value TEXT)');
    await DatabaseService.closeDatabase();

    await DatabaseService.resetToSeed(backup: false);

    final afterResetDb = await DatabaseService.openDatabaseFile();
    final markerRows = await afterResetDb.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name = '__reset_marker'
      ''');
    expect(markerRows, isEmpty);
    await _expectMeaningCanonicalState(afterResetDb);
    await _expectInferredRelationStatus(afterResetDb);
    await _expectRelationStatusRow(
      afterResetDb,
      assertedRelationStatusCode,
      expectedAsserted,
    );
    await _expectRelationStatusDistribution(afterResetDb, expectedDistribution);
    expect(File(p.join(dataDir.path, 'backups')).existsSync(), isFalse);
    expect(_isInside(tempRoot!.path, workPath), isTrue);
  });

  test(
    'Android data path remains app-private and ignores Windows Debug resolver',
    () {
      final systemTempParentPath = p.join(tempRoot!.path, 'android_parent');

      final resolvedPath = DatabaseService.resolveDataDirPathForTest(
        isAndroid: true,
        isWindows: true,
        isDebug: true,
        currentDirectoryPath: p.join(tempRoot!.path, 'debug'),
        resolvedExecutablePath: p.join(tempRoot!.path, 'debug', 'study.exe'),
        systemTempParentPath: systemTempParentPath,
      );

      _expectSamePath(
        resolvedPath,
        p.join(systemTempParentPath, 'files', 'data'),
      );
    },
  );
}

Future<Directory> _createProjectRoot(
  Directory parent, {
  required bool withWork,
}) async {
  final projectRoot = Directory(p.join(parent.path, 'reshet_project'));
  final dataDir = Directory(p.join(projectRoot.path, 'data'));

  await dataDir.create(recursive: true);
  await File(
    p.join(projectRoot.path, 'pubspec.yaml'),
  ).writeAsString('name: reshet_project_test\n');
  if (withWork) {
    await File(p.join(dataDir.path, 'reshet_work.db')).writeAsString('fixture');
  }

  return projectRoot;
}

Future<Directory> _createDataRoot(Directory parent) async {
  final dataDir = Directory(p.join(parent.path, 'project', 'data'));
  await dataDir.create(recursive: true);
  return dataDir;
}

void _expectSamePath(String actual, String expected) {
  expect(p.equals(p.normalize(actual), p.normalize(expected)), isTrue);
}

bool _isInside(String parent, String child) {
  return p.equals(parent, child) || p.isWithin(parent, child);
}

Future<Map<String, Object?>> _readRelationStatusRowFromPath(
  String dbPath,
  String code,
) async {
  return _withReadOnlyDb(dbPath, (db) => _readRelationStatusRow(db, code));
}

Future<Map<String, int>> _readRelationStatusDistributionFromPath(
  String dbPath,
) async {
  return _withReadOnlyDb(dbPath, _readRelationStatusDistribution);
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

Future<Map<String, Object?>> _readRelationStatusRow(
  Database db,
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

Future<Map<String, int>> _readRelationStatusDistribution(Database db) async {
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

Future<void> _expectInferredRelationStatus(Database db) async {
  final row = await _readRelationStatusRow(db, 'inferred');

  expect(row['code'], 'inferred');
  expect(row['label'], '기존 데이터 기반');
  expect(
    row['description'],
    '기존 데이터와 기존 처리 경로에서 보존된 관계 상태다. 이 값은 관계 유형·방향·근거가 현재 기준에서 독립적으로 확정·검증되었음을 뜻하지 않는다.',
  );
  expect(row['sort_order'], 7);
}

Future<void> _expectRelationStatusRow(
  Database db,
  String code,
  Map<String, Object?> expected,
) async {
  final row = await _readRelationStatusRow(db, code);

  expect(row['code'], expected['code']);
  expect(row['label'], expected['label']);
  expect(row['description'], expected['description']);
  expect(row['sort_order'], expected['sort_order']);
}

Future<void> _expectRelationStatusDistribution(
  Database db,
  Map<String, int> expected,
) async {
  final actual = await _readRelationStatusDistribution(db);

  expect(actual, expected);
}

Future<void> _expectMeaningCanonicalState(Database db) async {
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
      WHERE seq BETWEEN 1 AND 7
      EXCEPT
      SELECT word_id, seq, meaning
      FROM expected_meaning_set
    )
    SELECT
      (SELECT COUNT(*) FROM expected_meaning_set) AS expected_row_count,
      (SELECT COUNT(*) FROM word_meaning_set) AS actual_row_count,
      (SELECT COUNT(*) FROM expected_minus_actual)
        AS expected_minus_actual_count,
      (SELECT COUNT(*) FROM actual_minus_expected)
        AS actual_minus_expected_count
    ''');

  final row = compareRows.single;
  expect(row['actual_row_count'], row['expected_row_count']);
  expect(row['expected_minus_actual_count'], 0);
  expect(row['actual_minus_expected_count'], 0);
}
