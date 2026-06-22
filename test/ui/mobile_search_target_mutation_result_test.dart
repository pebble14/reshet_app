import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/word/word_detail_like_display_item.dart';
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
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
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
      final createdWordId = await _createUnrelatedWordFromActiveGraph(
        tester,
        spelling: 'Phase29 local retarget',
      );

      expect(tester.element(find.byType(WordGraphScreen)), same(targetElement));
      expect(
        find.byType(WordGraphScreen, skipOffstage: false).evaluate().length,
        2,
      );
      expect(
        find.byKey(ValueKey<String>('graph-center-node:$createdWordId')),
        findsOneWidget,
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
