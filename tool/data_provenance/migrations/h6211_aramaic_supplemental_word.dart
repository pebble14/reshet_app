import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/database/approved_content_sha256.dart';
import 'package:reshet_app/database/database_service.dart';
import 'package:reshet_app/domain/word/word_write_models.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// H6211 선택지 4 승인에 한정한 일회성 데이터 적용이다.
/// 기존 batch manifest 계약·앱·schema는 확장하지 않는다.
Future<void> main(List<String> arguments) async {
  if (arguments.any((argument) => argument != '--apply') ||
      arguments.length > 1) {
    throw ArgumentError('인자 없음: 사본 생성/undo 검증, --apply: 승인 원본 적용');
  }
  final apply = arguments.contains('--apply');
  final root = Directory.current.absolute;
  final work = File(p.join(root.path, 'data', 'reshet_work.db'));
  final seed = File(p.join(root.path, 'data', 'reshet_seed.db'));
  final manifestFile = File(
    p.join(
      root.path,
      'tool',
      'data_provenance',
      'manifests',
      'h6211_aramaic_supplemental_word.json',
    ),
  );
  final manifest =
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
  require(
    manifest['format_version'] == 1 &&
        manifest['operation'] ==
            'create_non_strong_word_via_existing_repository',
    '승인 manifest 종류',
  );
  final target = manifest['target'] as Map<String, dynamic>;
  final word = manifest['word'] as Map<String, dynamic>;
  require(
    word['word_id'] == 'H0000_0042' &&
        word['language'] == '아람어' &&
        word['strong_number'] == null &&
        word['spelling'] == 'עֲשַׂב' &&
        word['transliteration'] == null &&
        word['pronunciation'] == null &&
        jsonEncode(word['meanings']) == jsonEncode(['풀']),
    '승인된 보충 단어 범위',
  );
  final provenance = manifest['provenance'] as Map<String, dynamic>;
  final approval = File(p.join(root.path, provenance['document_id'] as String));
  require(
    await ApprovedContentSha256.file(approval) == provenance['document_sha256'],
    '승인 원문 SHA',
  );
  for (final file in [work, seed]) {
    for (final suffix in ['-wal', '-shm', '-journal']) {
      require(!File('${file.path}$suffix').existsSync(), 'DB sidecar: $suffix');
    }
  }
  final before = await ApprovedContentSha256.file(work);
  final seedBefore = await ApprovedContentSha256.file(seed);
  require(before == target['expected_work_sha256'], 'work DB exact SHA');
  final directory = Directory(
    p.join(
      root.path,
      'data',
      'backups',
      'approved_content_batch',
      'h102_approval_20261017',
      'supplement_${apply ? 'apply' : 'dry_run'}',
    ),
  );
  require(!directory.existsSync(), '동일 적용 기록 재실행 금지');
  await directory.create(recursive: true);
  final dataDirectory = Directory(p.join(directory.path, 'data'));
  await dataDirectory.create();
  final copy = await work.copy(p.join(dataDirectory.path, 'reshet_work.db'));
  require(await ApprovedContentSha256.file(copy) == before, 'byte 백업 일치');

  final report = <String, Object?>{
    'mode': apply ? 'apply' : 'dry_run',
    'manifest_sha256': await ApprovedContentSha256.file(manifestFile),
    'runner_sha256': await ApprovedContentSha256.file(
      File(
        p.join(
          root.path,
          'tool/data_provenance/migrations/h6211_aramaic_supplemental_word.dart',
        ),
      ),
    ),
    'work_sha256_before': before,
    'seed_sha256_before': seedBefore,
    'byte_backup': copy.path,
  };
  await DatabaseService.closeDatabase();
  await DatabaseService.initialize();

  Future<void> execute() async {
    final database = await DatabaseService.openDatabaseFile();
    require(
      p.equals(
        p.normalize(database.path),
        p.normalize(apply ? work.path : copy.path),
      ),
      '실제 DB 경로',
    );
    require(
      (await database.rawQuery('PRAGMA user_version')).single.values.single ==
          target['expected_user_version'],
      'user_version',
    );
    final repository = WordRepository();
    final generated = await repository.generateNextWordId(language: '아람어');
    require(generated == word['word_id'], '기존 ID 할당 규칙/미사용 ID');
    require(
      (await database.query(
        'WORD_TABLE',
        where: 'id = ?',
        whereArgs: [generated],
      )).isEmpty,
      '신규 단어 ID',
    );
    final historyBefore =
        (await database.rawQuery(
              'SELECT MAX(id) AS value FROM CHANGE_HISTORY',
            )).single['value']
            as int;
    await repository.createWord(
      id: generated,
      payload: CanonicalWordWritePayload(
        language: '아람어',
        strongNumber: null,
        expressionSets: const [
          CanonicalExpressionWriteSet(
            spelling: 'עֲשַׂב',
            transliteration: null,
            pronunciation: null,
            seq: 1,
            isRepresentative: true,
          ),
        ],
        meanings: const ['풀'],
        note: word['note'] as String,
      ),
    );
    final actualWord = (await database.query(
      'WORD_TABLE',
      where: 'id = ?',
      whereArgs: [generated],
    )).single;
    final expressions = await database.query(
      'word_expression_set',
      where: 'word_id = ?',
      whereArgs: [generated],
    );
    final meanings = await database.query(
      'word_meaning_set',
      where: 'word_id = ?',
      whereArgs: [generated],
    );
    final history = await database.query(
      'CHANGE_HISTORY',
      where: 'id > ?',
      whereArgs: [historyBefore],
    );
    require(
      actualWord['언어'] == '아람어' &&
          actualWord['스트롱넘버'] == null &&
          actualWord['비고'] == word['note'],
      '신규 word projection',
    );
    require(
      expressions.length == 1 &&
          expressions.single['seq'] == 1 &&
          expressions.single['spelling'] == 'עֲשַׂב' &&
          expressions.single['is_representative'] == 1 &&
          expressions.single['transliteration'] == null &&
          expressions.single['pronunciation'] == null,
      '신규 expression projection',
    );
    require(
      meanings.length == 1 &&
          meanings.single['seq'] == 1 &&
          meanings.single['meaning'] == '풀',
      '신규 meaning projection',
    );
    require(
      history.length == 1 &&
          history.single['entity_type'] == 'word' &&
          history.single['action_type'] == 'create' &&
          history.single['entity_id'] == generated &&
          history.single['before_json'] == null &&
          history.single['undone_at'] == null,
      '생성 history 1건',
    );
    await checkIntegrity(database);
    report.addAll({
      'word': actualWord,
      'expressions': expressions,
      'meanings': meanings,
      'history': history,
    });
    if (!apply) {
      require(
        (await repository.undoLastChange()).didUndo,
        '실제 repository undo',
      );
      for (final table in [
        'WORD_TABLE',
        'word_expression_set',
        'word_meaning_set',
      ]) {
        require(
          (await database.query(
            table,
            where: '${table == 'WORD_TABLE' ? 'id' : 'word_id'} = ?',
            whereArgs: [generated],
          )).isEmpty,
          'undo $table',
        );
      }
      await checkIntegrity(database);
      report['actual_undo_passed'] = true;
    }
  }

  try {
    if (apply) {
      await execute();
    } else {
      await DatabaseService.withIsolatedDataRoot(
        dataRootPath: dataDirectory.path,
        action: execute,
      );
    }
  } finally {
    await DatabaseService.closeDatabase();
  }
  final after = await ApprovedContentSha256.file(work);
  require(apply || after == before, 'dry-run 원본 불변');
  require(await ApprovedContentSha256.file(seed) == seedBefore, 'seed 불변');
  for (final file in [work, seed, copy]) {
    for (final suffix in ['-wal', '-shm', '-journal']) {
      require(!File('${file.path}$suffix').existsSync(), '최종 sidecar');
    }
  }
  report.addAll({
    'status': 'passed',
    'work_sha256_after': after,
    'seed_unchanged': true,
  });
  final result = File(p.join(directory.path, 'result.json'));
  await result.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  stdout.writeln(
    '보충 어휘 ${apply ? '적용' : '사본 생성/undo 검증'} 성공: ${word['word_id']}',
  );
  stdout.writeln('result: ${result.path}');
  stdout.writeln('work SHA: $after');
}

void require(bool condition, String label) {
  if (!condition) throw StateError('검증 실패: $label');
}

Future<void> checkIntegrity(Database database) async {
  require(
    (await database.rawQuery('PRAGMA integrity_check')).single.values.single ==
        'ok',
    'integrity_check',
  );
  require(
    (await database.rawQuery('PRAGMA foreign_key_check')).isEmpty,
    'foreign_key_check',
  );
}
