import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reshet_app/database/database_service.dart';

void main() {
  late Directory root;
  late String exePath;
  late String localData;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('reshet_distribution_path_');
    exePath = p.join(root.path, 'Reshet', 'study.exe');
    localData = p.join(root.path, 'LocalAppData');
    await Directory(p.dirname(exePath)).create();
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  String resolve(String cwd, {String? appData, String? executable}) =>
      DatabaseService.resolveDataDirPathForTest(
        isAndroid: false,
        isWindows: true,
        isDebug: false,
        currentDirectoryPath: cwd,
        resolvedExecutablePath: executable ?? exePath,
        systemTempParentPath: root.path,
        localAppDataPath: appData,
      );

  test('설치형은 프로젝트/배포/기타 CWD 모두 동일 사용자 저장소를 사용한다', () {
    for (final cwd in [
      root.path,
      p.dirname(exePath),
      p.join(root.path, 'other'),
    ]) {
      expect(
        resolve(cwd, appData: localData),
        p.join(localData, 'Reshet', 'data'),
      );
    }
  });
  test('portable 표시는 exe 옆에서만 읽고 LOCALAPPDATA 없이 user_data를 선택한다', () async {
    await File(p.join(p.dirname(exePath), 'reshet.portable')).writeAsString('');
    for (final cwd in [
      root.path,
      p.dirname(exePath),
      p.join(root.path, 'other'),
    ]) {
      expect(resolve(cwd), p.join(p.dirname(exePath), 'user_data'));
    }
  });
  test('포터블 폴더를 옮기면 함께 이동한 사용자 DB 위치를 선택한다', () async {
    final oldDir = Directory(p.dirname(exePath));
    await File(p.join(oldDir.path, 'reshet.portable')).writeAsString('');
    await Directory(p.join(oldDir.path, 'user_data')).create();
    await File(
      p.join(oldDir.path, 'user_data', 'reshet_work.db'),
    ).writeAsString('사용자 자료');
    final moved = await oldDir.rename(p.join(root.path, 'moved'));
    final resolved = resolve(
      root.path,
      executable: p.join(moved.path, 'study.exe'),
    );
    expect(
      await File(p.join(resolved, 'reshet_work.db')).readAsString(),
      '사용자 자료',
    );
  });
  test('CWD의 portable 표시나 과거 DB로 모드를 추측하지 않는다', () async {
    await File(p.join(root.path, 'reshet.portable')).writeAsString('');
    await Directory(p.join(root.path, 'data')).create();
    await File(
      p.join(root.path, 'data', 'reshet_work.db'),
    ).writeAsString('과거 DB');
    expect(
      resolve(root.path, appData: localData),
      p.join(localData, 'Reshet', 'data'),
    );
  });
  test('설치형 사용자 경로가 없거나 상대경로이면 CWD fallback 없이 실패한다', () {
    for (final value in [null, '', 'relative']) {
      expect(() => resolve(root.path, appData: value), throwsStateError);
    }
  });
}
