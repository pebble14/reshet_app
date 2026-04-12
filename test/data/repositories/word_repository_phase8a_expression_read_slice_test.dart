import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/expression/read_source_policy.dart';

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
      reason: 'Phase 8-A expression read slice test needs the seed work DB.',
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

  group('Phase 8-A raw single-word read first slice', () {
    test(
      'getWordMapById uses NORMALIZED_WITH_FALLBACK and preserves expression projection',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_P8A_SINGLE_WORD';
        final legacyWordRow = {
          'id': wordId,
          '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
          '\uD45C\uAE301': 'phase8a-alpha',
          '\uC74C\uC5ED1': 'alpha',
          '\uBC1C\uC74C1': 'alpha',
          '\uD45C\uAE302': 'phase8a-beta',
          '\uC74C\uC5ED2': 'beta',
          '\uBC1C\uC74C2': 'beta',
          '\uC758\uBBF81': 'phase8a single word stable',
        };

        await db.insert('WORD_TABLE', legacyWordRow);
        await db.insert('word_expression_set', {
          'word_id': wordId,
          'seq': 1,
          'is_representative': 1,
          'spelling': 'phase8a-alpha',
          'transliteration': 'alpha',
          'pronunciation': 'alpha',
        });
        await db.insert('word_expression_set', {
          'word_id': wordId,
          'seq': 2,
          'is_representative': 0,
          'spelling': 'phase8a-beta',
          'transliteration': 'beta',
          'pronunciation': 'beta',
        });

        final row = await repository.getWordMapById(wordId);
        final snapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (entry) =>
                  entry.wordId == wordId && entry.context == 'getWordMapById',
            );

        expect(row, isNotNull);
        expect(
          snapshot.requestedPolicy,
          ReadSourcePolicy.normalizedWithFallback,
        );
        expect(snapshot.finalResultSource, FinalReadResultSource.normalized);
        expect(snapshot.didFallback, isFalse);
        _expectSameExpressionProjection(legacyWordRow, row!);
      },
    );

    test(
      'getWordMapByIdForExplorerSingleWord falls back on visible mismatch and preserves legacy expression projection',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const wordId = 'T9000_P8A_EXPLORER_MISMATCH';
        final legacyWordRow = {
          'id': wordId,
          '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
          '\uD45C\uAE301': 'alpha',
          '\uC74C\uC5ED1': '\uC54C\uD30C',
          '\uBC1C\uC74C1': 'alpha',
          '\uD45C\uAE302': 'aleph',
          '\uC74C\uC5ED2': '\uC54C\uB808\uD504',
          '\uBC1C\uC74C2': 'aleph',
          '\uC758\uBBF81': 'phase8a explorer mismatch',
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

        final row = await repository.getWordMapByIdForExplorerSingleWord(
          wordId,
        );
        final snapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (entry) =>
                  entry.wordId == wordId &&
                  entry.context == 'readForExplorerSingleWord',
            );

        expect(row, isNotNull);
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
        _expectSameExpressionProjection(legacyWordRow, row!);
      },
    );

    test('getWordsByIds stays LEGACY in the Phase 8-A first slice', () async {
      final repository = WordRepository();
      final db = await DatabaseService.openDatabaseFile();
      const wordId = 'T9000_P8A_BATCH_LEGACY';

      await db.insert('WORD_TABLE', {
        'id': wordId,
        '\uC5B8\uC5B4': '\uD14C\uC2A4\uD2B8',
        '\uD45C\uAE301': 'batch-legacy',
        '\uC74C\uC5ED1': 'batch-legacy',
        '\uBC1C\uC74C1': 'batch-legacy',
        '\uC758\uBBF81': 'phase8a batch legacy',
      });
      await db.insert('word_expression_set', {
        'word_id': wordId,
        'seq': 1,
        'is_representative': 1,
        'spelling': 'batch-legacy',
        'transliteration': 'batch-legacy',
        'pronunciation': 'batch-legacy',
      });

      final rows = await repository.getWordsByIds([wordId]);
      final snapshot = WordRepository.debugReadSourceCollector
          .debugRecentSnapshots()
          .lastWhere(
            (entry) =>
                entry.wordId == wordId && entry.context == 'getWordsByIds',
          );

      expect(rows, hasLength(1));
      expect(snapshot.requestedPolicy, ReadSourcePolicy.legacy);
      expect(snapshot.finalResultSource, FinalReadResultSource.legacy);
      expect(snapshot.didFallback, isFalse);
    });
  });
}

Future<Directory> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(
    p.join(repoRootPath, '.tmp_phase8a_expression_read_slice_tests'),
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

void _expectSameExpressionProjection(
  Map<String, dynamic> expectedWordRow,
  Map<String, dynamic> actualWordRow,
) {
  for (var slot = 1; slot <= 6; slot++) {
    expect(
      _readTrimmedString(actualWordRow, '\uD45C\uAE30$slot'),
      _readTrimmedString(expectedWordRow, '\uD45C\uAE30$slot'),
      reason: 'spelling$slot should stay compatible',
    );
    expect(
      _readTrimmedString(actualWordRow, '\uC74C\uC5ED$slot'),
      _readTrimmedString(expectedWordRow, '\uC74C\uC5ED$slot'),
      reason: 'transliteration$slot should stay compatible',
    );
    expect(
      _readTrimmedString(actualWordRow, '\uBC1C\uC74C$slot'),
      _readTrimmedString(expectedWordRow, '\uBC1C\uC74C$slot'),
      reason: 'pronunciation$slot should stay compatible',
    );
  }
}

String _readTrimmedString(Map<String, dynamic> row, String key) {
  return (row[key] ?? '').toString().trim();
}
