import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_restore_service.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory isolatedRoot;
  late _FakeRestoreRunner restoreRunner;
  final sourceWorkDatabase = File(
    p.join(Directory.current.path, 'data', 'reshet_work.db'),
  );

  setUpAll(() async {
    expect(sourceWorkDatabase.existsSync(), isTrue);
    await DatabaseService.closeDatabase();
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    isolatedRoot = await Directory.systemTemp.createTemp(
      'reshet_phase48b3_home_',
    );
    final dataDirectory = Directory(p.join(isolatedRoot.path, 'data'));
    await dataDirectory.create(recursive: true);
    await sourceWorkDatabase.copy(p.join(dataDirectory.path, 'reshet_work.db'));
    await sourceWorkDatabase.copy(p.join(dataDirectory.path, 'reshet_seed.db'));
    DatabaseService.setDataRootOverrideForTest(dataDirectory.path);
    SharedPreferences.setMockInitialValues({
      'first_run_brand_intro_seen': true,
    });
    restoreRunner = _FakeRestoreRunner();
  });

  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    await _deleteWithRetry(isolatedRoot);
  });

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          restoreService: restoreRunner,
          providedDataService: restoreRunner,
        ),
      ),
    );
    await _pumpUntil(
      tester,
      () => find.byType(TextField).evaluate().isNotEmpty,
    );
  }

  Future<void> openRestoreConfirmation(WidgetTester tester) async {
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('데이터 복원'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('제공 데이터 유지 선택과 필수 백업 안내를 표시한다', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('제공 데이터로 전체 교체'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('합쳐지지 않습니다'), findsOneWidget);
    expect(find.textContaining('저장을 취소하거나 실패하면 교체하지 않습니다'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '내 데이터 유지'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(restoreRunner.didStartDatabaseRestore, isFalse);
  });

  testWidgets('제공 데이터 교체 성공 후 검색 상태와 백업 복원 안내를 갱신한다', (tester) async {
    restoreRunner.handler = () async => const RestoreSucceeded();
    await pumpHome(tester);
    await tester.enterText(find.byType(TextField).first, '교체 전 검색');
    await tester.pump();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('제공 데이터로 전체 교체'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(FilledButton, '전체 교체'));
    await _pumpUntil(
      tester,
      () => find.textContaining('제공 데이터로 교체했습니다').evaluate().isNotEmpty,
    );
    expect(restoreRunner.didStartDatabaseRestore, isTrue);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('복원 메뉴와 교체·rollback·비암호화 안내를 표시한다', (tester) async {
    await pumpHome(tester);

    await openRestoreConfirmation(tester);

    expect(find.textContaining('현재 데이터가 교체됩니다'), findsOneWidget);
    expect(find.textContaining('rollback snapshot'), findsOneWidget);
    expect(find.textContaining('암호화되지 않았을 수 있고'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(restoreRunner.didStartDatabaseRestore, isFalse);
    expect(
      find.byKey(const Key('database-restore-progress-indicator')),
      findsNothing,
    );
  });

  testWidgets('복원 진행 중 body와 action을 차단하고 중복 실행을 막는다', (tester) async {
    final completer = Completer<RestoreResult>();
    restoreRunner.handler = () => completer.future;
    await pumpHome(tester);

    await openRestoreConfirmation(tester);
    await tester.tap(find.widgetWithText(FilledButton, '복원'));
    await tester.pump();

    expect(restoreRunner.didStartDatabaseRestore, isTrue);
    expect(
      find.byKey(const Key('database-restore-progress-indicator')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>))
          .enabled,
      isFalse,
    );

    completer.complete(const RestoreCancelled());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const Key('database-restore-progress-indicator')),
      findsNothing,
    );
    expect(find.textContaining('복원에 실패'), findsNothing);
  });

  testWidgets('성공 후 검색과 Home 목록 상태를 초기화한 뒤 안내한다', (tester) async {
    restoreRunner.handler = () async => const RestoreSucceeded();
    await pumpHome(tester);
    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, '복원 전 검색');
    await tester.pump();

    await openRestoreConfirmation(tester);
    await tester.tap(find.widgetWithText(FilledButton, '복원'));
    await _pumpUntil(
      tester,
      () => find.text('데이터 복원이 완료되었습니다.').evaluate().isNotEmpty,
    );
    await _pumpUntil(
      tester,
      () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
    );

    expect(tester.widget<TextField>(searchField).controller?.text, isEmpty);
    expect(find.text('데이터 복원이 완료되었습니다.'), findsOneWidget);
  });

  testWidgets('거절과 rollback 실패 안내를 구분한다', (tester) async {
    restoreRunner.handler = () async =>
        const RestoreRejected(RestoreRejectionReason.schemaIncompatible);
    await pumpHome(tester);

    await openRestoreConfirmation(tester);
    await tester.tap(find.widgetWithText(FilledButton, '복원'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('복원 schema와 호환되지 않는'), findsOneWidget);

    restoreRunner.handler = () async => RestoreFailed(
      stage: RestoreFailureStage.originalReopen,
      rollbackStatus: RestoreRollbackStatus.failed,
      error: StateError('rollback failed'),
      stackTrace: StackTrace.current,
    );
    await openRestoreConfirmation(tester);
    await tester.tap(find.widgetWithText(FilledButton, '복원'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('원본 복구에 실패했습니다'), findsOneWidget);
  });

  test('복원 성공 시 generation을 증가시켜 Explorer key를 교체한다', () {
    final source = File(
      p.join(Directory.current.path, 'lib', 'ui', 'home_screen.dart'),
    ).readAsStringSync();

    expect(source, contains('_restoreGeneration++;'));
    expect(
      source,
      matches(
        RegExp(r"'\$_restoreGeneration:'\s*'\$_largeScreenExplorerWordId'"),
      ),
    );
  });
}

class _FakeRestoreRunner
    implements DatabaseRestoreRunner, ProvidedDatabaseReplaceRunner {
  Future<RestoreResult> Function() handler = () async =>
      const RestoreCancelled();
  bool didStartDatabaseRestore = false;
  @override
  Future<RestoreResult> replaceWithBundledSeed({
    required Future<bool> Function() confirmation,
  }) => restore(confirmation: confirmation);

  @override
  Future<RestoreResult> restore({
    required Future<bool> Function() confirmation,
  }) async {
    final confirmed = await confirmation();
    if (!confirmed) return const RestoreCancelled();
    didStartDatabaseRestore = true;
    return handler();
  }
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 120; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  fail('Home 화면 준비가 제한 시간 안에 완료되지 않았습니다.');
}

Future<void> _deleteWithRetry(Directory directory) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    try {
      await directory.delete(recursive: true);
      return;
    } on FileSystemException {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
  await directory.delete(recursive: true);
}
