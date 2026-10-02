import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/approved_content_sha256.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/database/seed_release_service.dart';
import 'package:reshet_app/domain/expression/pronunciation_notation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late File work;
  late File seed;
  late SeedReleaseService service;
  late String workHash;
  late String seedHash;
  setUpAll(() async {
    await DatabaseService.initialize();
  });
  setUp(() async {
    root = await Directory.systemTemp.createTemp('reshet_seed_release_test_');
    final data = await Directory(p.join(root.path, 'data')).create();
    final source = File(
      p.join(Directory.current.path, 'data', 'reshet_seed.db'),
    );
    work = await source.copy(p.join(data.path, 'reshet_work.db'));
    seed = await source.copy(p.join(data.path, 'reshet_seed.db'));
    final db = await databaseFactory.openDatabase(work.path);
    try {
      await db.insert('CHANGE_HISTORY', {
        'group_id': 'seed-test',
        'action_type': 'update',
        'entity_type': 'word',
        'entity_id': 'G0185_0000',
        'created_at': '2026-10-02T00:00:00Z',
      });
      await db.rawUpdate('UPDATE WORD_TABLE SET 비고 = ? WHERE id = ?', [
        '사용자 비고 보존',
        'G0185_0000',
      ]);
    } finally {
      await db.close();
    }
    workHash = await ApprovedContentSha256.file(work);
    seedHash = await ApprovedContentSha256.file(seed);
    service = SeedReleaseService(root.path);
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });
  Future<void> unchanged() async {
    expect(await ApprovedContentSha256.file(work), workHash);
    expect(await ApprovedContentSha256.file(seed), seedHash);
  }

  Future<File> promote(File report) => service.promote(
    report,
    expectedReportSha256: ApprovedContentSha256.bytes(report.readAsBytesSync()),
  );

  Future<File> writeHolds({
    bool duplicate = false,
    bool mismatch = false,
  }) async {
    final db = await databaseFactory.openDatabase(
      work.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    late Map<String, Object?> row;
    try {
      row = (await db.rawQuery(
        "SELECT word_id,seq,spelling,pronunciation,pronunciation_notation,pronunciation_notation_name FROM word_expression_set WHERE word_id='G0185_0000' AND seq=1",
      )).single;
    } finally {
      await db.close();
    }
    if (mismatch) row = {...row, 'pronunciation': '원본과 다른 값'};
    final file = File(
      p.join(
        root.path,
        'tool',
        'data_provenance',
        'manifests',
        'seed_pronunciation_holds.json',
      ),
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'format': 1,
        'rows': [row, if (duplicate) row],
      }),
    );
    return file;
  }

  Future<File> writeRmac() async {
    final file = File(
      p.join(
        root.path,
        'tool',
        'data_provenance',
        'manifests',
        'seed_rmac_translations.json',
      ),
    );
    await file.parent.create(recursive: true);
    return File(
      p.join(
        Directory.current.path,
        'tool',
        'data_provenance',
        'manifests',
        'seed_rmac_translations.json',
      ),
    ).copy(file.path);
  }

  test('공개 원천의 한글 번역만 적용하고 영문·식별자·작업본을 보존한다', () async {
    await writeRmac();
    final db = await databaseFactory.openDatabase(work.path);
    late List<Map<String, Object?>> english;
    try {
      english = await db.query('RMAC_TABLE', orderBy: 'RMAC');
      await db.rawUpdate(
        "UPDATE RMAC_TABLE_KR SET Tense='과거 스크랩 설명' WHERE RMAC='V-AAI-1S'",
      );
    } finally {
      await db.close();
    }
    workHash = await ApprovedContentSha256.file(work);
    final file = await service.prepare();
    await unchanged();
    final report = jsonDecode(await file.readAsString()) as Map;
    expect(report['format'], 3);
    expect(
      report['checks']['content_preserved_except_approved_seed_changes_and_history'],
      true,
    );
    expect(
      report['checks']['content_preserved_except_approved_holds_and_history'],
      false,
    );
    final candidate = await databaseFactory.openDatabase(
      p.join(file.parent.path, 'candidate.db'),
    );
    try {
      expect(await candidate.query('RMAC_TABLE', orderBy: 'RMAC'), english);
      final korean = await candidate.query('RMAC_TABLE_KR', orderBy: 'RMAC');
      expect(
        korean.map((r) => r['RMAC']).toList(),
        english.map((r) => r['RMAC']).toList(),
      );
      expect(
        (await candidate.query(
          'RMAC_TABLE_KR',
          where: 'RMAC = ?',
          whereArgs: ['V-AAI-1S'],
        )).single['Tense'],
        '부정과거 G5777',
      );
    } finally {
      await candidate.close();
    }
    await promote(file);
    expect(await ApprovedContentSha256.file(work), workHash);
  });

  test('번역 목록에 없는 영문 값과 영문·한글 식별자 차이는 거부한다', () async {
    await writeRmac();
    final db = await databaseFactory.openDatabase(work.path);
    try {
      await db.rawUpdate(
        "UPDATE RMAC_TABLE SET Tense='출처 미확인 설명' WHERE RMAC='V-AAI-1S'",
      );
    } finally {
      await db.close();
    }
    workHash = await ApprovedContentSha256.file(work);
    await expectLater(service.prepare(), throwsStateError);
    await unchanged();
    final db2 = await databaseFactory.openDatabase(work.path);
    try {
      await db2.rawUpdate(
        "UPDATE RMAC_TABLE SET Tense='Aorist G5777' WHERE RMAC='V-AAI-1S'",
      );
      await db2.delete(
        'RMAC_TABLE_KR',
        where: 'RMAC = ?',
        whereArgs: ['V-AAI-1S'],
      );
    } finally {
      await db2.close();
    }
    workHash = await ApprovedContentSha256.file(work);
    await expectLater(service.prepare(), throwsStateError);
    await unchanged();
  });

  test('후보 검사 뒤 RMAC 목록을 바꾸면 승격하지 않는다', () async {
    final policy = await writeRmac();
    final file = await service.prepare();
    await policy.writeAsString(' ', mode: FileMode.append);
    await expectLater(promote(file), throwsStateError);
    await unchanged();
  });

  test('RMAC 후보 내용을 변조하면 보고서 hash를 바꿔도 승격하지 않는다', () async {
    await writeRmac();
    final file = await service.prepare();
    final candidate = File(p.join(file.parent.path, 'candidate.db'));
    final db = await databaseFactory.openDatabase(candidate.path);
    try {
      await db.rawUpdate(
        "UPDATE RMAC_TABLE_KR SET Tense='임의 설명' WHERE RMAC='V-AAI-1S'",
      );
    } finally {
      await db.close();
    }
    final report = jsonDecode(await file.readAsString()) as Map;
    report['candidate_sha256'] = await ApprovedContentSha256.file(candidate);
    await file.writeAsString(jsonEncode(report));
    await expectLater(promote(file), throwsStateError);
    await unchanged();
  });

  test('승인한 발음만 후보에서 비우고 작업본과 다른 필드는 보존한다', () async {
    await writeHolds();
    final file = await service.prepare();
    await unchanged();
    final report = jsonDecode(await file.readAsString()) as Map;
    expect(report['pronunciation_holds'].length, 1);
    expect(report['checks']['content_preserved_except_history'], false);
    expect(
      report['checks']['content_preserved_except_approved_holds_and_history'],
      true,
    );
    final db = await databaseFactory.openDatabase(
      p.join(file.parent.path, 'candidate.db'),
      options: OpenDatabaseOptions(readOnly: true),
    );
    try {
      final row = (await db.rawQuery(
        "SELECT * FROM word_expression_set WHERE word_id='G0185_0000' AND seq=1",
      )).single;
      expect(
        readStoredPronunciation(
          pronunciation: row['pronunciation'],
          notationCode: row['pronunciation_notation'],
          notationName: row['pronunciation_notation_name'],
        ),
        isNull,
      );
      final change =
          (report['diff']['word_expression_set']['changed'] as List).single
              as Map;
      final before = Map.of(change['before'] as Map);
      final after = Map.of(change['after'] as Map);
      for (final key in [
        'pronunciation',
        'pronunciation_notation',
        'pronunciation_notation_name',
      ]) {
        before.remove(key);
        after.remove(key);
      }
      expect(after, before);
    } finally {
      await db.close();
    }
    await promote(file);
    expect(await ApprovedContentSha256.file(work), workHash);
  });

  test('원래 발음이 다르거나 대상이 중복이면 원본을 보존하고 거부한다', () async {
    await writeHolds(mismatch: true);
    await expectLater(service.prepare(), throwsStateError);
    await unchanged();
    await writeHolds(duplicate: true);
    await expectLater(service.prepare(), throwsStateError);
    await unchanged();
  });

  test('검사 뒤 예외 목록이 변경되면 승격하지 않는다', () async {
    final holds = await writeHolds();
    final report = await service.prepare();
    await holds.writeAsString(' ', mode: FileMode.append);
    await expectLater(promote(report), throwsStateError);
    await unchanged();
  });

  test('발음 보류와 무관한 후보 변경은 보고서 hash를 다시 만들어도 거부한다', () async {
    await writeHolds();
    final file = await service.prepare();
    final candidate = File(p.join(file.parent.path, 'candidate.db'));
    final db = await databaseFactory.openDatabase(candidate.path);
    try {
      await db.rawUpdate(
        "UPDATE WORD_TABLE SET 비고='범위 밖 변경' WHERE id='G0185_0000'",
      );
    } finally {
      await db.close();
    }
    final report = jsonDecode(await file.readAsString()) as Map;
    report['candidate_sha256'] = await ApprovedContentSha256.file(candidate);
    await file.writeAsString(jsonEncode(report));
    await expectLater(promote(file), throwsStateError);
    await unchanged();
  });

  test('후보에서만 이력을 비우고 비고/내용을 보존하며 변경값을 보고한다', () async {
    final reportFile = await service.prepare();
    await unchanged();
    final report = jsonDecode(await reportFile.readAsString()) as Map;
    expect(report['removed_history_count'], greaterThan(0));
    expect(report['checks']['runtime_probe'], 'passed');
    expect(report['diff']['WORD_TABLE']['changed'].length, 1);
    final candidate = File(p.join(reportFile.parent.path, 'candidate.db'));
    final db = await databaseFactory.openDatabase(
      candidate.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    try {
      expect(
        (await db.rawQuery(
          'SELECT COUNT(*) AS n FROM CHANGE_HISTORY',
        )).single['n'],
        0,
      );
      expect(
        (await db.rawQuery(
          "SELECT 비고 FROM WORD_TABLE WHERE id='G0185_0000'",
        )).single['비고'],
        '사용자 비고 보존',
      );
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    } finally {
      await db.close();
    }
    expect(
      await File(p.join(reportFile.parent.path, 'summary.txt')).exists(),
      isTrue,
    );
  });

  test('명시적 승격은 이전 seed를 보관하고 work를 변경하지 않는다', () async {
    final report = await service.prepare();
    final candidateHash = await ApprovedContentSha256.file(
      File(p.join(report.parent.path, 'candidate.db')),
    );
    final backup = await promote(report);
    expect(await ApprovedContentSha256.file(backup), seedHash);
    expect(await ApprovedContentSha256.file(seed), candidateHash);
    expect(await ApprovedContentSha256.file(work), workHash);
    await expectLater(promote(report), throwsStateError);
  });

  test('검사 후 후보가 바뀌면 승격하지 않는다', () async {
    final report = await service.prepare();
    await File(p.join(report.parent.path, 'candidate.db')).writeAsString('변조');
    await expectLater(promote(report), throwsStateError);
    await unchanged();
  });

  test('승인 보고서 SHA가 다르면 승격하지 않는다', () async {
    final report = await service.prepare();
    final expected = await ApprovedContentSha256.file(report);
    await report.writeAsString(' ', mode: FileMode.append);
    await expectLater(
      service.promote(report, expectedReportSha256: expected),
      throwsStateError,
    );
    await unchanged();
  });

  test('검사 후 기존 seed가 바뀌면 변경된 seed를 보존한다', () async {
    final report = await service.prepare();
    final db = await databaseFactory.openDatabase(seed.path);
    try {
      await db.execute('CREATE TABLE unexpected(value TEXT)');
    } finally {
      await db.close();
    }
    final changed = await ApprovedContentSha256.file(seed);
    await expectLater(promote(report), throwsStateError);
    expect(await ApprovedContentSha256.file(seed), changed);
  });

  test('진행 중 sidecar가 있으면 후보 준비를 중단한다', () async {
    await File('${work.path}-wal').writeAsString('사용 중');
    await expectLater(service.prepare(), throwsStateError);
    await unchanged();
  });

  test('후보 구조 검증 실패 시 기존 DB를 보존한다', () async {
    final db = await databaseFactory.openDatabase(work.path);
    try {
      await db.execute('DROP TABLE RMAC_TABLE');
    } finally {
      await db.close();
    }
    final invalidHash = await ApprovedContentSha256.file(work);
    await expectLater(service.prepare(), throwsA(isA<Exception>()));
    expect(await ApprovedContentSha256.file(seed), seedHash);
    expect(await ApprovedContentSha256.file(work), invalidHash);
  });

  test('두 번째 rename 실패는 이전 seed를 복구하고 백업도 보관한다', () async {
    final report = await service.prepare();
    var calls = 0;
    service = SeedReleaseService(
      root.path,
      rename: (from, to) async {
        calls++;
        if (calls == 2) throw FileSystemException('rename 실패 주입');
        await File(from).rename(to);
      },
    );
    await expectLater(promote(report), throwsA(isA<FileSystemException>()));
    await unchanged();
    expect(
      await ApprovedContentSha256.file(
        File(p.join(report.parent.path, 'previous_seed.db')),
      ),
      seedHash,
    );
  });

  test('교체 후 검증 실패도 이전 seed를 복구한다', () async {
    final report = await service.prepare();
    var calls = 0;
    service = SeedReleaseService(
      root.path,
      rename: (from, to) async {
        await File(from).rename(to);
        calls++;
        if (calls == 2) await File(to).writeAsString('교체 후 손상 주입');
      },
    );
    await expectLater(promote(report), throwsA(isA<Exception>()));
    await unchanged();
    expect(
      await File(p.join(report.parent.path, 'previous_seed.db')).exists(),
      isTrue,
    );
  });
}
