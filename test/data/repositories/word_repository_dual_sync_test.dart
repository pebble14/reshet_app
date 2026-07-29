import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/expression/pronunciation_notation.dart';
import 'package:reshet_app/domain/word/word_write_models.dart';

import '../../support/database_test_isolation_guard.dart';

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
  late String sourceSeedDbPath;
  late String sourceWorkDbPath;
  Directory? isolatedRoot;

  setUpAll(() async {
    repoRootPath = Directory.current.path;
    sourceSeedDbPath = p.join(repoRootPath, 'data', 'reshet_seed.db');
    sourceWorkDbPath = p.join(repoRootPath, 'data', 'reshet_work.db');

    expect(
      File(sourceSeedDbPath).existsSync(),
      isTrue,
      reason: 'dual-sync 테스트용 기준 seed DB가 필요합니다.',
    );

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

  group('WordRepository normalized persistence', () {
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

      expect(await _loadActualSemanticRows(wordId), [
        (
          wordId: wordId,
          seq: 1,
          isRepresentative: 1,
          spelling: 'alpha',
          transliteration: '알파',
          pronunciation: 'al-fa',
        ),
        (
          wordId: wordId,
          seq: 2,
          isRepresentative: 0,
          spelling: 'aleph',
          transliteration: null,
          pronunciation: null,
        ),
      ]);
      expect(await _loadActualMeaningRows(wordId), [
        (wordId: wordId, seq: 1, meaning: '첫째 의미'),
      ]);
      expect(
        _readExpressionSlots(await _loadWordTableRow(wordId)).values,
        everyElement(isNull),
      );
      expect(
        _readMeaningSlots(await _loadWordTableRow(wordId)).values,
        everyElement(isNull),
      );

      final createHistoryAfter = await _loadLatestWordHistorySnapshot(
        wordId: wordId,
        actionType: 'create',
        jsonColumn: 'after_json',
      );
      expect(_readHistoryNormalizedRows(createHistoryAfter), hasLength(2));
      expect(_readHistoryNormalizedMeaningRows(createHistoryAfter), [
        {'word_id': wordId, 'seq': 1, 'meaning': '첫째 의미'},
      ]);
      _expectNoLegacyExpressionKeys(createHistoryAfter);
      _expectNoLegacyMeaningKeys(createHistoryAfter);
    });

    test(
      'createWord preserves 8+ canonical meanings without writing legacy slots',
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
        expect(_readMeaningSlots(wordRow).values, everyElement(isNull));
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
        _expectNoLegacyMeaningKeys(createHistoryAfter);

        await DatabaseService.closeDatabase();
        await DatabaseService.openDatabaseFile();
        expect(await _loadActualMeaningRows(wordId), [
          for (var index = 1; index <= 8; index++)
            (wordId: wordId, seq: index, meaning: 'canonical meaning $index'),
        ]);
      },
    );

    test('raw live rows do not fall back to legacy meaning slots', () {
      final repository = WordRepository();

      final seed = repository.buildWordEditSeedFromWordRow({
        'id': 'T9000_1015',
        '언어': '테스트언어',
        '표기1': 'legacy-live-row',
        '의미1': 'legacy runtime fallback must stay hidden',
      });

      expect(seed.meanings, isEmpty);
    });

    test(
      'create update and undo preserve 7+ canonical expressions without changing physical slots',
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
        expect(
          _readExpressionSlots(createdWordRow).values,
          everyElement(isNull),
        );
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
        _expectNoLegacyExpressionKeys(createHistoryAfter);

        final db = await DatabaseService.openDatabaseFile();
        final physicalExpressionSentinels = <String, Object?>{
          for (var index = 1; index <= 6; index++)
            '표기$index': 'physical_spelling_$index',
          for (var index = 1; index <= 6; index++)
            '음역$index': 'physical_transliteration_$index',
          for (var index = 1; index <= 6; index++)
            '발음$index': 'physical_pronunciation_$index',
        };
        await db.update(
          'WORD_TABLE',
          physicalExpressionSentinels,
          where: 'id = ?',
          whereArgs: [wordId],
        );

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
        _expectNoLegacyExpressionKeys(updateHistoryBefore);
        _expectNoLegacyExpressionKeys(updateHistoryAfter);
        expect(
          _readExpressionSlots(await _loadWordTableRow(wordId)),
          physicalExpressionSentinels,
        );

        final undone = await repository.undoLastChange();
        expect(undone.didUndo, isTrue);
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
        expect(
          _readExpressionSlots(await _loadWordTableRow(wordId)),
          physicalExpressionSentinels,
        );
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

        final legacyMeaningSlotsBefore = _readMeaningSlots(
          await _loadWordTableRow(wordId),
        );
        expect(legacyMeaningSlotsBefore.values, everyElement(isNull));
        final physicalExpressionSlotsBefore = _readExpressionSlots(
          await _loadWordTableRow(wordId),
        );
        expect(physicalExpressionSlotsBefore.values, everyElement(isNull));

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

        expect(await _loadActualMeaningRows(wordId), [
          (wordId: wordId, seq: 1, meaning: '대표 변경 후'),
        ]);
        expect(
          _readMeaningSlots(await _loadWordTableRow(wordId)),
          legacyMeaningSlotsBefore,
        );
        expect(
          _readExpressionSlots(await _loadWordTableRow(wordId)),
          physicalExpressionSlotsBefore,
        );

        final actualRows = await _loadActualSemanticRows(wordId);
        expect(actualRows, hasLength(2));
        expect(actualRows.first.spelling, 'beth');
        expect(actualRows.first.isRepresentative, 1);

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
        _expectNoLegacyExpressionKeys(updateHistoryBefore);
        _expectNoLegacyExpressionKeys(updateHistoryAfter);
        _expectNoLegacyMeaningKeys(updateHistoryBefore);
        _expectNoLegacyMeaningKeys(updateHistoryAfter);
      },
    );

    test(
      'create update delete and undo work without legacy expression columns',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_1017';
        final originalExpressions = _expressionSets(
          7,
          prefix: 'columnless_original',
        );
        final updatedExpressions = _expressionSets(
          8,
          prefix: 'columnless_updated',
        );

        await _dropLegacyExpressionColumns(db);

        await repository.createWord(
          id: wordId,
          payload: _payload(
            expressionSets: originalExpressions,
            meanings: const ['columnless original meaning'],
          ),
        );
        final createdWordRow = await _loadWordTableRow(wordId);
        _expectNoLegacyExpressionKeys(createdWordRow);
        expect(await _loadActualSemanticRows(wordId), hasLength(7));
        final createHistoryAfter = await _loadLatestWordHistorySnapshot(
          wordId: wordId,
          actionType: 'create',
          jsonColumn: 'after_json',
        );
        expect(_readHistoryNormalizedRows(createHistoryAfter), hasLength(7));
        _expectNoLegacyExpressionKeys(createHistoryAfter);

        await repository.updateWord(
          id: wordId,
          payload: _payload(
            expressionSets: updatedExpressions,
            meanings: const ['columnless updated meaning'],
          ),
        );
        expect(await _loadActualSemanticRows(wordId), hasLength(8));
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
        _expectNoLegacyExpressionKeys(updateHistoryBefore);
        _expectNoLegacyExpressionKeys(updateHistoryAfter);

        final updateUndone = await repository.undoLastChange();
        expect(updateUndone.didUndo, isTrue);
        expect(await _loadActualSemanticRows(wordId), hasLength(7));
        expect(
          (await _loadActualSemanticRows(wordId)).last.spelling,
          'columnless_original_spelling_7',
        );

        await repository.deleteWord(wordId);
        expect(
          await db.query(
            'WORD_TABLE',
            columns: const ['id'],
            where: 'id = ?',
            whereArgs: [wordId],
          ),
          isEmpty,
        );
        final deleteHistoryBefore = await _loadLatestWordHistorySnapshot(
          wordId: wordId,
          actionType: 'delete',
          jsonColumn: 'before_json',
        );
        expect(_readHistoryNormalizedRows(deleteHistoryBefore), hasLength(7));
        _expectNoLegacyExpressionKeys(deleteHistoryBefore);

        final deleteUndone = await repository.undoLastChange();
        expect(deleteUndone.didUndo, isTrue);
        final restoredRows = await _loadActualSemanticRows(wordId);
        expect(restoredRows, hasLength(7));
        expect(restoredRows.last.spelling, 'columnless_original_spelling_7');
        _expectNoLegacyExpressionKeys(await _loadWordTableRow(wordId));
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
        final deletedWordRows = await db.query(
          'WORD_TABLE',
          columns: const ['id'],
          where: 'id = ?',
          whereArgs: [wordId],
          limit: 1,
        );
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

        expect(deletedWordRows, isEmpty);
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
        _expectNoLegacyExpressionKeys(deleteHistoryBefore);

        final undone = await repository.undoLastChange();
        expect(undone.didUndo, isTrue);

        expect(await _loadActualSemanticRows(wordId), [
          (
            wordId: wordId,
            seq: 1,
            isRepresentative: 1,
            spelling: 'gamma',
            transliteration: '감마',
            pronunciation: 'ga-ma',
          ),
          (
            wordId: wordId,
            seq: 2,
            isRepresentative: 0,
            spelling: 'gimel',
            transliteration: null,
            pronunciation: null,
          ),
        ]);
        expect(await _loadActualMeaningRows(wordId), [
          (wordId: wordId, seq: 1, meaning: '삭제 전 의미'),
          (wordId: wordId, seq: 2, meaning: '두 번째 의미'),
        ]);
        expect(
          _readMeaningSlots(await _loadWordTableRow(wordId)).values,
          everyElement(isNull),
        );
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

      final db = await DatabaseService.openDatabaseFile();
      final wordRows = await db.query(
        'WORD_TABLE',
        columns: const ['id'],
        where: 'id = ?',
        whereArgs: [wordId],
        limit: 1,
      );
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

      expect(wordRows, isEmpty);
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
              pronunciation: '/epsilon/',
              pronunciationNotation: PronunciationNotation.ipaPhonemic,
              seq: 1,
              isRepresentative: true,
            ),
            CanonicalExpressionWriteSet(
              spelling: 'eps',
              transliteration: null,
              pronunciation: '/eps/',
              pronunciationNotation: PronunciationNotation.ipaPhonemic,
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

      expect(await _loadActualSemanticRows(wordId), [
        (
          wordId: wordId,
          seq: 1,
          isRepresentative: 1,
          spelling: 'eps',
          transliteration: null,
          pronunciation: 'eps',
        ),
      ]);
      expect(await _loadActualMeaningRows(wordId), [
        (wordId: wordId, seq: 1, meaning: '수정됨'),
      ]);

      final undone = await repository.undoLastChange();
      expect(undone.didUndo, isTrue);

      expect(await _loadActualMeaningRows(wordId), [
        (wordId: wordId, seq: 1, meaning: '원본'),
      ]);
      expect(
        _readMeaningSlots(await _loadWordTableRow(wordId)).values,
        everyElement(isNull),
      );

      final actualRows = await _loadActualSemanticRows(wordId);
      expect(actualRows, hasLength(2));
      expect(actualRows.first.spelling, 'epsilon');
      expect(actualRows.first.isRepresentative, 1);

      final db = await DatabaseService.openDatabaseFile();
      final restoredPronunciationRows = await db.query(
        'word_expression_set',
        columns: const [
          'pronunciation',
          'pronunciation_notation',
          'pronunciation_notation_name',
        ],
        where: 'word_id = ? AND seq = ?',
        whereArgs: [wordId, 2],
      );
      expect(restoredPronunciationRows.single, {
        'pronunciation': 'eps',
        'pronunciation_notation': 'ipa_phonemic',
        'pronunciation_notation_name': null,
      });

      final detail = await repository
          .getWordDetailLikeDisplayItemByIdForDetailScreen(wordId);
      final searchResult = (await repository.searchWordsMap(
        'epsilon',
      )).singleWhere((item) => item.wordId == wordId);
      expect(detail!.pronunciations.first, '/epsilon/');
      expect(searchResult.representativePronunciation, '/epsilon/');
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
        final db = await DatabaseService.openDatabaseFile();
        await db.update(
          'WORD_TABLE',
          const {
            '표기1': 'physical-zeta',
            '음역1': 'physical-zeta-transliteration',
            '발음1': 'physical-zeta-pronunciation',
          },
          where: 'id = ?',
          whereArgs: [wordId],
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
        _expectNoLegacyMeaningKeys(beforeSnapshot);
        _expectNoLegacyExpressionKeys(beforeSnapshot);
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

        final restoredWordRow = await _loadWordTableRow(wordId);
        final restoredNormalizedRows = await _loadActualSemanticRows(wordId);
        expect(restoredWordRow['표기1'], 'physical-zeta');
        expect(restoredWordRow['음역1'], 'physical-zeta-transliteration');
        expect(restoredWordRow['발음1'], 'physical-zeta-pronunciation');
        expect(_readMeaningSlots(restoredWordRow).values, everyElement(isNull));
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
      'word history excludes legacy expression relation and meaning slots on undo',
      () async {
        final repository = WordRepository();
        const wordId = 'T9000_1013';
        const relatedWordId = 'T9000_1014';
        const originalNote = 'word history before';
        const updatedNote = 'word history after';
        final relatedColumns = List<String>.generate(
          7,
          (index) => '관련${index + 1}',
          growable: false,
        );
        final meaningColumns = List<String>.generate(
          7,
          (index) => '의미${index + 1}',
          growable: false,
        );
        final expressionColumns = <String>[
          for (final prefix in const ['표기', '음역', '발음'])
            for (var index = 1; index <= 6; index++) '$prefix$index',
        ];

        await repository.createWord(
          id: wordId,
          payload: _payload(
            expressionSets: const [
              CanonicalExpressionWriteSet(
                spelling: 'history-before',
                transliteration: '히스토리 이전',
                pronunciation: null,
                seq: 1,
                isRepresentative: true,
              ),
            ],
            meanings: const ['history before meaning'],
            note: originalNote,
          ),
        );
        await repository.createWord(
          id: relatedWordId,
          payload: _payload(
            expressionSets: const [
              CanonicalExpressionWriteSet(
                spelling: 'history-related',
                transliteration: '히스토리 관계',
                pronunciation: null,
                seq: 1,
                isRepresentative: true,
              ),
            ],
          ),
        );

        final db = await DatabaseService.openDatabaseFile();
        final wordTableColumns = (await db.rawQuery(
          "PRAGMA table_info('WORD_TABLE')",
        )).map((row) => row['name']).whereType<String>().toSet();
        expect(wordTableColumns.intersection(relatedColumns.toSet()), isEmpty);
        final relationId = await db.insert('WORD_RELATION', {
          'word_id_1': wordId,
          'word_id_2': relatedWordId,
          'direction_code': 'unknown',
          'description': 'word history relation invariant',
          'updated_at': DateTime.now().toIso8601String(),
        });

        await repository.updateWord(
          id: wordId,
          payload: _payload(
            expressionSets: const [
              CanonicalExpressionWriteSet(
                spelling: 'history-after',
                transliteration: '히스토리 이후',
                pronunciation: null,
                seq: 1,
                isRepresentative: true,
              ),
            ],
            meanings: const ['history after meaning'],
            note: updatedNote,
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
        final afterSnapshot = await _loadHistorySnapshot(
          historyId,
          'after_json',
        );

        for (final column in relatedColumns) {
          expect(beforeSnapshot.containsKey(column), isFalse);
          expect(afterSnapshot.containsKey(column), isFalse);
        }
        for (final column in meaningColumns) {
          expect(beforeSnapshot.containsKey(column), isFalse);
          expect(afterSnapshot.containsKey(column), isFalse);
        }
        expect(beforeSnapshot, containsPair('id', wordId));
        expect(beforeSnapshot, containsPair('언어', '테스트언어'));
        expect(beforeSnapshot, containsPair('비고', originalNote));
        for (final column in expressionColumns) {
          expect(beforeSnapshot.containsKey(column), isFalse);
        }
        expect(
          beforeSnapshot.containsKey(_historyNormalizedExpressionRowsKey),
          isTrue,
        );
        expect(
          beforeSnapshot.containsKey(_historyNormalizedMeaningRowsKey),
          isTrue,
        );
        expect(afterSnapshot, containsPair('id', wordId));
        expect(afterSnapshot, containsPair('언어', '테스트언어'));
        expect(afterSnapshot, containsPair('비고', updatedNote));
        for (final column in expressionColumns) {
          expect(afterSnapshot.containsKey(column), isFalse);
        }
        expect(
          afterSnapshot.containsKey(_historyNormalizedExpressionRowsKey),
          isTrue,
        );
        expect(
          afterSnapshot.containsKey(_historyNormalizedMeaningRowsKey),
          isTrue,
        );

        for (var index = 1; index <= 7; index++) {
          beforeSnapshot['관련$index'] = 'legacy-related-$index';
          beforeSnapshot['의미$index'] = 'legacy-meaning-$index';
        }
        for (final column in expressionColumns) {
          beforeSnapshot[column] = 'tampered-$column';
        }
        await _writeHistorySnapshot(historyId, 'before_json', beforeSnapshot);

        final relationRowsBeforeUndo = (await db.query(
          'WORD_RELATION',
          where: 'word_id_1 = ? OR word_id_2 = ?',
          whereArgs: [wordId, wordId],
          orderBy: 'id ASC',
        )).map(Map<String, dynamic>.from).toList(growable: false);
        expect(relationRowsBeforeUndo, hasLength(1));
        expect(relationRowsBeforeUndo.single['id'], relationId);

        final undone = await repository.undoLastChange();
        expect(undone.didUndo, isTrue);

        final restoredWordRow = await _loadWordTableRow(wordId);
        expect(
          _readExpressionSlots(restoredWordRow).values,
          everyElement(isNull),
        );
        expect(restoredWordRow['비고'], originalNote);
        for (final column in relatedColumns) {
          expect(restoredWordRow.containsKey(column), isFalse);
        }
        expect(
          meaningColumns.map((column) => restoredWordRow[column]),
          everyElement(isNull),
        );
        expect(await _loadActualMeaningRows(wordId), [
          (wordId: wordId, seq: 1, meaning: 'history before meaning'),
        ]);
        expect(
          (await _loadActualSemanticRows(wordId)).single.spelling,
          'history-before',
        );

        final relationRowsAfterUndo = (await db.query(
          'WORD_RELATION',
          where: 'word_id_1 = ? OR word_id_2 = ?',
          whereArgs: [wordId, wordId],
          orderBy: 'id ASC',
        )).map(Map<String, dynamic>.from).toList(growable: false);
        expect(relationRowsAfterUndo, relationRowsBeforeUndo);
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

        final restoredNormalizedRows = await _loadActualSemanticRows(wordId);
        expect(restoredNormalizedRows.first.spelling, 'legacy-only-restore');
        expect(restoredNormalizedRows.first.transliteration, '레거시 음역');
        expect(restoredNormalizedRows.first.pronunciation, 'legacy-pron');
        final restoredMeaningRows = await _loadActualMeaningRows(wordId);
        expect(restoredMeaningRows, [
          (wordId: wordId, seq: 1, meaning: '레거시 의미'),
          (wordId: wordId, seq: 7, meaning: '레거시 일곱째 의미'),
        ]);
        expect(
          _readMeaningSlots(await _loadWordTableRow(wordId)).values,
          everyElement(isNull),
        );
        expect(
          _readExpressionSlots(await _loadWordTableRow(wordId)).values,
          everyElement(isNull),
        );
      },
    );

    test(
      'legacy-only delete history restores canonical meanings without legacy DML',
      () async {
        final repository = WordRepository();
        const wordId = 'T9000_1016';

        await repository.createWord(
          id: wordId,
          payload: _payload(
            expressionSets: const [
              CanonicalExpressionWriteSet(
                spelling: 'legacy-delete-restore',
                transliteration: null,
                pronunciation: null,
                seq: 1,
                isRepresentative: true,
              ),
            ],
            meanings: const ['canonical value replaced by legacy snapshot'],
          ),
        );
        await repository.deleteWord(wordId);

        final historyId = await _loadLatestWordHistoryId(
          wordId: wordId,
          actionType: 'delete',
        );
        final beforeSnapshot = await _loadHistorySnapshot(
          historyId,
          'before_json',
        );
        beforeSnapshot.remove(_historyNormalizedExpressionRowsKey);
        beforeSnapshot.remove(_historyNormalizedMeaningRowsKey);
        beforeSnapshot['표기1'] = 'legacy-delete-expression';
        beforeSnapshot['음역1'] = '레거시 삭제 음역';
        beforeSnapshot['발음1'] = 'legacy-delete-pronunciation';
        beforeSnapshot['의미1'] = '삭제 복원 레거시 의미';
        beforeSnapshot['의미4'] = '삭제 복원 네 번째 의미';
        await _writeHistorySnapshot(historyId, 'before_json', beforeSnapshot);

        final undone = await repository.undoLastChange();
        expect(undone.didUndo, isTrue);

        expect(await _loadActualMeaningRows(wordId), [
          (wordId: wordId, seq: 1, meaning: '삭제 복원 레거시 의미'),
          (wordId: wordId, seq: 4, meaning: '삭제 복원 네 번째 의미'),
        ]);
        expect(await _loadActualSemanticRows(wordId), [
          (
            wordId: wordId,
            seq: 1,
            isRepresentative: 1,
            spelling: 'legacy-delete-expression',
            transliteration: '레거시 삭제 음역',
            pronunciation: 'legacy-delete-pronunciation',
          ),
        ]);
        expect(
          _readMeaningSlots(await _loadWordTableRow(wordId)).values,
          everyElement(isNull),
        );
        expect(
          _readExpressionSlots(await _loadWordTableRow(wordId)).values,
          everyElement(isNull),
        );
      },
    );

    test(
      'updateWord rolls back all writes when canonical meaning insert fails',
      () async {
        final repository = WordRepository();
        const wordId = 'T9000_1008';
        const rejectedMeaning = 'rollback canonical meaning failure';
        const triggerName = 'meaning_canonical_write_failure';
        const failureSentinel = 'canonical meaning write failure sentinel';

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
        final beforeWordRow = await _loadWordTableRow(wordId);
        final beforeExpressionRows = await _loadActualSemanticRows(wordId);
        final beforeMeaningRows = await _loadActualMeaningRows(wordId);
        final historyRowsBefore = await db.query(
          'CHANGE_HISTORY',
          columns: const ['id'],
          where: 'entity_type = ? AND entity_id = ?',
          whereArgs: ['word', wordId],
        );

        await db.execute('''
CREATE TEMP TRIGGER "$triggerName"
BEFORE INSERT ON "word_meaning_set"
WHEN NEW."word_id" = '$wordId' AND NEW."meaning" = '$rejectedMeaning'
BEGIN
  SELECT RAISE(ABORT, '$failureSentinel');
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
              meanings: const [rejectedMeaning],
            ),
          );
        } catch (error) {
          updateError = error;
        } finally {
          await db.execute('DROP TRIGGER IF EXISTS "$triggerName"');
        }

        expect(updateError, isNotNull);
        expect(updateError.toString(), contains(failureSentinel));
        expect(await _loadWordTableRow(wordId), beforeWordRow);
        expect(await _loadActualSemanticRows(wordId), beforeExpressionRows);
        expect(await _loadActualMeaningRows(wordId), beforeMeaningRows);
        final historyRowsAfter = await db.query(
          'CHANGE_HISTORY',
          columns: const ['id'],
          where: 'entity_type = ? AND entity_id = ?',
          whereArgs: ['word', wordId],
        );
        expect(historyRowsAfter, historyRowsBefore);
      },
    );
  });
}

Future<Directory> _createIsolatedWorkspace(String sourceSeedDbPath) async {
  final isolatedRoot = await Directory.systemTemp.createTemp(
    'reshet_dual_sync_tests_',
  );
  final dataDir = Directory(p.join(isolatedRoot.path, 'data'));
  await dataDir.create(recursive: true);

  await File(sourceSeedDbPath).copy(p.join(dataDir.path, 'reshet_seed.db'));

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

void _expectNoLegacyMeaningKeys(Map<String, dynamic> snapshot) {
  for (var index = 1; index <= 7; index++) {
    expect(snapshot.containsKey('의미$index'), isFalse);
  }
}

void _expectNoLegacyExpressionKeys(Map<String, dynamic> snapshot) {
  for (final prefix in const ['표기', '음역', '발음']) {
    for (var index = 1; index <= 6; index++) {
      expect(snapshot.containsKey('$prefix$index'), isFalse);
    }
  }
}

Future<void> _dropLegacyExpressionColumns(dynamic db) async {
  for (final prefix in const ['표기', '음역', '발음']) {
    for (var index = 1; index <= 6; index++) {
      await db.execute('ALTER TABLE WORD_TABLE DROP COLUMN "$prefix$index"');
    }
  }
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

Map<String, Object?> _readExpressionSlots(Map<String, dynamic> wordRow) {
  return {
    for (final prefix in const ['표기', '음역', '발음'])
      for (var index = 1; index <= 6; index++)
        '$prefix$index': wordRow['$prefix$index'],
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
