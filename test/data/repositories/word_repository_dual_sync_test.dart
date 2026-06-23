import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/adapters/legacy_word_expression_read_adapter.dart';
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/word/word_write_models.dart';

typedef SemanticExpressionRow = ({
  String wordId,
  int seq,
  int isRepresentative,
  String spelling,
  String? transliteration,
  String? pronunciation,
});

typedef SemanticMeaningRow = ({String wordId, int seq, String meaning});

const String _historyNormalizedExpressionRowsKey =
    '_normalized_expression_rows';
const String _historyNormalizedMeaningRowsKey = '_normalized_meaning_rows';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String repoRootPath;
  late String sourceWorkDbPath;
  Directory? isolatedRoot;

  setUpAll(() async {
    repoRootPath = Directory.current.path;
    sourceWorkDbPath = p.join(repoRootPath, 'data', 'reshet_work.db');

    expect(
      File(sourceWorkDbPath).existsSync(),
      isTrue,
      reason: 'dual-sync 테스트용 기준 DB가 필요합니다.',
    );

    await DatabaseService.closeDatabase();
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    isolatedRoot = await _createIsolatedWorkspace(
      repoRootPath,
      sourceWorkDbPath,
    );
    Directory.current = isolatedRoot!.path;
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    Directory.current = repoRootPath;

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await isolatedRoot!.delete(recursive: true);
    }
  });

  group('WordRepository dual-sync', () {
    test('runtime backfill preserves G2367_0000 raw meaning slots', () async {
      final db = await DatabaseService.openDatabaseFile();
      final rows = await db.query(
        'word_meaning_set',
        columns: const ['word_id', 'seq', 'meaning'],
        where: 'word_id = ?',
        whereArgs: ['G2367_0000'],
        orderBy: 'seq ASC',
      );

      expect(rows, [
        {'word_id': 'G2367_0000', 'seq': 1, 'meaning': '산다락나무의'},
        {
          'word_id': 'G2367_0000',
          'seq': 7,
          'meaning': "산다락(sandarac)나무의 학명은 'Tetraclinis articulata'.",
        },
      ]);
      expect(rows.map((row) => row['seq']), isNot(contains(2)));
    });

    test('createWord keeps normalized rows semantically aligned', () async {
      final repository = WordRepository();
      const wordId = 'T9000_1001';

      await repository.createWord(
        id: wordId,
        payload: _payload(
          expressionSets: const [
            CanonicalExpressionWriteSet(
              spelling: 'alpha',
              transliteration: '알파',
              pronunciation: 'al-fa',
              seq: 1,
              isRepresentative: true,
            ),
            CanonicalExpressionWriteSet(
              spelling: 'aleph',
              transliteration: null,
              pronunciation: null,
              seq: 2,
              isRepresentative: false,
            ),
          ],
          meanings: const ['첫째 의미'],
          note: 'dual-sync create',
        ),
      );

      await _expectSemanticSync(wordId);
      await _expectMeaningSync(wordId);

      final createHistoryAfter = await _loadLatestWordHistorySnapshot(
        wordId: wordId,
        actionType: 'create',
        jsonColumn: 'after_json',
      );
      expect(_readHistoryNormalizedRows(createHistoryAfter), hasLength(2));
      expect(_readHistoryNormalizedMeaningRows(createHistoryAfter), [
        {'word_id': wordId, 'seq': 1, 'meaning': '첫째 의미'},
      ]);
    });

    test(
      'updateWord full-replaces normalized rows after representative change',
      () async {
        final repository = WordRepository();
        const wordId = 'T9000_1002';

        await repository.createWord(
          id: wordId,
          payload: _payload(
            expressionSets: const [
              CanonicalExpressionWriteSet(
                spelling: 'beta',
                transliteration: '베타',
                pronunciation: 'be-ta',
                seq: 1,
                isRepresentative: true,
              ),
              CanonicalExpressionWriteSet(
                spelling: 'beth',
                transliteration: '베트',
                pronunciation: null,
                seq: 2,
                isRepresentative: false,
              ),
              CanonicalExpressionWriteSet(
                spelling: 'vet',
                transliteration: null,
                pronunciation: 'vet',
                seq: 3,
                isRepresentative: false,
              ),
            ],
          ),
        );

        await repository.updateWord(
          id: wordId,
          payload: _payload(
            expressionSets: const [
              CanonicalExpressionWriteSet(
                spelling: 'beth',
                transliteration: '베트',
                pronunciation: null,
                seq: 1,
                isRepresentative: true,
              ),
              CanonicalExpressionWriteSet(
                spelling: 'beta',
                transliteration: '베타',
                pronunciation: 'be-ta',
                seq: 2,
                isRepresentative: false,
              ),
            ],
            meanings: const ['대표 변경 후'],
          ),
        );

        await _expectSemanticSync(wordId);
        await _expectMeaningSync(wordId);

        final actualRows = await _loadActualSemanticRows(wordId);
        expect(actualRows, hasLength(2));
        expect(actualRows.first.spelling, 'beth');
        expect(actualRows.first.isRepresentative, 1);

        final rereadAfterSave = await repository
            .getWordMapByIdForReadAfterSaveSingleWord(wordId);
        expect(rereadAfterSave, isNotNull);
        expect(rereadAfterSave!['표기1'], 'beth');
        expect(rereadAfterSave['표기2'], 'beta');

        final updateHistoryBefore = await _loadLatestWordHistorySnapshot(
          wordId: wordId,
          actionType: 'update',
          jsonColumn: 'before_json',
        );
        final updateHistoryAfter = await _loadLatestWordHistorySnapshot(
          wordId: wordId,
          actionType: 'update',
          jsonColumn: 'after_json',
        );
        expect(_readHistoryNormalizedRows(updateHistoryBefore), hasLength(3));
        expect(_readHistoryNormalizedRows(updateHistoryAfter), hasLength(2));
        expect(_readHistoryNormalizedMeaningRows(updateHistoryAfter), [
          {'word_id': wordId, 'seq': 1, 'meaning': '대표 변경 후'},
        ]);
      },
    );

    test(
      'deleteWord removes normalized rows and undoLastChange restores them',
      () async {
        final repository = WordRepository();
        const wordId = 'T9000_1003';

        await repository.createWord(
          id: wordId,
          payload: _payload(
            expressionSets: const [
              CanonicalExpressionWriteSet(
                spelling: 'gamma',
                transliteration: '감마',
                pronunciation: 'ga-ma',
                seq: 1,
                isRepresentative: true,
              ),
              CanonicalExpressionWriteSet(
                spelling: 'gimel',
                transliteration: '',
                pronunciation: '',
                seq: 2,
                isRepresentative: false,
              ),
            ],
            meanings: const ['삭제 전 의미', '두 번째 의미'],
          ),
        );

        await repository.deleteWord(wordId);

        final db = await DatabaseService.openDatabaseFile();
        final deletedWord = await repository.getWordMapById(wordId);
        final remainingRows = await db.query(
          'word_expression_set',
          where: 'word_id = ?',
          whereArgs: [wordId],
        );
        final remainingMeaningRows = await db.query(
          'word_meaning_set',
          where: 'word_id = ?',
          whereArgs: [wordId],
        );

        expect(deletedWord, isNull);
        expect(remainingRows, isEmpty);
        expect(remainingMeaningRows, isEmpty);

        final undone = await repository.undoLastChange();
        expect(undone.didUndo, isTrue);
        expect(undone.primaryWordId, wordId);

        await _expectSemanticSync(wordId);
        await _expectMeaningSync(wordId);

        final rereadAfterUndo = await repository
            .getWordMapByIdForReadAfterUndoSingleWord(wordId);
        expect(rereadAfterUndo, isNotNull);
        expect(rereadAfterUndo!['표기1'], 'gamma');
        expect(rereadAfterUndo['표기2'], 'gimel');
      },
    );

    test('undoLastChange removes normalized rows for recent create', () async {
      final repository = WordRepository();
      const wordId = 'T9000_1004';

      await repository.createWord(
        id: wordId,
        payload: _payload(
          expressionSets: const [
            CanonicalExpressionWriteSet(
              spelling: 'delta',
              transliteration: '델타',
              pronunciation: null,
              seq: 1,
              isRepresentative: true,
            ),
          ],
        ),
      );

      final undone = await repository.undoLastChange();
      expect(undone.didUndo, isTrue);
      expect(undone.primaryWordId, isNull);

      final db = await DatabaseService.openDatabaseFile();
      final word = await repository.getWordMapById(wordId);
      final rows = await db.query(
        'word_expression_set',
        where: 'word_id = ?',
        whereArgs: [wordId],
      );

      expect(word, isNull);
      expect(rows, isEmpty);
    });

    test('undoLastChange restores normalized rows for recent update', () async {
      final repository = WordRepository();
      const wordId = 'T9000_1005';

      await repository.createWord(
        id: wordId,
        payload: _payload(
          expressionSets: const [
            CanonicalExpressionWriteSet(
              spelling: 'epsilon',
              transliteration: '엡실론',
              pronunciation: null,
              seq: 1,
              isRepresentative: true,
            ),
            CanonicalExpressionWriteSet(
              spelling: 'eps',
              transliteration: null,
              pronunciation: 'eps',
              seq: 2,
              isRepresentative: false,
            ),
          ],
          meanings: const ['원본'],
        ),
      );

      await repository.updateWord(
        id: wordId,
        payload: _payload(
          expressionSets: const [
            CanonicalExpressionWriteSet(
              spelling: 'eps',
              transliteration: null,
              pronunciation: 'eps',
              seq: 1,
              isRepresentative: true,
            ),
          ],
          meanings: const ['수정됨'],
        ),
      );

      await _expectSemanticSync(wordId);
      await _expectMeaningSync(wordId);

      final undone = await repository.undoLastChange();
      expect(undone.didUndo, isTrue);
      expect(undone.primaryWordId, wordId);

      await _expectSemanticSync(wordId);
      await _expectMeaningSync(wordId);

      final actualRows = await _loadActualSemanticRows(wordId);
      expect(actualRows, hasLength(2));
      expect(actualRows.first.spelling, 'epsilon');
      expect(actualRows.first.isRepresentative, 1);
    });

    test(
      'undoLastChange prefers normalized snapshot for new history rows',
      () async {
        final repository = WordRepository();
        const wordId = 'T9000_1006';

        await repository.createWord(
          id: wordId,
          payload: _payload(
            expressionSets: const [
              CanonicalExpressionWriteSet(
                spelling: 'zeta',
                transliteration: '제타',
                pronunciation: 'ze-ta',
                seq: 1,
                isRepresentative: true,
              ),
              CanonicalExpressionWriteSet(
                spelling: 'zayin',
                transliteration: null,
                pronunciation: null,
                seq: 2,
                isRepresentative: false,
              ),
            ],
          ),
        );

        await repository.updateWord(
          id: wordId,
          payload: _payload(
            expressionSets: const [
              CanonicalExpressionWriteSet(
                spelling: 'updated-zeta',
                transliteration: '업데이트',
                pronunciation: null,
                seq: 1,
                isRepresentative: true,
              ),
            ],
          ),
        );

        final historyId = await _loadLatestWordHistoryId(
          wordId: wordId,
          actionType: 'update',
        );
        final beforeSnapshot = await _loadHistorySnapshot(
          historyId,
          'before_json',
        );
        beforeSnapshot['표기1'] = 'tampered-legacy';
        await _writeHistorySnapshot(historyId, 'before_json', beforeSnapshot);

        final undone = await repository.undoLastChange();
        expect(undone.didUndo, isTrue);
        expect(undone.primaryWordId, wordId);

        final restoredWordRow = await _loadWordTableRow(wordId);
        final restoredNormalizedRows = await _loadActualSemanticRows(wordId);
        expect(restoredWordRow['표기1'], 'tampered-legacy');
        expect(restoredNormalizedRows, [
          (
            wordId: wordId,
            seq: 1,
            isRepresentative: 1,
            spelling: 'zeta',
            transliteration: '제타',
            pronunciation: 'ze-ta',
          ),
          (
            wordId: wordId,
            seq: 2,
            isRepresentative: 0,
            spelling: 'zayin',
            transliteration: null,
            pronunciation: null,
          ),
        ]);
      },
    );

    test(
      'undoLastChange falls back to legacy snapshot when normalized history is absent',
      () async {
        final repository = WordRepository();
        const wordId = 'T9000_1007';

        await repository.createWord(
          id: wordId,
          payload: _payload(
            expressionSets: const [
              CanonicalExpressionWriteSet(
                spelling: 'eta',
                transliteration: '에타',
                pronunciation: 'e-ta',
                seq: 1,
                isRepresentative: true,
              ),
              CanonicalExpressionWriteSet(
                spelling: 'heth',
                transliteration: null,
                pronunciation: null,
                seq: 2,
                isRepresentative: false,
              ),
            ],
          ),
        );

        await repository.updateWord(
          id: wordId,
          payload: _payload(
            expressionSets: const [
              CanonicalExpressionWriteSet(
                spelling: 'updated-eta',
                transliteration: null,
                pronunciation: null,
                seq: 1,
                isRepresentative: true,
              ),
            ],
          ),
        );

        final historyId = await _loadLatestWordHistoryId(
          wordId: wordId,
          actionType: 'update',
        );
        final beforeSnapshot = await _loadHistorySnapshot(
          historyId,
          'before_json',
        );
        beforeSnapshot.remove(_historyNormalizedExpressionRowsKey);
        beforeSnapshot.remove(_historyNormalizedMeaningRowsKey);
        beforeSnapshot['표기1'] = 'legacy-only-restore';
        beforeSnapshot['음역1'] = '레거시 음역';
        beforeSnapshot['발음1'] = 'legacy-pron';
        beforeSnapshot['의미1'] = '레거시 의미';
        beforeSnapshot['의미7'] = '레거시 일곱째 의미';
        await _writeHistorySnapshot(historyId, 'before_json', beforeSnapshot);

        final undone = await repository.undoLastChange();
        expect(undone.didUndo, isTrue);
        expect(undone.primaryWordId, wordId);

        await _expectSemanticSync(wordId);

        final restoredNormalizedRows = await _loadActualSemanticRows(wordId);
        expect(restoredNormalizedRows.first.spelling, 'legacy-only-restore');
        expect(restoredNormalizedRows.first.transliteration, '레거시 음역');
        expect(restoredNormalizedRows.first.pronunciation, 'legacy-pron');
        final restoredMeaningRows = await _loadActualMeaningRows(wordId);
        expect(restoredMeaningRows, [
          (wordId: wordId, seq: 1, meaning: '레거시 의미'),
          (wordId: wordId, seq: 7, meaning: '레거시 일곱째 의미'),
        ]);
      },
    );
  });
}

Future<Directory> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(p.join(repoRootPath, '.tmp_dual_sync_tests'));
  if (!tmpRoot.existsSync()) {
    await tmpRoot.create(recursive: true);
  }

  final isolatedRoot = Directory(
    p.join(tmpRoot.path, 'case_${DateTime.now().microsecondsSinceEpoch}'),
  );
  await isolatedRoot.create(recursive: true);

  final dataDir = Directory(p.join(isolatedRoot.path, 'data'));
  await dataDir.create(recursive: true);

  await File(sourceWorkDbPath).copy(p.join(dataDir.path, 'reshet_seed.db'));
  await File(sourceWorkDbPath).copy(p.join(dataDir.path, 'reshet_work.db'));

  return isolatedRoot;
}

CanonicalWordWritePayload _payload({
  required List<CanonicalExpressionWriteSet> expressionSets,
  List<String> meanings = const [],
  String? note,
}) {
  return CanonicalWordWritePayload(
    language: '테스트언어',
    strongNumber: null,
    expressionSets: expressionSets,
    meanings: meanings,
    note: note,
  );
}

Future<void> _expectSemanticSync(String wordId) async {
  final expected = await _loadExpectedSemanticRows(wordId);
  final actual = await _loadActualSemanticRows(wordId);

  expect(
    actual,
    expected,
    reason:
        'word_expression_set semantic compare 축(word_id, seq, is_representative, spelling, transliteration, pronunciation)이 legacy snapshot과 일치해야 합니다.',
  );
}

Future<void> _expectMeaningSync(String wordId) async {
  final expected = await _loadExpectedMeaningRows(wordId);
  final actual = await _loadActualMeaningRows(wordId);

  expect(
    actual,
    expected,
    reason:
        'word_meaning_set semantic compare 축(word_id, seq, meaning)이 legacy 의미 slot projection과 일치해야 합니다.',
  );
}

Future<List<SemanticExpressionRow>> _loadExpectedSemanticRows(
  String wordId,
) async {
  final db = await DatabaseService.openDatabaseFile();
  final rows = await db.query(
    'WORD_TABLE',
    where: 'id = ?',
    whereArgs: [wordId],
    limit: 1,
  );

  if (rows.isEmpty) {
    return const [];
  }

  final wordRow = Map<String, dynamic>.from(rows.first);
  final readResult = readLegacyWordExpressionRow(wordRow);

  return List.generate(readResult.sets.length, (index) {
    final set = readResult.sets[index];
    return (
      wordId: wordId,
      seq: set.seq,
      isRepresentative: set.isRepresentative ? 1 : 0,
      spelling: set.spelling,
      transliteration: set.transliteration,
      pronunciation: set.pronunciation,
    );
  }, growable: false);
}

Future<List<SemanticExpressionRow>> _loadActualSemanticRows(
  String wordId,
) async {
  final db = await DatabaseService.openDatabaseFile();
  final rows = await db.query(
    'word_expression_set',
    columns: const [
      'word_id',
      'seq',
      'is_representative',
      'spelling',
      'transliteration',
      'pronunciation',
    ],
    where: 'word_id = ?',
    whereArgs: [wordId],
    orderBy: 'seq ASC',
  );

  return rows
      .map(
        (row) => (
          wordId: (row['word_id'] ?? '').toString(),
          seq: _readInt(row['seq']),
          isRepresentative: _readInt(row['is_representative']),
          spelling: (row['spelling'] ?? '').toString(),
          transliteration: row['transliteration'] as String?,
          pronunciation: row['pronunciation'] as String?,
        ),
      )
      .toList(growable: false);
}

Future<List<SemanticMeaningRow>> _loadExpectedMeaningRows(String wordId) async {
  final db = await DatabaseService.openDatabaseFile();
  final rows = await db.query(
    'WORD_TABLE',
    where: 'id = ?',
    whereArgs: [wordId],
    limit: 1,
  );

  if (rows.isEmpty) {
    return const [];
  }

  final wordRow = Map<String, dynamic>.from(rows.first);
  final expectedRows = <SemanticMeaningRow>[];
  for (var index = 1; index <= 7; index++) {
    final rawMeaning = wordRow['의미$index'];
    if (rawMeaning == null) {
      continue;
    }

    final meaning = rawMeaning.toString();
    if (meaning.isEmpty) {
      continue;
    }

    expectedRows.add((wordId: wordId, seq: index, meaning: meaning));
  }

  return expectedRows;
}

Future<List<SemanticMeaningRow>> _loadActualMeaningRows(String wordId) async {
  final db = await DatabaseService.openDatabaseFile();
  final rows = await db.query(
    'word_meaning_set',
    columns: const ['word_id', 'seq', 'meaning'],
    where: 'word_id = ?',
    whereArgs: [wordId],
    orderBy: 'seq ASC',
  );

  return rows
      .map(
        (row) => (
          wordId: (row['word_id'] ?? '').toString(),
          seq: _readInt(row['seq']),
          meaning: (row['meaning'] ?? '').toString(),
        ),
      )
      .toList(growable: false);
}

Future<int> _loadLatestWordHistoryId({
  required String wordId,
  required String actionType,
}) async {
  final db = await DatabaseService.openDatabaseFile();
  final rows = await db.query(
    'CHANGE_HISTORY',
    columns: const ['id'],
    where: 'entity_type = ? AND entity_id = ? AND action_type = ?',
    whereArgs: ['word', wordId, actionType],
    orderBy: 'created_at DESC, id DESC',
    limit: 1,
  );

  expect(rows, isNotEmpty, reason: '변경 이력 row가 필요합니다.');
  return _readInt(rows.first['id']);
}

Future<Map<String, dynamic>> _loadLatestWordHistorySnapshot({
  required String wordId,
  required String actionType,
  required String jsonColumn,
}) async {
  final historyId = await _loadLatestWordHistoryId(
    wordId: wordId,
    actionType: actionType,
  );
  return _loadHistorySnapshot(historyId, jsonColumn);
}

Future<Map<String, dynamic>> _loadHistorySnapshot(
  int historyId,
  String jsonColumn,
) async {
  final db = await DatabaseService.openDatabaseFile();
  final rows = await db.query(
    'CHANGE_HISTORY',
    columns: [jsonColumn],
    where: 'id = ?',
    whereArgs: [historyId],
    limit: 1,
  );

  expect(rows, isNotEmpty, reason: '지정한 history row를 찾을 수 없습니다.');
  final jsonText = rows.first[jsonColumn] as String?;
  expect(jsonText, isNotNull, reason: '$jsonColumn snapshot이 필요합니다.');
  return Map<String, dynamic>.from(jsonDecode(jsonText!));
}

Future<void> _writeHistorySnapshot(
  int historyId,
  String jsonColumn,
  Map<String, dynamic> snapshot,
) async {
  final db = await DatabaseService.openDatabaseFile();
  await db.update(
    'CHANGE_HISTORY',
    {jsonColumn: jsonEncode(snapshot)},
    where: 'id = ?',
    whereArgs: [historyId],
  );
}

List<Map<String, dynamic>> _readHistoryNormalizedRows(
  Map<String, dynamic> snapshot,
) {
  final rawRows = snapshot[_historyNormalizedExpressionRowsKey];
  if (rawRows is! List) {
    return const [];
  }

  return rawRows
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList(growable: false);
}

List<Map<String, dynamic>> _readHistoryNormalizedMeaningRows(
  Map<String, dynamic> snapshot,
) {
  final rawRows = snapshot[_historyNormalizedMeaningRowsKey];
  if (rawRows is! List) {
    return const [];
  }

  return rawRows
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList(growable: false);
}

Future<Map<String, dynamic>> _loadWordTableRow(String wordId) async {
  final db = await DatabaseService.openDatabaseFile();
  final rows = await db.query(
    'WORD_TABLE',
    where: 'id = ?',
    whereArgs: [wordId],
    limit: 1,
  );

  expect(rows, isNotEmpty, reason: 'WORD_TABLE row가 필요합니다.');
  return Map<String, dynamic>.from(rows.first);
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }

  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed != null) {
    return parsed;
  }

  throw ArgumentError.value(value, 'value', '정수 변환에 실패했습니다.');
}
