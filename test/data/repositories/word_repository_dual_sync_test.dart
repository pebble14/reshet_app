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
      'createWord preserves 8+ canonical meanings and projects only first seven legacy slots',
      () async {
        final repository = WordRepository();
        const wordId = 'T9000_1010';
        final meanings = List<String>.generate(
          8,
          (index) => 'canonical meaning ${index + 1}',
          growable: false,
        );

        await repository.createWord(
          id: wordId,
          payload: _payload(
            expressionSets: const [
              CanonicalExpressionWriteSet(
                spelling: 'meaning-eight-title',
                transliteration: null,
                pronunciation: null,
                seq: 1,
                isRepresentative: true,
              ),
            ],
            meanings: meanings,
          ),
        );

        expect(await _loadActualMeaningRows(wordId), [
          for (var index = 1; index <= 8; index++)
            (wordId: wordId, seq: index, meaning: 'canonical meaning $index'),
        ]);

        final wordRow = await _loadWordTableRow(wordId);
        expect(_readMeaningSlots(wordRow), {
          for (var index = 1; index <= 7; index++)
            '의미$index': 'canonical meaning $index',
        });
        expect(wordRow.containsKey('의미8'), isFalse);

        final detail = await repository
            .getWordDetailLikeDisplayItemByIdForDetailScreen(wordId);
        expect(detail, isNotNull);
        expect(detail!.meanings, meanings);

        final editSeed = await repository.getWordEditSeedForDetailEdit(wordId);
        expect(editSeed, isNotNull);
        expect(editSeed!.meanings, meanings);

        final createHistoryAfter = await _loadLatestWordHistorySnapshot(
          wordId: wordId,
          actionType: 'create',
          jsonColumn: 'after_json',
        );
        expect(_readHistoryNormalizedMeaningRows(createHistoryAfter), [
          for (var index = 1; index <= 8; index++)
            {
              'word_id': wordId,
              'seq': index,
              'meaning': 'canonical meaning $index',
            },
        ]);

        await DatabaseService.closeDatabase();
        await DatabaseService.openDatabaseFile();
        expect(await _loadActualMeaningRows(wordId), [
          for (var index = 1; index <= 8; index++)
            (wordId: wordId, seq: index, meaning: 'canonical meaning $index'),
        ]);
      },
    );

    test(
      'create update and undo preserve 7+ canonical expression sets while legacy projection stays six slots',
      () async {
        final repository = WordRepository();
        const wordId = 'T9000_1012';
        final originalExpressions = _expressionSets(
          7,
          prefix: 'phase33_original',
        );
        final updatedExpressions = _expressionSets(
          7,
          prefix: 'phase33_updated',
        );

        await repository.createWord(
          id: wordId,
          payload: _payload(expressionSets: originalExpressions),
        );

        expect(await _loadActualSemanticRows(wordId), [
          for (var index = 1; index <= 7; index++)
            (
              wordId: wordId,
              seq: index,
              isRepresentative: index == 1 ? 1 : 0,
              spelling: 'phase33_original_spelling_$index',
              transliteration: 'phase33_original_trans_$index',
              pronunciation: 'phase33_original_pron_$index',
            ),
        ]);

        final createdWordRow = await _loadWordTableRow(wordId);
        for (var index = 1; index <= 6; index++) {
          expect(
            createdWordRow['표기$index'],
            'phase33_original_spelling_$index',
          );
          expect(createdWordRow['음역$index'], 'phase33_original_trans_$index');
          expect(createdWordRow['발음$index'], 'phase33_original_pron_$index');
        }
        expect(createdWordRow.containsKey('표기7'), isFalse);
        expect(createdWordRow.containsKey('음역7'), isFalse);
        expect(createdWordRow.containsKey('발음7'), isFalse);

        final detail = await repository
            .getWordDetailLikeDisplayItemByIdForDetailScreen(wordId);
        expect(detail, isNotNull);
        expect(detail!.spellings, [
          for (var index = 1; index <= 7; index++)
            'phase33_original_spelling_$index',
        ]);
        expect(detail.transliterations, [
          for (var index = 1; index <= 7; index++)
            'phase33_original_trans_$index',
        ]);
        expect(detail.pronunciations, [
          for (var index = 1; index <= 7; index++)
            'phase33_original_pron_$index',
        ]);

        final editSeed = await repository.getWordEditSeedForDetailEdit(wordId);
        expect(editSeed, isNotNull);
        expect(editSeed!.expressionReadResult.sets, hasLength(7));
        expect(
          editSeed.expressionReadResult.sets[6].spelling,
          ['phase33_original_spelling_7'].single,
        );

        final createHistoryAfter = await _loadLatestWordHistorySnapshot(
          wordId: wordId,
          actionType: 'create',
          jsonColumn: 'after_json',
        );
        expect(_readHistoryNormalizedRows(createHistoryAfter), hasLength(7));

        await repository.updateWord(
          id: wordId,
          payload: _payload(expressionSets: updatedExpressions),
        );
        expect(await _loadActualSemanticRows(wordId), [
          for (var index = 1; index <= 7; index++)
            (
              wordId: wordId,
              seq: index,
              isRepresentative: index == 1 ? 1 : 0,
              spelling: 'phase33_updated_spelling_$index',
              transliteration: 'phase33_updated_trans_$index',
              pronunciation: 'phase33_updated_pron_$index',
            ),
        ]);

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
        expect(_readHistoryNormalizedRows(updateHistoryBefore), hasLength(7));
        expect(_readHistoryNormalizedRows(updateHistoryAfter), hasLength(7));

        final undone = await repository.undoLastChange();
        expect(undone.didUndo, isTrue);
        expect(undone.primaryWordId, wordId);
        expect(await _loadActualSemanticRows(wordId), [
          for (var index = 1; index <= 7; index++)
            (
              wordId: wordId,
              seq: index,
              isRepresentative: index == 1 ? 1 : 0,
              spelling: 'phase33_original_spelling_$index',
              transliteration: 'phase33_original_trans_$index',
              pronunciation: 'phase33_original_pron_$index',
            ),
        ]);
      },
    );

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
        expect(_readHistoryNormalizedMeaningRows(updateHistoryBefore), isEmpty);
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

        final deleteHistoryBefore = await _loadLatestWordHistorySnapshot(
          wordId: wordId,
          actionType: 'delete',
          jsonColumn: 'before_json',
        );
        expect(_readHistoryNormalizedMeaningRows(deleteHistoryBefore), [
          {'word_id': wordId, 'seq': 1, 'meaning': '삭제 전 의미'},
          {'word_id': wordId, 'seq': 2, 'meaning': '두 번째 의미'},
        ]);

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
          meanings: const ['생성 취소 의미'],
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
      final meaningRows = await db.query(
        'word_meaning_set',
        where: 'word_id = ?',
        whereArgs: [wordId],
      );

      expect(word, isNull);
      expect(rows, isEmpty);
      expect(meaningRows, isEmpty);
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
      'undoLastChange restores 8+ canonical meanings for recent update',
      () async {
        final repository = WordRepository();
        const wordId = 'T9000_1011';
        final originalMeanings = List<String>.generate(
          8,
          (index) => 'undo original meaning ${index + 1}',
          growable: false,
        );
        final updatedMeanings = List<String>.generate(
          9,
          (index) => 'undo updated meaning ${index + 1}',
          growable: false,
        );

        await repository.createWord(
          id: wordId,
          payload: _payload(
            expressionSets: const [
              CanonicalExpressionWriteSet(
                spelling: 'undo-meaning-title',
                transliteration: null,
                pronunciation: null,
                seq: 1,
                isRepresentative: true,
              ),
            ],
            meanings: originalMeanings,
          ),
        );

        await repository.updateWord(
          id: wordId,
          payload: _payload(
            expressionSets: const [
              CanonicalExpressionWriteSet(
                spelling: 'undo-meaning-title-updated',
                transliteration: null,
                pronunciation: null,
                seq: 1,
                isRepresentative: true,
              ),
            ],
            meanings: updatedMeanings,
          ),
        );

        final undone = await repository.undoLastChange();
        expect(undone.didUndo, isTrue);
        expect(undone.primaryWordId, wordId);

        expect(await _loadActualMeaningRows(wordId), [
          for (var index = 1; index <= 8; index++)
            (
              wordId: wordId,
              seq: index,
              meaning: 'undo original meaning $index',
            ),
        ]);

        final detail = await repository
            .getWordDetailLikeDisplayItemByIdForDetailScreen(wordId);
        expect(detail, isNotNull);
        expect(detail!.meanings, originalMeanings);
      },
    );

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
            meanings: const [
              'zeta 의미 1',
              'zeta 의미 2',
              'zeta 의미 3',
              'zeta 의미 4',
              'zeta 의미 5',
              'zeta 의미 6',
              'zeta 의미 7',
              'zeta 의미 8',
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
            meanings: const ['updated-zeta 의미'],
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
        beforeSnapshot['의미1'] = 'tampered legacy meaning';
        beforeSnapshot['의미2'] = null;
        beforeSnapshot['의미3'] = null;
        beforeSnapshot['의미4'] = null;
        beforeSnapshot['의미5'] = null;
        beforeSnapshot['의미6'] = null;
        beforeSnapshot['의미7'] = null;
        await _writeHistorySnapshot(historyId, 'before_json', beforeSnapshot);

        final undone = await repository.undoLastChange();
        expect(undone.didUndo, isTrue);
        expect(undone.primaryWordId, wordId);

        final restoredWordRow = await _loadWordTableRow(wordId);
        final restoredNormalizedRows = await _loadActualSemanticRows(wordId);
        expect(restoredWordRow['표기1'], 'tampered-legacy');
        expect(restoredWordRow['의미1'], 'tampered legacy meaning');
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
        expect(await _loadActualMeaningRows(wordId), [
          for (var index = 1; index <= 8; index++)
            (wordId: wordId, seq: index, meaning: 'zeta 의미 $index'),
        ]);
      },
    );

    test(
      'undoLastChange falls back to legacy meaning slots for legacy-only snapshot',
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
        beforeSnapshot['의미2'] = null;
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

    test(
      'updateWord rollback restores legacy and normalized meanings on projection failure',
      () async {
        final repository = WordRepository();
        const wordId = 'T9000_1008';
        const updatedMeaning1 = 'rollback 새 의미 1';
        const updatedMeaning2 = 'rollback 새 의미 2';
        const updatedMeaning3 = 'rollback 새 의미 3';
        const triggerName = 'phase31e_meaning_projection_failure';
        const legacyProjectionFailureSentinel =
            'phase31e legacy projection failure sentinel';
        const normalizedFirstViolationSentinel =
            'phase31e normalized-first violation sentinel';

        await repository.createWord(
          id: wordId,
          payload: _payload(
            expressionSets: const [
              CanonicalExpressionWriteSet(
                spelling: 'theta',
                transliteration: '세타',
                pronunciation: null,
                seq: 1,
                isRepresentative: true,
              ),
            ],
            meanings: const ['rollback 이전 의미 1', 'rollback 이전 의미 2'],
          ),
        );

        final db = await DatabaseService.openDatabaseFile();
        final beforeMeaningSlots = _readMeaningSlots(
          await _loadWordTableRow(wordId),
        );
        final beforeMeaningRows = await _loadActualMeaningRows(wordId);

        await db.execute('''
CREATE TEMP TRIGGER "$triggerName"
BEFORE UPDATE OF "의미1", "의미2", "의미3", "의미4", "의미5", "의미6", "의미7"
ON "WORD_TABLE"
WHEN OLD."id" = '$wordId' AND NEW."의미1" = '$updatedMeaning1'
BEGIN
  SELECT CASE
    WHEN (
      SELECT COUNT(*)
      FROM "word_meaning_set"
      WHERE "word_id" = OLD."id"
    ) != 3
    THEN RAISE(ABORT, '$normalizedFirstViolationSentinel')
  END;
  SELECT CASE
    WHEN NOT EXISTS (
      SELECT 1
      FROM "word_meaning_set"
      WHERE "word_id" = OLD."id"
        AND "seq" = 1
        AND "meaning" = '$updatedMeaning1'
    )
    THEN RAISE(ABORT, '$normalizedFirstViolationSentinel')
  END;
  SELECT CASE
    WHEN NOT EXISTS (
      SELECT 1
      FROM "word_meaning_set"
      WHERE "word_id" = OLD."id"
        AND "seq" = 2
        AND "meaning" = '$updatedMeaning2'
    )
    THEN RAISE(ABORT, '$normalizedFirstViolationSentinel')
  END;
  SELECT CASE
    WHEN NOT EXISTS (
      SELECT 1
      FROM "word_meaning_set"
      WHERE "word_id" = OLD."id"
        AND "seq" = 3
        AND "meaning" = '$updatedMeaning3'
    )
    THEN RAISE(ABORT, '$normalizedFirstViolationSentinel')
  END;
  SELECT RAISE(ABORT, '$legacyProjectionFailureSentinel');
END
''');

        Object? updateError;
        try {
          await repository.updateWord(
            id: wordId,
            payload: _payload(
              expressionSets: const [
                CanonicalExpressionWriteSet(
                  spelling: 'theta-updated',
                  transliteration: '세타 수정',
                  pronunciation: null,
                  seq: 1,
                  isRepresentative: true,
                ),
              ],
              meanings: const [
                updatedMeaning1,
                updatedMeaning2,
                updatedMeaning3,
              ],
            ),
          );
        } catch (error) {
          updateError = error;
        } finally {
          await db.execute('DROP TRIGGER IF EXISTS "$triggerName"');
        }

        expect(updateError, isNotNull);
        expect(
          updateError.toString(),
          contains(legacyProjectionFailureSentinel),
        );
        expect(
          updateError.toString(),
          isNot(contains(normalizedFirstViolationSentinel)),
        );

        expect(
          _readMeaningSlots(await _loadWordTableRow(wordId)),
          beforeMeaningSlots,
        );
        expect(await _loadActualMeaningRows(wordId), beforeMeaningRows);
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

List<CanonicalExpressionWriteSet> _expressionSets(
  int count, {
  required String prefix,
}) {
  return List<CanonicalExpressionWriteSet>.generate(count, (index) {
    final seq = index + 1;
    return CanonicalExpressionWriteSet(
      spelling: '${prefix}_spelling_$seq',
      transliteration: '${prefix}_trans_$seq',
      pronunciation: '${prefix}_pron_$seq',
      seq: seq,
      isRepresentative: seq == 1,
    );
  }, growable: false);
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

Map<String, Object?> _readMeaningSlots(Map<String, dynamic> wordRow) {
  return {
    for (var index = 1; index <= 7; index++) '의미$index': wordRow['의미$index'],
  };
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
