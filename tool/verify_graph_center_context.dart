import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:reshet_app/data/models/word.dart';
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/expression/read_source_policy.dart';
import 'package:reshet_app/ui/word_graph_cache.dart';

typedef _GraphLoadResult = ({
  Word centerWord,
  List<Word> connectedWords,
  List<WordRelationEdgeInfo> relationEdges,
  bool usedBaseCache,
});

Future<void> main() async {
  final exitCodeValue = await _runVerification();
  exit(exitCodeValue);
}

Future<int> _runVerification() async {
  final repoRootPath = Directory.current.path;
  final sourceWorkDbPath = p.join(repoRootPath, 'data', 'reshet_work.db');
  Directory? isolatedRoot;
  Directory? tmpRoot;

  try {
    if (!File(sourceWorkDbPath).existsSync()) {
      stderr.writeln('[verify] missing source work db: $sourceWorkDbPath');
      return 1;
    }

    final isolatedWorkspace = await _createIsolatedWorkspace(
      repoRootPath,
      sourceWorkDbPath,
    );
    isolatedRoot = isolatedWorkspace.isolatedRoot;
    tmpRoot = isolatedWorkspace.tmpRoot;
    Directory.current = isolatedRoot.path;

    await DatabaseService.closeDatabase();
    await DatabaseService.initialize();
    WordRepository.debugSetReadSourcePolicyOverride(null);
    WordRepository.debugReadSourceCollector.debugReset();
    WordGraphDataCache.clear();

    final repository = WordRepository();
    final db = await DatabaseService.openDatabaseFile();

    const centerWordId = 'T9000_RS_GRAPH_CENTER_ZONE';
    const childWordId = 'T9000_RS_GRAPH_CENTER_ZONE_CHILD';
    const emptyCenterWordId = 'T9000_RS_GRAPH_CENTER_EMPTY';
    const mismatchCenterWordId = 'T9000_RS_GRAPH_CENTER_DETAIL_MISMATCH';

    await _insertStableWord(
      db,
      id: centerWordId,
      spelling: 'graph-center-zone',
      meaning: 'graph center zone',
    );
    await _insertStableExpressionSet(
      db,
      wordId: centerWordId,
      spelling: 'graph-center-zone',
    );

    await _insertStableWord(
      db,
      id: childWordId,
      spelling: 'graph-center-child',
      meaning: 'graph center child',
    );
    await _insertStableExpressionSet(
      db,
      wordId: childWordId,
      spelling: 'graph-center-child',
    );

    await _insertStableWord(
      db,
      id: emptyCenterWordId,
      spelling: 'graph-center-empty',
      meaning: 'graph center empty',
    );
    await _insertStableExpressionSet(
      db,
      wordId: emptyCenterWordId,
      spelling: 'graph-center-empty',
    );

    await _insertMismatchWord(
      db,
      id: mismatchCenterWordId,
      primarySpelling: 'alpha',
      primaryTransliteration: 'alpha',
      secondarySpelling: 'aleph',
      secondaryTransliteration: 'aleph',
      meaning: 'detail mismatch center',
    );

    await db.insert('WORD_RELATION', {
      'word_id_1': centerWordId,
      'word_id_2': childWordId,
      'direction_code': 'unknown',
      'updated_at': DateTime.now().toIso8601String(),
    });

    final failures = <String>[];

    WordRepository.debugReadSourceCollector.debugReset();
    WordGraphDataCache.clear();
    final scenarioA = await _loadGraphSteadyState(
      repository: repository,
      centerWordId: centerWordId,
    );
    final genericRows = await repository.getWordsByIds([childWordId]);
    final centerSnapshotA = _findLastSnapshot(
      wordId: centerWordId,
      context: 'readForGraphCenterSingleWord',
    );
    final childSnapshotA = _findLastSnapshot(
      wordId: childWordId,
      context: 'readForGraphBatch',
    );
    final genericSnapshotA = _findLastSnapshot(
      wordId: childWordId,
      context: 'getWordsByIds',
    );
    final centerSummaryA = WordRepository.debugReadSourceCollector
        .summaryForWord(centerWordId);
    final childSummaryA = WordRepository.debugReadSourceCollector
        .summaryForWord(childWordId);

    stdout.writeln(
      '[verify:A] center snapshot: '
      'context=${centerSnapshotA?.context ?? "-"} '
      'policy=${centerSnapshotA?.requestedPolicy.name ?? "-"} '
      'final=${centerSnapshotA?.finalResultSource.name ?? "-"}',
    );
    stdout.writeln(
      '[verify:A] child snapshot: '
      'context=${childSnapshotA?.context ?? "-"} '
      'policy=${childSnapshotA?.requestedPolicy.name ?? "-"} '
      'final=${childSnapshotA?.finalResultSource.name ?? "-"}',
    );
    stdout.writeln(
      '[verify:A] generic snapshot: '
      'context=${genericSnapshotA?.context ?? "-"} '
      'policy=${genericSnapshotA?.requestedPolicy.name ?? "-"} '
      'final=${genericSnapshotA?.finalResultSource.name ?? "-"}',
    );
    stdout.writeln(
      '[verify:A] center summary='
      '${centerSummaryA?.formatLine() ?? "-"}',
    );
    stdout.writeln(
      '[verify:A] child summary='
      '${childSummaryA?.formatLine() ?? "-"}',
    );

    if (scenarioA.centerWord.id != centerWordId) {
      failures.add('scenario A: graph center word id was not resolved');
    }
    if (scenarioA.connectedWords.length != 1 ||
        scenarioA.connectedWords.single.id != childWordId) {
      failures.add('scenario A: graph child load did not stay intact');
    }
    if (genericRows.length != 1 ||
        (genericRows.single['id'] ?? '').toString() != childWordId) {
      failures.add('scenario A: generic batch no longer returns the child row');
    }
    if (centerSnapshotA == null ||
        centerSnapshotA.context != 'readForGraphCenterSingleWord') {
      failures.add('scenario A: center context was not recorded separately');
    } else {
      if (centerSnapshotA.requestedPolicy !=
          ReadSourcePolicy.normalizedWithFallback) {
        failures.add(
          'scenario A: center policy was not normalizedWithFallback',
        );
      }
      if (centerSnapshotA.finalResultSource !=
          FinalReadResultSource.normalized) {
        failures.add('scenario A: stable center did not stay on normalized');
      }
    }
    if (childSnapshotA == null ||
        childSnapshotA.context != 'readForGraphBatch') {
      failures.add(
        'scenario A: child context no longer uses readForGraphBatch',
      );
    }
    if (genericSnapshotA == null ||
        genericSnapshotA.requestedPolicy != ReadSourcePolicy.legacy ||
        genericSnapshotA.finalResultSource != FinalReadResultSource.legacy) {
      failures.add('scenario A: generic batch stopped behaving as legacy');
    }
    if (centerSummaryA == null ||
        centerSummaryA.contexts.toSet().length != 1 ||
        !centerSummaryA.contexts.contains('readForGraphCenterSingleWord')) {
      failures.add('scenario A: center summary contexts were not isolated');
    }
    if (childSummaryA == null ||
        !childSummaryA.contexts.contains('readForGraphBatch') ||
        !childSummaryA.contexts.contains('getWordsByIds')) {
      failures.add(
        'scenario A: child summary did not keep batch/generic split',
      );
    }

    WordRepository.debugReadSourceCollector.debugReset();
    WordGraphDataCache.clear();
    final scenarioB = await _loadGraphSteadyState(
      repository: repository,
      centerWordId: emptyCenterWordId,
    );
    final emptyCenterSnapshot = _findLastSnapshot(
      wordId: emptyCenterWordId,
      context: 'readForGraphCenterSingleWord',
    );
    final emptyCenterSummary = WordRepository.debugReadSourceCollector
        .summaryForWord(emptyCenterWordId);

    stdout.writeln(
      '[verify:B] empty center summary='
      '${emptyCenterSummary?.formatLine() ?? "-"}',
    );

    if (scenarioB.connectedWords.isNotEmpty ||
        scenarioB.relationEdges.isNotEmpty) {
      failures.add(
        'scenario B: empty-relation graph unexpectedly loaded edges',
      );
    }
    if (emptyCenterSnapshot == null || emptyCenterSummary == null) {
      failures.add(
        'scenario B: empty-relation graph did not record center read',
      );
    }

    WordRepository.debugReadSourceCollector.debugReset();
    WordGraphDataCache.clear();
    final cacheMissLoad = await _loadGraphSteadyState(
      repository: repository,
      centerWordId: centerWordId,
    );
    final cacheMissCenterSnapshot = _findLastSnapshot(
      wordId: centerWordId,
      context: 'readForGraphCenterSingleWord',
    );
    final cacheMissChildSnapshot = _findLastSnapshot(
      wordId: childWordId,
      context: 'readForGraphBatch',
    );

    WordRepository.debugReadSourceCollector.debugReset();
    final cacheHitLoad = await _loadGraphSteadyState(
      repository: repository,
      centerWordId: centerWordId,
    );
    final cacheHitCenterSnapshot = _findLastSnapshot(
      wordId: centerWordId,
      context: 'readForGraphCenterSingleWord',
    );
    final cacheHitChildSnapshot = _findLastSnapshot(
      wordId: childWordId,
      context: 'readForGraphBatch',
    );
    final cacheHitCenterSummary = WordRepository.debugReadSourceCollector
        .summaryForWord(centerWordId);

    stdout.writeln(
      '[verify:C] cache miss usedBaseCache=${cacheMissLoad.usedBaseCache} '
      'centerContext=${cacheMissCenterSnapshot?.context ?? "-"} '
      'childContext=${cacheMissChildSnapshot?.context ?? "-"}',
    );
    stdout.writeln(
      '[verify:C] cache hit usedBaseCache=${cacheHitLoad.usedBaseCache} '
      'centerContext=${cacheHitCenterSnapshot?.context ?? "-"} '
      'childContext=${cacheHitChildSnapshot?.context ?? "-"}',
    );
    stdout.writeln(
      '[verify:C] cache hit center summary='
      '${cacheHitCenterSummary?.formatLine() ?? "-"}',
    );

    if (cacheMissLoad.usedBaseCache) {
      failures.add('scenario C: first load unexpectedly used the base cache');
    }
    if (!cacheHitLoad.usedBaseCache) {
      failures.add('scenario C: second load did not use the base cache');
    }
    if (cacheHitCenterSnapshot == null) {
      failures.add('scenario C: cache hit lost the center context observation');
    }
    if (cacheHitChildSnapshot != null) {
      failures.add(
        'scenario C: cache hit reloaded graph batch children unexpectedly',
      );
    }

    WordRepository.debugReadSourceCollector.debugReset();
    WordGraphDataCache.clear();
    final detailLikeRow = await repository
        .getWordDetailMapByIdForReadSourcePhase2Only(mismatchCenterWordId);
    final graphCenterLoad = await _loadGraphSteadyState(
      repository: repository,
      centerWordId: mismatchCenterWordId,
    );
    final graphCenterSnapshotD = _findLastSnapshot(
      wordId: mismatchCenterWordId,
      context: 'readForGraphCenterSingleWord',
    );
    final detailWord = detailLikeRow == null
        ? null
        : Word.fromMap(detailLikeRow);
    final graphCenterWord = graphCenterLoad.centerWord;

    stdout.writeln(
      '[verify:D] detail word: '
      'spelling1=${detailWord?.spelling1} meaning1=${detailWord?.meaning1}',
    );
    stdout.writeln(
      '[verify:D] graph center word: '
      'spelling1=${graphCenterWord.spelling1} meaning1=${graphCenterWord.meaning1}',
    );
    stdout.writeln(
      '[verify:D] graph center snapshot: '
      'context=${graphCenterSnapshotD?.context ?? "-"} '
      'final=${graphCenterSnapshotD?.finalResultSource.name ?? "-"} '
      'reason=${graphCenterSnapshotD?.fallbackObservation?.reason.name ?? "-"}',
    );

    if (detailWord == null) {
      failures.add('scenario D: detail-like row could not be loaded');
    } else {
      if (detailWord.spelling1 != graphCenterWord.spelling1 ||
          detailWord.transliteration1 != graphCenterWord.transliteration1 ||
          detailWord.pronunciation1 != graphCenterWord.pronunciation1 ||
          detailWord.meaning1 != graphCenterWord.meaning1) {
        failures.add(
          'scenario D: graph center display no longer matches detail-like safe zone',
        );
      }
    }
    if (graphCenterSnapshotD == null ||
        graphCenterSnapshotD.finalResultSource !=
            FinalReadResultSource.legacyFallback ||
        graphCenterSnapshotD.fallbackObservation?.reason !=
            ReadFallbackReason.userVisibleDisplayMismatch) {
      failures.add(
        'scenario D: graph center mismatch did not use detail-like fallback guard',
      );
    }

    if (failures.isNotEmpty) {
      for (final failure in failures) {
        stderr.writeln('[verify] failure: $failure');
      }
      return 1;
    }

    stdout.writeln(
      '[verify] success: graph center controlled zone, empty graph observation, '
      'cache-hit center reread, and detail-like display alignment are intact.',
    );
    return 0;
  } catch (error, stackTrace) {
    stderr.writeln('[verify] exception: $error');
    stderr.writeln(stackTrace);
    return 1;
  } finally {
    await DatabaseService.closeDatabase();
    WordRepository.debugSetReadSourcePolicyOverride(null);
    WordRepository.debugReadSourceCollector.debugReset();
    WordGraphDataCache.clear();
    Directory.current = repoRootPath;

    if (isolatedRoot != null && isolatedRoot.existsSync()) {
      try {
        await isolatedRoot.delete(recursive: true);
      } catch (error) {
        stderr.writeln(
          '[verify] warning: failed to delete isolated workspace: $error',
        );
      }
    }

    if (tmpRoot != null && tmpRoot.existsSync()) {
      try {
        if (tmpRoot.listSync().isEmpty) {
          await tmpRoot.delete(recursive: true);
        }
      } catch (error) {
        stderr.writeln('[verify] warning: failed to delete temp root: $error');
      }
    }
  }
}

Future<_GraphLoadResult> _loadGraphSteadyState({
  required WordRepository repository,
  required String centerWordId,
}) async {
  final centerWordMap = await repository.getWordMapByIdForGraphCenterSingleWord(
    centerWordId,
  );
  if (centerWordMap == null) {
    throw StateError('Graph center word not found: $centerWordId');
  }

  final centerWord = Word.fromMap(centerWordMap);
  final cachedBaseGraph = WordGraphDataCache.getBaseGraph(
    centerWordId: centerWordId,
  );
  if (cachedBaseGraph != null) {
    return (
      centerWord: centerWord,
      connectedWords: cachedBaseGraph.connectedWords,
      relationEdges: cachedBaseGraph.relationEdges,
      usedBaseCache: true,
    );
  }

  final visibleGraphData = await repository.getVisibleGraphDataForGraph(
    centerWordId,
  );
  WordGraphDataCache.putBaseGraph(
    centerWordId: centerWordId,
    connectedWords: visibleGraphData.connectedWords,
    relationEdges: visibleGraphData.relationEdges,
  );
  return (
    centerWord: centerWord,
    connectedWords: visibleGraphData.connectedWords,
    relationEdges: visibleGraphData.relationEdges,
    usedBaseCache: false,
  );
}

Future<void> _insertStableWord(
  dynamic db, {
  required String id,
  required String spelling,
  required String meaning,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
    '\uD45C\uAE301': spelling,
    '\uC74C\uC5ED1': spelling,
    '\uBC1C\uC74C1': spelling,
    '\uC758\uBBF81': meaning,
  });
}

Future<void> _insertStableExpressionSet(
  dynamic db, {
  required String wordId,
  required String spelling,
}) async {
  await db.insert('word_expression_set', {
    'word_id': wordId,
    'seq': 1,
    'is_representative': 1,
    'spelling': spelling,
    'transliteration': spelling,
    'pronunciation': spelling,
  });
}

Future<void> _insertMismatchWord(
  dynamic db, {
  required String id,
  required String primarySpelling,
  required String primaryTransliteration,
  required String secondarySpelling,
  required String secondaryTransliteration,
  required String meaning,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
    '\uD45C\uAE301': primarySpelling,
    '\uC74C\uC5ED1': primaryTransliteration,
    '\uBC1C\uC74C1': primarySpelling,
    '\uD45C\uAE302': secondarySpelling,
    '\uC74C\uC5ED2': secondaryTransliteration,
    '\uBC1C\uC74C2': secondarySpelling,
    '\uC758\uBBF81': meaning,
  });
  await db.insert('word_expression_set', {
    'word_id': id,
    'seq': 1,
    'is_representative': 0,
    'spelling': primarySpelling,
    'transliteration': primaryTransliteration,
    'pronunciation': primarySpelling,
  });
  await db.insert('word_expression_set', {
    'word_id': id,
    'seq': 2,
    'is_representative': 1,
    'spelling': secondarySpelling,
    'transliteration': secondaryTransliteration,
    'pronunciation': secondarySpelling,
  });
}

WordExpressionReadSnapshot? _findLastSnapshot({
  required String wordId,
  required String context,
}) {
  final snapshots = WordRepository.debugReadSourceCollector
      .debugRecentSnapshots();
  for (final snapshot in snapshots.reversed) {
    if (snapshot.wordId == wordId && snapshot.context == context) {
      return snapshot;
    }
  }
  return null;
}

Future<({Directory isolatedRoot, Directory tmpRoot})> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(p.join(repoRootPath, '.tmp_graph_center_verify'));
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

  return (isolatedRoot: isolatedRoot, tmpRoot: tmpRoot);
}
