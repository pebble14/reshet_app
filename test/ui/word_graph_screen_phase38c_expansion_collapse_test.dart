import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/ui/word_graph_cache.dart';
import 'package:reshet_app/ui/word_graph_screen.dart';

const _centerWordId = 'T938C_CENTER';
const _sourceAWordId = 'T938C_SOURCE_A';
const _sourceBWordId = 'T938C_SOURCE_B';
const _aOnlyWordId = 'T938C_A_ONLY';
const _bOnlyWordId = 'T938C_B_ONLY';
const _sharedWordId = 'T938C_SHARED';
const _aExtraWordIds = [
  'T938C_A_EXTRA_1',
  'T938C_A_EXTRA_2',
  'T938C_A_EXTRA_3',
  'T938C_A_EXTRA_4',
  'T938C_A_EXTRA_5',
];
const _collapseLabel = '확장 접기';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String repoRootPath;
  late String sourceWorkDbPath;
  Directory? isolatedRoot;
  late int relationAOnlyId;
  late int relationASharedId;
  late int relationBOnlyId;
  late int relationBSharedId;

  setUpAll(() async {
    repoRootPath = Directory.current.path;
    sourceWorkDbPath = p.join(repoRootPath, 'data', 'reshet_work.db');

    expect(File(sourceWorkDbPath).existsSync(), isTrue);
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    WordGraphDataCache.clear();
    isolatedRoot = await _createIsolatedWorkspace(sourceWorkDbPath);
    Directory.current = isolatedRoot!.path;

    final db = await DatabaseService.openDatabaseFile();
    await _insertWord(db, id: _centerWordId, spelling: 'Phase38C Center');
    await _insertWord(db, id: _sourceAWordId, spelling: 'Phase38C Source A');
    await _insertWord(db, id: _sourceBWordId, spelling: 'Phase38C Source B');
    await _insertWord(db, id: _aOnlyWordId, spelling: 'Phase38C A Only');
    await _insertWord(db, id: _bOnlyWordId, spelling: 'Phase38C B Only');
    await _insertWord(db, id: _sharedWordId, spelling: 'Phase38C Shared');
    for (final wordId in _aExtraWordIds) {
      await _insertWord(db, id: wordId, spelling: 'Phase38C $wordId');
    }
    await _insertRelation(db, wordId1: _centerWordId, wordId2: _sourceAWordId);
    await _insertRelation(db, wordId1: _centerWordId, wordId2: _sourceBWordId);
    relationAOnlyId = await _insertRelation(
      db,
      wordId1: _sourceAWordId,
      wordId2: _aOnlyWordId,
    );
    relationASharedId = await _insertRelation(
      db,
      wordId1: _sourceAWordId,
      wordId2: _sharedWordId,
    );
    for (final wordId in _aExtraWordIds) {
      await _insertRelation(db, wordId1: _sourceAWordId, wordId2: wordId);
    }
    relationBOnlyId = await _insertRelation(
      db,
      wordId1: _sourceBWordId,
      wordId2: _bOnlyWordId,
    );
    relationBSharedId = await _insertRelation(
      db,
      wordId1: _sourceBWordId,
      wordId2: _sharedWordId,
    );
    await DatabaseService.closeDatabase();
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    WordGraphDataCache.clear();
    Directory.current = repoRootPath;

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await _deleteIsolatedWorkspace(isolatedRoot!);
    }
  });

  group('Phase 38-C depth 1 expansion collapse', () {
    testWidgets(
      'collapses only the selected source branch and preserves another expanded source',
      (tester) async {
        await _pumpGraph(tester);
        expect(_collapseActionFinder(), findsNothing);

        await _tapNode(tester, _sourceAWordId);
        await _pumpUntil(
          tester,
          () =>
              _nodeFinder(_aOnlyWordId).evaluate().isNotEmpty &&
              _nodeFinder(_sharedWordId).evaluate().isNotEmpty &&
              _collapseActionFinder().evaluate().length == 1,
          reason:
              'source A expansion must expose its branch and collapse action.',
        );
        expect(find.text(_collapseLabel), findsOneWidget);

        await _tapNode(tester, _sourceBWordId);
        await _pumpUntil(
          tester,
          () =>
              _nodeFinder(_bOnlyWordId).evaluate().isNotEmpty &&
              _collapseActionFinder().evaluate().length == 1,
          reason:
              'source B expansion must expose its branch and collapse action.',
        );

        await _tapNode(tester, _sourceAWordId);
        await _pumpUntil(
          tester,
          () => _collapseActionFinder().evaluate().length == 1,
          reason: 'returning to expanded source A must show collapse action.',
        );
        await tester.tap(_collapseActionFinder());
        await _pumpUntil(
          tester,
          () =>
              _nodeFinder(_aOnlyWordId).evaluate().isEmpty &&
              _nodeFinder(_bOnlyWordId).evaluate().isNotEmpty &&
              _nodeFinder(_sharedWordId).evaluate().isNotEmpty,
          reason:
              'collapsing source A must remove A-only nodes and keep B/shared nodes.',
        );

        expect(_nodeFinder(_sourceAWordId), findsOneWidget);
        expect(_nodeFinder(_sourceBWordId), findsOneWidget);
        expect(_selectedRingFinder(_sourceAWordId), findsOneWidget);
        expect(_collapseActionFinder(), findsNothing);

        await _tapNode(tester, _sourceBWordId);
        await _pumpUntil(
          tester,
          () => _selectedRingFinder(_sourceBWordId).evaluate().length == 1,
          reason: 'source B must remain selectable after source A collapse.',
        );
        await _setCameraScale(tester, 1.2);
        await _pumpUntil(
          tester,
          () =>
              _edgeChipFinder(relationBOnlyId).evaluate().isNotEmpty &&
              _edgeChipFinder(relationBSharedId).evaluate().isNotEmpty,
          reason:
              'remaining source B expansion edges must stay in the rebuilt graph.',
        );

        await _tapNode(tester, _sharedWordId);
        await _pumpUntil(
          tester,
          () => _selectedRingFinder(_sharedWordId).evaluate().length == 1,
          reason: 'shared depth 2 node must stay selectable after rebuild.',
        );
        await _setCameraScale(tester, 1.2);
        expect(_edgeChipFinder(relationAOnlyId), findsNothing);
        expect(_edgeChipFinder(relationASharedId), findsNothing);
        expect(_edgeChipFinder(relationBSharedId), findsOneWidget);

        await _disposeRuntimeApp(tester);
      },
    );

    testWidgets('selected but unexpanded depth 1 node hides collapse action', (
      tester,
    ) async {
      await _pumpGraph(tester, selectedWordId: _sourceAWordId);
      await _pumpUntil(
        tester,
        () => _selectedRingFinder(_sourceAWordId).evaluate().length == 1,
        reason: 'source A must be selected without running depth 2 expansion.',
      );

      expect(_nodeFinder(_aOnlyWordId), findsNothing);
      expect(_collapseActionFinder(), findsNothing);

      await _disposeRuntimeApp(tester);
    });

    testWidgets('collapse resets the selected source +N more reveal state', (
      tester,
    ) async {
      await _pumpGraph(tester);

      await _tapNode(tester, _sourceAWordId);
      await _pumpUntil(
        tester,
        () =>
            _collapseActionFinder().evaluate().length == 1 &&
            _sourcePlaceholderFinder(_sourceAWordId).evaluate().length == 1,
        reason: 'source A expansion must start with a +N more placeholder.',
      );

      await tester.tap(
        _sourcePlaceholderFinder(_sourceAWordId),
        warnIfMissed: false,
      );
      await _pumpUntil(
        tester,
        () => _sourcePlaceholderFinder(_sourceAWordId).evaluate().isEmpty,
        reason: 'source A +N more placeholder must disappear after reveal.',
      );

      await tester.tap(_collapseActionFinder());
      await _pumpUntil(
        tester,
        () =>
            _collapseActionFinder().evaluate().isEmpty &&
            _nodeFinder(_aOnlyWordId).evaluate().isEmpty,
        reason: 'source A collapse must remove its expansion branch.',
      );

      await _tapNode(tester, _sourceBWordId);
      await _pumpUntil(
        tester,
        () => _selectedRingFinder(_sourceBWordId).evaluate().length == 1,
        reason: 'selecting another source must allow source A re-expansion.',
      );
      await _tapNode(tester, _sourceAWordId);
      await _pumpUntil(
        tester,
        () => _sourcePlaceholderFinder(_sourceAWordId).evaluate().length == 1,
        reason: 'source A +N more placeholder must return after re-expansion.',
      );

      await _disposeRuntimeApp(tester);
    });
  });
}

Finder _collapseActionFinder() {
  return find.byKey(const Key('selected-node-collapse-expansion'));
}

Finder _nodeFinder(String wordId) {
  return find.byKey(ValueKey<String>('graph-peripheral-node:$wordId'));
}

Finder _selectedRingFinder(String wordId) {
  return find.byKey(
    ValueKey<String>('graph-peripheral-node-selected-ring:$wordId'),
  );
}

Finder _sourcePlaceholderFinder(String sourceWordId) {
  return find.byKey(
    ValueKey<String>('graph-node-visual-scale:__graph_more__::$sourceWordId'),
  );
}

Finder _edgeChipFinder(int relationId) {
  return find.byKey(ValueKey<String>('graph-edge-chip:$relationId'));
}

Future<void> _pumpGraph(WidgetTester tester, {String? selectedWordId}) async {
  _setSurfaceSize(tester, const Size(1200, 900));
  await tester.pumpWidget(
    MaterialApp(
      home: WordGraphScreen(
        centerWordId: _centerWordId,
        selectedWordId: selectedWordId,
      ),
    ),
  );

  await _pumpUntil(
    tester,
    () =>
        find.byType(CircularProgressIndicator).evaluate().isEmpty &&
        _nodeFinder(_sourceAWordId).evaluate().isNotEmpty &&
        _nodeFinder(_sourceBWordId).evaluate().isNotEmpty,
    reason: 'controlled graph fixture must render both depth 1 source nodes.',
  );
}

Future<void> _tapNode(WidgetTester tester, String wordId) async {
  await tester.tap(_nodeFinder(wordId), warnIfMissed: false);
  await tester.pump();
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
    'reshet_phase38c_expansion_collapse_',
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
  required String spelling,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '\uC5B8\uC5B4': 'Phase38C Language',
    '\uD45C\uAE301': spelling,
    '\uC74C\uC5ED1': '$spelling transliteration',
    '\uC758\uBBF81': '$spelling meaning',
  });
  await db.insert('word_expression_set', {
    'word_id': id,
    'seq': 1,
    'is_representative': 1,
    'spelling': spelling,
    'transliteration': '$spelling transliteration',
  });
}

Future<int> _insertRelation(
  dynamic db, {
  required String wordId1,
  required String wordId2,
}) async {
  final orderedWordId1 = wordId1.compareTo(wordId2) <= 0 ? wordId1 : wordId2;
  final orderedWordId2 = wordId1.compareTo(wordId2) <= 0 ? wordId2 : wordId1;
  return await db.insert('WORD_RELATION', {
    'word_id_1': orderedWordId1,
    'word_id_2': orderedWordId2,
    'direction_code': 'unknown',
    'relation_type': 'translation',
    'category_code': 'translation',
    'updated_at': DateTime.now().toIso8601String(),
  });
}
