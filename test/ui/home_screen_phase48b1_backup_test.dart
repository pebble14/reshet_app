import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_backup_service.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory isolatedRoot;
  late _FakeBackupRunner backupRunner;
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
      'reshet_phase48b1_home_',
    );
    final dataDirectory = Directory(p.join(isolatedRoot.path, 'data'));
    await dataDirectory.create(recursive: true);
    await sourceWorkDatabase.copy(p.join(dataDirectory.path, 'reshet_work.db'));
    await sourceWorkDatabase.copy(p.join(dataDirectory.path, 'reshet_seed.db'));
    DatabaseService.setDataRootOverrideForTest(dataDirectory.path);
    SharedPreferences.setMockInitialValues({
      'first_run_brand_intro_seen': true,
    });
    backupRunner = _FakeBackupRunner();
  });

  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    await _deleteWithRetry(isolatedRoot);
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(backupService: backupRunner)),
    );
    await _pumpUntil(
      tester,
      () => find.byType(TextField).evaluate().isNotEmpty,
    );
  }

  Future<void> openBackupConfirmation(WidgetTester tester) async {
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('데이터 백업'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('백업 메뉴와 비암호화 안내를 표시하고 확인 취소 시 service를 실행하지 않는다', (tester) async {
    await pumpHome(tester);

    await openBackupConfirmation(tester);

    expect(find.textContaining('암호화되지 않습니다'), findsOneWidget);
    expect(find.textContaining('단어, 관계, 메모와 변경 이력'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(backupRunner.callCount, 0);
    expect(find.textContaining('백업에 실패'), findsNothing);
  });

  testWidgets('실행 중 진행 상태와 action guard를 표시하고 cancelled 완료 후 정상 해제한다', (
    tester,
  ) async {
    final completer = Completer<BackupResult>();
    backupRunner.handler = () => completer.future;
    await pumpHome(tester);

    await openBackupConfirmation(tester);
    await tester.tap(find.widgetWithText(FilledButton, '백업'));
    await tester.pump();

    expect(backupRunner.callCount, 1);
    expect(
      find.byKey(const Key('database-backup-progress-indicator')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>))
          .enabled,
      isFalse,
    );

    completer.complete(const BackupCancelled());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const Key('database-backup-progress-indicator')),
      findsNothing,
    );
    expect(
      tester
          .widget<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>))
          .enabled,
      isTrue,
    );
    expect(find.textContaining('백업에 실패'), findsNothing);
  });

  testWidgets('성공과 실패 snackbar를 구분하고 각 완료 후 guard를 해제한다', (tester) async {
    backupRunner.handler = () async => const BackupSucceeded();
    await pumpHome(tester);

    await openBackupConfirmation(tester);
    await tester.tap(find.widgetWithText(FilledButton, '백업'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('데이터 백업이 완료되었습니다.'), findsOneWidget);
    expect(
      tester
          .widget<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>))
          .enabled,
      isTrue,
    );

    backupRunner.handler = () async => BackupFailed(
      stage: BackupFailureStage.snapshotCreation,
      error: StateError('test failure'),
      stackTrace: StackTrace.current,
    );
    await openBackupConfirmation(tester);
    await tester.tap(find.widgetWithText(FilledButton, '백업'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('데이터 백업에 실패했습니다. 잠시 후 다시 시도하세요.'), findsOneWidget);
    expect(
      tester
          .widget<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>))
          .enabled,
      isTrue,
    );
  });
}

class _FakeBackupRunner implements DatabaseBackupRunner {
  Future<BackupResult> Function() handler = () async => const BackupCancelled();
  int callCount = 0;

  @override
  Future<BackupResult> createBackup() {
    callCount += 1;
    return handler();
  }
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 120; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) {
      return;
    }
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
