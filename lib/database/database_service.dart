/*
  database_service.dart

  이 파일은 SQLite 데이터베이스 연결을 담당한다.

  역할:
  1. Windows 환경에서 SQLite 초기화
  2. 지정된 경로의 DB 파일 열기
  3. 이후 CRUD 기능 확장 가능

  현재 단계 목표:
  - DB 연결 성공 여부 확인
*/

import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static Database? _database;

  /// 초기 상태(골든) DB 파일명
  static const String _seedDbFileName = 'reshet_seed.db';

  /// 앱이 실제로 수정하는 작업용 DB 파일명
  static const String _workDbFileName = 'reshet_work.db';

  /// 과거 파일명 호환(기존 사용 중인 DB)
  static const String _legacySeedFileName = 'bbwdb_20260106.db';

  /// data 폴더 경로 (현재는 Windows/데스크탑 기준)
  static String _dataDirPath() {
    final currentPath = Directory.current.path;
    return join(currentPath, 'data');
  }

  static String _seedDbPath() {
    final dataDir = _dataDirPath();
    final seed = join(dataDir, _seedDbFileName);
    final legacy = join(dataDir, _legacySeedFileName);

    // seed가 없고 legacy가 있으면 legacy를 seed로 취급(rename 없이도 동작)
    if (!File(seed).existsSync() && File(legacy).existsSync()) {
      return legacy;
    }
    return seed;
  }

  static String _workDbPath() {
    return join(_dataDirPath(), _workDbFileName);
  }

  /*
    initialize()

    Windows 환경에서 SQLite FFI를 초기화한다.
    반드시 DB 열기 전에 호출해야 한다.
  */
  static Future<void> initialize() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  /*
    openDatabaseFile()

    프로젝트 루트의 data 폴더에 있는
    reshet.db 파일을 연다.
  */
  static Future<Database> openDatabaseFile() async {
    if (_database != null) {
      return _database!;
    }

    final seedPath = _seedDbPath();
    final workPath = _workDbPath();

    // work DB가 없으면 seed를 복사하여 work 생성
    if (!File(workPath).existsSync()) {
      final seedFile = File(seedPath);
      if (!seedFile.existsSync()) {
        throw Exception('초기 DB(seed)를 찾을 수 없습니다: $seedPath');
      }
      await File(workPath).create(recursive: true);
      await seedFile.copy(workPath);
    }

    _database = await databaseFactory.openDatabase(workPath);

    // ✅ 여기 추가 (DB 무결성/인덱스 보장)
    await _ensureWordRelationIndexes(_database!);

    return _database!;
  }

  /// 테스트용 DB 연결 확인 메서드
  /// 실제 테이블 없이 간단한 문자열을 반환한다.
  static Future<String> getTestData() async {
    return "DB 연결 확인 완료";
  }

  /// 현재 연결된 DB의 모든 테이블 목록을 조회한다.
  static Future<List<String>> getTableList() async {
    final db = _database;

    if (db == null) {
      throw Exception("데이터베이스가 초기화되지 않았습니다.");
    }

    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;",
    );

    return result.map((row) => row['name'] as String).toList();
  }

  /// WORD_TABLE 데이터 일부 조회 (테스트용)
  static Future<List<Map<String, dynamic>>> getWords() async {
    final db = _database;

    if (db == null) {
      throw Exception("데이터베이스가 초기화되지 않았습니다.");
    }

    return await db.query('WORD_TABLE', limit: 50);
  }

  /// 현재 열려있는 DB를 닫는다.
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// 작업용 DB를 초기(seed) 상태로 되돌린다.
  /// - backup=true면 data/backups에 현재 작업용 DB를 복사해 둔다.
  static Future<void> resetToSeed({bool backup = true}) async {
    final seedPath = _seedDbPath();
    final workPath = _workDbPath();

    final seedFile = File(seedPath);
    if (!seedFile.existsSync()) {
      throw Exception('초기 DB(seed)를 찾을 수 없습니다: $seedPath');
    }

    // 열려있으면 닫기
    await closeDatabase();

    // 백업
    final workFile = File(workPath);
    if (backup && workFile.existsSync()) {
      final backupsDir = Directory(join(_dataDirPath(), 'backups'));
      if (!backupsDir.existsSync()) {
        backupsDir.createSync(recursive: true);
      }
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('-', '')
          .replaceAll('.', '');
      final backupPath = join(backupsDir.path, 'reshet_backup_$ts.db');
      await workFile.copy(backupPath);
    }

    // work를 seed로 덮어쓰기
    if (workFile.existsSync()) {
      await workFile.delete();
    }
    await seedFile.copy(workPath);

    // 다시 열기(이후 쿼리 즉시 가능)
    _database = await databaseFactory.openDatabase(workPath);

    // ✅ reset 이후에도 인덱스/중복제거 보장
    await _ensureWordRelationIndexes(_database!);
  }

  /// WORD_RELATION 테이블 무결성/성능 보강
  /// 1) (word_id_1, word_id_2) 완전 중복 row 제거
  /// 2) UNIQUE 인덱스 추가 (중복 관계 DB 차단)
  /// 3) 조회 성능 인덱스 추가 (그래프 로딩 개선)
  static Future<void> _ensureWordRelationIndexes(Database db) async {
    await db.transaction((txn) async {
      // 1) 완전 중복 제거: (word_id_1, word_id_2)별로 가장 작은 id만 남긴다
      // - DB에 이미 CHECK(word_id_1 < word_id_2)가 있어서 방향 정규화는 되어 있음
      final deleted = await txn.rawDelete('''
        DELETE FROM WORD_RELATION
        WHERE id NOT IN (
          SELECT MIN(id)
          FROM WORD_RELATION
          GROUP BY word_id_1, word_id_2
        )
      ''');

      // 디버그 로그(원하면 지워도 됨)
      // ignore: avoid_print
      print('[DB] WORD_RELATION 중복 제거: $deleted row 삭제');

      // 2) 중복 관계 차단(핵심): 같은 두 단어 쌍은 1개만 허용
      await txn.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_word_relation_pair
        ON WORD_RELATION(word_id_1, word_id_2)
      ''');

      // 3) 그래프 로딩 최적화: OR 조건 조회에 대비해 개별 인덱스도 추가
      await txn.execute('''
        CREATE INDEX IF NOT EXISTS idx_word_relation_word1
        ON WORD_RELATION(word_id_1)
      ''');
      await txn.execute('''
        CREATE INDEX IF NOT EXISTS idx_word_relation_word2
        ON WORD_RELATION(word_id_2)
      ''');
    });
  }
}
