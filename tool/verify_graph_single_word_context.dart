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

    const stableWordId = 'T9000_RS_GRAPH_SINGLE_STABLE_VERIFY';
    const mismatchWordId = 'T9000_RS_GRAPH_SINGLE_MISMATCH_VERIFY';

    await _insertStableWord(
      db,
      id: stableWordId,
      spelling: 'graph-single-stable',
      meaning: 'graph single stable',
    );
    await _insertStableExpressionSet(
      db,
      wordId: stableWordId,
      spelling: 'graph-single-stable',
    );

    await _insertMismatchWord(
      db,
      id: mismatchWordId,
      primarySpelling: 'alpha',
      primaryTransliteration: 'alpha',
      secondarySpelling: 'aleph',
      secondaryTransliteration: 'aleph',
      meaning: 'graph single mismatch',
    );

    final stableRow = await repository.getWordMapByIdForGraphSingleWord(
      stableWordId,
    );
    final mismatchRow = await repository.getWordMapByIdForGraphSingleWord(
      mismatchWordId,
    );
    final stableSnapshot = _findLastSnapshot(
      wordId: stableWordId,
      context: 'readForGraphSingleWord',
    );
    final mismatchSnapshot = _findLastSnapshot(
      wordId: mismatchWordId,
      context: 'readForGraphSingleWord',
    );
    final stableSummary = WordRepository.debugReadSourceCollector
        .summaryForWord(stableWordId);
    final mismatchSummary = WordRepository.debugReadSourceCollector
        .summaryForWord(mismatchWordId);

    stdout.writeln(
      '[verify:stable] row='
      'spelling1=${stableRow?['표기1'] ?? "-"} '
      'meaning1=${stableRow?['의미1'] ?? "-"}',
    );
    stdout.writeln(
      '[verify:stable] snapshot='
      'context=${stableSnapshot?.context ?? "-"} '
      'policy=${stableSnapshot?.requestedPolicy.name ?? "-"} '
      'final=${stableSnapshot?.finalResultSource.name ?? "-"}',
    );
    stdout.writeln(
      '[verify:stable] summary='
      '${stableSummary?.formatLine() ?? "-"}',
    );
    stdout.writeln(
      '[verify:mismatch] row='
      'spelling1=${mismatchRow?['표기1'] ?? "-"} '
      'meaning1=${mismatchRow?['의미1'] ?? "-"}',
    );
    stdout.writeln(
      '[verify:mismatch] snapshot='
      'context=${mismatchSnapshot?.context ?? "-"} '
      'policy=${mismatchSnapshot?.requestedPolicy.name ?? "-"} '
      'final=${mismatchSnapshot?.finalResultSource.name ?? "-"} '
      'reason=${mismatchSnapshot?.fallbackObservation?.reason.name ?? "-"}',
    );
    stdout.writeln(
      '[verify:mismatch] summary='
      '${mismatchSummary?.formatLine() ?? "-"}',
    );

    final failures = <String>[];

    if (stableRow == null) {
      failures.add('stable case did not return a row');
    }
    if (stableSnapshot == null ||
        stableSnapshot.context != 'readForGraphSingleWord') {
      failures.add('stable case did not keep readForGraphSingleWord context');
    } else {
      if (stableSnapshot.requestedPolicy !=
          ReadSourcePolicy.normalizedWithFallback) {
        failures.add('stable case did not use normalizedWithFallback policy');
      }
      if (stableSnapshot.finalResultSource !=
          FinalReadResultSource.normalized) {
        failures.add('stable case did not stay on normalized');
      }
    }
    if (stableSummary == null ||
        stableSummary.contexts.toSet().length != 1 ||
        !stableSummary.contexts.contains('readForGraphSingleWord')) {
      failures.add('stable summary contexts were not isolated');
    }

    if (mismatchRow == null) {
      failures.add('mismatch case did not return a row');
    }
    if (mismatchSnapshot == null ||
        mismatchSnapshot.context != 'readForGraphSingleWord') {
      failures.add('mismatch case did not keep readForGraphSingleWord context');
    } else {
      if (mismatchSnapshot.requestedPolicy !=
          ReadSourcePolicy.normalizedWithFallback) {
        failures.add('mismatch case did not use normalizedWithFallback policy');
      }
      if (mismatchSnapshot.finalResultSource !=
          FinalReadResultSource.legacyFallback) {
        failures.add('mismatch case did not fall back to legacy');
      }
      if (mismatchSnapshot.fallbackObservation?.reason !=
          ReadFallbackReason.userVisibleDisplayMismatch) {
        failures.add('mismatch case reason was not userVisibleDisplayMismatch');
      }
    }
    if ((mismatchRow?['표기1'] ?? '').toString() != 'alpha') {
      failures.add('mismatch case did not preserve the legacy display row');
    }
    if (mismatchSummary == null ||
        mismatchSummary.contexts.toSet().length != 1 ||
        !mismatchSummary.contexts.contains('readForGraphSingleWord')) {
      failures.add('mismatch summary contexts were not isolated');
    }

    if (failures.isNotEmpty) {
      for (final failure in failures) {
        stderr.writeln('[verify] failure: $failure');
      }
      return 1;
    }

    stdout.writeln(
      '[verify] success: graph single-word controlled zone is intact.',
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

Future<void> _insertStableWord(
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
    '언어': '테스트',
    '표기1': primarySpelling,
    '음역1': primaryTransliteration,
    '발음1': primarySpelling,
    '표기2': secondarySpelling,
    '음역2': secondaryTransliteration,
    '발음2': secondarySpelling,
    '의미1': meaning,
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

Future<Directory> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(p.join(repoRootPath, '.tmp_graph_single_verify'));
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
