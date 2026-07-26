import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/graph/graph_create_post_save_payload.dart';
import 'package:reshet_app/domain/graph/graph_center_word_display_item.dart';
import 'package:reshet_app/domain/graph/graph_visible_word.dart';
import 'package:reshet_app/domain/graph/graph_word_label_display_item.dart';
import 'package:reshet_app/domain/word/word_detail_like_display_item.dart';
import 'package:reshet_app/domain/word/word_edit_seed.dart';
import 'package:reshet_app/ui/mobile_word_search_screen.dart';
import 'package:reshet_app/ui/word_detail_route_result.dart';
import 'package:reshet_app/ui/word_detail_screen.dart';
import 'package:reshet_app/ui/word_edit_screen.dart';
import 'package:reshet_app/ui/word_graph_cache.dart';
import 'package:reshet_app/ui/word_graph_screen.dart';

const _representativeWordId = 'H0001_0000';
const _mobileSearchActionKey = Key('mobile-global-search-action');
const _mobileSearchFieldKey = Key('mobile-global-search-field');
const _mobileSearchSubmitKey = Key('mobile-global-search-submit');
const _mobileSearchResultListKey = Key('mobile-global-search-result-list');
const _mobileGraphOverflowKey = Key('mobile-graph-command-overflow');
const _selectedPreviewKey = Key('mobile-selected-node-preview');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String repoRootPath;
  late String sourceWorkDbPath;
  Directory? isolatedRoot;

  setUpAll(() async {
    repoRootPath = Directory.current.path;
    sourceWorkDbPath = p.join(repoRootPath, 'data', 'reshet_work.db');
    expect(File(sourceWorkDbPath).existsSync(), isTrue);
    await DatabaseService.closeDatabase();
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    WordGraphDataCache.clear();
    isolatedRoot = await _createIsolatedWorkspace(sourceWorkDbPath);
    Directory.current = isolatedRoot!.path;
    DatabaseService.setDataRootOverrideForTest(
      p.join(isolatedRoot!.path, 'data'),
    );
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    WordGraphDataCache.clear();
    Directory.current = repoRootPath;
    if (isolatedRoot case final root? when root.existsSync()) {
      await _deleteIsolatedWorkspace(root);
    }
  });

  group('route-local mutation impact', () {
    test('여러 mutation을 immutable aggregate snapshot으로 누적한다', () {
      final collector = WordMutationImpactCollector();

      collector.recordChangedWord(' A ');
      collector.recordDeletedWord('B', graphAffectedWordIds: ['C', ' ']);
      collector.recordGraphAffectedWords(['D', 'A']);

      final snapshot = collector.snapshot;
      expect(snapshot.changedWordIds, {'A'});
      expect(snapshot.deletedWordIds, {'B'});
      expect(snapshot.graphAffectedWordIds, {'A', 'B', 'C', 'D'});
      expect(() => snapshot.changedWordIds.add('E'), throwsUnsupportedError);
    });

    test('checkpoint는 같은 ID의 반복 mutation과 mutation 없는 back을 구분한다', () {
      final collector = WordMutationImpactCollector();
      collector.recordChangedWord('A');
      final checkpoint = collector.checkpoint;

      expect(collector.impactSince(checkpoint).isEmpty, isTrue);

      collector.recordChangedWord('A');
      expect(collector.impactSince(checkpoint).changedWordIds, {'A'});
    });

    test('삭제 result를 앞선 relation impact와 병합한다', () {
      final collector = WordMutationImpactCollector();
      final checkpoint = collector.checkpoint;
      collector.recordGraphAffectedWords(['A', 'B']);

      final impact = mutationImpactSince(
        collector: collector,
        checkpoint: checkpoint,
        routeResult: const WordDetailDeletedResult(wordId: 'CENTER'),
      );

      expect(impact.deletedWordIds, {'CENTER'});
      expect(impact.graphAffectedWordIds, {'A', 'B', 'CENTER'});
    });

    test('Graph active 범위와 겹치는 impact만 식별한다', () {
      final relatedImpact = WordMutationImpact(
        graphAffectedWordIds: ['VISIBLE'],
      );
      final unrelatedImpact = WordMutationImpact(
        graphAffectedWordIds: ['OUTSIDE'],
      );

      expect(relatedImpact.affectsGraphWordIds(['CENTER', 'VISIBLE']), isTrue);
      expect(
        unrelatedImpact.affectsGraphWordIds(['CENTER', 'VISIBLE']),
        isFalse,
      );
    });

    test('Detail origin은 자기 단어 edit와 delete만 구분해 처리한다', () {
      expect(
        resolveDetailMutationOriginAction(
          impact: WordMutationImpact(changedWordIds: ['ORIGIN']),
          originWordId: 'ORIGIN',
        ),
        DetailMutationOriginAction.refresh,
      );
      expect(
        resolveDetailMutationOriginAction(
          impact: WordMutationImpact(deletedWordIds: ['ORIGIN']),
          originWordId: 'ORIGIN',
        ),
        DetailMutationOriginAction.close,
      );
      expect(
        resolveDetailMutationOriginAction(
          impact: WordMutationImpact(changedWordIds: ['OTHER']),
          originWordId: 'ORIGIN',
        ),
        DetailMutationOriginAction.none,
      );
    });

    test('Graph origin은 peripheral 삭제와 center 삭제를 구분한다', () {
      final peripheralDecision = resolveGraphMutationOriginDecision(
        impact: WordMutationImpact(deletedWordIds: ['PERIPHERAL']),
        centerWordId: 'CENTER',
        selectedWordId: 'PERIPHERAL',
        activeWordIds: ['CENTER', 'PERIPHERAL'],
      );
      expect(peripheralDecision.shouldClose, isFalse);
      expect(peripheralDecision.shouldClearSelection, isTrue);
      expect(peripheralDecision.shouldRefresh, isTrue);

      final centerDecision = resolveGraphMutationOriginDecision(
        impact: WordMutationImpact(deletedWordIds: ['CENTER']),
        centerWordId: 'CENTER',
        selectedWordId: 'PERIPHERAL',
        activeWordIds: ['CENTER', 'PERIPHERAL'],
      );
      expect(centerDecision.shouldClose, isTrue);
      expect(centerDecision.shouldRefresh, isFalse);
    });
  });

  group('Mobile Search target mutation origin 반영', () {
    testWidgets('Graph-create editor 취소 뒤 discard guard 거부 시 후처리를 중단한다', (
      tester,
    ) async {
      _setSurfaceSize(tester, const Size(800, 900));
      final repository = _ControlledGraphCreateDiscardRepository(
        discardResult: false,
      );
      final requestedCenterWordIds = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: WordGraphScreen(
            centerWordId: _representativeWordId,
            repositoryForTesting: repository,
            onChangeCenterWordId: requestedCenterWordIds.add,
          ),
        ),
      );
      await _waitForGraphBootstrap(tester);
      final originElement = tester.element(find.byType(WordGraphScreen));

      await _openGraphCreateDialog(tester);
      await tester.enterText(
        find.widgetWithText(TextField, '표기'),
        'Phase graph create discard guard retained',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, '저장'));
      await _pumpUntil(
        tester,
        () => find.byType(WordEditScreen).evaluate().length == 1,
        reason: '정상 edit seed로 editor에 진입해야 한다.',
      );

      await tester.binding.handlePopRoute();
      await tester.pump();
      await _pumpUntil(
        tester,
        () =>
            repository.discardedWordId != null &&
            find.byType(WordEditScreen).evaluate().isEmpty,
        reason: 'editor route가 닫히고 graph-create discard guard를 확인해야 한다.',
      );

      expect(tester.takeException(), isNull);
      expect(tester.element(find.byType(WordGraphScreen)), same(originElement));
      expect(
        find.byKey(
          const ValueKey<String>('graph-center-node:$_representativeWordId'),
        ),
        findsOneWidget,
      );
      expect(requestedCenterWordIds, isEmpty);
      expect(repository.postSavePayloadReadCount, 0);
      await tester.runAsync(
        () => _expectCommittedGraphCreateWordRetained(
          repository.discardedWordId!,
        ),
      );

      await _disposeRuntimeApp(tester);
    });

    testWidgets('Graph-create strict failure cleanup 예외를 caller에서 차단한다', (
      tester,
    ) async {
      _setSurfaceSize(tester, const Size(800, 900));
      final repository = _ControlledGraphCreateDiscardRepository(
        throwOnDiscard: true,
        forceStrictSeedFailure: true,
      );
      final requestedCenterWordIds = <String>[];
      final logs = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          logs.add(message);
        }
      };
      addTearDown(() {
        debugPrint = previousDebugPrint;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: WordGraphScreen(
            centerWordId: _representativeWordId,
            repositoryForTesting: repository,
            onChangeCenterWordId: requestedCenterWordIds.add,
          ),
        ),
      );
      await _waitForGraphBootstrap(tester);
      final originElement = tester.element(find.byType(WordGraphScreen));
      final centerReadCountBeforeCreate = repository.centerReadCount;

      await _openGraphCreateDialog(tester);
      await tester.enterText(
        find.widgetWithText(TextField, '표기'),
        'Phase graph create cleanup exception retained',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, '저장'));
      await _pumpUntil(
        tester,
        () => find
            .text('편집 화면을 열지 못했습니다. 생성된 단어가 남아 있을 수 있습니다.')
            .evaluate()
            .isNotEmpty,
        reason: 'cleanup 예외 안내가 표시되어야 한다.',
      );

      expect(tester.takeException(), isNull);
      expect(repository.discardedWordId, isNotNull);
      expect(find.byType(WordEditScreen), findsNothing);
      expect(tester.element(find.byType(WordGraphScreen)), same(originElement));
      expect(
        find.byKey(
          const ValueKey<String>('graph-center-node:$_representativeWordId'),
        ),
        findsOneWidget,
      );
      expect(requestedCenterWordIds, isEmpty);
      expect(repository.postSavePayloadReadCount, 0);
      expect(repository.centerReadCount, centerReadCountBeforeCreate);
      expect(
        logs,
        contains(
          predicate<String>(
            (line) =>
                line.contains('[GraphCreateCleanup] discard failed:') &&
                line.contains('injected graph-create discard failure') &&
                line.contains('discardCreatedWordForGraphCreateFlow'),
          ),
        ),
      );
      await tester.runAsync(
        () => _expectCommittedGraphCreateWordRetained(
          repository.discardedWordId!,
        ),
      );
      debugPrint = previousDebugPrint;

      await _disposeRuntimeApp(tester);
    });

    testWidgets('Graph target local retarget이 route result owner를 보존한다', (
      tester,
    ) async {
      _setSurfaceSize(tester, const Size(800, 900));
      final collector = WordMutationImpactCollector();
      await tester.pumpWidget(
        MaterialApp(
          home: WordGraphScreen(
            centerWordId: _representativeWordId,
            mutationImpactCollector: collector,
          ),
        ),
      );
      await _waitForGraphBootstrap(tester);

      final originElement = tester.element(find.byType(WordGraphScreen));
      await _openSearchAndSubmit(tester, 'H2');
      await tester.tap(find.byTooltip('그래프').first);
      await _pumpUntil(
        tester,
        () =>
            find.byType(WordGraphScreen).evaluate().length == 1 &&
            find
                    .byType(WordGraphScreen, skipOffstage: false)
                    .evaluate()
                    .length ==
                2 &&
            find.byType(MobileWordSearchScreen).evaluate().isEmpty,
        reason: 'origin 위에 target Graph가 열려야 한다.',
      );
      await _waitForGraphBootstrap(tester);

      final targetElement = tester.element(find.byType(WordGraphScreen));
      await _zoomAndPanActiveGraphAwayFromCenter(tester);
      final transformController = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!;
      final scaleBeforeRetarget = transformController.value.getMaxScaleOnAxis();
      expect(scaleBeforeRetarget, greaterThan(1.0));
      expect(
        _widgetRect(
          tester,
          find.byType(InteractiveViewer),
        ).contains(_widgetRect(tester, _centerNodeFinder()).center),
        isFalse,
        reason: 'retarget 전 target Graph center가 viewport 밖에 있어야 한다.',
      );

      final createdWordId = await _createUnrelatedWordFromActiveGraph(
        tester,
        spelling: 'Phase29 local retarget',
      );
      await tester.pump();

      expect(tester.element(find.byType(WordGraphScreen)), same(targetElement));
      expect(
        find.byType(WordGraphScreen, skipOffstage: false).evaluate().length,
        2,
      );
      expect(
        find.byKey(ValueKey<String>('graph-center-node:$createdWordId')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<InteractiveViewer>(find.byType(InteractiveViewer))
            .transformationController!
            .value
            .getMaxScaleOnAxis(),
        closeTo(scaleBeforeRetarget, 0.0001),
      );
      expect(
        _widgetRect(tester, find.byType(InteractiveViewer)).contains(
          _widgetRect(
            tester,
            find.byKey(ValueKey<String>('graph-center-node:$createdWordId')),
          ).center,
        ),
        isTrue,
        reason: 'local retarget 후 새 center node가 Graph viewport 안에 보여야 한다.',
      );

      collector.recordGraphAffectedWords([_representativeWordId]);
      await tester.binding.handlePopRoute();
      await tester.pump();
      await _pumpUntil(
        tester,
        () =>
            find.byType(WordGraphScreen).evaluate().length == 1 &&
            find
                    .byType(WordGraphScreen, skipOffstage: false)
                    .evaluate()
                    .length ==
                1,
        reason: '한 번의 back으로 target route가 종료되고 origin Graph로 복귀해야 한다.',
      );
      await _pumpForAsyncWork(tester);

      expect(tester.element(find.byType(WordGraphScreen)), same(originElement));
      await _disposeRuntimeApp(tester);
    });

    testWidgets('collector 없는 standalone Graph는 pushReplacement를 유지한다', (
      tester,
    ) async {
      _setSurfaceSize(tester, const Size(800, 900));
      await tester.pumpWidget(
        MaterialApp(home: WordGraphScreen(centerWordId: _representativeWordId)),
      );
      await _waitForGraphBootstrap(tester);

      final initialElement = tester.element(find.byType(WordGraphScreen));
      final createdWordId = await _createUnrelatedWordFromActiveGraph(
        tester,
        spelling: 'Phase29 standalone replacement',
      );

      expect(
        tester.element(find.byType(WordGraphScreen)),
        isNot(same(initialElement)),
      );
      expect(
        find.byType(WordGraphScreen, skipOffstage: false).evaluate().length,
        1,
      );
      expect(
        find.byKey(ValueKey<String>('graph-center-node:$createdWordId')),
        findsOneWidget,
      );

      await _disposeRuntimeApp(tester);
    });

    testWidgets('Graph origin refresh가 camera, selection, 확장 node 위치를 보존한다', (
      tester,
    ) async {
      _setSurfaceSize(tester, const Size(800, 900));
      final collector = WordMutationImpactCollector();
      await tester.pumpWidget(
        MaterialApp(
          home: WordGraphScreen(
            centerWordId: _representativeWordId,
            mutationImpactCollector: collector,
          ),
        ),
      );
      await _waitForGraphBootstrap(tester);

      final originElement = tester.element(find.byType(WordGraphScreen));
      final peripheralNodes = _peripheralNodeFinder();
      expect(peripheralNodes, findsWidgets);
      final initialNodeCount = peripheralNodes.evaluate().length;
      final selectedNodeKey = tester.widget(peripheralNodes.first).key!;
      await tester.tap(peripheralNodes.first);
      await _pumpUntil(
        tester,
        () =>
            find.byKey(_selectedPreviewKey).evaluate().length == 1 &&
            _peripheralNodeFinder().evaluate().length > initialNodeCount,
        reason: 'depth-1 node selection과 확장 요청이 완료되어야 한다.',
      );

      final selectedNodeFinder = find.byKey(selectedNodeKey);
      final expectedNodeKeys = _peripheralNodeFinder()
          .evaluate()
          .map((element) => element.widget.key)
          .whereType<ValueKey<String>>()
          .map((key) => key.value)
          .toSet();

      final transformController = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!;
      final changedTransform = transformController.value.clone()
        ..setEntry(0, 0, 1.3)
        ..setEntry(1, 1, 1.3)
        ..setEntry(0, 3, 42)
        ..setEntry(1, 3, 31);
      transformController.value = changedTransform;
      await tester.pump();
      final expectedNodeCenter = tester.getCenter(selectedNodeFinder);
      final expectedTransform = List<double>.from(
        transformController.value.storage,
      );

      await _openSearchAndSubmit(tester, 'H2');
      await tester.tap(find.byType(ListTile).first);
      await _pumpUntil(
        tester,
        () => find.byType(WordDetailScreen).evaluate().length == 1,
        reason: '검색 target Detail이 열려야 한다.',
      );

      collector.recordGraphAffectedWords([_representativeWordId]);
      await tester.binding.handlePopRoute();
      await tester.pump();
      await _pumpUntil(
        tester,
        () =>
            find.byType(WordGraphScreen).evaluate().length == 1 &&
            find.byType(MobileWordSearchScreen).evaluate().isEmpty,
        reason: 'target back 후 origin Graph로 복귀해야 한다.',
      );
      await _pumpForAsyncWork(tester);

      expect(tester.element(find.byType(WordGraphScreen)), same(originElement));
      expect(find.byKey(_selectedPreviewKey), findsOneWidget);
      expect(
        _peripheralNodeFinder()
            .evaluate()
            .map((element) => element.widget.key)
            .whereType<ValueKey<String>>()
            .map((key) => key.value)
            .toSet(),
        expectedNodeKeys,
      );
      expect(
        tester.getCenter(find.byKey(selectedNodeKey)),
        within(distance: 0.1, from: expectedNodeCenter),
      );
      final restoredTransform = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!
          .value
          .storage;
      for (var index = 0; index < expectedTransform.length; index++) {
        expect(
          restoredTransform[index],
          closeTo(expectedTransform[index], 1e-9),
        );
      }

      await _disposeRuntimeApp(tester);
    });

    testWidgets('Detail origin refresh가 route와 scroll을 보존한다', (tester) async {
      _setSurfaceSize(tester, const Size(360, 640));
      final collector = WordMutationImpactCollector();
      final displayItem = WordDetailLikeDisplayItem(
        representativeSpelling: 'Phase28 원본 상세',
        meanings: List.generate(30, (index) => 'Phase28 원본 의미 ${index + 1}'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WordDetailScreen(
            wordId: 'PHASE28_DETAIL_ORIGIN',
            initialDisplayItem: displayItem,
            mutationImpactCollector: collector,
          ),
        ),
      );
      await tester.pump();

      final originElement = tester.element(find.byType(WordDetailScreen));
      final originScrollable = find.descendant(
        of: find.byType(WordDetailScreen),
        matching: find.byType(Scrollable),
      );
      await tester.drag(originScrollable.first, const Offset(0, -260));
      await tester.pump();
      final expectedScrollOffset = tester
          .state<ScrollableState>(originScrollable.first)
          .position
          .pixels;
      expect(expectedScrollOffset, greaterThan(0));

      await _openSearchAndSubmit(tester, 'H2');
      await tester.tap(find.byType(ListTile).first);
      await _pumpUntil(
        tester,
        () => find.byType(WordDetailScreen).evaluate().length == 2,
        reason: 'origin 위에 target Detail이 열려야 한다.',
      );
      collector.recordChangedWord('PHASE28_DETAIL_ORIGIN');
      await tester.binding.handlePopRoute();
      await tester.pump();
      await _pumpUntil(
        tester,
        () => find.byType(WordDetailScreen).evaluate().length == 1,
        reason: 'target back 후 origin Detail로 복귀해야 한다.',
      );
      await _pumpForAsyncWork(tester);

      expect(
        tester.element(find.byType(WordDetailScreen)),
        same(originElement),
      );
      final restoredScrollable = find.descendant(
        of: find.byType(WordDetailScreen),
        matching: find.byType(Scrollable),
      );
      expect(
        tester.state<ScrollableState>(restoredScrollable.first).position.pixels,
        closeTo(expectedScrollOffset, 0.1),
      );

      await _disposeRuntimeApp(tester);
    });
  });
}

Finder _peripheralNodeFinder() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('graph-peripheral-node:');
  });
}

Finder _centerNodeFinder() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('graph-center-node:');
  });
}

Future<void> _zoomAndPanActiveGraphAwayFromCenter(WidgetTester tester) async {
  await _pinchZoomActiveGraph(tester);
  await _panActiveGraphUntilCenterLeavesViewport(tester);
}

Future<void> _pinchZoomActiveGraph(WidgetTester tester) async {
  final viewport = _widgetRect(tester, find.byType(InteractiveViewer));
  final center = viewport.center;
  final first = await tester.createGesture(pointer: 1);
  final second = await tester.createGesture(pointer: 2);

  await first.down(center - const Offset(24, 0));
  await second.down(center + const Offset(24, 0));
  await tester.pump();
  await first.moveTo(center - const Offset(96, 0));
  await second.moveTo(center + const Offset(96, 0));
  await tester.pump();
  await first.up();
  await second.up();
  await tester.pump();
}

Future<void> _panActiveGraphUntilCenterLeavesViewport(
  WidgetTester tester,
) async {
  final graphFinder = find.byType(InteractiveViewer);
  for (var attempt = 0; attempt < 4; attempt++) {
    await tester.drag(graphFinder, const Offset(620, 520));
    await tester.pump();
    if (!_widgetRect(
      tester,
      graphFinder,
    ).contains(_widgetRect(tester, _centerNodeFinder()).center)) {
      return;
    }
  }

  expect(
    _widgetRect(
      tester,
      graphFinder,
    ).contains(_widgetRect(tester, _centerNodeFinder()).center),
    isFalse,
    reason: 'retarget 전 target Graph center가 viewport 밖으로 이동해야 한다.',
  );
}

Rect _widgetRect(WidgetTester tester, Finder finder) {
  return Rect.fromPoints(
    tester.getTopLeft(finder),
    tester.getBottomRight(finder),
  );
}

Future<String> _createUnrelatedWordFromActiveGraph(
  WidgetTester tester, {
  required String spelling,
}) async {
  await tester.tap(find.byKey(_mobileGraphOverflowKey));
  await tester.pumpAndSettle();
  await tester.tap(find.text('단어 추가'));
  await tester.pumpAndSettle();

  expect(find.text('신규 단어 생성'), findsOneWidget);
  await tester.enterText(find.widgetWithText(TextField, '표기'), spelling);
  await tester.tap(find.widgetWithText(ElevatedButton, '저장'));
  await _pumpUntil(
    tester,
    () => find.byType(WordEditScreen).evaluate().length == 1,
    reason: '생성된 단어의 편집 화면이 열려야 한다.',
  );

  final editSaveButton = find.descendant(
    of: find.byType(WordEditScreen),
    matching: find.widgetWithText(ElevatedButton, '저장'),
  );
  await tester.scrollUntilVisible(
    editSaveButton,
    300,
    scrollable: find
        .descendant(
          of: find.byType(WordEditScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.tap(editSaveButton);
  await _pumpUntil(
    tester,
    () =>
        find.byType(WordEditScreen).evaluate().isEmpty &&
        _centerNodeFinder().evaluate().length == 1 &&
        find.byType(CircularProgressIndicator).evaluate().isEmpty,
    reason: '새 단어를 center로 하는 Graph 전환이 완료되어야 한다.',
  );

  final centerKey = tester.widget(_centerNodeFinder()).key! as ValueKey<String>;
  return centerKey.value.substring('graph-center-node:'.length);
}

Future<void> _openGraphCreateDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(_mobileGraphOverflowKey));
  await tester.pumpAndSettle();
  await tester.tap(find.text('단어 추가'));
  await tester.pumpAndSettle();
  expect(find.text('신규 단어 생성'), findsOneWidget);
}

Future<void> _expectCommittedGraphCreateWordRetained(String wordId) async {
  final db = await DatabaseService.openDatabaseFile();
  final wordRows = await db.query(
    'WORD_TABLE',
    columns: ['id'],
    where: 'id = ?',
    whereArgs: [wordId],
  );
  final expressionRows = await db.query(
    'word_expression_set',
    columns: ['id'],
    where: 'word_id = ?',
    whereArgs: [wordId],
  );
  final activeCreateHistoryRows = await db.query(
    'CHANGE_HISTORY',
    columns: ['id'],
    where:
        'entity_type = ? AND entity_id = ? AND action_type = ? '
        'AND undone_at IS NULL',
    whereArgs: ['word', wordId, 'create'],
  );
  final relationRows = await db.query(
    'WORD_RELATION',
    columns: ['id'],
    where: 'word_id_1 = ? OR word_id_2 = ?',
    whereArgs: [wordId, wordId],
  );

  expect(wordRows, hasLength(1));
  expect(expressionRows, hasLength(1));
  expect(activeCreateHistoryRows, hasLength(1));
  expect(relationRows, isEmpty);
}

Future<void> _openSearchAndSubmit(WidgetTester tester, String query) async {
  await tester.tap(find.byKey(_mobileSearchActionKey));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(_mobileSearchFieldKey), query);
  await tester.tap(find.byKey(_mobileSearchSubmitKey));
  await _pumpUntil(
    tester,
    () => find.byKey(_mobileSearchResultListKey).evaluate().length == 1,
    reason: '검색 결과 목록이 표시되어야 한다.',
  );
}

void _setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _waitForGraphBootstrap(WidgetTester tester) {
  return _pumpUntil(
    tester,
    () =>
        find.byType(InteractiveViewer).evaluate().length == 1 &&
        find.byType(CircularProgressIndicator).evaluate().isEmpty,
    reason: 'Graph bootstrap이 완료되어야 한다.',
  );
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

Future<void> _pumpForAsyncWork(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 600)),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _disposeRuntimeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump(const Duration(seconds: 11));
}

Future<Directory> _createIsolatedWorkspace(String sourceWorkDbPath) async {
  final isolatedRoot = await Directory.systemTemp.createTemp(
    'reshet_phase28b_runtime_',
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

class _ControlledGraphCreateDiscardRepository extends WordRepository {
  final bool discardResult;
  final bool throwOnDiscard;
  final bool forceStrictSeedFailure;

  String? discardedWordId;
  int centerReadCount = 0;
  int postSavePayloadReadCount = 0;

  _ControlledGraphCreateDiscardRepository({
    this.discardResult = true,
    this.throwOnDiscard = false,
    this.forceStrictSeedFailure = false,
  });

  @override
  Future<Map<String, dynamic>?> getWordMapByIdForGraphCenterSingleWord(
    String id,
  ) async {
    centerReadCount++;
    return {
      'id': id,
      '\uC5B8\uC5B4': 'Graph create caller test',
      '\uD45C\uAE301': id,
    };
  }

  @override
  Future<GraphCenterWordDisplayItem?>
  getGraphCenterWordDisplayItemByIdForGraphCenterSingleWord(String id) async {
    return GraphCenterWordDisplayItem(
      wordId: id,
      language: 'Graph create caller test',
      displayStrongNumber: '',
      representativeSpelling: id,
      representativeTransliteration: '',
      representativePronunciation: '',
      primaryMeaning: '',
    );
  }

  @override
  Future<VisibleWordGraphData> getVisibleGraphDataForGraph(
    String centerWordId,
  ) async {
    return const (
      connectedWords: <GraphVisibleWord>[],
      wordLabels: <GraphWordLabelDisplayItem>[],
      relationEdges: <WordRelationEdgeInfo>[],
    );
  }

  @override
  Future<Set<String>>
  findWordIdsInDbWideLanguageSpellingTransliterationCollisionGroups(
    Iterable<String> wordIds,
  ) async {
    return const <String>{};
  }

  @override
  Future<WordEditSeed?> getWordEditSeedForGraphCreateEdit(String id) {
    if (forceStrictSeedFailure) {
      return Future<WordEditSeed?>.value();
    }
    return super.getWordEditSeedForGraphCreateEdit(id);
  }

  @override
  Future<bool> discardCreatedWordForGraphCreateFlow(String wordId) async {
    discardedWordId = wordId;
    if (throwOnDiscard) {
      throw StateError('injected graph-create discard failure');
    }
    return discardResult;
  }

  @override
  Future<GraphCreatePostSavePayload?> getGraphCreatePostSavePayloadAfterEdit(
    String id,
  ) {
    postSavePayloadReadCount++;
    return super.getGraphCreatePostSavePayloadAfterEdit(id);
  }
}
