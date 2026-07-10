import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/ui/word_detail_screen.dart';
import 'package:reshet_app/ui/word_graph_cache.dart';
import 'package:reshet_app/ui/word_graph_screen.dart';

const _representativeWordId = 'H0001_0000';
const _previewKey = Key('mobile-selected-node-preview');
const _centerActionKey = Key('selected-node-center-action');
const _relationLauncherKey = Key('selected-node-relation-launcher');

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

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await _deleteIsolatedWorkspace(isolatedRoot!);
    }
  });

  group('Phase 24-L mobile selected-node preview', () {
    test('representative DB row maps to the detail display contract', () async {
      final displayItem = await WordRepository()
          .getWordDetailLikeDisplayItemByIdForDetailScreen(
            _representativeWordId,
          );

      expect(displayItem, isNotNull);
      expect(displayItem!.displayStrongNumber, 'H1');
      expect(displayItem.representativeSpelling, 'אָב');
      expect(displayItem.transliterations.first, '아브');
      expect(displayItem.meanings.first, '아버지');
    });

    testWidgets('narrow selected graph shows compact preview fields', (
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
        () => find.byKey(_previewKey).evaluate().length == 1,
        reason: 'narrow selected graph must show the mobile preview.',
      );

      expect(find.byKey(_previewKey), findsOneWidget);
      expect(find.text('H1'), findsWidgets);
      expect(find.text('אָב'), findsWidgets);
      expect(find.text('아브'), findsWidgets);
      expect(find.text('아버지'), findsWidgets);

      await _disposeRuntimeApp(tester);
    });

    testWidgets('narrow graph without selection hides preview', (tester) async {
      _setSurfaceSize(tester, const Size(800, 900));
      await tester.pumpWidget(
        MaterialApp(home: WordGraphScreen(centerWordId: _representativeWordId)),
      );

      await _waitForGraphBootstrap(tester);
      expect(find.byKey(_previewKey), findsNothing);

      await _disposeRuntimeApp(tester);
    });

    testWidgets('900px selected graph hides mobile preview', (tester) async {
      _setSurfaceSize(tester, const Size(900, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: WordGraphScreen(
            centerWordId: _representativeWordId,
            selectedWordId: _representativeWordId,
          ),
        ),
      );

      await _waitForGraphBootstrap(tester);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      expect(find.byKey(_previewKey), findsNothing);

      await _disposeRuntimeApp(tester);
    });

    testWidgets('preview tap opens selected word detail route', (tester) async {
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
        () => find.byKey(_previewKey).evaluate().length == 1,
        reason: 'preview must be ready before route interaction.',
      );
      await tester.tap(find.byKey(_previewKey));
      await _pumpUntil(
        tester,
        () => find.byType(WordDetailScreen).evaluate().length == 1,
        reason: 'preview tap must open the existing WordDetailScreen route.',
      );

      expect(find.byType(WordDetailScreen), findsOneWidget);
      final detailScreen = tester.widget<WordDetailScreen>(
        find.byType(WordDetailScreen),
      );
      expect(detailScreen.wordId, _representativeWordId);

      await _disposeRuntimeApp(tester);
    });

    testWidgets(
      'portrait peripheral selection stacks preview, center action, and relation launcher without overlap',
      (tester) async {
        _setSurfaceSize(tester, const Size(360, 640));
        await tester.pumpWidget(
          MaterialApp(
            home: WordGraphScreen(centerWordId: _representativeWordId),
          ),
        );

        await _pumpUntil(
          tester,
          () => _peripheralNodeFinder().evaluate().isNotEmpty,
          reason: 'portrait graph must render at least one peripheral node.',
        );
        final peripheralNode = tester.widget<GestureDetector>(
          _peripheralNodeFinder().first,
        );
        final peripheralNodeKey = peripheralNode.key! as ValueKey<String>;
        final selectedWordId = peripheralNodeKey.value.substring(
          'graph-peripheral-node:'.length,
        );
        peripheralNode.onTap!.call();
        await tester.pump();

        await _pumpUntil(
          tester,
          () =>
              find.byKey(_previewKey).evaluate().length == 1 &&
              find.byKey(_centerActionKey).evaluate().length == 1 &&
              find.byKey(_relationLauncherKey).evaluate().length == 1,
          reason:
              'portrait peripheral selection must show all selected-node surfaces.',
        );

        final previewRect = tester.getRect(find.byKey(_previewKey));
        final centerActionRect = tester.getRect(find.byKey(_centerActionKey));
        final relationLauncherRect = tester.getRect(
          find.byKey(_relationLauncherKey),
        );
        expect(find.text('이 단어를 중심으로 보기'), findsOneWidget);
        expect(previewRect.overlaps(centerActionRect), isFalse);
        expect(centerActionRect.overlaps(relationLauncherRect), isFalse);
        expect(previewRect.bottom, lessThan(centerActionRect.top));
        expect(centerActionRect.bottom, lessThan(relationLauncherRect.top));
        expect(tester.takeException(), isNull);

        tester
            .widget<GestureDetector>(find.byKey(peripheralNodeKey))
            .onTap!
            .call();
        await tester.pump();

        expect(
          find.byType(WordGraphScreen),
          findsOneWidget,
          reason: 'same-node retap must keep standalone graph route depth.',
        );

        await tester.tap(find.byKey(_centerActionKey));
        await _pumpUntil(
          tester,
          () => find.byType(WordGraphScreen).evaluate().length == 2,
          reason: 'center action must open the existing standalone graph path.',
        );
        final graphScreens = tester
            .widgetList<WordGraphScreen>(find.byType(WordGraphScreen))
            .toList(growable: false);
        expect(graphScreens.last.centerWordId, selectedWordId);

        await _disposeRuntimeApp(tester);
      },
    );

    testWidgets(
      'portrait preview and relation launcher do not overlap and launcher opens action',
      (tester) async {
        _setSurfaceSize(tester, const Size(360, 640));
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
              find.byKey(_previewKey).evaluate().length == 1 &&
              find.byKey(_relationLauncherKey).evaluate().length == 1,
          reason: 'portrait graph must show preview and relation launcher.',
        );

        final previewRect = tester.getRect(find.byKey(_previewKey));
        final relationLauncherRect = tester.getRect(
          find.byKey(_relationLauncherKey),
        );
        expect(previewRect.overlaps(relationLauncherRect), isFalse);
        expect(previewRect.bottom, lessThan(relationLauncherRect.top));

        final opensRelationMenu = find
            .descendant(
              of: find.byKey(_relationLauncherKey),
              matching: find.byType(PopupMenuButton<int>),
            )
            .evaluate()
            .isNotEmpty;
        await tester.tap(find.byKey(_relationLauncherKey));
        await _pumpUntil(
          tester,
          () => opensRelationMenu
              ? find.byType(PopupMenuItem<int>).evaluate().isNotEmpty
              : find.byType(AlertDialog).evaluate().length == 1,
          reason: 'relation launcher must open its existing action surface.',
        );
        if (opensRelationMenu) {
          expect(find.byType(PopupMenuItem<int>), findsWidgets);
        } else {
          expect(find.byType(AlertDialog), findsOneWidget);
        }

        await _disposeRuntimeApp(tester);
      },
    );
  });
}

Finder _peripheralNodeFinder() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return widget is GestureDetector &&
        key is ValueKey<String> &&
        key.value.startsWith('graph-peripheral-node:');
  });
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
    () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
    reason: 'graph bootstrap reads must finish before assertions.',
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
  await tester.pump();
}

Future<Directory> _createIsolatedWorkspace(String sourceWorkDbPath) async {
  final isolatedRoot = await Directory.systemTemp.createTemp(
    'reshet_phase24l_preview_',
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
