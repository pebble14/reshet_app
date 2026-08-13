import 'dart:convert';
import 'dart:io';

import 'package:reshet_app/database/approved_content_batch_service.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runApprovedContentBatchCli(
    arguments,
    output: stdout,
    errorOutput: stderr,
  );
}

Future<int> runApprovedContentBatchCli(
  List<String> arguments, {
  required StringSink output,
  required StringSink errorOutput,
}) async {
  _ApprovedContentCliOptions options;
  try {
    options = _ApprovedContentCliOptions.parse(arguments);
  } on ApprovedContentValidationException catch (error) {
    errorOutput.writeln('인자 검증 실패: ${error.message}');
    errorOutput.writeln('사용법은 --help로 확인하세요.');
    return 2;
  }

  if (options.showHelp) {
    output.write(_helpText);
    return 0;
  }

  try {
    final projectRoot = ApprovedContentBatchRunner.discoverProjectRoot(
      Directory.current,
    );
    final runner = ApprovedContentBatchRunner(projectRoot: projectRoot);
    final manifestFile = File(options.manifestPath!);
    if (options.apply) {
      final result = await runner.apply(manifestFile: manifestFile);
      output.writeln('live apply 성공: ${result.batchId}');
      output.writeln('history group: ${result.historyGroupId}');
      output.writeln('snapshot: ${result.snapshotPath}');
      output.writeln('report: ${result.reportPath}');
      output.writeln('work SHA: ${result.workSha256After}');
      output.writeln('seed SHA 불변: ${result.seedSha256}');
    } else {
      final result = await runner.dryRun(
        manifestFile: manifestFile,
        databaseFile: options.databasePath == null
            ? null
            : File(options.databasePath!),
      );
      const encoder = JsonEncoder.withIndent('  ');
      output.writeln(encoder.convert(result.toJson()));
    }
    return 0;
  } on ApprovedContentValidationException catch (error) {
    errorOutput.writeln('검증 실패: ${error.message}');
    return 2;
  } on ApprovedContentExecutionException catch (error) {
    errorOutput.writeln('실행 실패: ${error.message}');
    if (error.reportPath != null) {
      errorOutput.writeln('실패 보고서: ${error.reportPath}');
    }
    return 1;
  } catch (error, stackTrace) {
    errorOutput.writeln('내부 실행 실패: $error');
    errorOutput.writeln(stackTrace);
    return 1;
  }
}

final class _ApprovedContentCliOptions {
  const _ApprovedContentCliOptions({
    required this.showHelp,
    required this.apply,
    required this.manifestPath,
    required this.databasePath,
  });

  final bool showHelp;
  final bool apply;
  final String? manifestPath;
  final String? databasePath;

  static _ApprovedContentCliOptions parse(List<String> arguments) {
    var showHelp = false;
    var apply = false;
    String? manifestPath;
    String? databasePath;

    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      switch (argument) {
        case '--help':
        case '-h':
          showHelp = true;
        case '--apply':
          if (apply) {
            throw const ApprovedContentValidationException(
              '--apply가 중복 지정됐습니다.',
            );
          }
          apply = true;
        case '--manifest':
          if (manifestPath != null) {
            throw const ApprovedContentValidationException(
              '--manifest가 중복 지정됐습니다.',
            );
          }
          if (index + 1 >= arguments.length) {
            throw const ApprovedContentValidationException(
              '--manifest 뒤에 JSON 파일 경로가 필요합니다.',
            );
          }
          manifestPath = arguments[++index];
          if (manifestPath.isEmpty) {
            throw const ApprovedContentValidationException(
              '--manifest 경로가 비어 있습니다.',
            );
          }
        case '--database':
          if (databasePath != null) {
            throw const ApprovedContentValidationException(
              '--database가 중복 지정됐습니다.',
            );
          }
          if (index + 1 >= arguments.length) {
            throw const ApprovedContentValidationException(
              '--database 뒤에 read-only 검증 대상 경로가 필요합니다.',
            );
          }
          databasePath = arguments[++index];
          if (databasePath.isEmpty) {
            throw const ApprovedContentValidationException(
              '--database 경로가 비어 있습니다.',
            );
          }
        default:
          throw ApprovedContentValidationException('알 수 없는 인자입니다: $argument');
      }
    }

    if (showHelp) {
      return _ApprovedContentCliOptions(
        showHelp: true,
        apply: false,
        manifestPath: manifestPath,
        databasePath: databasePath,
      );
    }
    if (manifestPath == null) {
      throw const ApprovedContentValidationException(
        '--manifest <manifest.json>이 필요합니다.',
      );
    }
    if (apply && databasePath != null) {
      throw const ApprovedContentValidationException(
        '--apply와 --database는 함께 사용할 수 없습니다. '
        'live apply 대상은 canonical data/reshet_work.db로 고정됩니다.',
      );
    }
    return _ApprovedContentCliOptions(
      showHelp: false,
      apply: apply,
      manifestPath: manifestPath,
      databasePath: databasePath,
    );
  }
}

const String _helpText = '''
Reshet 승인 콘텐츠 batch applicator v1/v2

사용법:
  dart run tool/approved_content_batch.dart --manifest <manifest.json>
  dart run tool/approved_content_batch.dart --manifest <manifest.json> --apply

옵션:
  --manifest <path>  manifest v1 또는 v2 JSON 파일
  --database <path>  dry-run 전용 read-only 검증 대상 DB
  --apply            전체 dry-run 성공 뒤 canonical data/reshet_work.db에 적용
  --help, -h         도움말 표시

--apply가 없으면 항상 dry-run입니다. --apply는 임의 DB 경로 및 seed DB와
조합할 수 없으며, manifest의 exact work DB SHA를 승인 경계로 사용합니다.
''';
