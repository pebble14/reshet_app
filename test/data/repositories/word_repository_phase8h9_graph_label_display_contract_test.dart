import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/graph/graph_visible_word.dart';
import 'package:reshet_app/domain/graph/graph_word_label_display_item.dart';

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
      reason:
          'Phase 8-H-9 graph label display contract test needs the seed work DB.',
    );

    await DatabaseService.closeDatabase();
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    isolatedRoot = await _createIsolatedWorkspace(
      repoRootPath,
      sourceWorkDbPath,
    );
    Directory.current = isolatedRoot!.path;
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    Directory.current = repoRootPath;

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await isolatedRoot!.delete(recursive: true);
    }
  });

  group('Phase 8-H-9 graph word label display contract first slice', () {
    test(
      'supplies representative graph label contract with graph visible words',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const centerWordId = 'T9000_H9_GRAPH_CENTER';
        const childWordId = 'T9000_H9_GRAPH_CHILD';

        await _insertWord(
          db,
          id: centerWordId,
          language: ' center language ',
          primaryMeaning: ' center meaning ',
          legacySpelling: 'legacy-center',
          legacyTransliteration: 'legacy-center-translit',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'representative-center',
              'transliteration': 'representative-center-translit',
            },
          ],
        );
        await _insertWord(
          db,
          id: childWordId,
          language: ' actual display language ',
          primaryMeaning: ' primary child meaning ',
          strongNumber: 'h00042',
          legacySpelling: 'legacy-child-title',
          legacyTransliteration: 'legacy-child-translit',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 0,
              'spelling': 'first-normalized-but-not-representative',
              'transliteration': 'first-normalized-translit',
            },
            {
              'seq': 2,
              'is_representative': 1,
              'spelling': 'representative-child-title',
              'transliteration': 'representative-child-translit',
            },
          ],
        );
        await _insertRelation(db, wordId1: centerWordId, wordId2: childWordId);

        final graphData = await repository.getVisibleGraphDataForGraph(
          centerWordId,
        );

        expect(graphData.connectedWords, hasLength(1));
        expect(graphData.connectedWords, isA<List<GraphVisibleWord>>());
        expect(graphData.connectedWords.single.wordId, childWordId);
        expect(
          graphData.connectedWords.single.fallbackSpelling,
          'legacy-child-title',
        );
        expect(graphData.wordLabels, isA<List<GraphWordLabelDisplayItem>>());

        final childLabel = graphData.wordLabels.singleWhere(
          (label) => label.wordId == childWordId,
        );
        expect(childLabel.representativeSpelling, 'representative-child-title');
        expect(
          childLabel.representativeTransliteration,
          'representative-child-translit',
        );
        expect(childLabel.displayStrongNumber, 'H42');
        expect(childLabel.language, 'actual display language');
        expect(childLabel.primaryMeaning, 'primary child meaning');
        expect(childLabel.graphBuilderLabel, 'representative-child-title');
        expect(childLabel.peripheralTitleLabel, 'representative-child-title');
        expect(childLabel.relationDisplayName, 'representative-child-title');
        expect(
          childLabel.secondaryLabel(showStrongNumber: false),
          'representative-child-translit',
        );
        expect(
          childLabel.secondaryLabel(showStrongNumber: true),
          'representative-child-translit · H42',
        );

        final centerLabel = graphData.wordLabels.singleWhere(
          (label) => label.wordId == centerWordId,
        );
        expect(centerLabel.representativeSpelling, 'representative-center');
        expect(centerLabel.language, 'center language');
        expect(centerLabel.primaryMeaning, 'center meaning');
      },
    );

    test(
      'falls back to the first normalized expression only when representative row is absent',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const centerWordId = 'T9000_H9_GRAPH_FALLBACK_CENTER';
        const childWordId = 'T9000_H9_GRAPH_FALLBACK_CHILD';

        await _insertWord(
          db,
          id: centerWordId,
          legacySpelling: 'fallback-center',
          legacyTransliteration: 'fallback-center-translit',
          expressionRows: const [
            {
              'seq': 1,
              'is_representative': 1,
              'spelling': 'fallback-center',
              'transliteration': 'fallback-center-translit',
            },
          ],
        );
        await _insertWord(
          db,
          id: childWordId,
          language: '   ',
          primaryMeaning: '   ',
          legacySpelling: 'legacy-fallback-child',
          legacyTransliteration: 'legacy-fallback-translit',
          expressionRows: const [
            {
              'seq': 2,
              'is_representative': 0,
              'spelling': 'second-normalized-title',
              'transliteration': 'second-normalized-translit',
            },
            {
              'seq': 1,
              'is_representative': 0,
              'spelling': 'first-normalized-title',
              'transliteration': 'first-normalized-translit',
            },
          ],
        );
        await _insertRelation(db, wordId1: centerWordId, wordId2: childWordId);

        final graphData = await repository.getVisibleGraphDataForGraph(
          centerWordId,
        );
        final childLabel = graphData.wordLabels.singleWhere(
          (label) => label.wordId == childWordId,
        );

        expect(childLabel.representativeSpelling, 'first-normalized-title');
        expect(
          childLabel.representativeTransliteration,
          'first-normalized-translit',
        );
        expect(childLabel.language, '');
        expect(childLabel.primaryMeaning, '');
      },
    );

    test(
      'keeps legacy expression fallback when normalized rows are absent',
      () async {
        final repository = WordRepository();
        final db = await DatabaseService.openDatabaseFile();
        const centerWordId = 'T9000_H9_GRAPH_LEGACY_CENTER';
        const childWordId = 'T9000_H9_GRAPH_LEGACY_CHILD';

        await _insertWord(
          db,
          id: centerWordId,
          legacySpelling: 'legacy-center',
          legacyTransliteration: 'legacy-center-translit',
          expressionRows: const [],
        );
        await _insertWord(
          db,
          id: childWordId,
          language: ' legacy language ',
          primaryMeaning: ' legacy meaning ',
          legacySpelling: 'legacy-child',
          legacyTransliteration: 'legacy-child-translit',
          expressionRows: const [],
        );
        await _insertRelation(db, wordId1: centerWordId, wordId2: childWordId);

        final graphData = await repository.getVisibleGraphDataForGraph(
          centerWordId,
        );
        final childLabel = graphData.wordLabels.singleWhere(
          (label) => label.wordId == childWordId,
        );

        expect(childLabel.representativeSpelling, 'legacy-child');
        expect(
          childLabel.representativeTransliteration,
          'legacy-child-translit',
        );
        expect(childLabel.language, 'legacy language');
        expect(childLabel.primaryMeaning, 'legacy meaning');
      },
    );

    test('includes language and primary meaning in equality and hashCode', () {
      const base = GraphWordLabelDisplayItem(
        wordId: 'word',
        representativeSpelling: 'spelling',
        representativeTransliteration: 'transliteration',
        displayStrongNumber: 'H1',
        language: 'language',
        primaryMeaning: 'meaning',
      );
      const same = GraphWordLabelDisplayItem(
        wordId: 'word',
        representativeSpelling: 'spelling',
        representativeTransliteration: 'transliteration',
        displayStrongNumber: 'H1',
        language: 'language',
        primaryMeaning: 'meaning',
      );
      const differentLanguage = GraphWordLabelDisplayItem(
        wordId: 'word',
        representativeSpelling: 'spelling',
        representativeTransliteration: 'transliteration',
        displayStrongNumber: 'H1',
        language: 'other language',
        primaryMeaning: 'meaning',
      );
      const differentMeaning = GraphWordLabelDisplayItem(
        wordId: 'word',
        representativeSpelling: 'spelling',
        representativeTransliteration: 'transliteration',
        displayStrongNumber: 'H1',
        language: 'language',
        primaryMeaning: 'other meaning',
      );

      expect(base, same);
      expect(base.hashCode, same.hashCode);
      expect(base, isNot(differentLanguage));
      expect(base, isNot(differentMeaning));
      expect({base, differentLanguage, differentMeaning}, hasLength(3));
    });
  });
}

Future<Directory> _createIsolatedWorkspace(
  String repoRootPath,
  String sourceWorkDbPath,
) async {
  final tmpRoot = Directory(
    p.join(repoRootPath, '.tmp_phase8h9_graph_label_contract_tests'),
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

Future<void> _insertWord(
  dynamic db, {
  required String id,
  String language = 'test',
  String? primaryMeaning,
  String? strongNumber,
  required String legacySpelling,
  required String legacyTransliteration,
  required List<Map<String, Object?>> expressionRows,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '\uC5B8\uC5B4': language,
    '\uC2A4\uD2B8\uB871\uB118\uBC84': strongNumber,
    '\uD45C\uAE301': legacySpelling,
    '\uC74C\uC5ED1': legacyTransliteration,
    '\uC758\uBBF81': primaryMeaning,
  });

  for (final row in expressionRows) {
    await db.insert('word_expression_set', {'word_id': id, ...row});
  }
  if (primaryMeaning != null) {
    await db.insert('word_meaning_set', {
      'word_id': id,
      'seq': 1,
      'meaning': primaryMeaning,
    });
  }
}

Future<void> _insertRelation(
  dynamic db, {
  required String wordId1,
  required String wordId2,
}) async {
  await db.insert('WORD_RELATION', {
    'word_id_1': wordId1,
    'word_id_2': wordId2,
    'direction_code': 'unknown',
    'updated_at': DateTime.now().toIso8601String(),
  });
}
