import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/expression/read_source_policy.dart';
import 'package:reshet_app/domain/graph/graph_create_post_save_payload.dart';
import 'package:sqflite_common/sqlite_api.dart';

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
      reason: 'graph post-save payload test needs the seed work DB.',
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
        expect(
          snapshot.requestedPolicy,
          ReadSourcePolicy.normalizedWithFallback,
        );
        expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
        expect(snapshot.didFallback, isFalse);
        expect(snapshot.context, 'readForGraphCreatePostSavePayload');
      },
    );

    test(
      'records fallback reason and keeps hidden slot data out of the payload',
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
        expect(payload.representativeSpelling, 'legacy-post-save-title');
        expect(payload.representativeSpelling, isNot('legacy-hidden-translit'));
        expect(
          snapshot.requestedPolicy,
          ReadSourcePolicy.normalizedWithFallback,
        );
        expect(
          snapshot.finalResultSource,
          FinalReadResultSource.legacyFallback,
        );
        expect(snapshot.didFallback, isTrue);
        expect(
          snapshot.fallbackObservation?.reason,
          ReadFallbackReason.userVisibleDisplayMismatch,
        );
        expect(
          snapshot.fallbackObservation?.context,
          'readForGraphCreatePostSavePayload',
        );
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
  Database db, {
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

Future<Directory> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(
    p.join(repoRootPath, '.tmp_graph_create_post_save_payload_tests'),
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
