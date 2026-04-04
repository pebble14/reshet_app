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

        final actualRows = await _loadActualSemanticRows(wordId);
        expect(actualRows, hasLength(2));
        expect(actualRows.first.spelling, 'beth');
        expect(actualRows.first.isRepresentative, 1);
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

        expect(deletedWord, isNull);
        expect(remainingRows, isEmpty);

        final undone = await repository.undoLastChange();
        expect(undone, isTrue);

        await _expectSemanticSync(wordId);
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
      expect(undone, isTrue);

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

      final undone = await repository.undoLastChange();
      expect(undone, isTrue);

      await _expectSemanticSync(wordId);

      final actualRows = await _loadActualSemanticRows(wordId);
      expect(actualRows, hasLength(2));
      expect(actualRows.first.spelling, 'epsilon');
      expect(actualRows.first.isRepresentative, 1);
    });
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
