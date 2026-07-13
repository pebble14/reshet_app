import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_backup_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testRoot;
  late Database sourceDatabase;
  late _FakeDestinationWriter writer;
  Directory? createdSnapshotDirectory;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    testRoot = await Directory.systemTemp.createTemp('reshet_backup_test_');
    sourceDatabase = await databaseFactory.openDatabase(
      p.join(testRoot.path, 'source.db'),
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await _createRuntimeFixture(sourceDatabase);
    writer = _FakeDestinationWriter(result: 'content://backup/result.db');
  });

  tearDown(() async {
    if (sourceDatabase.isOpen) {
      await sourceDatabase.close();
    }
    if (testRoot.existsSync()) {
      await testRoot.delete(recursive: true);
    }
  });

  DatabaseBackupService createService({
    BackupDestinationWriter? destinationWriter,
    BackupSnapshotDatabaseOpener? snapshotDatabaseOpener,
    BackupTempDirectoryCreator? tempDirectoryCreator,
  }) {
    return DatabaseBackupService(
      destinationWriter: destinationWriter ?? writer,
      sourceDatabaseOpener: () async => sourceDatabase,
      snapshotDatabaseOpener: snapshotDatabaseOpener,
      tempDirectoryCreator:
          tempDirectoryCreator ??
          (prefix) async {
            createdSnapshotDirectory = await testRoot.createTemp(prefix);
            return createdSnapshotDirectory!;
          },
      clock: () => DateTime(2026, 7, 13, 9, 8, 7),
    );
  }

  test('열린 SQLite connection에서 snapshot을 검증하고 저장한 뒤 임시 파일을 정리한다', () async {
    final result = await createService().createBackup();

    expect(result, isA<BackupSucceeded>());
    expect(writer.receivedBytes, isNotNull);
    expect(writer.receivedBytes, isNotEmpty);
    expect(writer.receivedFileName, 'reshet_backup_20260713_090807.db');
    expect(writer.sourceFileExistedDuringSave, isTrue);
    expect(createdSnapshotDirectory!.existsSync(), isFalse);

    final capturedSnapshot = File(
      p.join(testRoot.path, 'captured_snapshot.db'),
    );
    await capturedSnapshot.writeAsBytes(writer.receivedBytes!, flush: true);
    final snapshotDatabase = await databaseFactory.openDatabase(
      capturedSnapshot.path,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
    addTearDown(() async {
      if (snapshotDatabase.isOpen) {
        await snapshotDatabase.close();
      }
    });

    final integrityRows = await snapshotDatabase.rawQuery(
      'PRAGMA integrity_check',
    );
    expect(integrityRows, [
      const {'integrity_check': 'ok'},
    ]);

    final schemaRows = await snapshotDatabase.rawQuery('''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
        ''');
    final tableNames = schemaRows
        .map((row) => row['name'])
        .whereType<String>()
        .toSet();
    expect(
      tableNames,
      containsAll(DatabaseBackupService.requiredRuntimeTables),
    );

    final sourceCount = await sourceDatabase.rawQuery(
      'SELECT COUNT(*) AS row_count FROM WORD_TABLE',
    );
    final snapshotCount = await snapshotDatabase.rawQuery(
      'SELECT COUNT(*) AS row_count FROM WORD_TABLE',
    );
    expect(snapshotCount, sourceCount);
    expect(await sourceDatabase.rawQuery('SELECT 1 AS value'), [
      const {'value': 1},
    ]);
  });

  test('Android형 반환 문자열을 File로 재접근하지 않고 성공으로 처리한다', () async {
    writer.result = 'content://documents/tree/reshet_backup.db';

    final result = await createService().createBackup();

    expect(result, isA<BackupSucceeded>());
    expect(createdSnapshotDirectory!.existsSync(), isFalse);
  });

  test('file_selector writer는 기본 이름과 db filter를 전달하고 선택 path에 저장한다', () async {
    final destinationFile = File(p.join(testRoot.path, 'selected_backup.db'));
    String? capturedSuggestedName;
    List<XTypeGroup>? capturedTypeGroups;
    final destinationWriter = FileSelectorBackupDestinationWriter(
      saveLocationGetter:
          ({required acceptedTypeGroups, required suggestedName}) async {
            capturedSuggestedName = suggestedName;
            capturedTypeGroups = acceptedTypeGroups;
            return FileSaveLocation(destinationFile.path);
          },
    );
    final result = await destinationWriter.save(
      fileName: 'reshet_backup_20260713_090807.db',
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      sourceFilePath: p.join(testRoot.path, 'unused_snapshot.db'),
    );

    expect(result, destinationFile.path);
    expect(capturedSuggestedName, 'reshet_backup_20260713_090807.db');
    expect(capturedTypeGroups, hasLength(1));
    expect(capturedTypeGroups!.single.extensions, ['db']);
    expect(await destinationFile.readAsBytes(), [1, 2, 3, 4]);
  });

  test('file_selector writer는 위치 선택 취소 시 null을 반환한다', () async {
    final destinationWriter = FileSelectorBackupDestinationWriter(
      saveLocationGetter:
          ({required acceptedTypeGroups, required suggestedName}) async => null,
    );

    final result = await destinationWriter.save(
      fileName: 'reshet_backup_20260713_090807.db',
      bytes: Uint8List.fromList([1]),
      sourceFilePath: p.join(testRoot.path, 'unused_snapshot.db'),
    );

    expect(result, isNull);
  });

  test('Android writer는 snapshot path와 기본 파일명을 SAF adapter에 전달한다', () async {
    String? receivedSourcePath;
    String? receivedFileName;
    final destinationWriter = AndroidBackupDestinationWriter(
      saveFile: ({required sourceFilePath, required fileName}) async {
        receivedSourcePath = sourceFilePath;
        receivedFileName = fileName;
        return 'content://documents/reshet_backup.db';
      },
    );
    final sourcePath = p.join(testRoot.path, 'snapshot.db');

    final result = await destinationWriter.save(
      fileName: 'reshet_backup_20260713_090807.db',
      bytes: Uint8List.fromList([1]),
      sourceFilePath: sourcePath,
    );

    expect(result, 'content://documents/reshet_backup.db');
    expect(receivedSourcePath, sourcePath);
    expect(receivedFileName, 'reshet_backup_20260713_090807.db');
  });

  test('Android writer는 SAF 취소 null을 그대로 반환한다', () async {
    final destinationWriter = AndroidBackupDestinationWriter(
      saveFile: ({required sourceFilePath, required fileName}) async => null,
    );

    final result = await destinationWriter.save(
      fileName: 'reshet_backup_20260713_090807.db',
      bytes: Uint8List.fromList([1]),
      sourceFilePath: p.join(testRoot.path, 'snapshot.db'),
    );

    expect(result, isNull);
  });

  test('저장 dialog 취소를 실패로 바꾸지 않고 임시 파일을 정리한다', () async {
    writer.result = null;

    final result = await createService().createBackup();

    expect(result, isA<BackupCancelled>());
    expect(createdSnapshotDirectory!.existsSync(), isFalse);
    expect(await sourceDatabase.rawQuery('SELECT 1 AS value'), [
      const {'value': 1},
    ]);
  });

  test('destination 예외를 구분하고 임시 파일을 정리하며 원본 연결을 유지한다', () async {
    writer.error = StateError('destination write failed');

    final result = await createService().createBackup();

    expect(result, isA<BackupFailed>());
    expect((result as BackupFailed).stage, BackupFailureStage.destinationWrite);
    expect(createdSnapshotDirectory!.existsSync(), isFalse);
    expect(await sourceDatabase.rawQuery('SELECT 1 AS value'), [
      const {'value': 1},
    ]);
  });

  test('기존 snapshot output path를 덮어쓰지 않고 안전하게 실패한다', () async {
    final result = await createService(
      tempDirectoryCreator: (prefix) async {
        createdSnapshotDirectory = await testRoot.createTemp(prefix);
        await File(
          p.join(
            createdSnapshotDirectory!.path,
            DatabaseBackupService.snapshotFileName,
          ),
        ).writeAsString('existing');
        return createdSnapshotDirectory!;
      },
    ).createBackup();

    expect(result, isA<BackupFailed>());
    expect((result as BackupFailed).stage, BackupFailureStage.snapshotCreation);
    expect(writer.saveCallCount, 0);
    expect(createdSnapshotDirectory!.existsSync(), isFalse);
    expect(await sourceDatabase.rawQuery('SELECT 1 AS value'), [
      const {'value': 1},
    ]);
  });

  test('필수 runtime schema가 빠진 snapshot은 저장하지 않고 정리한다', () async {
    await sourceDatabase.execute('DROP TABLE RELATION_STATUS');

    final result = await createService().createBackup();

    expect(result, isA<BackupFailed>());
    expect(
      (result as BackupFailed).stage,
      BackupFailureStage.snapshotValidation,
    );
    expect(writer.saveCallCount, 0);
    expect(createdSnapshotDirectory!.existsSync(), isFalse);
    expect(await sourceDatabase.rawQuery('SELECT 1 AS value'), [
      const {'value': 1},
    ]);
  });
}

Future<void> _createRuntimeFixture(Database database) async {
  for (final statement in const [
    'CREATE TABLE WORD_TABLE (id TEXT PRIMARY KEY, memo TEXT)',
    'CREATE TABLE WORD_RELATION (id INTEGER PRIMARY KEY)',
    'CREATE TABLE word_expression_set (word_id TEXT, seq INTEGER)',
    'CREATE TABLE word_meaning_set (word_id TEXT, seq INTEGER)',
    'CREATE TABLE CHANGE_HISTORY (id INTEGER PRIMARY KEY)',
    'CREATE TABLE RELATION_CATEGORY (code TEXT PRIMARY KEY)',
    'CREATE TABLE RELATION_TYPE (code TEXT PRIMARY KEY)',
    'CREATE TABLE RELATION_STATUS (code TEXT PRIMARY KEY)',
    'CREATE TABLE RMAC_TABLE (RMAC TEXT PRIMARY KEY)',
    'CREATE TABLE RMAC_TABLE_KR (RMAC TEXT PRIMARY KEY)',
  ]) {
    await database.execute(statement);
  }
  await database.insert('WORD_TABLE', {
    'id': 'backup_fixture_word',
    'memo': 'Phase 48-B1 대표 행',
  });
}

class _FakeDestinationWriter implements BackupDestinationWriter {
  _FakeDestinationWriter({this.result});

  String? result;
  Object? error;
  int saveCallCount = 0;
  String? receivedFileName;
  Uint8List? receivedBytes;
  String? receivedSourceFilePath;
  bool? sourceFileExistedDuringSave;

  @override
  Future<String?> save({
    required String fileName,
    required Uint8List bytes,
    required String sourceFilePath,
  }) async {
    saveCallCount += 1;
    receivedFileName = fileName;
    receivedBytes = bytes;
    receivedSourceFilePath = sourceFilePath;
    sourceFileExistedDuringSave = File(sourceFilePath).existsSync();
    if (error case final error?) {
      throw error;
    }
    return result;
  }
}
