import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/graph/graph_relation_add_search_result_item.dart';

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
          'Phase 8-H-4 graph relation add search contract test needs the seed work DB.',
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

  group('Phase 8-H-4 graph relation add search contract first slice', () {
    test(
      'keeps legacy search semantics while projecting representative spelling into the typed result',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_H4_GRAPH_SEARCH_SPELLING';

        await _insertWord(
          db,
          id: wordId,
          legacySpelling: 'legacy-spelling-match',
          meaning1: 'graph relation meaning',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'representative-title',
            },
          ],
        );

        final results = await repository.searchWords(
          'legacy-spelling-match',
          limit: 20,
        );

        expect(results, hasLength(1));
        expect(results.single, isA<GraphRelationAddSearchResultItem>());
        expect(results.single.wordId, wordId);
        expect(results.single.representativeSpelling, 'representative-title');
        expect(results.single.primaryMeaning, 'graph relation meaning');
        expect(results.single.displayStrongNumber, '');
      },
    );

    test(
      'keeps meaning and strong number display fields in the minimal typed contract',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_H4_GRAPH_SEARCH_STRONG';
        const strongNumber = 'PH8H4_STRONG_UNIQUE_314159';

        await _insertWord(
          db,
          id: wordId,
          strongNumber: strongNumber,
          legacySpelling: 'legacy-non-match',
          meaning1: 'strong meaning',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'representative-strong-title',
            },
          ],
        );

        final results = await repository.searchWords(strongNumber, limit: 20);

        expect(results, hasLength(1));
        expect(results.single.wordId, wordId);
        expect(
          results.single.representativeSpelling,
          'representative-strong-title',
        );
        expect(results.single.primaryMeaning, 'strong meaning');
        expect(results.single.displayStrongNumber, strongNumber);
      },
    );

    test(
      'finds relation add candidates by the 8th canonical meaning',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_H4_GRAPH_SEARCH_MEANING8';
        const keyword = 'phase32-graph-canonical-meaning-08';

        await _insertWord(
          db,
          id: wordId,
          legacySpelling: 'phase32 graph search title',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'representative-graph-meaning8-title',
            },
          ],
        );
        for (var index = 1; index <= 8; index++) {
          await db.insert('word_meaning_set', {
            'word_id': wordId,
            'seq': index,
            'meaning': index == 8 ? keyword : 'phase32 graph meaning $index',
          });
        }

        final results = await repository.searchWords(keyword, limit: 20);
        final targetResults = results
            .where((result) => result.wordId == wordId)
            .toList(growable: false);

        expect(targetResults, hasLength(1));
        expect(
          targetResults.single.representativeSpelling,
          'representative-graph-meaning8-title',
        );
        expect(targetResults.single.primaryMeaning, 'phase32 graph meaning 1');
      },
    );
  });
}

Future<Directory> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(
    p.join(repoRootPath, '.tmp_phase8h4_graph_relation_add_search_tests'),
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
  required String legacySpelling,
  String? meaning1,
  required List<Map<String, Object?>> expressionRows,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '언어': '테스트',
    '스트롱넘버': strongNumber,
    '표기1': legacySpelling,
    '의미1': meaning1,
  });

  for (final row in expressionRows) {
    await db.insert('word_expression_set', {'word_id': id, ...row});
  }
  if (meaning1 != null) {
    await db.insert('word_meaning_set', {
      'word_id': id,
      'seq': 1,
      'meaning': meaning1,
    });
  }
}
