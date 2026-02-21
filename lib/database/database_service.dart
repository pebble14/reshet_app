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

    // 현재 실행 경로
    final currentPath = Directory.current.path;

    // data/reshet.db 경로 생성
    final dbPath = join(currentPath, 'data', 'reshet.db');

    _database = await databaseFactory.openDatabase(dbPath);

    return _database!;
  }

  /// 테스트용 DB 연결 확인 메서드
  /// 실제 테이블 없이 간단한 문자열을 반환한다.
  static Future<String> getTestData() async {
    return "DB 연결 확인 완료";
  }
}
