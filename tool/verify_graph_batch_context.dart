// Verification-only tool for Phase 4-E graph batch policy promotion.
//
// This script does not modify production behavior. It creates an isolated
// workspace database, runs graph-owned batch reads for a normalized-success
// case and a display-mismatch fallback case, then compares them with a generic
// batch read so the collector context separation can be verified.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/expression/read_source_policy.dart';

Future<void> main() async {
  final exitCodeValue = await _runVerification();
  exit(exitCodeValue);
}

Future<int> _runVerification() async {
  final repoRootPath = Directory.current.path;
  final sourceWorkDbPath = p.join(repoRootPath, 'data', 'reshet_work.db');
  Directory? isolatedRoot;

  try {
    if (!File(sourceWorkDbPath).existsSync()) {
      stderr.writeln('[verify] missing source work db: $sourceWorkDbPath');
      return 1;
    }

    isolatedRoot = await _createIsolatedWorkspace(
      repoRootPath,
      sourceWorkDbPath,
    );
    Directory.current = isolatedRoot.path;

    await DatabaseService.closeDatabase();
    await DatabaseService.initialize();
    WordRepository.debugSetReadSourcePolicyOverride(null);
    WordRepository.debugReadSourceCollector.debugReset();

    final repository = WordRepository();
    final db = await DatabaseService.openDatabaseFile();

    const centerWordId = 'T9000_RS_GRAPH_CENTER';
    const stableChildWordId = 'T9000_RS_GRAPH_CHILD_STABLE';
    const mismatchChildWordId = 'T9000_RS_GRAPH_CHILD_MISMATCH';

    await _insertWord(
      db,
      id: centerWordId,
      spelling: 'graph-center',
      meaning: 'graph center',
    );
    await _insertWord(
      db,
      id: stableChildWordId,
      spelling: 'graph-stable',
      meaning: 'graph stable',
    );
    await db.insert('word_expression_set', {
      'word_id': stableChildWordId,
      'seq': 1,
      'is_representative': 1,
      'spelling': 'graph-stable',
      'transliteration': 'graph-stable',
      'pronunciation': 'graph-stable',
    });
    await db.insert('WORD_TABLE', {
      'id': mismatchChildWordId,
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
      'word_id': mismatchChildWordId,
      'seq': 1,
      'is_representative': 0,
      'spelling': 'alpha',
      'transliteration': '\uC54C\uD30C',
      'pronunciation': 'alpha',
    });
    await db.insert('word_expression_set', {
      'word_id': mismatchChildWordId,
      'seq': 2,
      'is_representative': 1,
      'spelling': 'aleph',
      'transliteration': '\uC54C\uB808\uD504',
      'pronunciation': 'aleph',
    });
    await db.insert('WORD_RELATION', {
      'word_id_1': centerWordId,
      'word_id_2': stableChildWordId,
      'direction_code': 'unknown',
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert('WORD_RELATION', {
      'word_id_1': centerWordId,
      'word_id_2': mismatchChildWordId,
      'direction_code': 'unknown',
      'updated_at': DateTime.now().toIso8601String(),
    });

    final graphData = await repository.getVisibleGraphDataForGraph(
      centerWordId,
    );
    final genericRows = await repository.getWordsByIds([stableChildWordId]);
    final snapshots = WordRepository.debugReadSourceCollector
        .debugRecentSnapshots();

    final stableGraphSnapshot = snapshots.lastWhere(
      (snapshot) =>
          snapshot.wordId == stableChildWordId &&
          snapshot.context == 'readForGraphBatch',
    );
    final mismatchGraphSnapshot = snapshots.lastWhere(
      (snapshot) =>
          snapshot.wordId == mismatchChildWordId &&
          snapshot.context == 'readForGraphBatch',
    );
    final genericSnapshot = snapshots.lastWhere(
      (snapshot) =>
          snapshot.wordId == stableChildWordId &&
          snapshot.context == 'getWordsByIds',
    );
    final stableSummary = WordRepository.debugReadSourceCollector.summaryForWord(
      stableChildWordId,
    );
    final graphWordsById = {
      for (final word in graphData.connectedWords) word.id: word,
    };
    final stableGraphWord = graphWordsById[stableChildWordId];
    final mismatchGraphWord = graphWordsById[mismatchChildWordId];

    stdout.writeln('[verify] isolated workspace: ${isolatedRoot.path}');
    stdout.writeln(
      '[verify] graph connectedWords=${graphData.connectedWords.length}',
    );
    stdout.writeln('[verify] generic rows=${genericRows.length}');
    stdout.writeln(
      '[verify] graph stable word: '
      'spelling1=${stableGraphWord?.spelling1} '
      'meaning1=${stableGraphWord?.meaning1}',
    );
    stdout.writeln(
      '[verify] graph mismatch word: '
      'spelling1=${mismatchGraphWord?.spelling1} '
      'meaning1=${mismatchGraphWord?.meaning1}',
    );
    stdout.writeln(
      '[verify] graph normalized snapshot: '
      'wordId=${stableGraphSnapshot.wordId} '
      'context=${stableGraphSnapshot.context} '
      'policy=${stableGraphSnapshot.requestedPolicy.name} '
      'final=${stableGraphSnapshot.finalResultSource.name}',
    );
    stdout.writeln(
      '[verify] graph fallback snapshot: '
      'wordId=${mismatchGraphSnapshot.wordId} '
      'context=${mismatchGraphSnapshot.context} '
      'policy=${mismatchGraphSnapshot.requestedPolicy.name} '
      'final=${mismatchGraphSnapshot.finalResultSource.name} '
      'reason=${mismatchGraphSnapshot.fallbackObservation?.reason.name ?? "-"}',
    );
    stdout.writeln(
      '[verify] generic snapshot: '
      'wordId=${genericSnapshot.wordId} '
      'context=${genericSnapshot.context} '
      'policy=${genericSnapshot.requestedPolicy.name} '
      'final=${genericSnapshot.finalResultSource.name}',
    );
    stdout.writeln(
      '[verify] stable summary contexts='
      '${stableSummary?.contexts.join("|") ?? "-"}',
    );

    final failures = <String>[];
    if (graphData.connectedWords.length != 2) {
      failures.add('graph batch did not resolve the expected child words');
    }
    if (stableGraphWord == null || stableGraphWord.id != stableChildWordId) {
      failures.add('graph batch did not resolve the stable child word');
    }
    if (mismatchGraphWord == null ||
        mismatchGraphWord.id != mismatchChildWordId) {
      failures.add('graph batch did not resolve the mismatch child word');
    }
    if (stableGraphWord?.spelling1 != 'graph-stable') {
      failures.add('graph stable word display was not preserved');
    }
    if (mismatchGraphWord?.spelling1 != 'alpha') {
      failures.add('graph mismatch word did not fall back to legacy display');
    }
    if (genericRows.length != 1 ||
        (genericRows.single['id'] ?? '').toString() != stableChildWordId) {
      failures.add('generic batch did not return the expected child row');
    }
    if (stableGraphSnapshot.context != 'readForGraphBatch') {
      failures.add('graph batch context was not readForGraphBatch');
    }
    if (mismatchGraphSnapshot.context != 'readForGraphBatch') {
      failures.add('graph batch fallback context was not readForGraphBatch');
    }
    if (genericSnapshot.context != 'getWordsByIds') {
      failures.add('generic batch context was not getWordsByIds');
    }
    if (stableGraphSnapshot.context == genericSnapshot.context) {
      failures.add('graph batch and generic batch contexts were not separated');
    }
    if (stableGraphSnapshot.requestedPolicy !=
        ReadSourcePolicy.normalizedWithFallback) {
      failures.add('graph batch policy was not promoted to normalizedWithFallback');
    }
    if (mismatchGraphSnapshot.requestedPolicy !=
        ReadSourcePolicy.normalizedWithFallback) {
      failures.add(
        'graph batch fallback policy was not promoted to normalizedWithFallback',
      );
    }
    if (stableGraphSnapshot.finalResultSource !=
        FinalReadResultSource.normalized) {
      failures.add('graph batch normalized case did not stay on normalized');
    }
    if (mismatchGraphSnapshot.finalResultSource !=
        FinalReadResultSource.legacyFallback) {
      failures.add('graph batch mismatch case did not fall back to legacy');
    }
    if (mismatchGraphSnapshot.fallbackObservation?.reason !=
        ReadFallbackReason.userVisibleDisplayMismatch) {
      failures.add('graph batch mismatch reason was not userVisibleDisplayMismatch');
    }
    if (genericSnapshot.requestedPolicy != ReadSourcePolicy.legacy) {
      failures.add('generic batch policy changed from legacy');
    }
    if (genericSnapshot.finalResultSource != FinalReadResultSource.legacy) {
      failures.add('generic batch final source changed from legacy');
    }
    if (stableSummary == null) {
      failures.add('collector summary for stable child was not recorded');
    } else {
      final summaryContexts = stableSummary.contexts.toSet();
      if (!summaryContexts.contains('readForGraphBatch')) {
        failures.add('collector summary did not keep readForGraphBatch context');
      }
      if (!summaryContexts.contains('getWordsByIds')) {
        failures.add('collector summary did not keep generic batch context');
      }
      if (summaryContexts.length != 2) {
        failures.add('collector summary did not keep graph/generic contexts separable');
      }
    }

    if (failures.isNotEmpty) {
      for (final failure in failures) {
        stderr.writeln('[verify] failure: $failure');
      }
      return 1;
    }

    stdout.writeln(
      '[verify] success: graph batch policy and collector context separation are intact.',
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
  }
}

Future<void> _insertWord(
  dynamic db, {
  required String id,
  required String spelling,
  required String meaning,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '언어': '테스트',
    '표기1': spelling,
    '음역1': spelling,
    '발음1': spelling,
    '의미1': meaning,
  });
}

Future<Directory> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(p.join(repoRootPath, '.tmp_graph_batch_verify'));
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
