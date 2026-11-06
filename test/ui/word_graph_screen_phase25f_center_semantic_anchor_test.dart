import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/ui/word_graph_cache.dart';
import 'package:reshet_app/ui/word_graph_screen.dart';

const _fullWordId = 'T925F_FULL';
const _languageOnlyWordId = 'T925F_LANGUAGE_ONLY';
const _strongOnlyWordId = 'T925F_STRONG_ONLY';
const _blankWordId = 'T925F_BLANK';
const _pronunciation = '표시하면 안 되는 발음';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String sourceWorkDbPath;
  Directory? isolatedRoot;

  setUpAll(() async {
    sourceWorkDbPath = p.join(Directory.current.path, 'data', 'reshet_work.db');

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
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    WordGraphDataCache.clear();
    DatabaseService.setDataRootOverrideForTest(null);

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await _deleteIsolatedWorkspace(isolatedRoot!);
    }
  });

  group('Phase 25-F center semantic anchor', () {
    setUp(() async {
      final db = await DatabaseService.openDatabaseFile();
      await _insertPhase25FFixtures(db);
    });

    testWidgets(
      'renders full identity in fixed hierarchy without pronunciation or overflow',
      (tester) async {
        await _pumpGraph(tester, centerWordId: _fullWordId);

        expect(_centerTextValues(tester, _fullWordId), [
          '헬라어 · G42',
          'φέρω',
          '페로',
          '나르다\u2009·\u2009옮기다',
        ]);
        expect(
          find.descendant(
            of: _centerFinder(_fullWordId),
            matching: find.text(_pronunciation),
          ),
          findsNothing,
        );

        for (final role in [
          'metadata',
          'spelling',
          'transliteration',
          'meaning',
        ]) {
          final text = tester.widget<Text>(_lineFinder(_fullWordId, role));
          expect(text.textAlign, TextAlign.center);
          expect(text.maxLines, 1);
          expect(text.overflow, TextOverflow.ellipsis);
        }

        final spelling = tester.widget<Text>(
          _lineFinder(_fullWordId, 'spelling'),
        );
        final metadata = tester.widget<Text>(
          _lineFinder(_fullWordId, 'metadata'),
        );
        final transliteration = tester.widget<Text>(
          _lineFinder(_fullWordId, 'transliteration'),
        );
        final meaning = tester.widget<Text>(
          _lineFinder(_fullWordId, 'meaning'),
        );
        final strongSpan =
            (metadata.textSpan! as TextSpan).children!.last as TextSpan;
        final labelColumn = tester.widget<Column>(
          _semanticAnchorFinder(_fullWordId),
        );
        expect(strongSpan.text, 'G42');
        expect(strongSpan.style!.fontWeight, FontWeight.w600);
        expect(meaning.style!.fontWeight, FontWeight.w600);
        expect(labelColumn.children.whereType<SizedBox>().last.height, 6);
        expect(
          spelling.style!.fontSize,
          greaterThan(metadata.style!.fontSize!),
        );
        expect(
          spelling.style!.fontSize,
          greaterThan(transliteration.style!.fontSize!),
        );
        expect(spelling.style!.fontSize, greaterThan(meaning.style!.fontSize!));
        expect(
          tester.getSize(_centerFinder(_fullWordId)),
          const Size(180, 180),
        );
        expect(tester.takeException(), isNull);

        await _disposeRuntimeApp(tester);
      },
    );

    testWidgets(
      'composes partial metadata and omits every blank line and gap',
      (tester) async {
        await _pumpGraph(tester, centerWordId: _languageOnlyWordId);
        expect(_centerTextValues(tester, _languageOnlyWordId), ['영어', '-fer']);
        expect(
          tester
              .widget<Column>(_semanticAnchorFinder(_languageOnlyWordId))
              .children
              .whereType<SizedBox>()
              .length,
          1,
        );

        await _disposeRuntimeApp(tester);
        await _pumpGraph(tester, centerWordId: _strongOnlyWordId);
        expect(_centerTextValues(tester, _strongOnlyWordId), [
          'H7',
          'אב',
          '아버지',
        ]);
        expect(_lineFinder(_strongOnlyWordId, 'transliteration'), findsNothing);
        final labelColumn = tester.widget<Column>(
          _semanticAnchorFinder(_strongOnlyWordId),
        );
        expect(labelColumn.children.whereType<SizedBox>().last.height, 4);

        await _disposeRuntimeApp(tester);
        await _pumpGraph(tester, centerWordId: _blankWordId);
        expect(_lineFinder(_blankWordId, 'metadata'), findsNothing);
        expect(_lineFinder(_blankWordId, 'transliteration'), findsNothing);
        expect(_lineFinder(_blankWordId, 'meaning'), findsNothing);
        expect(_centerTextValues(tester, _blankWordId), [_blankWordId]);
        expect(
          tester.widget<Column>(_semanticAnchorFinder(_blankWordId)).children,
          hasLength(1),
        );
        expect(tester.takeException(), isNull);

        await _disposeRuntimeApp(tester);
      },
    );

    testWidgets(
      'keeps center identity fixed while peripheral LOD follows raw scale',
      (tester) async {
        await _pumpGraph(tester, centerWordId: _fullWordId);
        const expectedCenterLines = [
          '헬라어 · G42',
          'φέρω',
          '페로',
          '나르다\u2009·\u2009옮기다',
        ];

        expect(_centerTextValues(tester, _fullWordId), expectedCenterLines);
        _expectPeripheralLod(_languageOnlyWordId, PeripheralNodeLodLevel.lod1);

        await _setCameraScale(tester, 1.20);
        expect(_centerTextValues(tester, _fullWordId), expectedCenterLines);
        _expectPeripheralLod(_languageOnlyWordId, PeripheralNodeLodLevel.lod2);

        await _setCameraScale(tester, 1.85);
        expect(_centerTextValues(tester, _fullWordId), expectedCenterLines);
        _expectPeripheralLod(_languageOnlyWordId, PeripheralNodeLodLevel.lod3);

        await _setCameraScale(tester, 3.2);
        expect(_centerTextValues(tester, _fullWordId), expectedCenterLines);
        _expectPeripheralLod(_languageOnlyWordId, PeripheralNodeLodLevel.lod3);
        expect(tester.takeException(), isNull);

        await _disposeRuntimeApp(tester);
      },
    );

    testWidgets('center tap preserves selection contract', (tester) async {
      String? selectedWordId;
      await _pumpGraph(
        tester,
        centerWordId: _fullWordId,
        surfaceSize: const Size(800, 900),
        onSelectWordId: (wordId) => selectedWordId = wordId,
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump();

      _centerGestureDetector(_fullWordId).onTap!();
      await tester.pump();
      expect(selectedWordId, _fullWordId);

      await _disposeRuntimeApp(tester);
    });
  });
}

Finder _centerFinder(String wordId) {
  return find.byKey(ValueKey<String>('graph-center-node:$wordId'));
}

GestureDetector _centerGestureDetector(String wordId) {
  GestureDetector? result;
  _centerFinder(wordId).evaluate().single.visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is GestureDetector) {
      result = widget;
      return false;
    }
    return true;
  });
  return result!;
}

Finder _semanticAnchorFinder(String wordId) {
  return find.byKey(
    ValueKey<String>('graph-center-node-semantic-anchor:$wordId'),
  );
}

Finder _lineFinder(String wordId, String role) {
  return find.byKey(ValueKey<String>('graph-center-node-line:$wordId:$role'));
}

List<String> _centerTextValues(WidgetTester tester, String wordId) {
  return find
      .descendant(
        of: _semanticAnchorFinder(wordId),
        matching: find.byType(Text),
      )
      .evaluate()
      .map((element) {
        final text = element.widget as Text;
        return text.data ?? text.textSpan!.toPlainText();
      })
      .toList(growable: false);
}

void _expectPeripheralLod(String wordId, PeripheralNodeLodLevel lod) {
  expect(
    find.byKey(
      ValueKey<String>('graph-peripheral-node-lod:$wordId:${lod.name}'),
    ),
    findsOneWidget,
  );
}

Future<void> _pumpGraph(
  WidgetTester tester, {
  required String centerWordId,
  Size surfaceSize = const Size(1200, 900),
  ValueChanged<String>? onSelectWordId,
}) async {
  _setSurfaceSize(tester, surfaceSize);
  await tester.pumpWidget(
    MaterialApp(
      home: WordGraphScreen(
        centerWordId: centerWordId,
        onSelectWordId: onSelectWordId,
      ),
    ),
  );

  await _pumpUntil(
    tester,
    () =>
        find.byType(CircularProgressIndicator).evaluate().isEmpty &&
        _centerFinder(centerWordId).evaluate().length == 1,
    reason: 'controlled center node must render.',
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
    'reshet_phase25f_',
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

Future<void> _insertPhase25FFixtures(dynamic db) async {
  await _insertWord(
    db,
    id: _fullWordId,
    language: '  헬라어  ',
    strongNumber: 'g00042',
    spelling: 'φέρω',
    transliteration: '페로',
    pronunciation: _pronunciation,
    meaning: '나르다·옮기다',
  );
  await _insertWord(
    db,
    id: _languageOnlyWordId,
    language: '  영어  ',
    spelling: '-fer',
    transliteration: '',
    meaning: '',
  );
  await _insertWord(
    db,
    id: _strongOnlyWordId,
    language: '   ',
    strongNumber: 'h00007',
    spelling: 'אב',
    transliteration: '',
    meaning: '아버지',
  );
  await _insertWord(
    db,
    id: _blankWordId,
    language: '   ',
    spelling: '   ',
    transliteration: '   ',
    meaning: '   ',
  );

  await _insertRelation(db, wordId1: _fullWordId, wordId2: _languageOnlyWordId);
  await _insertRelation(db, wordId1: _fullWordId, wordId2: _strongOnlyWordId);
  await _insertRelation(db, wordId1: _fullWordId, wordId2: _blankWordId);
}

Future<void> _insertWord(
  dynamic db, {
  required String id,
  required String language,
  String? strongNumber,
  required String spelling,
  required String transliteration,
  String pronunciation = '',
  required String meaning,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '언어': language,
    '스트롱넘버': strongNumber,
  });
  if (spelling.trim().isNotEmpty) {
    await db.insert('word_expression_set', {
      'word_id': id,
      'seq': 1,
      'is_representative': 1,
      'spelling': spelling,
      'transliteration': transliteration.trim().isEmpty
          ? null
          : transliteration,
      'pronunciation': pronunciation.trim().isEmpty ? null : pronunciation,
    });
  }
  if (meaning.trim().isNotEmpty) {
    await db.insert('word_meaning_set', {
      'word_id': id,
      'seq': 1,
      'meaning': meaning,
    });
  }
}

Future<void> _insertRelation(
  dynamic db, {
  required String wordId1,
  required String wordId2,
}) async {
  final orderedWordIds = [wordId1, wordId2]..sort();
  await db.insert('WORD_RELATION', {
    'word_id_1': orderedWordIds.first,
    'word_id_2': orderedWordIds.last,
    'direction_code': 'unknown',
    'updated_at': DateTime.now().toIso8601String(),
  });
}
