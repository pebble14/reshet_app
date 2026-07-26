import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/expression/read_source_policy.dart';
import 'package:reshet_app/domain/word/word_edit_seed.dart';

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
      reason: 'edit seed read context test needs the seed work DB.',
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

  group('Edit seed read controlled zone', () {
    test(
      'returns typed edit seeds and keeps owner collector contexts isolated',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_EDIT_SEED_CONTEXT_OK';
        final legacyWordRow = await _insertWord(
          db,
          id: wordId,
          strongNumber: 'H990001',
          legacySpelling: 'edit-seed-title',
          legacyTransliteration: 'edit-seed-translit',
          legacyPronunciation: 'edit-seed-pron',
          meaning1: 'edit seed meaning',
          note: 'edit seed note',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'edit-seed-title',
              'transliteration': 'edit-seed-translit',
              'pronunciation': 'edit-seed-pron',
            },
          ],
        );
        final rawSeed = repository.buildWordEditSeedFromWordRow(legacyWordRow);

        final detailSeed = await repository.getWordEditSeedForDetailEdit(
          wordId,
        );
        final explorerSeed = await repository.getWordEditSeedForExplorerEdit(
          wordId,
        );
        final graphCreateSeed = await repository
            .getWordEditSeedForGraphCreateEdit(wordId);
        final detailSnapshot = _lastSnapshotFor(
          wordId,
          'readForDetailEditSeed',
        );
        final explorerSnapshot = _lastSnapshotFor(
          wordId,
          'readForExplorerEditSeed',
        );
        final graphCreateSnapshot = _lastSnapshotFor(
          wordId,
          'readForGraphCreateEditSeed',
        );

        expect(detailSeed, isA<WordEditSeed>());
        expect(explorerSeed, isA<WordEditSeed>());
        expect(graphCreateSeed, isA<WordEditSeed>());
        expect(detailSeed!.wordId, rawSeed.wordId);
        expect(detailSeed.language, rawSeed.language);
        expect(detailSeed.strongNumber, rawSeed.strongNumber);
        expect(detailSeed.note, rawSeed.note);
        expect(detailSeed.meanings, rawSeed.meanings);
        expect(detailSeed.expressionReadResult.sets, hasLength(1));
        expect(
          detailSeed.expressionReadResult.sets.single.spelling,
          'edit-seed-title',
        );
        expect(explorerSeed!.wordId, rawSeed.wordId);
        expect(
          explorerSeed.expressionReadResult.sets.single.spelling,
          detailSeed.expressionReadResult.sets.single.spelling,
        );
        expect(graphCreateSeed!.wordId, rawSeed.wordId);
        expect(
          graphCreateSeed.expressionReadResult.sets.single.spelling,
          detailSeed.expressionReadResult.sets.single.spelling,
        );

        expect(
          detailSnapshot.requestedPolicy,
          ReadSourcePolicy.normalizedWithFallback,
        );
        expect(
          explorerSnapshot.requestedPolicy,
          ReadSourcePolicy.normalizedWithFallback,
        );
        expect(
          graphCreateSnapshot.requestedPolicy,
          ReadSourcePolicy.normalizedWithFallback,
        );
        expect(
          detailSnapshot.finalResultSource,
          FinalReadResultSource.normalized,
        );
        expect(
          explorerSnapshot.finalResultSource,
          FinalReadResultSource.normalized,
        );
        expect(
          graphCreateSnapshot.finalResultSource,
          FinalReadResultSource.normalized,
        );
        expect(detailSnapshot.didFallback, isFalse);
        expect(explorerSnapshot.didFallback, isFalse);
        expect(graphCreateSnapshot.didFallback, isFalse);
        expect(detailSnapshot.context, isNot(explorerSnapshot.context));
        expect(detailSnapshot.context, isNot(graphCreateSnapshot.context));
        expect(explorerSnapshot.context, isNot(graphCreateSnapshot.context));
      },
    );

    test(
      'uses canonical expression rows and ignores stale legacy hidden slot issues',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_EDIT_SEED_FALLBACK_HIDDEN';

        await _insertWord(
          db,
          id: wordId,
          legacySpelling: 'legacy-visible-title',
          legacyTransliteration: 'legacy-visible-translit',
          legacyPronunciation: 'legacy-visible-pron',
          hiddenTransliteration2: 'legacy-hidden-translit',
          meaning1: 'fallback hidden issue meaning',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'normalized-visible-title',
              'transliteration': 'legacy-visible-translit',
              'pronunciation': 'legacy-visible-pron',
            },
          ],
        );

        final explorerSeed = await repository.getWordEditSeedForExplorerEdit(
          wordId,
        );
        final graphCreateSeed = await repository
            .getWordEditSeedForGraphCreateEdit(wordId);
        final explorerSnapshot = _lastSnapshotFor(
          wordId,
          'readForExplorerEditSeed',
        );
        final graphCreateSnapshot = _lastSnapshotFor(
          wordId,
          'readForGraphCreateEditSeed',
        );

        expect(explorerSeed, isA<WordEditSeed>());
        expect(graphCreateSeed, isA<WordEditSeed>());
        expect(
          explorerSnapshot.finalResultSource,
          FinalReadResultSource.normalized,
        );
        expect(explorerSnapshot.didFallback, isFalse);
        expect(explorerSnapshot.fallbackObservation, isNull);
        expect(
          graphCreateSnapshot.finalResultSource,
          FinalReadResultSource.normalized,
        );
        expect(graphCreateSnapshot.didFallback, isFalse);
        expect(graphCreateSnapshot.fallbackObservation, isNull);
        expect(
          explorerSeed!.expressionReadResult.sets.single.spelling,
          'normalized-visible-title',
        );
        expect(
          graphCreateSeed!.expressionReadResult.sets.single.spelling,
          'normalized-visible-title',
        );
        expect(explorerSeed.hiddenSlotIssues, isEmpty);
        expect(graphCreateSeed.hiddenSlotIssues, isEmpty);
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

Future<Map<String, dynamic>> _insertWord(
  dynamic db, {
  required String id,
  String language = '\uD14C\uC2A4\uD2B8',
  String? strongNumber,
  required String legacySpelling,
  required String legacyTransliteration,
  required String legacyPronunciation,
  String? hiddenTransliteration2,
  required String meaning1,
  String? note,
  required List<Map<String, Object?>> expressionRows,
}) async {
  final wordRow = <String, dynamic>{
    'id': id,
    '\uC5B8\uC5B4': language,
    '\uC2A4\uD2B8\uB871\uB118\uBC84': strongNumber,
    '\uD45C\uAE301': legacySpelling,
    '\uC74C\uC5ED1': legacyTransliteration,
    '\uBC1C\uC74C1': legacyPronunciation,
    '\uC74C\uC5ED2': hiddenTransliteration2,
    '\uC758\uBBF81': meaning1,
    '\uBE44\uACE0': note,
  };

  await db.insert('WORD_TABLE', wordRow);
  for (final expressionRow in expressionRows) {
    await db.insert('word_expression_set', {'word_id': id, ...expressionRow});
  }
  await db.insert('word_meaning_set', {
    'word_id': id,
    'seq': 1,
    'meaning': meaning1,
  });

  return wordRow;
}

Future<Directory> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(
    p.join(repoRootPath, '.tmp_edit_seed_read_context_tests'),
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
