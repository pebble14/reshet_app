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
          'Phase 8-H-12 home search ranking contract test needs the seed work DB.',
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

  group('Phase 8-H-12 home search ranking candidate contract first slice', () {
    test(
      'keeps strong, spelling, and meaning ranking priority while returning display items',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const keyword = 'H812120';
        const strongExactWordId = 'T9000_H12_RANK_1_STRONG_EXACT';
        const strongPrefixWordId = 'T9000_H12_RANK_2_STRONG_PREFIX';
        const spellingExactWordId = 'T9000_H12_RANK_3_SPELLING_EXACT';
        const meaningPartialWordId = 'T9000_H12_RANK_4_MEANING_PARTIAL';
        const targetWordIds = <String>{
          strongExactWordId,
          strongPrefixWordId,
          spellingExactWordId,
          meaningPartialWordId,
        };

        await _insertWord(
          db,
          id: strongExactWordId,
          strongNumber: 'h812120',
          spelling1: 'strong exact title',
          meaning1: 'strong exact meaning',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'strong exact title',
            },
          ],
        );
        await _insertWord(
          db,
          id: strongPrefixWordId,
          strongNumber: 'H8121209',
          spelling1: 'strong prefix title',
          meaning1: 'strong prefix meaning',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'strong prefix title',
            },
          ],
        );
        await _insertWord(
          db,
          id: spellingExactWordId,
          spelling1: keyword,
          meaning1: 'spelling exact meaning',
          expressionRows: const [
            {'seq': 1, 'is_representative': 1, 'spelling': keyword},
          ],
        );
        await _insertWord(
          db,
          id: meaningPartialWordId,
          spelling1: 'meaning partial title',
          meaning1: 'meaning partial $keyword marker',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'meaning partial title',
            },
          ],
        );

        final items = await repository.searchWordsMap(keyword, limit: 20);
        final targetItems = items
            .where((item) => targetWordIds.contains(item.wordId))
            .toList(growable: false);

        expect(targetItems, hasLength(4));
        expect(
          targetItems.map((item) => item.wordId),
          equals(const [
            strongExactWordId,
            strongPrefixWordId,
            spellingExactWordId,
            meaningPartialWordId,
          ]),
        );
        expect(targetItems, everyElement(isA<HomeSearchResultDisplayItem>()));
        expect(targetItems.first.displayStrongNumber, keyword);
        expect(targetItems.first.representativeSpelling, 'strong exact title');
        expect(
          targetItems.last.subtitleMeaning,
          'meaning partial $keyword marker',
        );
      },
    );

    test(
      'keeps indexed spelling field order ahead of id tie-break order',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const keyword = 'phase8h12-slot-order-token';
        const fieldIndexTwoWordId = 'T9000_H12_FIELD_A_SLOT2';
        const fieldIndexOneWordId = 'T9000_H12_FIELD_Z_SLOT1';
        const targetWordIds = <String>{
          fieldIndexTwoWordId,
          fieldIndexOneWordId,
        };

        await _insertWord(
          db,
          id: fieldIndexTwoWordId,
          spelling1: 'field two visible title',
          spelling2: keyword,
          meaning1: 'field two meaning',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'field two visible title',
            },
            {'seq': 2, 'is_representative': 0, 'spelling': keyword},
          ],
        );
        await _insertWord(
          db,
          id: fieldIndexOneWordId,
          spelling1: keyword,
          meaning1: 'field one meaning',
          expressionRows: const [
            {'seq': 1, 'is_representative': 1, 'spelling': keyword},
          ],
        );

        final items = await repository.searchWordsMap(keyword, limit: 20);
        final targetItems = items
            .where((item) => targetWordIds.contains(item.wordId))
            .toList(growable: false);

        expect(targetItems, hasLength(2));
        expect(
          targetItems.map((item) => item.wordId),
          equals(const [fieldIndexOneWordId, fieldIndexTwoWordId]),
        );
      },
    );

    test('finds a word once by its 8th canonical meaning', () async {
      final repository = WordRepository();
      final db = await DatabaseService.openDatabaseFile();
      const wordId = 'T9000_H12_MEANING8_ONCE';
      const keyword = 'phase32-home-canonical-meaning-08';

      await _insertWord(
        db,
        id: wordId,
        spelling1: 'phase32 home meaning title',
        meaning1: 'phase32 home meaning 1',
        expressionRows: const [
          {
            'seq': 1,
            'is_representative': 1,
            'spelling': 'phase32 home meaning title',
          },
        ],
      );
      for (var index = 2; index <= 8; index++) {
        await db.insert('word_meaning_set', {
          'word_id': wordId,
          'seq': index,
          'meaning': index == 8 ? keyword : 'phase32 home meaning $index',
        });
      }

      final items = await repository.searchWordsMap(keyword, limit: 20);
      final targetItems = items
          .where((item) => item.wordId == wordId)
          .toList(growable: false);

      expect(targetItems, hasLength(1));
      expect(targetItems.single.subtitleMeaning, 'phase32 home meaning 1');
    });

    test(
      'finds a word once by its 7th canonical spelling and transliteration',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_H12_EXPR7_ONCE';
        const spellingKeyword = 'phase33-home-spelling-07';
        const transliterationKeyword = 'phase33-home-trans-07';

        await _insertWord(
          db,
          id: wordId,
          spelling1: 'phase33 home representative',
          meaning1: 'phase33 home expression seven',
          expressionRows: [
            for (var index = 1; index <= 7; index++)
              {
                'seq': index,
                'is_representative': index == 1 ? 1 : 0,
                'spelling': index == 7
                    ? spellingKeyword
                    : 'phase33-home-spelling-0$index',
                'transliteration': index == 7
                    ? transliterationKeyword
                    : 'phase33-home-trans-0$index',
              },
          ],
        );

        final spellingItems = await repository.searchWordsMap(
          spellingKeyword,
          limit: 20,
        );
        final transliterationItems = await repository.searchWordsMap(
          transliterationKeyword,
          limit: 20,
        );

        final spellingMatches = spellingItems
            .where((item) => item.wordId == wordId)
            .toList(growable: false);
        final transliterationMatches = transliterationItems
            .where((item) => item.wordId == wordId)
            .toList(growable: false);

        expect(spellingMatches, hasLength(1));
        expect(transliterationMatches, hasLength(1));
        expect(
          spellingMatches.single.representativeSpelling,
          'phase33-home-spelling-01',
        );
        expect(
          transliterationMatches.single.representativeSpelling,
          'phase33-home-spelling-01',
        );
      },
    );
  });
}

Future<Directory> _createIsolatedWorkspace(
  String sourceWorkDbPath,
  String sourceSeedDbPath,
) async {
  final isolatedRoot = await Directory.systemTemp.createTemp(
    'reshet_phase8h12_home_search_ranking_contract_tests_',
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
  String? strongNumber,
  required String spelling1,
  String? spelling2,
  required String meaning1,
  required List<Map<String, Object?>> expressionRows,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '언어': '테스트',
    '스트롱넘버': strongNumber,
    '표기1': spelling1,
    '표기2': spelling2,
    '의미1': meaning1,
  });

  for (final row in expressionRows) {
    await db.insert('word_expression_set', {'word_id': id, ...row});
  }
  await db.insert('word_meaning_set', {
    'word_id': id,
    'seq': 1,
    'meaning': meaning1,
  });
}
