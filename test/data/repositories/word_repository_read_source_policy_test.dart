import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/adapters/legacy_word_expression_read_adapter.dart';
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/expression/read_source_policy.dart';
import 'package:reshet_app/domain/graph/graph_visible_word.dart';
import 'package:reshet_app/domain/word/word_detail_like_display_item.dart';

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
      reason: 'read source policy 테스트용 기준 seed DB가 필요합니다.',
    );

    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    WordRepository.debugSetReadSourcePolicyOverride(null);
    WordRepository.debugReadSourceCollector.debugReset();
    isolatedRoot = await _createIsolatedWorkspace(sourceSeedDbPath);
    DatabaseService.setDataRootOverrideForTest(
      p.join(isolatedRoot!.path, 'data'),
    );
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

  group('WordRepository read source foundation', () {
    test(
      'keeps the global default as LEGACY while raw single-word read uses NORMALIZED_WITH_FALLBACK',
      () async {
        final logs = <String>[];
        final previousDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) {
            logs.add(message);
          }
        };
        addTearDown(() {
          debugPrint = previousDebugPrint;
        });

        expect(
          WordRepository.debugCurrentReadSourcePolicy,
          ReadSourcePolicy.legacy,
        );

        final repository = WordRepository();
        final row = await repository.getWordMapById('E0000_0010');
        final snapshot = WordRepository.debugReadSourceCollector
            .debugLastSnapshotForWord('E0000_0010');

        expect(row, isNotNull);
        expect(snapshot, isNotNull);
        expect(
          snapshot!.requestedPolicy,
          ReadSourcePolicy.normalizedWithFallback,
        );
        expect(snapshot.resolvedSource, ResolvedReadSource.normalized);
        expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
        expect(snapshot.didFallback, isFalse);
        expect(snapshot.legacyResultAvailable, isTrue);
        expect(snapshot.normalizedResultAvailable, isTrue);
        expect(snapshot.readResult.sets, hasLength(2));

        final observationLog = logs.singleWhere(
          (line) => line.startsWith('[ExpressionReadSource] '),
        );
        expect(
          observationLog,
          '[ExpressionReadSource] '
          'context=getWordMapById '
          'policy=NORMALIZED_WITH_FALLBACK '
          'resolved=normalized '
          'final=normalized '
          'reason=-',
        );
        expect(observationLog, isNot(contains('E0000_0010')));
        expect(observationLog, isNot(contains('Eva')));
      },
    );

    test(
      'connects normalized read adapter when policy override is enabled',
      () async {
        WordRepository.debugSetReadSourcePolicyOverride(
          ReadSourcePolicy.normalizedWithFallback,
        );
        final repository = WordRepository();

        final row = await repository.getWordMapById('E0000_0010');
        final snapshot = WordRepository.debugReadSourceCollector
            .debugLastSnapshotForWord('E0000_0010');

        expect(row, isNotNull);
        expect(row!['표기1'], 'Eva');
        expect(snapshot, isNotNull);
        expect(
          snapshot!.requestedPolicy,
          ReadSourcePolicy.normalizedWithFallback,
        );
        expect(snapshot.resolvedSource, ResolvedReadSource.normalized);
        expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
        expect(snapshot.didFallback, isFalse);
        expect(snapshot.legacyResultAvailable, isTrue);
        expect(snapshot.normalizedResultAvailable, isTrue);
        expect(snapshot.readResult.sets, hasLength(2));
        expect(snapshot.readResult.sets.first.spelling, 'Eva');
        expect(snapshot.readResult.sets.first.isRepresentative, isTrue);
      },
    );

    test(
      'treats empty normalized rows as canonical empty expression result',
      () async {
        WordRepository.debugSetReadSourcePolicyOverride(
          ReadSourcePolicy.normalizedWithFallback,
        );
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();

        await db.insert('WORD_TABLE', {
          'id': 'T9000_RS_EMPTY',
          '언어': '테스트',
          '표기1': 'fallback-empty',
          '음역1': '폴백',
          '발음1': 'fallback',
        });

        final row = await repository.getWordMapById('T9000_RS_EMPTY');
        final snapshot = WordRepository.debugReadSourceCollector
            .debugLastSnapshotForWord('T9000_RS_EMPTY');

        expect(row, isNotNull);
        expect(snapshot, isNotNull);
        expect(snapshot!.resolvedSource, ResolvedReadSource.normalized);
        expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
        expect(snapshot.didFallback, isFalse);
        expect(snapshot.fallbackObservation, isNull);
        expect(snapshot.readResult.sets, isEmpty);
        expect(snapshot.legacyResultAvailable, isTrue);
        expect(snapshot.normalizedResultAvailable, isTrue);
      },
    );

    test(
      'records query-failed fallback observation when normalized table is unavailable',
      () async {
        final logs = <String>[];
        final previousDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) {
            logs.add(message);
          }
        };
        addTearDown(() {
          debugPrint = previousDebugPrint;
        });

        WordRepository.debugSetReadSourcePolicyOverride(
          ReadSourcePolicy.normalizedWithFallback,
        );
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();

        await db.execute('DROP TABLE word_expression_set');

        final row = await repository.getWordMapById('E0000_0001');
        final snapshot = WordRepository.debugReadSourceCollector
            .debugLastSnapshotForWord('E0000_0001');

        expect(row, isNotNull);
        expect(snapshot, isNotNull);
        expect(snapshot!.resolvedSource, ResolvedReadSource.legacy);
        expect(
          snapshot.finalResultSource,
          FinalReadResultSource.legacyFallback,
        );
        expect(snapshot.didFallback, isTrue);
        expect(
          snapshot.fallbackObservation!.reason,
          ReadFallbackReason.queryFailed,
        );
        expect(snapshot.fallbackObservation!.detail, isNotEmpty);

        final observationLog = logs.singleWhere(
          (line) => line.startsWith('[ExpressionReadSource] '),
        );
        expect(
          observationLog,
          '[ExpressionReadSource] '
          'context=getWordMapById '
          'policy=NORMALIZED_WITH_FALLBACK '
          'resolved=legacy '
          'final=legacy_fallback '
          'reason=query_failed',
        );
        expect(observationLog, isNot(contains('E0000_0001')));
        expect(
          observationLog,
          isNot(contains(snapshot.fallbackObservation!.detail!)),
        );
        expect(observationLog, isNot(contains('word_expression_set')));
      },
    );

    test(
      'records minimum-expression-not-met fallback observation when normalized rows have no valid spelling',
      () async {
        WordRepository.debugSetReadSourcePolicyOverride(
          ReadSourcePolicy.normalizedWithFallback,
        );
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();

        await db.execute('PRAGMA ignore_check_constraints = ON');
        await db.insert('WORD_TABLE', {
          'id': 'T9000_RS_MIN_EXPR',
          '언어': '테스트',
          '표기1': 'legacy-valid',
          '음역1': '레거시',
          '발음1': 'legacy-valid',
        });
        await db.insert('word_expression_set', {
          'word_id': 'T9000_RS_MIN_EXPR',
          'seq': 1,
          'is_representative': 1,
          'spelling': '   ',
          'transliteration': 'issue-only',
          'pronunciation': 'issue-only',
        });
        await db.execute('PRAGMA ignore_check_constraints = OFF');

        final row = await repository.getWordMapById('T9000_RS_MIN_EXPR');
        final snapshot = WordRepository.debugReadSourceCollector
            .debugLastSnapshotForWord('T9000_RS_MIN_EXPR');

        expect(row, isNotNull);
        expect(snapshot, isNotNull);
        expect(snapshot!.resolvedSource, ResolvedReadSource.legacy);
        expect(
          snapshot.finalResultSource,
          FinalReadResultSource.legacyFallback,
        );
        expect(snapshot.didFallback, isTrue);
        expect(
          snapshot.fallbackObservation!.reason,
          ReadFallbackReason.minimumExpressionNotMet,
        );
        expect(
          snapshot.fallbackObservation!.detail,
          contains('valid spelling'),
        );
      },
    );

    test(
      'records mapping-invalid fallback observation when normalized rows violate canonical ordering rules',
      () async {
        WordRepository.debugSetReadSourcePolicyOverride(
          ReadSourcePolicy.normalizedWithFallback,
        );
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();

        await db.execute('DROP TABLE word_expression_set');
        await db.execute('''
          CREATE TABLE word_expression_set (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word_id TEXT NOT NULL,
            seq INTEGER,
            is_representative INTEGER,
            spelling TEXT,
            transliteration TEXT,
            pronunciation TEXT,
            pronunciation_notation TEXT CHECK (
              pronunciation_notation IS NULL OR pronunciation_notation IN (
                'strong_dictionary',
                'ipa_phonemic',
                'ipa_phonetic',
                'other',
                'unknown'
              )
            ),
            pronunciation_notation_name TEXT CHECK (
              pronunciation_notation_name IS NULL OR
              LENGTH(TRIM(pronunciation_notation_name)) > 0
            )
          )
          ''');

        await db.insert('WORD_TABLE', {
          'id': 'T9000_RS_MAPPING',
          '언어': '테스트',
          '표기1': 'legacy-alpha',
          '음역1': '레거시 알파',
          '발음1': 'legacy-alpha',
        });
        await db.insert('word_expression_set', {
          'word_id': 'T9000_RS_MAPPING',
          'seq': 1,
          'is_representative': 1,
          'spelling': 'alpha',
        });
        await db.insert('word_expression_set', {
          'word_id': 'T9000_RS_MAPPING',
          'seq': 1,
          'is_representative': 0,
          'spelling': 'aleph',
        });

        final row = await repository.getWordMapById('T9000_RS_MAPPING');
        final snapshot = WordRepository.debugReadSourceCollector
            .debugLastSnapshotForWord('T9000_RS_MAPPING');

        expect(row, isNotNull);
        expect(snapshot, isNotNull);
        expect(snapshot!.resolvedSource, ResolvedReadSource.legacy);
        expect(
          snapshot.finalResultSource,
          FinalReadResultSource.legacyFallback,
        );
        expect(snapshot.didFallback, isTrue);
        expect(
          snapshot.fallbackObservation!.reason,
          ReadFallbackReason.mappingInvalid,
        );
        expect(snapshot.fallbackObservation!.detail, contains('duplicate seq'));
      },
    );

    test(
      'keeps normalized-only empty rows visible without falling back to legacy',
      () async {
        WordRepository.debugSetReadSourcePolicyOverride(
          ReadSourcePolicy.normalizedOnly,
        );
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();

        await db.insert('WORD_TABLE', {
          'id': 'T9000_RS_STRICT',
          '언어': '테스트',
          '표기1': 'strict-only',
        });

        final row = await repository.getWordMapById('T9000_RS_STRICT');
        final snapshot = WordRepository.debugReadSourceCollector
            .debugLastSnapshotForWord('T9000_RS_STRICT');

        expect(row, isNotNull);
        expect(snapshot, isNotNull);
        expect(snapshot!.resolvedSource, ResolvedReadSource.normalized);
        expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
        expect(snapshot.didFallback, isFalse);
        expect(snapshot.fallbackObservation, isNull);
        expect(snapshot.readResult.sets, isEmpty);
      },
    );
  });

  group('Canonical read/write closure guard', () {
    test(
      'user-facing feature contexts use canonical read policy and normalized rows',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const centerWordId = 'T9000_RS_CLOSURE_CENTER';
        const targetWordId = 'T9000_RS_CLOSURE_TARGET';
        const strongNumber = 'G999999';
        const canonicalTitle = 'canonical-closure-title';
        const canonicalMeaning = 'canonical closure meaning';

        await _insertCanonicalClosureWord(
          db,
          id: centerWordId,
          strongNumber: 'G999998',
          legacySpelling: 'legacy-closure-center',
          canonicalSpelling: 'canonical-closure-center',
          canonicalMeaning: 'canonical closure center meaning',
        );
        await _insertCanonicalClosureWord(
          db,
          id: targetWordId,
          strongNumber: strongNumber,
          legacySpelling: 'legacy-closure-title',
          canonicalSpelling: canonicalTitle,
          canonicalMeaning: canonicalMeaning,
        );
        await db.insert('WORD_RELATION', {
          'word_id_1': centerWordId,
          'word_id_2': targetWordId,
          'direction_code': 'unknown',
          'updated_at': DateTime.now().toIso8601String(),
        });

        final detailDisplay = await repository
            .getWordDetailLikeDisplayItemByIdForDetailScreen(targetWordId);
        _expectNormalizedSnapshot(
          targetWordId,
          'getWordDetailLikeDisplayItemByIdForDetailScreen',
          expectedPolicy: ReadSourcePolicy.normalizedOnly,
        );
        final splitViewDisplay = await repository
            .getWordDetailLikeDisplayItemByIdForSplitView(targetWordId);
        _expectNormalizedSnapshot(
          targetWordId,
          'readForSplitViewSingleWord',
          expectedPolicy: ReadSourcePolicy.normalizedOnly,
        );
        final graphSingleRow = await repository
            .getWordMapByIdForGraphSingleWord(targetWordId);
        _expectNormalizedSnapshot(targetWordId, 'readForGraphSingleWord');
        final graphCenterRow = await repository
            .getWordMapByIdForGraphCenterSingleWord(targetWordId);
        _expectNormalizedSnapshot(
          targetWordId,
          'readForGraphCenterSingleWord',
          expectedPolicy: ReadSourcePolicy.normalizedOnly,
        );
        final graphCenterDisplay = await repository
            .getGraphCenterWordDisplayItemByIdForGraphCenterSingleWord(
              targetWordId,
            );
        final graphData = await repository.getVisibleGraphDataForGraph(
          centerWordId,
        );
        _expectNormalizedSnapshot(
          targetWordId,
          'readForGraphBatch',
          expectedPolicy: ReadSourcePolicy.normalizedOnly,
        );
        final strongItems = await repository.getStrongWordsMap();
        _expectNormalizedSnapshot(
          targetWordId,
          'getStrongWordsMap',
          expectedPolicy: ReadSourcePolicy.normalizedOnly,
        );
        final searchItems = await repository.searchWordsMap(
          canonicalTitle,
          limit: 20,
        );
        _expectNormalizedSnapshot(
          targetWordId,
          'searchWordsMap',
          expectedPolicy: ReadSourcePolicy.normalizedOnly,
        );
        final strongExactItems = await repository.searchStrongExactMap(
          strongNumber,
          limit: 20,
        );
        _expectNormalizedSnapshot(
          targetWordId,
          'searchStrongExactMap',
          expectedPolicy: ReadSourcePolicy.normalizedOnly,
        );
        final detailSeed = await repository.getWordEditSeedForDetailEdit(
          targetWordId,
        );
        _expectNormalizedSnapshot(targetWordId, 'readForDetailEditSeed');
        final explorerSeed = await repository.getWordEditSeedForExplorerEdit(
          targetWordId,
        );
        _expectNormalizedSnapshot(targetWordId, 'readForExplorerEditSeed');
        final graphEditSeed = await repository
            .getWordEditSeedForGraphCreateEdit(targetWordId);
        _expectNormalizedSnapshot(targetWordId, 'readForGraphCreateEditSeed');
        final graphPostSavePayload = await repository
            .getGraphCreatePostSavePayloadAfterEdit(targetWordId);
        _expectNormalizedSnapshot(
          targetWordId,
          'readForGraphCreatePostSavePayload',
          expectedPolicy: ReadSourcePolicy.normalizedOnly,
        );

        final graphChild = graphData.connectedWords.singleWhere(
          (word) => word.wordId == targetWordId,
        );
        final strongItem = strongItems.singleWhere(
          (item) => item.wordId == targetWordId,
        );
        final searchItem = searchItems.singleWhere(
          (item) => item.wordId == targetWordId,
        );
        final strongExactItem = strongExactItems.singleWhere(
          (item) => item.wordId == targetWordId,
        );

        expect(detailDisplay, isNotNull);
        expect(detailDisplay!.representativeSpelling, canonicalTitle);
        expect(detailDisplay.meanings, [canonicalMeaning]);
        expect(splitViewDisplay, isNotNull);
        expect(splitViewDisplay!.representativeSpelling, canonicalTitle);
        expect(graphSingleRow!['표기1'], canonicalTitle);
        expect(graphCenterRow!['표기1'], canonicalTitle);
        expect(graphCenterDisplay, isNotNull);
        expect(graphCenterDisplay!.representativeSpelling, canonicalTitle);
        expect(graphCenterDisplay.primaryMeaning, canonicalMeaning);
        expect(graphChild.fallbackSpelling, canonicalTitle);
        expect(strongItem.representativeSpelling, canonicalTitle);
        expect(searchItem.representativeSpelling, canonicalTitle);
        expect(strongExactItem.representativeSpelling, canonicalTitle);
        expect(
          detailSeed!.expressionReadResult.sets.single.spelling,
          canonicalTitle,
        );
        expect(detailSeed.meanings, [canonicalMeaning]);
        expect(
          explorerSeed!.expressionReadResult.sets.single.spelling,
          canonicalTitle,
        );
        expect(
          graphEditSeed!.expressionReadResult.sets.single.spelling,
          canonicalTitle,
        );
        expect(graphPostSavePayload!.representativeSpelling, canonicalTitle);
      },
    );

    test(
      'Home normalized-only query failure does not use legacy fallback',
      () async {
        final previousDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {};
        addTearDown(() {
          debugPrint = previousDebugPrint;
        });

        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_RS_HOME_STRICT_FAILURE';

        await db.insert('WORD_TABLE', {
          'id': wordId,
          '언어': '테스트',
          '스트롱넘버': 'H0',
          '표기1': 'home-strict-failure',
        });
        await db.execute('DROP TABLE word_expression_set');

        final items = await repository.getStrongWordsMap(limit: 1);
        final snapshot =
            repository.debugLastWordExpressionReadSnapshots[wordId]!;

        expect(items.single.wordId, wordId);
        expect(snapshot.context, 'getStrongWordsMap');
        expect(snapshot.requestedPolicy, ReadSourcePolicy.normalizedOnly);
        expect(snapshot.resolvedSource, ResolvedReadSource.normalized);
        expect(
          snapshot.finalResultSource,
          FinalReadResultSource.normalizedFailure,
        );
        expect(
          snapshot.finalResultSource,
          isNot(FinalReadResultSource.legacyFallback),
        );
      },
    );

    test('generic raw batch remains a LEGACY compatibility boundary', () async {
      final repository = WordRepository();
      final db = await DatabaseService.openDatabaseFile();
      const wordId = 'T9000_RS_GENERIC_RAW_COMPAT';

      await _insertCanonicalClosureWord(
        db,
        id: wordId,
        strongNumber: 'H943002',
        legacySpelling: 'legacy-generic-title',
        canonicalSpelling: 'normalized-generic-title',
        canonicalMeaning: 'normalized generic meaning',
      );

      final rows = await repository.getWordsByIds([wordId]);
      final snapshot = _lastSnapshotFor(wordId, 'getWordsByIds');

      expect(rows, hasLength(1));
      expect(rows.single['표기1'], 'legacy-generic-title');
      expect(snapshot.requestedPolicy, ReadSourcePolicy.legacy);
      expect(snapshot.finalResultSource, FinalReadResultSource.legacy);
      expect(snapshot.didFallback, isFalse);
    });
  });

  group('WordRepository split view single-word path', () {
    test(
      'split view uses NORMALIZED_ONLY and matches detail display',
      () async {
        final repository = WordRepository();

        final splitViewRow = await repository
            .getWordDetailLikeDisplayItemByIdForSplitView('E0000_0010');
        final detailRow = await repository
            .getWordDetailLikeDisplayItemByIdForDetailScreen('E0000_0010');
        final splitViewSnapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (snapshot) =>
                  snapshot.wordId == 'E0000_0010' &&
                  snapshot.context == 'readForSplitViewSingleWord',
            );

        expect(splitViewRow, isNotNull);
        expect(detailRow, isNotNull);
        expect(
          splitViewSnapshot.requestedPolicy,
          ReadSourcePolicy.normalizedOnly,
        );
        expect(
          splitViewSnapshot.finalResultSource,
          FinalReadResultSource.normalized,
        );
        expect(splitViewSnapshot.didFallback, isFalse);
        expect(splitViewSnapshot.legacyResultAvailable, isTrue);
        expect(splitViewSnapshot.normalizedResultAvailable, isTrue);
        _expectSameDetailDisplay(detailRow!, splitViewRow!);
      },
    );

    test(
      'split view uses canonical rows when normalized success changes the visible detail display',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        final legacyWordRow = {
          'id': 'T9000_RS_SPLIT_MISMATCH',
          '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
          '\uD45C\uAE301': 'alpha',
          '\uC74C\uC5ED1': '\uC54C\uD30C',
          '\uBC1C\uC74C1': 'alpha',
          '\uD45C\uAE302': 'aleph',
          '\uC74C\uC5ED2': '\uC54C\uB808\uD504',
          '\uBC1C\uC74C2': 'aleph',
          '\uC758\uBBF81': 'split mismatch',
        };

        await db.insert('WORD_TABLE', legacyWordRow);
        await db.insert('word_expression_set', {
          'word_id': 'T9000_RS_SPLIT_MISMATCH',
          'seq': 1,
          'is_representative': 0,
          'spelling': 'alpha',
          'transliteration': '\uC54C\uD30C',
          'pronunciation': 'alpha',
        });
        await db.insert('word_expression_set', {
          'word_id': 'T9000_RS_SPLIT_MISMATCH',
          'seq': 2,
          'is_representative': 1,
          'spelling': 'aleph',
          'transliteration': '\uC54C\uB808\uD504',
          'pronunciation': 'aleph',
        });

        final splitViewRow = await repository
            .getWordDetailLikeDisplayItemByIdForSplitView(
              'T9000_RS_SPLIT_MISMATCH',
            );
        final snapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (entry) =>
                  entry.wordId == 'T9000_RS_SPLIT_MISMATCH' &&
                  entry.context == 'readForSplitViewSingleWord',
            );

        expect(splitViewRow, isNotNull);
        expect(snapshot.requestedPolicy, ReadSourcePolicy.normalizedOnly);
        expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
        expect(snapshot.didFallback, isFalse);
        expect(snapshot.legacyResultAvailable, isTrue);
        expect(snapshot.normalizedResultAvailable, isTrue);
        expect(snapshot.fallbackObservation, isNull);
        expect(splitViewRow!.representativeSpelling, 'aleph');
        expect(splitViewRow.spellings, ['alpha', 'aleph']);
      },
    );
  });

  group('WordRepository graph batch path', () {
    test(
      'graph batch uses canonical policy while generic raw batch remains LEGACY compatibility boundary',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const centerWordId = 'T9000_RS_GRAPH_CENTER';
        const childWordId = 'T9000_RS_GRAPH_CHILD';

        await db.insert('WORD_TABLE', {
          'id': centerWordId,
          '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
          '\uD45C\uAE301': 'graph-center',
          '\uC74C\uC5ED1': 'graph-center',
          '\uBC1C\uC74C1': 'graph-center',
          '\uC758\uBBF81': 'graph center',
        });
        await db.insert('WORD_TABLE', {
          'id': childWordId,
          '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
          '\uD45C\uAE301': 'graph-child',
          '\uC74C\uC5ED1': 'graph-child',
          '\uBC1C\uC74C1': 'graph-child',
          '\uC758\uBBF81': 'graph child',
        });
        await db.insert('word_expression_set', {
          'word_id': childWordId,
          'seq': 1,
          'is_representative': 1,
          'spelling': 'graph-child',
          'transliteration': 'graph-child',
          'pronunciation': 'graph-child',
        });
        await db.insert('WORD_RELATION', {
          'word_id_1': centerWordId,
          'word_id_2': childWordId,
          'direction_code': 'unknown',
          'updated_at': DateTime.now().toIso8601String(),
        });

        final graphData = await repository.getVisibleGraphDataForGraph(
          centerWordId,
        );
        final genericRows = await repository.getWordsByIds([childWordId]);
        final graphSnapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (snapshot) =>
                  snapshot.wordId == childWordId &&
                  snapshot.context == 'readForGraphBatch',
            );
        final genericSnapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (snapshot) =>
                  snapshot.wordId == childWordId &&
                  snapshot.context == 'getWordsByIds',
            );

        expect(graphData.connectedWords, hasLength(1));
        expect(graphData.connectedWords, isA<List<GraphVisibleWord>>());
        expect(graphData.connectedWords.single.wordId, childWordId);
        expect(graphData.connectedWords.single.fallbackSpelling, 'graph-child');
        expect(graphData.relationEdges, hasLength(1));
        expect(genericRows, hasLength(1));
        expect(genericRows.single['id'], childWordId);

        expect(graphSnapshot.requestedPolicy, ReadSourcePolicy.normalizedOnly);
        expect(
          graphSnapshot.finalResultSource,
          FinalReadResultSource.normalized,
        );
        expect(graphSnapshot.didFallback, isFalse);
        expect(graphSnapshot.legacyResultAvailable, isTrue);
        expect(graphSnapshot.normalizedResultAvailable, isTrue);

        expect(genericSnapshot.requestedPolicy, ReadSourcePolicy.legacy);
        expect(genericSnapshot.finalResultSource, FinalReadResultSource.legacy);
        expect(genericSnapshot.didFallback, isFalse);
        expect(graphSnapshot.context, 'readForGraphBatch');
        expect(genericSnapshot.context, 'getWordsByIds');
        expect(graphSnapshot.context, isNot(genericSnapshot.context));
      },
    );

    test(
      'graph batch uses canonical rows when normalized success changes the visible graph row display',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const centerWordId = 'T9000_RS_GRAPH_CENTER_MISMATCH';
        const childWordId = 'T9000_RS_GRAPH_CHILD_MISMATCH';

        await db.insert('WORD_TABLE', {
          'id': centerWordId,
          '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
          '\uD45C\uAE301': 'graph-center',
          '\uC74C\uC5ED1': 'graph-center',
          '\uBC1C\uC74C1': 'graph-center',
          '\uC758\uBBF81': 'graph center',
        });
        await db.insert('WORD_TABLE', {
          'id': childWordId,
          '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
          '\uD45C\uAE301': 'alpha',
          '\uC74C\uC5ED1': '\uC54C\uD30C',
          '\uBC1C\uC74C1': 'alpha',
          '\uD45C\uAE302': 'aleph',
          '\uC74C\uC5ED2': '\uC54C\uB808\uD504',
          '\uBC1C\uC74C2': 'aleph',
          '\uC758\uBBF81': 'graph mismatch',
        });
        await db.insert('word_expression_set', {
          'word_id': childWordId,
          'seq': 1,
          'is_representative': 0,
          'spelling': 'alpha',
          'transliteration': '\uC54C\uD30C',
          'pronunciation': 'alpha',
        });
        await db.insert('word_expression_set', {
          'word_id': childWordId,
          'seq': 2,
          'is_representative': 1,
          'spelling': 'aleph',
          'transliteration': '\uC54C\uB808\uD504',
          'pronunciation': 'aleph',
        });
        await db.insert('WORD_RELATION', {
          'word_id_1': centerWordId,
          'word_id_2': childWordId,
          'direction_code': 'unknown',
          'updated_at': DateTime.now().toIso8601String(),
        });

        final graphData = await repository.getVisibleGraphDataForGraph(
          centerWordId,
        );
        final snapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (entry) =>
                  entry.wordId == childWordId &&
                  entry.context == 'readForGraphBatch',
            );

        expect(graphData.connectedWords, hasLength(1));
        expect(graphData.connectedWords, isA<List<GraphVisibleWord>>());
        expect(graphData.connectedWords.single.wordId, childWordId);
        expect(graphData.connectedWords.single.fallbackSpelling, 'alpha');
        expect(snapshot.requestedPolicy, ReadSourcePolicy.normalizedOnly);
        expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
        expect(snapshot.didFallback, isFalse);
        expect(snapshot.legacyResultAvailable, isTrue);
        expect(snapshot.normalizedResultAvailable, isTrue);
        expect(snapshot.fallbackObservation, isNull);
      },
    );

    test(
      'relation edge read preserves raw status_code past seven edges',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const centerWordId = 'T9000_RS_STATUS_CENTER';
        final childWordIds = List<String>.generate(
          8,
          (index) => 'T9000_RS_STATUS_CHILD_${index + 1}',
        );

        await db.insert('WORD_TABLE', {
          'id': centerWordId,
          '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
          '\uD45C\uAE301': 'status-center',
          '\uC74C\uC5ED1': 'status-center',
          '\uBC1C\uC74C1': 'status-center',
          '\uC758\uBBF81': 'status center',
        });
        for (final childWordId in childWordIds) {
          await db.insert('WORD_TABLE', {
            'id': childWordId,
            '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
            '\uD45C\uAE301': childWordId.toLowerCase(),
            '\uC74C\uC5ED1': childWordId.toLowerCase(),
            '\uBC1C\uC74C1': childWordId.toLowerCase(),
            '\uC758\uBBF81': 'status child',
          });
        }

        for (var index = 0; index < childWordIds.length; index++) {
          await db.insert('WORD_RELATION', {
            'word_id_1': centerWordId,
            'word_id_2': childWordIds[index],
            'direction_code': 'unknown',
            'status_code': index == 7 ? 'hypothesized' : 'asserted',
            'updated_at': DateTime.now().toIso8601String(),
          });
        }

        final edges = await repository.getRelationEdges(centerWordId);

        expect(edges, hasLength(8));
        expect(edges.last.otherWordId, childWordIds.last);
        expect(edges.last.statusCode, 'hypothesized');
      },
    );
  });

  group('WordRepository graph single-word path', () {
    test(
      'graph single uses NORMALIZED_WITH_FALLBACK and keeps its collector context isolated',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_RS_GRAPH_SINGLE_STABLE';

        final legacyWordRow = {
          'id': wordId,
          '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
          '\uD45C\uAE301': 'graph-single-stable',
          '\uC74C\uC5ED1': 'graph-single-stable',
          '\uBC1C\uC74C1': 'graph-single-stable',
          '\uC758\uBBF81': 'graph single stable',
        };

        await db.insert('WORD_TABLE', legacyWordRow);
        await db.insert('word_expression_set', {
          'word_id': wordId,
          'seq': 1,
          'is_representative': 1,
          'spelling': 'graph-single-stable',
          'transliteration': 'graph-single-stable',
          'pronunciation': 'graph-single-stable',
        });

        final graphSingleRow = await repository
            .getWordMapByIdForGraphSingleWord(wordId);
        final snapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (entry) =>
                  entry.wordId == wordId &&
                  entry.context == 'readForGraphSingleWord',
            );
        final summary = WordRepository.debugReadSourceCollector.summaryForWord(
          wordId,
        );

        expect(graphSingleRow, isNotNull);
        expect(
          snapshot.requestedPolicy,
          ReadSourcePolicy.normalizedWithFallback,
        );
        expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
        expect(snapshot.didFallback, isFalse);
        expect(snapshot.legacyResultAvailable, isTrue);
        expect(snapshot.normalizedResultAvailable, isTrue);
        expect(summary, isNotNull);
        expect(summary!.contexts, ['readForGraphSingleWord']);
        expect(graphSingleRow!['표기1'], 'graph-single-stable');
      },
    );

    test(
      'graph single uses canonical rows when normalized success changes the visible detail display',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_RS_GRAPH_SINGLE_MISMATCH';

        final legacyWordRow = {
          'id': wordId,
          '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
          '\uD45C\uAE301': 'alpha',
          '\uC74C\uC5ED1': '\uC54C\uD30C',
          '\uBC1C\uC74C1': 'alpha',
          '\uD45C\uAE302': 'aleph',
          '\uC74C\uC5ED2': '\uC54C\uB808\uD504',
          '\uBC1C\uC74C2': 'aleph',
          '\uC758\uBBF81': 'graph single mismatch',
        };

        await db.insert('WORD_TABLE', legacyWordRow);
        await db.insert('word_expression_set', {
          'word_id': wordId,
          'seq': 1,
          'is_representative': 0,
          'spelling': 'alpha',
          'transliteration': '\uC54C\uD30C',
          'pronunciation': 'alpha',
        });
        await db.insert('word_expression_set', {
          'word_id': wordId,
          'seq': 2,
          'is_representative': 1,
          'spelling': 'aleph',
          'transliteration': '\uC54C\uB808\uD504',
          'pronunciation': 'aleph',
        });

        final graphSingleRow = await repository
            .getWordMapByIdForGraphSingleWord(wordId);
        final snapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (entry) =>
                  entry.wordId == wordId &&
                  entry.context == 'readForGraphSingleWord',
            );
        final summary = WordRepository.debugReadSourceCollector.summaryForWord(
          wordId,
        );

        expect(graphSingleRow, isNotNull);
        expect(
          snapshot.requestedPolicy,
          ReadSourcePolicy.normalizedWithFallback,
        );
        expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
        expect(snapshot.didFallback, isFalse);
        expect(snapshot.legacyResultAvailable, isTrue);
        expect(snapshot.normalizedResultAvailable, isTrue);
        expect(snapshot.fallbackObservation, isNull);
        expect(summary, isNotNull);
        expect(summary!.contexts, ['readForGraphSingleWord']);
        expect(graphSingleRow!['표기1'], 'alpha');
        expect(graphSingleRow['표기2'], 'aleph');
      },
    );
  });

  group('WordRepository detail screen display item path', () {
    test(
      'keeps the global default as LEGACY while detail screen display item read uses NORMALIZED_ONLY',
      () async {
        final repository = WordRepository();

        final rawSingleWordRow = await repository.getWordMapById('E0000_0010');
        final rawSingleWordSnapshot = WordRepository.debugReadSourceCollector
            .debugLastSnapshotForWord('E0000_0010');
        final detailRow = await repository
            .getWordDetailLikeDisplayItemByIdForDetailScreen('E0000_0010');
        final detailSnapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (snapshot) =>
                  snapshot.wordId == 'E0000_0010' &&
                  snapshot.context ==
                      'getWordDetailLikeDisplayItemByIdForDetailScreen',
            );

        expect(rawSingleWordRow, isNotNull);
        expect(detailRow, isNotNull);
        expect(rawSingleWordSnapshot, isNotNull);
        expect(
          rawSingleWordSnapshot!.requestedPolicy,
          ReadSourcePolicy.normalizedWithFallback,
        );
        expect(detailSnapshot.requestedPolicy, ReadSourcePolicy.normalizedOnly);
        expect(
          detailSnapshot.finalResultSource,
          FinalReadResultSource.normalized,
        );
        expect(detailSnapshot.didFallback, isFalse);
        expect(detailSnapshot.legacyResultAvailable, isTrue);
        expect(detailSnapshot.normalizedResultAvailable, isTrue);
        _expectSameDetailDisplay(rawSingleWordRow!, detailRow!);
      },
    );

    test(
      'uses an empty canonical expression list when detail-only API sees empty normalized rows',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        final legacyWordRow = {
          'id': 'T9000_RS_DETAIL_EMPTY',
          '언어': '테스트',
          '표기1': 'detail-empty',
          '음역1': '디테일 엠프티',
          '발음1': 'detail-empty',
          '의미1': 'detail fallback',
        };

        await db.insert('WORD_TABLE', legacyWordRow);

        final detailRow = await repository
            .getWordDetailLikeDisplayItemByIdForDetailScreen(
              'T9000_RS_DETAIL_EMPTY',
            );
        final snapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (entry) =>
                  entry.wordId == 'T9000_RS_DETAIL_EMPTY' &&
                  entry.context ==
                      'getWordDetailLikeDisplayItemByIdForDetailScreen',
            );

        expect(detailRow, isNotNull);
        expect(snapshot.requestedPolicy, ReadSourcePolicy.normalizedOnly);
        expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
        expect(snapshot.didFallback, isFalse);
        expect(snapshot.legacyResultAvailable, isTrue);
        expect(snapshot.normalizedResultAvailable, isTrue);
        expect(snapshot.fallbackObservation, isNull);
        expect(detailRow!.representativeSpelling, isNull);
        expect(detailRow.spellings, isEmpty);
      },
    );

    test(
      'uses canonical rows when normalized success changes the user-visible detail display',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        final legacyWordRow = {
          'id': 'T9000_RS_DETAIL_MISMATCH',
          '언어': '테스트',
          '표기1': 'alpha',
          '음역1': '알파',
          '발음1': 'alpha',
          '표기2': 'aleph',
          '음역2': '알레프',
          '발음2': 'aleph',
          '의미1': 'display mismatch',
        };

        await db.insert('WORD_TABLE', legacyWordRow);
        await db.insert('word_expression_set', {
          'word_id': 'T9000_RS_DETAIL_MISMATCH',
          'seq': 1,
          'is_representative': 0,
          'spelling': 'alpha',
          'transliteration': '알파',
          'pronunciation': 'alpha',
        });
        await db.insert('word_expression_set', {
          'word_id': 'T9000_RS_DETAIL_MISMATCH',
          'seq': 2,
          'is_representative': 1,
          'spelling': 'aleph',
          'transliteration': '알레프',
          'pronunciation': 'aleph',
        });

        final detailRow = await repository
            .getWordDetailLikeDisplayItemByIdForDetailScreen(
              'T9000_RS_DETAIL_MISMATCH',
            );
        final snapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (entry) =>
                  entry.wordId == 'T9000_RS_DETAIL_MISMATCH' &&
                  entry.context ==
                      'getWordDetailLikeDisplayItemByIdForDetailScreen',
            );

        expect(detailRow, isNotNull);
        expect(snapshot.requestedPolicy, ReadSourcePolicy.normalizedOnly);
        expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
        expect(snapshot.didFallback, isFalse);
        expect(snapshot.legacyResultAvailable, isTrue);
        expect(snapshot.normalizedResultAvailable, isTrue);
        expect(snapshot.fallbackObservation, isNull);
        expect(detailRow!.representativeSpelling, 'aleph');
        expect(detailRow.spellings, ['alpha', 'aleph']);
      },
    );
  });

  group('ReadSourceDebugCollector wrapper output', () {
    test(
      'provides summary-by-word, summary-by-reason, and recent raw event lines',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();

        await repository.getWordMapById('E0000_0010');

        await db.insert('WORD_TABLE', {
          'id': 'T9000_RS_SUMMARY',
          '언어': '테스트',
          '표기1': 'summary-word',
          '음역1': '서머리',
          '발음1': 'summary',
        });

        await repository.getWordDetailLikeDisplayItemByIdForDetailScreen(
          'T9000_RS_SUMMARY',
        );

        final wordSummary = WordRepository.debugReadSourceCollector
            .summaryForWord('T9000_RS_SUMMARY');
        final reasonSummaries = WordRepository.debugReadSourceCollector
            .summariesByReason();
        final recentEvents = WordRepository.debugReadSourceCollector
            .recentEvents(limit: 5);
        final wordSummaryLines = WordRepository.debugReadSourceCollector
            .formatWordSummaryLines(wordId: 'T9000_RS_SUMMARY');
        final reasonSummaryLines = WordRepository.debugReadSourceCollector
            .formatReasonSummaryLines();
        final recentEventLines = WordRepository.debugReadSourceCollector
            .formatRecentEventLines(limit: 5);

        expect(wordSummary, isNotNull);
        expect(wordSummary!.fallbackEvents, 0);
        expect(wordSummary.reasonCounts, isEmpty);
        expect(reasonSummaries, isEmpty);
        expect(recentEvents, isNotEmpty);
        expect(recentEvents.first.wordId, 'T9000_RS_SUMMARY');
        expect(wordSummaryLines.single, contains('[read-summary:word]'));
        expect(wordSummaryLines.single, contains('wordId=T9000_RS_SUMMARY'));
        expect(reasonSummaryLines, isEmpty);
        expect(recentEventLines.first, contains('[read-event]'));
        expect(recentEventLines.first, contains('reason=-'));
      },
    );
  });
}

Future<Directory> _createIsolatedWorkspace(String sourceSeedDbPath) async {
  final isolatedRoot = await Directory.systemTemp.createTemp(
    'reshet_read_source_policy_tests_',
  );
  final dataDir = Directory(p.join(isolatedRoot.path, 'data'));
  await dataDir.create(recursive: true);

  await File(sourceSeedDbPath).copy(p.join(dataDir.path, 'reshet_seed.db'));

  return isolatedRoot;
}

WordExpressionReadSnapshot _lastSnapshotFor(String wordId, String context) {
  return WordRepository.debugReadSourceCollector
      .debugRecentSnapshots()
      .lastWhere(
        (snapshot) => snapshot.wordId == wordId && snapshot.context == context,
      );
}

void _expectNormalizedSnapshot(
  String wordId,
  String context, {
  ReadSourcePolicy expectedPolicy = ReadSourcePolicy.normalizedWithFallback,
}) {
  final snapshot = _lastSnapshotFor(wordId, context);

  expect(snapshot.requestedPolicy, expectedPolicy);
  expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
  expect(snapshot.didFallback, isFalse);
  expect(snapshot.legacyResultAvailable, isTrue);
  expect(snapshot.normalizedResultAvailable, isTrue);
  expect(snapshot.fallbackObservation, isNull);
}

Future<void> _insertCanonicalClosureWord(
  dynamic db, {
  required String id,
  required String strongNumber,
  required String legacySpelling,
  required String canonicalSpelling,
  required String canonicalMeaning,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
    '\uC2A4\uD2B8\uB871\uB118\uBC84': strongNumber,
    '\uD45C\uAE301': legacySpelling,
    '\uC74C\uC5ED1': 'legacy-translit-$id',
    '\uBC1C\uC74C1': 'legacy-pron-$id',
    '\uC758\uBBF81': 'legacy meaning $id',
  });
  await db.insert('word_expression_set', {
    'word_id': id,
    'seq': 1,
    'is_representative': 1,
    'spelling': canonicalSpelling,
    'transliteration': 'canonical-translit-$id',
    'pronunciation': 'canonical-pron-$id',
  });
  await db.insert('word_meaning_set', {
    'word_id': id,
    'seq': 1,
    'meaning': canonicalMeaning,
  });
}

void _expectSameDetailDisplay(Object expectedDetail, Object actualDetail) {
  final expected = _buildDetailDisplaySummary(expectedDetail);
  final actual = _buildDetailDisplaySummary(actualDetail);

  expect(actual.representativeSpelling, expected.representativeSpelling);
  expect(actual.spellings, equals(expected.spellings));
  expect(actual.transliterations, equals(expected.transliterations));
  expect(actual.pronunciations, equals(expected.pronunciations));
  expect(actual.meanings, equals(expected.meanings));
}

({
  String? representativeSpelling,
  List<String> spellings,
  List<String> transliterations,
  List<String> pronunciations,
  List<String> meanings,
})
_buildDetailDisplaySummary(Object detail) {
  if (detail is WordDetailLikeDisplayItem) {
    return (
      representativeSpelling: detail.representativeSpelling,
      spellings: detail.spellings,
      transliterations: detail.transliterations,
      pronunciations: detail.pronunciations,
      meanings: detail.meanings,
    );
  }

  if (detail is! Map<String, dynamic>) {
    throw ArgumentError.value(
      detail,
      'detail',
      'Map<String, dynamic> 또는 WordDetailLikeDisplayItem만 비교할 수 있습니다.',
    );
  }

  final wordRow = detail;
  final readResult = readLegacyWordExpressionRow(wordRow);
  final representativeSpelling = readResult.sets.isEmpty
      ? null
      : _nullIfEmptyString(
          readResult.sets
              .firstWhere(
                (set) => set.isRepresentative,
                orElse: () => readResult.sets.first,
              )
              .spelling,
        );

  return (
    representativeSpelling: representativeSpelling,
    spellings: _collectUniqueNonEmptyValues(
      readResult.sets.map((set) => set.spelling),
    ),
    transliterations: _collectUniqueNonEmptyValues(
      readResult.sets.map((set) => set.transliteration),
    ),
    pronunciations: _collectUniqueNonEmptyValues(
      readResult.sets.map((set) => set.pronunciation),
    ),
    meanings: _collectSeries(wordRow, '의미', 7),
  );
}

String? _nullIfEmptyString(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

List<String> _collectUniqueNonEmptyValues(Iterable<String?> values) {
  final collectedValues = <String>[];

  for (final value in values) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty || collectedValues.contains(trimmed)) {
      continue;
    }
    collectedValues.add(trimmed);
  }

  return collectedValues;
}

List<String> _collectSeries(
  Map<String, dynamic> wordRow,
  String prefix,
  int count,
) {
  final values = <String>[];

  for (var index = 1; index <= count; index++) {
    final value = (wordRow['$prefix$index'] ?? '').toString().trim();
    if (value.isEmpty || values.contains(value)) {
      continue;
    }
    values.add(value);
  }

  return values;
}
