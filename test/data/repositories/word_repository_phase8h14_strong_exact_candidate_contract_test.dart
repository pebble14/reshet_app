import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/home/home_search_result_display_item.dart';

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
      reason:
          'Phase 8-H-14 strong exact candidate contract test needs the seed work DB.',
    );
    expect(File(sourceSeedDbPath).existsSync(), isTrue);

    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    WordRepository.debugSetReadSourcePolicyOverride(null);
    WordRepository.debugReadSourceCollector.debugReset();
    isolatedRoot = await _createIsolatedWorkspace(
      sourceWorkDbPath,
      sourceSeedDbPath,
    );
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
    WordRepository.debugSetReadSourcePolicyOverride(null);
    WordRepository.debugReadSourceCollector.debugReset();

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await isolatedRoot!.delete(recursive: true);
    }
  });

  group('Phase 8-H-14 home strong exact candidate contract first slice', () {
    test('fails closed for actual project database targets', () {
      expect(
        () => ensureSystemTempDatabaseTargets(
          dataRootPath: p.join(repoRootPath, 'data'),
          actualWorkDbPath: sourceWorkDbPath,
          actualSeedDbPath: sourceSeedDbPath,
        ),
        throwsStateError,
      );
    });

    test(
      'keeps zero-padded strong exact matching without strong prefix false positives',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        final wordColumns = (await db.rawQuery(
          "PRAGMA table_info('WORD_TABLE')",
        )).map((row) => row['name']).whereType<String>().toSet();
        expect(
          wordColumns.intersection(const {
            '의미1',
            '의미2',
            '의미3',
            '의미4',
            '의미5',
            '의미6',
            '의미7',
          }),
          isEmpty,
        );
        const keyword = 'H814140';
        const firstWordId = 'T9000_H14_STRONG_EXACT_A';
        const secondWordId = 'T9000_H14_STRONG_EXACT_B';
        const falsePositiveWordId = 'T9000_H14_STRONG_FALSE_POSITIVE';
        const targetWordIds = <String>{
          firstWordId,
          secondWordId,
          falsePositiveWordId,
        };

        await _insertWord(
          db,
          id: secondWordId,
          strongNumber: 'h0814140',
          spelling1: 'legacy-second-title',
          canonicalMeaning: 'canonical second meaning',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'representative-second-title',
            },
          ],
        );
        await _insertWord(
          db,
          id: firstWordId,
          strongNumber: 'H814140',
          spelling1: 'legacy-first-title',
          canonicalMeaning: 'canonical first meaning',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'representative-first-title',
            },
          ],
        );
        await _insertWord(
          db,
          id: falsePositiveWordId,
          strongNumber: 'H8141400',
          spelling1: 'false-positive-title',
          canonicalMeaning: 'canonical false positive meaning',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'false-positive-title',
            },
          ],
        );

        final items = await repository.searchStrongExactMap(keyword, limit: 20);
        final targetItems = items
            .where((item) => targetWordIds.contains(item.wordId))
            .toList(growable: false);

        expect(targetItems, everyElement(isA<HomeSearchResultDisplayItem>()));
        expect(
          targetItems.map((item) => item.wordId),
          equals(const [firstWordId, secondWordId]),
        );
        expect(targetItems.map((item) => item.displayStrongNumber), [
          keyword,
          keyword,
        ]);
        expect(
          targetItems.map((item) => item.representativeSpelling),
          equals(const [
            'representative-first-title',
            'representative-second-title',
          ]),
        );
        expect(targetItems.map((item) => item.subtitleMeaning), [
          'canonical first meaning',
          'canonical second meaning',
        ]);
        expect(
          items.map((item) => item.wordId),
          isNot(contains(falsePositiveWordId)),
        );

        final snapshots = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .where(
              (snapshot) =>
                  snapshot.context == 'searchStrongExactMap' &&
                  {firstWordId, secondWordId}.contains(snapshot.wordId),
            )
            .toList(growable: false);
        expect(snapshots, hasLength(2));
      },
    );
  });
}

Future<Directory> _createIsolatedWorkspace(
  String sourceWorkDbPath,
  String sourceSeedDbPath,
) async {
  final isolatedRoot = await Directory.systemTemp.createTemp(
    'reshet_phase8h14_strong_exact_candidate_tests_',
  );

  final dataDir = Directory(p.join(isolatedRoot.path, 'data'));
  await dataDir.create(recursive: true);

  await File(sourceSeedDbPath).copy(p.join(dataDir.path, 'reshet_seed.db'));
  await File(sourceWorkDbPath).copy(p.join(dataDir.path, 'reshet_work.db'));

  return isolatedRoot;
}

Future<void> _insertWord(
  dynamic db, {
  required String id,
  required String strongNumber,
  required String spelling1,
  required String canonicalMeaning,
  required List<Map<String, Object?>> expressionRows,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '언어': '테스트',
    '스트롱넘버': strongNumber,
    '표기1': spelling1,
  });

  for (final row in expressionRows) {
    await db.insert('word_expression_set', {'word_id': id, ...row});
  }
  await db.insert('word_meaning_set', {
    'word_id': id,
    'seq': 1,
    'meaning': canonicalMeaning,
  });
}
