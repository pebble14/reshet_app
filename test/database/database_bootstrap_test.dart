import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_bootstrap.dart';
import 'package:reshet_app/database/database_seed_asset_loader.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late String workPath;

  setUp(() async {
    await DatabaseService.initialize();
    root = await Directory.systemTemp.createTemp('reshet_bootstrap_test_');
    workPath = p.join(root.path, 'user_data', 'reshet_work.db');
  });
  tearDown(() async {
    await DatabaseService.closeDatabase();
    await root.delete(recursive: true);
  });

  Future<void> writeFixture(File file) async {
    final db = await databaseFactory.openDatabase(file.path);
    try {
      await db.execute('CREATE TABLE research(value TEXT)');
      await db.insert('research', {'value': '사용자 연구'});
    } finally {
      await db.close();
    }
  }

  Future<void> checkNoStaging() async {
    final files = await Directory(p.dirname(workPath)).list().toList();
    expect(files.whereType<Directory>(), isEmpty);
  }

  test('bundled seed를 검증하여 최초 work를 만들고 실제 runtime으로 연다', () async {
    await DatabaseBootstrap.createIfMissing(
      workPath: workPath,
      writeSeed: (file) async {
        await file.writeAsBytes(
          await loadBundledDatabaseAsset('data/reshet_seed.db'),
          flush: true,
        );
      },
      prepareDatabase: DatabaseService.ensureRuntimeSchema,
    );
    await DatabaseService.withIsolatedDataRoot(
      dataRootPath: p.dirname(workPath),
      action: () async {
        final db = await DatabaseService.openDatabaseFile();
        expect(
          (await db.rawQuery('PRAGMA integrity_check')).single.values.single,
          'ok',
        );
        expect(
          (await db.rawQuery(
            'SELECT COUNT(*) AS n FROM word_expression_set',
          )).single['n'],
          greaterThan(0),
        );
        expect(
          (await db.rawQuery(
            'PRAGMA table_info(WORD_TABLE)',
          )).map((r) => r['name']),
          isNot(contains('표기1')),
        );
      },
    );
    await checkNoStaging();
  });

  test('기존 work가 있으면 seed와 migration 콜백을 실행하지 않는다', () async {
    await File(workPath).parent.create(recursive: true);
    await writeFixture(File(workPath));
    final before = await File(workPath).readAsBytes();
    await DatabaseBootstrap.createIfMissing(
      workPath: workPath,
      writeSeed: (_) async => fail('기존 DB에 seed를 적용하면 안 됩니다'),
      prepareDatabase: (_) async => fail('bootstrap은 기존 DB를 변경하면 안 됩니다'),
    );
    expect(await File(workPath).readAsBytes(), before);
  });

  test('손상된 seed는 work로 남지 않고 수정된 seed로 재시도할 수 있다', () async {
    await expectLater(
      DatabaseBootstrap.createIfMissing(
        workPath: workPath,
        writeSeed: (file) async {
          await file.writeAsString('손상된 SQLite 파일');
        },
        prepareDatabase: (_) async => fail('손상된 파일에서 migration을 실행하면 안 됩니다'),
      ),
      throwsA(isA<DatabaseException>()),
    );
    expect(await File(workPath).exists(), isFalse);
    await checkNoStaging();
    await DatabaseBootstrap.createIfMissing(
      workPath: workPath,
      writeSeed: writeFixture,
      prepareDatabase: (_) async {},
    );
    expect(await File(workPath).exists(), isTrue);
  });

  test('seed 복사 중 실패해도 부분 work를 남기지 않는다', () async {
    await expectLater(
      DatabaseBootstrap.createIfMissing(
        workPath: workPath,
        writeSeed: (file) async {
          await file.writeAsString('일부 바이트');
          throw StateError('복사 실패 주입');
        },
        prepareDatabase: (_) async {},
      ),
      throwsStateError,
    );
    expect(await File(workPath).exists(), isFalse);
    await checkNoStaging();
  });

  test('migration 도중 실패하면 임시 DB 변경도 폐기한다', () async {
    await expectLater(
      DatabaseBootstrap.createIfMissing(
        workPath: workPath,
        writeSeed: writeFixture,
        prepareDatabase: (db) async {
          await db.execute('DELETE FROM research');
          throw StateError('migration 실패 주입');
        },
      ),
      throwsStateError,
    );
    expect(await File(workPath).exists(), isFalse);
    await checkNoStaging();
  });

  test('WAL의 준비 변경도 최종 단일 DB에 보존한다', () async {
    await DatabaseBootstrap.createIfMissing(
      workPath: workPath,
      writeSeed: writeFixture,
      prepareDatabase: (db) async {
        await db.rawQuery('PRAGMA journal_mode=WAL');
        await db.insert('research', {'value': '준비 중 추가'});
      },
    );
    final db = await databaseFactory.openDatabase(workPath);
    try {
      expect(await db.query('research'), [
        {'value': '사용자 연구'},
        {'value': '준비 중 추가'},
      ]);
    } finally {
      await db.close();
    }
    await checkNoStaging();
  });

  test('초기화 중 나타난 기존 work를 교체하지 않는다', () async {
    await expectLater(
      DatabaseBootstrap.createIfMissing(
        workPath: workPath,
        writeSeed: writeFixture,
        prepareDatabase: (_) async {
          await File(workPath).writeAsString('보존할 파일');
        },
      ),
      throwsStateError,
    );
    expect(await File(workPath).readAsString(), '보존할 파일');
  });

  test('저장 폴더 생성 실패 시 다른 경로로 우회하지 않는다', () async {
    await File(p.dirname(workPath)).writeAsString('폴더가 아닌 파일');
    await expectLater(
      DatabaseBootstrap.createIfMissing(
        workPath: workPath,
        writeSeed: (_) async => fail('저장 위치 확보 전에 seed를 읽으면 안 됩니다'),
        prepareDatabase: (_) async {},
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(await File(p.dirname(workPath)).readAsString(), '폴더가 아닌 파일');
  });
}
