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
          'Phase 8-H-12 home search ranking contract test needs the seed work DB.',
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
  });
}

Future<Directory> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(
    p.join(repoRootPath, '.tmp_phase8h12_home_search_ranking_contract_tests'),
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
}
