import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/expression/read_source_policy.dart';
import 'package:reshet_app/domain/home/home_default_strong_list_item.dart';

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
          'Phase 8-H-5 home strong display contract test needs the seed work DB.',
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

  group('Phase 8-H-5 home default strong list display contract first slice', () {
    test(
      'projects the default strong list into the minimal typed display contract',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_H5_HOME_STRONG_CONTRACT';
        const storedStrongNumber = 'h900001';

        await _insertWord(
          db,
          id: wordId,
          strongNumber: storedStrongNumber,
          legacySpelling: 'legacy-home-title',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'representative-home-title',
            },
          ],
        );

        final items = await repository.getStrongWordsMap();

        expect(items, isNotEmpty);
        final item = items.singleWhere((entry) => entry.wordId == wordId);
        expect(item, isA<HomeDefaultStrongListItem>());
        expect(item.displayStrongNumber, 'H900001');
        expect(item.representativeSpelling, 'representative-home-title');
      },
    );

    test(
      'keeps the legacy visible contract when normalized expression rows are unavailable',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_H5_HOME_STRONG_LEGACY_FALLBACK';

        await _insertWord(
          db,
          id: wordId,
          strongNumber: 'G900002',
          legacySpelling: 'legacy-visible-title',
          expressionRows: const [],
        );

        final items = await repository.getStrongWordsMap();
        final snapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (entry) =>
                  entry.wordId == wordId && entry.context == 'getStrongWordsMap',
            );

        final item = items.singleWhere((entry) => entry.wordId == wordId);
        expect(item.displayStrongNumber, 'G900002');
        expect(item.representativeSpelling, 'legacy-visible-title');
        expect(
          snapshot.finalResultSource,
          FinalReadResultSource.legacyFallback,
        );
        expect(
          snapshot.fallbackObservation?.reason,
          ReadFallbackReason.emptyResult,
        );
      },
    );
  });
}

Future<Directory> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(
    p.join(repoRootPath, '.tmp_phase8h5_home_strong_display_contract_tests'),
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
  required String legacySpelling,
  required List<Map<String, Object?>> expressionRows,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
    '\uC2A4\uD2B8\uB871\uB118\uBC84': strongNumber,
    '\uD45C\uAE301': legacySpelling,
    '\uC758\uBBF81': 'phase8h5 home strong item',
  });

  for (final row in expressionRows) {
    await db.insert('word_expression_set', {'word_id': id, ...row});
  }
}
