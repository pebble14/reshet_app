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
    test('SHA-256 known vector와 기존 valid v1 manifest를 파싱한다', () async {
      expect(
        ApprovedContentSha256.bytes(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      final manifest = ApprovedContentBatchManifest.parse(
        await p1ManifestFile.readAsBytes(),
      );
      expect(manifest.formatVersion, 1);
      expect(manifest.batchId, 'RESHET-EC-P1-REHEARSAL-FIXTURE');
      expect(manifest.writeRequest.meaningReplacements, hasLength(3));
      expect(manifest.writeRequest.wordNoteReplacements, isEmpty);
      expect(manifest.writeRequest.relationCreates, hasLength(3));
      expect(manifest.writeRequest.operationCount, 6);
    });

    test('valid v2 word note manifest를 파싱한다', () {
      final manifest = _parseMap(
        _v2Manifest(
          wordNoteReplacements: [
            {'word_id': _noteSetWordId, 'before': null, 'after': '승인 비고'},
          ],
        ),
      );

      expect(manifest.formatVersion, 2);
      expect(manifest.writeRequest.meaningReplacements, isEmpty);
      expect(manifest.writeRequest.wordNoteReplacements, hasLength(1));
      expect(manifest.writeRequest.wordNoteReplacements.single.before, isNull);
      expect(manifest.writeRequest.wordNoteReplacements.single.after, '승인 비고');
      expect(manifest.writeRequest.operationCount, 1);
    });

    test('valid v3 Strong supersession metadata를 파싱한다', () {
      final manifest = _parseMap(
        _v3Manifest(
          batchId: 'RESHET-TEST-H5229-ACTIVE-APPROVED-CONTENT-SLICE',
          meaningReplacements: [
            {
              'word_id': 'H5229_0000',
              'before': [
                {'seq': 1, 'meaning': '올곧음'},
              ],
              'after': [
                {'seq': 1, 'meaning': '올바름'},
              ],
            },
          ],
          supersedes: const [
            {
              'strong_number': 'H5229',
              'batch_id':
                  'RESHET-EC-SECOND-SEMANTIC-BATCH-APPROVED-CONTENT-SLICE',
            },
          ],
        ),
      );

      expect(manifest.formatVersion, 3);
      expect(manifest.supersedes, hasLength(1));
      expect(manifest.supersedes.single.strongNumber, 'H5229');
      expect(
        manifest.supersedes.single.batchId,
        'RESHET-EC-SECOND-SEMANTIC-BATCH-APPROVED-CONTENT-SLICE',
      );
      expect(manifest.writeRequest.meaningReplacements, hasLength(1));
      expect(manifest.writeRequest.wordNoteReplacements, isEmpty);
      expect(manifest.writeRequest.operationCount, 1);
      expect(manifest.toReportJson()['supersedes'], const [
        {
          'strong_number': 'H5229',
          'batch_id': 'RESHET-EC-SECOND-SEMANTIC-BATCH-APPROVED-CONTENT-SLICE',
        },
      ]);
    });

    test('v3 self-supersession과 source Strong 부재를 거부한다', () {
      const activeBatchId = 'RESHET-TEST-H5229-ACTIVE-APPROVED-CONTENT-SLICE';
      final meaningReplacements = <Map<String, Object?>>[
        {
          'word_id': 'H5229_0000',
          'before': [
            {'seq': 1, 'meaning': '올곧음'},
          ],
          'after': [
            {'seq': 1, 'meaning': '올바름'},
          ],
        },
      ];
      final selfSupersession = _v3Manifest(
        batchId: activeBatchId,
        meaningReplacements: meaningReplacements,
        supersedes: const [
          {'strong_number': 'H5229', 'batch_id': activeBatchId},
        ],
      );
      expect(
        () => _parseMap(selfSupersession),
        throwsA(isA<ApprovedContentValidationException>()),
      );

      final missingSourceStrong = _v3Manifest(
        batchId: activeBatchId,
        meaningReplacements: meaningReplacements,
        supersedes: const [
          {
            'strong_number': 'H6772',
            'batch_id': 'RESHET-EC-P2-APPROVED-CONTENT-SLICE',
          },
        ],
      );
      expect(
        () => _parseMap(missingSourceStrong),
        throwsA(isA<ApprovedContentValidationException>()),
      );
    });

    test('invalid version, type, required field, unknown operation을 거부한다', () {
      final invalidVersion = _fixtureMap(p1ManifestFile)
        ..['format_version'] = 4;
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

    test('v2 note의 canonical·row·중복·unknown field 위반을 거부한다', () {
      Map<String, dynamic> withAfter(Object? value) => _v2Manifest(
        wordNoteReplacements: [
          {'word_id': _noteSetWordId, 'before': null, 'after': value},
        ],
      );

      for (final invalidValue in ['', '   ', 1]) {
        expect(
          () => _parseMap(withAfter(invalidValue)),
          throwsA(isA<ApprovedContentValidationException>()),
        );
      }

      final malformed = _v2Manifest(
        wordNoteReplacements: [
          {'word_id': _noteSetWordId, 'before': null},
        ],
      );
      expect(
        () => _parseMap(malformed),
        throwsA(isA<ApprovedContentValidationException>()),
      );

      final duplicate = _v2Manifest(
        wordNoteReplacements: [
          {'word_id': _noteSetWordId, 'before': null, 'after': '첫 값'},
          {'word_id': _noteSetWordId, 'before': null, 'after': '둘째 값'},
        ],
      );
      expect(
        () => _parseMap(duplicate),
        throwsA(isA<ApprovedContentValidationException>()),
      );

      final unknownRowField = withAfter('승인 비고');
      final rows = unknownRowField['word_note_replacements']! as List;
      (rows.single as Map<String, dynamic>)['memo'] = 'unknown';
      expect(
        () => _parseMap(unknownRowField),
        throwsA(isA<ApprovedContentValidationException>()),
      );

      final unknownRootField = withAfter('승인 비고')..['note_updates'] = [];
      expect(
        () => _parseMap(unknownRootField),
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

    test('note before 불일치와 존재하지 않는 word를 거부한다', () async {
      final fixture = await _createNoteFixture(caseDirectory!, p1Snapshot);
      final runner = ApprovedContentBatchRunner(projectRoot: repoRoot);

      final beforeMismatch = await _writeManifest(
        caseDirectory!,
        'note_before_mismatch.json',
        _v2Manifest(
          expectedWorkSha256: fixture.sha256,
          expectedUserVersion: fixture.userVersion,
          wordNoteReplacements: [
            {
              'word_id': _noteSetWordId,
              'before': 'DB와 다른 비고',
              'after': '승인 비고',
            },
          ],
        ),
      );
      await expectLater(
        runner.dryRun(
          manifestFile: beforeMismatch,
          databaseFile: fixture.database,
        ),
        throwsA(
          isA<ApprovedContentValidationException>().having(
            (error) => error.message,
            'message',
            contains('note before projection'),
          ),
        ),
      );

      final missingWord = await _writeManifest(
        caseDirectory!,
        'note_missing_word.json',
        _v2Manifest(
          expectedWorkSha256: fixture.sha256,
          expectedUserVersion: fixture.userVersion,
          wordNoteReplacements: [
            {
              'word_id': 'TEST_APPROVED_NOTE_MISSING',
              'before': null,
              'after': '승인 비고',
            },
          ],
        ),
      );
      await expectLater(
        runner.dryRun(
          manifestFile: missingWord,
          databaseFile: fixture.database,
        ),
        throwsA(
          isA<ApprovedContentValidationException>().having(
            (error) => error.message,
            'message',
            contains('note 대상 word가 존재하지 않습니다'),
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
    test('v2 note-only dry-run에서 note set·clear 후 원본을 byte 불변으로 둔다', () async {
      final fixture = await _createNoteFixture(caseDirectory!, p1Snapshot);
      final manifestFile = await _writeManifest(
        caseDirectory!,
        'note_only.json',
        _v2Manifest(
          expectedWorkSha256: fixture.sha256,
          expectedUserVersion: fixture.userVersion,
          wordNoteReplacements: [
            {'word_id': _noteSetWordId, 'before': null, 'after': '새 승인 비고'},
            {'word_id': _noteClearWordId, 'before': '삭제 전 비고', 'after': null},
          ],
        ),
      );

      final result = await ApprovedContentBatchRunner(
        projectRoot: repoRoot,
      ).dryRun(manifestFile: manifestFile, databaseFile: fixture.database);

      expect(result.didUndo, isTrue);
      expect(result.historyRowCount, 2);
      expect(result.meaningReplacementCount, 0);
      expect(result.wordNoteReplacementCount, 2);
      expect(result.relationCreateCount, 0);
      expect(result.databaseSha256Before, fixture.sha256);
      expect(result.databaseSha256After, fixture.sha256);
      expect(
        await ApprovedContentSha256.file(fixture.database),
        fixture.sha256,
      );

      final database = await databaseFactory.openDatabase(
        fixture.database.path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );
      try {
        final rows = await database.query(
          'WORD_TABLE',
          columns: ['id', '비고'],
          where: 'id IN (?, ?)',
          whereArgs: [_noteSetWordId, _noteClearWordId],
          orderBy: 'id ASC',
        );
        expect(rows, [
          {'id': _noteClearWordId, '비고': '삭제 전 비고'},
          {'id': _noteSetWordId, '비고': null},
        ]);
      } finally {
        await database.close();
      }
    });

    test('P1 snapshot에서 6 operation을 적용하고 실제 undo 1회로 복원한다', () async {
      final p1ShaBefore = await ApprovedContentSha256.file(p1Snapshot);
      final result = await ApprovedContentBatchRunner(
        projectRoot: repoRoot,
      ).dryRun(manifestFile: p1ManifestFile, databaseFile: p1Snapshot);

      expect(result.didUndo, isTrue);
      expect(result.historyRowCount, 6);
      expect(result.meaningReplacementCount, 3);
      expect(result.wordNoteReplacementCount, 0);
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

    test('같은 word의 meaning 뒤 note 실패가 전체 transaction을 rollback한다', () async {
      final dataDirectory = Directory(
        p.join(caseDirectory!.path, 'atomic_data'),
      );
      await dataDirectory.create();
      final fixture = await _createNoteFixture(
        dataDirectory,
        p1Snapshot,
        fileName: 'reshet_work.db',
      );
      final manifest = _parseMap(
        _v2Manifest(
          expectedWorkSha256: fixture.sha256,
          expectedUserVersion: fixture.userVersion,
          meaningReplacements: [
            {
              'word_id': _noteSetWordId,
              'before': [
                {'seq': 1, 'meaning': 'fixture meaning'},
              ],
              'after': [
                {'seq': 1, 'meaning': '승인 meaning'},
              ],
            },
          ],
          wordNoteReplacements: [
            {'word_id': _noteSetWordId, 'before': null, 'after': '승인 비고'},
          ],
        ),
      );

      await DatabaseService.withIsolatedDataRoot(
        dataRootPath: dataDirectory.path,
        action: () async {
          final database = await DatabaseService.openDatabaseFile();
          final historyCountBefore =
              (await database.rawQuery(
                    'SELECT COUNT(*) AS row_count FROM CHANGE_HISTORY',
                  )).single['row_count']
                  as int;
          await database.execute('''
            CREATE TRIGGER test_abort_approved_note
            BEFORE UPDATE OF "비고" ON WORD_TABLE
            WHEN NEW.id = '$_noteSetWordId'
            BEGIN
              SELECT RAISE(ABORT, 'test note failure');
            END
          ''');

          await expectLater(
            WordRepository().applyApprovedContentBatch(manifest.writeRequest),
            throwsA(anything),
          );
          final meaningRows = await database.query(
            'word_meaning_set',
            columns: ['seq', 'meaning'],
            where: 'word_id = ?',
            whereArgs: [_noteSetWordId],
            orderBy: 'seq ASC',
          );
          final wordRows = await database.query(
            'WORD_TABLE',
            columns: ['비고'],
            where: 'id = ?',
            whereArgs: [_noteSetWordId],
          );
          final historyCountAfter =
              (await database.rawQuery(
                    'SELECT COUNT(*) AS row_count FROM CHANGE_HISTORY',
                  )).single['row_count']
                  as int;
          expect(meaningRows, [
            {'seq': 1, 'meaning': 'fixture meaning'},
          ]);
          expect(wordRows.single['비고'], isNull);
          expect(historyCountAfter, historyCountBefore);
        },
      );
    });

    test('v2 meaning+note apply가 snapshot·history를 남기고 한 번에 undo된다', () async {
      final isolatedRoot = Directory(
        p.join(caseDirectory!.path, 'v2_apply_root'),
      );
      final dataDirectory = Directory(p.join(isolatedRoot.path, 'data'));
      await dataDirectory.create(recursive: true);
      final fixture = await _createNoteFixture(
        dataDirectory,
        p1Snapshot,
        fileName: 'reshet_work.db',
      );
      final seedFile = await fixture.database.copy(
        p.join(dataDirectory.path, 'reshet_seed.db'),
      );
      final seedShaBefore = await ApprovedContentSha256.file(seedFile);
      final seedSizeBefore = await seedFile.length();
      final manifestFile = await _writeManifest(
        caseDirectory!,
        'meaning_and_note.json',
        _v2Manifest(
          expectedWorkSha256: fixture.sha256,
          expectedUserVersion: fixture.userVersion,
          meaningReplacements: [
            {
              'word_id': _noteSetWordId,
              'before': [
                {'seq': 1, 'meaning': 'fixture meaning'},
              ],
              'after': [
                {'seq': 1, 'meaning': '승인 meaning'},
              ],
            },
          ],
          wordNoteReplacements: [
            {'word_id': _noteSetWordId, 'before': null, 'after': '승인 비고'},
          ],
        ),
      );

      final result = await ApprovedContentBatchRunner(
        projectRoot: isolatedRoot,
        temporaryDirectoryParent: caseDirectory,
        clock: () => DateTime.utc(2026, 8, 13, 12, 34, 56, 789, 123),
      ).apply(manifestFile: manifestFile);

      expect(result.historyRowCount, 2);
      expect(result.createdRelations, isEmpty);
      expect(File(result.snapshotPath).existsSync(), isTrue);
      expect(await seedFile.length(), seedSizeBefore);
      expect(await ApprovedContentSha256.file(seedFile), seedShaBefore);

      final snapshotDatabase = await databaseFactory.openDatabase(
        result.snapshotPath,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );
      try {
        final snapshotWord = await snapshotDatabase.query(
          'WORD_TABLE',
          columns: ['비고'],
          where: 'id = ?',
          whereArgs: [_noteSetWordId],
        );
        final snapshotMeanings = await snapshotDatabase.query(
          'word_meaning_set',
          columns: ['seq', 'meaning'],
          where: 'word_id = ?',
          whereArgs: [_noteSetWordId],
          orderBy: 'seq ASC',
        );
        expect(snapshotWord.single['비고'], isNull);
        expect(snapshotMeanings, [
          {'seq': 1, 'meaning': 'fixture meaning'},
        ]);
      } finally {
        await snapshotDatabase.close();
      }

      final appliedDatabase = await databaseFactory.openDatabase(
        fixture.database.path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );
      try {
        final word = await appliedDatabase.query(
          'WORD_TABLE',
          columns: ['비고'],
          where: 'id = ?',
          whereArgs: [_noteSetWordId],
        );
        final meanings = await appliedDatabase.query(
          'word_meaning_set',
          columns: ['seq', 'meaning'],
          where: 'word_id = ?',
          whereArgs: [_noteSetWordId],
          orderBy: 'seq ASC',
        );
        final historyRows = await appliedDatabase.query(
          'CHANGE_HISTORY',
          where: 'group_id = ?',
          whereArgs: [result.historyGroupId],
          orderBy: 'id ASC',
        );
        expect(word.single['비고'], '승인 비고');
        expect(meanings, [
          {'seq': 1, 'meaning': '승인 meaning'},
        ]);
        expect(historyRows, hasLength(2));
        expect(
          historyRows.every(
            (row) =>
                row['group_id'] == result.historyGroupId &&
                row['entity_type'] == 'word' &&
                row['entity_id'] == _noteSetWordId &&
                row['undone_at'] == null,
          ),
          isTrue,
        );

        final meaningBefore = _historyJson(historyRows[0], 'before_json');
        final meaningAfter = _historyJson(historyRows[0], 'after_json');
        final noteBefore = _historyJson(historyRows[1], 'before_json');
        final noteAfter = _historyJson(historyRows[1], 'after_json');
        expect(meaningBefore['비고'], isNull);
        expect(meaningAfter['비고'], isNull);
        expect(
          (meaningBefore['_normalized_meaning_rows'] as List).single,
          containsPair('meaning', 'fixture meaning'),
        );
        expect(
          (meaningAfter['_normalized_meaning_rows'] as List).single,
          containsPair('meaning', '승인 meaning'),
        );
        expect(noteBefore['비고'], isNull);
        expect(noteAfter['비고'], '승인 비고');
        expect(
          noteBefore['_normalized_meaning_rows'],
          noteAfter['_normalized_meaning_rows'],
        );
        expect(
          (noteBefore['_normalized_meaning_rows'] as List).single,
          containsPair('meaning', '승인 meaning'),
        );
      } finally {
        await appliedDatabase.close();
      }

      await DatabaseService.withIsolatedDataRoot(
        dataRootPath: dataDirectory.path,
        action: () async {
          final undo = await WordRepository().undoLastChange();
          expect(undo.didUndo, isTrue);
          final database = await DatabaseService.openDatabaseFile();
          final word = await database.query(
            'WORD_TABLE',
            columns: ['비고'],
            where: 'id = ?',
            whereArgs: [_noteSetWordId],
          );
          final meanings = await database.query(
            'word_meaning_set',
            columns: ['seq', 'meaning'],
            where: 'word_id = ?',
            whereArgs: [_noteSetWordId],
            orderBy: 'seq ASC',
          );
          final historyRows = await database.query(
            'CHANGE_HISTORY',
            where: 'group_id = ?',
            whereArgs: [result.historyGroupId],
          );
          expect(word.single['비고'], isNull);
          expect(meanings, [
            {'seq': 1, 'meaning': 'fixture meaning'},
          ]);
          expect(
            historyRows.every(
              (row) =>
                  row['undone_at'] is String &&
                  (row['undone_at']! as String).isNotEmpty,
            ),
            isTrue,
          );
        },
      );
    });

    test('승인값과 다른 note mutation을 verifier가 거부한다', () async {
      final fixture = await _createNoteFixture(caseDirectory!, p1Snapshot);
      final database = await databaseFactory.openDatabase(
        fixture.database.path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await database.execute('''
          CREATE TRIGGER test_mutate_approved_note
          AFTER UPDATE OF "비고" ON WORD_TABLE
          WHEN NEW.id = '$_noteSetWordId'
          BEGIN
            UPDATE WORD_TABLE SET "비고" = '비승인 변조' WHERE id = NEW.id;
          END
        ''');
      } finally {
        await database.close();
      }
      final shaWithTrigger = await ApprovedContentSha256.file(fixture.database);
      final manifestFile = await _writeManifest(
        caseDirectory!,
        'unexpected_note_mutation.json',
        _v2Manifest(
          expectedWorkSha256: shaWithTrigger,
          expectedUserVersion: fixture.userVersion,
          wordNoteReplacements: [
            {'word_id': _noteSetWordId, 'before': null, 'after': '승인 비고'},
          ],
        ),
      );

      await expectLater(
        ApprovedContentBatchRunner(
          projectRoot: repoRoot,
        ).dryRun(manifestFile: manifestFile, databaseFile: fixture.database),
        throwsA(
          isA<ApprovedContentExecutionException>().having(
            (error) => error.cause.toString(),
            'cause',
            contains('note projection'),
          ),
        ),
      );
      expect(
        await ApprovedContentSha256.file(fixture.database),
        shaWithTrigger,
      );
    });

    test('승인 note 외 word core mutation을 verifier가 거부한다', () async {
      final fixture = await _createNoteFixture(caseDirectory!, p1Snapshot);
      final database = await databaseFactory.openDatabase(
        fixture.database.path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await database.execute('''
          CREATE TRIGGER test_mutate_unapproved_word_core
          AFTER UPDATE OF "비고" ON WORD_TABLE
          WHEN NEW.id = '$_noteSetWordId'
          BEGIN
            UPDATE WORD_TABLE SET "언어" = '비승인 변조' WHERE id = NEW.id;
          END
        ''');
      } finally {
        await database.close();
      }
      final shaWithTrigger = await ApprovedContentSha256.file(fixture.database);
      final manifestFile = await _writeManifest(
        caseDirectory!,
        'unexpected_word_core_mutation.json',
        _v2Manifest(
          expectedWorkSha256: shaWithTrigger,
          expectedUserVersion: fixture.userVersion,
          wordNoteReplacements: [
            {'word_id': _noteSetWordId, 'before': null, 'after': '승인 비고'},
          ],
        ),
      );

      await expectLater(
        ApprovedContentBatchRunner(
          projectRoot: repoRoot,
        ).dryRun(manifestFile: manifestFile, databaseFile: fixture.database),
        throwsA(
          isA<ApprovedContentExecutionException>().having(
            (error) => error.cause.toString(),
            'cause',
            contains('target WORD_TABLE'),
          ),
        ),
      );
      expect(
        await ApprovedContentSha256.file(fixture.database),
        shaWithTrigger,
      );
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

const String _noteSetWordId = 'TEST_APPROVED_NOTE_SET';
const String _noteClearWordId = 'TEST_APPROVED_NOTE_CLEAR';

final class _NoteFixture {
  const _NoteFixture({
    required this.database,
    required this.sha256,
    required this.userVersion,
  });

  final File database;
  final String sha256;
  final int userVersion;
}

Future<_NoteFixture> _createNoteFixture(
  Directory directory,
  File source, {
  String fileName = 'approved_note_fixture.db',
}) async {
  await directory.create(recursive: true);
  final databaseFile = await source.copy(p.join(directory.path, fileName));
  final database = await databaseFactory.openDatabase(
    databaseFile.path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  late int userVersion;
  try {
    await database.transaction((txn) async {
      await txn.insert('WORD_TABLE', {
        'id': _noteSetWordId,
        '언어': '테스트 언어',
        '스트롱넘버': null,
        '비고': null,
        'graph_expand_mode': 'default',
      });
      await txn.insert('word_meaning_set', {
        'word_id': _noteSetWordId,
        'seq': 1,
        'meaning': 'fixture meaning',
      });
      await txn.insert('WORD_TABLE', {
        'id': _noteClearWordId,
        '언어': '테스트 언어',
        '스트롱넘버': null,
        '비고': '삭제 전 비고',
        'graph_expand_mode': 'default',
      });
      await txn.insert('word_meaning_set', {
        'word_id': _noteClearWordId,
        'seq': 1,
        'meaning': 'clear fixture meaning',
      });
    });
    userVersion =
        (await database.rawQuery('PRAGMA user_version')).single.values.single
            as int;
  } finally {
    await database.close();
  }
  return _NoteFixture(
    database: databaseFile,
    sha256: await ApprovedContentSha256.file(databaseFile),
    userVersion: userVersion,
  );
}

Map<String, dynamic> _v2Manifest({
  String expectedWorkSha256 =
      '0000000000000000000000000000000000000000000000000000000000000000',
  int expectedUserVersion = 0,
  List<Map<String, Object?>> meaningReplacements = const [],
  List<Map<String, Object?>> wordNoteReplacements = const [],
}) {
  return {
    'format_version': 2,
    'batch_id': 'RESHET-EC-TEST-WORD-NOTE',
    'provenance': {
      'document_id': 'test-word-note',
      'document_sha256':
          '1111111111111111111111111111111111111111111111111111111111111111',
    },
    'target': {
      'expected_work_sha256': expectedWorkSha256,
      'expected_user_version': expectedUserVersion,
    },
    'meaning_replacements': meaningReplacements,
    'word_note_replacements': wordNoteReplacements,
    'relation_creates': <Object?>[],
  };
}

Map<String, dynamic> _v3Manifest({
  required String batchId,
  required List<Map<String, Object?>> meaningReplacements,
  required List<Map<String, Object?>> supersedes,
  List<Map<String, Object?>> wordNoteReplacements = const [],
}) {
  return _v2Manifest(
      meaningReplacements: meaningReplacements,
      wordNoteReplacements: wordNoteReplacements,
    )
    ..['format_version'] = 3
    ..['batch_id'] = batchId
    ..['supersedes'] = supersedes;
}

Map<String, dynamic> _historyJson(Map<String, Object?> historyRow, String key) {
  return Map<String, dynamic>.from(
    jsonDecode(historyRow[key]! as String) as Map,
  );
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
