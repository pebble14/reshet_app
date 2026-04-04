import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/adapters/legacy_word_expression_read_adapter.dart';
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
      reason: 'read source policy 테스트용 기준 DB가 필요합니다.',
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

  group('WordRepository read source foundation', () {
    test('keeps the default policy as LEGACY', () async {
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
      expect(snapshot!.requestedPolicy, ReadSourcePolicy.legacy);
      expect(snapshot.resolvedSource, ResolvedReadSource.legacy);
      expect(snapshot.finalResultSource, FinalReadResultSource.legacy);
      expect(snapshot.didFallback, isFalse);
      expect(snapshot.legacyResultAvailable, isTrue);
      expect(snapshot.normalizedResultAvailable, isFalse);
      expect(snapshot.readResult.sets, hasLength(2));
    });

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

    test('records empty-result fallback observation in model form', () async {
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
      expect(snapshot!.resolvedSource, ResolvedReadSource.legacy);
      expect(snapshot.finalResultSource, FinalReadResultSource.legacyFallback);
      expect(snapshot.didFallback, isTrue);
      expect(
        snapshot.fallbackObservation!.reason,
        ReadFallbackReason.emptyResult,
      );
      expect(snapshot.fallbackObservation!.wordId, 'T9000_RS_EMPTY');
      expect(
        snapshot.fallbackObservation!.policy,
        ReadSourcePolicy.normalizedWithFallback,
      );
      expect(snapshot.fallbackObservation!.context, 'getWordMapById');
    });

    test(
      'records query-failed fallback observation when normalized table is unavailable',
      () async {
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
            pronunciation TEXT
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
      'keeps normalized-only failures visible without falling back to legacy',
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
        expect(
          snapshot.finalResultSource,
          FinalReadResultSource.normalizedFailure,
        );
        expect(snapshot.didFallback, isTrue);
        expect(
          snapshot.fallbackObservation!.reason,
          ReadFallbackReason.emptyResult,
        );
        expect(snapshot.readResult.sets, isEmpty);
      },
    );
  });

  group('WordRepository detail-only phase2 path', () {
    test(
      'keeps the global default as LEGACY while the detail-only API uses NORMALIZED_WITH_FALLBACK',
      () async {
        final repository = WordRepository();

        final legacyRow = await repository.getWordMapById('E0000_0010');
        final legacySnapshot = WordRepository.debugReadSourceCollector
            .debugLastSnapshotForWord('E0000_0010');
        final detailRow = await repository
            .getWordDetailMapByIdForReadSourcePhase2Only('E0000_0010');
        final detailSnapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (snapshot) =>
                  snapshot.wordId == 'E0000_0010' &&
                  snapshot.context ==
                      'getWordDetailMapByIdForReadSourcePhase2Only',
            );

        expect(legacyRow, isNotNull);
        expect(detailRow, isNotNull);
        expect(legacySnapshot, isNotNull);
        expect(legacySnapshot!.requestedPolicy, ReadSourcePolicy.legacy);
        expect(
          detailSnapshot.requestedPolicy,
          ReadSourcePolicy.normalizedWithFallback,
        );
        expect(
          detailSnapshot.finalResultSource,
          FinalReadResultSource.normalized,
        );
        expect(detailSnapshot.didFallback, isFalse);
        expect(detailSnapshot.legacyResultAvailable, isTrue);
        expect(detailSnapshot.normalizedResultAvailable, isTrue);
        _expectSameDetailDisplay(legacyRow!, detailRow!);
      },
    );

    test(
      'falls back to legacy when detail-only API sees empty normalized rows',
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
            .getWordDetailMapByIdForReadSourcePhase2Only(
              'T9000_RS_DETAIL_EMPTY',
            );
        final snapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (entry) =>
                  entry.wordId == 'T9000_RS_DETAIL_EMPTY' &&
                  entry.context ==
                      'getWordDetailMapByIdForReadSourcePhase2Only',
            );

        expect(detailRow, isNotNull);
        expect(
          snapshot.requestedPolicy,
          ReadSourcePolicy.normalizedWithFallback,
        );
        expect(
          snapshot.finalResultSource,
          FinalReadResultSource.legacyFallback,
        );
        expect(snapshot.didFallback, isTrue);
        expect(snapshot.legacyResultAvailable, isTrue);
        expect(snapshot.normalizedResultAvailable, isFalse);
        expect(snapshot.fallbackObservation, isNotNull);
        expect(
          snapshot.fallbackObservation!.reason,
          ReadFallbackReason.emptyResult,
        );
        _expectSameDetailDisplay(legacyWordRow, detailRow!);
      },
    );

    test(
      'falls back to legacy when normalized success would change the user-visible detail display',
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
            .getWordDetailMapByIdForReadSourcePhase2Only(
              'T9000_RS_DETAIL_MISMATCH',
            );
        final snapshot = WordRepository.debugReadSourceCollector
            .debugRecentSnapshots()
            .lastWhere(
              (entry) =>
                  entry.wordId == 'T9000_RS_DETAIL_MISMATCH' &&
                  entry.context ==
                      'getWordDetailMapByIdForReadSourcePhase2Only',
            );

        expect(detailRow, isNotNull);
        expect(
          snapshot.requestedPolicy,
          ReadSourcePolicy.normalizedWithFallback,
        );
        expect(
          snapshot.finalResultSource,
          FinalReadResultSource.legacyFallback,
        );
        expect(snapshot.didFallback, isTrue);
        expect(snapshot.legacyResultAvailable, isTrue);
        expect(snapshot.normalizedResultAvailable, isTrue);
        expect(
          snapshot.fallbackObservation!.reason,
          ReadFallbackReason.userVisibleDisplayMismatch,
        );
        expect(
          snapshot.fallbackObservation!.detail,
          contains('representative_spelling'),
        );
        _expectSameDetailDisplay(legacyWordRow, detailRow!);
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

        await repository.getWordDetailMapByIdForReadSourcePhase2Only(
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
        expect(wordSummary!.fallbackEvents, 1);
        expect(wordSummary.reasonCounts[ReadFallbackReason.emptyResult], 1);
        expect(reasonSummaries, isNotEmpty);
        expect(
          reasonSummaries.any(
            (summary) => summary.reason == ReadFallbackReason.emptyResult,
          ),
          isTrue,
        );
        expect(recentEvents, isNotEmpty);
        expect(recentEvents.first.wordId, 'T9000_RS_SUMMARY');
        expect(wordSummaryLines.single, contains('[read-summary:word]'));
        expect(wordSummaryLines.single, contains('wordId=T9000_RS_SUMMARY'));
        expect(reasonSummaryLines.join('\n'), contains('reason=empty_result'));
        expect(recentEventLines.first, contains('[read-event]'));
        expect(recentEventLines.first, contains('reason=empty_result'));
      },
    );
  });
}

Future<Directory> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(
    p.join(repoRootPath, '.tmp_read_source_policy_tests'),
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

void _expectSameDetailDisplay(
  Map<String, dynamic> expectedWordRow,
  Map<String, dynamic> actualWordRow,
) {
  final expected = _buildDetailDisplaySummary(expectedWordRow);
  final actual = _buildDetailDisplaySummary(actualWordRow);

  expect(actual.representativeSpelling, expected.representativeSpelling);
  expect(actual.spellings, equals(expected.spellings));
  expect(actual.transliterations, equals(expected.transliterations));
  expect(actual.pronunciations, equals(expected.pronunciations));
  expect(actual.meanings, equals(expected.meanings));
}

({
  String representativeSpelling,
  List<String> spellings,
  List<String> transliterations,
  List<String> pronunciations,
  List<String> meanings,
})
_buildDetailDisplaySummary(Map<String, dynamic> wordRow) {
  final readResult = readLegacyWordExpressionRow(wordRow);
  final representativeSpelling = readResult.sets.isEmpty
      ? ''
      : readResult.sets
            .firstWhere(
              (set) => set.isRepresentative,
              orElse: () => readResult.sets.first,
            )
            .spelling;

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
