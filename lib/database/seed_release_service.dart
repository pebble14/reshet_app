import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'approved_content_sha256.dart';
import 'database_service.dart';
import 'database_snapshot_service.dart';

typedef SeedRename = Future<void> Function(String from, String to);

/// 개발자용 배포 후보 생성/승격. 사용자 앱의 자동 업데이트 경로가 아니다.
final class SeedReleaseService {
  SeedReleaseService(String projectRoot, {SeedRename? rename})
    : root = Directory(projectRoot).absolute,
      _rename = rename ?? _renameFile;

  final Directory root;
  final SeedRename _rename;
  static const _validator = DatabaseRestoreSchemaValidator();
  File get work => File(p.join(root.path, 'data', 'reshet_work.db'));
  File get seed => File(p.join(root.path, 'data', 'reshet_seed.db'));
  Directory get output =>
      Directory(p.join(root.path, 'data', 'backups', 'seed_release'));

  static Future<void> _renameFile(String from, String to) async {
    await File(from).rename(to);
  }

  Future<T> _locked<T>(Future<T> Function() action) async {
    await output.create(recursive: true);
    final handle = await File(
      p.join(output.path, 'release.lock'),
    ).open(mode: FileMode.append);
    var locked = false;
    try {
      await handle.lock(FileLock.exclusive);
      locked = true;
      return await action();
    } finally {
      if (locked) await handle.unlock();
      await handle.close();
    }
  }

  Future<void> _noSidecars(File file) async {
    if (!await file.exists()) throw StateError('DB가 없습니다: ${file.path}');
    if (await FileSystemEntity.isLink(file.path)) {
      throw StateError('DB 심볼릭 링크는 지원하지 않습니다.');
    }
    for (final suffix in ['-wal', '-shm', '-journal']) {
      if (await File('${file.path}$suffix').exists()) {
        throw StateError('앱과 DB 편집기를 닫고 다시 실행하세요: ${file.path}$suffix');
      }
    }
  }

  Future<Database> _open(File file, {bool readOnly = true}) =>
      databaseFactory.openDatabase(
        file.path,
        options: OpenDatabaseOptions(readOnly: readOnly, singleInstance: false),
      );

  Future<void> _validate(File file) async {
    await _validator.validateRuntimeFile(file.path);
    final db = await _open(file);
    try {
      if ((await db.rawQuery('PRAGMA foreign_key_check')).isNotEmpty) {
        throw StateError('외래키 검사 실패: ${file.path}');
      }
    } finally {
      await db.close();
    }
  }

  Future<Map<String, Object?>> _logical(File file) async {
    final db = await _open(file);
    try {
      final schema = await db.rawQuery(
        "SELECT type,name,tbl_name,sql FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' ORDER BY type,name",
      );
      final tables = <String, Object?>{};
      for (final row in schema.where((r) => r['type'] == 'table')) {
        final name = row['name'] as String;
        final quoted = '"${name.replaceAll('"', '""')}"';
        final info = await db.rawQuery('PRAGMA table_info($quoted)');
        final primary = info.where((c) => (c['pk'] as int) > 0).toList()
          ..sort((a, b) => (a['pk'] as int).compareTo(b['pk'] as int));
        final values = await db.rawQuery('SELECT * FROM $quoted');
        final rows = <String, String>{};
        for (final value in values) {
          final normalized = <String, Object?>{
            for (final entry in value.entries)
              entry.key: entry.value is List<int>
                  ? {'blob': base64Encode(entry.value as List<int>)}
                  : entry.value,
          };
          final encoded = jsonEncode(normalized);
          final key = primary.isEmpty
              ? encoded
              : jsonEncode([
                  for (final col in primary) normalized[col['name']],
                ]);
          if (rows.containsKey(key)) {
            throw StateError('비교할 행의 고유 키가 없습니다: $name');
          }
          rows[key] = encoded;
        }
        final keys = rows.keys.toList()..sort();
        tables[name] = {for (final key in keys) key: rows[key]};
      }
      return {
        'schema': schema,
        'user_version': (await db.rawQuery(
          'PRAGMA user_version',
        )).single.values.single,
        'tables': tables,
      };
    } finally {
      await db.close();
    }
  }

  void _assertSameContent(
    Map<String, Object?> before,
    Map<String, Object?> after,
  ) {
    final left = Map<String, Object?>.from(before['tables'] as Map)
      ..remove('CHANGE_HISTORY');
    final right = Map<String, Object?>.from(after['tables'] as Map)
      ..remove('CHANGE_HISTORY');
    if (jsonEncode(left) != jsonEncode(right) ||
        jsonEncode(before['schema']) != jsonEncode(after['schema']) ||
        before['user_version'] != after['user_version']) {
      throw StateError('편집 이력 이외의 내용 또는 구조가 변경되었습니다.');
    }
    if ((after['tables'] as Map)['CHANGE_HISTORY'] case final Map history
        when history.isNotEmpty) {
      throw StateError('배포 후보의 편집 이력이 비어 있지 않습니다.');
    }
  }

  Map<String, Object?> _diff(
    Map<String, Object?> old,
    Map<String, Object?> next,
  ) {
    final a = old['tables'] as Map;
    final b = next['tables'] as Map;
    final result = <String, Object?>{};
    final names = {...a.keys.cast<String>(), ...b.keys.cast<String>()}.toList()
      ..sort();
    for (final name in names) {
      final left = (a[name] as Map?) ?? {};
      final right = (b[name] as Map?) ?? {};
      final added = right.keys.where((k) => !left.containsKey(k)).toList();
      final removed = left.keys.where((k) => !right.containsKey(k)).toList();
      final changed = right.keys
          .where((k) => left.containsKey(k) && left[k] != right[k])
          .toList();
      result[name] = {
        'before': left.length,
        'after': right.length,
        'added': [for (final k in added) jsonDecode(right[k] as String)],
        'removed': [for (final k in removed) jsonDecode(left[k] as String)],
        'changed': [
          for (final k in changed)
            {
              'before': jsonDecode(left[k] as String),
              'after': jsonDecode(right[k] as String),
            },
        ],
      };
    }
    return result;
  }

  Future<File> prepare() => _locked(() async {
    await DatabaseService.initialize();
    await _noSidecars(work);
    await _noSidecars(seed);
    if (await work.resolveSymbolicLinks() ==
        await seed.resolveSymbolicLinks()) {
      throw StateError('work와 seed가 같습니다.');
    }
    final workHash = await ApprovedContentSha256.file(work);
    final seedHash = await ApprovedContentSha256.file(seed);
    await _validate(work);
    await _validate(seed);
    final workContent = await _logical(work);
    final seedContent = await _logical(seed);
    final directory = await output.createTemp('candidate_');
    final candidate = File(p.join(directory.path, 'candidate.db'));
    try {
      final source = await _open(work);
      try {
        final snapshot = await DatabaseSnapshotService().create(
          sourceDatabase: source,
        );
        try {
          await snapshot.file.copy(candidate.path);
        } finally {
          await snapshot.cleanup();
        }
      } finally {
        await source.close();
      }
      final db = await _open(candidate, readOnly: false);
      try {
        await db.execute('PRAGMA secure_delete=ON');
        await db.delete('CHANGE_HISTORY');
        await db.execute('VACUUM');
      } finally {
        await db.close();
      }
      await _validate(candidate);
      final candidateContent = await _logical(candidate);
      _assertSameContent(workContent, candidateContent);
      // runtime ensure는 별도 사본에서만 실행해 후보 내용은 고정한다.
      final probe = await candidate.copy(
        p.join(directory.path, 'runtime_probe.db'),
      );
      final runtime = await _open(probe, readOnly: false);
      try {
        await DatabaseService.ensureRuntimeSchema(runtime);
      } finally {
        await runtime.close();
      }
      await _validate(probe);
      _assertSameContent(candidateContent, await _logical(probe));
      await probe.delete();
      await _noSidecars(work);
      await _noSidecars(seed);
      if (await ApprovedContentSha256.file(work) != workHash ||
          await ApprovedContentSha256.file(seed) != seedHash) {
        throw StateError('후보 생성 중 원본 DB가 변경되었습니다. 후보를 다시 만드세요.');
      }
      final diff = _diff(seedContent, candidateContent);
      final report = <String, Object?>{
        'format': 1,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'history_policy': 'clear_candidate_only',
        'work_path': await work.resolveSymbolicLinks(),
        'seed_path': await seed.resolveSymbolicLinks(),
        'work_sha256': workHash,
        'seed_sha256_before': seedHash,
        'candidate_sha256': await ApprovedContentSha256.file(candidate),
        'checks': {
          'integrity': 'ok',
          'foreign_key_issues': 0,
          'content_preserved_except_history': true,
          'runtime_probe': 'passed',
        },
        'removed_history_count':
            ((workContent['tables'] as Map)['CHANGE_HISTORY'] as Map).length,
        'diff': diff,
      };
      final summary = StringBuffer(
        '배포용 seed 후보 검사 통과\n생성: ${report['created_at']}\n원본 work와 기존 seed는 변경하지 않았습니다.\n편집 이력 ${report['removed_history_count']}건은 후보에서만 제거했습니다.\n',
      );
      for (final entry in diff.entries) {
        final d = entry.value as Map;
        summary.writeln(
          '${entry.key}: ${d['before']} → ${d['after']} / 추가 ${(d['added'] as List).length}, 삭제 ${(d['removed'] as List).length}, 수정 ${(d['changed'] as List).length}',
        );
        if (entry.key != 'CHANGE_HISTORY') {
          for (final row in (d['changed'] as List).take(5)) {
            summary.writeln('  변경: ${jsonEncode(row)}');
          }
          for (final row in (d['added'] as List).take(5)) {
            summary.writeln('  추가: ${jsonEncode(row)}');
          }
          for (final row in (d['removed'] as List).take(5)) {
            summary.writeln('  삭제: ${jsonEncode(row)}');
          }
        }
      }
      summary.writeln(
        '전체 변경값: report.json. 의미의 정당성, 테스트 자료 또는 비공개 내용 여부는 자동 판정하지 않습니다.',
      );
      await File(
        p.join(directory.path, 'summary.txt'),
      ).writeAsString(summary.toString(), flush: true);
      final file = File(p.join(directory.path, 'report.json'));
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(report),
        flush: true,
      );
      return file;
    } catch (_) {
      // report.json이 없으면 검증/승격 가능한 후보가 아니다. 조사용 파일은 보존한다.
      rethrow;
    }
  });

  Future<File> promote(
    File reportFile, {
    required String expectedReportSha256,
  }) => _locked(() async {
    await DatabaseService.initialize();
    final reportPath = await reportFile.resolveSymbolicLinks();
    if (!p.isWithin(await output.resolveSymbolicLinks(), reportPath) ||
        p.basename(reportPath) != 'report.json') {
      throw StateError('이 프로젝트의 후보 보고서만 승격할 수 있습니다.');
    }
    if (await ApprovedContentSha256.file(reportFile) != expectedReportSha256) {
      throw StateError('승인한 보고서와 SHA가 다릅니다.');
    }
    final report =
        jsonDecode(await reportFile.readAsString()) as Map<String, dynamic>;
    if (report['format'] != 1 ||
        report['history_policy'] != 'clear_candidate_only' ||
        report['checks']?['runtime_probe'] != 'passed') {
      throw StateError('지원하지 않거나 검증되지 않은 보고서입니다.');
    }
    final candidate = File(p.join(p.dirname(reportPath), 'candidate.db'));
    await _noSidecars(candidate);
    await _noSidecars(seed);
    await _noSidecars(work);
    if (report['seed_path'] != await seed.resolveSymbolicLinks() ||
        report['work_path'] != await work.resolveSymbolicLinks()) {
      throw StateError('보고서의 대상 프로젝트가 다릅니다.');
    }
    final expectedSeed = report['seed_sha256_before'] as String;
    final expectedCandidate = report['candidate_sha256'] as String;
    if (await ApprovedContentSha256.file(seed) != expectedSeed ||
        await ApprovedContentSha256.file(candidate) != expectedCandidate) {
      throw StateError('검사 이후 seed 또는 후보가 변경되었습니다.');
    }
    await _validate(candidate);
    final db = await _open(candidate);
    try {
      if ((await db.rawQuery(
            'SELECT COUNT(*) AS n FROM CHANGE_HISTORY',
          )).single['n'] !=
          0) {
        throw StateError('후보 편집 이력이 비어 있지 않습니다.');
      }
    } finally {
      await db.close();
    }
    final backup = File(p.join(p.dirname(reportPath), 'previous_seed.db'));
    if (await backup.exists()) throw StateError('이미 승격한 후보이거나 이전 복구 파일이 있습니다.');
    final stageDir = await seed.parent.createTemp('.seed_promote_');
    final staged = File(p.join(stageDir.path, 'seed.db'));
    var moved = false;
    var published = false;
    try {
      await candidate.copy(staged.path);
      if (await ApprovedContentSha256.file(staged) != expectedCandidate) {
        throw StateError('승격 사본 검증 실패');
      }
      await _noSidecars(seed);
      if (await ApprovedContentSha256.file(seed) != expectedSeed) {
        throw StateError('교체 직전 seed가 변경되었습니다.');
      }
      await _rename(seed.path, backup.path);
      moved = true;
      await _rename(staged.path, seed.path);
      published = true;
      await _validate(seed);
      if (await ApprovedContentSha256.file(seed) != expectedCandidate) {
        throw StateError('교체 후 seed 검증 실패');
      }
      return backup;
    } catch (error) {
      if (moved) {
        try {
          if (published) {
            await _rename(seed.path, p.join(stageDir.path, 'failed_seed.db'));
          }
          // 복구 뒤에도 백업 파일은 남긴다.
          await backup.copy(seed.path);
          if (await ApprovedContentSha256.file(seed) != expectedSeed) {
            throw StateError('복구 SHA 불일치');
          }
        } catch (rollback) {
          throw StateError(
            'seed 교체 실패: $error / 자동 복구 실패: $rollback / 보존 백업: ${backup.path}',
          );
        }
      }
      rethrow;
    } finally {
      // 같은 data 폴더에서 직접 생성한 staging만 정리한다.
      if (p.isWithin(seed.parent.absolute.path, stageDir.absolute.path)) {
        try {
          await stageDir.delete(recursive: true);
        } catch (_) {
          /* 검증 결과와 백업은 보존 */
        }
      }
    }
  });
}
