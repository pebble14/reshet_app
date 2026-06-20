import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/ui/word_graph_cache.dart';
import 'package:reshet_app/ui/word_graph_screen.dart';

const _representativeWordId = 'H0001_0000';
const _centerVisualScaleKey = Key('graph-center-node-visual-scale');

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

  group('Phase 25-B graph node visual scale cap', () {
    testWidgets(
      'caps node visuals while center distance follows raw camera scale',
      (tester) async {
        await _pumpGraph(tester);

        final centerFinder = find.byKey(_centerVisualScaleKey);
        final peripheralFinder = _peripheralNodeTransforms().first;

        await _setCameraScale(tester, 1.6);
        expect(_localVisualScale(tester, centerFinder), closeTo(1.0, 0.0001));
        expect(
          _localVisualScale(tester, peripheralFinder),
          closeTo(1.0, 0.0001),
        );
        final distanceAtCap =
            (tester.getCenter(peripheralFinder) -
                    tester.getCenter(centerFinder))
                .distance;

        await _setCameraScale(tester, 3.2);
        final centerLocalScale = _localVisualScale(tester, centerFinder);
        final peripheralLocalScale = _localVisualScale(
          tester,
          peripheralFinder,
        );
        expect(centerLocalScale, closeTo(0.5, 0.0001));
        expect(peripheralLocalScale, closeTo(0.5, 0.0001));
        expect(3.2 * centerLocalScale, closeTo(1.6, 0.0001));
        expect(3.2 * peripheralLocalScale, closeTo(1.6, 0.0001));

        final distanceAboveCap =
            (tester.getCenter(peripheralFinder) -
                    tester.getCenter(centerFinder))
                .distance;
        expect(distanceAboveCap, closeTo(distanceAtCap * 2, 0.1));

        await _disposeRuntimeApp(tester);
      },
    );

    testWidgets('high zoom hit area matches the capped visible node bounds', (
      tester,
    ) async {
      String? selectedWordId;
      await _pumpGraph(
        tester,
        onSelectWordId: (wordId) => selectedWordId = wordId,
      );

      final peripheralFinder = _peripheralNodeTransforms().first;
      await _centerNodeInViewportAtScale(tester, peripheralFinder, 3.2);
      final nodeCenter = tester.getCenter(peripheralFinder);
      final baseNodeSize = tester.getSize(peripheralFinder).width;
      final cappedVisibleHalf = baseNodeSize / 2 * 1.6;

      await tester.tapAt(nodeCenter);
      await tester.pump();
      expect(selectedWordId, isNotNull);

      selectedWordId = null;
      await tester.tapAt(nodeCenter + Offset(cappedVisibleHalf + 12, 0));
      await tester.pump();
      expect(selectedWordId, isNull);

      await _disposeRuntimeApp(tester);
    });

    testWidgets('arrow tips use the capped node half', (tester) async {
      await _pumpGraph(tester);

      await _setCameraScale(tester, 1.0);
      final uncappedTips = _recordArrowTips(tester);
      expect(uncappedTips, isNotEmpty);

      final expectedHalfReductions = <double>{
        tester.getSize(find.byKey(_centerVisualScaleKey)).width / 4,
        for (final element in _peripheralNodeTransforms().evaluate())
          tester
                  .getSize(
                    find.byElementPredicate(
                      (candidate) => candidate == element,
                    ),
                  )
                  .width /
              4,
      };

      await _setCameraScale(tester, 3.2);
      final cappedTips = _recordArrowTips(tester);
      expect(cappedTips.length, uncappedTips.length);

      final remainingCappedTips = [...cappedTips];
      for (final uncappedTip in uncappedTips) {
        remainingCappedTips.sort(
          (left, right) => (left - uncappedTip).distance.compareTo(
            (right - uncappedTip).distance,
          ),
        );
        final cappedTip = remainingCappedTips.removeAt(0);
        final actualShift = (cappedTip - uncappedTip).distance;
        expect(
          expectedHalfReductions.any(
            (expectedShift) => (actualShift - expectedShift).abs() < 0.1,
          ),
          isTrue,
          reason: 'S=3.2이면 V=0.5이므로 arrow tip 이동량은 base node half의 절반이어야 한다.',
        );
      }

      await _disposeRuntimeApp(tester);
    });
  });
}

Finder _peripheralNodeTransforms() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return widget is Transform &&
        key is ValueKey<String> &&
        key.value.startsWith('graph-node-visual-scale:');
  });
}

double _localVisualScale(WidgetTester tester, Finder finder) {
  return tester.widget<Transform>(finder).transform.storage[0];
}

Future<void> _pumpGraph(
  WidgetTester tester, {
  ValueChanged<String>? onSelectWordId,
}) async {
  _setSurfaceSize(tester, const Size(1200, 900));
  await tester.pumpWidget(
    MaterialApp(
      home: WordGraphScreen(
        centerWordId: _representativeWordId,
        onSelectWordId: onSelectWordId,
      ),
    ),
  );

  await _pumpUntil(
    tester,
    () =>
        find.byType(CircularProgressIndicator).evaluate().isEmpty &&
        _peripheralNodeTransforms().evaluate().isNotEmpty,
    reason: 'graph bootstrap must render at least one peripheral node.',
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

Future<void> _centerNodeInViewportAtScale(
  WidgetTester tester,
  Finder nodeFinder,
  double scale,
) async {
  await _setCameraScale(tester, 1.0);
  final viewportFinder = find.byType(InteractiveViewer);
  final viewportRect = tester.getRect(viewportFinder);
  final sceneNodeCenter = tester.getCenter(nodeFinder) - viewportRect.topLeft;
  final targetCenter = viewportRect.size.center(Offset.zero);
  final translation = targetCenter - sceneNodeCenter * scale;

  final viewer = tester.widget<InteractiveViewer>(viewportFinder);
  final matrix = Matrix4.identity();
  matrix.translateByDouble(translation.dx, translation.dy, 0, 1.0);
  matrix.scaleByDouble(scale, scale, scale, 1.0);
  viewer.transformationController!.value = matrix;
  viewer.onInteractionUpdate?.call(
    ScaleUpdateDetails(
      focalPoint: targetCenter,
      localFocalPoint: targetCenter,
      scale: scale,
    ),
  );
  await tester.pump(const Duration(milliseconds: 250));
}

List<Offset> _recordArrowTips(WidgetTester tester) {
  for (final element in find.byType(CustomPaint).evaluate()) {
    final customPaint = element.widget as CustomPaint;
    final painter = customPaint.painter;
    if (painter == null) {
      continue;
    }

    final canvas = _LineRecordingCanvas();
    painter.paint(canvas, const Size(2400, 1600));
    final arrowTips = _arrowTipsFrom(canvas.lines);
    if (arrowTips.isNotEmpty) {
      return arrowTips;
    }
  }

  return const <Offset>[];
}

List<Offset> _arrowTipsFrom(List<({Offset start, Offset end})> lines) {
  final tips = <Offset>[];
  for (var index = 0; index + 1 < lines.length; index++) {
    final first = lines[index];
    final second = lines[index + 1];
    final shareStart = (first.start - second.start).distance < 0.001;
    final areArrowWings =
        (first.end - first.start).distance < 30 &&
        (second.end - second.start).distance < 30;
    if (shareStart && areArrowWings) {
      tips.add(first.start);
      index++;
    }
  }
  return tips;
}

class _LineRecordingCanvas extends TestRecordingCanvas {
  final lines = <({Offset start, Offset end})>[];

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    lines.add((start: p1, end: p2));
    super.drawLine(p1, p2, paint);
  }
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

Future<void> _disposeRuntimeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

Future<Directory> _createIsolatedWorkspace(String sourceWorkDbPath) async {
  final isolatedRoot = await Directory.systemTemp.createTemp(
    'reshet_phase25b_node_scale_cap_',
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
