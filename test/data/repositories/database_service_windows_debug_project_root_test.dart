import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';

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

  test('existing work DB opens without requiring a seed DB', () async {
    final dataDir = await _createDataRoot(tempRoot!);
    await sourceSeedFile.copy(p.join(dataDir.path, 'reshet_work.db'));
    DatabaseService.setDataRootOverrideForTest(dataDir.path);

    final db = await DatabaseService.openDatabaseFile();
    final tableRows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' LIMIT 1",
    );

    expect(tableRows, isNotEmpty);
    expect(File(p.join(dataDir.path, 'reshet_work.db')).existsSync(), isTrue);
    expect(File(p.join(dataDir.path, 'reshet_seed.db')).existsSync(), isFalse);
    expect(_isInside(tempRoot!.path, dataDir.path), isTrue);
  });

  test('seed DB creates work DB in the project data root only', () async {
    final dataDir = await _createDataRoot(tempRoot!);
    await sourceSeedFile.copy(p.join(dataDir.path, 'reshet_seed.db'));
    DatabaseService.setDataRootOverrideForTest(dataDir.path);

    final workPath = p.join(dataDir.path, 'reshet_work.db');
    expect(File(workPath).existsSync(), isFalse);

    final db = await DatabaseService.openDatabaseFile();
    final tableRows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' LIMIT 1",
    );

    expect(tableRows, isNotEmpty);
    expect(File(workPath).existsSync(), isTrue);
    expect(_isInside(tempRoot!.path, workPath), isTrue);
  });

  test('resetToSeed uses the resolved project data root', () async {
    final dataDir = await _createDataRoot(tempRoot!);
    final seedPath = p.join(dataDir.path, 'reshet_seed.db');
    final workPath = p.join(dataDir.path, 'reshet_work.db');
    await sourceSeedFile.copy(seedPath);
    await sourceSeedFile.copy(workPath);

    DatabaseService.setDataRootOverrideForTest(dataDir.path);
    final beforeResetDb = await DatabaseService.openDatabaseFile();
    await beforeResetDb.execute('CREATE TABLE __reset_marker(value TEXT)');
    await DatabaseService.closeDatabase();

    await DatabaseService.resetToSeed(backup: false);

    final afterResetDb = await DatabaseService.openDatabaseFile();
    final markerRows = await afterResetDb.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name = '__reset_marker'
      ''',
    );
    expect(markerRows, isEmpty);
    expect(File(p.join(dataDir.path, 'backups')).existsSync(), isFalse);
    expect(_isInside(tempRoot!.path, workPath), isTrue);
  });

  test('Android data path remains app-private and ignores Windows Debug resolver', () {
    final systemTempParentPath = p.join(tempRoot!.path, 'android_parent');

    final resolvedPath = DatabaseService.resolveDataDirPathForTest(
      isAndroid: true,
      isWindows: true,
      isDebug: true,
      currentDirectoryPath: p.join(tempRoot!.path, 'debug'),
      resolvedExecutablePath: p.join(tempRoot!.path, 'debug', 'study.exe'),
      systemTempParentPath: systemTempParentPath,
    );

    _expectSamePath(resolvedPath, p.join(systemTempParentPath, 'files', 'data'));
  });
}

Future<Directory> _createProjectRoot(
  Directory parent, {
  required bool withWork,
}) async {
  final projectRoot = Directory(p.join(parent.path, 'reshet_project'));
  final dataDir = Directory(p.join(projectRoot.path, 'data'));

  await dataDir.create(recursive: true);
  await File(p.join(projectRoot.path, 'pubspec.yaml')).writeAsString(
    'name: reshet_project_test\n',
  );
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
