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
      reason: 'history probe 테스트용 기준 DB가 필요합니다.',
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

  group('WordRepository explorer history probe path', () {
    test(
      'returns only existing ids for mixed candidates and does not emit read source collector snapshots',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        final existingRows = await db.query(
          'WORD_TABLE',
          columns: ['id'],
          orderBy: 'id',
          limit: 2,
        );

        expect(existingRows, hasLength(2));
        final firstId = existingRows[0]['id']! as String;
        final secondId = existingRows[1]['id']! as String;

        final existingIds = await repository
            .probeExistingWordIdsForExplorerHistory([
              '  $firstId  ',
              secondId,
              firstId,
              'T9000_RS_HISTORY_PROBE_MISSING',
            ]);

        expect(existingIds, equals(<String>{firstId, secondId}));
        expect(
          WordRepository.debugReadSourceCollector.debugRecentSnapshots(),
          isEmpty,
        );
      },
    );

    test(
      'returns empty set when candidates are blank or missing only',
      () async {
        final repository = WordRepository();

        final existingIds = await repository
            .probeExistingWordIdsForExplorerHistory([
              ' ',
              '',
              'T9000_RS_HISTORY_PROBE_MISSING_ONLY',
            ]);

        expect(existingIds, isEmpty);
        expect(
          WordRepository.debugReadSourceCollector.debugRecentSnapshots(),
          isEmpty,
        );
      },
    );
  });
}

Future<Directory> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(p.join(repoRootPath, '.tmp_history_probe_tests'));
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
