import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/ui/word_graph_cache.dart';
import 'package:reshet_app/ui/word_graph_screen.dart';

const _centerWordId = 'T925D_CENTER';
const _fullWordId = 'T925D_FULL';
const _sparseWordId = 'T925D_SPARSE';

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
      id: _fullWordId,
      language: ' 실제 표시 언어 ',
      strongNumber: 'h00042',
      spelling: '대표 표기',
      transliteration: '대표 음역',
      meaning: ' 대표 의미 ',
    );
    await _insertWord(
      db,
      id: _sparseWordId,
      language: ' 희소 언어 ',
      spelling: '',
      transliteration: '',
      meaning: '   ',
    );
    await _insertRelation(db, wordId1: _centerWordId, wordId2: _fullWordId);
    await _insertRelation(db, wordId1: _centerWordId, wordId2: _sparseWordId);
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    WordGraphDataCache.clear();
    Directory.current = repoRootPath;

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await _deleteIsolatedWorkspace(isolatedRoot!);
    }
  });

  group('Phase 25-D peripheral node LOD', () {
    test('uses the fixed initial scale boundaries', () {
      expect(
        resolvePeripheralNodeLodForTesting(cameraScale: 1.149),
        PeripheralNodeLodLevel.lod1,
      );
      expect(
        resolvePeripheralNodeLodForTesting(cameraScale: 1.15),
        PeripheralNodeLodLevel.lod2,
      );
      expect(
        resolvePeripheralNodeLodForTesting(cameraScale: 1.799),
        PeripheralNodeLodLevel.lod2,
      );
      expect(
        resolvePeripheralNodeLodForTesting(cameraScale: 1.80),
        PeripheralNodeLodLevel.lod3,
      );
    });

    testWidgets(
      'changes line hierarchy by raw scale and omits blank payload lines',
      (tester) async {
        await _pumpGraph(tester);

        _expectLineText(tester, _fullWordId, 'strong', 'H42');
        expect(_lineFinder(_fullWordId, 'language'), findsNothing);
        expect(_lineFinder(_fullWordId, 'spelling'), findsNothing);

        _expectLineText(tester, _sparseWordId, 'spelling', _sparseWordId);
        expect(_lineFinder(_sparseWordId, 'strong'), findsNothing);

        await _setCameraScale(tester, 1.20);
        _expectLineText(tester, _fullWordId, 'language', '실제 표시 언어');
        _expectLineText(tester, _fullWordId, 'strong', 'H42');
        _expectLineText(tester, _fullWordId, 'spelling', '대표 표기');
        expect(_lineFinder(_fullWordId, 'transliteration'), findsNothing);
        expect(_lineFinder(_fullWordId, 'meaning'), findsNothing);

        await _setCameraScale(tester, 1.85);
        _expectLineText(tester, _fullWordId, 'language', '실제 표시 언어');
        _expectLineText(tester, _fullWordId, 'strong', 'H42');
        _expectLineText(tester, _fullWordId, 'spelling', '대표 표기');
        _expectLineText(tester, _fullWordId, 'transliteration', '대표 음역');
        _expectLineText(tester, _fullWordId, 'meaning', '대표 의미');

        final languageText = tester.widget<Text>(
          _lineFinder(_fullWordId, 'language'),
        );
        expect(languageText.data, isNot('T'));

        _expectLineText(tester, _sparseWordId, 'language', '희소 언어');
        _expectLineText(tester, _sparseWordId, 'spelling', _sparseWordId);
        expect(_lineFinder(_sparseWordId, 'strong'), findsNothing);
        expect(_lineFinder(_sparseWordId, 'transliteration'), findsNothing);
        expect(_lineFinder(_sparseWordId, 'meaning'), findsNothing);
        expect(
          _lodTextValues(tester, _sparseWordId, PeripheralNodeLodLevel.lod3),
          ['희소 언어', _sparseWordId],
        );

        for (final role in [
          'language',
          'strong',
          'spelling',
          'transliteration',
          'meaning',
        ]) {
          final text = tester.widget<Text>(_lineFinder(_fullWordId, role));
          expect(text.maxLines, 1);
          expect(text.overflow, TextOverflow.ellipsis);
        }

        await _disposeRuntimeApp(tester);
      },
    );

    testWidgets('holds hysteresis bands and resolves large jumps directly', (
      tester,
    ) async {
      await _pumpGraph(tester);

      await _setCameraScale(tester, 1.20);
      _expectLod(tester, _fullWordId, PeripheralNodeLodLevel.lod2);
      await _setCameraScale(tester, 1.15);
      _expectLod(tester, _fullWordId, PeripheralNodeLodLevel.lod2);
      await _setCameraScale(tester, 1.10);
      _expectLod(tester, _fullWordId, PeripheralNodeLodLevel.lod2);
      await _setCameraScale(tester, 1.09);
      _expectLod(tester, _fullWordId, PeripheralNodeLodLevel.lod1);

      await _setCameraScale(tester, 1.90);
      _expectLod(tester, _fullWordId, PeripheralNodeLodLevel.lod3);
      await _setCameraScale(tester, 1.80);
      _expectLod(tester, _fullWordId, PeripheralNodeLodLevel.lod3);
      await _setCameraScale(tester, 1.75);
      _expectLod(tester, _fullWordId, PeripheralNodeLodLevel.lod3);
      await _setCameraScale(tester, 1.74);
      _expectLod(tester, _fullWordId, PeripheralNodeLodLevel.lod2);

      await _setCameraScale(tester, 1.90);
      _expectLod(tester, _fullWordId, PeripheralNodeLodLevel.lod3);
      await _setCameraScale(tester, 1.0);
      _expectLod(tester, _fullWordId, PeripheralNodeLodLevel.lod1);

      await _disposeRuntimeApp(tester);
    });

    testWidgets('keeps the actual peripheral capacity curve in LOD 3', (
      tester,
    ) async {
      await _pumpGraph(tester);
      await _setCameraScale(tester, 1.85);

      tester.widget<GestureDetector>(_nodeFinder(_fullWordId)).onTap!();
      await tester.pump(const Duration(milliseconds: 250));

      final localScaleAtLod3 = _localVisualScale(tester, _fullWordId);
      final fontSizeAtLod3 = _lineFontSize(tester, _fullWordId, 'spelling');
      final borderWidthAtLod3 = _bodyBorderWidth(tester, _fullWordId);
      final ringWidthAtLod3 = _selectedRingWidth(tester, _fullWordId);

      expect(localScaleAtLod3, closeTo(1.8 / 1.85, 0.0001));

      await _setCameraScale(tester, 3.2);
      _expectLod(tester, _fullWordId, PeripheralNodeLodLevel.lod3);
      expect(
        _localVisualScale(tester, _fullWordId),
        closeTo(1.8 / 3.2, 0.0001),
      );
      expect(
        _lineFontSize(tester, _fullWordId, 'spelling'),
        closeTo(fontSizeAtLod3, 0.0001),
      );
      expect(
        _bodyBorderWidth(tester, _fullWordId),
        closeTo(borderWidthAtLod3, 0.0001),
      );
      expect(
        _selectedRingWidth(tester, _fullWordId),
        closeTo(ringWidthAtLod3, 0.0001),
      );

      await _disposeRuntimeApp(tester);
    });
  });
}

Finder _nodeFinder(String wordId) {
  return find.byKey(ValueKey<String>('graph-peripheral-node:$wordId'));
}

Finder _lineFinder(String wordId, String role) {
  return find.byKey(
    ValueKey<String>('graph-peripheral-node-lod-line:$wordId:$role'),
  );
}

Finder _lodFinder(String wordId, PeripheralNodeLodLevel lod) {
  return find.byKey(
    ValueKey<String>('graph-peripheral-node-lod:$wordId:${lod.name}'),
  );
}

void _expectLineText(
  WidgetTester tester,
  String wordId,
  String role,
  String expected,
) {
  final finder = _lineFinder(wordId, role);
  expect(finder, findsOneWidget);
  expect(tester.widget<Text>(finder).data, expected);
}

void _expectLod(
  WidgetTester tester,
  String wordId,
  PeripheralNodeLodLevel lod,
) {
  expect(_lodFinder(wordId, lod), findsOneWidget);
}

List<String> _lodTextValues(
  WidgetTester tester,
  String wordId,
  PeripheralNodeLodLevel lod,
) {
  final textFinder = find.descendant(
    of: _lodFinder(wordId, lod),
    matching: find.byType(Text),
  );
  return textFinder
      .evaluate()
      .map((element) => (element.widget as Text).data ?? '')
      .toList(growable: false);
}

double _localVisualScale(WidgetTester tester, String wordId) {
  final transform = tester.widget<Transform>(
    find.byKey(ValueKey<String>('graph-node-visual-scale:$wordId')),
  );
  return transform.transform.storage[0];
}

double _lineFontSize(WidgetTester tester, String wordId, String role) {
  return tester.widget<Text>(_lineFinder(wordId, role)).style!.fontSize!;
}

double _bodyBorderWidth(WidgetTester tester, String wordId) {
  final container = tester.widget<AnimatedContainer>(
    find.byKey(ValueKey<String>('graph-peripheral-node-body:$wordId')),
  );
  final decoration = container.decoration! as BoxDecoration;
  return (decoration.border! as Border).top.width;
}

double _selectedRingWidth(WidgetTester tester, String wordId) {
  final container = tester.widget<AnimatedContainer>(
    find.byKey(ValueKey<String>('graph-peripheral-node-selected-ring:$wordId')),
  );
  final decoration = container.decoration! as BoxDecoration;
  return (decoration.border! as Border).top.width;
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
        _nodeFinder(_fullWordId).evaluate().isNotEmpty &&
        _nodeFinder(_sparseWordId).evaluate().isNotEmpty,
    reason: 'controlled peripheral nodes must render.',
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
    'reshet_phase25d_peripheral_lod_',
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
  String? strongNumber,
  required String spelling,
  required String transliteration,
  required String meaning,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '\uC5B8\uC5B4': language,
    '\uC2A4\uD2B8\uB871\uB118\uBC84': strongNumber,
    '\uD45C\uAE301': spelling,
    '\uC74C\uC5ED1': transliteration,
    '\uC758\uBBF81': meaning,
  });
  if (spelling.trim().isNotEmpty) {
    await db.insert('word_expression_set', {
      'word_id': id,
      'seq': 1,
      'is_representative': 1,
      'spelling': spelling,
      'transliteration': transliteration,
    });
  }
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
