import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database_service.dart';

abstract interface class BackupDestinationWriter {
  Future<String?> save({
    required String fileName,
    required Uint8List bytes,
    required String sourceFilePath,
  });
}

typedef BackupSaveLocationGetter =
    Future<FileSaveLocation?> Function({
      required List<XTypeGroup> acceptedTypeGroups,
      required String suggestedName,
    });
typedef AndroidBackupFileSaver =
    Future<String?> Function({
      required String sourceFilePath,
      required String fileName,
    });

class PlatformBackupDestinationWriter implements BackupDestinationWriter {
  const PlatformBackupDestinationWriter({
    this.fileSelectorWriter = const FileSelectorBackupDestinationWriter(),
    this.androidWriter = const AndroidBackupDestinationWriter(),
  });

  final BackupDestinationWriter fileSelectorWriter;
  final BackupDestinationWriter androidWriter;

  @override
  Future<String?> save({
    required String fileName,
    required Uint8List bytes,
    required String sourceFilePath,
  }) {
    if (Platform.isAndroid) {
      return androidWriter.save(
        fileName: fileName,
        bytes: bytes,
        sourceFilePath: sourceFilePath,
      );
    }
    if (Platform.isWindows) {
      return fileSelectorWriter.save(
        fileName: fileName,
        bytes: bytes,
        sourceFilePath: sourceFilePath,
      );
    }
    throw UnsupportedError('Data backup destination is not supported.');
  }
}

class FileSelectorBackupDestinationWriter implements BackupDestinationWriter {
  const FileSelectorBackupDestinationWriter({
    BackupSaveLocationGetter? saveLocationGetter,
  }) : _saveLocationGetter = saveLocationGetter;

  static const XTypeGroup _sqliteTypeGroup = XTypeGroup(
    label: 'SQLite database',
    extensions: ['db'],
  );

  final BackupSaveLocationGetter? _saveLocationGetter;

  @override
  Future<String?> save({
    required String fileName,
    required Uint8List bytes,
    required String sourceFilePath,
  }) async {
    final location =
        await (_saveLocationGetter?.call(
              acceptedTypeGroups: const [_sqliteTypeGroup],
              suggestedName: fileName,
            ) ??
            getSaveLocation(
              acceptedTypeGroups: const [_sqliteTypeGroup],
              suggestedName: fileName,
            ));
    if (location == null) {
      return null;
    }

    final file = XFile.fromData(
      bytes,
      mimeType: 'application/vnd.sqlite3',
      name: fileName,
    );
    await file.saveTo(location.path);
    return location.path;
  }
}

class AndroidBackupDestinationWriter implements BackupDestinationWriter {
  const AndroidBackupDestinationWriter({AndroidBackupFileSaver? saveFile})
    : _saveFile = saveFile;

  final AndroidBackupFileSaver? _saveFile;

  @override
  Future<String?> save({
    required String fileName,
    required Uint8List bytes,
    required String sourceFilePath,
  }) {
    return _saveFile?.call(
          sourceFilePath: sourceFilePath,
          fileName: fileName,
        ) ??
        FlutterFileDialog.saveFile(
          params: SaveFileDialogParams(
            sourceFilePath: sourceFilePath,
            fileName: fileName,
            mimeTypesFilter: const ['application/vnd.sqlite3'],
          ),
        );
  }
}

enum BackupFailureStage {
  snapshotCreation,
  snapshotValidation,
  sourceRead,
  destinationWrite,
}

sealed class BackupResult {
  const BackupResult();
}

final class BackupSucceeded extends BackupResult {
  const BackupSucceeded();
}

final class BackupCancelled extends BackupResult {
  const BackupCancelled();
}

final class BackupFailed extends BackupResult {
  const BackupFailed({
    required this.stage,
    required this.error,
    required this.stackTrace,
  });

  final BackupFailureStage stage;
  final Object error;
  final StackTrace stackTrace;
}

abstract interface class DatabaseBackupRunner {
  Future<BackupResult> createBackup();
}

typedef BackupSourceDatabaseOpener = Future<Database> Function();
typedef BackupTempDirectoryCreator = Future<Directory> Function(String prefix);
typedef BackupSnapshotDatabaseOpener = Future<Database> Function(String path);
typedef BackupClock = DateTime Function();

class DatabaseBackupService implements DatabaseBackupRunner {
  const DatabaseBackupService({
    this.destinationWriter = const PlatformBackupDestinationWriter(),
    BackupSourceDatabaseOpener? sourceDatabaseOpener,
    BackupTempDirectoryCreator? tempDirectoryCreator,
    BackupSnapshotDatabaseOpener? snapshotDatabaseOpener,
    BackupClock? clock,
  }) : _sourceDatabaseOpener = sourceDatabaseOpener,
       _tempDirectoryCreator = tempDirectoryCreator,
       _snapshotDatabaseOpener = snapshotDatabaseOpener,
       _clock = clock;

  static const String tempDirectoryPrefix = 'reshet_backup_snapshot_';
  static const String snapshotFileName = 'snapshot.db';
  static const Set<String> requiredRuntimeTables = {
    'WORD_TABLE',
    'WORD_RELATION',
    'word_expression_set',
    'word_meaning_set',
    'CHANGE_HISTORY',
    'RELATION_CATEGORY',
    'RELATION_TYPE',
    'RELATION_STATUS',
  };

  final BackupDestinationWriter destinationWriter;
  final BackupSourceDatabaseOpener? _sourceDatabaseOpener;
  final BackupTempDirectoryCreator? _tempDirectoryCreator;
  final BackupSnapshotDatabaseOpener? _snapshotDatabaseOpener;
  final BackupClock? _clock;

  @override
  Future<BackupResult> createBackup() async {
    Directory? tempDirectory;
    File? snapshotFile;
    Database? validationDatabase;

    try {
      final sourceDatabase = await _runStage(
        BackupFailureStage.snapshotCreation,
        () =>
            _sourceDatabaseOpener?.call() ?? DatabaseService.openDatabaseFile(),
      );
      final createdTempDirectory = await _runStage(
        BackupFailureStage.snapshotCreation,
        () =>
            _tempDirectoryCreator?.call(tempDirectoryPrefix) ??
            Directory.systemTemp.createTemp(tempDirectoryPrefix),
      );
      tempDirectory = createdTempDirectory;
      final createdSnapshotFile = File(
        p.join(createdTempDirectory.path, snapshotFileName),
      );
      snapshotFile = createdSnapshotFile;

      await _runStage(BackupFailureStage.snapshotCreation, () async {
        if (await createdSnapshotFile.exists()) {
          throw StateError('Snapshot output path already exists.');
        }
        await sourceDatabase.execute('VACUUM INTO ?', [
          createdSnapshotFile.path,
        ]);
      });

      await _runStage(BackupFailureStage.snapshotValidation, () async {
        validationDatabase =
            await (_snapshotDatabaseOpener?.call(createdSnapshotFile.path) ??
                databaseFactory.openDatabase(
                  createdSnapshotFile.path,
                  options: OpenDatabaseOptions(
                    readOnly: true,
                    singleInstance: false,
                  ),
                ));
        await _validateSnapshot(validationDatabase!);
        await validationDatabase!.close();
        validationDatabase = null;
      });

      await _runStage(
        BackupFailureStage.sourceRead,
        () => sourceDatabase.rawQuery('SELECT 1'),
      );

      final snapshotBytes = await _runStage(
        BackupFailureStage.sourceRead,
        createdSnapshotFile.readAsBytes,
      );
      final selectedDestination = await _runStage(
        BackupFailureStage.destinationWrite,
        () => destinationWriter.save(
          fileName: buildDefaultFileName(_clock?.call() ?? DateTime.now()),
          bytes: snapshotBytes,
          sourceFilePath: createdSnapshotFile.path,
        ),
      );

      return selectedDestination == null
          ? const BackupCancelled()
          : const BackupSucceeded();
    } on _BackupStageException catch (failure) {
      return BackupFailed(
        stage: failure.stage,
        error: failure.error,
        stackTrace: failure.stackTrace,
      );
    } finally {
      if (validationDatabase != null) {
        try {
          await validationDatabase!.close();
        } catch (error, stackTrace) {
          debugPrint('백업 snapshot 검증 connection 정리 실패: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
      await _cleanupTempSnapshot(tempDirectory, snapshotFile);
    }
  }

  static String buildDefaultFileName(DateTime localTime) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return 'reshet_backup_'
        '${localTime.year.toString().padLeft(4, '0')}'
        '${twoDigits(localTime.month)}'
        '${twoDigits(localTime.day)}_'
        '${twoDigits(localTime.hour)}'
        '${twoDigits(localTime.minute)}'
        '${twoDigits(localTime.second)}.db';
  }

  static Future<void> _validateSnapshot(Database snapshotDatabase) async {
    final integrityRows = await snapshotDatabase.rawQuery(
      'PRAGMA integrity_check',
    );
    final integrityValue = integrityRows.length == 1
        ? integrityRows.single.values.single
        : null;
    if (integrityValue != 'ok') {
      throw StateError('Snapshot integrity check failed.');
    }

    final schemaRows = await snapshotDatabase.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
      ''');
    final tableNames = schemaRows
        .map((row) => row['name'])
        .whereType<String>()
        .toSet();
    final missingTables = requiredRuntimeTables.difference(tableNames);
    if (missingTables.isNotEmpty) {
      throw StateError('Snapshot runtime schema is incomplete.');
    }
  }

  static Future<T> _runStage<T>(
    BackupFailureStage stage,
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      throw _BackupStageException(stage, error, stackTrace);
    }
  }

  static Future<void> _cleanupTempSnapshot(
    Directory? tempDirectory,
    File? snapshotFile,
  ) async {
    if (tempDirectory == null || snapshotFile == null) {
      return;
    }

    final normalizedDirectory = p.normalize(p.absolute(tempDirectory.path));
    final normalizedSnapshot = p.normalize(p.absolute(snapshotFile.path));
    final isExpectedDirectory = p
        .basename(normalizedDirectory)
        .startsWith(tempDirectoryPrefix);
    final isSnapshotInsideDirectory =
        p.dirname(normalizedSnapshot) == normalizedDirectory;
    if (!isExpectedDirectory || !isSnapshotInsideDirectory) {
      debugPrint('백업 임시 파일 경로 안전성 확인 실패로 cleanup을 건너뜁니다.');
      return;
    }

    try {
      if (await snapshotFile.exists()) {
        await snapshotFile.delete();
      }
      if (await tempDirectory.exists()) {
        await tempDirectory.delete();
      }
    } catch (error, stackTrace) {
      debugPrint('백업 임시 파일 정리 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

class _BackupStageException implements Exception {
  const _BackupStageException(this.stage, this.error, this.stackTrace);

  final BackupFailureStage stage;
  final Object error;
  final StackTrace stackTrace;
}
