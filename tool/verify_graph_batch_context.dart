// Verification-only tool for Phase 4-D graph batch context separation.
//
// This script does not modify production behavior. It creates an isolated
// workspace database, runs one graph-owned batch read and one generic batch
// read, then prints the captured collector contexts so the result can be
// verified from the command line.

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

    const centerWordId = 'T9000_RS_GRAPH_A';
    const childWordId = 'T9000_RS_GRAPH_B';

    await _insertWord(
      db,
      id: centerWordId,
      spelling: 'graph-center',
      meaning: 'graph center',
    );
    await _insertWord(
      db,
      id: childWordId,
      spelling: 'graph-child',
      meaning: 'graph child',
    );
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
    final snapshots = WordRepository.debugReadSourceCollector
        .debugRecentSnapshots();

    final graphSnapshot = snapshots.lastWhere(
      (snapshot) =>
          snapshot.wordId == childWordId &&
          snapshot.context == 'readForGraphBatch',
    );
    final genericSnapshot = snapshots.lastWhere(
      (snapshot) =>
          snapshot.wordId == childWordId && snapshot.context == 'getWordsByIds',
    );

    stdout.writeln('[verify] isolated workspace: ${isolatedRoot.path}');
    stdout.writeln(
      '[verify] graph connectedWords=${graphData.connectedWords.length}',
    );
    stdout.writeln('[verify] generic rows=${genericRows.length}');
    stdout.writeln(
      '[verify] graph snapshot: '
      'wordId=${graphSnapshot.wordId} '
      'context=${graphSnapshot.context} '
      'policy=${graphSnapshot.requestedPolicy.name} '
      'final=${graphSnapshot.finalResultSource.name}',
    );
    stdout.writeln(
      '[verify] generic snapshot: '
      'wordId=${genericSnapshot.wordId} '
      'context=${genericSnapshot.context} '
      'policy=${genericSnapshot.requestedPolicy.name} '
      'final=${genericSnapshot.finalResultSource.name}',
    );

    final failures = <String>[];
    if (graphData.connectedWords.length != 1 ||
        graphData.connectedWords.single.id != childWordId) {
      failures.add('graph batch did not resolve the expected child word');
    }
    if (genericRows.length != 1 ||
        (genericRows.single['id'] ?? '').toString() != childWordId) {
      failures.add('generic batch did not return the expected child row');
    }
    if (graphSnapshot.context != 'readForGraphBatch') {
      failures.add('graph batch context was not readForGraphBatch');
    }
    if (genericSnapshot.context != 'getWordsByIds') {
      failures.add('generic batch context was not getWordsByIds');
    }
    if (graphSnapshot.context == genericSnapshot.context) {
      failures.add('graph batch and generic batch contexts were not separated');
    }
    if (graphSnapshot.requestedPolicy != ReadSourcePolicy.legacy) {
      failures.add('graph batch policy changed from legacy');
    }
    if (genericSnapshot.requestedPolicy != ReadSourcePolicy.legacy) {
      failures.add('generic batch policy changed from legacy');
    }

    if (failures.isNotEmpty) {
      for (final failure in failures) {
        stderr.writeln('[verify] failure: $failure');
      }
      return 1;
    }

    stdout.writeln(
      '[verify] success: graph batch and generic batch contexts are separated.',
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
