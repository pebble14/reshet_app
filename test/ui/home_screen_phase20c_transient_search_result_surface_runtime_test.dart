import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/ui/home_screen.dart';
import 'package:reshet_app/ui/word_detail_screen.dart';
import 'package:reshet_app/ui/word_explorer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      reason: 'Phase 20-C runtime guardrail needs the current work DB.',
    );

    await DatabaseService.closeDatabase();
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    isolatedRoot = await _createIsolatedWorkspace(sourceWorkDbPath);
    Directory.current = isolatedRoot!.path;
    SharedPreferences.setMockInitialValues({
      'first_run_brand_intro_seen': true,
    });
  });

  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await DatabaseService.closeDatabase();
    Directory.current = repoRootPath;

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await _deleteIsolatedWorkspace(isolatedRoot!);
    }
  });

  group('Phase 20-C transient search result surface runtime guardrail', () {
    testWidgets(
      'large-screen submit, dismiss, Strong, clear, and candidate tap keep boundaries',
      (tester) async {
        _setSurfaceSize(tester, const Size(1440, 1000));
        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await _pumpUntil(
          tester,
          () => find.byType(WordExplorerScreen).evaluate().length == 1,
          reason: 'large-screen Explorer pane must mount after DB bootstrap.',
        );
        await _waitForExplorerBootstrap(tester);

        final explorerFinder = find.byType(WordExplorerScreen);
        final initialExplorerElement = tester.element(explorerFinder);
        final initialExplorer = tester.widget<WordExplorerScreen>(
          explorerFinder,
        );
        final searchField = find.widgetWithText(TextField, '검색 (표기/의미/스트롱 번호)');
        final strongField = find.widgetWithText(TextField, 'Strong/스트롱');

        expect(_strongRailListFinder(), findsOneWidget);
        expect(_defaultStrongListFinder(), findsNothing);
        expect(tester.getSize(_strongRailListFinder()).width, 160.0);
        expect(tester.getSize(strongField).width, 136.0);
        final initialStrongRailRect = tester.getRect(_strongRailListFinder());
        final initialExplorerRect = tester.getRect(explorerFinder);
        expect(
          tester
              .widget<TextField>(strongField)
              .decoration
              ?.floatingLabelBehavior,
          FloatingLabelBehavior.always,
        );

        await tester.enterText(strongField, 'H7225');
        await _pumpStrongJumpAnimation(tester);

        expect(tester.widget<TextField>(strongField).controller?.text, 'H7225');
        expect(tester.takeException(), isNull);
        expect(_strongRailListFinder(), findsOneWidget);
        expect(_defaultStrongListFinder(), findsNothing);

        await tester.enterText(searchField, 'H2');
        await tester.tap(find.byTooltip('검색'));
        await _pumpUntil(
          tester,
          () => _transientCandidateTiles().evaluate().isNotEmpty,
          reason: 'large-screen H2 submit must show transient candidates.',
        );

        expect(_transientSurfaceFinder(), findsOneWidget);
        expect(tester.element(explorerFinder), same(initialExplorerElement));
        expect(tester.getRect(_strongRailListFinder()), initialStrongRailRect);
        expect(tester.getRect(explorerFinder), initialExplorerRect);
        expect(
          tester.widget<WordExplorerScreen>(explorerFinder).initialWordId,
          initialExplorer.initialWordId,
        );
        expect(_strongRailListFinder(), findsOneWidget);
        expect(_leftSearchCandidateTiles(), findsNothing);

        await tester.tap(
          find.byKey(
            const Key('dismiss-large-screen-transient-search-result-surface'),
          ),
        );
        await tester.pump();

        expect(_transientSurfaceFinder(), findsNothing);
        expect(_strongRailListFinder(), findsOneWidget);
        expect(_leftSearchCandidateTiles(), findsNothing);
        expect(tester.getRect(_strongRailListFinder()), initialStrongRailRect);
        expect(tester.getRect(explorerFinder), initialExplorerRect);
        expect(tester.element(explorerFinder), same(initialExplorerElement));
        expect(
          tester.widget<WordExplorerScreen>(explorerFinder).initialWordId,
          initialExplorer.initialWordId,
        );

        await tester.enterText(strongField, 'G26');
        await _pumpStrongJumpAnimation(tester);

        expect(_transientSurfaceFinder(), findsNothing);
        expect(_strongRailListFinder(), findsOneWidget);
        expect(_leftSearchCandidateTiles(), findsNothing);
        expect(tester.getRect(_strongRailListFinder()), initialStrongRailRect);
        expect(tester.getRect(explorerFinder), initialExplorerRect);
        expect(tester.element(explorerFinder), same(initialExplorerElement));
        expect(
          tester.widget<WordExplorerScreen>(explorerFinder).initialWordId,
          initialExplorer.initialWordId,
        );

        await tester.tap(find.byTooltip('검색'));
        await _pumpUntil(
          tester,
          () => _transientCandidateTiles().evaluate().isNotEmpty,
          reason: 'repeated H2 submit must reopen transient candidates.',
        );

        await tester.enterText(strongField, 'H85');
        await _pumpStrongJumpAnimation(tester);

        expect(_transientSurfaceFinder(), findsOneWidget);
        expect(_strongRailListFinder(), findsOneWidget);
        expect(_leftSearchCandidateTiles(), findsNothing);
        expect(tester.getRect(_strongRailListFinder()), initialStrongRailRect);
        expect(tester.getRect(explorerFinder), initialExplorerRect);
        expect(tester.element(explorerFinder), same(initialExplorerElement));
        expect(
          tester.widget<WordExplorerScreen>(explorerFinder).initialWordId,
          initialExplorer.initialWordId,
        );

        await tester.tap(find.byTooltip('초기화'));
        await tester.pump();
        await _pumpUntil(
          tester,
          () => _strongRailListFinder().evaluate().length == 1,
          reason: 'clear must restore the Strong Rail.',
        );

        expect(_transientSurfaceFinder(), findsNothing);
        expect(_strongRailListFinder(), findsOneWidget);
        expect(_defaultStrongListFinder(), findsNothing);
        expect(tester.getRect(_strongRailListFinder()), initialStrongRailRect);
        expect(tester.getRect(explorerFinder), initialExplorerRect);
        expect(tester.element(explorerFinder), same(initialExplorerElement));
        expect(
          tester.widget<WordExplorerScreen>(explorerFinder).initialWordId,
          initialExplorer.initialWordId,
        );

        await tester.enterText(searchField, 'H2');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await _pumpUntil(
          tester,
          () => _transientCandidateTiles().evaluate().isNotEmpty,
          reason: 'H2 submit must show a selectable transient candidate.',
        );

        await tester.tap(_transientCandidateTiles().first);
        await _pumpUntil(
          tester,
          () =>
              find.byType(WordExplorerScreen).evaluate().length == 1 &&
              tester.widget<WordExplorerScreen>(explorerFinder).initialWordId !=
                  initialExplorer.initialWordId,
          reason:
              'explicit transient candidate tap must retarget the Explorer.',
        );

        expect(_transientSurfaceFinder(), findsNothing);
        expect(
          tester.element(explorerFinder),
          isNot(same(initialExplorerElement)),
        );

        await _disposeRuntimeApp(tester);
      },
    );

    testWidgets('large-screen no-result state is shown inside the panel', (
      tester,
    ) async {
      _setSurfaceSize(tester, const Size(1440, 1000));
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await _pumpUntil(
        tester,
        () => find.byType(WordExplorerScreen).evaluate().length == 1,
        reason: 'large-screen Explorer pane must mount after DB bootstrap.',
      );
      await _waitForExplorerBootstrap(tester);

      final explorerFinder = find.byType(WordExplorerScreen);
      final initialExplorer = tester.widget<WordExplorerScreen>(explorerFinder);
      final searchField = find.widgetWithText(TextField, '검색 (표기/의미/스트롱 번호)');

      await tester.enterText(searchField, 'PHASE20C_RESULT_NOT_FOUND_20260606');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _pumpUntil(
        tester,
        () =>
            find
                .byKey(const Key('large-screen-transient-search-result-empty'))
                .evaluate()
                .length ==
            1,
        reason: 'large-screen no-result state must render inside the panel.',
      );

      expect(_transientSurfaceFinder(), findsOneWidget);
      expect(
        tester.widget<WordExplorerScreen>(explorerFinder).initialWordId,
        initialExplorer.initialWordId,
      );

      await _disposeRuntimeApp(tester);
    });

    testWidgets('small-screen keeps search result detail route flow', (
      tester,
    ) async {
      _setSurfaceSize(tester, const Size(800, 900));
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await _pumpUntil(
        tester,
        () => _defaultStrongListFinder().evaluate().length == 1,
        reason: 'small-screen default Strong list must render after bootstrap.',
      );

      expect(_defaultStrongListFinder(), findsOneWidget);
      expect(_strongRailListFinder(), findsNothing);

      final searchField = find.widgetWithText(TextField, '검색 (표기/의미/스트롱 번호)');
      await tester.enterText(searchField, 'H2');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _pumpUntil(
        tester,
        () => find.byType(ListTile).evaluate().isNotEmpty,
        reason: 'small-screen search must render at least one candidate.',
      );

      expect(_transientSurfaceFinder(), findsNothing);
      expect(find.byType(WordExplorerScreen), findsNothing);

      await tester.tap(find.byType(ListTile).first);
      await _pumpUntil(
        tester,
        () => find.byType(WordDetailScreen).evaluate().length == 1,
        reason: 'small-screen search result tap must open the detail route.',
      );

      expect(_transientSurfaceFinder(), findsNothing);
      expect(find.byType(WordExplorerScreen), findsNothing);
      expect(find.byType(WordDetailScreen), findsOneWidget);

      await _disposeRuntimeApp(tester);
    });
  });
}

Finder _transientSurfaceFinder() {
  return find.byKey(const Key('large-screen-transient-search-result-surface'));
}

Finder _transientCandidateTiles() {
  return find.descendant(
    of: _transientSurfaceFinder(),
    matching: find.byType(ListTile),
  );
}

Finder _leftSearchCandidateTiles() {
  return find.descendant(
    of: find.byWidgetPredicate(
      (widget) =>
          widget is ListView &&
          widget.key !=
              const Key('large-screen-transient-search-result-list') &&
          widget.itemExtent == null,
      description: 'left search result ListView',
    ),
    matching: find.byType(ListTile),
  );
}

Finder _strongRailListFinder() {
  return find.byWidgetPredicate(
    (widget) => widget is ListView && widget.itemExtent == 46.0,
    description: 'Strong Rail ListView',
  );
}

Finder _defaultStrongListFinder() {
  return find.byWidgetPredicate(
    (widget) => widget is ListView && widget.itemExtent == 56.0,
    description: 'default Strong browse/discovery ListView',
  );
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

Future<void> _waitForExplorerBootstrap(WidgetTester tester) {
  return _pumpUntil(
    tester,
    () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
    reason: 'Explorer bootstrap reads must finish before boundary assertions.',
  );
}

Future<void> _pumpStrongJumpAnimation(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(const Duration(milliseconds: 250));
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
    'reshet_phase20c_runtime_',
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
