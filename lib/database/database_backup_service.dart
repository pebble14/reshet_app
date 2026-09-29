import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:path/path.dart' as p;

import 'database_service.dart';
import 'database_snapshot_service.dart';

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
    this.protectedDirectories = const [],
  }) : _saveLocationGetter = saveLocationGetter;

  static const XTypeGroup _sqliteTypeGroup = XTypeGroup(
    label: 'SQLite database',
    extensions: ['db'],
  );

  final BackupSaveLocationGetter? _saveLocationGetter;
  final List<String> protectedDirectories;

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

    final parent = await Directory(
      p.dirname(p.absolute(location.path)),
    ).resolveSymbolicLinks();
    final destination = p.join(parent, p.basename(location.path));
    for (final directory in protectedDirectories) {
      final protected = await Directory(directory).resolveSymbolicLinks();
      if (p.equals(protected, destination) ||
          p.isWithin(protected, destination)) {
        throw StateError('백업은 앱 데이터 폴더 밖에 저장해야 합니다.');
      }
    }
    if (await File(destination).exists()) {
      final resolved = await File(destination).resolveSymbolicLinks();
      for (final directory in protectedDirectories) {
        final protected = await Directory(directory).resolveSymbolicLinks();
        if (p.equals(protected, resolved) || p.isWithin(protected, resolved)) {
          throw StateError('앱 데이터 파일을 백업 대상으로 덮어쓸 수 없습니다.');
        }
      }
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
typedef BackupTempDirectoryCreator = SnapshotTempDirectoryCreator;
typedef BackupSnapshotDatabaseOpener = SnapshotDatabaseOpener;
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
  static const String snapshotFileName =
      DatabaseSnapshotService.snapshotFileName;
  static const Set<String> requiredRuntimeTables =
      DatabaseRestoreSchemaValidator.requiredTables;

  final BackupDestinationWriter destinationWriter;
  final BackupSourceDatabaseOpener? _sourceDatabaseOpener;
  final BackupTempDirectoryCreator? _tempDirectoryCreator;
  final BackupSnapshotDatabaseOpener? _snapshotDatabaseOpener;
  final BackupClock? _clock;

  @override
  Future<BackupResult> createBackup() async {
    DatabaseSnapshot? snapshot;

    try {
      final sourceDatabase = await _runStage(
        BackupFailureStage.snapshotCreation,
        () =>
            _sourceDatabaseOpener?.call() ?? DatabaseService.openDatabaseFile(),
      );
      try {
        snapshot =
            await DatabaseSnapshotService(
              tempDirectoryCreator: _tempDirectoryCreator,
              snapshotDatabaseOpener: _snapshotDatabaseOpener,
            ).create(
              sourceDatabase: sourceDatabase,
              directoryPrefix: tempDirectoryPrefix,
            );
      } on SnapshotException catch (failure) {
        final stage = switch (failure.stage) {
          SnapshotFailureStage.creation => BackupFailureStage.snapshotCreation,
          SnapshotFailureStage.validation =>
            BackupFailureStage.snapshotValidation,
          SnapshotFailureStage.sourceRead => BackupFailureStage.sourceRead,
        };
        throw _BackupStageException(stage, failure.error, failure.stackTrace);
      }

      final snapshotBytes = await _runStage(
        BackupFailureStage.sourceRead,
        snapshot.file.readAsBytes,
      );
      final selectedDestination = await _runStage(
        BackupFailureStage.destinationWrite,
        () => destinationWriter.save(
          fileName: buildDefaultFileName(_clock?.call() ?? DateTime.now()),
          bytes: snapshotBytes,
          sourceFilePath: snapshot!.file.path,
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
      if (snapshot != null) {
        try {
          await snapshot.cleanup();
        } catch (error, stackTrace) {
          debugPrint('백업 snapshot 임시 파일 정리 실패: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
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
}

class _BackupStageException implements Exception {
  const _BackupStageException(this.stage, this.error, this.stackTrace);

  final BackupFailureStage stage;
  final Object error;
  final StackTrace stackTrace;
}
