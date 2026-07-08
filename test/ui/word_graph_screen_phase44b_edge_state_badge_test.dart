import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/domain/graph/graph_center_word_display_item.dart';
import 'package:reshet_app/domain/graph/graph_visible_word.dart';
import 'package:reshet_app/domain/graph/graph_word_label_display_item.dart';
import 'package:reshet_app/ui/word_graph_cache.dart';
import 'package:reshet_app/ui/word_graph_screen.dart';

const _centerWordId = 'T944B_CENTER';
const _outgoingWordId = 'T944B_OUTGOING';
const _incomingWordId = 'T944B_INCOMING';
const _undirectedWordId = 'T944B_UNDIRECTED';
const _unknownWordId = 'T944B_UNKNOWN';

const _outgoingRelationId = 944201;
const _incomingRelationId = 944202;
const _undirectedRelationId = 944203;
const _unknownRelationId = 944204;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(WordGraphDataCache.clear);
  tearDown(WordGraphDataCache.clear);

  group('Phase 44-B edge state badge', () {
    test('direction summary별 edge 상태 배지 label을 분리한다', () {
      expect(edgeStateBadgeLabelForTesting('outgoing'), isNull);
      expect(edgeStateBadgeLabelForTesting('incoming'), isNull);
      expect(edgeStateBadgeLabelForTesting('undirected'), '무향');
      expect(edgeStateBadgeLabelForTesting('unknown'), '미정');
      expect(edgeStateBadgeLabelForTesting('mixed'), '혼합');
    });

    testWidgets('방향 edge chip은 배지 없이 유지하고 비방향 edge만 상태 배지를 표시한다', (
      tester,
    ) async {
      final repository = _FakeWordRepository(_graphData());

      await _pumpGraph(tester, repository);
      await _setCameraScale(tester, 1.2);
      await _pumpUntil(
        tester,
        () =>
            [
              _outgoingRelationId,
              _incomingRelationId,
              _undirectedRelationId,
              _unknownRelationId,
            ].every(
              (relationId) =>
                  _edgeChipFinder(relationId.toString()).evaluate().length == 1,
            ),
        reason: 'visible zoom에서는 모든 focused fixture edge chip이 렌더링되어야 한다.',
      );

      expect(
        _edgeStateBadgeFinder(_outgoingRelationId.toString()),
        findsNothing,
      );
      expect(
        _edgeStateBadgeFinder(_incomingRelationId.toString()),
        findsNothing,
      );
      expect(
        _edgeChipTextFinder(_undirectedRelationId.toString(), '무향'),
        findsOneWidget,
      );
      expect(
        _edgeChipTextFinder(_unknownRelationId.toString(), '미정'),
        findsOneWidget,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '긴 relation label과 상태 배지가 함께 렌더링되어도 layout overflow가 없어야 한다.',
      );

      await tester.tap(_edgeChipFinder(_unknownRelationId.toString()));
      await _pumpUntil(
        tester,
        () => find.byType(AlertDialog).evaluate().length == 1,
        reason: 'edge chip tap은 기존 관계 상세 popup을 열어야 한다.',
      );

      expect(find.textContaining('관계:'), findsOneWidget);
      expect(find.text('Phase44B unknown detail'), findsOneWidget);

      await _disposeRuntimeApp(tester);
    });
  });
}

Finder _edgeChipFinder(String edgeId) {
  return find.byKey(ValueKey<String>('graph-edge-chip:$edgeId'));
}

Finder _edgeStateBadgeFinder(String edgeId) {
  return find.byKey(ValueKey<String>('graph-edge-chip-state-badge:$edgeId'));
}

Finder _edgeChipTextFinder(String edgeId, String text) {
  return find.descendant(
    of: _edgeChipFinder(edgeId),
    matching: find.text(text),
  );
}

Future<void> _pumpGraph(WidgetTester tester, WordRepository repository) async {
  _setSurfaceSize(tester, const Size(1200, 900));
  await tester.pumpWidget(
    MaterialApp(
      home: WordGraphScreen(
        centerWordId: _centerWordId,
        repositoryForTesting: repository,
      ),
    ),
  );

  await _pumpUntil(
    tester,
    () =>
        find.byType(CircularProgressIndicator).evaluate().isEmpty &&
        find
            .byKey(ValueKey<String>('graph-peripheral-node:$_unknownWordId'))
            .evaluate()
            .isNotEmpty,
    reason: 'controlled graph fixture must render the unknown target node.',
  );
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
    if (condition()) return;
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

VisibleWordGraphData _graphData() {
  final connectedWordIds = [
    _outgoingWordId,
    _incomingWordId,
    _undirectedWordId,
    _unknownWordId,
  ];
  return (
    connectedWords: connectedWordIds.map(_visibleWord).toList(growable: false),
    wordLabels: [
      _wordLabel(_centerWordId),
      ...connectedWordIds.map(_wordLabel),
    ],
    relationEdges: [
      _edgeInfo(
        relationId: _outgoingRelationId,
        wordId2: _outgoingWordId,
        directionCode: 'w1_to_w2',
        centerRelativeDirection: 'outgoing',
        relationType: 'compound',
        description: 'Phase44B outgoing detail',
      ),
      _edgeInfo(
        relationId: _incomingRelationId,
        wordId2: _incomingWordId,
        directionCode: 'w2_to_w1',
        centerRelativeDirection: 'incoming',
        relationType: 'compound',
        description: 'Phase44B incoming detail',
      ),
      _edgeInfo(
        relationId: _undirectedRelationId,
        wordId2: _undirectedWordId,
        directionCode: 'undirected',
        centerRelativeDirection: 'undirected',
        relationType: 'approx_transliteration',
        description: 'Phase44B undirected detail',
      ),
      _edgeInfo(
        relationId: _unknownRelationId,
        wordId2: _unknownWordId,
        directionCode: 'unknown',
        centerRelativeDirection: 'unknown',
        relationType: 'conventional_transliteration',
        description: 'Phase44B unknown detail',
      ),
    ],
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
    language: 'Phase44B Fake Language',
    primaryMeaning: '$wordId meaning',
  );
}

GraphCenterWordDisplayItem _centerDisplayItem(String wordId) {
  return GraphCenterWordDisplayItem(
    wordId: wordId,
    language: 'Phase44B Fake Language',
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
    '\uC5B8\uC5B4': 'Phase44B Fake Language',
    '\uC2A4\uD2B8\uB871\uB118\uBC84': '',
    '\uD45C\uAE301': wordId,
    '\uC74C\uC5ED1': '$wordId transliteration',
    '\uBC1C\uC74C1': '',
    '\uC758\uBBF81': '$wordId meaning',
  };
}

WordRelationEdgeInfo _edgeInfo({
  required int relationId,
  required String wordId2,
  required String directionCode,
  required String centerRelativeDirection,
  required String relationType,
  required String description,
}) {
  return WordRelationEdgeInfo(
    relationId: relationId,
    wordId1: _centerWordId,
    wordId2: wordId2,
    otherWordId: wordId2,
    directionCode: directionCode,
    centerRelativeDirection: centerRelativeDirection,
    categoryCode: 'translation',
    categoryLabel: '번역',
    relationType: relationType,
    relationTypeLabel: '번역',
    statusCode: 'asserted',
    description: description,
  );
}

class _FakeWordRepository extends WordRepository {
  final VisibleWordGraphData graphData;

  _FakeWordRepository(this.graphData);

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
    if (centerWordId != _centerWordId) {
      throw StateError('Unexpected graph center: $centerWordId');
    }
    return graphData;
  }

  @override
  Future<List<WordRelationEdgeInfo>> getRelationEdgesWithinWordIdsForGraph(
    Iterable<String> wordIds,
  ) async {
    return const <WordRelationEdgeInfo>[];
  }

  @override
  Future<Set<String>>
  findWordIdsInDbWideLanguageSpellingTransliterationCollisionGroups(
    Iterable<String> wordIds,
  ) async {
    return const <String>{};
  }
}
