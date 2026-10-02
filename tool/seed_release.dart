import 'dart:io';

import 'package:reshet_app/database/approved_content_sha256.dart';
import 'package:reshet_app/database/seed_release_service.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help')) {
    stdout.writeln(
      '프로젝트 루트에서 실행하세요. 앱과 DB 편집기를 닫아야 합니다.\n'
      '후보 생성: dart run tool/seed_release.dart prepare\n'
      '승인 발음 보류: tool/data_provenance/manifests/seed_pronunciation_holds.json을 자동 적용합니다.\n'
      'RMAC 한글 재작성: tool/data_provenance/manifests/seed_rmac_translations.json을 자동 적용합니다.\n'
      '승격: dart run tool/seed_release.dart promote <report.json> <승인한 보고서 SHA256>\n'
      'prepare는 work/seed를 교체하지 않습니다. promote만 기존 seed를 백업하고 교체합니다.',
    );
    return;
  }
  try {
    final service = SeedReleaseService(Directory.current.path);
    if (args.length == 1 && args[0] == 'prepare') {
      final report = await service.prepare();
      stdout.writeln(
        '후보 검사 완료: ${report.path}\n요약: ${report.parent.path}${Platform.pathSeparator}summary.txt\n보고서 SHA256: ${await ApprovedContentSha256.file(report)}\n기존 seed는 교체하지 않았습니다.',
      );
    } else if (args.length == 3 && args[0] == 'promote') {
      final backup = await service.promote(
        File(args[1]),
        expectedReportSha256: args[2],
      );
      stdout.writeln(
        'seed 교체 완료. 이전 seed 백업: ${backup.path}\n앱 빌드와 배포는 별도로 수행하세요.',
      );
    } else {
      throw ArgumentError('명령 인자가 잘못되었습니다. --help를 확인하세요.');
    }
  } catch (error) {
    stderr.writeln('배포 seed 작업 실패: $error');
    exitCode = 1;
  }
}
