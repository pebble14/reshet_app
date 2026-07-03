import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/models/word.dart';
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/graph/graph_build_options.dart';
import 'package:reshet_app/domain/graph/graph_builder.dart';
import 'package:reshet_app/domain/graph/graph_center_word_display_item.dart';
import 'package:reshet_app/domain/graph/graph_visible_word.dart';
import 'package:reshet_app/domain/graph/graph_word_label_display_item.dart';
import 'package:reshet_app/ui/word_graph_cache.dart';
import 'package:reshet_app/ui/word_graph_screen.dart';

const _centerWordId = 'T938E_CENTER';
const _sourceAWordId = 'T938E_SOURCE_A';
const _sourceBWordId = 'T938E_SOURCE_B';
const _aOnlyWordId = 'T938E_A_ONLY';
const _bOnlyWordId = 'T938E_B_ONLY';
const _sharedWordId = 'T938E_SHARED';
const _sameLabelEnglishWordId = 'T938E_SAME_LABEL_EN';
const _sameLabelLatinWordId = 'T938E_SAME_LABEL_LT';
const _aExtraWordIds = [
  'T938E_A_EXTRA_1',
  'T938E_A_EXTRA_2',
  'T938E_A_EXTRA_3',
  'T938E_A_EXTRA_4',
  'T938E_A_EXTRA_5',
];
const _collapseLabel = '확장 접기';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String repoRootPath;
  late String sourceWorkDbPath;
  Directory? isolatedRoot;
  late int relationCenterAId;
  late int relationSourcePairId;
  late int relationAOnlyBOnlyId;
  late int relationBOnlySharedId;
  late int relationSameLabelId;

  setUpAll(() async {
    repoRootPath = Directory.current.path;
    sourceWorkDbPath = p.join(repoRootPath, 'data', 'reshet_work.db');

    expect(File(sourceWorkDbPath).existsSync(), isTrue);
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    WordGraphDataCache.clear();
    isolatedRoot = await _createIsolatedWorkspace(sourceWorkDbPath);
    Directory.current = isolatedRoot!.path;

    final db = await DatabaseService.openDatabaseFile();
    await _insertWord(db, id: _centerWordId, spelling: 'Phase38E Center');
    await _insertWord(db, id: _sourceAWordId, spelling: 'Phase38E Source A');
    await _insertWord(db, id: _sourceBWordId, spelling: 'Phase38E Source B');
    await _insertWord(db, id: _aOnlyWordId, spelling: 'Phase38E A Only');
    await _insertWord(db, id: _bOnlyWordId, spelling: 'Phase38E B Only');
    await _insertWord(db, id: _sharedWordId, spelling: 'Phase38E Shared');
    await _insertWord(
      db,
      id: _sameLabelEnglishWordId,
      language: '영어',
      spelling: '-fer',
    );
    await _insertWord(
      db,
      id: _sameLabelLatinWordId,
      language: '라틴어',
      spelling: '-fer',
    );
    for (final wordId in _aExtraWordIds) {
      await _insertWord(db, id: wordId, spelling: 'Phase38E $wordId');
    }

    relationCenterAId = await _insertRelation(
      db,
      wordId1: _centerWordId,
      wordId2: _sourceAWordId,
    );
    await _insertRelation(db, wordId1: _centerWordId, wordId2: _sourceBWordId);
    await _insertRelation(
      db,
      wordId1: _centerWordId,
      wordId2: _sameLabelEnglishWordId,
    );
    await _insertRelation(
      db,
      wordId1: _centerWordId,
      wordId2: _sameLabelLatinWordId,
    );
    relationSourcePairId = await _insertRelation(
      db,
      wordId1: _sourceAWordId,
      wordId2: _sourceBWordId,
      directionCode: 'w1_to_w2',
      description: 'Phase38E depth 1 internal relation',
    );
    await _insertRelation(db, wordId1: _sourceAWordId, wordId2: _aOnlyWordId);
    await _insertRelation(db, wordId1: _sourceAWordId, wordId2: _sharedWordId);
    for (final wordId in _aExtraWordIds) {
      await _insertRelation(db, wordId1: _sourceAWordId, wordId2: wordId);
    }
    await _insertRelation(db, wordId1: _sourceBWordId, wordId2: _bOnlyWordId);
    await _insertRelation(db, wordId1: _sourceBWordId, wordId2: _sharedWordId);
    relationAOnlyBOnlyId = await _insertRelation(
      db,
      wordId1: _aOnlyWordId,
      wordId2: _bOnlyWordId,
    );
    relationBOnlySharedId = await _insertRelation(
      db,
      wordId1: _bOnlyWordId,
      wordId2: _sharedWordId,
    );
    relationSameLabelId = await _insertRelation(
      db,
      wordId1: _sameLabelEnglishWordId,
      wordId2: _sameLabelLatinWordId,
      categoryCode: 'unspecified',
      relationType: 'related',
    );
    await DatabaseService.closeDatabase();
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    WordGraphDataCache.clear();
    Directory.current = repoRootPath;

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await _deleteIsolatedWorkspace(isolatedRoot!);
    }
  });

  group('Phase 38-E visible internal relation edges', () {
    test(
      'keeps canonical endpoint ids for same display label supplemental edge',
      () {
        final builder = GraphBuilder();
        final result = builder.buildMergedVisibleGraphData(
          options: GraphBuildOptions(
            centerWordId: _centerWordId,
            maxDepth: 2,
            maxNodes: 30,
          ),
          centerWord: Word(id: _centerWordId, spelling1: 'Phase38E Center'),
          baseWords: const [
            GraphVisibleWord(
              wordId: _sameLabelEnglishWordId,
              fallbackSpelling: '-fer',
              fallbackStrongNumber: '',
              fallbackTransliteration: '-퍼',
            ),
            GraphVisibleWord(
              wordId: _sameLabelLatinWordId,
              fallbackSpelling: '-fer',
              fallbackStrongNumber: '',
              fallbackTransliteration: '-페르',
            ),
          ],
          wordLabels: const [
            GraphWordLabelDisplayItem(
              wordId: _centerWordId,
              representativeSpelling: 'Phase38E Center',
              representativeTransliteration: '',
              displayStrongNumber: '',
              language: '중심',
              primaryMeaning: '',
            ),
            GraphWordLabelDisplayItem(
              wordId: _sameLabelEnglishWordId,
              representativeSpelling: '-fer',
              representativeTransliteration: '-퍼',
              displayStrongNumber: '',
              language: '영어',
              primaryMeaning: '나르는',
            ),
            GraphWordLabelDisplayItem(
              wordId: _sameLabelLatinWordId,
              representativeSpelling: '-fer',
              representativeTransliteration: '-페르',
              displayStrongNumber: '',
              language: '라틴어',
              primaryMeaning: '나르는',
            ),
          ],
          baseRelationEdges: [
            _edgeInfo(
              relationId: 938751,
              wordId1: _centerWordId,
              wordId2: _sameLabelEnglishWordId,
            ),
            _edgeInfo(
              relationId: 938752,
              wordId1: _centerWordId,
              wordId2: _sameLabelLatinWordId,
            ),
          ],
          supplementalRelationEdges: [
            _edgeInfo(
              relationId: 267,
              wordId1: _sameLabelEnglishWordId,
              wordId2: _sameLabelLatinWordId,
              relationType: 'related',
              categoryCode: 'unspecified',
            ),
          ],
        );

        final edge = result.viewData.edges.singleWhere(
          (edge) => edge.relationId == 267,
        );
        expect(edge.sourceId, _sameLabelEnglishWordId);
        expect(edge.targetId, _sameLabelLatinWordId);
        expect(edge.sourceId, isNot(edge.targetId));
        expect(edge.id, '267');
        expect(
          result.relationEdges.singleWhere((edge) => edge.relationId == 267),
          isA<WordRelationEdgeInfo>()
              .having(
                (edge) => edge.wordId1,
                'wordId1',
                _sameLabelEnglishWordId,
              )
              .having((edge) => edge.wordId2, 'wordId2', _sameLabelLatinWordId),
        );
      },
    );

    testWidgets(
      'adds depth 1 internal edge and keeps existing relation id dedupe/detail contract',
      (tester) async {
        await _pumpGraph(tester, selectedWordId: _sourceAWordId);
        await _setCameraScale(tester, 1.2);

        await _pumpUntil(
          tester,
          () => _edgeChipFinder(relationSourcePairId).evaluate().length == 1,
          reason:
              'source A and source B must receive their DB relation as a supplemental edge.',
        );
        expect(_edgeChipFinder(relationCenterAId), findsOneWidget);

        await tester.tap(
          _edgeChipFinder(relationSourcePairId),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Phase38E Source A'), findsWidgets);
        expect(find.textContaining('Phase38E Source B'), findsWidgets);
        expect(find.text('중심 -> 상대'), findsOneWidget);
        expect(find.text('Phase38E depth 1 internal relation'), findsOneWidget);

        await _disposeRuntimeApp(tester);
      },
    );

    testWidgets(
      'shows same display label supplemental edge without self-reference',
      (tester) async {
        await _pumpGraph(tester, selectedWordId: _sameLabelEnglishWordId);
        await _setCameraScale(tester, 1.2);

        await _pumpUntil(
          tester,
          () => _edgeChipFinder(relationSameLabelId).evaluate().length == 1,
          reason:
              'same display labels must not hide a real relation between different ids.',
        );

        await tester.tap(
          _edgeChipFinder(relationSameLabelId),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(find.text('(자기 참조)'), findsNothing);
        expect(find.text('관계: -fer ↔ -fer'), findsOneWidget);
        expect(find.textContaining('의미적으로 관련'), findsOneWidget);

        await _disposeRuntimeApp(tester);
      },
    );

    testWidgets('recomputes depth 2 internal edges after expansion and collapse', (
      tester,
    ) async {
      await _pumpGraph(tester);

      await _tapNode(tester, _sourceAWordId);
      await _pumpUntil(
        tester,
        () =>
            _nodeFinder(_aOnlyWordId).evaluate().isNotEmpty &&
            _nodeFinder(_sharedWordId).evaluate().isNotEmpty &&
            _collapseActionFinder().evaluate().length == 1,
        reason: 'source A expansion must expose A-only and shared nodes.',
      );
      await _tapNode(tester, _sourceBWordId);
      await _pumpUntil(
        tester,
        () => _nodeFinder(_bOnlyWordId).evaluate().isNotEmpty,
        reason: 'source B expansion must expose B-only node.',
      );
      await _tapNode(tester, _aOnlyWordId);
      await _setCameraScale(tester, 1.2);
      await _pumpUntil(
        tester,
        () => _edgeChipFinder(relationAOnlyBOnlyId).evaluate().length == 1,
        reason:
            'visible depth 2 nodes from different sources must receive a supplemental edge.',
      );
      await _tapNode(tester, _bOnlyWordId);
      await _pumpUntil(
        tester,
        () => _edgeChipFinder(relationBOnlySharedId).evaluate().length == 1,
        reason:
            'another visible depth 2 internal relation must remain reachable from its endpoint.',
      );

      await _tapNode(tester, _sourceAWordId);
      await _pumpUntil(
        tester,
        () => find.text(_collapseLabel).evaluate().length == 1,
        reason: 'source A collapse action must become available.',
      );
      await tester.tap(_collapseActionFinder());
      await _pumpUntil(
        tester,
        () =>
            _nodeFinder(_aOnlyWordId).evaluate().isEmpty &&
            _nodeFinder(_bOnlyWordId).evaluate().isNotEmpty &&
            _nodeFinder(_sharedWordId).evaluate().isNotEmpty,
        reason:
            'collapsing source A must remove A-only nodes and keep source B/shared nodes.',
      );

      await _tapNode(tester, _bOnlyWordId);
      await _setCameraScale(tester, 1.2);
      await _pumpUntil(
        tester,
        () => _edgeChipFinder(relationBOnlySharedId).evaluate().length == 1,
        reason: 'remaining visible internal relation must be recalculated.',
      );
      expect(_edgeChipFinder(relationAOnlyBOnlyId), findsNothing);

      await _disposeRuntimeApp(tester);
    });

    testWidgets(
      'ignores stale supplemental result after graph revision changes',
      (tester) async {
        const firstCenterId = 'T938E_FAKE_CENTER_1';
        const secondCenterId = 'T938E_FAKE_CENTER_2';
        const firstAId = 'T938E_FAKE_1_A';
        const firstBId = 'T938E_FAKE_1_B';
        const secondAId = 'T938E_FAKE_2_A';
        const secondBId = 'T938E_FAKE_2_B';
        const staleRelationId = 938500;
        final repository = _FakeWordRepository({
          firstCenterId: _fakeGraphData(
            centerWordId: firstCenterId,
            connectedWordIds: const [firstAId, firstBId],
          ),
          secondCenterId: _fakeGraphData(
            centerWordId: secondCenterId,
            connectedWordIds: const [secondAId, secondBId],
          ),
        });

        await _pumpFakeGraph(
          tester,
          centerWordId: firstCenterId,
          repository: repository,
        );
        await _pumpUntil(
          tester,
          () => repository.supplementalRequests.length == 1,
          reason: 'first graph must start supplemental relation lookup.',
        );

        await _pumpFakeGraph(
          tester,
          centerWordId: secondCenterId,
          repository: repository,
        );
        await _pumpUntil(
          tester,
          () =>
              _nodeFinder(secondAId).evaluate().isNotEmpty &&
              _nodeFinder(secondBId).evaluate().isNotEmpty &&
              repository.supplementalRequests.length == 2,
          reason: 'second graph must render before stale result completes.',
        );

        repository.supplementalRequests.first.complete([
          _edgeInfo(
            relationId: staleRelationId,
            wordId1: secondAId,
            wordId2: secondBId,
          ),
        ]);
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await _setCameraScale(tester, 1.2);
        await tester.pump(const Duration(milliseconds: 250));

        expect(_edgeChipFinder(staleRelationId), findsNothing);
        repository.supplementalRequests[1].complete(
          const <WordRelationEdgeInfo>[],
        );

        await _disposeRuntimeApp(tester);
      },
    );

    testWidgets('excludes +N more placeholder from supplemental lookup input', (
      tester,
    ) async {
      const fakeCenterId = 'T938E_FAKE_PLACEHOLDER_CENTER';
      const placeholderNodeId =
          '__graph_more__::center::T938E_FAKE_PLACEHOLDER_CENTER';
      final connectedWordIds = List<String>.generate(
        13,
        (index) => 'T938E_FAKE_VISIBLE_$index',
        growable: false,
      );
      final repository = _FakeWordRepository({
        fakeCenterId: _fakeGraphData(
          centerWordId: fakeCenterId,
          connectedWordIds: connectedWordIds,
        ),
      });

      await _pumpFakeGraph(
        tester,
        centerWordId: fakeCenterId,
        repository: repository,
      );
      await _pumpUntil(
        tester,
        () => repository.supplementalRequests.length == 1,
        reason:
            'graph with center +N more placeholder must still start lookup.',
      );

      expect(_sourcePlaceholderFinder('center::$fakeCenterId'), findsOneWidget);
      expect(
        repository.supplementalRequests.first.wordIds,
        isNot(contains(placeholderNodeId)),
      );
      expect(repository.supplementalRequests.first.wordIds.length, 13);
      repository.supplementalRequests.first.complete(
        const <WordRelationEdgeInfo>[],
      );

      await _disposeRuntimeApp(tester);
    });
  });
}

Finder _collapseActionFinder() {
  return find.byKey(const Key('selected-node-collapse-expansion'));
}

Finder _nodeFinder(String wordId) {
  return find.byKey(ValueKey<String>('graph-peripheral-node:$wordId'));
}

Finder _sourcePlaceholderFinder(String sourceWordId) {
  return find.byKey(
    ValueKey<String>('graph-node-visual-scale:__graph_more__::$sourceWordId'),
  );
}

Finder _edgeChipFinder(int relationId) {
  return find.byKey(ValueKey<String>('graph-edge-chip:$relationId'));
}

Future<void> _pumpGraph(WidgetTester tester, {String? selectedWordId}) async {
  _setSurfaceSize(tester, const Size(1200, 900));
  await tester.pumpWidget(
    MaterialApp(
      home: WordGraphScreen(
        centerWordId: _centerWordId,
        selectedWordId: selectedWordId,
      ),
    ),
  );

  await _pumpUntil(
    tester,
    () =>
        find.byType(CircularProgressIndicator).evaluate().isEmpty &&
        _nodeFinder(_sourceAWordId).evaluate().isNotEmpty &&
        _nodeFinder(_sourceBWordId).evaluate().isNotEmpty,
    reason: 'controlled graph fixture must render both depth 1 source nodes.',
  );
}

Future<void> _pumpFakeGraph(
  WidgetTester tester, {
  required String centerWordId,
  required _FakeWordRepository repository,
}) async {
  _setSurfaceSize(tester, const Size(1200, 900));
  await tester.pumpWidget(
    MaterialApp(
      home: WordGraphScreen(
        centerWordId: centerWordId,
        repositoryForTesting: repository,
      ),
    ),
  );

  await _pumpUntil(
    tester,
    () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
    reason: 'fake graph must finish base graph load.',
  );
}

Future<void> _tapNode(WidgetTester tester, String wordId) async {
  await tester.tap(_nodeFinder(wordId), warnIfMissed: false);
  await tester.pump();
}

Future<void> _setCameraScale(WidgetTester tester, double scale) async {
  final viewer = tester.widget<InteractiveViewer>(
    find.byType(InteractiveViewer),
  );
  final matrix = Matrix4.identity();
  matrix.scaleByDouble(scale, scale, scale, 1.0);
  viewer.transformationController!.value = matrix;
  viewer.onInteractionUpdate?.call(
    ScaleUpdateDetails(
      focalPoint: Offset.zero,
      localFocalPoint: Offset.zero,
      scale: scale,
    ),
  );
  await tester.pump(const Duration(milliseconds: 250));
}

void _setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String reason,
}) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) {
      return;
    }
  }

  expect(condition(), isTrue, reason: reason);
}

Future<void> _disposeRuntimeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

Future<Directory> _createIsolatedWorkspace(String sourceWorkDbPath) async {
  final isolatedRoot = await Directory.systemTemp.createTemp(
    'reshet_phase38e_visible_internal_edges_',
  );
  final isolatedDataDir = Directory(p.join(isolatedRoot.path, 'data'));
  await isolatedDataDir.create(recursive: true);
  await File(
    sourceWorkDbPath,
  ).copy(p.join(isolatedDataDir.path, 'reshet_seed.db'));
  await File(
    sourceWorkDbPath,
  ).copy(p.join(isolatedDataDir.path, 'reshet_work.db'));
  return isolatedRoot;
}

Future<void> _deleteIsolatedWorkspace(Directory isolatedRoot) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    try {
      await isolatedRoot.delete(recursive: true);
      return;
    } on FileSystemException {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  await isolatedRoot.delete(recursive: true);
}

Future<void> _insertWord(
  dynamic db, {
  required String id,
  String language = 'Phase38E Language',
  required String spelling,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '\uC5B8\uC5B4': language,
    '\uD45C\uAE301': spelling,
    '\uC74C\uC5ED1': '$spelling transliteration',
    '\uC758\uBBF81': '$spelling meaning',
  });
  await db.insert('word_expression_set', {
    'word_id': id,
    'seq': 1,
    'is_representative': 1,
    'spelling': spelling,
    'transliteration': '$spelling transliteration',
  });
}

Future<int> _insertRelation(
  dynamic db, {
  required String wordId1,
  required String wordId2,
  String directionCode = 'unknown',
  String categoryCode = 'translation',
  String relationType = 'translation',
  String description = '',
}) async {
  final orderedWordId1 = wordId1.compareTo(wordId2) <= 0 ? wordId1 : wordId2;
  final orderedWordId2 = wordId1.compareTo(wordId2) <= 0 ? wordId2 : wordId1;
  return await db.insert('WORD_RELATION', {
    'word_id_1': orderedWordId1,
    'word_id_2': orderedWordId2,
    'direction_code': directionCode,
    'relation_type': relationType,
    'category_code': categoryCode,
    'description': description,
    'updated_at': DateTime.now().toIso8601String(),
  });
}

class _FakeWordRepository extends WordRepository {
  final Map<String, _FakeGraphData> graphDataByCenterId;
  final List<_SupplementalRequest> supplementalRequests =
      <_SupplementalRequest>[];

  _FakeWordRepository(this.graphDataByCenterId);

  @override
  Future<Map<String, dynamic>?> getWordMapByIdForGraphCenterSingleWord(
    String id,
  ) async {
    return _wordRow(id);
  }

  @override
  Future<GraphCenterWordDisplayItem?>
  getGraphCenterWordDisplayItemByIdForGraphCenterSingleWord(String id) async {
    return _centerDisplayItem(id);
  }

  @override
  Future<VisibleWordGraphData> getVisibleGraphDataForGraph(
    String centerWordId,
  ) async {
    final graphData = graphDataByCenterId[centerWordId];
    if (graphData == null) {
      throw StateError('Missing fake graph data: $centerWordId');
    }
    return graphData.visibleGraphData;
  }

  @override
  Future<List<WordRelationEdgeInfo>> getRelationEdgesWithinWordIdsForGraph(
    Iterable<String> wordIds,
  ) {
    final request = _SupplementalRequest(wordIds.toList(growable: false));
    supplementalRequests.add(request);
    return request.future;
  }

  @override
  Future<Set<String>>
  findWordIdsInDbWideLanguageSpellingTransliterationCollisionGroups(
    Iterable<String> wordIds,
  ) async {
    return const <String>{};
  }
}

class _SupplementalRequest {
  final List<String> wordIds;
  final Completer<List<WordRelationEdgeInfo>> _completer =
      Completer<List<WordRelationEdgeInfo>>();

  _SupplementalRequest(this.wordIds);

  Future<List<WordRelationEdgeInfo>> get future => _completer.future;

  void complete(List<WordRelationEdgeInfo> relationEdges) {
    if (_completer.isCompleted) {
      return;
    }
    _completer.complete(relationEdges);
  }
}

class _FakeGraphData {
  final VisibleWordGraphData visibleGraphData;

  const _FakeGraphData({required this.visibleGraphData});
}

_FakeGraphData _fakeGraphData({
  required String centerWordId,
  required List<String> connectedWordIds,
}) {
  return _FakeGraphData(
    visibleGraphData: (
      connectedWords: connectedWordIds
          .map(_visibleWord)
          .toList(growable: false),
      wordLabels: [
        _wordLabel(centerWordId),
        ...connectedWordIds.map(_wordLabel),
      ],
      relationEdges: [
        for (var index = 0; index < connectedWordIds.length; index++)
          _edgeInfo(
            relationId: 938000 + index,
            wordId1: centerWordId,
            wordId2: connectedWordIds[index],
          ),
      ],
    ),
  );
}

GraphVisibleWord _visibleWord(String wordId) {
  return GraphVisibleWord(
    wordId: wordId,
    fallbackSpelling: wordId,
    fallbackStrongNumber: '',
    fallbackTransliteration: '$wordId transliteration',
  );
}

GraphWordLabelDisplayItem _wordLabel(String wordId) {
  return GraphWordLabelDisplayItem(
    wordId: wordId,
    representativeSpelling: wordId,
    representativeTransliteration: '$wordId transliteration',
    displayStrongNumber: '',
    language: 'Phase38E Fake Language',
    primaryMeaning: '$wordId meaning',
  );
}

GraphCenterWordDisplayItem _centerDisplayItem(String wordId) {
  return GraphCenterWordDisplayItem(
    wordId: wordId,
    language: 'Phase38E Fake Language',
    displayStrongNumber: '',
    representativeSpelling: wordId,
    representativeTransliteration: '$wordId transliteration',
    representativePronunciation: '',
    primaryMeaning: '$wordId meaning',
  );
}

Map<String, dynamic> _wordRow(String wordId) {
  return {
    'id': wordId,
    '\uC5B8\uC5B4': 'Phase38E Fake Language',
    '\uC2A4\uD2B8\uB871\uB118\uBC84': '',
    '\uD45C\uAE301': wordId,
    '\uC74C\uC5ED1': '$wordId transliteration',
    '\uBC1C\uC74C1': '',
    '\uC758\uBBF81': '$wordId meaning',
  };
}

WordRelationEdgeInfo _edgeInfo({
  required int relationId,
  required String wordId1,
  required String wordId2,
  String directionCode = 'unknown',
  String relationType = 'translation',
  String categoryCode = 'translation',
}) {
  return WordRelationEdgeInfo(
    relationId: relationId,
    wordId1: wordId1,
    wordId2: wordId2,
    otherWordId: wordId2,
    directionCode: directionCode,
    centerRelativeDirection: 'unknown',
    categoryCode: categoryCode,
    categoryLabel: '번역',
    relationType: relationType,
    relationTypeLabel: '번역',
    statusCode: 'asserted',
  );
}
