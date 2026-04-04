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
      reason: 'read source policy 테스트용 기준 DB가 필요합니다.',
    );

    await DatabaseService.closeDatabase();
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    WordRepository.debugSetReadSourcePolicyOverride(null);
    isolatedRoot = await _createIsolatedWorkspace(
      repoRootPath,
      sourceWorkDbPath,
    );
    Directory.current = isolatedRoot!.path;
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    WordRepository.debugSetReadSourcePolicyOverride(null);
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
      final snapshot = repository.debugLastWordExpressionReadSnapshotFor(
        'E0000_0010',
      );

      expect(row, isNotNull);
      expect(snapshot, isNotNull);
      expect(snapshot!.requestedPolicy, ReadSourcePolicy.legacy);
      expect(snapshot.resolvedSource, ResolvedReadSource.legacy);
      expect(snapshot.didFallback, isFalse);
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
        final snapshot = repository.debugLastWordExpressionReadSnapshotFor(
          'E0000_0010',
        );

        expect(row, isNotNull);
        expect(row!['표기1'], 'Eva');
        expect(snapshot, isNotNull);
        expect(
          snapshot!.requestedPolicy,
          ReadSourcePolicy.normalizedWithFallback,
        );
        expect(snapshot.resolvedSource, ResolvedReadSource.normalized);
        expect(snapshot.didFallback, isFalse);
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
      final snapshot = repository.debugLastWordExpressionReadSnapshotFor(
        'T9000_RS_EMPTY',
      );

      expect(row, isNotNull);
      expect(snapshot, isNotNull);
      expect(snapshot!.resolvedSource, ResolvedReadSource.legacy);
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
        final snapshot = repository.debugLastWordExpressionReadSnapshotFor(
          'E0000_0001',
        );

        expect(row, isNotNull);
        expect(snapshot, isNotNull);
        expect(snapshot!.resolvedSource, ResolvedReadSource.legacy);
        expect(snapshot.didFallback, isTrue);
        expect(
          snapshot.fallbackObservation!.reason,
          ReadFallbackReason.queryFailed,
        );
        expect(snapshot.fallbackObservation!.detail, isNotEmpty);
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
        final snapshot = repository.debugLastWordExpressionReadSnapshotFor(
          'T9000_RS_STRICT',
        );

        expect(row, isNotNull);
        expect(snapshot, isNotNull);
        expect(snapshot!.resolvedSource, ResolvedReadSource.normalized);
        expect(snapshot.didFallback, isTrue);
        expect(
          snapshot.fallbackObservation!.reason,
          ReadFallbackReason.emptyResult,
        );
        expect(snapshot.readResult.sets, isEmpty);
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
