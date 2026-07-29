import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_restore_service.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/database/database_snapshot_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late _DatabaseHarness harness;
  late File candidate;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    root = await Directory.systemTemp.createTemp('reshet_restore_test_');
    harness = _DatabaseHarness(root);
    await harness.createWork(marker: '복원 전 데이터');
    candidate = File(p.join(root.path, 'candidate.db'));
    await _createCompatibleDatabase(candidate.path, marker: '백업 시점 데이터');
  });

  tearDown(() async {
    await harness.close();
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  DatabaseRestoreService createService({
    RestoreSourcePicker? sourcePicker,
    RestoreFileOperations? fileOperations,
    DatabaseRestoreSchemaValidator? validator,
    DatabaseSnapshotService? snapshotService,
    RestoreDatabaseCloser? databaseCloser,
    RestoreDatabaseOpener? databaseOpener,
    RestoreRuntimeEnsurer? runtimeEnsurer,
  }) {
    return DatabaseRestoreService(
      sourcePicker: sourcePicker ?? _FixedSourcePicker(candidate.path),
      fileOperations: fileOperations ?? const IoRestoreFileOperations(),
      validator: validator ?? const DatabaseRestoreSchemaValidator(),
      snapshotService: snapshotService ?? const DatabaseSnapshotService(),
      databaseOpener: databaseOpener ?? harness.open,
      databaseCloser: databaseCloser ?? harness.close,
      workPathGetter: () async => harness.workPath,
      dataDirectoryGetter: () async => root.path,
      runtimeEnsurer: runtimeEnsurer ?? (_) async {},
      clock: () => DateTime.fromMicrosecondsSinceEpoch(48003),
    );
  }

  Future<RestoreResult> restore(
    DatabaseRestoreService service, {
    bool confirmed = true,
  }) {
    return service.restore(confirmation: () async => confirmed);
  }

  test('Windows picker는 db filter와 일반 XFile path를 사용한다', () async {
    List<XTypeGroup>? capturedGroups;
    final picker = PlatformRestoreSourcePicker(
      platformOverride: RestorePlatform.windows,
      windowsPicker: (groups) async {
        capturedGroups = groups;
        return XFile(candidate.path);
      },
    );

    final selected = await picker.pick();

    expect(selected?.path, candidate.path);
    expect(selected?.cleanupAfterUse, isFalse);
    expect(capturedGroups, hasLength(1));
    expect(capturedGroups!.single.extensions, ['db']);
  });

  test('Android picker는 db extension과 cache copy 계약을 사용한다', () async {
    OpenFileDialogParams? capturedParams;
    final picker = PlatformRestoreSourcePicker(
      platformOverride: RestorePlatform.android,
      androidPicker: (params) async {
        capturedParams = params;
        return candidate.path;
      },
    );

    final selected = await picker.pick();

    expect(selected?.path, candidate.path);
    expect(selected?.cleanupAfterUse, isTrue);
    expect(capturedParams?.fileExtensionsFilter, ['db']);
    expect(capturedParams?.copyFileToCacheDir, isTrue);
    expect(capturedParams?.mimeTypesFilter, isNull);
  });

  test('Android cache candidate는 성공 후 best-effort 삭제한다', () async {
    final cacheCandidate = File(p.join(root.path, 'android_cache.db'));
    await candidate.copy(cacheCandidate.path);
    final picker = _CleanupSourcePicker(cacheCandidate.path);

    final result = await restore(createService(sourcePicker: picker));

    expect(result, isA<RestoreSucceeded>());
    expect(await cacheCandidate.exists(), isFalse);
  });

  test('파일 선택 취소는 DB 작업 없이 RestoreCancelled를 반환한다', () async {
    final result = await restore(
      createService(sourcePicker: const _CancelledSourcePicker()),
    );

    expect(result, isA<RestoreCancelled>());
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('확인 취소는 DB 작업 없이 RestoreCancelled를 반환한다', () async {
    final result = await restore(createService(), confirmed: false);

    expect(result, isA<RestoreCancelled>());
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('호환 DB를 staging과 검증을 거쳐 교체하고 새 데이터를 다시 연다', () async {
    final beforeHash = await _bytes(candidate);

    final result = await restore(createService());

    expect(result, isA<RestoreSucceeded>());
    expect(await harness.marker(), '백업 시점 데이터');
    expect(await _bytes(candidate), beforeHash);
  });

  test('full legacy backup은 staging에서 archive 후 물리 컬럼을 제거한다', () async {
    await _configureLegacyRelatedState(
      candidate.path,
      columnCount: 7,
      keepArchive: false,
      related1Value: 'unresolved-backup-target',
    );
    final beforeHash = await _bytes(candidate);

    final result = await restore(
      createService(runtimeEnsurer: DatabaseService.ensureRuntimeSchema),
    );

    expect(result, isA<RestoreSucceeded>());
    expect(await harness.marker(), '백업 시점 데이터');
    expect(await _bytes(candidate), beforeHash);

    final restored = await harness.open();
    final columns = (await restored.rawQuery(
      "PRAGMA table_info('WORD_TABLE')",
    )).map((row) => row['name']).whereType<String>().toSet();
    expect(columns.intersection(_legacyRelatedColumns.toSet()), isEmpty);
    expect(
      await restored.query(
        'WORD_LEGACY_RELATED_VALUE',
        orderBy: 'source_word_id, source_column',
      ),
      [
        {
          'source_word_id': 'fixture_word',
          'source_column': '관련1',
          'target_raw_value': 'unresolved-backup-target',
          'preservation_state': 'unresolved_legacy',
          'source_table': 'WORD_TABLE',
        },
      ],
    );
  });

  test('현행 backup은 실제 runtime ensure 후에도 복원된다', () async {
    final result = await restore(
      createService(runtimeEnsurer: DatabaseService.ensureRuntimeSchema),
    );

    expect(result, isA<RestoreSucceeded>());
    expect(await harness.marker(), '백업 시점 데이터');
    final restored = await harness.open();
    expect(
      await restored.rawQuery(
        "SELECT COUNT(*) AS row_count FROM WORD_LEGACY_RELATED_VALUE",
      ),
      [
        {'row_count': 0},
      ],
    );
  });

  test('일부 legacy 관련 컬럼만 있는 backup은 schemaIncompatible로 거절한다', () async {
    await _configureLegacyRelatedState(
      candidate.path,
      columnCount: 3,
      keepArchive: false,
    );

    final result = await restore(
      createService(runtimeEnsurer: DatabaseService.ensureRuntimeSchema),
    );

    expect(
      result,
      isA<RestoreRejected>().having(
        (value) => value.reason,
        'reason',
        RestoreRejectionReason.schemaIncompatible,
      ),
    );
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('legacy 관련 컬럼과 archive가 모두 없는 backup은 거절한다', () async {
    await _configureLegacyRelatedState(
      candidate.path,
      columnCount: 0,
      keepArchive: false,
    );

    final result = await restore(
      createService(runtimeEnsurer: DatabaseService.ensureRuntimeSchema),
    );

    expect(
      result,
      isA<RestoreRejected>().having(
        (value) => value.reason,
        'reason',
        RestoreRejectionReason.schemaIncompatible,
      ),
    );
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('legacy 원문과 충돌하는 archive가 있는 backup은 거절한다', () async {
    await _configureLegacyRelatedState(
      candidate.path,
      columnCount: 7,
      keepArchive: true,
      related1Value: 'original-backup-target',
      conflictingArchiveValue: 'conflicting-backup-target',
    );

    final result = await restore(
      createService(runtimeEnsurer: DatabaseService.ensureRuntimeSchema),
    );

    expect(
      result,
      isA<RestoreRejected>().having(
        (value) => value.reason,
        'reason',
        RestoreRejectionReason.schemaIncompatible,
      ),
    );
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('미지원 발음 표기 방식이 있는 backup은 integrityInvalid로 거절한다', () async {
    final database = await databaseFactory.openDatabase(
      candidate.path,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      await database.insert('word_expression_set', {
        'word_id': 'candidate_word',
        'seq': 1,
        'is_representative': 1,
        'spelling': 'invalid pronunciation metadata',
        'pronunciation': 'a',
        'pronunciation_notation': 'unsupported',
        'pronunciation_notation_name': null,
      });
    } finally {
      await database.close();
    }

    final result = await restore(createService());

    expect(
      result,
      isA<RestoreRejected>().having(
        (value) => value.reason,
        'reason',
        RestoreRejectionReason.integrityInvalid,
      ),
    );
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('비SQLite 파일은 notSqlite로 거절하고 원본 DB를 유지한다', () async {
    await candidate.writeAsString('not sqlite', flush: true);

    final result = await restore(createService());

    expect(
      result,
      isA<RestoreRejected>().having(
        (value) => value.reason,
        'reason',
        RestoreRejectionReason.notSqlite,
      ),
    );
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('integrity 실패는 integrityInvalid로 거절한다', () async {
    final result = await restore(
      createService(
        validator: _RejectingValidator(
          DatabaseValidationFailure.integrityInvalid,
        ),
      ),
    );

    expect(
      result,
      isA<RestoreRejected>().having(
        (value) => value.reason,
        'reason',
        RestoreRejectionReason.integrityInvalid,
      ),
    );
  });

  test('core table 부재는 unsupportedBackup으로 거절한다', () async {
    await harness.replaceCandidateWith(
      candidate,
      statements: ['CREATE TABLE unrelated (id INTEGER PRIMARY KEY)'],
    );

    final result = await restore(createService());

    expect(
      result,
      isA<RestoreRejected>().having(
        (value) => value.reason,
        'reason',
        RestoreRejectionReason.unsupportedBackup,
      ),
    );
  });

  test('필수 column 부재는 schemaIncompatible로 거절한다', () async {
    await _dropAndRecreateWordTable(candidate.path, 'id TEXT PRIMARY KEY');

    final result = await restore(createService());

    expect(
      result,
      isA<RestoreRejected>().having(
        (value) => value.reason,
        'reason',
        RestoreRejectionReason.schemaIncompatible,
      ),
    );
  });

  test('RMAC table 부재는 schemaIncompatible로 거절한다', () async {
    final db = await databaseFactory.openDatabase(
      candidate.path,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute('DROP TABLE RMAC_TABLE_KR');
    await db.close();

    final result = await restore(createService());

    expect(
      result,
      isA<RestoreRejected>().having(
        (value) => value.reason,
        'reason',
        RestoreRejectionReason.schemaIncompatible,
      ),
    );
  });

  test('필수 index가 같은 이름의 non-unique index이면 거절한다', () async {
    final db = await databaseFactory.openDatabase(
      candidate.path,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute('DROP INDEX ux_word_meaning_set_word_seq');
    await db.execute(
      'CREATE INDEX ux_word_meaning_set_word_seq '
      'ON word_meaning_set(word_id, seq)',
    );
    await db.close();

    final result = await restore(createService());

    expect(
      result,
      isA<RestoreRejected>().having(
        (value) => value.reason,
        'reason',
        RestoreRejectionReason.schemaIncompatible,
      ),
    );
  });

  test('rollback snapshot 생성 실패는 교체를 시작하지 않는다', () async {
    final result = await restore(
      createService(snapshotService: const _FailingSnapshotService()),
    );

    expect(
      result,
      isA<RestoreFailed>()
          .having(
            (value) => value.stage,
            'stage',
            RestoreFailureStage.rollbackSnapshotCreation,
          )
          .having(
            (value) => value.rollbackStatus,
            'rollback',
            RestoreRollbackStatus.notRequired,
          ),
    );
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('restore-owned destination 충돌 시 기존 파일을 덮어쓰지 않는다', () async {
    final collision = File(
      p.join(root.path, '.reshet_restore_48003.staged.db'),
    );
    await collision.writeAsString('기존 진단 파일', flush: true);

    final result = await restore(createService());

    expect(
      result,
      isA<RestoreFailed>()
          .having(
            (value) => value.stage,
            'stage',
            RestoreFailureStage.candidatePreparation,
          )
          .having(
            (value) => value.rollbackStatus,
            'rollback',
            RestoreRollbackStatus.notRequired,
          ),
    );
    expect(await collision.readAsString(), '기존 진단 파일');
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('staging 실패는 교체를 시작하지 않는다', () async {
    final operations = _FaultingFileOperations(failCopyCalls: {1});

    final result = await restore(createService(fileOperations: operations));

    expect(
      result,
      isA<RestoreFailed>().having(
        (value) => value.stage,
        'stage',
        RestoreFailureStage.staging,
      ),
    );
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('database close 실패 후 원본 reopen을 확인한다', () async {
    final result = await restore(
      createService(
        databaseCloser: () async => throw StateError('close failed'),
      ),
    );

    expect(
      result,
      isA<RestoreFailed>()
          .having(
            (value) => value.stage,
            'stage',
            RestoreFailureStage.databaseClose,
          )
          .having(
            (value) => value.rollbackStatus,
            'rollback',
            RestoreRollbackStatus.succeeded,
          ),
    );
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('첫 rename 실패 후 기존 work를 reopen한다', () async {
    final operations = _FaultingFileOperations(failRenameCalls: {1});

    final result = await restore(createService(fileOperations: operations));

    expect(
      result,
      isA<RestoreFailed>()
          .having(
            (value) => value.stage,
            'stage',
            RestoreFailureStage.replacement,
          )
          .having(
            (value) => value.rollbackStatus,
            'rollback',
            RestoreRollbackStatus.succeeded,
          ),
    );
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('두 번째 rename 실패 후 previous work를 복구한다', () async {
    final operations = _FaultingFileOperations(failRenameCalls: {2});

    final result = await restore(createService(fileOperations: operations));

    expect(
      result,
      isA<RestoreFailed>().having(
        (value) => value.rollbackStatus,
        'rollback',
        RestoreRollbackStatus.succeeded,
      ),
    );
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('새 DB open 실패 후 previous work를 복구한다', () async {
    var openCount = 0;
    Future<Database> failingOpen() async {
      openCount++;
      if (openCount == 2) throw StateError('new DB open failed');
      return harness.open();
    }

    final result = await restore(createService(databaseOpener: failingOpen));

    expect(
      result,
      isA<RestoreFailed>()
          .having(
            (value) => value.stage,
            'stage',
            RestoreFailureStage.databaseOpen,
          )
          .having(
            (value) => value.rollbackStatus,
            'rollback',
            RestoreRollbackStatus.succeeded,
          ),
    );
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('staged runtime ensure 실패는 live DB를 닫지 않는다', () async {
    final result = await restore(
      createService(
        runtimeEnsurer: (_) async => throw StateError('ensure failed'),
      ),
    );

    expect(
      result,
      isA<RestoreFailed>()
          .having(
            (value) => value.stage,
            'stage',
            RestoreFailureStage.runtimeEnsure,
          )
          .having(
            (value) => value.rollbackStatus,
            'rollback',
            RestoreRollbackStatus.notRequired,
          ),
    );
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('post-restore 검증 실패 후 previous work를 복구한다', () async {
    final validator = _FailingNthConnectionValidator(4);

    final result = await restore(createService(validator: validator));

    expect(
      result,
      isA<RestoreFailed>()
          .having(
            (value) => value.stage,
            'stage',
            RestoreFailureStage.postRestoreValidation,
          )
          .having(
            (value) => value.rollbackStatus,
            'rollback',
            RestoreRollbackStatus.succeeded,
          ),
    );
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('previous rollback 실패 시 snapshot으로 복구한다', () async {
    final operations = _FaultingFileOperations(failRenameCalls: {2, 3});

    final result = await restore(createService(fileOperations: operations));

    expect(
      result,
      isA<RestoreFailed>().having(
        (value) => value.rollbackStatus,
        'rollback',
        RestoreRollbackStatus.succeeded,
      ),
    );
    expect(await harness.marker(), '복원 전 데이터');
  });

  test('previous와 snapshot rollback이 모두 실패하면 파일을 보존하고 failed를 반환한다', () async {
    final operations = _FaultingFileOperations(
      failRenameCalls: {2, 3},
      failCopyCalls: {2},
    );

    final result = await restore(createService(fileOperations: operations));

    expect(
      result,
      isA<RestoreFailed>()
          .having(
            (value) => value.stage,
            'stage',
            RestoreFailureStage.originalReopen,
          )
          .having(
            (value) => value.rollbackStatus,
            'rollback',
            RestoreRollbackStatus.failed,
          ),
    );
  });

  test('rollback 후 원본 reopen 실패를 구분한다', () async {
    final operations = _FaultingFileOperations(failRenameCalls: {2});
    var openCount = 0;
    Future<Database> failingReopen() async {
      openCount++;
      if (openCount >= 2) throw StateError('reopen failed');
      return harness.open();
    }

    final result = await restore(
      createService(fileOperations: operations, databaseOpener: failingReopen),
    );

    expect(
      result,
      isA<RestoreFailed>()
          .having(
            (value) => value.stage,
            'stage',
            RestoreFailureStage.originalReopen,
          )
          .having(
            (value) => value.rollbackStatus,
            'rollback',
            RestoreRollbackStatus.failed,
          ),
    );
  });

  test('cleanup 실패는 검증된 DB 성공을 뒤집지 않는다', () async {
    final operations = _FaultingFileOperations(failDelete: true);

    final result = await restore(createService(fileOperations: operations));

    expect(result, isA<RestoreSucceeded>());
    expect(await harness.marker(), '백업 시점 데이터');
  });
}

class _DatabaseHarness {
  _DatabaseHarness(this.root);

  final Directory root;
  Database? _database;

  String get workPath => p.join(root.path, 'work.db');

  Future<void> createWork({required String marker}) async {
    await _createCompatibleDatabase(workPath, marker: marker);
    await open();
  }

  Future<Database> open() async {
    final current = _database;
    if (current != null && current.isOpen) return current;
    _database = await databaseFactory.openDatabase(
      workPath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    return _database!;
  }

  Future<void> close() async {
    final current = _database;
    _database = null;
    if (current != null && current.isOpen) {
      await current.close();
    }
  }

  Future<String?> marker() async {
    final db = await open();
    final rows = await db.query('WORD_TABLE', columns: ['비고'], limit: 1);
    return rows.single['비고'] as String?;
  }

  Future<void> replaceCandidateWith(
    File file, {
    required List<String> statements,
  }) async {
    if (await file.exists()) await file.delete();
    final db = await databaseFactory.openDatabase(
      file.path,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    for (final statement in statements) {
      await db.execute(statement);
    }
    await db.close();
  }
}

class _FixedSourcePicker implements RestoreSourcePicker {
  const _FixedSourcePicker(this.path);

  final String path;

  @override
  Future<RestoreCandidate?> pick() async => RestoreCandidate(path: path);
}

class _CancelledSourcePicker implements RestoreSourcePicker {
  const _CancelledSourcePicker();

  @override
  Future<RestoreCandidate?> pick() async => null;
}

class _CleanupSourcePicker implements RestoreSourcePicker {
  const _CleanupSourcePicker(this.path);

  final String path;

  @override
  Future<RestoreCandidate?> pick() async {
    return RestoreCandidate(path: path, cleanupAfterUse: true);
  }
}

class _RejectingValidator extends DatabaseRestoreSchemaValidator {
  const _RejectingValidator(this.failure);

  final DatabaseValidationFailure failure;

  @override
  Future<void> validateFile(String path) async {
    throw DatabaseValidationException(failure, 'fixture rejection');
  }
}

class _FailingNthConnectionValidator extends DatabaseRestoreSchemaValidator {
  _FailingNthConnectionValidator(this.failureCall);

  final int failureCall;
  int callCount = 0;

  @override
  Future<void> validateConnection(Database database) async {
    callCount++;
    if (callCount == failureCall) {
      throw const DatabaseValidationException(
        DatabaseValidationFailure.integrityInvalid,
        'post restore validation failed',
      );
    }
    await super.validateConnection(database);
  }
}

class _FailingSnapshotService extends DatabaseSnapshotService {
  const _FailingSnapshotService();

  @override
  Future<DatabaseSnapshot> create({
    required Database sourceDatabase,
    String directoryPrefix = DatabaseSnapshotService.defaultDirectoryPrefix,
  }) async {
    throw SnapshotException(
      stage: SnapshotFailureStage.creation,
      error: StateError('snapshot failed'),
      stackTrace: StackTrace.current,
    );
  }
}

class _FaultingFileOperations implements RestoreFileOperations {
  _FaultingFileOperations({
    this.failCopyCalls = const {},
    this.failRenameCalls = const {},
    this.failDelete = false,
  });

  final Set<int> failCopyCalls;
  final Set<int> failRenameCalls;
  final bool failDelete;
  final IoRestoreFileOperations delegate = const IoRestoreFileOperations();
  int copyCount = 0;
  int renameCount = 0;

  @override
  Future<void> copyWithFlush(String sourcePath, String destinationPath) async {
    copyCount++;
    if (failCopyCalls.contains(copyCount)) {
      throw StateError('copy $copyCount failed');
    }
    await delegate.copyWithFlush(sourcePath, destinationPath);
  }

  @override
  Future<void> delete(String path) async {
    if (failDelete) throw StateError('cleanup failed');
    await delegate.delete(path);
  }

  @override
  Future<bool> exists(String path) => delegate.exists(path);

  @override
  Future<void> rename(String sourcePath, String destinationPath) async {
    renameCount++;
    if (failRenameCalls.contains(renameCount)) {
      throw StateError('rename $renameCount failed');
    }
    await delegate.rename(sourcePath, destinationPath);
  }
}

Future<void> _createCompatibleDatabase(
  String path, {
  required String marker,
}) async {
  final db = await databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  for (final statement in _compatibleSchemaStatements) {
    await db.execute(statement);
  }
  await db.insert('WORD_TABLE', {
    'id': 'fixture_word',
    '스트롱넘버': 'H1',
    '표기1': 'fixture',
    '비고': marker,
  });
  await db.close();
}

Future<void> _configureLegacyRelatedState(
  String path, {
  required int columnCount,
  required bool keepArchive,
  String? related1Value,
  String? conflictingArchiveValue,
}) async {
  assert(columnCount >= 0 && columnCount <= _legacyRelatedColumns.length);
  final db = await databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  try {
    if (!keepArchive) {
      await db.execute('DROP TABLE WORD_LEGACY_RELATED_VALUE');
    }
    for (final column in _legacyRelatedColumns.take(columnCount)) {
      await db.execute('ALTER TABLE WORD_TABLE ADD COLUMN "$column" TEXT');
    }
    if (related1Value != null) {
      await db.update(
        'WORD_TABLE',
        {'관련1': related1Value},
        where: 'id = ?',
        whereArgs: ['fixture_word'],
      );
    }
    if (conflictingArchiveValue != null) {
      await db.insert('WORD_LEGACY_RELATED_VALUE', {
        'source_word_id': 'fixture_word',
        'source_column': '관련1',
        'target_raw_value': conflictingArchiveValue,
        'preservation_state': 'unresolved_legacy',
        'source_table': 'WORD_TABLE',
      });
    }
  } finally {
    await db.close();
  }
}

Future<void> _dropAndRecreateWordTable(String path, String columns) async {
  final db = await databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await db.execute('DROP TABLE WORD_TABLE');
  await db.execute('CREATE TABLE WORD_TABLE ($columns)');
  await db.close();
}

Future<List<int>> _bytes(File file) => file.readAsBytes();

const _legacyRelatedColumns = ['관련1', '관련2', '관련3', '관련4', '관련5', '관련6', '관련7'];

const _compatibleSchemaStatements = [
  'CREATE TABLE WORD_TABLE (id TEXT PRIMARY KEY, 언어 TEXT, 스트롱넘버 TEXT, 표기1 TEXT, 표기2 TEXT, 표기3 TEXT, 표기4 TEXT, 표기5 TEXT, 표기6 TEXT, 음역1 TEXT, 음역2 TEXT, 음역3 TEXT, 음역4 TEXT, 음역5 TEXT, 음역6 TEXT, 발음1 TEXT, 발음2 TEXT, 발음3 TEXT, 발음4 TEXT, 발음5 TEXT, 발음6 TEXT, 의미1 TEXT, 의미2 TEXT, 의미3 TEXT, 의미4 TEXT, 의미5 TEXT, 의미6 TEXT, 의미7 TEXT, 비고 TEXT)',
  _legacyRelatedArchiveDdl,
  'CREATE TABLE WORD_RELATION (id INTEGER PRIMARY KEY, word_id_1 TEXT, word_id_2 TEXT, category_code TEXT, relation_type TEXT, status_code TEXT, direction_code TEXT, description TEXT, relation_group_id TEXT)',
  'CREATE TABLE word_expression_set (id INTEGER PRIMARY KEY, word_id TEXT, seq INTEGER, is_representative INTEGER, spelling TEXT, transliteration TEXT, pronunciation TEXT, pronunciation_notation TEXT, pronunciation_notation_name TEXT)',
  'CREATE TABLE word_meaning_set (id INTEGER PRIMARY KEY, word_id TEXT, seq INTEGER, meaning TEXT)',
  'CREATE TABLE CHANGE_HISTORY (id INTEGER PRIMARY KEY, group_id TEXT, action_type TEXT, entity_type TEXT, entity_id TEXT, before_json TEXT, after_json TEXT, created_at TEXT, undone_at TEXT)',
  'CREATE TABLE RELATION_CATEGORY (code TEXT PRIMARY KEY, label TEXT, description TEXT, sort_order INTEGER)',
  'CREATE TABLE RELATION_TYPE (code TEXT PRIMARY KEY, category_code TEXT, label TEXT, description TEXT, sort_order INTEGER)',
  'CREATE TABLE RELATION_STATUS (code TEXT PRIMARY KEY, label TEXT, description TEXT, sort_order INTEGER)',
  'CREATE TABLE RMAC_TABLE (RMAC TEXT PRIMARY KEY, Part_of_Speech TEXT, Tense TEXT, Voice TEXT, Mood TEXT, Person TEXT, "Case" TEXT, Number TEXT, Gender TEXT, Degree TEXT, Form TEXT)',
  'CREATE TABLE RMAC_TABLE_KR (RMAC TEXT PRIMARY KEY, Part_of_Speech TEXT, Tense TEXT, Voice TEXT, Mood TEXT, Person TEXT, "Case" TEXT, Number TEXT, Gender TEXT, Degree TEXT, Form TEXT)',
  'CREATE UNIQUE INDEX idx_word_relation_pair_type_direction_unique ON WORD_RELATION(word_id_1, word_id_2, relation_type, direction_code)',
  'CREATE UNIQUE INDEX ux_word_expression_set_word_seq ON word_expression_set(word_id, seq)',
  'CREATE UNIQUE INDEX ux_word_expression_set_one_representative ON word_expression_set(word_id) WHERE is_representative = 1',
  'CREATE UNIQUE INDEX ux_word_meaning_set_word_seq ON word_meaning_set(word_id, seq)',
];

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
