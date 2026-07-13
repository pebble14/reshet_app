import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database_service.dart';
import 'database_snapshot_service.dart';

enum RestoreRejectionReason {
  notSqlite,
  integrityInvalid,
  schemaIncompatible,
  unsupportedBackup,
}

enum RestoreFailureStage {
  sourceSelection,
  candidatePreparation,
  candidateValidation,
  rollbackSnapshotCreation,
  databaseClose,
  staging,
  replacement,
  databaseOpen,
  runtimeEnsure,
  postRestoreValidation,
  rollback,
  originalReopen,
}

enum RestoreRollbackStatus { notRequired, succeeded, failed }

sealed class RestoreResult {
  const RestoreResult();
}

final class RestoreSucceeded extends RestoreResult {
  const RestoreSucceeded();
}

final class RestoreCancelled extends RestoreResult {
  const RestoreCancelled();
}

final class RestoreRejected extends RestoreResult {
  const RestoreRejected(this.reason);

  final RestoreRejectionReason reason;
}

final class RestoreFailed extends RestoreResult {
  const RestoreFailed({
    required this.stage,
    required this.rollbackStatus,
    required this.error,
    required this.stackTrace,
  });

  final RestoreFailureStage stage;
  final RestoreRollbackStatus rollbackStatus;
  final Object error;
  final StackTrace stackTrace;
}

final class RestoreCandidate {
  const RestoreCandidate({required this.path, this.cleanupAfterUse = false});

  final String path;
  final bool cleanupAfterUse;
}

abstract interface class RestoreSourcePicker {
  Future<RestoreCandidate?> pick();
}

enum RestorePlatform { windows, android, unsupported }

typedef WindowsRestoreFilePicker =
    Future<XFile?> Function(List<XTypeGroup> acceptedTypeGroups);
typedef AndroidRestoreFilePicker =
    Future<String?> Function(OpenFileDialogParams params);

class PlatformRestoreSourcePicker implements RestoreSourcePicker {
  const PlatformRestoreSourcePicker({
    WindowsRestoreFilePicker? windowsPicker,
    AndroidRestoreFilePicker? androidPicker,
    RestorePlatform? platformOverride,
  }) : _windowsPicker = windowsPicker,
       _androidPicker = androidPicker,
       _platformOverride = platformOverride;

  static const XTypeGroup _sqliteTypeGroup = XTypeGroup(
    label: 'SQLite database',
    extensions: ['db'],
  );

  final WindowsRestoreFilePicker? _windowsPicker;
  final AndroidRestoreFilePicker? _androidPicker;
  final RestorePlatform? _platformOverride;

  @override
  Future<RestoreCandidate?> pick() async {
    final platform =
        _platformOverride ??
        (Platform.isWindows
            ? RestorePlatform.windows
            : Platform.isAndroid
            ? RestorePlatform.android
            : RestorePlatform.unsupported);
    if (platform == RestorePlatform.windows) {
      final file =
          await (_windowsPicker?.call(const [_sqliteTypeGroup]) ??
              openFile(acceptedTypeGroups: const [_sqliteTypeGroup]));
      return file == null ? null : RestoreCandidate(path: file.path);
    }
    if (platform == RestorePlatform.android) {
      const params = OpenFileDialogParams(
        fileExtensionsFilter: ['db'],
        copyFileToCacheDir: true,
      );
      final path =
          await (_androidPicker?.call(params) ??
              FlutterFileDialog.pickFile(params: params));
      return path == null
          ? null
          : RestoreCandidate(path: path, cleanupAfterUse: true);
    }
    throw UnsupportedError('Data restore source is not supported.');
  }
}

abstract interface class DatabaseRestoreRunner {
  Future<RestoreResult> restore({
    required Future<bool> Function() confirmation,
  });
}

abstract interface class RestoreFileOperations {
  Future<bool> exists(String path);
  Future<void> copyWithFlush(String sourcePath, String destinationPath);
  Future<void> rename(String sourcePath, String destinationPath);
  Future<void> delete(String path);
}

class IoRestoreFileOperations implements RestoreFileOperations {
  const IoRestoreFileOperations();

  @override
  Future<bool> exists(String path) => File(path).exists();

  @override
  Future<void> copyWithFlush(String sourcePath, String destinationPath) async {
    final destination = File(destinationPath);
    if (await destination.exists()) {
      throw StateError('Restore-owned destination already exists.');
    }
    await File(sourcePath).openRead().pipe(destination.openWrite());
    final flushedFile = await destination.open(mode: FileMode.append);
    try {
      await flushedFile.flush();
    } finally {
      await flushedFile.close();
    }
  }

  @override
  Future<void> rename(String sourcePath, String destinationPath) async {
    if (await File(destinationPath).exists() ||
        await Directory(destinationPath).exists()) {
      throw StateError('Restore rename destination already exists.');
    }
    await File(sourcePath).rename(destinationPath);
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

typedef RestoreDatabaseOpener = Future<Database> Function();
typedef RestoreDatabaseCloser = Future<void> Function();
typedef RestorePathGetter = Future<String> Function();
typedef RestoreStagedDatabaseOpener = Future<Database> Function(String path);
typedef RestoreRuntimeEnsurer = Future<void> Function(Database database);
typedef RestoreClock = DateTime Function();

class DatabaseRestoreService implements DatabaseRestoreRunner {
  const DatabaseRestoreService({
    this.sourcePicker = const PlatformRestoreSourcePicker(),
    this.fileOperations = const IoRestoreFileOperations(),
    this.validator = const DatabaseRestoreSchemaValidator(),
    this.snapshotService = const DatabaseSnapshotService(),
    RestoreDatabaseOpener? databaseOpener,
    RestoreDatabaseCloser? databaseCloser,
    RestorePathGetter? workPathGetter,
    RestorePathGetter? dataDirectoryGetter,
    RestoreStagedDatabaseOpener? stagedDatabaseOpener,
    RestoreRuntimeEnsurer? runtimeEnsurer,
    RestoreClock? clock,
  }) : _databaseOpener = databaseOpener,
       _databaseCloser = databaseCloser,
       _workPathGetter = workPathGetter,
       _dataDirectoryGetter = dataDirectoryGetter,
       _stagedDatabaseOpener = stagedDatabaseOpener,
       _runtimeEnsurer = runtimeEnsurer,
       _clock = clock;

  static const String rollbackSnapshotPrefix = 'reshet_restore_rollback_';

  final RestoreSourcePicker sourcePicker;
  final RestoreFileOperations fileOperations;
  final DatabaseRestoreSchemaValidator validator;
  final DatabaseSnapshotService snapshotService;
  final RestoreDatabaseOpener? _databaseOpener;
  final RestoreDatabaseCloser? _databaseCloser;
  final RestorePathGetter? _workPathGetter;
  final RestorePathGetter? _dataDirectoryGetter;
  final RestoreStagedDatabaseOpener? _stagedDatabaseOpener;
  final RestoreRuntimeEnsurer? _runtimeEnsurer;
  final RestoreClock? _clock;

  @override
  Future<RestoreResult> restore({
    required Future<bool> Function() confirmation,
  }) async {
    RestoreCandidate? candidate;
    try {
      try {
        candidate = await sourcePicker.pick();
      } catch (error, stackTrace) {
        return RestoreFailed(
          stage: RestoreFailureStage.sourceSelection,
          rollbackStatus: RestoreRollbackStatus.notRequired,
          error: error,
          stackTrace: stackTrace,
        );
      }
      if (candidate == null) {
        return const RestoreCancelled();
      }

      bool confirmed;
      try {
        confirmed = await confirmation();
      } catch (error, stackTrace) {
        return RestoreFailed(
          stage: RestoreFailureStage.sourceSelection,
          rollbackStatus: RestoreRollbackStatus.notRequired,
          error: error,
          stackTrace: stackTrace,
        );
      }
      if (!confirmed) {
        return const RestoreCancelled();
      }

      return await _restoreCandidate(candidate);
    } finally {
      if (candidate?.cleanupAfterUse ?? false) {
        try {
          await fileOperations.delete(candidate!.path);
        } catch (error, stackTrace) {
          debugPrint('Android 복원 입력 cache 정리 실패: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    }
  }

  Future<RestoreResult> _restoreCandidate(RestoreCandidate candidate) async {
    try {
      await validator.validateFile(candidate.path);
    } on DatabaseValidationException catch (error) {
      return RestoreRejected(_rejectionReason(error.failure));
    } catch (error, stackTrace) {
      return RestoreFailed(
        stage: RestoreFailureStage.candidateValidation,
        rollbackStatus: RestoreRollbackStatus.notRequired,
        error: error,
        stackTrace: stackTrace,
      );
    }

    DatabaseSnapshot? rollbackSnapshot;
    String? stagedPath;
    String? previousPath;
    String? failedPath;
    String? workPath;
    var liveDatabaseClosed = false;
    var stagedFileOwned = false;
    var workMovedToPrevious = false;
    var replacementMovedToWork = false;

    try {
      final liveDatabase = await _runStage(
        RestoreFailureStage.rollbackSnapshotCreation,
        () => _databaseOpener?.call() ?? DatabaseService.openDatabaseFile(),
      );
      rollbackSnapshot = await _runStage(
        RestoreFailureStage.rollbackSnapshotCreation,
        () => snapshotService.create(
          sourceDatabase: liveDatabase,
          directoryPrefix: rollbackSnapshotPrefix,
        ),
      );

      final dataDirectory = await _runStage(
        RestoreFailureStage.candidatePreparation,
        () =>
            _dataDirectoryGetter?.call() ?? DatabaseService.dataDirectoryPath(),
      );
      final resolvedWorkPath = await _runStage(
        RestoreFailureStage.candidatePreparation,
        () => _workPathGetter?.call() ?? DatabaseService.workDatabasePath(),
      );
      workPath = resolvedWorkPath;
      if (p.equals(
        p.normalize(p.absolute(candidate.path)),
        p.normalize(p.absolute(resolvedWorkPath)),
      )) {
        throw _RestoreStageException(
          RestoreFailureStage.candidatePreparation,
          StateError(
            'The live work database cannot be its own restore source.',
          ),
          StackTrace.current,
        );
      }
      final token = (_clock?.call() ?? DateTime.now()).microsecondsSinceEpoch
          .toString();
      stagedPath = p.join(dataDirectory, '.reshet_restore_$token.staged.db');
      previousPath = p.join(
        dataDirectory,
        '.reshet_restore_$token.previous.db',
      );
      failedPath = p.join(dataDirectory, '.reshet_restore_$token.failed.db');
      for (final ownedPath in [stagedPath, previousPath, failedPath]) {
        if (await fileOperations.exists(ownedPath)) {
          throw _RestoreStageException(
            RestoreFailureStage.candidatePreparation,
            StateError('Restore-owned path already exists.'),
            StackTrace.current,
          );
        }
      }

      stagedFileOwned = true;
      await _runStage(
        RestoreFailureStage.staging,
        () => fileOperations.copyWithFlush(candidate.path, stagedPath!),
      );
      await _runStage(
        RestoreFailureStage.candidateValidation,
        () => validator.validateFile(stagedPath!),
      );

      Database? stagedDatabase;
      try {
        stagedDatabase = await _runStage(
          RestoreFailureStage.runtimeEnsure,
          () =>
              _stagedDatabaseOpener?.call(stagedPath!) ??
              databaseFactory.openDatabase(
                stagedPath!,
                options: OpenDatabaseOptions(singleInstance: false),
              ),
        );
        await _runStage(
          RestoreFailureStage.runtimeEnsure,
          () =>
              _runtimeEnsurer?.call(stagedDatabase!) ??
              DatabaseService.ensureRuntimeSchema(stagedDatabase!),
        );
      } finally {
        if (stagedDatabase != null && stagedDatabase.isOpen) {
          await stagedDatabase.close();
        }
      }
      await _runStage(
        RestoreFailureStage.candidateValidation,
        () => validator.validateFile(stagedPath!),
      );

      await _runStage(
        RestoreFailureStage.databaseClose,
        () => _databaseCloser?.call() ?? DatabaseService.closeDatabase(),
      );
      liveDatabaseClosed = true;
      await _runStage(
        RestoreFailureStage.replacement,
        () => fileOperations.rename(workPath!, previousPath!),
      );
      workMovedToPrevious = true;
      await _runStage(
        RestoreFailureStage.replacement,
        () => fileOperations.rename(stagedPath!, workPath!),
      );
      replacementMovedToWork = true;

      final restoredDatabase = await _runStage(
        RestoreFailureStage.databaseOpen,
        () => _databaseOpener?.call() ?? DatabaseService.openDatabaseFile(),
      );
      await _runStage(RestoreFailureStage.postRestoreValidation, () async {
        await validator.validateConnection(restoredDatabase);
        await restoredDatabase.rawQuery(
          'SELECT COUNT(*) AS row_count FROM WORD_TABLE',
        );
      });

      await _bestEffortDelete(previousPath);
      await _bestEffortSnapshotCleanup(rollbackSnapshot);
      return const RestoreSucceeded();
    } on _RestoreStageException catch (failure) {
      return _recoverFromFailure(
        failure: failure,
        rollbackSnapshot: rollbackSnapshot,
        workPath: workPath,
        stagedPath: stagedPath,
        previousPath: previousPath,
        failedPath: failedPath,
        liveDatabaseClosed: liveDatabaseClosed,
        stagedFileOwned: stagedFileOwned,
        workMovedToPrevious: workMovedToPrevious,
        replacementMovedToWork: replacementMovedToWork,
      );
    } catch (error, stackTrace) {
      return _recoverFromFailure(
        failure: _RestoreStageException(
          RestoreFailureStage.candidatePreparation,
          error,
          stackTrace,
        ),
        rollbackSnapshot: rollbackSnapshot,
        workPath: workPath,
        stagedPath: stagedPath,
        previousPath: previousPath,
        failedPath: failedPath,
        liveDatabaseClosed: liveDatabaseClosed,
        stagedFileOwned: stagedFileOwned,
        workMovedToPrevious: workMovedToPrevious,
        replacementMovedToWork: replacementMovedToWork,
      );
    }
  }

  Future<RestoreResult> _recoverFromFailure({
    required _RestoreStageException failure,
    required DatabaseSnapshot? rollbackSnapshot,
    required String? workPath,
    required String? stagedPath,
    required String? previousPath,
    required String? failedPath,
    required bool liveDatabaseClosed,
    required bool stagedFileOwned,
    required bool workMovedToPrevious,
    required bool replacementMovedToWork,
  }) async {
    final needsReopen =
        liveDatabaseClosed ||
        workMovedToPrevious ||
        failure.stage == RestoreFailureStage.databaseClose;
    if (!needsReopen || workPath == null) {
      if (stagedFileOwned) {
        await _bestEffortDelete(stagedPath);
      }
      await _bestEffortSnapshotCleanup(rollbackSnapshot);
      return RestoreFailed(
        stage: failure.stage,
        rollbackStatus: RestoreRollbackStatus.notRequired,
        error: failure.error,
        stackTrace: failure.stackTrace,
      );
    }

    try {
      if (replacementMovedToWork) {
        await (_databaseCloser?.call() ?? DatabaseService.closeDatabase());
      }
      if (workMovedToPrevious) {
        if (replacementMovedToWork &&
            failedPath != null &&
            await fileOperations.exists(workPath)) {
          await fileOperations.rename(workPath, failedPath);
        }

        var previousRestored = false;
        if (previousPath != null && await fileOperations.exists(previousPath)) {
          try {
            await fileOperations.rename(previousPath, workPath);
            previousRestored = true;
          } catch (error, stackTrace) {
            debugPrint('previous work DB 복구 실패: $error');
            debugPrintStack(stackTrace: stackTrace);
          }
        }

        if (!previousRestored) {
          if (rollbackSnapshot == null) {
            throw StateError('Rollback snapshot is unavailable.');
          }
          if (await fileOperations.exists(workPath)) {
            throw StateError('Rollback destination is not empty.');
          }
          await fileOperations.copyWithFlush(
            rollbackSnapshot.file.path,
            workPath,
          );
        }
      }

      final reopenedDatabase =
          await (_databaseOpener?.call() ?? DatabaseService.openDatabaseFile());
      await validator.validateConnection(reopenedDatabase);
      await reopenedDatabase.rawQuery(
        'SELECT COUNT(*) AS row_count FROM WORD_TABLE',
      );
      if (stagedFileOwned) {
        await _bestEffortDelete(stagedPath);
      }
      await _bestEffortSnapshotCleanup(rollbackSnapshot);
      return RestoreFailed(
        stage: failure.stage,
        rollbackStatus: RestoreRollbackStatus.succeeded,
        error: failure.error,
        stackTrace: failure.stackTrace,
      );
    } catch (reopenError, reopenStackTrace) {
      return RestoreFailed(
        stage: RestoreFailureStage.originalReopen,
        rollbackStatus: RestoreRollbackStatus.failed,
        error: reopenError,
        stackTrace: reopenStackTrace,
      );
    }
  }

  Future<T> _runStage<T>(
    RestoreFailureStage stage,
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      throw _RestoreStageException(stage, error, stackTrace);
    }
  }

  Future<void> _bestEffortDelete(String? path) async {
    if (path == null) return;
    try {
      await fileOperations.delete(path);
    } catch (error, stackTrace) {
      debugPrint('복원 임시 파일 정리 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _bestEffortSnapshotCleanup(DatabaseSnapshot? snapshot) async {
    if (snapshot == null) return;
    try {
      await snapshot.cleanup();
    } catch (error, stackTrace) {
      debugPrint('복원 rollback snapshot 정리 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static RestoreRejectionReason _rejectionReason(
    DatabaseValidationFailure failure,
  ) {
    return switch (failure) {
      DatabaseValidationFailure.notSqlite => RestoreRejectionReason.notSqlite,
      DatabaseValidationFailure.integrityInvalid =>
        RestoreRejectionReason.integrityInvalid,
      DatabaseValidationFailure.schemaIncompatible =>
        RestoreRejectionReason.schemaIncompatible,
      DatabaseValidationFailure.unsupportedBackup =>
        RestoreRejectionReason.unsupportedBackup,
    };
  }
}

final class _RestoreStageException implements Exception {
  const _RestoreStageException(this.stage, this.error, this.stackTrace);

  final RestoreFailureStage stage;
  final Object error;
  final StackTrace stackTrace;
}
