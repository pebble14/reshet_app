import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/ui/word_graph_cache.dart';
import 'package:reshet_app/ui/word_graph_screen.dart';

const _centerWordId = 'T936B_CENTER';
const _targetWordId = 'T936B_TARGET';

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
    DatabaseService.setDataRootOverrideForTest(
      p.join(isolatedRoot!.path, 'data'),
    );
    Directory.current = isolatedRoot!.path;

    final db = await DatabaseService.openDatabaseFile();
    await _insertWord(
      db,
      id: _centerWordId,
      language: '중심 언어',
      spelling: '중심 표기',
      transliteration: '중심 음역',
      meaning: '중심 의미',
    );
    await _insertWord(
      db,
      id: _targetWordId,
      language: '상대 언어',
      spelling: '상대 표기',
      transliteration: '상대 음역',
      meaning: '상대 의미',
    );
    await _insertRelation(db, wordId1: _centerWordId, wordId2: _targetWordId);
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

  group('Phase 36-B edge chip placement', () {
    test('기본 anchor는 parallel offset 적용 후 visible segment 중앙이다', () {
      final placement = resolveEdgeChipPlacementForTesting(
        edgeStart: const Offset(0, 14),
        edgeEnd: const Offset(220, 14),
        label: '관계',
        sceneScale: 1.2,
        sourceNodeHalf: 40,
        targetNodeHalf: 30,
        hasOutgoingArrow: true,
      );

      _expectOffsetClose(placement.visibleStart, const Offset(48, 14));
      _expectOffsetClose(placement.visibleEnd, const Offset(168, 14));
      _expectOffsetClose(placement.selectedCenter, const Offset(108, 14));
      expect(placement.selectedCandidateKind, 'visibleSegmentCenter');
    });

    test('충돌 시 normal 후보보다 tangent 후보를 먼저 선택한다', () {
      final placement = resolveEdgeChipPlacementForTesting(
        edgeStart: Offset.zero,
        edgeEnd: const Offset(260, 0),
        label: '관계',
        sceneScale: 1.2,
        sourceNodeHalf: 20,
        targetNodeHalf: 20,
        nodeObstacles: [
          Rect.fromCenter(center: Offset(110, 0), width: 2, height: 200),
        ],
      );

      expect(placement.selectedCandidateKind, 'tangentForward');
      expect(
        placement.candidates.map((candidate) => candidate.kind),
        isNot(contains('radial')),
      );
      expect(placement.candidates.map((candidate) => candidate.kind).take(3), [
        'visibleSegmentCenter',
        'tangentForward',
        'tangentBackward',
      ]);
    });

    test('짧은 edge와 큰 chip에서도 후보 중심은 node와 arrowhead 안전 구간 밖에 남는다', () {
      final placement = resolveEdgeChipPlacementForTesting(
        edgeStart: Offset.zero,
        edgeEnd: const Offset(150, 0),
        label: '매우 긴 관계 chip',
        sceneScale: 1.2,
        sourceNodeHalf: 30,
        targetNodeHalf: 30,
        hasOutgoingArrow: true,
      );

      final minX = placement.visibleStart.dx;
      final maxX = placement.visibleEnd.dx;
      for (final candidate in placement.candidates) {
        expect(candidate.center.dx, greaterThanOrEqualTo(minX - 0.001));
        expect(candidate.center.dx, lessThanOrEqualTo(maxX + 0.001));
      }
      expect(placement.selectedCenter.dx, closeTo((minX + maxX) / 2, 0.001));
    });

    test('parallel edge는 이미 분리된 shifted geometry 기준 placement를 유지한다', () {
      final upper = resolveEdgeChipPlacementForTesting(
        edgeStart: const Offset(0, 14),
        edgeEnd: const Offset(220, 14),
        label: '관계',
        sceneScale: 1.2,
        sourceNodeHalf: 20,
        targetNodeHalf: 20,
      );
      final lower = resolveEdgeChipPlacementForTesting(
        edgeStart: const Offset(0, -14),
        edgeEnd: const Offset(220, -14),
        label: '관계',
        sceneScale: 1.2,
        sourceNodeHalf: 20,
        targetNodeHalf: 20,
      );

      expect(upper.selectedCenter.dy, closeTo(14, 0.001));
      expect(lower.selectedCenter.dy, closeTo(-14, 0.001));
      expect(
        upper.selectedCenter.dy,
        isNot(closeTo(lower.selectedCenter.dy, 0.001)),
      );
    });

    test('zoom visibility threshold는 기존 1.15 기준을 유지한다', () {
      expect(isEdgeChipVisibleForTesting(1.149), isFalse);
      expect(isEdgeChipVisibleForTesting(1.15), isTrue);
    });

    test('충돌이 없으면 기존 visible segment 중심 후보를 유지한다', () {
      final placement = resolveEdgeChipPlacementForTesting(
        edgeStart: Offset.zero,
        edgeEnd: const Offset(260, 0),
        label: '관계',
        sceneScale: 1.2,
        sourceNodeHalf: 20,
        targetNodeHalf: 20,
      );

      expect(placement.selectedCandidateKind, 'visibleSegmentCenter');
      expect(placement.selectedCenter, const Offset(130, 0));
    });

    test('node obstacle 회피에서도 normal 후보는 edge 인접 8px 범위를 유지한다', () {
      final placement = resolveEdgeChipPlacementForTesting(
        edgeStart: Offset.zero,
        edgeEnd: const Offset(260, 0),
        label: '관계',
        sceneScale: 1.2,
        sourceNodeHalf: 20,
        targetNodeHalf: 20,
        nodeObstacles: [
          Rect.fromCenter(center: const Offset(130, 0), width: 260, height: 40),
        ],
      );

      expect(placement.selectedCandidateKind, 'normalPositive');
      expect(placement.selectedCenter.dx, closeTo(130, 0.001));
      expect(placement.selectedCenter.dy, closeTo(8, 0.001));
      expect(
        placement.candidates
            .where((candidate) => candidate.kind.startsWith('normal'))
            .every((candidate) => candidate.center.dy.abs() <= 8.001),
        isTrue,
      );
    });

    test('placed chip 회피에서도 normal 후보는 edge 인접 8px 범위를 유지한다', () {
      final placement = resolveEdgeChipPlacementForTesting(
        edgeStart: Offset.zero,
        edgeEnd: const Offset(260, 0),
        label: '관계',
        sceneScale: 1.2,
        sourceNodeHalf: 20,
        targetNodeHalf: 20,
        placedLabelBounds: [
          Rect.fromCenter(center: const Offset(130, 0), width: 260, height: 40),
        ],
      );

      expect(placement.selectedCandidateKind, 'normalPositive');
      expect(placement.selectedCenter.dx, closeTo(130, 0.001));
      expect(placement.selectedCenter.dy, closeTo(8, 0.001));
      expect(
        placement.candidates
            .where((candidate) => candidate.kind.startsWith('normal'))
            .every((candidate) => candidate.center.dy.abs() <= 8.001),
        isTrue,
      );
    });

    testWidgets('visible zoom chip tap은 기존 관계 상세 popup을 연다', (tester) async {
      await _pumpGraph(tester);
      await _setCameraScale(tester, 1.2);
      await _pumpUntil(
        tester,
        () => _edgeChipFinder().evaluate().isNotEmpty,
        reason: 'visible zoom에서는 edge chip이 렌더링되어야 한다.',
      );

      await tester.tap(_edgeChipFinder().first, warnIfMissed: false);
      await _pumpUntil(
        tester,
        () => find.byType(AlertDialog).evaluate().length == 1,
        reason: 'edge chip tap은 기존 관계 상세 popup을 열어야 한다.',
      );

      expect(find.textContaining('관계:'), findsOneWidget);

      await _disposeRuntimeApp(tester);
    });
  });
}

Finder _edgeChipFinder() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith('graph-edge-chip:');
  });
}

void _expectOffsetClose(Offset actual, Offset expected) {
  expect(actual.dx, closeTo(expected.dx, 0.001));
  expect(actual.dy, closeTo(expected.dy, 0.001));
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
    'reshet_phase36b_edge_chip_',
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

Future<void> _insertRelation(
  dynamic db, {
  required String wordId1,
  required String wordId2,
}) async {
  await db.insert('WORD_RELATION', {
    'word_id_1': wordId1,
    'word_id_2': wordId2,
    'direction_code': 'unknown',
    'updated_at': DateTime.now().toIso8601String(),
  });
}
