import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late String workPath;

  setUpAll(() async {
    await DatabaseService.initialize();
  });

  setUp(() async {
    await DatabaseService.closeDatabase();
    root = await Directory.systemTemp.createTemp('reshet_db_lifecycle_test_');
    workPath = p.join(root.path, 'reshet_work.db');
    DatabaseService.setDataRootOverrideForTest(root.path);
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    DatabaseService.setDataRootOverrideForTest(null);
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('ensure 실패 시 connection을 게시하지 않고 수정 후 재시도할 수 있다', () async {
    final invalid = await databaseFactory.openDatabase(
      workPath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await invalid.execute('CREATE TABLE WORD_TABLE (id TEXT PRIMARY KEY)');
    await invalid.close();

    await expectLater(DatabaseService.openDatabaseFile(), throwsA(anything));
    expect(DatabaseService.hasOpenDatabaseForTest, isFalse);

    await File(workPath).delete();
    await _createEnsureCompatibleDatabase(workPath);

    final opened = await DatabaseService.openDatabaseFile();
    expect(opened.isOpen, isTrue);
    expect(DatabaseService.hasOpenDatabaseForTest, isTrue);
    expect(await DatabaseService.openDatabaseFile(), same(opened));
  });

  test('closeDatabase 후 singleton을 비우고 다시 열 수 있다', () async {
    await _createEnsureCompatibleDatabase(workPath);
    final first = await DatabaseService.openDatabaseFile();

    await DatabaseService.closeDatabase();

    expect(first.isOpen, isFalse);
    expect(DatabaseService.hasOpenDatabaseForTest, isFalse);
    final reopened = await DatabaseService.openDatabaseFile();
    expect(reopened.isOpen, isTrue);
    expect(reopened, isNot(same(first)));
  });
}

Future<void> _createEnsureCompatibleDatabase(String path) async {
  final db = await databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await db.execute('''
    CREATE TABLE WORD_TABLE (
      id TEXT PRIMARY KEY,
      언어 TEXT,
      스트롱넘버 TEXT,
      표기1 TEXT,
      표기2 TEXT,
      표기3 TEXT,
      표기4 TEXT,
      표기5 TEXT,
      표기6 TEXT,
      음역1 TEXT,
      음역2 TEXT,
      음역3 TEXT,
      음역4 TEXT,
      음역5 TEXT,
      음역6 TEXT,
      발음1 TEXT,
      발음2 TEXT,
      발음3 TEXT,
      발음4 TEXT,
      발음5 TEXT,
      발음6 TEXT,
      의미1 TEXT,
      의미2 TEXT,
      의미3 TEXT,
      의미4 TEXT,
      의미5 TEXT,
      의미6 TEXT,
      의미7 TEXT,
      비고 TEXT,
      graph_expand_mode TEXT NOT NULL DEFAULT 'default'
    )
  ''');
  await db.execute('''
    CREATE TABLE WORD_RELATION (
      id INTEGER PRIMARY KEY,
      word_id_1 TEXT NOT NULL,
      word_id_2 TEXT NOT NULL,
      category_code TEXT,
      relation_type TEXT,
      status_code TEXT DEFAULT 'asserted',
      direction_code TEXT NOT NULL DEFAULT 'unknown',
      description TEXT,
      relation_group_id TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE word_expression_set (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      word_id TEXT NOT NULL,
      seq INTEGER NOT NULL,
      is_representative INTEGER NOT NULL,
      spelling TEXT NOT NULL,
      transliteration TEXT,
      pronunciation TEXT,
      pronunciation_notation TEXT,
      pronunciation_notation_name TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE word_meaning_set (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      word_id TEXT NOT NULL,
      seq INTEGER NOT NULL,
      meaning TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE RELATION_CATEGORY (
      code TEXT PRIMARY KEY,
      label TEXT NOT NULL,
      description TEXT,
      sort_order INTEGER DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE RELATION_TYPE (
      code TEXT PRIMARY KEY,
      category_code TEXT NOT NULL,
      label TEXT NOT NULL,
      description TEXT,
      sort_order INTEGER DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE RELATION_STATUS (
      code TEXT PRIMARY KEY,
      label TEXT NOT NULL,
      description TEXT,
      sort_order INTEGER DEFAULT 0
    )
  ''');
  await db.insert('WORD_TABLE', {
    'id': 'fixture_word',
    '스트롱넘버': 'H1',
    '표기1': 'fixture',
    '의미1': 'fixture meaning',
  });
  await db.insert('word_expression_set', {
    'word_id': 'fixture_word',
    'seq': 1,
    'is_representative': 1,
    'spelling': 'fixture',
  });
  await db.insert('word_meaning_set', {
    'word_id': 'fixture_word',
    'seq': 1,
    'meaning': 'fixture meaning',
  });
  await db.close();
}
