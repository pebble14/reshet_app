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
      reason: 'Phase 18-N runtime guardrail needs the current work DB.',
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

  group('Phase 18-N HomeScreen runtime guardrail', () {
    testWidgets(
      'large-screen search and Strong jump keep separate runtime roles',
      (tester) async {
        _setSurfaceSize(tester, const Size(1440, 900));
        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await _pumpUntil(
          tester,
          () => find.byType(WordExplorerScreen).evaluate().length == 1,
          reason: 'large-screen Explorer pane must mount after DB bootstrap.',
        );
        await _pumpUntil(
          tester,
          () => _strongRailListFinder().evaluate().length == 1,
          reason:
              'Strong Rail list must render from the existing default list.',
        );
        await _waitForExplorerBootstrap(tester);

        final explorerFinder = find.byType(WordExplorerScreen);
        final initialExplorerElement = tester.element(explorerFinder);
        final initialExplorer = tester.widget<WordExplorerScreen>(
          explorerFinder,
        );
        final initialRailOffset = _scrollOffset(
          tester,
          _strongRailListFinder(),
        );

        final searchField = find.widgetWithText(TextField, '검색 (표기·음역·의미·스트롱)');
        await tester.enterText(searchField, 'H1');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await _pumpUntil(
          tester,
          () => _visibleListTileTitles(
            tester,
          ).any((title) => title.contains('H1')),
          reason: 'general search submit must render H1 search candidates.',
        );

        final searchTitlesBeforeStrongJump = _visibleListTileTitles(tester);
        expect(searchTitlesBeforeStrongJump, isNotEmpty);

        final strongField = find.widgetWithText(TextField, 'Strong/스트롱');
        await tester.enterText(strongField, 'G26');
        await _pumpStrongJumpAnimation(tester);

        expect(
          _scrollOffset(tester, _strongRailListFinder()),
          greaterThan(initialRailOffset),
          reason: 'G26 input must move only the Strong Rail scroll position.',
        );
        expect(_visibleListTileTitles(tester), searchTitlesBeforeStrongJump);
        expect(tester.element(explorerFinder), same(initialExplorerElement));

        await tester.enterText(strongField, 'H85');
        await _pumpStrongJumpAnimation(tester);

        expect(
          _scrollOffset(tester, _strongRailListFinder()),
          greaterThan(initialRailOffset),
          reason:
              'Strong input must move only the Strong Rail scroll position.',
        );
        expect(_visibleListTileTitles(tester), searchTitlesBeforeStrongJump);
        expect(tester.element(explorerFinder), same(initialExplorerElement));

        final explorerAfterStrongJump = tester.widget<WordExplorerScreen>(
          explorerFinder,
        );
        expect(explorerAfterStrongJump.key, initialExplorer.key);
        expect(
          explorerAfterStrongJump.initialWordId,
          initialExplorer.initialWordId,
        );

        await _disposeRuntimeApp(tester);
      },
    );

    testWidgets(
      'graph passive callback does not retarget or remount Explorer',
      (tester) async {
        _setSurfaceSize(tester, const Size(1440, 900));
        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await _pumpUntil(
          tester,
          () => find.byType(WordExplorerScreen).evaluate().length == 1,
          reason: 'large-screen Explorer pane must mount after DB bootstrap.',
        );
        await _pumpUntil(
          tester,
          () => _strongRailListFinder().evaluate().length == 1,
          reason:
              'Strong Rail list must render from the existing default list.',
        );
        await _waitForExplorerBootstrap(tester);

        final explorerFinder = find.byType(WordExplorerScreen);
        final initialExplorerElement = tester.element(explorerFinder);
        final initialExplorer = tester.widget<WordExplorerScreen>(
          explorerFinder,
        );
        final callback = initialExplorer.onSelectedStrongWordChanged;
        expect(callback, isNotNull);
        final initialRailOffset = _scrollOffset(
          tester,
          _strongRailListFinder(),
        );
        expect(_passiveSelectedDotFinder(), findsNothing);

        callback!.call('PHASE18N_PASSIVE_H85', 'H85');
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump(const Duration(milliseconds: 250));

        expect(
          _scrollOffset(tester, _strongRailListFinder()),
          greaterThan(initialRailOffset),
        );
        expect(_passiveSelectedDotFinder(), findsOneWidget);
        expect(tester.element(explorerFinder), same(initialExplorerElement));
        final explorerAfterPassiveSync = tester.widget<WordExplorerScreen>(
          explorerFinder,
        );
        expect(explorerAfterPassiveSync.key, initialExplorer.key);
        expect(
          explorerAfterPassiveSync.initialWordId,
          initialExplorer.initialWordId,
        );

        callback.call('PHASE18N_NO_STRONG', '');
        await tester.pump();

        expect(_passiveSelectedDotFinder(), findsNothing);
        expect(tester.element(explorerFinder), same(initialExplorerElement));
        final explorerAfterPassiveClear = tester.widget<WordExplorerScreen>(
          explorerFinder,
        );
        expect(explorerAfterPassiveClear.key, initialExplorer.key);
        expect(
          explorerAfterPassiveClear.initialWordId,
          initialExplorer.initialWordId,
        );

        await _disposeRuntimeApp(tester);
      },
    );

    testWidgets('small-screen search result tap keeps detail route flow', (
      tester,
    ) async {
      _setSurfaceSize(tester, const Size(800, 900));
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await _pumpUntil(
        tester,
        () =>
            find
                .widgetWithText(TextField, '검색 (표기·음역·의미·스트롱)')
                .evaluate()
                .length ==
            1,
        reason: 'small-screen search field must render after DB bootstrap.',
      );

      expect(find.byType(WordExplorerScreen), findsNothing);
      expect(find.widgetWithText(TextField, 'Strong/스트롱'), findsNothing);

      final searchField = find.widgetWithText(TextField, '검색 (표기·음역·의미·스트롱)');
      await tester.enterText(searchField, 'H1');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _pumpUntil(
        tester,
        () => find.byType(ListTile).evaluate().isNotEmpty,
        reason: 'small-screen search must render at least one candidate.',
      );

      await tester.tap(find.byType(ListTile).first);
      await _pumpUntil(
        tester,
        () => find.byType(WordDetailScreen).evaluate().length == 1,
        reason: 'small-screen search result tap must open the detail route.',
      );

      expect(find.byType(WordExplorerScreen), findsNothing);
      expect(find.byType(WordDetailScreen), findsOneWidget);

      await _disposeRuntimeApp(tester);
    });
  });
}

Finder _strongRailListFinder() {
  return find.byWidgetPredicate(
    (widget) => widget is ListView && widget.itemExtent == 46.0,
    description: 'Strong Rail ListView',
  );
}

Finder _passiveSelectedDotFinder() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is SizedBox && widget.width == 6.0 && widget.height == 6.0,
    description: 'Strong Rail passive selected marker',
  );
}

double _scrollOffset(WidgetTester tester, Finder listFinder) {
  final listView = tester.widget<ListView>(listFinder);
  final controller = listView.controller;
  expect(controller, isNotNull);
  expect(controller!.hasClients, isTrue);
  return controller.offset;
}

List<String> _visibleListTileTitles(WidgetTester tester) {
  return find
      .byType(ListTile)
      .evaluate()
      .map((element) => element.widget as ListTile)
      .map((tile) => tile.title)
      .whereType<Text>()
      .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
      .where((text) => text.isNotEmpty)
      .toList(growable: false);
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
    'reshet_phase18n_runtime_',
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
