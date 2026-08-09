import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/expression/read_source_policy.dart';
import 'package:reshet_app/domain/graph/graph_visible_word.dart';
import 'package:reshet_app/domain/word/word_detail_like_display_item.dart';

import '../../support/database_test_isolation_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String repoRootPath;
  late String sourceSeedDbPath;
  late String sourceWorkDbPath;
  Directory? isolatedRoot;

  setUpAll(() async {
    repoRootPath = Directory.current.path;
    sourceSeedDbPath = p.join(repoRootPath, 'data', 'reshet_seed.db');
    sourceWorkDbPath = p.join(repoRootPath, 'data', 'reshet_work.db');

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

  group('WordRepository read source foundation', () {
    test(
      'keeps the global default as LEGACY while detail edit seed uses NORMALIZED_ONLY',
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
        final seed = await repository.getWordEditSeedForDetailEdit(
          'E0000_0010',
        );
        final snapshot = WordRepository.debugReadSourceCollector
            .debugLastSnapshotForWord('E0000_0010');

        expect(seed, isNotNull);
        expect(snapshot, isNotNull);
        expect(snapshot!.requestedPolicy, ReadSourcePolicy.normalizedOnly);
        expect(snapshot.resolvedSource, ResolvedReadSource.normalized);
        expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
        expect(snapshot.didFallback, isFalse);
        expect(snapshot.legacyResultAvailable, isFalse);
        expect(snapshot.normalizedResultAvailable, isTrue);
        expect(snapshot.readResult.sets, hasLength(2));

        final observationLog = logs.singleWhere(
          (line) => line.startsWith('[ExpressionReadSource] '),
        );
        expect(
          observationLog,
          '[ExpressionReadSource] '
          'context=readForDetailEditSeed '
          'policy=NORMALIZED_ONLY '
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

        final seed = await repository.getWordEditSeedForDetailEdit(
          'E0000_0010',
        );
        final snapshot = WordRepository.debugReadSourceCollector
            .debugLastSnapshotForWord('E0000_0010');

        expect(seed, isNotNull);
        expect(seed!.expressionReadResult.sets.first.spelling, 'Eva');
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
      'keeps Detail, Explorer, and Graph-create canonical empty as non-null normalized-only seeds',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();

        await db.insert('WORD_TABLE', {'id': 'T9000_RS_EMPTY', '언어': '테스트'});

        final detailSeed = await repository.getWordEditSeedForDetailEdit(
          'T9000_RS_EMPTY',
        );
        final explorerSeed = await repository.getWordEditSeedForExplorerEdit(
          'T9000_RS_EMPTY',
        );
        final graphCreateSeed = await repository
            .getWordEditSeedForGraphCreateEdit('T9000_RS_EMPTY');
        final detailSnapshot = _lastSnapshotFor(
          'T9000_RS_EMPTY',
          'readForDetailEditSeed',
        );
        final explorerSnapshot = _lastSnapshotFor(
          'T9000_RS_EMPTY',
          'readForExplorerEditSeed',
        );
        final graphCreateSnapshot = _lastSnapshotFor(
          'T9000_RS_EMPTY',
          'readForGraphCreateEditSeed',
        );

        expect(detailSeed, isNotNull);
        expect(detailSeed!.expressionReadResult.sets, isEmpty);
        expect(detailSnapshot.requestedPolicy, ReadSourcePolicy.normalizedOnly);
        expect(detailSnapshot.resolvedSource, ResolvedReadSource.normalized);
        expect(
          detailSnapshot.finalResultSource,
          FinalReadResultSource.normalized,
        );
        expect(detailSnapshot.didFallback, isFalse);
        expect(detailSnapshot.fallbackObservation, isNull);
        expect(detailSnapshot.readResult.sets, isEmpty);
        expect(detailSnapshot.legacyResultAvailable, isFalse);
        expect(detailSnapshot.normalizedResultAvailable, isTrue);

        expect(explorerSeed, isNotNull);
        expect(explorerSeed!.expressionReadResult.sets, isEmpty);
        expect(
          explorerSnapshot.requestedPolicy,
          ReadSourcePolicy.normalizedOnly,
        );
        expect(explorerSnapshot.resolvedSource, ResolvedReadSource.normalized);
        expect(
          explorerSnapshot.finalResultSource,
          FinalReadResultSource.normalized,
        );
        expect(explorerSnapshot.didFallback, isFalse);
        expect(explorerSnapshot.fallbackObservation, isNull);
        expect(explorerSnapshot.readResult.sets, isEmpty);
        expect(explorerSnapshot.legacyResultAvailable, isFalse);
        expect(explorerSnapshot.normalizedResultAvailable, isTrue);

        expect(graphCreateSeed, isNotNull);
        expect(graphCreateSeed!.expressionReadResult.sets, isEmpty);
        expect(
          graphCreateSnapshot.requestedPolicy,
          ReadSourcePolicy.normalizedOnly,
        );
        expect(
          graphCreateSnapshot.resolvedSource,
          ResolvedReadSource.normalized,
        );
        expect(
          graphCreateSnapshot.finalResultSource,
          FinalReadResultSource.normalized,
        );
        expect(graphCreateSnapshot.didFallback, isFalse);
        expect(graphCreateSnapshot.fallbackObservation, isNull);
        expect(graphCreateSnapshot.readResult.sets, isEmpty);
        expect(graphCreateSnapshot.legacyResultAvailable, isFalse);
        expect(graphCreateSnapshot.normalizedResultAvailable, isTrue);
      },
    );

    test(
      'fails Detail, Explorer, and Graph-create closed on query failure',
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

        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();

        await db.execute('DROP TABLE word_expression_set');

        final detailSeed = await repository.getWordEditSeedForDetailEdit(
          'E0000_0001',
        );
        final explorerSeed = await repository.getWordEditSeedForExplorerEdit(
          'E0000_0001',
        );
        final graphCreateSeed = await repository
            .getWordEditSeedForGraphCreateEdit('E0000_0001');
        final detailSnapshot = _lastSnapshotFor(
          'E0000_0001',
          'readForDetailEditSeed',
        );
        final explorerSnapshot = _lastSnapshotFor(
          'E0000_0001',
          'readForExplorerEditSeed',
        );
        final graphCreateSnapshot = _lastSnapshotFor(
          'E0000_0001',
          'readForGraphCreateEditSeed',
        );

        expect(detailSeed, isNull);
        expect(detailSnapshot.requestedPolicy, ReadSourcePolicy.normalizedOnly);
        expect(detailSnapshot.resolvedSource, ResolvedReadSource.normalized);
        expect(
          detailSnapshot.finalResultSource,
          FinalReadResultSource.normalizedFailure,
        );
        expect(detailSnapshot.didFallback, isTrue);
        expect(
          detailSnapshot.fallbackObservation!.reason,
          ReadFallbackReason.queryFailed,
        );
        expect(detailSnapshot.readResult.sets, isEmpty);
        expect(detailSnapshot.fallbackObservation!.detail, isNotEmpty);

        expect(explorerSeed, isNull);
        expect(
          explorerSnapshot.requestedPolicy,
          ReadSourcePolicy.normalizedOnly,
        );
        expect(explorerSnapshot.resolvedSource, ResolvedReadSource.normalized);
        expect(
          explorerSnapshot.finalResultSource,
          FinalReadResultSource.normalizedFailure,
        );
        expect(
          explorerSnapshot.finalResultSource,
          isNot(FinalReadResultSource.legacyFallback),
        );
        expect(explorerSnapshot.didFallback, isTrue);
        expect(
          explorerSnapshot.fallbackObservation!.reason,
          ReadFallbackReason.queryFailed,
        );
        expect(explorerSnapshot.readResult.sets, isEmpty);
        expect(explorerSnapshot.legacyReadResult, isNull);
        expect(explorerSnapshot.fallbackObservation!.detail, isNotEmpty);

        expect(graphCreateSeed, isNull);
        expect(
          graphCreateSnapshot.requestedPolicy,
          ReadSourcePolicy.normalizedOnly,
        );
        expect(
          graphCreateSnapshot.resolvedSource,
          ResolvedReadSource.normalized,
        );
        expect(
          graphCreateSnapshot.finalResultSource,
          FinalReadResultSource.normalizedFailure,
        );
        expect(
          graphCreateSnapshot.finalResultSource,
          isNot(FinalReadResultSource.legacyFallback),
        );
        expect(graphCreateSnapshot.didFallback, isTrue);
        expect(
          graphCreateSnapshot.fallbackObservation!.reason,
          ReadFallbackReason.queryFailed,
        );
        expect(graphCreateSnapshot.readResult.sets, isEmpty);
        expect(graphCreateSnapshot.legacyReadResult, isNull);
        expect(graphCreateSnapshot.fallbackObservation!.detail, isNotEmpty);

        final detailObservationLog = logs.singleWhere(
          (line) =>
              line.startsWith('[ExpressionReadSource] ') &&
              line.contains('context=readForDetailEditSeed '),
        );
        expect(
          detailObservationLog,
          '[ExpressionReadSource] '
          'context=readForDetailEditSeed '
          'policy=NORMALIZED_ONLY '
          'resolved=normalized '
          'final=normalized_failure '
          'reason=query_failed',
        );
        expect(detailObservationLog, isNot(contains('E0000_0001')));
        expect(
          detailObservationLog,
          isNot(contains(detailSnapshot.fallbackObservation!.detail!)),
        );
        expect(detailObservationLog, isNot(contains('word_expression_set')));

        final explorerObservationLog = logs.singleWhere(
          (line) =>
              line.startsWith('[ExpressionReadSource] ') &&
              line.contains('context=readForExplorerEditSeed '),
        );
        expect(
          explorerObservationLog,
          '[ExpressionReadSource] '
          'context=readForExplorerEditSeed '
          'policy=NORMALIZED_ONLY '
          'resolved=normalized '
          'final=normalized_failure '
          'reason=query_failed',
        );
        expect(explorerObservationLog, isNot(contains('E0000_0001')));
        expect(
          explorerObservationLog,
          isNot(contains(explorerSnapshot.fallbackObservation!.detail!)),
        );
        expect(explorerObservationLog, isNot(contains('word_expression_set')));

        final graphCreateObservationLog = logs.singleWhere(
          (line) =>
              line.startsWith('[ExpressionReadSource] ') &&
              line.contains('context=readForGraphCreateEditSeed '),
        );
        expect(
          graphCreateObservationLog,
          '[ExpressionReadSource] '
          'context=readForGraphCreateEditSeed '
          'policy=NORMALIZED_ONLY '
          'resolved=normalized '
          'final=normalized_failure '
          'reason=query_failed',
        );
        expect(graphCreateObservationLog, isNot(contains('E0000_0001')));
        expect(
          graphCreateObservationLog,
          isNot(contains(graphCreateSnapshot.fallbackObservation!.detail!)),
        );
        expect(
          graphCreateObservationLog,
          isNot(contains('word_expression_set')),
        );
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
        await db.insert('WORD_TABLE', {'id': 'T9000_RS_MIN_EXPR', '언어': '테스트'});
        await db.insert('word_expression_set', {
          'word_id': 'T9000_RS_MIN_EXPR',
          'seq': 1,
          'is_representative': 1,
          'spelling': '   ',
          'transliteration': 'issue-only',
          'pronunciation': 'issue-only',
        });
        await db.execute('PRAGMA ignore_check_constraints = OFF');

        final seed = await repository.getWordEditSeedForDetailEdit(
          'T9000_RS_MIN_EXPR',
        );
        final snapshot = WordRepository.debugReadSourceCollector
            .debugLastSnapshotForWord('T9000_RS_MIN_EXPR');

        expect(seed, isNotNull);
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
      'fails Detail, Explorer, and Graph-create closed on mapping-invalid rows',
      () async {
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

        await db.insert('WORD_TABLE', {'id': 'T9000_RS_MAPPING', '언어': '테스트'});
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

        final detailSeed = await repository.getWordEditSeedForDetailEdit(
          'T9000_RS_MAPPING',
        );
        final explorerSeed = await repository.getWordEditSeedForExplorerEdit(
          'T9000_RS_MAPPING',
        );
        final graphCreateSeed = await repository
            .getWordEditSeedForGraphCreateEdit('T9000_RS_MAPPING');
        final detailSnapshot = _lastSnapshotFor(
          'T9000_RS_MAPPING',
          'readForDetailEditSeed',
        );
        final explorerSnapshot = _lastSnapshotFor(
          'T9000_RS_MAPPING',
          'readForExplorerEditSeed',
        );
        final graphCreateSnapshot = _lastSnapshotFor(
          'T9000_RS_MAPPING',
          'readForGraphCreateEditSeed',
        );

        expect(detailSeed, isNull);
        expect(detailSnapshot.requestedPolicy, ReadSourcePolicy.normalizedOnly);
        expect(detailSnapshot.resolvedSource, ResolvedReadSource.normalized);
        expect(
          detailSnapshot.finalResultSource,
          FinalReadResultSource.normalizedFailure,
        );
        expect(detailSnapshot.didFallback, isTrue);
        expect(
          detailSnapshot.fallbackObservation!.reason,
          ReadFallbackReason.mappingInvalid,
        );
        expect(
          detailSnapshot.fallbackObservation!.detail,
          contains('duplicate seq'),
        );
        expect(detailSnapshot.readResult.sets, isEmpty);

        expect(explorerSeed, isNull);
        expect(
          explorerSnapshot.requestedPolicy,
          ReadSourcePolicy.normalizedOnly,
        );
        expect(explorerSnapshot.resolvedSource, ResolvedReadSource.normalized);
        expect(
          explorerSnapshot.finalResultSource,
          FinalReadResultSource.normalizedFailure,
        );
        expect(
          explorerSnapshot.finalResultSource,
          isNot(FinalReadResultSource.legacyFallback),
        );
        expect(explorerSnapshot.didFallback, isTrue);
        expect(
          explorerSnapshot.fallbackObservation!.reason,
          ReadFallbackReason.mappingInvalid,
        );
        expect(
          explorerSnapshot.fallbackObservation!.detail,
          contains('duplicate seq'),
        );
        expect(explorerSnapshot.readResult.sets, isEmpty);
        expect(explorerSnapshot.legacyReadResult, isNull);

        expect(graphCreateSeed, isNull);
        expect(
          graphCreateSnapshot.requestedPolicy,
          ReadSourcePolicy.normalizedOnly,
        );
        expect(
          graphCreateSnapshot.resolvedSource,
          ResolvedReadSource.normalized,
        );
        expect(
          graphCreateSnapshot.finalResultSource,
          FinalReadResultSource.normalizedFailure,
        );
        expect(
          graphCreateSnapshot.finalResultSource,
          isNot(FinalReadResultSource.legacyFallback),
        );
        expect(graphCreateSnapshot.didFallback, isTrue);
        expect(
          graphCreateSnapshot.fallbackObservation!.reason,
          ReadFallbackReason.mappingInvalid,
        );
        expect(
          graphCreateSnapshot.fallbackObservation!.detail,
          contains('duplicate seq'),
        );
        expect(graphCreateSnapshot.readResult.sets, isEmpty);
        expect(graphCreateSnapshot.legacyReadResult, isNull);
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

        await db.insert('WORD_TABLE', {'id': 'T9000_RS_STRICT', '언어': '테스트'});

        final seed = await repository.getWordEditSeedForDetailEdit(
          'T9000_RS_STRICT',
        );
        final snapshot = WordRepository.debugReadSourceCollector
            .debugLastSnapshotForWord('T9000_RS_STRICT');

        expect(seed, isNotNull);
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
      'user-facing feature contexts work without legacy expression columns',
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
          canonicalSpelling: 'canonical-closure-center',
          canonicalMeaning: 'canonical closure center meaning',
        );
        await _insertCanonicalClosureWord(
          db,
          id: targetWordId,
          strongNumber: strongNumber,
          canonicalSpelling: canonicalTitle,
          canonicalMeaning: canonicalMeaning,
        );
        await db.insert('WORD_RELATION', {
          'word_id_1': centerWordId,
          'word_id_2': targetWordId,
          'direction_code': 'unknown',
          'updated_at': DateTime.now().toIso8601String(),
        });
        await _expectLegacyExpressionColumnsAbsent(db);

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
        _expectNormalizedSnapshot(
          targetWordId,
          'readForDetailEditSeed',
          expectedPolicy: ReadSourcePolicy.normalizedOnly,
        );
        final explorerSeed = await repository.getWordEditSeedForExplorerEdit(
          targetWordId,
        );
        _expectNormalizedSnapshot(
          targetWordId,
          'readForExplorerEditSeed',
          expectedPolicy: ReadSourcePolicy.normalizedOnly,
        );
        final graphEditSeed = await repository
            .getWordEditSeedForGraphCreateEdit(targetWordId);
        _expectNormalizedSnapshot(
          targetWordId,
          'readForGraphCreateEditSeed',
          expectedPolicy: ReadSourcePolicy.normalizedOnly,
        );
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
        canonicalSpelling: 'legacy-generic-title',
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
        expect(splitViewSnapshot.legacyResultAvailable, isFalse);
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
        expect(snapshot.legacyResultAvailable, isFalse);
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
        });
        await db.insert('WORD_TABLE', {
          'id': childWordId,
          '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
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
        expect(graphSnapshot.legacyResultAvailable, isFalse);
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
        });
        await db.insert('WORD_TABLE', {
          'id': childWordId,
          '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
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
        expect(snapshot.legacyResultAvailable, isFalse);
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
        });
        for (final childWordId in childWordIds) {
          await db.insert('WORD_TABLE', {
            'id': childWordId,
            '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
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

  group('WordRepository detail screen display item path', () {
    test(
      'keeps the global default as LEGACY while detail screen display item read uses NORMALIZED_ONLY',
      () async {
        final repository = WordRepository();

        expect(
          WordRepository.debugCurrentReadSourcePolicy,
          ReadSourcePolicy.legacy,
        );
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

        expect(detailRow, isNotNull);
        expect(detailSnapshot.requestedPolicy, ReadSourcePolicy.normalizedOnly);
        expect(
          detailSnapshot.finalResultSource,
          FinalReadResultSource.normalized,
        );
        expect(detailSnapshot.didFallback, isFalse);
        expect(detailSnapshot.legacyResultAvailable, isFalse);
        expect(detailSnapshot.normalizedResultAvailable, isTrue);
      },
    );

    test(
      'uses an empty canonical expression list when detail-only API sees empty normalized rows',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        final legacyWordRow = {'id': 'T9000_RS_DETAIL_EMPTY', '언어': '테스트'};

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
        expect(snapshot.legacyResultAvailable, isFalse);
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
        final legacyWordRow = {'id': 'T9000_RS_DETAIL_MISMATCH', '언어': '테스트'};

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
        expect(snapshot.legacyResultAvailable, isFalse);
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

        await db.insert('WORD_TABLE', {'id': 'T9000_RS_SUMMARY', '언어': '테스트'});

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
  expect(snapshot.legacyResultAvailable, isFalse);
  expect(snapshot.normalizedResultAvailable, isTrue);
  expect(snapshot.fallbackObservation, isNull);
}

Future<void> _expectLegacyExpressionColumnsAbsent(dynamic db) async {
  final legacyColumns = <String>[
    for (final prefix in const ['표기', '음역', '발음'])
      for (var index = 1; index <= 6; index++) '$prefix$index',
  ];

  final remainingColumns = (await db.rawQuery(
    "PRAGMA table_info('WORD_TABLE')",
  )).map((row) => row['name']).whereType<String>().toSet();
  expect(remainingColumns.intersection(legacyColumns.toSet()), isEmpty);
}

Future<void> _insertCanonicalClosureWord(
  dynamic db, {
  required String id,
  required String strongNumber,
  required String canonicalSpelling,
  required String canonicalMeaning,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
    '\uC2A4\uD2B8\uB871\uB118\uBC84': strongNumber,
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

void _expectSameDetailDisplay(
  WordDetailLikeDisplayItem expected,
  WordDetailLikeDisplayItem actual,
) {
  expect(actual.representativeSpelling, expected.representativeSpelling);
  expect(actual.spellings, equals(expected.spellings));
  expect(actual.transliterations, equals(expected.transliterations));
  expect(actual.pronunciations, equals(expected.pronunciations));
  expect(actual.meanings, equals(expected.meanings));
}
