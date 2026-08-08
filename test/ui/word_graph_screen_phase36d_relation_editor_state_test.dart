import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/ui/word_graph_cache.dart';
import 'package:reshet_app/ui/word_graph_screen.dart';

import '../support/database_test_isolation_guard.dart';

const _centerWordId = 'T936D_CENTER';
const _editTargetWordId = 'T936D_EDIT_TARGET';
const _addTargetWordId = 'T936D_ADD_TARGET';

const _centerSpelling = 'Phase36D Center';
const _editTargetSpelling = 'Phase36D Edit Target';
const _addTargetSpelling = 'Phase36D Add Target';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String repoRootPath;
  late String sourceWorkDbPath;
  late String sourceSeedDbPath;
  Directory? isolatedRoot;
  late String semanticCategoryLabel;
  late String lexicalCategoryLabel;
  late String similarTypeLabel;
  late String synonymTypeLabel;
  late String assertedStatusLabel;
  late String hypothesizedStatusLabel;
  late String inferredStatusLabel;
  late String assertedStatusDescription;
  late String hypothesizedStatusDescription;
  late String inferredStatusDescription;
  late List<String> allStatusLabels;

  setUpAll(() async {
    repoRootPath = Directory.current.path;
    sourceWorkDbPath = p.join(repoRootPath, 'data', 'reshet_work.db');
    sourceSeedDbPath = p.join(repoRootPath, 'data', 'reshet_seed.db');

    expect(File(sourceWorkDbPath).existsSync(), isTrue);
    expect(File(sourceSeedDbPath).existsSync(), isTrue);
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    WordGraphDataCache.clear();
    isolatedRoot = await _createIsolatedWorkspace(sourceSeedDbPath);
    final isolatedDataRootPath = p.join(isolatedRoot!.path, 'data');
    ensureSystemTempDatabaseTargets(
      dataRootPath: isolatedDataRootPath,
      actualWorkDbPath: sourceWorkDbPath,
      actualSeedDbPath: sourceSeedDbPath,
    );
    DatabaseService.setDataRootOverrideForTest(isolatedDataRootPath);

    final db = await DatabaseService.openDatabaseFile();
    semanticCategoryLabel = await _lookupLabel(
      db,
      table: 'RELATION_CATEGORY',
      code: 'semantic',
    );
    lexicalCategoryLabel = await _lookupLabel(
      db,
      table: 'RELATION_CATEGORY',
      code: 'lexical',
    );
    similarTypeLabel = await _lookupLabel(
      db,
      table: 'RELATION_TYPE',
      code: 'similar',
    );
    synonymTypeLabel = await _lookupLabel(
      db,
      table: 'RELATION_TYPE',
      code: 'synonym',
    );
    assertedStatusLabel = await _lookupLabel(
      db,
      table: 'RELATION_STATUS',
      code: 'asserted',
    );
    hypothesizedStatusLabel = await _lookupLabel(
      db,
      table: 'RELATION_STATUS',
      code: 'hypothesized',
    );
    inferredStatusLabel = await _lookupLabel(
      db,
      table: 'RELATION_STATUS',
      code: 'inferred',
    );
    assertedStatusDescription = await _lookupDescription(
      db,
      table: 'RELATION_STATUS',
      code: 'asserted',
    );
    hypothesizedStatusDescription = await _lookupDescription(
      db,
      table: 'RELATION_STATUS',
      code: 'hypothesized',
    );
    inferredStatusDescription = await _lookupDescription(
      db,
      table: 'RELATION_STATUS',
      code: 'inferred',
    );
    allStatusLabels = await _lookupLabelsInOrder(db, table: 'RELATION_STATUS');
    await _insertWord(
      db,
      id: _centerWordId,
      spelling: _centerSpelling,
      transliteration: 'phase36d-center',
      meaning: 'Phase 36D center meaning',
    );
    await _insertWord(
      db,
      id: _editTargetWordId,
      spelling: _editTargetSpelling,
      transliteration: 'phase36d-edit-target',
      meaning: 'Phase 36D edit target meaning',
    );
    await _insertWord(
      db,
      id: _addTargetWordId,
      spelling: _addTargetSpelling,
      transliteration: 'phase36d-add-target',
      meaning: 'Phase 36D add target meaning',
    );
    await DatabaseService.closeDatabase();
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    WordGraphDataCache.clear();
    DatabaseService.setDataRootOverrideForTest(null);

    if (isolatedRoot != null && isolatedRoot!.existsSync()) {
      await _deleteIsolatedWorkspace(isolatedRoot!);
    }
  });

  group('Phase 36-D relation editor state', () {
    group('edit dialog', () {
      setUp(() async {
        final db = await DatabaseService.openDatabaseFile();
        await _insertRelation(
          db,
          wordId1: _centerWordId,
          wordId2: _editTargetWordId,
          categoryCode: 'semantic',
          relationType: 'similar',
        );
      });

      testWidgets(
        'clears an invalid type after category change and reopens saved values',
        (tester) async {
          await _pumpGraph(tester);
          await _openFirstEdgeDetailDialog(tester);
          await tester.tap(find.byKey(const Key('relation-edit-mode-button')));
          await _pumpUntil(
            tester,
            () => _dropdownByPrefix(
              'relation-edit-category:',
            ).evaluate().isNotEmpty,
            reason: 'edit dropdowns must appear after lookup options load.',
          );

          await _selectDropdownOption(
            tester,
            keyPrefix: 'relation-edit-category:',
            optionLabel: lexicalCategoryLabel,
          );

          expect(find.text(similarTypeLabel), findsNothing);
          await _openDropdown(tester, keyPrefix: 'relation-edit-type:');
          expect(find.text(synonymTypeLabel), findsOneWidget);
          expect(find.text(similarTypeLabel), findsNothing);
          await _tapDropdownOption(tester, synonymTypeLabel);

          await tester.tap(find.byKey(const Key('relation-edit-save-button')));
          await _pumpUntil(
            tester,
            () => find.byType(AlertDialog).evaluate().isEmpty,
            reason: 'edit dialog must close after saving the relation.',
          );
          await _openFirstEdgeDetailDialog(tester);
          expect(find.text(lexicalCategoryLabel), findsOneWidget);
          expect(find.text(synonymTypeLabel), findsOneWidget);
          expect(find.text('관계 상태: $inferredStatusLabel'), findsOneWidget);

          await _disposeRuntimeApp(tester);
        },
      );

      testWidgets('상태 표시·선택 유지·취소·status-only 저장을 지원한다', (tester) async {
        await _pumpGraph(tester);
        await _openFirstEdgeDetailDialog(tester);

        expect(find.text('관계 상태: $inferredStatusLabel'), findsOneWidget);
        expect(find.text(inferredStatusDescription), findsOneWidget);

        await tester.tap(find.byKey(const Key('relation-edit-mode-button')));
        await _pumpUntil(
          tester,
          () => _dropdownByPrefix(
            'relation-edit-status:inferred',
          ).evaluate().isNotEmpty,
          reason: '편집 진입 시 inferred 상태 선택이 유지되어야 합니다.',
        );

        await _openDropdown(tester, keyPrefix: 'relation-edit-status:');
        for (final statusLabel in allStatusLabels) {
          expect(find.text(statusLabel), findsWidgets);
        }
        await _tapDropdownOption(tester, assertedStatusLabel);
        expect(find.text(assertedStatusDescription), findsOneWidget);
        expect(
          tester
              .widget<ElevatedButton>(
                find.byKey(const Key('relation-edit-save-button')),
              )
              .onPressed,
          isNotNull,
        );

        await tester.tap(find.widgetWithText(TextButton, '취소'));
        await tester.pump();
        expect(find.text('관계 상태: $inferredStatusLabel'), findsOneWidget);
        expect(find.text(inferredStatusDescription), findsOneWidget);

        await tester.tap(find.byKey(const Key('relation-edit-mode-button')));
        await _pumpUntil(
          tester,
          () => _dropdownByPrefix(
            'relation-edit-status:inferred',
          ).evaluate().isNotEmpty,
          reason: '취소 후 편집 재진입 시 inferred 상태가 복원되어야 합니다.',
        );
        await _selectDropdownOption(
          tester,
          keyPrefix: 'relation-edit-status:',
          optionLabel: assertedStatusLabel,
        );
        await tester.tap(find.byKey(const Key('relation-edit-save-button')));
        await _pumpUntil(
          tester,
          () => find.byType(AlertDialog).evaluate().isEmpty,
          reason: '상태만 변경한 저장 후 상세 다이얼로그가 닫혀야 합니다.',
        );

        await _openFirstEdgeDetailDialog(tester);
        expect(find.text('관계 상태: $assertedStatusLabel'), findsOneWidget);
        expect(find.text(assertedStatusDescription), findsOneWidget);
        expect(tester.takeException(), isNull);

        await _disposeRuntimeApp(tester);
      });
    });

    testWidgets('관계 목록 항목에서 각 관계 상태를 식별 가능하게 표시한다', (tester) async {
      _setSurfaceSize(tester, const Size(320, 160));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  relationListStatusTextForTesting(
                    _relationInfoForStatus(
                      relationId: 93601,
                      statusCode: 'inferred',
                      statusLabel: inferredStatusLabel,
                    ),
                  ),
                  relationListStatusTextForTesting(
                    _relationInfoForStatus(
                      relationId: 93602,
                      statusCode: 'asserted',
                      statusLabel: assertedStatusLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('상태: $inferredStatusLabel'), findsOneWidget);
      expect(find.text('상태: $assertedStatusLabel'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeRuntimeApp(tester);
    });

    testWidgets(
      'add dialog keeps visible type selection aligned with the saved payload',
      (tester) async {
        await _pumpGraph(tester, selectedWordId: _centerWordId);

        await tester.tap(find.byIcon(Icons.add_link));
        await _pumpUntil(
          tester,
          () => find.byType(AlertDialog).evaluate().length == 1,
          reason: 'relation add search dialog must open.',
        );
        await tester.enterText(
          find.byType(TextField).first,
          _addTargetSpelling,
        );
        await _pumpUntil(
          tester,
          () => _searchResultTile(_addTargetSpelling).evaluate().isNotEmpty,
          reason: 'relation add search must show the target word.',
        );
        await tester.tap(_searchResultTile(_addTargetSpelling));
        await _pumpUntil(
          tester,
          () =>
              _dropdownByPrefix('relation-add-category:').evaluate().isNotEmpty,
          reason: 'relation add editor dialog must open.',
        );

        expect(
          _dropdownByPrefix('relation-add-status:asserted'),
          findsOneWidget,
        );
        expect(find.text(assertedStatusLabel), findsOneWidget);
        expect(find.text(assertedStatusDescription), findsOneWidget);
        await _openDropdown(tester, keyPrefix: 'relation-add-status:');
        expect(find.text(inferredStatusLabel), findsNothing);
        for (final statusLabel in allStatusLabels.where(
          (label) => label != inferredStatusLabel,
        )) {
          expect(find.text(statusLabel), findsWidgets);
        }
        await _tapDropdownOption(tester, hypothesizedStatusLabel);
        expect(find.text(hypothesizedStatusDescription), findsOneWidget);

        await _selectDropdownOption(
          tester,
          keyPrefix: 'relation-add-category:',
          optionLabel: semanticCategoryLabel,
        );
        await _selectDropdownOption(
          tester,
          keyPrefix: 'relation-add-type:',
          optionLabel: similarTypeLabel,
        );
        expect(find.text(similarTypeLabel), findsWidgets);

        await _selectDropdownOption(
          tester,
          keyPrefix: 'relation-add-category:',
          optionLabel: lexicalCategoryLabel,
        );

        expect(find.text(similarTypeLabel), findsNothing);
        await _selectDropdownOption(
          tester,
          keyPrefix: 'relation-add-type:',
          optionLabel: synonymTypeLabel,
        );
        expect(find.text(synonymTypeLabel), findsWidgets);
        expect(
          tester
              .widget<ElevatedButton>(
                find.byKey(const Key('relation-add-save-button')),
              )
              .onPressed,
          isNotNull,
        );

        await tester.tap(find.widgetWithText(TextButton, '취소'));
        await _pumpUntil(
          tester,
          () => find.byType(AlertDialog).evaluate().isEmpty,
          reason: 'relation add dialog must close after cancellation.',
        );
        expect(tester.takeException(), isNull);

        await _disposeRuntimeApp(tester);
      },
    );
  });
}

WordRelationEdgeInfo _relationInfoForStatus({
  required int relationId,
  required String statusCode,
  required String statusLabel,
}) {
  return WordRelationEdgeInfo(
    relationId: relationId,
    wordId1: _centerWordId,
    wordId2: _editTargetWordId,
    otherWordId: _editTargetWordId,
    directionCode: 'unknown',
    centerRelativeDirection: 'unknown',
    statusCode: statusCode,
    statusLabel: statusLabel,
  );
}

Finder _dropdownByPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  });
}

Finder _edgeChipFinder() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith('graph-edge-chip:');
  });
}

Finder _searchResultTile(String label) {
  return find.ancestor(of: find.text(label), matching: find.byType(ListTile));
}

Future<void> _openDropdown(
  WidgetTester tester, {
  required String keyPrefix,
}) async {
  await tester.tap(_dropdownByPrefix(keyPrefix));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tapDropdownOption(WidgetTester tester, String optionLabel) async {
  await tester.tap(find.text(optionLabel).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _selectDropdownOption(
  WidgetTester tester, {
  required String keyPrefix,
  required String optionLabel,
}) async {
  await _openDropdown(tester, keyPrefix: keyPrefix);
  await _tapDropdownOption(tester, optionLabel);
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
    () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
    reason: 'graph bootstrap reads must finish before relation actions.',
  );
}

Future<void> _openFirstEdgeDetailDialog(WidgetTester tester) async {
  await _setCameraScale(tester, 1.2);
  await _pumpUntil(
    tester,
    () => _edgeChipFinder().evaluate().isNotEmpty,
    reason: 'relation edge chip must render before opening relation details.',
  );

  await tester.tap(_edgeChipFinder().first, warnIfMissed: false);
  await _pumpUntil(
    tester,
    () => find.byType(AlertDialog).evaluate().length == 1,
    reason: 'edge chip tap must open the relation detail dialog.',
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

Future<String> _lookupLabel(
  dynamic db, {
  required String table,
  required String code,
}) async {
  final rows = await db.query(
    table,
    columns: ['label'],
    where: 'code = ?',
    whereArgs: [code],
    limit: 1,
  );
  expect(rows, hasLength(1));
  final label = ((rows.single['label'] as String?) ?? '').trim();
  return label.isEmpty ? code : label;
}

Future<String> _lookupDescription(
  dynamic db, {
  required String table,
  required String code,
}) async {
  final rows = await db.query(
    table,
    columns: ['description'],
    where: 'code = ?',
    whereArgs: [code],
    limit: 1,
  );
  expect(rows, hasLength(1));
  return ((rows.single['description'] as String?) ?? '').trim();
}

Future<List<String>> _lookupLabelsInOrder(
  dynamic db, {
  required String table,
}) async {
  final rows = List<Map<String, Object?>>.from(
    await db.query(
      table,
      columns: ['code', 'label'],
      orderBy: 'sort_order ASC, label ASC, code ASC',
    ),
  );
  return rows
      .map<String>((row) {
        final code = ((row['code'] as String?) ?? '').trim();
        final label = ((row['label'] as String?) ?? '').trim();
        return label.isEmpty ? code : label;
      })
      .toList(growable: false);
}

Future<Directory> _createIsolatedWorkspace(String sourceSeedDbPath) async {
  final isolatedRoot = await Directory.systemTemp.createTemp(
    'reshet_phase36d_relation_editor_',
  );
  final isolatedDataDir = Directory(p.join(isolatedRoot.path, 'data'));
  await isolatedDataDir.create(recursive: true);
  await File(
    sourceSeedDbPath,
  ).copy(p.join(isolatedDataDir.path, 'reshet_seed.db'));
  await File(
    sourceSeedDbPath,
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
  required String transliteration,
  required String meaning,
}) async {
  await db.insert('WORD_TABLE', {
    'id': id,
    '\uC5B8\uC5B4': 'Phase 36D Language',
    '\uC2A4\uD2B8\uB871\uB118\uBC84': '',
  });
  await db.insert('word_expression_set', {
    'word_id': id,
    'seq': 1,
    'is_representative': 1,
    'spelling': spelling,
    'transliteration': transliteration,
  });
  await db.insert('word_meaning_set', {
    'word_id': id,
    'seq': 1,
    'meaning': meaning,
  });
}

Future<int> _insertRelation(
  dynamic db, {
  required String wordId1,
  required String wordId2,
  required String categoryCode,
  required String relationType,
  String statusCode = 'inferred',
  String directionCode = 'unknown',
}) async {
  return await db.insert('WORD_RELATION', {
    'word_id_1': wordId1,
    'word_id_2': wordId2,
    'category_code': categoryCode,
    'relation_type': relationType,
    'status_code': statusCode,
    'direction_code': directionCode,
    'updated_at': DateTime.now().toIso8601String(),
  });
}
