import 'dart:io';

import 'package:path/path.dart' as p;

void ensureSystemTempDatabaseTargets({
  required String dataRootPath,
  required String actualWorkDbPath,
  required String actualSeedDbPath,
}) {
  final normalizedSystemTempPath = _normalizedAbsolutePath(
    Directory.systemTemp.path,
  );
  final normalizedProtectedPaths = {
    _normalizedAbsolutePath(actualWorkDbPath),
    _normalizedAbsolutePath(actualSeedDbPath),
  };
  final normalizedTargetPaths = {
    _normalizedAbsolutePath(p.join(dataRootPath, 'reshet_work.db')),
    _normalizedAbsolutePath(p.join(dataRootPath, 'reshet_seed.db')),
  };

  final protectedCollisions = normalizedTargetPaths.intersection(
    normalizedProtectedPaths,
  );
  if (protectedCollisions.isNotEmpty) {
    throw StateError(
      '테스트 DB 경로가 actual work/seed DB와 충돌합니다: '
      '${protectedCollisions.join(', ')}',
    );
  }

  final nonTempTargets = normalizedTargetPaths
      .where(
        (targetPath) =>
            targetPath != normalizedSystemTempPath &&
            !p.isWithin(normalizedSystemTempPath, targetPath),
      )
      .toList(growable: false);
  if (nonTempTargets.isNotEmpty) {
    throw StateError(
      '테스트 DB는 system temp 아래에 있어야 합니다: '
      '${nonTempTargets.join(', ')}',
    );
  }
}

String _normalizedAbsolutePath(String path) {
  final normalizedPath = p.normalize(p.absolute(path));
  return Platform.isWindows ? normalizedPath.toLowerCase() : normalizedPath;
}
