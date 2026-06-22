import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/word/word_detail_like_display_item.dart';
import 'package:reshet_app/ui/mobile_word_search_screen.dart';
import 'package:reshet_app/ui/word_detail_screen.dart';
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

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await _deleteIsolatedWorkspace(isolatedRoot!);
    }
  });

  group('Phase 27-B mobile global search access', () {
    test('Home과 Mobile route가 동일한 query seam을 사용한다', () {
      final homeSource = File(
        p.join(repoRootPath, 'lib', 'ui', 'home_screen.dart'),
      ).readAsStringSync();
      final mobileSearchSource = File(
        p.join(repoRootPath, 'lib', 'ui', 'mobile_word_search_screen.dart'),
      ).readAsStringSync();

      expect(homeSource, contains('runWordSearchQuery('));
      expect(mobileSearchSource, contains('runWordSearchQuery('));
    });

    testWidgets('mobile Graph는 search와 기존 command overflow를 제공한다', (
      tester,
    ) async {
      _setSurfaceSize(tester, const Size(800, 900));
      await tester.pumpWidget(
        MaterialApp(home: WordGraphScreen(centerWordId: _representativeWordId)),
      );
      await _waitForGraphBootstrap(tester);

      expect(find.byKey(_mobileSearchActionKey), findsOneWidget);
      expect(find.byKey(_mobileGraphOverflowKey), findsOneWidget);
      expect(find.byTooltip('전체보기'), findsNothing);

      await tester.tap(find.byKey(_mobileGraphOverflowKey));
      await tester.pumpAndSettle();

      const commandLabels = [
        '전체보기',
        '보기 초기화',
        '선택 노드 중앙 맞춤',
        '관계 추가',
        '선택 단어 삭제',
        '단어 추가',
      ];
      for (final label in commandLabels) {
        expect(find.text(label), findsOneWidget);
      }

      await tester.tap(find.text('보기 초기화'));
      await tester.pump();
      expect(find.byType(WordGraphScreen), findsOneWidget);

      await _disposeRuntimeApp(tester);
    });

    testWidgets('mobile Detail은 search를 제공하고 Desktop은 기존 구성을 유지한다', (
      tester,
    ) async {
      const detailItem = WordDetailLikeDisplayItem(
        representativeSpelling: 'Detail breakpoint test',
      );

      _setSurfaceSize(tester, const Size(800, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: WordDetailScreen(
            wordId: 'T27_DETAIL_BREAKPOINT',
            initialDisplayItem: detailItem,
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(_mobileSearchActionKey), findsOneWidget);

      await _disposeRuntimeApp(tester);

      _setSurfaceSize(tester, const Size(900, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: WordDetailScreen(
            wordId: 'T27_DETAIL_BREAKPOINT',
            initialDisplayItem: detailItem,
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(_mobileSearchActionKey), findsNothing);

      await _disposeRuntimeApp(tester);
    });

    testWidgets('Desktop Graph는 mobile search 없이 기존 direct command를 유지한다', (
      tester,
    ) async {
      _setSurfaceSize(tester, const Size(900, 900));
      await tester.pumpWidget(
        MaterialApp(home: WordGraphScreen(centerWordId: _representativeWordId)),
      );
      await _waitForGraphBootstrap(tester);

      expect(find.byKey(_mobileSearchActionKey), findsNothing);
      expect(find.byKey(_mobileGraphOverflowKey), findsNothing);
      expect(find.byTooltip('전체보기'), findsOneWidget);
      expect(find.byTooltip('보기 초기화'), findsOneWidget);
      expect(find.byTooltip('선택 노드 중앙 맞춤'), findsOneWidget);
      expect(find.byTooltip('관계 추가'), findsOneWidget);
      expect(find.byTooltip('선택 단어 삭제'), findsOneWidget);
      expect(find.byTooltip('단어 추가'), findsOneWidget);

      await _disposeRuntimeApp(tester);
    });

    testWidgets('Graph origin은 Search와 target을 제거한 뒤 camera와 selection을 보존한다', (
      tester,
    ) async {
      _setSurfaceSize(tester, const Size(800, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: WordGraphScreen(
            centerWordId: _representativeWordId,
            selectedWordId: _representativeWordId,
          ),
        ),
      );
      await _pumpUntil(
        tester,
        () =>
            find.byType(InteractiveViewer).evaluate().length == 1 &&
            find.byKey(_selectedPreviewKey).evaluate().length == 1,
        reason: 'Graph bootstrap과 초기 selection 표시가 완료되어야 한다.',
      );

      final originElement = tester.element(find.byType(WordGraphScreen));
      final interactiveViewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final transformController = interactiveViewer.transformationController!;
      final changedTransform = transformController.value.clone()
        ..setEntry(0, 0, 1.25)
        ..setEntry(1, 1, 1.25)
        ..setEntry(0, 3, 36)
        ..setEntry(1, 3, 24);
      transformController.value = changedTransform;
      await tester.pump();
      final expectedTransform = List<double>.from(
        transformController.value.storage,
      );

      await _openSearchAndSubmit(tester, 'H2');
      expect(
        tester
            .widget<TextField>(find.byKey(_mobileSearchFieldKey))
            .focusNode
            ?.hasFocus,
        isTrue,
      );
      await tester.tap(find.byType(ListTile).first);
      await _pumpUntil(
        tester,
        () =>
            find.byType(WordDetailScreen).evaluate().length == 1 &&
            find.byType(MobileWordSearchScreen).evaluate().isEmpty,
        reason: '검색 route를 제거한 뒤 Detail target을 push해야 한다.',
      );

      await tester.pageBack();
      await _pumpUntil(
        tester,
        () =>
            find.byType(WordGraphScreen).evaluate().length == 1 &&
            find.byType(MobileWordSearchScreen).evaluate().isEmpty,
        reason: 'target back 후 원래 Graph만 남아야 한다.',
      );

      expect(tester.element(find.byType(WordGraphScreen)), same(originElement));
      expect(find.byKey(_selectedPreviewKey), findsOneWidget);
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

    testWidgets('Detail origin은 Search와 Graph target을 제거한 뒤 scroll을 보존한다', (
      tester,
    ) async {
      _setSurfaceSize(tester, const Size(360, 640));
      final originDisplayItem = WordDetailLikeDisplayItem(
        representativeSpelling: '원래 상세 단어',
        displayStrongNumber: 'T27',
        meanings: List.generate(30, (index) => '원래 상세 의미 ${index + 1}'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WordDetailScreen(
            wordId: 'T27_DETAIL_ORIGIN',
            initialDisplayItem: originDisplayItem,
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
      await tester.tap(find.byTooltip('그래프').first);
      await _pumpUntil(
        tester,
        () =>
            find.byType(WordGraphScreen).evaluate().length == 1 &&
            find.byType(MobileWordSearchScreen).evaluate().isEmpty,
        reason: '검색 route를 제거한 뒤 Graph target을 push해야 한다.',
      );

      await tester.pageBack();
      await _pumpUntil(
        tester,
        () =>
            find.byType(WordDetailScreen).evaluate().length == 1 &&
            find.byType(MobileWordSearchScreen).evaluate().isEmpty,
        reason: 'target back 후 원래 Detail만 남아야 한다.',
      );

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

Future<void> _openSearchAndSubmit(WidgetTester tester, String query) async {
  await tester.tap(find.byKey(_mobileSearchActionKey));
  await tester.pumpAndSettle();
  expect(find.byType(MobileWordSearchScreen), findsOneWidget);

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

Future<void> _disposeRuntimeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump(const Duration(seconds: 11));
}

Future<Directory> _createIsolatedWorkspace(String sourceWorkDbPath) async {
  final isolatedRoot = await Directory.systemTemp.createTemp(
    'reshet_phase27b_runtime_',
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
