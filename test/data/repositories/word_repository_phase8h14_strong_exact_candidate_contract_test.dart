import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/home/home_search_result_display_item.dart';

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
          'Phase 8-H-14 strong exact candidate contract test needs the seed work DB.',
    );

    await DatabaseService.closeDatabase();
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    WordRepository.debugSetReadSourcePolicyOverride(null);
    WordRepository.debugReadSourceCollector.debugReset();
    isolatedRoot = await _createIsolatedWorkspace(
      repoRootPath,
      sourceWorkDbPath,
    );
    Directory.current = isolatedRoot!.path;
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    WordRepository.debugSetReadSourcePolicyOverride(null);
    WordRepository.debugReadSourceCollector.debugReset();
    Directory.current = repoRootPath;

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await isolatedRoot!.delete(recursive: true);
    }
  });

  group('Phase 8-H-14 home strong exact candidate contract first slice', () {
    test(
      'keeps zero-padded strong exact matching without strong prefix false positives',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
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
          meaning1: 'second meaning',
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
          meaning1: 'first meaning',
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
          meaning1: 'false positive meaning',
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
          equals(const ['legacy-first-title', 'legacy-second-title']),
        );
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
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(
    p.join(repoRootPath, '.tmp_phase8h14_strong_exact_candidate_tests'),
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
  required String strongNumber,
  required String spelling1,
  required String meaning1,
  required List<Map<String, Object?>> expressionRows,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '언어': '테스트',
    '스트롱넘버': strongNumber,
    '표기1': spelling1,
    '의미1': meaning1,
  });

  for (final row in expressionRows) {
    await db.insert('word_expression_set', {'word_id': id, ...row});
  }
}
