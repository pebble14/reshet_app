import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';

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
      reason: 'graph navigation existence probe test needs the seed work DB.',
    );

    await DatabaseService.closeDatabase();
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    WordRepository.debugReadSourceCollector.debugReset();
    isolatedRoot = await _createIsolatedWorkspace(
      repoRootPath,
      sourceWorkDbPath,
    );
    Directory.current = isolatedRoot!.path;
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    WordRepository.debugReadSourceCollector.debugReset();
    Directory.current = repoRootPath;

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await isolatedRoot!.delete(recursive: true);
    }
  });

  group('Graph navigation existence probe', () {
    test('checks only WORD_TABLE id existence for graph navigation', () async {
      final repository = WordRepository();
      final db = await DatabaseService.openDatabaseFile();
      const wordId = 'T9000_GRAPH_NAV_EXISTS_ONLY_ID';

      await db.delete('WORD_TABLE', where: 'id = ?', whereArgs: [wordId]);
      await db.insert('WORD_TABLE', {'id': wordId});

      final expressionRows = await db.query(
        'word_expression_set',
        where: 'word_id = ?',
        whereArgs: [wordId],
      );
      expect(expressionRows, isEmpty);

      final exists = await repository.wordExistsForGraphNavigation(' $wordId ');

      expect(exists, isTrue);
      expect(
        WordRepository.debugReadSourceCollector.debugRecentSnapshots(),
        isEmpty,
      );

      final idOnlyRows = await db.query(
        'WORD_TABLE',
        columns: const ['id'],
        where: 'id = ?',
        whereArgs: [wordId],
      );
      expect(idOnlyRows, [
        {'id': wordId},
      ]);
    });

    test('returns false for blank or missing graph navigation ids', () async {
      final repository = WordRepository();

      expect(await repository.wordExistsForGraphNavigation('   '), isFalse);
      expect(
        await repository.wordExistsForGraphNavigation(
          'T9000_GRAPH_NAV_MISSING',
        ),
        isFalse,
      );
      expect(
        WordRepository.debugReadSourceCollector.debugRecentSnapshots(),
        isEmpty,
      );
    });
  });
}

Future<Directory> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(
    p.join(repoRootPath, '.tmp_graph_navigation_probe_tests'),
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
