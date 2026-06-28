import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/ui/word_graph_cache.dart';
import 'package:reshet_app/ui/word_graph_screen.dart';

const _centerWordId = 'H0001_0000';

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

  group('Phase 33-B graph create expression set dialog', () {
    testWidgets(
      'adds the seventh spelling transliteration and pronunciation fields',
      (tester) async {
        _setSurfaceSize(tester, const Size(1200, 1600));

        await tester.pumpWidget(
          MaterialApp(home: WordGraphScreen(centerWordId: _centerWordId)),
        );
        await _waitForGraphBootstrap(tester);

        await tester.tap(find.byTooltip('단어 추가'));
        await _pumpUntil(
          tester,
          () => find.byType(AlertDialog).evaluate().isNotEmpty,
          reason: 'graph create dialog must open from the app bar action.',
        );

        for (var index = 0; index < 6; index++) {
          await _enterExpressionSetValues(tester, index);
          if (index < 5) {
            await _tapAddExpressionSet(tester);
          }
        }

        expect(_expressionField('표기'), findsNWidgets(6));
        expect(_expressionField('음역'), findsNWidgets(6));
        expect(_expressionField('발음'), findsNWidgets(6));

        await _tapAddExpressionSet(tester);

        expect(_expressionField('표기'), findsNWidgets(7));
        expect(_expressionField('음역'), findsNWidgets(7));
        expect(_expressionField('발음'), findsNWidgets(7));
        expect(_expressionField('표기').at(6), findsOneWidget);
        expect(_expressionField('음역').at(6), findsOneWidget);
        expect(_expressionField('발음').at(6), findsOneWidget);

        await _disposeRuntimeApp(tester);
      },
    );
  });
}

Finder _expressionField(String label) {
  return find.widgetWithText(TextField, label);
}

Future<void> _enterExpressionSetValues(WidgetTester tester, int index) async {
  final suffix = (index + 1).toString().padLeft(2, '0');

  await tester.ensureVisible(_expressionField('표기').at(index));
  await tester.enterText(
    _expressionField('표기').at(index),
    'phase33_dialog_spelling_$suffix',
  );
  await tester.enterText(
    _expressionField('음역').at(index),
    'phase33_dialog_trans_$suffix',
  );
  await tester.enterText(
    _expressionField('발음').at(index),
    'phase33_dialog_pron_$suffix',
  );
  await tester.pump();
}

Future<void> _tapAddExpressionSet(WidgetTester tester) async {
  final addButton = find.widgetWithText(TextButton, '+ 세트 추가');
  await tester.ensureVisible(addButton);
  await tester.tap(addButton);
  await tester.pump();
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
    reason: 'graph bootstrap reads must finish before dialog interaction.',
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
    'reshet_phase33b_graph_create_dialog_',
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
