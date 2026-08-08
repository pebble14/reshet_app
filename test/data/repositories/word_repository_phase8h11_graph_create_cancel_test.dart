import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/word/word_write_models.dart';

import '../../support/database_test_isolation_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String repoRootPath;
  late String sourceWorkDbPath;
  late String sourceSeedDbPath;
  Directory? isolatedRoot;

  setUpAll(() async {
    repoRootPath = Directory.current.path;
    sourceWorkDbPath = p.join(repoRootPath, 'data', 'reshet_work.db');
    sourceSeedDbPath = p.join(repoRootPath, 'data', 'reshet_seed.db');

    expect(
      File(sourceWorkDbPath).existsSync(),
      isTrue,
      reason: 'Phase 8-H-11 graph create cancel test needs the seed work DB.',
    );
    expect(File(sourceSeedDbPath).existsSync(), isTrue);

    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    isolatedRoot = await _createIsolatedWorkspace(sourceSeedDbPath);
    final isolatedDataRootPath = p.join(isolatedRoot!.path, 'data');
    ensureSystemTempDatabaseTargets(
      dataRootPath: isolatedDataRootPath,
      actualWorkDbPath: sourceWorkDbPath,
      actualSeedDbPath: sourceSeedDbPath,
    );
    DatabaseService.setDataRootOverrideForTest(isolatedDataRootPath);
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await isolatedRoot!.delete(recursive: true);
    }
  });

  group('Phase 8-H-11 graph create cancel UX guard', () {
    test(
      'discards the just-created graph word without writing delete history',
      () async {
        final repository = WordRepository();
        const wordId = 'T9000_H11_GRAPH_CREATE_CANCEL';

        await repository.createWord(id: wordId, payload: _payload('cancel-me'));

        expect(await _wordExists(wordId), isTrue);
        expect(await _wordExpressionRowCount(wordId), 1);
        expect(await _wordMeaningRowCount(wordId), 1);

        final didDiscard = await repository
            .discardCreatedWordForGraphCreateFlow(wordId);

        expect(didDiscard, isTrue);
        expect(await _wordExists(wordId), isFalse);
        expect(await _wordExpressionRowCount(wordId), 0);
        expect(await _wordMeaningRowCount(wordId), 0);
        expect(await repository.countRelationsForWord(wordId), 0);

        final historyRows = await _historyRowsForWord(wordId);
        expect(historyRows, hasLength(1));
        expect(historyRows.single['action_type'], 'create');
        expect(historyRows.single['undone_at'], isNotNull);
        expect(
          historyRows.where((row) => row['action_type'] == 'delete'),
          isEmpty,
        );
      },
    );

    test(
      'discards the latest active create after previous history reused the id',
      () async {
        final repository = WordRepository();
        const wordId = 'T9000_H11_GRAPH_CREATE_CANCEL_REUSED';

        await repository.createWord(id: wordId, payload: _payload('first-use'));
        await repository.deleteWord(wordId);
        final historyCountBeforeReuse = (await _historyRowsForWord(
          wordId,
        )).length;

        await repository.createWord(
          id: wordId,
          payload: _payload('second-use'),
        );

        expect(await _wordExists(wordId), isTrue);
        expect(await _wordExpressionRowCount(wordId), 1);

        final didDiscard = await repository
            .discardCreatedWordForGraphCreateFlow(wordId);

        expect(didDiscard, isTrue);
        expect(await _wordExists(wordId), isFalse);
        expect(await _wordExpressionRowCount(wordId), 0);

        final historyRows = await _historyRowsForWord(wordId);
        expect(historyRows, hasLength(historyCountBeforeReuse + 1));
        expect(historyRows.last['action_type'], 'create');
        expect(historyRows.last['undone_at'], isNotNull);
        expect(
          historyRows.where((row) => row['action_type'] == 'delete'),
          hasLength(1),
        );
      },
    );

    test(
      'does not discard when the created word already has a relation',
      () async {
        final repository = WordRepository();
        const centerWordId = 'T9000_H11_GRAPH_CREATE_CANCEL_CENTER';
        const createdWordId = 'T9000_H11_GRAPH_CREATE_CANCEL_RELATED';

        await repository.createWord(
          id: centerWordId,
          payload: _payload('center-word'),
        );
        await repository.createWord(
          id: createdWordId,
          payload: _payload('related-word'),
        );
        await repository.createRelation(
          wordId1: centerWordId,
          wordId2: createdWordId,
          categoryCode: null,
          relationType: null,
          statusCode: 'asserted',
          directionCode: 'unknown',
          note: null,
          source: null,
        );

        final didDiscard = await repository
            .discardCreatedWordForGraphCreateFlow(createdWordId);

        expect(didDiscard, isFalse);
        expect(await _wordExists(createdWordId), isTrue);
        expect(await repository.countRelationsForWord(createdWordId), 1);

        final historyRows = await _historyRowsForWord(createdWordId);
        expect(
          historyRows.where(
            (row) => row['action_type'] == 'create' && row['undone_at'] == null,
          ),
          hasLength(1),
        );
      },
    );

    test('does not discard a word without create history', () async {
      final repository = WordRepository();
      final db = await DatabaseService.openDatabaseFile();
      const wordId = 'T9000_H11_GRAPH_CREATE_CANCEL_NO_HISTORY';

      await db.insert('WORD_TABLE', {
        'id': wordId,
        '\uC5B8\uC5B4': 'test',
        '\uC2A4\uD2B8\uB871\uB118\uBC84': '',
      });

      final didDiscard = await repository.discardCreatedWordForGraphCreateFlow(
        wordId,
      );

      expect(didDiscard, isFalse);
      expect(await _wordExists(wordId), isTrue);
    });
  });
}

CanonicalWordWritePayload _payload(String spelling) {
  return CanonicalWordWritePayload(
    language: 'test',
    strongNumber: null,
    expressionSets: [
      CanonicalExpressionWriteSet(
        spelling: spelling,
        transliteration: 'translit-$spelling',
        pronunciation: null,
        seq: 1,
        isRepresentative: true,
      ),
    ],
    meanings: ['meaning-$spelling'],
    note: null,
  );
}

Future<Directory> _createIsolatedWorkspace(String sourceSeedDbPath) async {
  final isolatedRoot = await Directory.systemTemp.createTemp(
    'reshet_phase8h11_graph_create_cancel_tests_',
  );

  final dataDir = Directory(p.join(isolatedRoot.path, 'data'));
  await dataDir.create(recursive: true);

  await File(sourceSeedDbPath).copy(p.join(dataDir.path, 'reshet_seed.db'));
  await File(sourceSeedDbPath).copy(p.join(dataDir.path, 'reshet_work.db'));

  return isolatedRoot;
}

Future<bool> _wordExists(String wordId) async {
  final db = await DatabaseService.openDatabaseFile();
  final rows = await db.query(
    'WORD_TABLE',
    columns: ['id'],
    where: 'id = ?',
    whereArgs: [wordId],
    limit: 1,
  );
  return rows.isNotEmpty;
}

Future<int> _wordExpressionRowCount(String wordId) async {
  final db = await DatabaseService.openDatabaseFile();
  final rows = await db.rawQuery(
    '''
    SELECT COUNT(*) AS count
    FROM word_expression_set
    WHERE word_id = ?
    ''',
    [wordId],
  );
  return (rows.single['count'] as int?) ?? 0;
}

Future<int> _wordMeaningRowCount(String wordId) async {
  final db = await DatabaseService.openDatabaseFile();
  final rows = await db.rawQuery(
    '''
    SELECT COUNT(*) AS count
    FROM word_meaning_set
    WHERE word_id = ?
    ''',
    [wordId],
  );
  return (rows.single['count'] as int?) ?? 0;
}

Future<List<Map<String, Object?>>> _historyRowsForWord(String wordId) async {
  final db = await DatabaseService.openDatabaseFile();
  return await db.query(
    'CHANGE_HISTORY',
    where: 'entity_type = ? AND entity_id = ?',
    whereArgs: ['word', wordId],
    orderBy: 'id ASC',
  );
}
