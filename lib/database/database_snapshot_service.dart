import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

enum DatabaseValidationFailure {
  notSqlite,
  integrityInvalid,
  schemaIncompatible,
  unsupportedBackup,
}

final class DatabaseValidationException implements Exception {
  const DatabaseValidationException(this.failure, this.message);

  final DatabaseValidationFailure failure;
  final String message;

  @override
  String toString() => 'DatabaseValidationException($failure, $message)';
}

enum SnapshotFailureStage { creation, validation, sourceRead }

final class SnapshotException implements Exception {
  const SnapshotException({
    required this.stage,
    required this.error,
    required this.stackTrace,
  });

  final SnapshotFailureStage stage;
  final Object error;
  final StackTrace stackTrace;
}

typedef SnapshotTempDirectoryCreator =
    Future<Directory> Function(String prefix);
typedef SnapshotDatabaseOpener = Future<Database> Function(String path);

final class DatabaseSnapshot {
  DatabaseSnapshot({
    required this.directory,
    required this.file,
    required this.directoryPrefix,
  });

  final Directory directory;
  final File file;
  final String directoryPrefix;

  Future<void> cleanup() async {
    final normalizedDirectory = p.normalize(p.absolute(directory.path));
    final normalizedFile = p.normalize(p.absolute(file.path));
    final ownsDirectory = p
        .basename(normalizedDirectory)
        .startsWith(directoryPrefix);
    final ownsFile = p.dirname(normalizedFile) == normalizedDirectory;
    if (!ownsDirectory || !ownsFile) {
      throw StateError('Snapshot cleanup ownership validation failed.');
    }

    if (await file.exists()) {
      await file.delete();
    }
    if (await directory.exists()) {
      await directory.delete();
    }
  }
}

class DatabaseRestoreSchemaValidator {
  const DatabaseRestoreSchemaValidator({SnapshotDatabaseOpener? databaseOpener})
    : _databaseOpener = databaseOpener;

  static const Set<String> requiredTables = {
    'WORD_TABLE',
    'WORD_RELATION',
    'word_expression_set',
    'word_meaning_set',
    'CHANGE_HISTORY',
    'RELATION_CATEGORY',
    'RELATION_TYPE',
    'RELATION_STATUS',
    'RMAC_TABLE',
    'RMAC_TABLE_KR',
  };

  static const Map<String, Set<String>> requiredColumns = {
    'WORD_TABLE': {'id', '언어', '스트롱넘버', '표기1', '의미1', '비고'},
    'WORD_RELATION': {
      'id',
      'word_id_1',
      'word_id_2',
      'category_code',
      'relation_type',
      'status_code',
      'direction_code',
      'description',
      'relation_group_id',
    },
    'word_expression_set': {
      'id',
      'word_id',
      'seq',
      'is_representative',
      'spelling',
      'transliteration',
      'pronunciation',
    },
    'word_meaning_set': {'id', 'word_id', 'seq', 'meaning'},
    'CHANGE_HISTORY': {
      'id',
      'group_id',
      'action_type',
      'entity_type',
      'entity_id',
      'before_json',
      'after_json',
      'created_at',
      'undone_at',
    },
    'RELATION_CATEGORY': {'code', 'label', 'description', 'sort_order'},
    'RELATION_TYPE': {
      'code',
      'category_code',
      'label',
      'description',
      'sort_order',
    },
    'RELATION_STATUS': {'code', 'label', 'description', 'sort_order'},
    'RMAC_TABLE': {
      'RMAC',
      'Part_of_Speech',
      'Tense',
      'Voice',
      'Mood',
      'Person',
      'Case',
      'Number',
      'Gender',
      'Degree',
      'Form',
    },
    'RMAC_TABLE_KR': {
      'RMAC',
      'Part_of_Speech',
      'Tense',
      'Voice',
      'Mood',
      'Person',
      'Case',
      'Number',
      'Gender',
      'Degree',
      'Form',
    },
  };

  static const Map<String, String> requiredPrimaryKeys = {
    'WORD_TABLE': 'id',
    'WORD_RELATION': 'id',
    'word_expression_set': 'id',
    'word_meaning_set': 'id',
    'CHANGE_HISTORY': 'id',
    'RELATION_CATEGORY': 'code',
    'RELATION_TYPE': 'code',
    'RELATION_STATUS': 'code',
    'RMAC_TABLE': 'RMAC',
    'RMAC_TABLE_KR': 'RMAC',
  };

  static const Map<String, Set<String>> requiredUniqueIndexes = {
    'WORD_RELATION': {'idx_word_relation_pair_type_direction_unique'},
    'word_expression_set': {
      'ux_word_expression_set_word_seq',
      'ux_word_expression_set_one_representative',
    },
    'word_meaning_set': {'ux_word_meaning_set_word_seq'},
  };

  final SnapshotDatabaseOpener? _databaseOpener;

  Future<void> validateFile(String path) async {
    Database? database;
    try {
      database =
          await (_databaseOpener?.call(path) ??
              databaseFactory.openDatabase(
                path,
                options: OpenDatabaseOptions(
                  readOnly: true,
                  singleInstance: false,
                ),
              ));
      await validateConnection(database);
    } on DatabaseValidationException {
      rethrow;
    } on DatabaseException catch (error) {
      throw DatabaseValidationException(
        DatabaseValidationFailure.notSqlite,
        error.toString(),
      );
    } finally {
      if (database != null && database.isOpen) {
        await database.close();
      }
    }
  }

  Future<void> validateConnection(Database database) async {
    List<Map<String, Object?>> integrityRows;
    try {
      integrityRows = await database.rawQuery('PRAGMA integrity_check');
    } on DatabaseException catch (error) {
      throw DatabaseValidationException(
        DatabaseValidationFailure.notSqlite,
        error.toString(),
      );
    }
    final integrityValue = integrityRows.length == 1
        ? integrityRows.single.values.single
        : null;
    if (integrityValue != 'ok') {
      throw const DatabaseValidationException(
        DatabaseValidationFailure.integrityInvalid,
        'SQLite integrity check failed.',
      );
    }

    final schemaRows = await database.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
    ''');
    final tableNames = schemaRows
        .map((row) => row['name'])
        .whereType<String>()
        .toSet();
    if (!tableNames.contains('WORD_TABLE') ||
        !tableNames.contains('WORD_RELATION')) {
      throw const DatabaseValidationException(
        DatabaseValidationFailure.unsupportedBackup,
        'Reshet core tables are missing.',
      );
    }
    if (!tableNames.containsAll(requiredTables)) {
      throw const DatabaseValidationException(
        DatabaseValidationFailure.schemaIncompatible,
        'Required backup tables are missing.',
      );
    }

    for (final entry in requiredColumns.entries) {
      final columns = await database.rawQuery(
        'PRAGMA table_info(${_quoteIdentifier(entry.key)})',
      );
      final columnNames = columns
          .map((row) => row['name'])
          .whereType<String>()
          .toSet();
      if (!columnNames.containsAll(entry.value)) {
        throw DatabaseValidationException(
          DatabaseValidationFailure.schemaIncompatible,
          'Required columns are missing from ${entry.key}.',
        );
      }

      final primaryKeyColumn = requiredPrimaryKeys[entry.key];
      if (primaryKeyColumn != null) {
        final hasPrimaryKey = columns.any(
          (row) => row['name'] == primaryKeyColumn && row['pk'] == 1,
        );
        if (!hasPrimaryKey) {
          throw DatabaseValidationException(
            DatabaseValidationFailure.schemaIncompatible,
            'Required primary key is missing from ${entry.key}.',
          );
        }
      }
    }

    for (final entry in requiredUniqueIndexes.entries) {
      final indexRows = await database.rawQuery(
        'PRAGMA index_list(${_quoteIdentifier(entry.key)})',
      );
      final uniqueIndexNames = indexRows
          .where((row) => row['unique'] == 1)
          .map((row) => row['name'])
          .whereType<String>()
          .toSet();
      if (!uniqueIndexNames.containsAll(entry.value)) {
        throw DatabaseValidationException(
          DatabaseValidationFailure.schemaIncompatible,
          'Required unique indexes are missing from ${entry.key}.',
        );
      }
    }

    await database.rawQuery('SELECT COUNT(*) AS row_count FROM WORD_TABLE');
  }

  static String _quoteIdentifier(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }
}

class DatabaseSnapshotService {
  const DatabaseSnapshotService({
    SnapshotTempDirectoryCreator? tempDirectoryCreator,
    SnapshotDatabaseOpener? snapshotDatabaseOpener,
    this.validator = const DatabaseRestoreSchemaValidator(),
  }) : _tempDirectoryCreator = tempDirectoryCreator,
       _snapshotDatabaseOpener = snapshotDatabaseOpener;

  static const String defaultDirectoryPrefix = 'reshet_db_snapshot_';
  static const String snapshotFileName = 'snapshot.db';

  final SnapshotTempDirectoryCreator? _tempDirectoryCreator;
  final SnapshotDatabaseOpener? _snapshotDatabaseOpener;
  final DatabaseRestoreSchemaValidator validator;

  Future<DatabaseSnapshot> create({
    required Database sourceDatabase,
    String directoryPrefix = defaultDirectoryPrefix,
  }) async {
    Directory? directory;
    File? snapshotFile;
    try {
      try {
        directory =
            await (_tempDirectoryCreator?.call(directoryPrefix) ??
                Directory.systemTemp.createTemp(directoryPrefix));
        snapshotFile = File(p.join(directory.path, snapshotFileName));
        if (await snapshotFile.exists()) {
          throw StateError('Snapshot output path already exists.');
        }
        await sourceDatabase.execute('VACUUM INTO ?', [snapshotFile.path]);
      } catch (error, stackTrace) {
        throw SnapshotException(
          stage: SnapshotFailureStage.creation,
          error: error,
          stackTrace: stackTrace,
        );
      }

      try {
        final validationService = _snapshotDatabaseOpener == null
            ? validator
            : DatabaseRestoreSchemaValidator(
                databaseOpener: _snapshotDatabaseOpener,
              );
        await validationService.validateFile(snapshotFile.path);
      } catch (error, stackTrace) {
        throw SnapshotException(
          stage: SnapshotFailureStage.validation,
          error: error,
          stackTrace: stackTrace,
        );
      }

      try {
        await sourceDatabase.rawQuery('SELECT 1');
      } catch (error, stackTrace) {
        throw SnapshotException(
          stage: SnapshotFailureStage.sourceRead,
          error: error,
          stackTrace: stackTrace,
        );
      }

      return DatabaseSnapshot(
        directory: directory,
        file: snapshotFile,
        directoryPrefix: directoryPrefix,
      );
    } catch (_) {
      if (directory != null && snapshotFile != null) {
        try {
          await DatabaseSnapshot(
            directory: directory,
            file: snapshotFile,
            directoryPrefix: directoryPrefix,
          ).cleanup();
        } catch (error, stackTrace) {
          debugPrint('snapshot 실패 후 임시 파일 정리 실패: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
      rethrow;
    }
  }
}
