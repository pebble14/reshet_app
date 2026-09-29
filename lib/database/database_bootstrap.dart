import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 최초 work DB만 생성한다. 원본 seed와 기존 사용자 DB는 변경하지 않는다.
final class DatabaseBootstrap {
  static Future<void> createIfMissing({
    required String workPath,
    required Future<void> Function(File stagedFile) writeSeed,
    required Future<void> Function(Database database) prepareDatabase,
  }) async {
    final workFile = File(workPath);
    if (await workFile.exists()) return;

    final parent = workFile.parent;
    await parent.create(recursive: true);
    // 여러 프로세스가 동시에 최초 실행돼도 서로의 work를 교체하지 않는다.
    // lock 파일은 삭제하지 않아 다른 프로세스가 같은 파일을 잠그게 한다.
    final lock = await File(
      '$workPath.bootstrap.lock',
    ).open(mode: FileMode.append);
    var locked = false;
    Directory? staging;
    try {
      await lock.lock(FileLock.exclusive);
      locked = true;
      if (await workFile.exists()) return;

      staging = await parent.createTemp('.reshet_bootstrap_');
      final stagedFile = File(p.join(staging.path, 'candidate.db'));
      await writeSeed(stagedFile);
      if (!await stagedFile.exists()) {
        throw StateError('초기 DB 사본이 생성되지 않았습니다.');
      }
      final database = await databaseFactory.openDatabase(
        stagedFile.path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await _checkIntegrity(database);
        await prepareDatabase(database);
        await _checkIntegrity(database);
        // 이동하는 DB 파일에 모든 변경을 포함하고 sidecar 의존성을 없앤다.
        await database.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
        await database.rawQuery('PRAGMA journal_mode=DELETE');
      } finally {
        await database.close();
      }
      if (await workFile.exists()) {
        throw StateError('초기화 중 작업 DB가 생성되어 기존 파일을 보존합니다.');
      }
      await stagedFile.rename(workPath);
    } finally {
      try {
        if (staging != null &&
            p.isWithin(p.absolute(parent.path), p.absolute(staging.path))) {
          await staging.delete(recursive: true);
        }
      } finally {
        try {
          if (locked) await lock.unlock();
        } finally {
          await lock.close();
        }
      }
    }
  }

  static Future<void> _checkIntegrity(Database database) async {
    final rows = await database.rawQuery('PRAGMA integrity_check');
    if (rows.length != 1 || rows.single.values.single != 'ok') {
      throw StateError('초기 DB 무결성 검사 실패: $rows');
    }
  }
}
