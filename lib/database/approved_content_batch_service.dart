import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../data/models/approved_content_batch_models.dart';
import '../data/repositories/word_repository.dart';
import 'approved_content_sha256.dart';
import 'database_service.dart';
import 'database_snapshot_service.dart';

final class ApprovedContentValidationException implements Exception {
  const ApprovedContentValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class ApprovedContentExecutionException implements Exception {
  const ApprovedContentExecutionException(
    this.message, {
    this.reportPath,
    this.cause,
  });

  final String message;
  final String? reportPath;
  final Object? cause;

  @override
  String toString() {
    final reportSuffix = reportPath == null ? '' : ' (report: $reportPath)';
    return '$message$reportSuffix';
  }
}

final class ApprovedContentBatchManifest {
  const ApprovedContentBatchManifest._({
    required this.rawBytes,
    required this.sha256,
    required this.formatVersion,
    required this.batchId,
    required this.documentId,
    required this.documentSha256,
    required this.expectedWorkSha256,
    required this.expectedUserVersion,
    required this.supersedes,
    required this.meaningApprovals,
    required this.writeRequest,
  });

  final Uint8List rawBytes;
  final String sha256;
  final int formatVersion;
  final String batchId;
  final String documentId;
  final String documentSha256;
  final String expectedWorkSha256;
  final int expectedUserVersion;
  final List<ApprovedContentSupersession> supersedes;
  final List<ApprovedContentMeaningApproval> meaningApprovals;
  final ApprovedContentBatchWriteRequest writeRequest;

  static ApprovedContentBatchManifest parse(Uint8List rawBytes) {
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(rawBytes));
    } on FormatException catch (error) {
      throw ApprovedContentValidationException(
        'manifest JSON 파싱 실패: ${error.message}',
      );
    }

    final root = _requireObject(decoded, r'$');
    final formatVersion = _requireInt(
      root['format_version'],
      r'$.format_version',
    );
    if (formatVersion < 1 || formatVersion > 5) {
      throw ApprovedContentValidationException(
        'manifest format_version은 1, 2, 3, 4 또는 5여야 합니다: $formatVersion',
      );
    }
    final requiredRootKeys = <String>{
      'format_version',
      'batch_id',
      'provenance',
      'target',
      'meaning_replacements',
      'relation_creates',
      if (formatVersion >= 2) 'word_note_replacements',
      if (formatVersion >= 3) 'supersedes',
      if (formatVersion >= 4) 'relation_replacements',
      if (formatVersion >= 5) 'meaning_approvals',
    };
    _requireExactKeys(root, r'$', required: requiredRootKeys);

    final batchId = _requireNonEmptyString(root['batch_id'], r'$.batch_id');
    if (formatVersion >= 3 && !batchId.endsWith('-APPROVED-CONTENT-SLICE')) {
      throw ApprovedContentValidationException(
        r'v3~v5 $.batch_id가 approved batch identity가 아닙니다: '
        '$batchId',
      );
    }
    final provenance = _requireObject(root['provenance'], r'$.provenance');
    _requireExactKeys(
      provenance,
      r'$.provenance',
      required: const {'document_id', 'document_sha256'},
    );
    final documentId = _requireNonEmptyString(
      provenance['document_id'],
      r'$.provenance.document_id',
    );
    final documentSha256 = _requireSha256(
      provenance['document_sha256'],
      r'$.provenance.document_sha256',
    );

    final target = _requireObject(root['target'], r'$.target');
    _requireExactKeys(
      target,
      r'$.target',
      required: const {'expected_work_sha256', 'expected_user_version'},
    );
    final expectedWorkSha256 = _requireSha256(
      target['expected_work_sha256'],
      r'$.target.expected_work_sha256',
    );
    final expectedUserVersion = _requireInt(
      target['expected_user_version'],
      r'$.target.expected_user_version',
    );
    if (expectedUserVersion < 0) {
      throw const ApprovedContentValidationException(
        'expected_user_version은 0 이상이어야 합니다.',
      );
    }

    final meaningValues = _requireList(
      root['meaning_replacements'],
      r'$.meaning_replacements',
    );
    final meaningReplacements = <ApprovedContentMeaningReplacement>[];
    for (var index = 0; index < meaningValues.length; index++) {
      final path =
          r'$.meaning_replacements['
          '${index.toString()}]';
      final value = _requireObject(meaningValues[index], path);
      _requireExactKeys(
        value,
        path,
        required: const {'word_id', 'before', 'after'},
      );
      final wordId = _requireNonEmptyString(value['word_id'], '$path.word_id');
      meaningReplacements.add(
        ApprovedContentMeaningReplacement(
          wordId: wordId,
          before: _parseMeaningRows(value['before'], '$path.before'),
          after: _parseMeaningRows(value['after'], '$path.after'),
        ),
      );
    }

    final meaningApprovalValues = formatVersion >= 5
        ? _requireList(root['meaning_approvals'], r'$.meaning_approvals')
        : const <Object?>[];
    final meaningApprovals = <ApprovedContentMeaningApproval>[];
    for (var index = 0; index < meaningApprovalValues.length; index++) {
      final path =
          r'$.meaning_approvals['
          '${index.toString()}]';
      final value = _requireObject(meaningApprovalValues[index], path);
      _requireExactKeys(value, path, required: const {'word_id', 'meanings'});
      meaningApprovals.add(
        ApprovedContentMeaningApproval(
          wordId: _requireNonEmptyString(value['word_id'], '$path.word_id'),
          meanings: _parseMeaningRows(value['meanings'], '$path.meanings'),
        ),
      );
    }

    final supersessionValues = formatVersion >= 3
        ? _requireList(root['supersedes'], r'$.supersedes')
        : const <Object?>[];
    final supersedes = <ApprovedContentSupersession>[];
    final supersessionIdentities = <String>{};
    for (var index = 0; index < supersessionValues.length; index++) {
      final path =
          r'$.supersedes['
          '${index.toString()}]';
      final value = _requireObject(supersessionValues[index], path);
      _requireExactKeys(
        value,
        path,
        required: const {'strong_number', 'batch_id'},
      );
      final strongNumber = _requireNonEmptyString(
        value['strong_number'],
        '$path.strong_number',
      );
      if (!RegExp(r'^[GH][0-9]{4}$').hasMatch(strongNumber)) {
        throw ApprovedContentValidationException(
          '$path.strong_number가 canonical Strong이 아닙니다: $strongNumber',
        );
      }
      final supersededBatchId = _requireNonEmptyString(
        value['batch_id'],
        '$path.batch_id',
      );
      if (!supersededBatchId.endsWith('-APPROVED-CONTENT-SLICE')) {
        throw ApprovedContentValidationException(
          '$path.batch_id가 approved batch identity가 아닙니다: '
          '$supersededBatchId',
        );
      }
      if (supersededBatchId == batchId) {
        throw ApprovedContentValidationException(
          '$path가 현재 batch를 self-supersession 합니다: $batchId',
        );
      }
      final identity = '$strongNumber\u0000$supersededBatchId';
      if (!supersessionIdentities.add(identity)) {
        throw ApprovedContentValidationException(
          '동일 Strong/batch supersession이 중복됐습니다: '
          '$strongNumber, $supersededBatchId',
        );
      }
      if (!meaningReplacements.any(
            (replacement) => replacement.wordId.startsWith('${strongNumber}_'),
          ) &&
          !meaningApprovals.any(
            (approval) => approval.wordId.startsWith('${strongNumber}_'),
          )) {
        throw ApprovedContentValidationException(
          '$path의 Strong이 현재 meaning_replacements 또는 '
          'meaning_approvals에 없습니다: $strongNumber',
        );
      }
      supersedes.add(
        ApprovedContentSupersession(
          strongNumber: strongNumber,
          batchId: supersededBatchId,
        ),
      );
    }

    final wordNoteValues = formatVersion >= 2
        ? _requireList(
            root['word_note_replacements'],
            r'$.word_note_replacements',
          )
        : const <Object?>[];
    final wordNoteReplacements = <ApprovedContentWordNoteReplacement>[];
    for (var index = 0; index < wordNoteValues.length; index++) {
      final path =
          r'$.word_note_replacements['
          '${index.toString()}]';
      final value = _requireObject(wordNoteValues[index], path);
      _requireExactKeys(
        value,
        path,
        required: const {'word_id', 'before', 'after'},
      );
      wordNoteReplacements.add(
        ApprovedContentWordNoteReplacement(
          wordId: _requireNonEmptyString(value['word_id'], '$path.word_id'),
          before: _requireCanonicalWordNote(value['before'], '$path.before'),
          after: _requireCanonicalWordNote(value['after'], '$path.after'),
        ),
      );
    }

    final relationValues = _requireList(
      root['relation_creates'],
      r'$.relation_creates',
    );
    final relationCreates = <ApprovedContentRelationCreate>[];
    for (var index = 0; index < relationValues.length; index++) {
      final path =
          r'$.relation_creates['
          '${index.toString()}]';
      final value = _requireObject(relationValues[index], path);
      _requireExactKeys(
        value,
        path,
        required: const {
          'word_id_1',
          'word_id_2',
          'category_code',
          'relation_type',
          'status_code',
          'direction_code',
          'description',
          'relation_group_id',
          'note',
          'source',
        },
      );
      relationCreates.add(
        ApprovedContentRelationCreate(
          wordId1: _requireNonEmptyString(
            value['word_id_1'],
            '$path.word_id_1',
          ),
          wordId2: _requireNonEmptyString(
            value['word_id_2'],
            '$path.word_id_2',
          ),
          categoryCode: _requireNonEmptyString(
            value['category_code'],
            '$path.category_code',
          ),
          relationType: _requireNonEmptyString(
            value['relation_type'],
            '$path.relation_type',
          ),
          statusCode: _requireNonEmptyString(
            value['status_code'],
            '$path.status_code',
          ),
          directionCode: _requireNonEmptyString(
            value['direction_code'],
            '$path.direction_code',
          ),
          description: _requireNullableString(
            value['description'],
            '$path.description',
          ),
          relationGroupId: _requireNullableString(
            value['relation_group_id'],
            '$path.relation_group_id',
          ),
          note: _requireNullableString(value['note'], '$path.note'),
          source: _requireNonEmptyString(value['source'], '$path.source'),
        ),
      );
    }

    final relationReplacementValues = formatVersion >= 4
        ? _requireList(
            root['relation_replacements'],
            r'$.relation_replacements',
          )
        : const <Object?>[];
    final relationReplacements = <ApprovedContentRelationReplacement>[];
    for (var index = 0; index < relationReplacementValues.length; index++) {
      final path =
          r'$.relation_replacements['
          '${index.toString()}]';
      final value = _requireObject(relationReplacementValues[index], path);
      _requireExactKeys(
        value,
        path,
        required: const {
          'relation_id',
          'word_id_1',
          'word_id_2',
          'before',
          'after',
        },
      );
      relationReplacements.add(
        ApprovedContentRelationReplacement(
          relationId: _requireInt(value['relation_id'], '$path.relation_id'),
          wordId1: _requireNonEmptyString(
            value['word_id_1'],
            '$path.word_id_1',
          ),
          wordId2: _requireNonEmptyString(
            value['word_id_2'],
            '$path.word_id_2',
          ),
          before: _parseRelationProjection(value['before'], '$path.before'),
          after: _parseRelationProjection(value['after'], '$path.after'),
        ),
      );
    }

    final request = ApprovedContentBatchWriteRequest(
      batchId: batchId,
      meaningReplacements: List<ApprovedContentMeaningReplacement>.unmodifiable(
        meaningReplacements,
      ),
      wordNoteReplacements:
          List<ApprovedContentWordNoteReplacement>.unmodifiable(
            wordNoteReplacements,
          ),
      relationCreates: List<ApprovedContentRelationCreate>.unmodifiable(
        relationCreates,
      ),
      relationReplacements:
          List<ApprovedContentRelationReplacement>.unmodifiable(
            relationReplacements,
          ),
    );
    _validateManifestOperationShape(request, meaningApprovals);

    return ApprovedContentBatchManifest._(
      rawBytes: Uint8List.fromList(rawBytes),
      sha256: ApprovedContentSha256.bytes(rawBytes),
      formatVersion: formatVersion,
      batchId: batchId,
      documentId: documentId,
      documentSha256: documentSha256,
      expectedWorkSha256: expectedWorkSha256,
      expectedUserVersion: expectedUserVersion,
      supersedes: List<ApprovedContentSupersession>.unmodifiable(supersedes),
      meaningApprovals: List<ApprovedContentMeaningApproval>.unmodifiable(
        meaningApprovals,
      ),
      writeRequest: request,
    );
  }

  Map<String, Object?> toReportJson() => {
    'format_version': formatVersion,
    'batch_id': batchId,
    'manifest_sha256': sha256,
    'provenance': {
      'document_id': documentId,
      'document_sha256': documentSha256,
    },
    'target': {
      'expected_work_sha256': expectedWorkSha256,
      'expected_user_version': expectedUserVersion,
    },
    if (formatVersion >= 3)
      'supersedes': supersedes
          .map((item) => item.toJson())
          .toList(growable: false),
    'operation_counts': {
      'meaning_replacements': writeRequest.meaningReplacements.length,
      'word_note_replacements': writeRequest.wordNoteReplacements.length,
      'relation_creates': writeRequest.relationCreates.length,
      'relation_replacements': writeRequest.relationReplacements.length,
      'total': writeRequest.operationCount,
    },
    'approval_counts': {
      'meaning_approvals': meaningApprovals.length,
      'total': meaningApprovals.length,
    },
  };
}

final class ApprovedContentMeaningApproval {
  const ApprovedContentMeaningApproval({
    required this.wordId,
    required this.meanings,
  });

  final String wordId;
  final List<ApprovedContentMeaningRow> meanings;
}

final class ApprovedContentSupersession {
  const ApprovedContentSupersession({
    required this.strongNumber,
    required this.batchId,
  });

  final String strongNumber;
  final String batchId;

  Map<String, Object?> toJson() => {
    'strong_number': strongNumber,
    'batch_id': batchId,
  };
}

final class ApprovedContentDryRunResult {
  const ApprovedContentDryRunResult({
    required this.batchId,
    required this.manifestSha256,
    required this.databasePath,
    required this.databaseSha256Before,
    required this.databaseSha256After,
    required this.schemaVersion,
    required this.userVersion,
    required this.historyGroupId,
    required this.historyRowCount,
    required this.meaningApprovalCount,
    required this.meaningReplacementCount,
    required this.wordNoteReplacementCount,
    required this.relationCreateCount,
    required this.relationReplacementCount,
    required this.didUndo,
    required this.writeExecuted,
  });

  final String batchId;
  final String manifestSha256;
  final String databasePath;
  final String databaseSha256Before;
  final String databaseSha256After;
  final int schemaVersion;
  final int userVersion;
  final String? historyGroupId;
  final int historyRowCount;
  final int meaningApprovalCount;
  final int meaningReplacementCount;
  final int wordNoteReplacementCount;
  final int relationCreateCount;
  final int relationReplacementCount;
  final bool didUndo;
  final bool writeExecuted;

  Map<String, Object?> toJson() => {
    'mode': 'dry-run',
    'status': 'success',
    'batch_id': batchId,
    'manifest_sha256': manifestSha256,
    'database_path': databasePath,
    'database_sha256_before': databaseSha256Before,
    'database_sha256_after': databaseSha256After,
    'schema_version': schemaVersion,
    'user_version': userVersion,
    'history_group_id': historyGroupId,
    'history_row_count': historyRowCount,
    'meaning_approval_count': meaningApprovalCount,
    'meaning_replacement_count': meaningReplacementCount,
    'word_note_replacement_count': wordNoteReplacementCount,
    'relation_create_count': relationCreateCount,
    'relation_replacement_count': relationReplacementCount,
    'did_undo': didUndo,
    'write_executed': writeExecuted,
    'original_database_unchanged': databaseSha256Before == databaseSha256After,
  };
}

final class ApprovedContentApplyResult {
  const ApprovedContentApplyResult({
    required this.batchId,
    required this.manifestSha256,
    required this.historyGroupId,
    required this.historyRowCount,
    required this.createdRelations,
    required this.replacedRelations,
    required this.workSha256Before,
    required this.workSha256After,
    required this.seedSha256,
    required this.seedSize,
    required this.snapshotPath,
    required this.snapshotSha256,
    required this.manifestCopyPath,
    required this.reportPath,
    required this.summaryPath,
    required this.sourceSchemaVersion,
    required this.snapshotSchemaVersion,
  });

  final String batchId;
  final String manifestSha256;
  final String historyGroupId;
  final int historyRowCount;
  final List<ApprovedContentCreatedRelation> createdRelations;
  final List<ApprovedContentReplacedRelation> replacedRelations;
  final String workSha256Before;
  final String workSha256After;
  final String seedSha256;
  final int seedSize;
  final String snapshotPath;
  final String snapshotSha256;
  final String manifestCopyPath;
  final String reportPath;
  final String summaryPath;
  final int sourceSchemaVersion;
  final int snapshotSchemaVersion;
}

final class ApprovedContentBatchRunner {
  ApprovedContentBatchRunner({
    required Directory projectRoot,
    Directory? temporaryDirectoryParent,
    DateTime Function()? clock,
  }) : projectRoot = Directory(p.normalize(p.absolute(projectRoot.path))),
       temporaryDirectoryParent =
           temporaryDirectoryParent ?? Directory.systemTemp,
       _clock = clock ?? DateTime.now;

  final Directory projectRoot;
  final Directory temporaryDirectoryParent;
  final DateTime Function() _clock;

  File get canonicalWorkDatabase =>
      File(p.join(projectRoot.path, 'data', 'reshet_work.db'));
  File get canonicalSeedDatabase =>
      File(p.join(projectRoot.path, 'data', 'reshet_seed.db'));
  Directory get _backupRoot => Directory(
    p.join(projectRoot.path, 'data', 'backups', 'approved_content_batch'),
  );

  static Directory discoverProjectRoot(Directory start) {
    var current = Directory(p.normalize(p.absolute(start.path)));
    while (true) {
      final pubspec = File(p.join(current.path, 'pubspec.yaml'));
      final dataDirectory = Directory(p.join(current.path, 'data'));
      if (pubspec.existsSync() && dataDirectory.existsSync()) {
        final pubspecText = pubspec.readAsStringSync();
        if (RegExp(
          r'^name:\s*reshet_app\s*$',
          multiLine: true,
        ).hasMatch(pubspecText)) {
          return current;
        }
      }
      final parent = current.parent;
      if (p.equals(parent.path, current.path)) {
        throw const ApprovedContentValidationException(
          'Reshet 저장소 root를 찾을 수 없습니다.',
        );
      }
      current = parent;
    }
  }

  Future<ApprovedContentDryRunResult> dryRun({
    required File manifestFile,
    File? databaseFile,
  }) async {
    final manifest = await _readManifest(manifestFile);
    final source = File(
      p.normalize(p.absolute((databaseFile ?? canonicalWorkDatabase).path)),
    );
    final checked = await _preflightDatabase(
      manifest: manifest,
      databaseFile: source,
      verifyExpectedHash: true,
    );
    return _executeDryRun(manifest: manifest, checked: checked);
  }

  Future<ApprovedContentApplyResult> apply({
    required File manifestFile,
    File? requestedDatabaseFile,
  }) async {
    final workFile = canonicalWorkDatabase;
    final seedFile = canonicalSeedDatabase;
    await _validateLiveTarget(
      requestedDatabaseFile: requestedDatabaseFile,
      workFile: workFile,
      seedFile: seedFile,
    );

    final manifest = await _readManifest(manifestFile);
    if (manifest.writeRequest.operationCount == 0) {
      throw const ApprovedContentValidationException(
        'approval-only manifest는 DB write operation이 없으므로 '
        '--apply할 수 없습니다. dry-run으로 현행 meaning projection을 '
        '검증한 뒤 Git tracked manifest를 승인 authority로 사용해야 합니다.',
      );
    }
    final firstCheck = await _preflightDatabase(
      manifest: manifest,
      databaseFile: workFile,
      verifyExpectedHash: true,
    );
    await _executeDryRun(manifest: manifest, checked: firstCheck);

    final checked = await _preflightDatabase(
      manifest: manifest,
      databaseFile: workFile,
      verifyExpectedHash: true,
    );
    if (!seedFile.existsSync()) {
      throw ApprovedContentValidationException(
        'canonical seed DB가 존재하지 않습니다: ${seedFile.path}',
      );
    }
    await _assertNoSidecars(seedFile);
    final seedSizeBefore = await seedFile.length();
    final seedShaBefore = await ApprovedContentSha256.file(seedFile);

    await DatabaseService.closeDatabase();
    await DatabaseService.initialize();

    final backupDirectory = await _createBackupDirectory();
    DatabaseSnapshot? snapshot;
    Database? sourceDatabase;
    try {
      sourceDatabase = await databaseFactory.openDatabase(
        workFile.path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      final directoryPrefix = p.basename(backupDirectory.path);
      snapshot =
          await DatabaseSnapshotService(
            tempDirectoryCreator: (_) async => backupDirectory,
          ).create(
            sourceDatabase: sourceDatabase,
            directoryPrefix: directoryPrefix,
          );
    } finally {
      if (sourceDatabase != null && sourceDatabase.isOpen) {
        await sourceDatabase.close();
      }
    }

    final snapshotFile = snapshot.file;
    final snapshotCheck = await _preflightDatabase(
      manifest: manifest,
      databaseFile: snapshotFile,
      verifyExpectedHash: false,
    );
    final snapshotSha256 = await ApprovedContentSha256.file(snapshotFile);

    final workShaAfterSnapshot = await ApprovedContentSha256.file(workFile);
    if (workShaAfterSnapshot != manifest.expectedWorkSha256) {
      throw ApprovedContentExecutionException(
        'VACUUM INTO snapshot 생성 뒤 source work DB SHA가 변경됐습니다.',
      );
    }
    await _assertNoSidecars(workFile);

    final manifestCopy = File(p.join(backupDirectory.path, 'manifest.json'));
    await manifestCopy.writeAsBytes(manifest.rawBytes, flush: true);
    final manifestCopySha = await ApprovedContentSha256.file(manifestCopy);
    if (manifestCopySha != manifest.sha256) {
      throw const ApprovedContentExecutionException(
        'backup manifest exact copy SHA 검증에 실패했습니다.',
      );
    }
    await File(
      p.join(backupDirectory.path, 'manifest.sha256'),
    ).writeAsString('${manifest.sha256}  manifest.json\n', flush: true);

    final reportFile = File(p.join(backupDirectory.path, 'result.json'));
    final summaryFile = File(p.join(backupDirectory.path, 'summary.txt'));
    ApprovedContentBatchWriteResult? writeResult;
    var committed = false;
    Database? liveDatabase;
    try {
      final immediateWorkSha = await ApprovedContentSha256.file(workFile);
      if (immediateWorkSha != manifest.expectedWorkSha256) {
        throw const ApprovedContentValidationException(
          '적용 직전 work DB SHA가 manifest precondition과 달라졌습니다.',
        );
      }
      await _assertNoSidecars(workFile);

      liveDatabase = await databaseFactory.openDatabase(
        workFile.path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      final baseline = await _DatabaseBaseline.capture(
        liveDatabase,
        manifest.writeRequest,
      );
      writeResult = await WordRepository().applyApprovedContentBatch(
        manifest.writeRequest,
        database: liveDatabase,
      );
      committed = true;
      await _verifyAppliedBatch(
        database: liveDatabase,
        request: manifest.writeRequest,
        result: writeResult,
        baseline: baseline,
      );
      await _verifyIntegrityAndForeignKeys(liveDatabase);
    } catch (error) {
      if (liveDatabase != null && liveDatabase.isOpen) {
        await liveDatabase.close();
        liveDatabase = null;
      }
      final failureReport = <String, Object?>{
        'mode': 'apply',
        'status': committed ? 'post_commit_verification_failed' : 'failed',
        'manifest': manifest.toReportJson(),
        'error': error.toString(),
        'snapshot_path': snapshotFile.path,
        'snapshot_sha256': snapshotSha256,
        'work_sha256': await _tryHash(workFile),
        'seed_sha256': await _tryHash(seedFile),
        'history_group_id': writeResult?.groupId,
        'automatic_restore_performed': false,
      };
      await _writeJsonReport(reportFile, failureReport);
      await summaryFile.writeAsString(
        '승인 콘텐츠 batch 적용 실패\n'
        '상태: ${failureReport['status']}\n'
        '오류: $error\n'
        'snapshot: ${snapshotFile.path}\n'
        '자동 복원: 수행하지 않음\n',
        flush: true,
      );
      throw ApprovedContentExecutionException(
        committed
            ? 'commit 이후 검증에 실패했습니다. snapshot과 실패 상태를 보존했습니다.'
            : 'live apply transaction이 실패했습니다. snapshot과 실패 상태를 보존했습니다.',
        reportPath: reportFile.path,
        cause: error,
      );
    } finally {
      if (liveDatabase != null && liveDatabase.isOpen) {
        await liveDatabase.close();
      }
    }

    final seedSizeAfter = await seedFile.length();
    final seedShaAfter = await ApprovedContentSha256.file(seedFile);
    if (seedSizeAfter != seedSizeBefore || seedShaAfter != seedShaBefore) {
      final failureReport = <String, Object?>{
        'mode': 'apply',
        'status': 'post_commit_verification_failed',
        'manifest': manifest.toReportJson(),
        'error': 'seed DB size 또는 SHA가 변경됐습니다.',
        'snapshot_path': snapshotFile.path,
        'snapshot_sha256': snapshotSha256,
        'work_sha256': await _tryHash(workFile),
        'seed_size_before': seedSizeBefore,
        'seed_size_after': seedSizeAfter,
        'seed_sha256_before': seedShaBefore,
        'seed_sha256_after': seedShaAfter,
        'history_group_id': writeResult.groupId,
        'automatic_restore_performed': false,
      };
      await _writeJsonReport(reportFile, failureReport);
      throw ApprovedContentExecutionException(
        'commit 이후 seed DB 불변 검증에 실패했습니다.',
        reportPath: reportFile.path,
      );
    }

    await _assertNoSidecars(seedFile);
    await _assertNoSidecars(workFile);
    final workShaAfter = await ApprovedContentSha256.file(workFile);
    final successReport = <String, Object?>{
      'mode': 'apply',
      'status': 'success',
      'manifest': manifest.toReportJson(),
      'work_database': {
        'path': workFile.path,
        'sha256_before': checked.sha256,
        'sha256_after': workShaAfter,
        'schema_version_before': checked.schemaVersion,
        'user_version': checked.userVersion,
      },
      'seed_database': {
        'path': seedFile.path,
        'size': seedSizeAfter,
        'sha256_before': seedShaBefore,
        'sha256_after': seedShaAfter,
        'unchanged': true,
      },
      'snapshot': {
        'path': snapshotFile.path,
        'sha256': snapshotSha256,
        'source_schema_version': checked.schemaVersion,
        'snapshot_schema_version': snapshotCheck.schemaVersion,
        'schema_cookie_difference_is_expected':
            checked.schemaVersion != snapshotCheck.schemaVersion,
      },
      'manifest_copy_path': manifestCopy.path,
      'history_group_id': writeResult.groupId,
      'history_row_count': writeResult.historyRowCount,
      'exclusive_transaction': true,
      'created_relations': writeResult.createdRelations
          .map((relation) => relation.row)
          .toList(growable: false),
      'replaced_relations': writeResult.replacedRelations
          .map(
            (relation) => {
              'id': relation.id,
              'before': relation.before,
              'after': relation.after,
            },
          )
          .toList(growable: false),
      'automatic_restore_performed': false,
    };
    await _writeJsonReport(reportFile, successReport);
    await summaryFile.writeAsString(
      '승인 콘텐츠 batch 적용 성공\n'
      'batch_id: ${manifest.batchId}\n'
      'history group: ${writeResult.groupId}\n'
      'history rows: ${writeResult.historyRowCount}\n'
      'meaning replacements: ${manifest.writeRequest.meaningReplacements.length}\n'
      'word note replacements: ${manifest.writeRequest.wordNoteReplacements.length}\n'
      'relation creates: ${manifest.writeRequest.relationCreates.length}\n'
      'relation replacements: ${manifest.writeRequest.relationReplacements.length}\n'
      'snapshot: ${snapshotFile.path}\n'
      'work SHA before: ${checked.sha256}\n'
      'work SHA after: $workShaAfter\n'
      'seed SHA unchanged: $seedShaAfter\n',
      flush: true,
    );

    return ApprovedContentApplyResult(
      batchId: manifest.batchId,
      manifestSha256: manifest.sha256,
      historyGroupId: writeResult.groupId,
      historyRowCount: writeResult.historyRowCount,
      createdRelations: writeResult.createdRelations,
      replacedRelations: writeResult.replacedRelations,
      workSha256Before: checked.sha256,
      workSha256After: workShaAfter,
      seedSha256: seedShaAfter,
      seedSize: seedSizeAfter,
      snapshotPath: snapshotFile.path,
      snapshotSha256: snapshotSha256,
      manifestCopyPath: manifestCopy.path,
      reportPath: reportFile.path,
      summaryPath: summaryFile.path,
      sourceSchemaVersion: checked.schemaVersion,
      snapshotSchemaVersion: snapshotCheck.schemaVersion,
    );
  }

  Future<ApprovedContentBatchManifest> _readManifest(File file) async {
    if (!file.existsSync()) {
      throw ApprovedContentValidationException(
        'manifest 파일이 존재하지 않습니다: ${file.path}',
      );
    }
    try {
      return ApprovedContentBatchManifest.parse(await file.readAsBytes());
    } on ApprovedContentValidationException {
      rethrow;
    } catch (error) {
      throw ApprovedContentValidationException('manifest 읽기 실패: $error');
    }
  }

  Future<_CheckedDatabase> _preflightDatabase({
    required ApprovedContentBatchManifest manifest,
    required File databaseFile,
    required bool verifyExpectedHash,
  }) async {
    if (!databaseFile.existsSync()) {
      throw ApprovedContentValidationException(
        '대상 DB가 존재하지 않습니다: ${databaseFile.path}',
      );
    }
    await _assertNoSidecars(databaseFile);
    final shaBefore = await ApprovedContentSha256.file(databaseFile);
    if (verifyExpectedHash && shaBefore != manifest.expectedWorkSha256) {
      throw ApprovedContentValidationException(
        '대상 DB SHA가 manifest expected_work_sha256과 다릅니다: '
        '$shaBefore != ${manifest.expectedWorkSha256}',
      );
    }

    await DatabaseService.initialize();
    Database? database;
    late int schemaVersion;
    late int userVersion;
    ApprovedContentValidationException? validationError;
    try {
      database = await databaseFactory.openDatabase(
        databaseFile.path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );
      await const DatabaseRestoreSchemaValidator().validateRuntimeConnection(
        database,
      );
      await _verifyIntegrityAndForeignKeys(database);
      schemaVersion = await _readPragmaInt(database, 'schema_version');
      userVersion = await _readPragmaInt(database, 'user_version');
      if (userVersion != manifest.expectedUserVersion) {
        throw ApprovedContentValidationException(
          '대상 DB user_version이 manifest와 다릅니다: '
          '$userVersion != ${manifest.expectedUserVersion}',
        );
      }
      try {
        await _verifyMeaningApprovals(database, manifest.meaningApprovals);
        if (manifest.writeRequest.operationCount > 0) {
          await WordRepository().validateApprovedContentBatchPreconditions(
            request: manifest.writeRequest,
            database: database,
          );
        }
      } catch (error) {
        throw ApprovedContentValidationException(
          'DB precondition 검증 실패: $error',
        );
      }
    } on ApprovedContentValidationException catch (error) {
      validationError = error;
    } catch (error) {
      validationError = ApprovedContentValidationException(
        '대상 DB read-only 검증 실패: $error',
      );
    } finally {
      if (database != null && database.isOpen) {
        await database.close();
      }
    }

    await _assertNoSidecars(databaseFile);
    final shaAfter = await ApprovedContentSha256.file(databaseFile);
    if (shaAfter != shaBefore) {
      throw ApprovedContentExecutionException(
        'read-only preflight 전후 대상 DB SHA가 변경됐습니다: ${databaseFile.path}',
      );
    }
    if (validationError != null) {
      throw validationError;
    }
    return _CheckedDatabase(
      file: databaseFile,
      sha256: shaBefore,
      schemaVersion: schemaVersion,
      userVersion: userVersion,
    );
  }

  Future<ApprovedContentDryRunResult> _executeDryRun({
    required ApprovedContentBatchManifest manifest,
    required _CheckedDatabase checked,
  }) async {
    if (manifest.writeRequest.operationCount == 0) {
      await _assertNoSidecars(checked.file);
      final sourceShaAfter = await ApprovedContentSha256.file(checked.file);
      if (sourceShaAfter != checked.sha256) {
        throw ApprovedContentExecutionException(
          'approval-only dry-run 전후 원본 DB SHA가 변경됐습니다: '
          '${checked.file.path}',
        );
      }
      return ApprovedContentDryRunResult(
        batchId: manifest.batchId,
        manifestSha256: manifest.sha256,
        databasePath: checked.file.path,
        databaseSha256Before: checked.sha256,
        databaseSha256After: sourceShaAfter,
        schemaVersion: checked.schemaVersion,
        userVersion: checked.userVersion,
        historyGroupId: null,
        historyRowCount: 0,
        meaningApprovalCount: manifest.meaningApprovals.length,
        meaningReplacementCount: 0,
        wordNoteReplacementCount: 0,
        relationCreateCount: 0,
        relationReplacementCount: 0,
        didUndo: false,
        writeExecuted: false,
      );
    }

    const temporaryPrefix = 'reshet_approved_content_batch_';
    final temporaryDirectory = await temporaryDirectoryParent.createTemp(
      temporaryPrefix,
    );
    final dataDirectory = Directory(p.join(temporaryDirectory.path, 'data'));
    await dataDirectory.create(recursive: true);
    final temporaryWork = File(p.join(dataDirectory.path, 'reshet_work.db'));
    await checked.file.copy(temporaryWork.path);
    final copiedSha = await ApprovedContentSha256.file(temporaryWork);
    if (copiedSha != checked.sha256) {
      await _deleteOwnedTemporaryDirectory(
        temporaryDirectory,
        prefix: temporaryPrefix,
      );
      throw const ApprovedContentExecutionException(
        'dry-run 임시 DB exact copy SHA 검증에 실패했습니다.',
      );
    }

    ApprovedContentBatchWriteResult? writeResult;
    var didUndo = false;
    Object? executionError;
    try {
      await DatabaseService.closeDatabase();
      await DatabaseService.initialize();
      await DatabaseService.withIsolatedDataRoot(
        dataRootPath: dataDirectory.path,
        action: () async {
          final database = await DatabaseService.openDatabaseFile();
          final baseline = await _DatabaseBaseline.capture(
            database,
            manifest.writeRequest,
          );
          writeResult = await WordRepository().applyApprovedContentBatch(
            manifest.writeRequest,
          );
          await _verifyAppliedBatch(
            database: database,
            request: manifest.writeRequest,
            result: writeResult!,
            baseline: baseline,
          );
          await _verifyIntegrityAndForeignKeys(database);

          final undoResult = await WordRepository().undoLastChange();
          didUndo = undoResult.didUndo;
          if (!didUndo) {
            throw StateError('실제 undoLastChange()가 didUndo=false를 반환했습니다.');
          }
          await _verifyUndoneBatch(
            database: database,
            request: manifest.writeRequest,
            result: writeResult!,
            baseline: baseline,
          );
          await _verifyIntegrityAndForeignKeys(database);
        },
      );
    } catch (error) {
      executionError = error;
    } finally {
      await DatabaseService.closeDatabase();
      await _deleteOwnedTemporaryDirectory(
        temporaryDirectory,
        prefix: temporaryPrefix,
      );
    }

    await _assertNoSidecars(checked.file);
    final sourceShaAfter = await ApprovedContentSha256.file(checked.file);
    if (sourceShaAfter != checked.sha256) {
      throw ApprovedContentExecutionException(
        'dry-run 전후 원본 DB SHA가 변경됐습니다: ${checked.file.path}',
        cause: executionError,
      );
    }
    if (executionError != null) {
      throw ApprovedContentExecutionException(
        'dry-run 임시 적용 또는 실제 undo 검증에 실패했습니다: $executionError',
        cause: executionError,
      );
    }

    final completedWriteResult = writeResult!;
    return ApprovedContentDryRunResult(
      batchId: manifest.batchId,
      manifestSha256: manifest.sha256,
      databasePath: checked.file.path,
      databaseSha256Before: checked.sha256,
      databaseSha256After: sourceShaAfter,
      schemaVersion: checked.schemaVersion,
      userVersion: checked.userVersion,
      historyGroupId: completedWriteResult.groupId,
      historyRowCount: completedWriteResult.historyRowCount,
      meaningApprovalCount: manifest.meaningApprovals.length,
      meaningReplacementCount: manifest.writeRequest.meaningReplacements.length,
      wordNoteReplacementCount:
          manifest.writeRequest.wordNoteReplacements.length,
      relationCreateCount: manifest.writeRequest.relationCreates.length,
      relationReplacementCount:
          manifest.writeRequest.relationReplacements.length,
      didUndo: didUndo,
      writeExecuted: true,
    );
  }

  Future<void> _validateLiveTarget({
    required File? requestedDatabaseFile,
    required File workFile,
    required File seedFile,
  }) async {
    if (!workFile.existsSync()) {
      throw ApprovedContentValidationException(
        'canonical work DB가 존재하지 않습니다: ${workFile.path}',
      );
    }
    final work = await _resolvedPath(workFile);
    final seed = seedFile.existsSync() ? await _resolvedPath(seedFile) : null;
    if (seed != null && _sameResolvedPath(work, seed)) {
      throw const ApprovedContentValidationException(
        'canonical work DB와 seed DB가 같은 resolved path를 가리킵니다.',
      );
    }
    if (requestedDatabaseFile == null) return;

    if (!requestedDatabaseFile.existsSync()) {
      throw ApprovedContentValidationException(
        '요청한 live apply DB가 존재하지 않습니다: ${requestedDatabaseFile.path}',
      );
    }
    final requested = await _resolvedPath(requestedDatabaseFile);
    if (seed != null && _sameResolvedPath(requested, seed)) {
      throw const ApprovedContentValidationException(
        'seed DB에는 live apply할 수 없습니다.',
      );
    }
    if (!_sameResolvedPath(requested, work)) {
      throw const ApprovedContentValidationException(
        'live apply는 canonical data/reshet_work.db만 허용합니다.',
      );
    }
  }

  Future<Directory> _createBackupDirectory() async {
    await _backupRoot.create(recursive: true);
    final timestamp = _timestampForPath(_clock().toUtc());
    var candidate = Directory(p.join(_backupRoot.path, timestamp));
    var suffix = 1;
    while (candidate.existsSync()) {
      candidate = Directory(p.join(_backupRoot.path, '${timestamp}_$suffix'));
      suffix++;
    }
    await candidate.create();
    return candidate;
  }
}

final class _CheckedDatabase {
  const _CheckedDatabase({
    required this.file,
    required this.sha256,
    required this.schemaVersion,
    required this.userVersion,
  });

  final File file;
  final String sha256;
  final int schemaVersion;
  final int userVersion;
}

final class _DatabaseBaseline {
  const _DatabaseBaseline({
    required this.targetWordRows,
    required this.targetExpressionDigest,
    required this.noteOnlyTargetMeaningDigest,
    required this.nonTargetMeaningDigest,
    required this.relationDigest,
    required this.outsideRelationDigest,
    required this.historyDigest,
    required this.schemaDigest,
  });

  final List<Map<String, Object?>> targetWordRows;
  final String targetExpressionDigest;
  final String noteOnlyTargetMeaningDigest;
  final String nonTargetMeaningDigest;
  final String relationDigest;
  final String outsideRelationDigest;
  final String historyDigest;
  final String schemaDigest;

  static Future<_DatabaseBaseline> capture(
    DatabaseExecutor database,
    ApprovedContentBatchWriteRequest request,
  ) async {
    return _DatabaseBaseline(
      targetWordRows: List<Map<String, Object?>>.unmodifiable(
        (await _targetWordRows(
          database,
          request,
        )).map((row) => Map<String, Object?>.unmodifiable(row)),
      ),
      targetExpressionDigest: _digestRows(
        await _targetExpressionRows(database, request),
      ),
      noteOnlyTargetMeaningDigest: _digestRows(
        await _noteOnlyTargetMeaningRows(database, request),
      ),
      nonTargetMeaningDigest: _digestRows(
        await _nonTargetMeaningRows(database, request),
      ),
      relationDigest: _digestRows(await _relationRows(database)),
      outsideRelationDigest: _digestRows(
        await _relationRows(
          database,
          excludedIds: request.relationReplacements
              .map((replacement) => replacement.relationId)
              .toList(growable: false),
        ),
      ),
      historyDigest: _digestRows(await _historyRows(database)),
      schemaDigest: _digestRows(await _schemaRows(database)),
    );
  }
}

List<ApprovedContentMeaningRow> _parseMeaningRows(Object? raw, String path) {
  final values = _requireList(raw, path);
  final rows = <ApprovedContentMeaningRow>[];
  for (var index = 0; index < values.length; index++) {
    final rowPath = '$path[$index]';
    final value = _requireObject(values[index], rowPath);
    _requireExactKeys(value, rowPath, required: const {'seq', 'meaning'});
    rows.add(
      ApprovedContentMeaningRow(
        seq: _requireInt(value['seq'], '$rowPath.seq'),
        meaning: _requireString(value['meaning'], '$rowPath.meaning'),
      ),
    );
  }
  return List<ApprovedContentMeaningRow>.unmodifiable(rows);
}

ApprovedContentRelationProjection _parseRelationProjection(
  Object? raw,
  String path,
) {
  final value = _requireObject(raw, path);
  _requireExactKeys(
    value,
    path,
    required: const {
      'category_code',
      'relation_type',
      'status_code',
      'direction_code',
      'description',
      'relation_group_id',
      'note',
      'source',
    },
  );
  return ApprovedContentRelationProjection(
    categoryCode: _requireNonEmptyString(
      value['category_code'],
      '$path.category_code',
    ),
    relationType: _requireNonEmptyString(
      value['relation_type'],
      '$path.relation_type',
    ),
    statusCode: _requireNonEmptyString(
      value['status_code'],
      '$path.status_code',
    ),
    directionCode: _requireNonEmptyString(
      value['direction_code'],
      '$path.direction_code',
    ),
    description: _requireNullableString(
      value['description'],
      '$path.description',
    ),
    relationGroupId: _requireNullableString(
      value['relation_group_id'],
      '$path.relation_group_id',
    ),
    note: _requireNullableString(value['note'], '$path.note'),
    source: _requireNonEmptyString(value['source'], '$path.source'),
  );
}

void _validateManifestOperationShape(
  ApprovedContentBatchWriteRequest request,
  List<ApprovedContentMeaningApproval> meaningApprovals,
) {
  if (request.operationCount == 0 && meaningApprovals.isEmpty) {
    throw const ApprovedContentValidationException(
      'manifest write operation 또는 meaning approval이 최소 1개 필요합니다.',
    );
  }
  final meaningTargets = <String>{};
  for (final replacement in request.meaningReplacements) {
    if (!meaningTargets.add(replacement.wordId)) {
      throw ApprovedContentValidationException(
        '동일 word의 meaning replacement가 중복됐습니다: ${replacement.wordId}',
      );
    }
    _validateManifestMeaningRows(
      replacement.wordId,
      'before',
      replacement.before,
    );
    _validateManifestMeaningRows(
      replacement.wordId,
      'after',
      replacement.after,
    );
    if (_meaningRowsEqual(replacement.before, replacement.after)) {
      throw ApprovedContentValidationException(
        'meaning before와 after가 동일한 no-op입니다: ${replacement.wordId}',
      );
    }
  }

  final approvalTargets = <String>{};
  for (final approval in meaningApprovals) {
    if (!RegExp(r'^[GH][0-9]{4}_.+$').hasMatch(approval.wordId)) {
      throw ApprovedContentValidationException(
        'meaning approval word_id가 canonical Strong word ID가 아닙니다: '
        '${approval.wordId}',
      );
    }
    if (!approvalTargets.add(approval.wordId)) {
      throw ApprovedContentValidationException(
        '동일 word의 meaning approval이 중복됐습니다: ${approval.wordId}',
      );
    }
    if (meaningTargets.contains(approval.wordId)) {
      throw ApprovedContentValidationException(
        '동일 word를 meaning replacement와 approval에 동시에 지정했습니다: '
        '${approval.wordId}',
      );
    }
    if (approval.meanings.isEmpty) {
      throw ApprovedContentValidationException(
        'meaning approval projection은 최소 1행이어야 합니다: '
        '${approval.wordId}',
      );
    }
    _validateManifestMeaningRows(
      approval.wordId,
      'approval',
      approval.meanings,
    );
  }

  final wordNoteTargets = <String>{};
  for (final replacement in request.wordNoteReplacements) {
    if (!wordNoteTargets.add(replacement.wordId)) {
      throw ApprovedContentValidationException(
        '동일 word의 note replacement가 중복됐습니다: ${replacement.wordId}',
      );
    }
    if (replacement.before == replacement.after) {
      throw ApprovedContentValidationException(
        'note before와 after가 동일한 no-op입니다: ${replacement.wordId}',
      );
    }
  }

  final createPairs = <String>{};
  const supportedDirections = {'w1_to_w2', 'w2_to_w1', 'undirected', 'unknown'};
  for (final relation in request.relationCreates) {
    if (relation.wordId1.compareTo(relation.wordId2) >= 0) {
      throw ApprovedContentValidationException(
        'relation pair는 word_id_1 < word_id_2 canonical 순서여야 합니다: '
        '${relation.wordId1}, ${relation.wordId2}',
      );
    }
    if (!supportedDirections.contains(relation.directionCode)) {
      throw ApprovedContentValidationException(
        '정의되지 않은 direction_code입니다: ${relation.directionCode}',
      );
    }
    final key = '${relation.wordId1}\u0000${relation.wordId2}';
    if (!createPairs.add(key)) {
      throw ApprovedContentValidationException(
        '동일 unordered relation pair가 중복됐습니다: '
        '${relation.wordId1}, ${relation.wordId2}',
      );
    }
  }

  final replacementIds = <int>{};
  final replacementPairs = <String>{};
  for (final replacement in request.relationReplacements) {
    if (replacement.relationId <= 0) {
      throw ApprovedContentValidationException(
        'relation_id는 양수여야 합니다: ${replacement.relationId}',
      );
    }
    if (!replacementIds.add(replacement.relationId)) {
      throw ApprovedContentValidationException(
        '동일 relation_id replacement가 중복됐습니다: '
        '${replacement.relationId}',
      );
    }
    if (replacement.wordId1.compareTo(replacement.wordId2) >= 0) {
      throw ApprovedContentValidationException(
        'relation replacement pair는 word_id_1 < word_id_2 canonical '
        '순서여야 합니다: ${replacement.wordId1}, ${replacement.wordId2}',
      );
    }
    final key = '${replacement.wordId1}\u0000${replacement.wordId2}';
    if (!replacementPairs.add(key)) {
      throw ApprovedContentValidationException(
        '동일 unordered relation replacement pair가 중복됐습니다: '
        '${replacement.wordId1}, ${replacement.wordId2}',
      );
    }
    if (createPairs.contains(key)) {
      throw ApprovedContentValidationException(
        '같은 unordered pair를 create와 replacement에 동시에 지정했습니다: '
        '${replacement.wordId1}, ${replacement.wordId2}',
      );
    }
    _validateManifestRelationProjection(
      replacement.relationId,
      'before',
      replacement.before,
      supportedDirections,
    );
    _validateManifestRelationProjection(
      replacement.relationId,
      'after',
      replacement.after,
      supportedDirections,
    );
    if (replacement.before.hasSameValues(replacement.after)) {
      throw ApprovedContentValidationException(
        'relation before와 after가 동일한 no-op입니다: '
        '${replacement.relationId}',
      );
    }
  }
}

void _validateManifestRelationProjection(
  int relationId,
  String projectionName,
  ApprovedContentRelationProjection projection,
  Set<String> supportedDirections,
) {
  final codes = <String, String>{
    'category_code': projection.categoryCode,
    'relation_type': projection.relationType,
    'status_code': projection.statusCode,
  };
  for (final entry in codes.entries) {
    if (entry.value.trim() != entry.value) {
      throw ApprovedContentValidationException(
        'relation $relationId $projectionName ${entry.key}는 '
        'trim 없는 canonical 값이어야 합니다.',
      );
    }
  }
  if (!supportedDirections.contains(projection.directionCode)) {
    throw ApprovedContentValidationException(
      'relation $relationId $projectionName direction_code가 '
      '정의되지 않았습니다: ${projection.directionCode}',
    );
  }
}

void _validateManifestMeaningRows(
  String wordId,
  String projection,
  List<ApprovedContentMeaningRow> rows,
) {
  var previousSeq = 0;
  for (final row in rows) {
    if (row.seq < 1 || row.seq <= previousSeq) {
      throw ApprovedContentValidationException(
        '$wordId meaning $projection seq는 양수이며 엄격한 오름차순이어야 합니다: '
        '${row.seq}',
      );
    }
    if (row.meaning.isEmpty) {
      throw ApprovedContentValidationException(
        '$wordId meaning $projection 문자열은 비어 있을 수 없습니다.',
      );
    }
    previousSeq = row.seq;
  }
}

bool _meaningRowsEqual(
  List<ApprovedContentMeaningRow> left,
  List<ApprovedContentMeaningRow> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index].seq != right[index].seq ||
        left[index].meaning != right[index].meaning) {
      return false;
    }
  }
  return true;
}

Map<String, dynamic> _requireObject(Object? value, String path) {
  if (value is! Map) {
    throw ApprovedContentValidationException('$path 값은 JSON object여야 합니다.');
  }
  if (value.keys.any((key) => key is! String)) {
    throw ApprovedContentValidationException('$path object key는 문자열이어야 합니다.');
  }
  return Map<String, dynamic>.from(value);
}

List<Object?> _requireList(Object? value, String path) {
  if (value is! List) {
    throw ApprovedContentValidationException('$path 값은 JSON array여야 합니다.');
  }
  return List<Object?>.from(value);
}

String _requireString(Object? value, String path) {
  if (value is! String) {
    throw ApprovedContentValidationException('$path 값은 문자열이어야 합니다.');
  }
  return value;
}

String _requireNonEmptyString(Object? value, String path) {
  final result = _requireString(value, path);
  if (result.isEmpty) {
    throw ApprovedContentValidationException('$path 값은 비어 있을 수 없습니다.');
  }
  return result;
}

String? _requireNullableString(Object? value, String path) {
  if (value == null) return null;
  return _requireString(value, path);
}

String? _requireCanonicalWordNote(Object? value, String path) {
  if (value == null) return null;
  final result = _requireString(value, path);
  if (result.isEmpty || result.trim().isEmpty) {
    throw ApprovedContentValidationException(
      '$path 값은 빈 문자열 또는 공백 문자열일 수 없습니다. 비고 없음은 null이어야 합니다.',
    );
  }
  return result;
}

int _requireInt(Object? value, String path) {
  if (value is! int) {
    throw ApprovedContentValidationException('$path 값은 정수여야 합니다.');
  }
  return value;
}

String _requireSha256(Object? value, String path) {
  final result = _requireString(value, path);
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(result)) {
    throw ApprovedContentValidationException(
      '$path 값은 소문자 64자리 SHA-256이어야 합니다.',
    );
  }
  return result;
}

void _requireExactKeys(
  Map<String, dynamic> value,
  String path, {
  required Set<String> required,
}) {
  final missing = required.difference(value.keys.toSet()).toList()..sort();
  if (missing.isNotEmpty) {
    throw ApprovedContentValidationException(
      '$path 필수 필드가 없습니다: ${missing.join(', ')}',
    );
  }
  final unknown = value.keys.toSet().difference(required).toList()..sort();
  if (unknown.isNotEmpty) {
    throw ApprovedContentValidationException(
      '$path 알 수 없는 필드 또는 operation 종류입니다: ${unknown.join(', ')}',
    );
  }
}

Future<void> _verifyMeaningApprovals(
  DatabaseExecutor database,
  List<ApprovedContentMeaningApproval> approvals,
) async {
  for (final approval in approvals) {
    final wordRows = await database.query(
      'WORD_TABLE',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [approval.wordId],
      limit: 2,
    );
    if (wordRows.length != 1) {
      throw StateError(
        'meaning approval 대상 word를 exact 1건 확인할 수 없습니다: '
        '${approval.wordId}',
      );
    }
    final actual = await _meaningRowsForWord(database, approval.wordId);
    _requireMeaningProjection(
      actual,
      approval.meanings,
      label: '${approval.wordId} current approval',
    );
  }
}

Future<void> _verifyAppliedBatch({
  required DatabaseExecutor database,
  required ApprovedContentBatchWriteRequest request,
  required ApprovedContentBatchWriteResult result,
  required _DatabaseBaseline baseline,
}) async {
  for (final replacement in request.meaningReplacements) {
    final actual = await _meaningRowsForWord(database, replacement.wordId);
    _requireMeaningProjection(
      actual,
      replacement.after,
      label: '${replacement.wordId} apply after',
    );
  }
  for (final replacement in request.wordNoteReplacements) {
    final actual = await _wordNoteForWord(database, replacement.wordId);
    if (actual != replacement.after) {
      throw StateError(
        '${replacement.wordId} apply after note projection이 exact 일치하지 않습니다.',
      );
    }
  }

  if (result.createdRelations.length != request.relationCreates.length) {
    throw StateError('생성 relation 결과 수가 manifest와 다릅니다.');
  }
  final createdIds = <int>[];
  for (var index = 0; index < request.relationCreates.length; index++) {
    final requested = request.relationCreates[index];
    final created = result.createdRelations[index];
    createdIds.add(created.id);
    final rows = await database.query(
      'WORD_RELATION',
      where: 'id = ?',
      whereArgs: [created.id],
      limit: 1,
    );
    if (rows.length != 1) {
      throw StateError('생성 relation row를 exact 1건 확인할 수 없습니다: ${created.id}');
    }
    final row = Map<String, Object?>.from(rows.single);
    final expectedFields = requested.toDatabaseRow(
      updatedAt: row['updated_at']! as String,
    );
    for (final entry in expectedFields.entries) {
      if (row[entry.key] != entry.value) {
        throw StateError('생성 relation ${created.id}.${entry.key} 값이 다릅니다.');
      }
    }
    if (row['created_at'] is! String ||
        (row['created_at']! as String).isEmpty) {
      throw StateError('생성 relation ${created.id}.created_at이 유효하지 않습니다.');
    }
    if (_digestRows([row]) != _digestRows([created.row])) {
      throw StateError(
        'repository relation 결과 row가 DB exact row와 다릅니다: ${created.id}',
      );
    }
  }

  if (result.replacedRelations.length != request.relationReplacements.length) {
    throw StateError('교체 relation 결과 수가 manifest와 다릅니다.');
  }
  final replacementIds = <int>[];
  for (var index = 0; index < request.relationReplacements.length; index++) {
    final requested = request.relationReplacements[index];
    final replaced = result.replacedRelations[index];
    replacementIds.add(requested.relationId);
    if (replaced.id != requested.relationId) {
      throw StateError('교체 relation 결과 id가 manifest와 다릅니다.');
    }
    if (!requested.before.matchesDatabaseRow(replaced.before) ||
        !requested.after.matchesDatabaseRow(replaced.after)) {
      throw StateError(
        '교체 relation 결과 before/after가 manifest와 exact 일치하지 않습니다: '
        '${requested.relationId}',
      );
    }
    for (final key in ['id', 'word_id_1', 'word_id_2', 'created_at']) {
      if (replaced.before[key] != replaced.after[key]) {
        throw StateError(
          '교체 relation immutable 필드가 변경됐습니다: '
          '${requested.relationId}/$key',
        );
      }
    }
    if (replaced.after['id'] != requested.relationId ||
        replaced.after['word_id_1'] != requested.wordId1 ||
        replaced.after['word_id_2'] != requested.wordId2) {
      throw StateError(
        '교체 relation identity가 manifest와 exact 일치하지 않습니다: '
        '${requested.relationId}',
      );
    }
    final updatedAt = replaced.after['updated_at'];
    if (updatedAt is! String ||
        updatedAt.isEmpty ||
        updatedAt == replaced.before['updated_at']) {
      throw StateError(
        '교체 relation updated_at이 갱신되지 않았습니다: '
        '${requested.relationId}',
      );
    }
    final rows = await database.query(
      'WORD_RELATION',
      where: 'id = ?',
      whereArgs: [requested.relationId],
      limit: 2,
    );
    if (rows.length != 1 ||
        _digestRows(rows) != _digestRows([replaced.after])) {
      throw StateError(
        '교체 relation 결과가 DB exact row와 다릅니다: '
        '${requested.relationId}',
      );
    }
  }

  final historyRows = await database.query(
    'CHANGE_HISTORY',
    where: 'group_id = ?',
    whereArgs: [result.groupId],
    orderBy: 'id ASC',
  );
  if (historyRows.length != request.operationCount ||
      historyRows.length != result.historyRowCount) {
    throw StateError('batch history row 수가 operation 수와 다릅니다.');
  }
  for (final row in historyRows) {
    if (row['undone_at'] != null) {
      throw StateError('새 batch history가 active 상태가 아닙니다: ${row['id']}');
    }
  }
  await _verifyHistoryPayloads(
    request: request,
    result: result,
    historyRows: historyRows,
  );
  await _verifyOutsideState(
    database: database,
    request: request,
    baseline: baseline,
    excludedRelationIds: [...createdIds, ...replacementIds],
    excludedHistoryGroupId: result.groupId,
    wordNotesApplied: true,
  );
}

Future<void> _verifyUndoneBatch({
  required DatabaseExecutor database,
  required ApprovedContentBatchWriteRequest request,
  required ApprovedContentBatchWriteResult result,
  required _DatabaseBaseline baseline,
}) async {
  for (final replacement in request.meaningReplacements) {
    final actual = await _meaningRowsForWord(database, replacement.wordId);
    _requireMeaningProjection(
      actual,
      replacement.before,
      label: '${replacement.wordId} undo before',
    );
  }
  for (final replacement in request.wordNoteReplacements) {
    final actual = await _wordNoteForWord(database, replacement.wordId);
    if (actual != replacement.before) {
      throw StateError(
        '${replacement.wordId} undo before note projection이 exact 일치하지 않습니다.',
      );
    }
  }
  for (final relation in result.createdRelations) {
    final rows = await database.query(
      'WORD_RELATION',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [relation.id],
    );
    if (rows.isNotEmpty) {
      throw StateError('undo 뒤 생성 relation이 남아 있습니다: ${relation.id}');
    }
  }
  for (final replaced in result.replacedRelations) {
    final rows = await database.query(
      'WORD_RELATION',
      where: 'id = ?',
      whereArgs: [replaced.id],
      limit: 2,
    );
    if (rows.length != 1 ||
        _digestRows(rows) != _digestRows([replaced.before])) {
      throw StateError(
        'undo 뒤 교체 relation이 original full row로 exact 복원되지 않았습니다: '
        '${replaced.id}',
      );
    }
  }
  final historyRows = await database.query(
    'CHANGE_HISTORY',
    where: 'group_id = ?',
    whereArgs: [result.groupId],
  );
  if (historyRows.length != request.operationCount ||
      historyRows.any(
        (row) =>
            row['undone_at'] is! String ||
            (row['undone_at']! as String).isEmpty,
      )) {
    throw StateError('undo 뒤 batch history 전체가 inactive 상태가 아닙니다.');
  }
  await _verifyOutsideState(
    database: database,
    request: request,
    baseline: baseline,
    excludedHistoryGroupId: result.groupId,
    wordNotesApplied: false,
  );
  final relationDigest = _digestRows(await _relationRows(database));
  if (relationDigest != baseline.relationDigest) {
    throw StateError('undo 뒤 WORD_RELATION projection이 baseline과 다릅니다.');
  }
}

Future<void> _verifyHistoryPayloads({
  required ApprovedContentBatchWriteRequest request,
  required ApprovedContentBatchWriteResult result,
  required List<Map<String, Object?>> historyRows,
}) async {
  final wordRowsById = <String, List<Map<String, Object?>>>{};
  final relationRowsByEntity = <String, Map<String, Object?>>{};
  for (final row in historyRows) {
    final entityType = row['entity_type'];
    final entityId = row['entity_id']?.toString();
    if (entityType == 'word' && entityId != null) {
      wordRowsById.putIfAbsent(entityId, () => []).add(row);
    } else if (entityType == 'relation' && entityId != null) {
      relationRowsByEntity['relation:$entityId'] = row;
    }
  }
  final wordRowIndexes = <String, int>{};
  final consumedHistoryIds = <Object?>{};

  Map<String, Object?> takeWordRow(String wordId) {
    final rows = wordRowsById[wordId] ?? const <Map<String, Object?>>[];
    final index = wordRowIndexes[wordId] ?? 0;
    if (index >= rows.length) {
      throw StateError('word update history가 없습니다: $wordId');
    }
    final row = rows[index];
    wordRowIndexes[wordId] = index + 1;
    if (!consumedHistoryIds.add(row['id'])) {
      throw StateError('같은 history row가 중복 소비됐습니다: ${row['id']}');
    }
    return row;
  }

  for (final replacement in request.meaningReplacements) {
    final row = takeWordRow(replacement.wordId);
    if (row['action_type'] != 'update') {
      throw StateError('meaning word history action이 update가 아닙니다.');
    }
    final before = _decodeHistoryJson(row['before_json'], 'before_json');
    final after = _decodeHistoryJson(row['after_json'], 'after_json');
    final beforeMeanings = _meaningRowsFromHistory(before);
    final afterMeanings = _meaningRowsFromHistory(after);
    _requireMeaningProjection(
      beforeMeanings,
      replacement.before,
      label: '${replacement.wordId} history before',
    );
    _requireMeaningProjection(
      afterMeanings,
      replacement.after,
      label: '${replacement.wordId} history after',
    );
    final beforeWithoutMeanings = Map<String, dynamic>.from(before)
      ..remove('_normalized_meaning_rows');
    final afterWithoutMeanings = Map<String, dynamic>.from(after)
      ..remove('_normalized_meaning_rows');
    if (_canonicalJson(beforeWithoutMeanings) !=
        _canonicalJson(afterWithoutMeanings)) {
      throw StateError('meaning history에서 core/expression projection이 변경됐습니다.');
    }
  }

  for (final replacement in request.wordNoteReplacements) {
    final row = takeWordRow(replacement.wordId);
    if (row['action_type'] != 'update') {
      throw StateError('note word history action이 update가 아닙니다.');
    }
    final before = _decodeHistoryJson(row['before_json'], 'before_json');
    final after = _decodeHistoryJson(row['after_json'], 'after_json');
    if (before['비고'] != replacement.before ||
        after['비고'] != replacement.after) {
      throw StateError(
        'note history before/after가 승인 projection과 exact 일치하지 않습니다: '
        '${replacement.wordId}',
      );
    }
    final beforeWithoutNote = Map<String, dynamic>.from(before)..remove('비고');
    final afterWithoutNote = Map<String, dynamic>.from(after)..remove('비고');
    if (_canonicalJson(beforeWithoutNote) != _canonicalJson(afterWithoutNote)) {
      throw StateError('note history에서 승인되지 않은 word projection이 변경됐습니다.');
    }
  }

  for (var index = 0; index < request.relationCreates.length; index++) {
    final relation = request.relationCreates[index];
    final created = result.createdRelations[index];
    final row = relationRowsByEntity['relation:${created.id}'];
    if (row == null ||
        row['action_type'] != 'create' ||
        row['before_json'] != null) {
      throw StateError('relation create history가 유효하지 않습니다: ${created.id}');
    }
    if (!consumedHistoryIds.add(row['id'])) {
      throw StateError('같은 history row가 중복 소비됐습니다: ${row['id']}');
    }
    final after = _decodeHistoryJson(row['after_json'], 'after_json');
    final expected = Map<String, Object?>.from(
      relation.toDatabaseRow(updatedAt: created.row['updated_at']! as String),
    )..['id'] = created.id;
    if (_canonicalJson(after) != _canonicalJson(expected)) {
      throw StateError(
        'relation create history payload가 기존 canonical 형식과 다릅니다.',
      );
    }
  }
  for (var index = 0; index < request.relationReplacements.length; index++) {
    final requested = request.relationReplacements[index];
    final replaced = result.replacedRelations[index];
    final row = relationRowsByEntity['relation:${requested.relationId}'];
    if (row == null ||
        row['action_type'] != 'update' ||
        row['before_json'] == null ||
        row['after_json'] == null) {
      throw StateError(
        'relation update history가 유효하지 않습니다: '
        '${requested.relationId}',
      );
    }
    if (!consumedHistoryIds.add(row['id'])) {
      throw StateError('같은 history row가 중복 소비됐습니다: ${row['id']}');
    }
    final before = _decodeHistoryJson(row['before_json'], 'before_json');
    final after = _decodeHistoryJson(row['after_json'], 'after_json');
    if (_digestRows([before]) != _digestRows([replaced.before]) ||
        _digestRows([after]) != _digestRows([replaced.after]) ||
        !requested.before.matchesDatabaseRow(before) ||
        !requested.after.matchesDatabaseRow(after)) {
      throw StateError(
        'relation update history full before/after가 exact 일치하지 않습니다: '
        '${requested.relationId}',
      );
    }
  }
  if (consumedHistoryIds.length != historyRows.length) {
    throw StateError('batch history에 승인 operation과 대응하지 않는 행이 있습니다.');
  }
}

Map<String, dynamic> _decodeHistoryJson(Object? value, String label) {
  if (value is! String) {
    throw StateError('$label 값이 문자열 JSON이 아닙니다.');
  }
  final decoded = jsonDecode(value);
  if (decoded is! Map) {
    throw StateError('$label 값이 JSON object가 아닙니다.');
  }
  return Map<String, dynamic>.from(decoded);
}

List<Map<String, Object?>> _meaningRowsFromHistory(Map<String, dynamic> value) {
  final rawRows = value['_normalized_meaning_rows'];
  if (rawRows is! List) {
    throw StateError('history normalized meaning projection이 없습니다.');
  }
  return rawRows
      .map((row) => Map<String, Object?>.from(row as Map))
      .toList(growable: false);
}

void _requireMeaningProjection(
  List<Map<String, Object?>> actual,
  List<ApprovedContentMeaningRow> expected, {
  required String label,
}) {
  if (actual.length != expected.length) {
    throw StateError('$label meaning row 수가 다릅니다.');
  }
  for (var index = 0; index < actual.length; index++) {
    if (actual[index]['seq'] != expected[index].seq ||
        actual[index]['meaning'] != expected[index].meaning) {
      throw StateError('$label meaning projection이 exact 일치하지 않습니다.');
    }
  }
}

Future<void> _verifyOutsideState({
  required DatabaseExecutor database,
  required ApprovedContentBatchWriteRequest request,
  required _DatabaseBaseline baseline,
  required bool wordNotesApplied,
  List<int> excludedRelationIds = const [],
  String? excludedHistoryGroupId,
}) async {
  final expectedTargetWordRows = baseline.targetWordRows
      .map((row) => Map<String, Object?>.from(row))
      .toList(growable: false);
  if (wordNotesApplied) {
    final rowsById = <String, Map<String, Object?>>{
      for (final row in expectedTargetWordRows) row['id']!.toString(): row,
    };
    for (final replacement in request.wordNoteReplacements) {
      final row = rowsById[replacement.wordId];
      if (row == null) {
        throw StateError(
          'baseline target WORD_TABLE에 note 대상이 없습니다: '
          '${replacement.wordId}',
        );
      }
      row['비고'] = replacement.after;
    }
  }
  final outsideRelationIds = <int>{
    ...excludedRelationIds,
    ...request.relationReplacements.map(
      (replacement) => replacement.relationId,
    ),
  }.toList(growable: false);
  final checks = <String, ({String actual, String expected})>{
    'target WORD_TABLE': (
      actual: _digestRows(await _targetWordRows(database, request)),
      expected: _digestRows(expectedTargetWordRows),
    ),
    'target word_expression_set': (
      actual: _digestRows(await _targetExpressionRows(database, request)),
      expected: baseline.targetExpressionDigest,
    ),
    'note-only target word_meaning_set': (
      actual: _digestRows(await _noteOnlyTargetMeaningRows(database, request)),
      expected: baseline.noteOnlyTargetMeaningDigest,
    ),
    'non-target word_meaning_set': (
      actual: _digestRows(await _nonTargetMeaningRows(database, request)),
      expected: baseline.nonTargetMeaningDigest,
    ),
    'outside WORD_RELATION': (
      actual: _digestRows(
        await _relationRows(database, excludedIds: outsideRelationIds),
      ),
      expected: baseline.outsideRelationDigest,
    ),
    'pre-existing CHANGE_HISTORY': (
      actual: _digestRows(
        await _historyRows(database, excludedGroupId: excludedHistoryGroupId),
      ),
      expected: baseline.historyDigest,
    ),
    'sqlite schema': (
      actual: _digestRows(await _schemaRows(database)),
      expected: baseline.schemaDigest,
    ),
  };
  for (final entry in checks.entries) {
    if (entry.value.actual != entry.value.expected) {
      throw StateError('${entry.key} 값이 batch 대상 밖에서 변경됐습니다.');
    }
  }
}

Future<List<Map<String, Object?>>> _targetWordRows(
  DatabaseExecutor database,
  ApprovedContentBatchWriteRequest request,
) async {
  final wordIds = _allTargetWordIds(request);
  if (wordIds.isEmpty) return const [];
  return database.rawQuery(
    'SELECT * FROM WORD_TABLE WHERE id IN (${_placeholders(wordIds.length)}) '
    'ORDER BY id ASC',
    wordIds,
  );
}

Future<List<Map<String, Object?>>> _targetExpressionRows(
  DatabaseExecutor database,
  ApprovedContentBatchWriteRequest request,
) async {
  final wordIds = _allTargetWordIds(request);
  if (wordIds.isEmpty) return const [];
  return database.rawQuery(
    'SELECT word_id, seq, is_representative, spelling, transliteration, '
    'pronunciation, pronunciation_notation, pronunciation_notation_name '
    'FROM word_expression_set '
    'WHERE word_id IN (${_placeholders(wordIds.length)}) '
    'ORDER BY word_id ASC, seq ASC, id ASC',
    wordIds,
  );
}

Future<List<Map<String, Object?>>> _nonTargetMeaningRows(
  DatabaseExecutor database,
  ApprovedContentBatchWriteRequest request,
) async {
  final wordIds = <String>{
    ...request.meaningReplacements.map((item) => item.wordId),
    ...request.wordNoteReplacements.map((item) => item.wordId),
  }.toList()..sort();
  if (wordIds.isEmpty) {
    return database.rawQuery(
      'SELECT * FROM word_meaning_set ORDER BY word_id ASC, seq ASC, id ASC',
    );
  }
  return database.rawQuery(
    'SELECT * FROM word_meaning_set '
    'WHERE word_id NOT IN (${_placeholders(wordIds.length)}) '
    'ORDER BY word_id ASC, seq ASC, id ASC',
    wordIds,
  );
}

Future<List<Map<String, Object?>>> _noteOnlyTargetMeaningRows(
  DatabaseExecutor database,
  ApprovedContentBatchWriteRequest request,
) async {
  final meaningWordIds = request.meaningReplacements
      .map((item) => item.wordId)
      .toSet();
  final wordIds =
      request.wordNoteReplacements
          .map((item) => item.wordId)
          .where((wordId) => !meaningWordIds.contains(wordId))
          .toSet()
          .toList()
        ..sort();
  if (wordIds.isEmpty) return const [];
  return database.rawQuery(
    'SELECT word_id, seq, meaning FROM word_meaning_set '
    'WHERE word_id IN (${_placeholders(wordIds.length)}) '
    'ORDER BY word_id ASC, seq ASC, id ASC',
    wordIds,
  );
}

Future<List<Map<String, Object?>>> _meaningRowsForWord(
  DatabaseExecutor database,
  String wordId,
) {
  return database.query(
    'word_meaning_set',
    columns: ['word_id', 'seq', 'meaning'],
    where: 'word_id = ?',
    whereArgs: [wordId],
    orderBy: 'seq ASC, id ASC',
  );
}

Future<String?> _wordNoteForWord(
  DatabaseExecutor database,
  String wordId,
) async {
  final rows = await database.query(
    'WORD_TABLE',
    columns: ['비고'],
    where: 'id = ?',
    whereArgs: [wordId],
    limit: 2,
  );
  if (rows.length != 1) {
    throw StateError('note 대상 word를 exact 1건 읽을 수 없습니다: $wordId');
  }
  final value = rows.single['비고'];
  if (value == null || value is String) return value as String?;
  throw StateError('note 대상 WORD_TABLE.비고가 null/string이 아닙니다: $wordId');
}

Future<List<Map<String, Object?>>> _relationRows(
  DatabaseExecutor database, {
  List<int> excludedIds = const [],
}) {
  if (excludedIds.isEmpty) {
    return database.query('WORD_RELATION', orderBy: 'id ASC');
  }
  return database.rawQuery(
    'SELECT * FROM WORD_RELATION '
    'WHERE id NOT IN (${_placeholders(excludedIds.length)}) ORDER BY id ASC',
    excludedIds,
  );
}

Future<List<Map<String, Object?>>> _historyRows(
  DatabaseExecutor database, {
  String? excludedGroupId,
}) {
  if (excludedGroupId == null) {
    return database.query('CHANGE_HISTORY', orderBy: 'id ASC');
  }
  return database.query(
    'CHANGE_HISTORY',
    where: 'group_id <> ?',
    whereArgs: [excludedGroupId],
    orderBy: 'id ASC',
  );
}

Future<List<Map<String, Object?>>> _schemaRows(DatabaseExecutor database) {
  return database.rawQuery('''
    SELECT type, name, tbl_name, sql
    FROM sqlite_master
    WHERE name NOT LIKE 'sqlite_%'
    ORDER BY type ASC, name ASC
  ''');
}

List<Object> _allTargetWordIds(ApprovedContentBatchWriteRequest request) {
  final ids = <String>{
    ...request.meaningReplacements.map((item) => item.wordId),
    ...request.wordNoteReplacements.map((item) => item.wordId),
    ...request.relationCreates.expand((item) => [item.wordId1, item.wordId2]),
    ...request.relationReplacements.expand(
      (item) => [item.wordId1, item.wordId2],
    ),
  }.toList()..sort();
  return List<Object>.from(ids);
}

String _placeholders(int count) => List.filled(count, '?').join(', ');

String _digestRows(List<Map<String, Object?>> rows) {
  return ApprovedContentSha256.bytes(utf8.encode(_canonicalJson(rows)));
}

String _canonicalJson(Object? value) => jsonEncode(_canonicalize(value));

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  if (value is Iterable) {
    return value.map(_canonicalize).toList(growable: false);
  }
  return value;
}

Future<void> _verifyIntegrityAndForeignKeys(DatabaseExecutor database) async {
  final integrityRows = await database.rawQuery('PRAGMA integrity_check');
  if (integrityRows.length != 1 || integrityRows.single.values.single != 'ok') {
    throw StateError('PRAGMA integrity_check가 ok가 아닙니다: $integrityRows');
  }
  final foreignKeyRows = await database.rawQuery('PRAGMA foreign_key_check');
  if (foreignKeyRows.isNotEmpty) {
    throw StateError(
      'PRAGMA foreign_key_check 위반이 있습니다: ${foreignKeyRows.length}',
    );
  }
}

Future<int> _readPragmaInt(DatabaseExecutor database, String pragma) async {
  final rows = await database.rawQuery('PRAGMA $pragma');
  final value = rows.single.values.single;
  if (value is int) return value;
  throw StateError('PRAGMA $pragma 결과가 정수가 아닙니다: $value');
}

Future<void> _assertNoSidecars(File databaseFile) async {
  final sidecars = [
    File('${databaseFile.path}-wal'),
    File('${databaseFile.path}-shm'),
    File('${databaseFile.path}-journal'),
  ];
  final existing = <String>[];
  for (final sidecar in sidecars) {
    if (await sidecar.exists()) existing.add(sidecar.path);
  }
  if (existing.isNotEmpty) {
    throw ApprovedContentValidationException(
      'SQLite sidecar가 존재해 안전한 batch 실행을 거부합니다: ${existing.join(', ')}',
    );
  }
}

Future<void> _deleteOwnedTemporaryDirectory(
  Directory directory, {
  required String prefix,
}) async {
  final normalized = p.normalize(p.absolute(directory.path));
  if (!p.basename(normalized).startsWith(prefix)) {
    throw StateError('임시 디렉터리 ownership 검증에 실패했습니다: $normalized');
  }
  if (await directory.exists()) {
    await directory.delete(recursive: true);
  }
}

Future<String> _resolvedPath(File file) async {
  return p.normalize(await file.resolveSymbolicLinks());
}

bool _sameResolvedPath(String left, String right) {
  if (Platform.isWindows) {
    return left.toLowerCase() == right.toLowerCase();
  }
  return left == right;
}

String _timestampForPath(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  String three(int number) => number.toString().padLeft(3, '0');
  return '${value.year.toString().padLeft(4, '0')}'
      '${two(value.month)}${two(value.day)}T'
      '${two(value.hour)}${two(value.minute)}${two(value.second)}'
      '${three(value.millisecond)}${three(value.microsecond)}Z';
}

Future<String?> _tryHash(File file) async {
  try {
    if (!file.existsSync()) return null;
    return await ApprovedContentSha256.file(file);
  } catch (_) {
    return null;
  }
}

Future<void> _writeJsonReport(File file, Map<String, Object?> report) async {
  const encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString('${encoder.convert(report)}\n', flush: true);
}
