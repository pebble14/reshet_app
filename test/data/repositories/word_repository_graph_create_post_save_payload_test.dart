import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/expression/read_source_policy.dart';
import 'package:reshet_app/domain/graph/graph_create_post_save_payload.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const List<String> _fixtureWordIds = [
  'T9000_GRAPH_POST_SAVE_PAYLOAD_OK',
  'T9000_GRAPH_POST_SAVE_PAYLOAD_FALLBACK',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String repoRootPath;
  late String sourceSeedDbPath;
  Directory? isolatedRoot;

  setUpAll(() async {
    repoRootPath = Directory.current.path;
    sourceSeedDbPath = p.join(repoRootPath, 'data', 'reshet_seed.db');

    expect(
      File(sourceSeedDbPath).existsSync(),
      isTrue,
      reason: 'graph post-save payload test needs the source seed DB.',
    );

    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    WordRepository.debugSetReadSourcePolicyOverride(null);
    WordRepository.debugReadSourceCollector.debugReset();
    isolatedRoot = await _createIsolatedWorkspace(sourceSeedDbPath);
    final isolatedDataRoot = p.join(isolatedRoot!.path, 'data');
    final isolatedSeedDbPath = p.join(isolatedDataRoot, 'reshet_seed.db');
    final isolatedWorkDbPath = p.join(isolatedDataRoot, 'reshet_work.db');

    DatabaseService.setDataRootOverrideForTest(isolatedDataRoot);
    Directory.current = isolatedRoot!.path;

    await _expectFixtureIdsAbsentFromPath(
      isolatedSeedDbPath,
      databaseLabel: 'isolated seed DB',
    );
    final workDatabase = await DatabaseService.openDatabaseFile();
    expect(File(isolatedWorkDbPath).existsSync(), isTrue);
    await _expectFixtureIdsAbsent(
      workDatabase,
      databaseLabel: 'isolated work DB',
    );
  });

  tearDown(() async {
    try {
      await DatabaseService.closeDatabase();
    } finally {
      DatabaseService.setDataRootOverrideForTest(null);
      WordRepository.debugSetReadSourcePolicyOverride(null);
      WordRepository.debugReadSourceCollector.debugReset();
      Directory.current = repoRootPath;

      final root = isolatedRoot;
      isolatedRoot = null;
      if (root != null && root.existsSync()) {
        await root.delete(recursive: true);
      }
    }
  });

  group('Graph create post-save payload read boundary', () {
    test(
      'returns typed payload and records normalized owner context',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_GRAPH_POST_SAVE_PAYLOAD_OK';

        await _insertWord(
          db,
          id: wordId,
          legacySpelling: 'graph-post-save-title',
          legacyTransliteration: 'graph-post-save-translit',
          legacyPronunciation: 'graph-post-save-pron',
          meaning1: 'graph post-save meaning',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'graph-post-save-title',
              'transliteration': 'graph-post-save-translit',
              'pronunciation': 'graph-post-save-pron',
            },
          ],
        );

        final payload = await repository.getGraphCreatePostSavePayloadAfterEdit(
          wordId,
        );
        final snapshot = _lastSnapshotFor(
          wordId,
          'readForGraphCreatePostSavePayload',
        );

        expect(payload, isA<GraphCreatePostSavePayload>());
        expect(payload!.wordId, wordId);
        expect(payload.representativeSpelling, 'graph-post-save-title');
        expect(snapshot.requestedPolicy, ReadSourcePolicy.normalizedOnly);
        expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
        expect(snapshot.didFallback, isFalse);
        expect(snapshot.context, 'readForGraphCreatePostSavePayload');
      },
    );

    test(
      'uses canonical expression rows and keeps hidden slot data out of the payload',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_GRAPH_POST_SAVE_PAYLOAD_FALLBACK';

        await _insertWord(
          db,
          id: wordId,
          legacySpelling: 'legacy-post-save-title',
          legacyTransliteration: 'legacy-post-save-translit',
          legacyPronunciation: 'legacy-post-save-pron',
          hiddenTransliteration2: 'legacy-hidden-translit',
          meaning1: 'graph post-save fallback meaning',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'normalized-post-save-title',
              'transliteration': 'legacy-post-save-translit',
              'pronunciation': 'legacy-post-save-pron',
            },
          ],
        );

        final payload = await repository.getGraphCreatePostSavePayloadAfterEdit(
          wordId,
        );
        final snapshot = _lastSnapshotFor(
          wordId,
          'readForGraphCreatePostSavePayload',
        );

        expect(payload, isA<GraphCreatePostSavePayload>());
        expect(payload!.wordId, wordId);
        expect(payload.representativeSpelling, 'normalized-post-save-title');
        expect(payload.representativeSpelling, isNot('legacy-hidden-translit'));
        expect(snapshot.requestedPolicy, ReadSourcePolicy.normalizedOnly);
        expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
        expect(snapshot.didFallback, isFalse);
        expect(snapshot.fallbackObservation, isNull);
      },
    );
  });
}

WordExpressionReadSnapshot _lastSnapshotFor(String wordId, String context) {
  return WordRepository.debugReadSourceCollector
      .debugRecentSnapshots()
      .lastWhere(
        (snapshot) => snapshot.wordId == wordId && snapshot.context == context,
      );
}

Future<void> _insertWord(
  dynamic db, {
  required String id,
  String language = '\uD14C\uC2A4\uD2B8',
  String? strongNumber,
  required String legacySpelling,
  required String legacyTransliteration,
  required String legacyPronunciation,
  String? hiddenTransliteration2,
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
    '\uC74C\uC5ED2': hiddenTransliteration2,
    '\uC758\uBBF81': meaning1,
  });
  for (final expressionRow in expressionRows) {
    await db.insert('word_expression_set', {'word_id': id, ...expressionRow});
  }
}

Future<void> _expectFixtureIdsAbsentFromPath(
  String databasePath, {
  required String databaseLabel,
}) async {
  final database = await databaseFactory.openDatabase(
    databasePath,
    options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
  );
  try {
    await _expectFixtureIdsAbsent(database, databaseLabel: databaseLabel);
  } finally {
    await database.close();
  }
}

Future<void> _expectFixtureIdsAbsent(
  DatabaseExecutor database, {
  required String databaseLabel,
}) async {
  final rows = await database.query(
    'WORD_TABLE',
    columns: const ['id'],
    where: 'id IN (?, ?)',
    whereArgs: _fixtureWordIds,
    orderBy: 'id ASC',
  );
  expect(
    rows,
    isEmpty,
    reason: '$databaseLabel must start without graph post-save fixtures.',
  );
}

Future<Directory> _createIsolatedWorkspace(String sourceSeedDbPath) async {
  final isolatedRoot = await Directory.systemTemp.createTemp(
    'reshet_graph_create_post_save_payload_',
  );
  try {
    final dataDir = Directory(p.join(isolatedRoot.path, 'data'));
    await dataDir.create(recursive: true);

    await File(sourceSeedDbPath).copy(p.join(dataDir.path, 'reshet_seed.db'));
    return isolatedRoot;
  } catch (_) {
    if (isolatedRoot.existsSync()) {
      await isolatedRoot.delete(recursive: true);
    }
    rethrow;
  }
}
