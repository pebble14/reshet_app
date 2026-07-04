import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/ui/word_graph_cache.dart';
import 'package:reshet_app/ui/word_graph_screen.dart';

const _centerWordId = 'T939C_CENTER';
const _targetWordId = 'T939C_TARGET';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String repoRootPath;
  late String sourceWorkDbPath;
  Directory? isolatedRoot;
  late int relationId;

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

    final db = await DatabaseService.openDatabaseFile();
    await _insertWord(
      db,
      id: _centerWordId,
      language: '중심 언어',
      spelling: 'Phase39C Center',
      transliteration: '중심 음역',
      meaning: '중심 의미',
    );
    await _insertWord(
      db,
      id: _targetWordId,
      language: '상대 언어',
      spelling: 'Phase39C Target',
      transliteration: '상대 음역',
      meaning: '상대 의미',
    );
    relationId = await _insertRelation(
      db,
      wordId1: _centerWordId,
      wordId2: _targetWordId,
      description: 'Phase39C relation detail',
    );
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    WordGraphDataCache.clear();
    Directory.current = repoRootPath;

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await _deleteIsolatedWorkspace(isolatedRoot!);
    }
  });

  testWidgets('inner visual 밖 outer envelope 안쪽 탭도 기존 관계 상세를 연다', (
    tester,
  ) async {
    await _pumpGraph(tester);
    await _setCameraScale(tester, 1.2);
    await _pumpUntil(
      tester,
      () => _edgeChipFinder(relationId).evaluate().length == 1,
      reason: 'visible zoom에서는 edge chip이 렌더링되어야 한다.',
    );
    await tester.pumpAndSettle();

    final outerRect = tester.getRect(_edgeChipFinder(relationId));
    final innerRect = tester.getRect(_edgeChipVisualFinder(relationId));

    expect(outerRect.width, greaterThan(innerRect.width));
    expect(
      outerRect.width * outerRect.height,
      greaterThan(innerRect.width * innerRect.height),
    );

    final tapPoint = Offset(
      (innerRect.right + outerRect.right) / 2,
      outerRect.center.dy,
    );
    expect(innerRect.contains(tapPoint), isFalse);
    expect(outerRect.contains(tapPoint), isTrue);

    await tester.tapAt(tapPoint);
    await _pumpUntil(
      tester,
      () => find.byType(AlertDialog).evaluate().length == 1,
      reason: 'outer envelope 안쪽 탭은 기존 관계 상세 popup을 열어야 한다.',
    );

    expect(find.textContaining('관계:'), findsOneWidget);
    expect(find.textContaining('Phase39C Center'), findsWidgets);
    expect(find.textContaining('Phase39C Target'), findsWidgets);
    expect(find.text('Phase39C relation detail'), findsOneWidget);

    await _disposeRuntimeApp(tester);
  });
}

Finder _edgeChipFinder(int relationId) {
  return find.byKey(ValueKey<String>('graph-edge-chip:$relationId'));
}

Finder _edgeChipVisualFinder(int relationId) {
  return find.byKey(ValueKey<String>('graph-edge-chip-visual:$relationId'));
}

Future<void> _pumpGraph(WidgetTester tester) async {
  _setSurfaceSize(tester, const Size(1200, 900));
  await tester.pumpWidget(
    MaterialApp(home: WordGraphScreen(centerWordId: _centerWordId)),
  );

  await _pumpUntil(
    tester,
    () =>
        find.byType(CircularProgressIndicator).evaluate().isEmpty &&
        find
            .byKey(ValueKey<String>('graph-peripheral-node:$_targetWordId'))
            .evaluate()
            .isNotEmpty,
    reason: 'controlled graph fixture must render the target node.',
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

Future<Directory> _createIsolatedWorkspace(String sourceWorkDbPath) async {
  final isolatedRoot = await Directory.systemTemp.createTemp(
    'reshet_phase39c_edge_chip_',
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
  required String language,
  required String spelling,
  required String transliteration,
  required String meaning,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '\uC5B8\uC5B4': language,
    '\uD45C\uAE301': spelling,
    '\uC74C\uC5ED1': transliteration,
    '\uC758\uBBF81': meaning,
  });
  await db.insert('word_expression_set', {
    'word_id': id,
    'seq': 1,
    'is_representative': 1,
    'spelling': spelling,
    'transliteration': transliteration,
  });
}

Future<int> _insertRelation(
  dynamic db, {
  required String wordId1,
  required String wordId2,
  required String description,
}) async {
  return await db.insert('WORD_RELATION', {
        'word_id_1': wordId1,
        'word_id_2': wordId2,
        'direction_code': 'unknown',
        'description': description,
        'updated_at': DateTime.now().toIso8601String(),
      })
      as int;
}
