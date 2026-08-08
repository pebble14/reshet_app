import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/models/relation_status_lookup.dart';
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';

import '../../support/database_test_isolation_guard.dart';

const _wordIdA = 'T_STATUS_A';
const _wordIdB = 'T_STATUS_B';
const _wordIdC = 'T_STATUS_C';
const _wordIdD = 'T_STATUS_D';
const _wordIdE = 'T_STATUS_E';
const _wordIdF = 'T_STATUS_F';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String sourceWorkDbPath;
  late String sourceSeedDbPath;
  Directory? isolatedRoot;

  setUpAll(() async {
    final repoRootPath = Directory.current.path;
    sourceWorkDbPath = p.join(repoRootPath, 'data', 'reshet_work.db');
    sourceSeedDbPath = p.join(repoRootPath, 'data', 'reshet_seed.db');

    expect(File(sourceWorkDbPath).existsSync(), isTrue);
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

    final db = await DatabaseService.openDatabaseFile();
    for (final wordId in const [
      _wordIdA,
      _wordIdB,
      _wordIdC,
      _wordIdD,
      _wordIdE,
      _wordIdF,
    ]) {
      await _insertWord(db, wordId);
    }
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await isolatedRoot!.delete(recursive: true);
    }
  });

  group('관계 상태 repository 계약', () {
    test('lookup을 정렬된 typed 값으로 반환하고 edge 표시 정보를 보존한다', () async {
      final repository = WordRepository();
      final statuses = await repository.getRelationStatuses();

      expect(statuses.map((status) => status.code), const [
        'asserted',
        'hypothesized',
        'disputed',
        'uncertain',
        'rejected',
        'unknown',
        'inferred',
      ]);
      expect(statuses.map((status) => status.sortOrder), [1, 2, 3, 4, 5, 6, 7]);
      expect(statuses.last.displayLabel, '기존 데이터 기반');
      expect(
        RelationStatusLookup.fromMap(const {
          'code': 'fallback-code',
          'label': '   ',
          'sort_order': 9,
        }).displayLabel,
        'fallback-code',
      );

      final db = await DatabaseService.openDatabaseFile();
      final relationId = await _insertRelation(
        db,
        wordId1: _wordIdA,
        wordId2: _wordIdB,
        statusCode: 'inferred',
      );

      final centerEdges = await repository.getRelationEdges(_wordIdA);
      final visibleEdges = await repository
          .getRelationEdgesWithinWordIdsForGraph([_wordIdA, _wordIdB]);

      for (final edge in [centerEdges.single, visibleEdges.single]) {
        expect(edge.relationId, relationId);
        expect(edge.statusCode, 'inferred');
        expect(edge.statusLabel, '기존 데이터 기반');
        expect(edge.statusDescription, contains('독립적으로 확정·검증되었음을 뜻하지 않는다'));
      }
    });

    test(
      '상태 create/update를 history에 보존하고 status-only update를 undo한다',
      () async {
        final repository = WordRepository();
        final relationId = await repository.createRelation(
          wordId1: _wordIdA,
          wordId2: _wordIdB,
          categoryCode: null,
          relationType: null,
          statusCode: ' hypothesized ',
          directionCode: 'unknown',
          note: null,
          source: null,
        );

        expect(await _relationStatusCode(relationId), 'hypothesized');
        var historyRows = await _relationHistoryRows(relationId);
        expect(historyRows, hasLength(1));
        expect(
          _decodeHistoryPayload(
            historyRows.single,
            'after_json',
          )['status_code'],
          'hypothesized',
        );

        await repository.updateRelation(
          relationId: relationId,
          categoryCode: null,
          relationType: null,
          statusCode: 'asserted',
          directionCode: 'unknown',
          note: null,
          source: null,
        );

        expect(await _relationStatusCode(relationId), 'asserted');
        historyRows = await _relationHistoryRows(relationId);
        expect(historyRows, hasLength(2));
        final updateHistory = historyRows.last;
        expect(updateHistory['action_type'], 'update');
        expect(
          _decodeHistoryPayload(updateHistory, 'before_json')['status_code'],
          'hypothesized',
        );
        expect(
          _decodeHistoryPayload(updateHistory, 'after_json')['status_code'],
          'asserted',
        );

        final undoResult = await repository.undoLastChange();
        expect(undoResult.didUndo, isTrue);
        expect(await _relationStatusCode(relationId), 'hypothesized');
        historyRows = await _relationHistoryRows(relationId);
        expect(historyRows.last['undone_at'], isNotNull);
      },
    );

    test('빈 값과 미정의 상태는 relation과 history를 변경하지 않는다', () async {
      final repository = WordRepository();
      final relationId = await repository.createRelation(
        wordId1: _wordIdA,
        wordId2: _wordIdB,
        categoryCode: null,
        relationType: null,
        statusCode: 'asserted',
        directionCode: 'unknown',
        note: null,
        source: null,
      );
      final historyCountBefore = await _relationHistoryCount();
      final relationCountBefore = await _relationCount();

      for (final invalidStatusCode in const ['   ', 'not-defined']) {
        await expectLater(
          repository.updateRelation(
            relationId: relationId,
            categoryCode: null,
            relationType: null,
            statusCode: invalidStatusCode,
            directionCode: 'unknown',
            note: null,
            source: null,
          ),
          throwsA(isA<ArgumentError>()),
        );
      }

      await expectLater(
        repository.createRelation(
          wordId1: _wordIdC,
          wordId2: _wordIdD,
          categoryCode: null,
          relationType: null,
          statusCode: ' ',
          directionCode: 'unknown',
          note: null,
          source: null,
        ),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        repository.createRelation(
          wordId1: _wordIdE,
          wordId2: _wordIdF,
          categoryCode: null,
          relationType: null,
          statusCode: 'not-defined',
          directionCode: 'unknown',
          note: null,
          source: null,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(await _relationStatusCode(relationId), 'asserted');
      expect(await _relationCount(), relationCountBefore);
      expect(await _relationHistoryCount(), historyCountBefore);
    });
  });
}

Future<Directory> _createIsolatedWorkspace(String sourceSeedDbPath) async {
  final isolatedRoot = await Directory.systemTemp.createTemp(
    'reshet_relation_status_repository_',
  );
  final isolatedDataDir = Directory(p.join(isolatedRoot.path, 'data'));
  await isolatedDataDir.create(recursive: true);
  await File(
    sourceSeedDbPath,
  ).copy(p.join(isolatedDataDir.path, 'reshet_seed.db'));
  await File(
    sourceSeedDbPath,
  ).copy(p.join(isolatedDataDir.path, 'reshet_work.db'));
  return isolatedRoot;
}

Future<void> _insertWord(dynamic db, String wordId) async {
  await db.insert('WORD_TABLE', {
    'id': wordId,
    '\uC5B8\uC5B4': '테스트 언어',
    '\uC2A4\uD2B8\uB871\uB118\uBC84': '',
  });
  await db.insert('word_expression_set', {
    'word_id': wordId,
    'seq': 1,
    'is_representative': 1,
    'spelling': wordId,
    'transliteration': '$wordId-transliteration',
  });
  await db.insert('word_meaning_set', {
    'word_id': wordId,
    'seq': 1,
    'meaning': '$wordId-meaning',
  });
}

Future<int> _insertRelation(
  dynamic db, {
  required String wordId1,
  required String wordId2,
  required String statusCode,
}) async {
  return await db.insert('WORD_RELATION', {
    'word_id_1': wordId1,
    'word_id_2': wordId2,
    'status_code': statusCode,
    'direction_code': 'unknown',
    'updated_at': DateTime.now().toIso8601String(),
  });
}

Future<String?> _relationStatusCode(int relationId) async {
  final db = await DatabaseService.openDatabaseFile();
  final rows = await db.query(
    'WORD_RELATION',
    columns: ['status_code'],
    where: 'id = ?',
    whereArgs: [relationId],
    limit: 1,
  );
  return rows.single['status_code'] as String?;
}

Future<List<Map<String, Object?>>> _relationHistoryRows(int relationId) async {
  final db = await DatabaseService.openDatabaseFile();
  return await db.query(
    'CHANGE_HISTORY',
    where: 'entity_type = ? AND entity_id = ?',
    whereArgs: ['relation', relationId.toString()],
    orderBy: 'id ASC',
  );
}

Map<String, dynamic> _decodeHistoryPayload(
  Map<String, Object?> historyRow,
  String column,
) {
  return Map<String, dynamic>.from(
    jsonDecode(historyRow[column]! as String) as Map,
  );
}

Future<int> _relationCount() async {
  final db = await DatabaseService.openDatabaseFile();
  final rows = await db.rawQuery('SELECT COUNT(*) AS count FROM WORD_RELATION');
  return rows.single['count']! as int;
}

Future<int> _relationHistoryCount() async {
  final db = await DatabaseService.openDatabaseFile();
  final rows = await db.rawQuery(
    "SELECT COUNT(*) AS count FROM CHANGE_HISTORY WHERE entity_type = 'relation'",
  );
  return rows.single['count']! as int;
}
