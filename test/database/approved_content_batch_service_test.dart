import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/approved_content_batch_service.dart';
import 'package:reshet_app/database/approved_content_sha256.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../tool/approved_content_batch.dart' as batch_cli;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory repoRoot;
  late File p1Snapshot;
  late File p1ManifestFile;
  late File liveWorkDatabase;
  late File liveSeedDatabase;
  late String liveWorkSha;
  late String liveSeedSha;
  late int liveSeedSize;
  Directory? caseDirectory;

  setUpAll(() async {
    repoRoot = Directory.current;
    p1Snapshot = File(
      p.join(
        repoRoot.path,
        'data',
        'backups',
        'reshet_ec_p1',
        '20260809T000258645',
        'reshet_work_pre_write.db',
      ),
    );
    p1ManifestFile = File(
      p.join(
        repoRoot.path,
        'test',
        'fixtures',
        'approved_content_batch',
        'p1_rehearsal_manifest.json',
      ),
    );
    liveWorkDatabase = File(p.join(repoRoot.path, 'data', 'reshet_work.db'));
    liveSeedDatabase = File(p.join(repoRoot.path, 'data', 'reshet_seed.db'));

    expect(p1Snapshot.existsSync(), isTrue);
    expect(p1ManifestFile.existsSync(), isTrue);
    expect(liveWorkDatabase.existsSync(), isTrue);
    expect(liveSeedDatabase.existsSync(), isTrue);
    expect(
      await ApprovedContentSha256.file(p1Snapshot),
      'cbc4d60b13b4489f3677122bda486aecafaecc47166a71d1a2cb4c901392599d',
    );
    liveWorkSha = await ApprovedContentSha256.file(liveWorkDatabase);
    liveSeedSha = await ApprovedContentSha256.file(liveSeedDatabase);
    liveSeedSize = await liveSeedDatabase.length();
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    caseDirectory = await Directory.systemTemp.createTemp(
      'reshet_approved_content_batch_test_',
    );
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    if (caseDirectory != null && caseDirectory!.existsSync()) {
      await caseDirectory!.delete(recursive: true);
    }
  });

  tearDownAll(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    expect(await ApprovedContentSha256.file(liveWorkDatabase), liveWorkSha);
    expect(await liveSeedDatabase.length(), liveSeedSize);
    expect(await ApprovedContentSha256.file(liveSeedDatabase), liveSeedSha);
  });

  group('manifest와 CLI 계약', () {
    test('SHA-256 known vector와 valid P1 manifest를 파싱한다', () async {
      expect(
        ApprovedContentSha256.bytes(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      final manifest = ApprovedContentBatchManifest.parse(
        await p1ManifestFile.readAsBytes(),
      );
      expect(manifest.batchId, 'RESHET-EC-P1-REHEARSAL-FIXTURE');
      expect(manifest.writeRequest.meaningReplacements, hasLength(3));
      expect(manifest.writeRequest.relationCreates, hasLength(3));
      expect(manifest.writeRequest.operationCount, 6);
    });

    test('invalid version, type, required field, unknown operation을 거부한다', () {
      final invalidVersion = _fixtureMap(p1ManifestFile)
        ..['format_version'] = 2;
      expect(
        () => _parseMap(invalidVersion),
        throwsA(isA<ApprovedContentValidationException>()),
      );

      final invalidType = _fixtureMap(p1ManifestFile)..['format_version'] = '1';
      expect(
        () => _parseMap(invalidType),
        throwsA(isA<ApprovedContentValidationException>()),
      );

      final missingField = _fixtureMap(p1ManifestFile)..remove('batch_id');
      expect(
        () => _parseMap(missingField),
        throwsA(isA<ApprovedContentValidationException>()),
      );

      final unknownOperation = _fixtureMap(p1ManifestFile)
        ..['relation_updates'] = <Object?>[];
      expect(
        () => _parseMap(unknownOperation),
        throwsA(isA<ApprovedContentValidationException>()),
      );
    });

    test('duplicate meaning target와 unordered relation pair를 거부한다', () {
      final duplicateMeaning = _fixtureMap(p1ManifestFile);
      final meaningRows = duplicateMeaning['meaning_replacements']! as List;
      meaningRows.add(_deepClone(meaningRows.first));
      expect(
        () => _parseMap(duplicateMeaning),
        throwsA(isA<ApprovedContentValidationException>()),
      );

      final duplicateRelation = _fixtureMap(p1ManifestFile);
      final relationRows = duplicateRelation['relation_creates']! as List;
      relationRows.add(_deepClone(relationRows.first));
      expect(
        () => _parseMap(duplicateRelation),
        throwsA(isA<ApprovedContentValidationException>()),
      );
    });

    test('--help와 apply 임의 DB 조합 거부를 제공한다', () async {
      final helpOutput = StringBuffer();
      final helpError = StringBuffer();
      expect(
        await batch_cli.runApprovedContentBatchCli(
          const ['--help'],
          output: helpOutput,
          errorOutput: helpError,
        ),
        0,
      );
      expect(helpOutput.toString(), contains('--manifest'));
      expect(helpOutput.toString(), contains('--apply'));

      final errorOutput = StringBuffer();
      expect(
        await batch_cli.runApprovedContentBatchCli(
          const [
            '--manifest',
            'manifest.json',
            '--database',
            'data/reshet_seed.db',
            '--apply',
          ],
          output: StringBuffer(),
          errorOutput: errorOutput,
        ),
        2,
      );
      expect(errorOutput.toString(), contains('함께 사용할 수 없습니다'));
    });
  });

  group('read-only precondition', () {
    test('SQLite sidecar가 있는 대상은 복제 전에 거부한다', () async {
      final copiedDatabase = await p1Snapshot.copy(
        p.join(caseDirectory!.path, 'sidecar_target.db'),
      );
      await File('${copiedDatabase.path}-wal').writeAsBytes(const [0]);
      final runner = ApprovedContentBatchRunner(projectRoot: repoRoot);

      await expectLater(
        runner.dryRun(
          manifestFile: p1ManifestFile,
          databaseFile: copiedDatabase,
        ),
        throwsA(
          isA<ApprovedContentValidationException>().having(
            (error) => error.message,
            'message',
            contains('sidecar'),
          ),
        ),
      );
    });

    test('expected SHA와 exact meaning before 불일치를 거부한다', () async {
      final runner = ApprovedContentBatchRunner(projectRoot: repoRoot);
      final shaMismatch = _fixtureMap(p1ManifestFile);
      (shaMismatch['target']! as Map<String, dynamic>)['expected_work_sha256'] =
          '0000000000000000000000000000000000000000000000000000000000000000';
      final shaManifest = await _writeManifest(
        caseDirectory!,
        'sha_mismatch.json',
        shaMismatch,
      );
      await expectLater(
        runner.dryRun(manifestFile: shaManifest, databaseFile: p1Snapshot),
        throwsA(
          isA<ApprovedContentValidationException>().having(
            (error) => error.message,
            'message',
            contains('expected_work_sha256'),
          ),
        ),
      );

      final beforeMismatch = _fixtureMap(p1ManifestFile);
      final meanings = beforeMismatch['meaning_replacements']! as List;
      final first = meanings.first as Map<String, dynamic>;
      final before = first['before']! as List;
      (before.first as Map<String, dynamic>)['meaning'] = 'exact mismatch';
      final beforeManifest = await _writeManifest(
        caseDirectory!,
        'before_mismatch.json',
        beforeMismatch,
      );
      await expectLater(
        runner.dryRun(manifestFile: beforeManifest, databaseFile: p1Snapshot),
        throwsA(
          isA<ApprovedContentValidationException>().having(
            (error) => error.message,
            'message',
            contains('before projection'),
          ),
        ),
      );
    });

    test('기존 pair, word 부재, lookup 부재를 거부한다', () async {
      final runner = ApprovedContentBatchRunner(projectRoot: repoRoot);
      final existingPair = _relationOnlyManifest(
        wordId1: 'H0001_0000',
        wordId2: 'H0002_0000',
        statusCode: 'inferred',
      );
      final existingPairFile = await _writeManifest(
        caseDirectory!,
        'existing_pair.json',
        existingPair,
      );
      await expectLater(
        runner.dryRun(manifestFile: existingPairFile, databaseFile: p1Snapshot),
        throwsA(
          isA<ApprovedContentValidationException>().having(
            (error) => error.message,
            'message',
            contains('이미 존재'),
          ),
        ),
      );

      final missingWord = _relationOnlyManifest(
        wordId1: 'H1652_0000',
        wordId2: 'H9999_9999',
        statusCode: 'asserted',
      );
      final missingWordFile = await _writeManifest(
        caseDirectory!,
        'missing_word.json',
        missingWord,
      );
      await expectLater(
        runner.dryRun(manifestFile: missingWordFile, databaseFile: p1Snapshot),
        throwsA(
          isA<ApprovedContentValidationException>().having(
            (error) => error.message,
            'message',
            contains('word가 존재하지 않습니다'),
          ),
        ),
      );

      final missingLookup = _relationOnlyManifest(
        wordId1: 'H1652_0000',
        wordId2: 'H1653_0000',
        statusCode: 'missing_status',
      );
      final missingLookupFile = await _writeManifest(
        caseDirectory!,
        'missing_lookup.json',
        missingLookup,
      );
      await expectLater(
        runner.dryRun(
          manifestFile: missingLookupFile,
          databaseFile: p1Snapshot,
        ),
        throwsA(
          isA<ApprovedContentValidationException>().having(
            (error) => error.message,
            'message',
            contains('status lookup'),
          ),
        ),
      );
    });

    test('seed와 비canonical DB live apply를 쓰기 전에 거부한다', () async {
      final runner = ApprovedContentBatchRunner(projectRoot: repoRoot);
      await expectLater(
        runner.apply(
          manifestFile: p1ManifestFile,
          requestedDatabaseFile: liveSeedDatabase,
        ),
        throwsA(
          isA<ApprovedContentValidationException>().having(
            (error) => error.message,
            'message',
            contains('seed DB'),
          ),
        ),
      );
      await expectLater(
        runner.apply(
          manifestFile: p1ManifestFile,
          requestedDatabaseFile: p1Snapshot,
        ),
        throwsA(
          isA<ApprovedContentValidationException>().having(
            (error) => error.message,
            'message',
            contains('canonical'),
          ),
        ),
      );
    });
  });

  group('transaction, undo, apply artifact', () {
    test('P1 snapshot에서 6 operation을 적용하고 실제 undo 1회로 복원한다', () async {
      final p1ShaBefore = await ApprovedContentSha256.file(p1Snapshot);
      final result = await ApprovedContentBatchRunner(
        projectRoot: repoRoot,
      ).dryRun(manifestFile: p1ManifestFile, databaseFile: p1Snapshot);

      expect(result.didUndo, isTrue);
      expect(result.historyRowCount, 6);
      expect(result.meaningReplacementCount, 3);
      expect(result.relationCreateCount, 3);
      expect(result.databaseSha256Before, p1ShaBefore);
      expect(result.databaseSha256After, p1ShaBefore);
      expect(await ApprovedContentSha256.file(p1Snapshot), p1ShaBefore);
      expect(await ApprovedContentSha256.file(liveWorkDatabase), liveWorkSha);
      expect(await ApprovedContentSha256.file(liveSeedDatabase), liveSeedSha);
    });

    test('late relation failure가 앞선 meaning과 history를 rollback한다', () async {
      final dataDirectory = Directory(p.join(caseDirectory!.path, 'data'));
      await dataDirectory.create();
      final copiedWork = await p1Snapshot.copy(
        p.join(dataDirectory.path, 'reshet_work.db'),
      );
      final manifest = ApprovedContentBatchManifest.parse(
        await p1ManifestFile.readAsBytes(),
      );

      await DatabaseService.withIsolatedDataRoot(
        dataRootPath: dataDirectory.path,
        action: () async {
          final database = await DatabaseService.openDatabaseFile();
          final beforeMeanings = await database.query(
            'word_meaning_set',
            columns: ['word_id', 'seq', 'meaning'],
            where: 'word_id = ?',
            whereArgs: ['H1653_0000'],
            orderBy: 'seq ASC, id ASC',
          );
          final historyCountBefore =
              (await database.rawQuery(
                    'SELECT COUNT(*) AS row_count FROM CHANGE_HISTORY',
                  )).single['row_count']!
                  as int;
          await database.execute('''
            CREATE TRIGGER test_approved_batch_abort_relation
            BEFORE INSERT ON WORD_RELATION
            WHEN NEW.source = 'RESHET-EC-P1-H1653-H1652'
            BEGIN
              SELECT RAISE(ABORT, 'test late relation failure');
            END
          ''');

          await expectLater(
            WordRepository().applyApprovedContentBatch(manifest.writeRequest),
            throwsA(anything),
          );
          final afterMeanings = await database.query(
            'word_meaning_set',
            columns: ['word_id', 'seq', 'meaning'],
            where: 'word_id = ?',
            whereArgs: ['H1653_0000'],
            orderBy: 'seq ASC, id ASC',
          );
          final historyCountAfter =
              (await database.rawQuery(
                    'SELECT COUNT(*) AS row_count FROM CHANGE_HISTORY',
                  )).single['row_count']!
                  as int;
          final createdRelations = await database.query(
            'WORD_RELATION',
            columns: ['id'],
            where: 'source LIKE ?',
            whereArgs: ['RESHET-EC-P1-%'],
          );
          expect(afterMeanings, beforeMeanings);
          expect(historyCountAfter, historyCountBefore);
          expect(createdRelations, isEmpty);
        },
      );
      expect(copiedWork.existsSync(), isTrue);
    });

    test(
      '임시 canonical root apply가 snapshot, manifest copy, report를 생성한다',
      () async {
        final isolatedRoot = Directory(
          p.join(caseDirectory!.path, 'apply_root'),
        );
        final dataDirectory = Directory(p.join(isolatedRoot.path, 'data'));
        await dataDirectory.create(recursive: true);
        final workFile = await p1Snapshot.copy(
          p.join(dataDirectory.path, 'reshet_work.db'),
        );
        final seedFile = await p1Snapshot.copy(
          p.join(dataDirectory.path, 'reshet_seed.db'),
        );
        final seedShaBefore = await ApprovedContentSha256.file(seedFile);
        final seedSizeBefore = await seedFile.length();

        final result = await ApprovedContentBatchRunner(
          projectRoot: isolatedRoot,
          temporaryDirectoryParent: caseDirectory,
          clock: () => DateTime.utc(2026, 8, 9, 12, 34, 56, 789, 123),
        ).apply(manifestFile: p1ManifestFile);

        expect(File(result.snapshotPath).existsSync(), isTrue);
        expect(File(result.manifestCopyPath).existsSync(), isTrue);
        expect(File(result.reportPath).existsSync(), isTrue);
        expect(File(result.summaryPath).existsSync(), isTrue);
        expect(
          await ApprovedContentSha256.file(File(result.manifestCopyPath)),
          result.manifestSha256,
        );
        expect(await seedFile.length(), seedSizeBefore);
        expect(await ApprovedContentSha256.file(seedFile), seedShaBefore);
        expect(result.historyRowCount, 6);
        expect(result.createdRelations, hasLength(3));
        expect(result.workSha256Before, isNot(result.workSha256After));

        final report =
            jsonDecode(await File(result.reportPath).readAsString())
                as Map<String, dynamic>;
        expect(report['status'], 'success');
        expect(report['history_group_id'], result.historyGroupId);
        expect(report['automatic_restore_performed'], isFalse);

        final database = await databaseFactory.openDatabase(
          workFile.path,
          options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
        );
        try {
          final meanings = await database.query(
            'word_meaning_set',
            columns: ['word_id', 'seq', 'meaning'],
            where: 'word_id IN (?, ?, ?)',
            whereArgs: ['H1653_0000', 'H1655_0000', 'H1656_0000'],
            orderBy: 'word_id ASC, seq ASC, id ASC',
          );
          expect(meanings.map((row) => row['meaning']).toList(), [
            '비',
            '소나기',
            '몸',
            '신체',
            '비',
          ]);
          final historyRows = await database.query(
            'CHANGE_HISTORY',
            where: 'group_id = ?',
            whereArgs: [result.historyGroupId],
          );
          expect(historyRows, hasLength(6));
          expect(historyRows.every((row) => row['undone_at'] == null), isTrue);
          final integrityRows = await database.rawQuery(
            'PRAGMA integrity_check',
          );
          expect(integrityRows.single.values.single, 'ok');
          expect(await database.rawQuery('PRAGMA foreign_key_check'), isEmpty);
        } finally {
          await database.close();
        }
      },
    );
  });
}

Map<String, dynamic> _fixtureMap(File file) {
  return Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map);
}

Object? _deepClone(Object? value) => jsonDecode(jsonEncode(value));

ApprovedContentBatchManifest _parseMap(Map<String, dynamic> value) {
  return ApprovedContentBatchManifest.parse(
    Uint8List.fromList(utf8.encode(jsonEncode(value))),
  );
}

Future<File> _writeManifest(
  Directory directory,
  String name,
  Map<String, dynamic> value,
) async {
  final file = File(p.join(directory.path, name));
  await file.writeAsString(jsonEncode(value), flush: true);
  return file;
}

Map<String, dynamic> _relationOnlyManifest({
  required String wordId1,
  required String wordId2,
  required String statusCode,
}) {
  return {
    'format_version': 1,
    'batch_id': 'RESHET-EC-TEST-RELATION',
    'provenance': {
      'document_id': 'test',
      'document_sha256':
          '1111111111111111111111111111111111111111111111111111111111111111',
    },
    'target': {
      'expected_work_sha256':
          'cbc4d60b13b4489f3677122bda486aecafaecc47166a71d1a2cb4c901392599d',
      'expected_user_version': 0,
    },
    'meaning_replacements': <Object?>[],
    'relation_creates': [
      {
        'word_id_1': wordId1,
        'word_id_2': wordId2,
        'category_code': 'etymological',
        'relation_type': 'root_shared',
        'status_code': statusCode,
        'direction_code': 'undirected',
        'description': null,
        'relation_group_id': null,
        'note': null,
        'source': 'RESHET-EC-TEST',
      },
    ],
  };
}
