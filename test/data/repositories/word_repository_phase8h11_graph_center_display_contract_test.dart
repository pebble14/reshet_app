import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/graph/graph_center_word_display_item.dart';

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
          'Phase 8-H-11 graph center display contract test needs the seed work DB.',
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

  group('Phase 8-H-11 graph center display contract first slice', () {
    test(
      'projects center node full display into the minimal typed contract',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_H11_GRAPH_CENTER_CONTRACT';

        await _insertWord(
          db,
          id: wordId,
          language: ' test-language ',
          strongNumber: 'h00042',
          legacySpelling: 'legacy-center-spelling',
          legacyTransliteration: 'legacy-center-translit',
          legacyPronunciation: 'legacy-center-pron',
          meaning1: ' primary center meaning ',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'representative-center-spelling',
              'transliteration': 'representative-center-translit',
              'pronunciation': 'representative-center-pron',
            },
          ],
        );

        final item = await repository
            .getGraphCenterWordDisplayItemByIdForGraphCenterSingleWord(wordId);

        expect(item, isA<GraphCenterWordDisplayItem>());
        expect(item!.wordId, wordId);
        expect(item.language, 'test-language');
        expect(item.displayStrongNumber, 'H42');
        expect(item.representativeSpelling, 'representative-center-spelling');
        expect(
          item.representativeTransliteration,
          'representative-center-translit',
        );
        expect(item.representativePronunciation, 'representative-center-pron');
        expect(item.primaryMeaning, 'primary center meaning');
      },
    );

    test(
      'falls back to the first normalized expression only when representative row is absent',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_H11_GRAPH_CENTER_FALLBACK';

        await _insertWord(
          db,
          id: wordId,
          legacySpelling: 'legacy-fallback-spelling',
          legacyTransliteration: 'legacy-fallback-translit',
          legacyPronunciation: 'legacy-fallback-pron',
          meaning1: 'fallback meaning',
          expressionRows: const [
            {
              'seq': 2,
              'is_representative': 0,
              'spelling': 'second-normalized-spelling',
              'transliteration': 'second-normalized-translit',
              'pronunciation': 'second-normalized-pron',
            },
            {
              'seq': 1,
              'is_representative': 0,
              'spelling': 'first-normalized-spelling',
              'transliteration': 'first-normalized-translit',
              'pronunciation': 'first-normalized-pron',
            },
          ],
        );

        final item = await repository
            .getGraphCenterWordDisplayItemByIdForGraphCenterSingleWord(wordId);

        expect(item, isNotNull);
        expect(item!.representativeSpelling, 'first-normalized-spelling');
        expect(item.representativeTransliteration, 'first-normalized-translit');
        expect(item.representativePronunciation, 'first-normalized-pron');
        expect(item.primaryMeaning, 'fallback meaning');
      },
    );
  });
}

Future<Directory> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(
    p.join(repoRootPath, '.tmp_phase8h11_graph_center_display_contract_tests'),
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
  String language = 'test',
  String? strongNumber,
  required String legacySpelling,
  required String legacyTransliteration,
  required String legacyPronunciation,
  required String meaning1,
  required List<Map<String, Object?>> expressionRows,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '\uC5B8\uC5B4': language,
    '\uC2A4\uD2B8\uB871\uB118\uBC84': strongNumber,
    '\uD45C\uAE301': legacySpelling,
    '\uC74C\uC5ED1': legacyTransliteration,
    '\uBC1C\uC74C1': legacyPronunciation,
    '\uC758\uBBF81': meaning1,
  });

  for (final row in expressionRows) {
    await db.insert('word_expression_set', {'word_id': id, ...row});
  }
}
