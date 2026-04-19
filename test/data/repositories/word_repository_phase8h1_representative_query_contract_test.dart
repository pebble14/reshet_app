import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/word/duplicate_candidate_display_item.dart';

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
      reason:
          'Phase 8-H-1 representative query contract test needs the seed work DB.',
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

  group('Phase 8-H-1 representative query contract first slice', () {
    test(
      'collision query uses representative values and does not fall back to legacy transliteration when representative row is blank',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordIdA = 'T9000_H1_COLLISION_A';
        const wordIdB = 'T9000_H1_COLLISION_B';
        const wordIdC = 'T9000_H1_COLLISION_C';

        await _insertWord(
          db,
          id: wordIdA,
          language: '테스트',
          legacySpelling: 'legacy-shared-slot',
          legacyTransliteration: 'legacy-shared-translit',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'shared-representative',
              'transliteration': 'shared-translit',
            },
          ],
        );
        await _insertWord(
          db,
          id: wordIdB,
          language: '테스트',
          legacySpelling: 'legacy-other-slot',
          legacyTransliteration: 'legacy-other-translit',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'shared-representative',
              'transliteration': 'shared-translit',
            },
          ],
        );
        await _insertWord(
          db,
          id: wordIdC,
          language: '테스트',
          legacySpelling: 'shared-representative',
          legacyTransliteration: 'shared-translit',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'shared-representative',
              'transliteration': null,
            },
          ],
        );

        final collisionWordIds = await repository
            .findWordIdsInDbWideLanguageSpellingTransliterationCollisionGroups([
              wordIdA,
              wordIdB,
              wordIdC,
            ]);

        expect(collisionWordIds, containsAll(<String>{wordIdA, wordIdB}));
        expect(collisionWordIds, isNot(contains(wordIdC)));
      },
    );

    test(
      'collision query falls back to the first normalized set only when the representative row is absent',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordIdA = 'T9000_H1_COLLISION_FALLBACK_A';
        const wordIdB = 'T9000_H1_COLLISION_FALLBACK_B';

        await _insertWord(
          db,
          id: wordIdA,
          language: '테스트',
          legacySpelling: 'legacy-fallback-a',
          legacyTransliteration: 'legacy-fallback-a',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 0,
              'spelling': 'fallback-shared',
              'transliteration': 'fallback-translit',
            },
            {
              'seq': 2,
              'is_representative': 0,
              'spelling': 'fallback-alt-a',
              'transliteration': 'fallback-alt-a',
            },
          ],
        );
        await _insertWord(
          db,
          id: wordIdB,
          language: '테스트',
          legacySpelling: 'legacy-fallback-b',
          legacyTransliteration: 'legacy-fallback-b',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 0,
              'spelling': 'fallback-shared',
              'transliteration': 'fallback-translit',
            },
            {
              'seq': 2,
              'is_representative': 0,
              'spelling': 'fallback-alt-b',
              'transliteration': 'fallback-alt-b',
            },
          ],
        );

        final collisionWordIds = await repository
            .findWordIdsInDbWideLanguageSpellingTransliterationCollisionGroups([
              wordIdA,
              wordIdB,
            ]);

        expect(collisionWordIds, equals(<String>{wordIdA, wordIdB}));
      },
    );

    test(
      'duplicate candidates keep strong priority and project representative spelling',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_H1_DUPLICATE_STRONG';
        const strongNumber = 'H999901';

        await _insertWord(
          db,
          id: wordId,
          language: '헬라어',
          strongNumber: strongNumber,
          legacySpelling: 'legacy-strong-slot',
          legacyTransliteration: 'legacy-strong-translit',
          meaning1: 'strong meaning',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'representative-strong',
              'transliteration': 'rep-strong',
            },
          ],
        );

        final candidates = await repository.findDuplicateCandidates(
          language: '다른언어',
          strongNumber: strongNumber,
          spelling1: 'totally-different-spelling',
        );

        expect(candidates, hasLength(1));
        expect(candidates.single, isA<DuplicateCandidateDisplayItem>());
        expect(candidates.single.wordId, wordId);
        expect(candidates.single.language, '헬라어');
        expect(candidates.single.strongNumber, strongNumber);
        expect(
          candidates.single.representativeSpelling,
          'representative-strong',
        );
        expect(candidates.single.primaryMeaning, 'strong meaning');
      },
    );

    test(
      'duplicate candidates match normalized strong display input',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_H1_DUPLICATE_NORMALIZED_STRONG';
        const storedStrongNumber = 'H000077';

        await _insertWord(
          db,
          id: wordId,
          language: '테스트',
          strongNumber: storedStrongNumber,
          legacySpelling: 'legacy-normalized-strong-slot',
          legacyTransliteration: 'legacy-normalized-strong-translit',
          meaning1: 'normalized strong meaning',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'representative-normalized-strong',
              'transliteration': 'rep-normalized-strong',
            },
          ],
        );

        final candidates = await repository.findDuplicateCandidates(
          language: '다른언어',
          strongNumber: 'H77',
          spelling1: 'totally-different-spelling',
        );

        expect(candidates, hasLength(1));
        expect(candidates.single.wordId, wordId);
        expect(candidates.single.strongNumber, storedStrongNumber);
        expect(
          candidates.single.representativeSpelling,
          'representative-normalized-strong',
        );
        expect(candidates.single.primaryMeaning, 'normalized strong meaning');
      },
    );

    test(
      'duplicate candidates use representative spelling for non-strong matches',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_H1_DUPLICATE_NON_STRONG';

        await _insertWord(
          db,
          id: wordId,
          language: '히브리어',
          legacySpelling: 'legacy-kfar-slot',
          legacyTransliteration: 'legacy-kfar-translit',
          meaning1: 'non strong meaning',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'כְּפַר',
              'transliteration': 'kfar',
            },
          ],
        );

        final candidates = await repository.findDuplicateCandidates(
          language: '히브리어',
          spelling1: 'כפר',
        );

        expect(candidates, hasLength(1));
        expect(candidates.single, isA<DuplicateCandidateDisplayItem>());
        expect(candidates.single.wordId, wordId);
        expect(candidates.single.language, '히브리어');
        expect(candidates.single.strongNumber, '');
        expect(candidates.single.representativeSpelling, 'כְּפַר');
        expect(candidates.single.primaryMeaning, 'non strong meaning');
      },
    );

    test(
      'duplicate candidates scan all same-language rows before non-strong match',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const language = 'phase8h1-non-strong-limit-language';
        const wordId = 'T9000_H1_DUPLICATE_NON_STRONG_AFTER_LIMIT';

        for (var index = 0; index < 205; index += 1) {
          await _insertWord(
            db,
            id: 'T9000_H1_NON_STRONG_FILLER_$index',
            language: language,
            legacySpelling: 'legacy-filler-$index',
            legacyTransliteration: 'legacy-filler-translit-$index',
            meaning1: 'filler meaning $index',
            expressionRows: [
              {
                'seq': 1,
                'is_representative': 1,
                'spelling': 'filler-spelling-$index',
                'transliteration': 'filler-translit-$index',
              },
            ],
          );
        }

        await _insertWord(
          db,
          id: wordId,
          language: ' $language ',
          legacySpelling: 'legacy-late-target-slot',
          legacyTransliteration: 'legacy-late-target-translit',
          meaning1: 'late non strong meaning',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'late-representative-spelling',
              'transliteration': 'late-rep',
            },
          ],
        );

        final candidates = await repository.findDuplicateCandidates(
          language: language,
          spelling1: 'late-representative-spelling',
        );

        expect(candidates, hasLength(1));
        expect(candidates.single.wordId, wordId);
        expect(candidates.single.language, language);
        expect(candidates.single.strongNumber, '');
        expect(
          candidates.single.representativeSpelling,
          'late-representative-spelling',
        );
        expect(candidates.single.primaryMeaning, 'late non strong meaning');
      },
    );
  });
}

Future<Directory> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(
    p.join(repoRootPath, '.tmp_phase8h1_representative_query_contract_tests'),
  );
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

Future<void> _insertWord(
  dynamic db, {
  required String id,
  required String language,
  String? strongNumber,
  required String legacySpelling,
  String? legacyTransliteration,
  String? meaning1,
  required List<Map<String, Object?>> expressionRows,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '언어': language,
    '스트롱넘버': strongNumber,
    '표기1': legacySpelling,
    '음역1': legacyTransliteration,
    '의미1': meaning1,
  });

  for (final row in expressionRows) {
    await db.insert('word_expression_set', {'word_id': id, ...row});
  }
}
