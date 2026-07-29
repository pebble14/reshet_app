/*
  database_service.dart

  SQLite work DB 경로와 FFI 초기화, open/ensure/close/reset lifecycle을
  관리한다.
*/

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

typedef _LegacyRelatedCell = ({
  String sourceWordId,
  String sourceColumn,
  String targetRawValue,
});

typedef _ClassifiedLegacyRelatedCell = ({
  String sourceWordId,
  String sourceColumn,
  String targetRawValue,
  String classification,
});

typedef _LegacyRelatedCellKey = ({String sourceWordId, String sourceColumn});

class DatabaseService {
  static Database? _database;
  static String? _dataRootOverrideForTest;

  /// 초기 상태(골든) DB 파일명
  static const String _seedDbFileName = 'reshet_seed.db';

  /// Android 앱 번들에 포함되는 초기 DB asset 경로
  static const String _seedDbAssetPath = 'data/reshet_seed.db';

  /// 앱이 실제로 수정하는 작업용 DB 파일명
  static const String _workDbFileName = 'reshet_work.db';

  /// 과거 파일명 호환(기존 사용 중인 DB)
  static const String _legacySeedFileName = 'bbwdb_20260106.db';

  static const String _legacyRelatedArchiveTableName =
      'WORD_LEGACY_RELATED_VALUE';
  static const String _legacyRelatedPreservationState = 'unresolved_legacy';
  static const String _legacyRelatedSourceTable = 'WORD_TABLE';
  static const List<String> _legacyRelatedColumns = [
    '관련1',
    '관련2',
    '관련3',
    '관련4',
    '관련5',
    '관련6',
    '관련7',
  ];
  static const List<String> _legacyMeaningColumns = [
    '의미1',
    '의미2',
    '의미3',
    '의미4',
    '의미5',
    '의미6',
    '의미7',
  ];
  static const Set<_LegacyRelatedCell> _approvedLegacyRelatedDiscards = {
    (
      sourceWordId: 'G1589_0000',
      sourceColumn: '관련1',
      targetRawValue: 'G1589_0000',
    ),
    (
      sourceWordId: 'G1696_0000',
      sourceColumn: '관련1',
      targetRawValue: 'G1696_0000',
    ),
    (
      sourceWordId: 'G2538_0000',
      sourceColumn: '관련1',
      targetRawValue: 'G2538_0000',
    ),
    (
      sourceWordId: 'G4173_0000',
      sourceColumn: '관련2',
      targetRawValue: 'G4173_0000',
    ),
    (
      sourceWordId: 'G4449_0000',
      sourceColumn: '관련1',
      targetRawValue: 'G4449_0000',
    ),
  };
  static const String _legacyRelatedArchiveTableDdl = '''
    CREATE TABLE WORD_LEGACY_RELATED_VALUE (
      source_word_id TEXT NOT NULL,
      source_column TEXT NOT NULL CHECK (
        source_column IN (
          '관련1',
          '관련2',
          '관련3',
          '관련4',
          '관련5',
          '관련6',
          '관련7'
        )
      ),
      target_raw_value TEXT NOT NULL,
      preservation_state TEXT NOT NULL CHECK (
        preservation_state = 'unresolved_legacy'
      ),
      source_table TEXT NOT NULL CHECK (
        source_table = 'WORD_TABLE'
      ),
      PRIMARY KEY (source_word_id, source_column)
    )
  ''';
  static const String _legacyRelatedCellsCte = '''
    legacy_cells(source_word_id, source_column, target_raw_value) AS (
      SELECT id, '관련1', [관련1]
      FROM WORD_TABLE
      WHERE [관련1] IS NOT NULL
      UNION ALL
      SELECT id, '관련2', [관련2]
      FROM WORD_TABLE
      WHERE [관련2] IS NOT NULL
      UNION ALL
      SELECT id, '관련3', [관련3]
      FROM WORD_TABLE
      WHERE [관련3] IS NOT NULL
      UNION ALL
      SELECT id, '관련4', [관련4]
      FROM WORD_TABLE
      WHERE [관련4] IS NOT NULL
      UNION ALL
      SELECT id, '관련5', [관련5]
      FROM WORD_TABLE
      WHERE [관련5] IS NOT NULL
      UNION ALL
      SELECT id, '관련6', [관련6]
      FROM WORD_TABLE
      WHERE [관련6] IS NOT NULL
      UNION ALL
      SELECT id, '관련7', [관련7]
      FROM WORD_TABLE
      WHERE [관련7] IS NOT NULL
    )
  ''';
  static const String _approvedLegacyRelatedDiscardPredicate = '''
    (
      source_word_id = 'G1589_0000' AND
      source_column = '관련1' AND
      target_raw_value = 'G1589_0000'
    ) OR (
      source_word_id = 'G1696_0000' AND
      source_column = '관련1' AND
      target_raw_value = 'G1696_0000'
    ) OR (
      source_word_id = 'G2538_0000' AND
      source_column = '관련1' AND
      target_raw_value = 'G2538_0000'
    ) OR (
      source_word_id = 'G4173_0000' AND
      source_column = '관련2' AND
      target_raw_value = 'G4173_0000'
    ) OR (
      source_word_id = 'G4449_0000' AND
      source_column = '관련1' AND
      target_raw_value = 'G4449_0000'
    )
  ''';

  static const Map<String, String> _wordRelationIndexDefinitions = {
    'idx_word_relation_signature_lookup': '''
      CREATE INDEX idx_word_relation_signature_lookup
      ON WORD_RELATION(
        word_id_1,
        word_id_2,
        COALESCE(relation_type, ''),
        COALESCE(direction_code, 'unknown')
      )
    ''',
    'idx_word_relation_pair_type_direction_unique': '''
      CREATE UNIQUE INDEX idx_word_relation_pair_type_direction_unique
      ON WORD_RELATION(
        word_id_1,
        word_id_2,
        COALESCE(relation_type, ''),
        COALESCE(direction_code, 'unknown')
      )
    ''',
  };

  static const List<
    ({String code, String label, String description, int sortOrder})
  >
  _relationCategoryDefinitions = [
    (
      code: 'semantic',
      label: '개념 관계',
      description: '의미상의 유사, 대조, 포함 관계를 나타내는 상위 분류',
      sortOrder: 1,
    ),
    (
      code: 'lexical',
      label: '어휘 관계',
      description: '단어 간 어휘 대응 관계를 나타내는 상위 분류',
      sortOrder: 2,
    ),
    (
      code: 'morphological',
      label: '형태 관계',
      description: '형태 변화와 단어 형성 관계를 나타내는 상위 분류',
      sortOrder: 3,
    ),
    (
      code: 'etymological',
      label: '어원 관계',
      description: '기원, 어근, 차용 관계를 나타내는 상위 분류',
      sortOrder: 4,
    ),
    (
      code: 'phonological',
      label: '음운 관계',
      description: '발음과 음운 변동 관계를 나타내는 상위 분류',
      sortOrder: 5,
    ),
    (
      code: 'transliteration',
      label: '음역 관계',
      description: '문자 체계 사이의 음역 관계를 나타내는 상위 분류',
      sortOrder: 6,
    ),
    (
      code: 'translation',
      label: '번역 관계',
      description: '의미 전달을 위한 번역 관계를 나타내는 상위 분류',
      sortOrder: 7,
    ),
    (
      code: 'unspecified',
      label: '미분류 관계',
      description: '기존 데이터 호환을 위해 유지하는 분류되지 않은 관계',
      sortOrder: 999,
    ),
  ];

  static const List<
    ({
      String code,
      String categoryCode,
      String label,
      String description,
      int sortOrder,
    })
  >
  _relationTypeDefinitions = [
    (
      code: 'similar',
      categoryCode: 'semantic',
      label: '의미 유사',
      description: '의미가 비슷하게 대응되는 관계',
      sortOrder: 1,
    ),
    (
      code: 'contrast',
      categoryCode: 'semantic',
      label: '의미 대조',
      description: '의미가 서로 대조되는 관계',
      sortOrder: 2,
    ),
    (
      code: 'broader',
      categoryCode: 'semantic',
      label: '상위 개념',
      description: '더 넓은 범주의 의미를 가리키는 관계',
      sortOrder: 3,
    ),
    (
      code: 'narrower',
      categoryCode: 'semantic',
      label: '하위 개념',
      description: '더 좁은 범주의 의미를 가리키는 관계',
      sortOrder: 4,
    ),
    (
      code: 'synonym',
      categoryCode: 'lexical',
      label: '동의어',
      description: '서로 바꾸어 쓸 수 있을 정도로 뜻이 가까운 관계',
      sortOrder: 1,
    ),
    (
      code: 'antonym',
      categoryCode: 'lexical',
      label: '반의어',
      description: '뜻이 서로 반대되는 관계',
      sortOrder: 2,
    ),
    (
      code: 'hypernym',
      categoryCode: 'lexical',
      label: '상위어',
      description: '더 넓은 어휘 범주에 속하는 관계',
      sortOrder: 3,
    ),
    (
      code: 'hyponym',
      categoryCode: 'lexical',
      label: '하위어',
      description: '더 구체적인 어휘 범주에 속하는 관계',
      sortOrder: 4,
    ),
    (
      code: 'derived',
      categoryCode: 'morphological',
      label: '파생어',
      description: '파생에 의해 연결되는 단어 형성 관계',
      sortOrder: 1,
    ),
    (
      code: 'inflected',
      categoryCode: 'morphological',
      label: '굴절형',
      description: '활용이나 굴절에 의해 연결되는 형태 관계',
      sortOrder: 2,
    ),
    (
      code: 'variant',
      categoryCode: 'morphological',
      label: '형태 변이',
      description: '철자나 형태가 달라진 이형 관계',
      sortOrder: 3,
    ),
    (
      code: 'compound',
      categoryCode: 'morphological',
      label: '합성',
      description: '둘 이상의 어휘 요소가 결합해 이루어진 단어 형성 관계',
      sortOrder: 4,
    ),
    (
      code: 'root_shared',
      categoryCode: 'etymological',
      label: '공통 어근',
      description: '공통된 어근을 공유하는 관계',
      sortOrder: 1,
    ),
    (
      code: 'borrowed_from',
      categoryCode: 'etymological',
      label: '차용어 관계',
      description: '언어 간 차용으로 연결되는 관계',
      sortOrder: 2,
    ),
    (
      code: 'loan_translation',
      categoryCode: 'etymological',
      label: '번역 차용',
      description: '표현 요소를 번역해 받아들인 차용 관계',
      sortOrder: 3,
    ),
    (
      code: 'root-related',
      categoryCode: 'etymological',
      label: '어근 관련',
      description: '레거시 데이터 호환을 위해 유지하는 어근 관련 관계',
      sortOrder: 999,
    ),
    (
      code: 'sound_similar',
      categoryCode: 'phonological',
      label: '발음 유사',
      description: '발음이 서로 유사하게 들리는 관계',
      sortOrder: 1,
    ),
    (
      code: 'sound_shift',
      categoryCode: 'phonological',
      label: '음운 변화',
      description: '음운 변동으로 이어지는 관계',
      sortOrder: 2,
    ),
    (
      code: 'direct_transliteration',
      categoryCode: 'transliteration',
      label: '직접 음역',
      description: '원어의 음을 직접 대응해 옮긴 관계',
      sortOrder: 1,
    ),
    (
      code: 'approx_transliteration',
      categoryCode: 'transliteration',
      label: '근사 음역',
      description: '음운 차이를 반영해 가깝게 옮긴 관계',
      sortOrder: 2,
    ),
    (
      code: 'conventional_transliteration',
      categoryCode: 'transliteration',
      label: '관용 음역',
      description: '관용적으로 굳어진 음역 관계',
      sortOrder: 3,
    ),
    (
      code: 'literal_translation',
      categoryCode: 'translation',
      label: '직역',
      description: '표현을 가능한 한 문자 그대로 옮긴 번역 관계',
      sortOrder: 1,
    ),
    (
      code: 'semantic_translation',
      categoryCode: 'translation',
      label: '의역',
      description: '의미 대응을 중심으로 옮긴 번역 관계',
      sortOrder: 2,
    ),
    (
      code: 'interpretive_translation',
      categoryCode: 'translation',
      label: '풀이 번역',
      description: '의미 풀이를 보완해 옮긴 번역 관계',
      sortOrder: 3,
    ),
    (
      code: 'related',
      categoryCode: 'unspecified',
      label: '일반 관련',
      description: '레거시 데이터 호환을 위해 유지하는 일반 관련 관계',
      sortOrder: 1,
    ),
  ];

  static const List<
    ({String code, String label, String description, int sortOrder})
  >
  _relationStatusDefinitions = [
    (
      code: 'inferred',
      label: '기존 데이터 기반',
      description:
          '기존 데이터와 기존 처리 경로에서 보존된 관계 상태다. 이 값은 관계 유형·방향·근거가 현재 기준에서 독립적으로 확정·검증되었음을 뜻하지 않는다.',
      sortOrder: 7,
    ),
  ];

  @visibleForTesting
  static void setDataRootOverrideForTest(String? dataRootPath) {
    _dataRootOverrideForTest = dataRootPath;
  }

  @visibleForTesting
  static String resolveDataDirPathForTest({
    required bool isAndroid,
    required bool isWindows,
    required bool isDebug,
    required String currentDirectoryPath,
    required String resolvedExecutablePath,
    required String systemTempParentPath,
    String? dataRootOverrideForTest,
  }) {
    return _resolveDataDirPath(
      isAndroid: isAndroid,
      isWindows: isWindows,
      isDebug: isDebug,
      currentDirectoryPath: currentDirectoryPath,
      resolvedExecutablePath: resolvedExecutablePath,
      systemTempParentPath: systemTempParentPath,
      dataRootOverrideForTest: dataRootOverrideForTest,
    );
  }

  /// data 폴더 경로.
  /// Windows Debug는 실행 위치와 무관하게 프로젝트 루트 data 폴더를 사용하고,
  /// Android는 앱 전용 내부 저장소를 사용한다.
  static Future<String> _dataDirPath() async {
    return _resolveDataDirPath(
      isAndroid: Platform.isAndroid,
      isWindows: Platform.isWindows,
      isDebug: kDebugMode,
      currentDirectoryPath: Directory.current.path,
      resolvedExecutablePath: Platform.resolvedExecutable,
      systemTempParentPath: Directory.systemTemp.parent.path,
      dataRootOverrideForTest: _dataRootOverrideForTest,
    );
  }

  static String _resolveDataDirPath({
    required bool isAndroid,
    required bool isWindows,
    required bool isDebug,
    required String currentDirectoryPath,
    required String resolvedExecutablePath,
    required String systemTempParentPath,
    required String? dataRootOverrideForTest,
  }) {
    if (dataRootOverrideForTest != null) {
      return dataRootOverrideForTest;
    }

    if (isAndroid) {
      return join(systemTempParentPath, 'files', 'data');
    }

    if (isWindows && isDebug) {
      return _windowsDebugProjectDataDirPath(
        currentDirectoryPath: currentDirectoryPath,
        resolvedExecutablePath: resolvedExecutablePath,
      );
    }

    return join(currentDirectoryPath, 'data');
  }

  static String _windowsDebugProjectDataDirPath({
    required String currentDirectoryPath,
    required String resolvedExecutablePath,
  }) {
    final currentRoot = _findProjectRootAtOrAbove(currentDirectoryPath);
    if (currentRoot != null) {
      return join(currentRoot.path, 'data');
    }

    if (resolvedExecutablePath.trim().isNotEmpty) {
      final executableRoot = _findProjectRootAtOrAbove(
        File(resolvedExecutablePath).parent.path,
      );
      if (executableRoot != null) {
        return join(executableRoot.path, 'data');
      }
    }

    throw StateError(
      'Windows Debug project root data directory를 찾을 수 없습니다. '
      'currentDirectory=$currentDirectoryPath, '
      'resolvedExecutable=$resolvedExecutablePath',
    );
  }

  static Directory? _findProjectRootAtOrAbove(String startPath) {
    var currentPath = normalize(absolute(startPath));

    while (true) {
      final current = Directory(currentPath);
      if (_isProjectRoot(current)) {
        return current;
      }

      final parentPath = dirname(currentPath);
      if (parentPath == currentPath) {
        return null;
      }
      currentPath = parentPath;
    }
  }

  static bool _isProjectRoot(Directory directory) {
    final dataDir = Directory(join(directory.path, 'data'));
    return File(join(directory.path, 'pubspec.yaml')).existsSync() &&
        dataDir.existsSync() &&
        (File(join(dataDir.path, _seedDbFileName)).existsSync() ||
            File(join(dataDir.path, _workDbFileName)).existsSync());
  }

  static Future<String> _seedDbPath() async {
    final dataDir = await _dataDirPath();
    final seed = join(dataDir, _seedDbFileName);
    final legacy = join(dataDir, _legacySeedFileName);

    // seed가 없고 legacy가 있으면 legacy를 seed로 취급(rename 없이도 동작)
    if (!File(seed).existsSync() && File(legacy).existsSync()) {
      return legacy;
    }
    return seed;
  }

  static Future<String> _workDbPath() async {
    return join(await _dataDirPath(), _workDbFileName);
  }

  /// 복원 staging 파일을 현재 work DB와 같은 filesystem에 배치하기 위한 제한적 경계다.
  static Future<String> dataDirectoryPath() => _dataDirPath();

  /// 현재 application work DB의 실제 경로를 반환한다.
  static Future<String> workDatabasePath() => _workDbPath();

  @visibleForTesting
  static bool get hasOpenDatabaseForTest => _database != null;

  static Future<File> _ensureSeedDbFile(String seedPath) async {
    final seedFile = File(seedPath);
    if (seedFile.existsSync()) {
      return seedFile;
    }

    if (Platform.isAndroid) {
      await _copyBundledSeedTo(seedPath);
      return File(seedPath);
    }

    throw Exception('초기 DB(seed)를 찾을 수 없습니다: $seedPath');
  }

  static Future<void> _copyBundledSeedTo(String seedPath) async {
    final seedFile = File(seedPath);
    await Directory(dirname(seedPath)).create(recursive: true);

    final seedBytes = await rootBundle.load(_seedDbAssetPath);
    await seedFile.writeAsBytes(
      Uint8List.view(
        seedBytes.buffer,
        seedBytes.offsetInBytes,
        seedBytes.lengthInBytes,
      ),
      flush: true,
    );
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

    작업용 reshet_work.db를 열고 runtime schema를 보장한다.
    작업용 DB가 없으면 초기 seed DB를 복사해 생성한다.
  */
  static Future<Database> openDatabaseFile() async {
    if (_database != null) {
      return _database!;
    }

    final seedPath = await _seedDbPath();
    final workPath = await _workDbPath();

    // work DB가 없으면 seed를 복사하여 work 생성
    if (!File(workPath).existsSync()) {
      final seedFile = await _ensureSeedDbFile(seedPath);
      await Directory(dirname(workPath)).create(recursive: true);
      await seedFile.copy(workPath);
    }

    Database? openedDatabase;
    try {
      openedDatabase = await databaseFactory.openDatabase(workPath);
      await ensureRuntimeSchema(openedDatabase);
      _database = openedDatabase;
      return openedDatabase;
    } catch (_) {
      if (openedDatabase != null && openedDatabase.isOpen) {
        await openedDatabase.close();
      }
      _database = null;
      rethrow;
    }
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
    final seedPath = await _seedDbPath();
    final workPath = await _workDbPath();
    final seedFile = await _ensureSeedDbFile(seedPath);

    // 열려있으면 닫기
    await closeDatabase();

    // 백업
    final workFile = File(workPath);
    if (backup && workFile.existsSync()) {
      final backupsDir = Directory(join(await _dataDirPath(), 'backups'));
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
    await Directory(dirname(workPath)).create(recursive: true);
    await seedFile.copy(workPath);

    // 다시 열기(이후 쿼리 즉시 가능)
    Database? openedDatabase;
    try {
      openedDatabase = await databaseFactory.openDatabase(workPath);
      await ensureRuntimeSchema(openedDatabase);
      _database = openedDatabase;
    } catch (_) {
      if (openedDatabase != null && openedDatabase.isOpen) {
        await openedDatabase.close();
      }
      _database = null;
      rethrow;
    }
  }

  /// 이미 열린 임의의 DB connection에 현재 runtime schema 보정을 적용한다.
  /// 외부 복원 원본에는 사용하지 않고 앱 소유 staging/work DB에만 사용한다.
  static Future<void> ensureRuntimeSchema(Database database) async {
    await _ensureLegacyRelatedColumnsMigration(database);
    await _ensureWordRelationV2Columns(database);
    await _ensureWordRelationIndexes(database);
    await _ensureHistoryTable(database);
    await _ensureRelationLookupMetadata(database);
    await _ensureWordExpressionSetSchema(database);
    await _ensureWordMeaningSetSchema(database);
  }

  /// restore 원본 사전검증에서 full-legacy 또는 migration 완료 상태만 허용한다.
  static Future<void> validateLegacyRelatedRestoreCandidate(
    Database database,
  ) async {
    await _validateLegacyRelatedSchemaState(database, allowFullLegacy: true);
  }

  /// runtime ensure 이후에는 legacy 컬럼이 없고 유효한 격리 테이블이 있어야 한다.
  static Future<void> validateLegacyRelatedRuntimeSchema(
    Database database,
  ) async {
    await _validateLegacyRelatedSchemaState(database, allowFullLegacy: false);
  }

  /// restore 원본은 meaning 물리 컬럼이 모두 있거나 모두 제거된 상태만 허용한다.
  static Future<void> validateLegacyMeaningRestoreCandidate(
    Database database,
  ) async {
    await _validateLegacyMeaningSchemaState(database, allowFullLegacy: true);
  }

  /// runtime ensure 이후에는 meaning 물리 컬럼이 없어야 한다.
  static Future<void> validateLegacyMeaningRuntimeSchema(
    Database database,
  ) async {
    await _validateLegacyMeaningSchemaState(database, allowFullLegacy: false);
  }

  static Future<void> _ensureLegacyRelatedColumnsMigration(Database db) async {
    try {
      await db.transaction((txn) async {
        final presentLegacyColumns = await _presentLegacyRelatedColumns(txn);
        final archiveExists = await _tableExists(
          txn,
          _legacyRelatedArchiveTableName,
        );

        if (presentLegacyColumns.isEmpty) {
          if (!archiveExists) {
            throw StateError(
              'legacy 컬럼과 $_legacyRelatedArchiveTableName이 모두 없습니다.',
            );
          }
          await _validateLegacyRelatedArchiveTable(txn);
          return;
        }

        if (presentLegacyColumns.length != _legacyRelatedColumns.length) {
          throw StateError(
            'legacy 관련 컬럼이 일부만 존재합니다: '
            '${presentLegacyColumns.join(', ')}',
          );
        }

        final relationSnapshotBefore = await _wordRelationSnapshot(txn);
        if (!archiveExists) {
          await txn.execute(_legacyRelatedArchiveTableDdl);
        }
        await _validateLegacyRelatedArchiveTable(txn);

        final classifiedCells = await _readClassifiedLegacyRelatedCells(txn);
        final unresolvedCells = classifiedCells
            .where((cell) => cell.classification == 'unresolved_legacy')
            .map(
              (cell) => (
                sourceWordId: cell.sourceWordId,
                sourceColumn: cell.sourceColumn,
                targetRawValue: cell.targetRawValue,
              ),
            )
            .toList(growable: false);
        await _validateExistingArchiveRowsAgainstExpected(
          txn,
          unresolvedCells,
          requireComplete: false,
        );

        final existingArchiveKeys = (await _readLegacyRelatedArchiveRows(txn))
            .map(
              (row) => (
                sourceWordId: row.sourceWordId,
                sourceColumn: row.sourceColumn,
              ),
            )
            .toSet();
        for (final cell in unresolvedCells) {
          final key = (
            sourceWordId: cell.sourceWordId,
            sourceColumn: cell.sourceColumn,
          );
          if (existingArchiveKeys.contains(key)) {
            continue;
          }
          await txn.insert(_legacyRelatedArchiveTableName, {
            'source_word_id': cell.sourceWordId,
            'source_column': cell.sourceColumn,
            'target_raw_value': cell.targetRawValue,
            'preservation_state': _legacyRelatedPreservationState,
            'source_table': _legacyRelatedSourceTable,
          });
        }

        await _validateExistingArchiveRowsAgainstExpected(
          txn,
          unresolvedCells,
          requireComplete: true,
        );
        _validateLegacyRelatedClassifications(classifiedCells);

        for (final column in _legacyRelatedColumns) {
          await txn.execute(
            'ALTER TABLE WORD_TABLE DROP COLUMN ${_quoteIdentifier(column)}',
          );
        }

        final remainingLegacyColumns = await _presentLegacyRelatedColumns(txn);
        if (remainingLegacyColumns.isNotEmpty) {
          throw StateError(
            'legacy 관련 컬럼 제거가 완료되지 않았습니다: '
            '${remainingLegacyColumns.join(', ')}',
          );
        }
        await _validateLegacyRelatedArchiveTable(txn);
        await _validateExistingArchiveRowsAgainstExpected(
          txn,
          unresolvedCells,
          requireComplete: true,
        );

        final relationSnapshotAfter = await _wordRelationSnapshot(txn);
        if (relationSnapshotAfter != relationSnapshotBefore) {
          throw StateError('WORD_RELATION이 legacy 컬럼 migration 중 변경됐습니다.');
        }
      });
    } catch (error) {
      throw StateError('관련 legacy migration 실패: $error');
    }
  }

  static Future<void> _validateLegacyRelatedSchemaState(
    DatabaseExecutor db, {
    required bool allowFullLegacy,
  }) async {
    final presentLegacyColumns = await _presentLegacyRelatedColumns(db);
    final archiveExists = await _tableExists(
      db,
      _legacyRelatedArchiveTableName,
    );

    if (presentLegacyColumns.isNotEmpty &&
        presentLegacyColumns.length != _legacyRelatedColumns.length) {
      throw StateError(
        '관련 legacy 컬럼이 일부만 존재합니다: '
        '${presentLegacyColumns.join(', ')}',
      );
    }

    if (presentLegacyColumns.length == _legacyRelatedColumns.length) {
      if (!allowFullLegacy) {
        throw StateError('관련 legacy 컬럼 7개가 migration 이후에도 남아 있습니다.');
      }
      if (archiveExists) {
        await _validateLegacyRelatedArchiveTable(db);
        final classifiedCells = await _readClassifiedLegacyRelatedCells(db);
        final unresolvedCells = classifiedCells
            .where((cell) => cell.classification == 'unresolved_legacy')
            .map(
              (cell) => (
                sourceWordId: cell.sourceWordId,
                sourceColumn: cell.sourceColumn,
                targetRawValue: cell.targetRawValue,
              ),
            )
            .toList(growable: false);
        await _validateExistingArchiveRowsAgainstExpected(
          db,
          unresolvedCells,
          requireComplete: false,
        );
      }
      return;
    }

    if (!archiveExists) {
      throw StateError(
        '관련 legacy 컬럼이 없지만 $_legacyRelatedArchiveTableName도 없습니다.',
      );
    }
    await _validateLegacyRelatedArchiveTable(db);
  }

  static Future<Set<String>> _presentLegacyRelatedColumns(
    DatabaseExecutor db,
  ) async {
    final tableColumns = await db.rawQuery("PRAGMA table_info('WORD_TABLE')");
    final names = tableColumns
        .map((row) => row['name'])
        .whereType<String>()
        .toSet();
    return _legacyRelatedColumns.where(names.contains).toSet();
  }

  static Future<bool> _tableExists(
    DatabaseExecutor db,
    String tableName,
  ) async {
    final rows = await db.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name = ?
      ''',
      [tableName],
    );
    return rows.isNotEmpty;
  }

  static Future<void> _validateLegacyRelatedArchiveTable(
    DatabaseExecutor db,
  ) async {
    final schemaRows = await db.rawQuery(
      '''
      SELECT sql
      FROM sqlite_master
      WHERE type = 'table'
        AND name = ?
      ''',
      [_legacyRelatedArchiveTableName],
    );
    if (schemaRows.length != 1) {
      throw StateError('$_legacyRelatedArchiveTableName table 정의를 찾을 수 없습니다.');
    }

    final actualSql = schemaRows.single['sql'] as String?;
    if (actualSql == null ||
        _normalizeIndexSql(actualSql) !=
            _normalizeIndexSql(_legacyRelatedArchiveTableDdl)) {
      throw StateError('$_legacyRelatedArchiveTableName DDL 계약이 일치하지 않습니다.');
    }

    final columns = await db.rawQuery(
      "PRAGMA table_info('$_legacyRelatedArchiveTableName')",
    );
    const expectedColumns = [
      (name: 'source_word_id', pk: 1),
      (name: 'source_column', pk: 2),
      (name: 'target_raw_value', pk: 0),
      (name: 'preservation_state', pk: 0),
      (name: 'source_table', pk: 0),
    ];
    if (columns.length != expectedColumns.length) {
      throw StateError('$_legacyRelatedArchiveTableName 컬럼 수가 일치하지 않습니다.');
    }
    for (var index = 0; index < expectedColumns.length; index++) {
      final actual = columns[index];
      final expected = expectedColumns[index];
      if (actual['name'] != expected.name ||
          (actual['type'] ?? '').toString().toUpperCase() != 'TEXT' ||
          actual['notnull'] != 1 ||
          actual['dflt_value'] != null ||
          actual['pk'] != expected.pk) {
        throw StateError(
          '$_legacyRelatedArchiveTableName 컬럼 계약이 일치하지 않습니다: '
          '${expected.name}',
        );
      }
    }

    final foreignKeys = await db.rawQuery(
      "PRAGMA foreign_key_list('$_legacyRelatedArchiveTableName')",
    );
    if (foreignKeys.isNotEmpty) {
      throw StateError('$_legacyRelatedArchiveTableName에는 FK를 둘 수 없습니다.');
    }

    final indexes = await db.rawQuery(
      "PRAGMA index_list('$_legacyRelatedArchiveTableName')",
    );
    if (indexes.any((row) => row['origin'] != 'pk')) {
      throw StateError(
        '$_legacyRelatedArchiveTableName에는 PK 외 index를 둘 수 없습니다.',
      );
    }

    final triggers = await db.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'trigger'
        AND tbl_name = ?
      ''',
      [_legacyRelatedArchiveTableName],
    );
    if (triggers.isNotEmpty) {
      throw StateError('$_legacyRelatedArchiveTableName에는 trigger를 둘 수 없습니다.');
    }

    final views = await db.rawQuery('''
      SELECT name, sql
      FROM sqlite_master
      WHERE type = 'view'
    ''');
    final archiveName = _legacyRelatedArchiveTableName.toLowerCase();
    if (views.any(
      (row) =>
          (row['sql'] ?? '').toString().toLowerCase().contains(archiveName),
    )) {
      throw StateError('$_legacyRelatedArchiveTableName을 사용하는 view를 둘 수 없습니다.');
    }

    await _readLegacyRelatedArchiveRows(db);
  }

  static Future<List<_ClassifiedLegacyRelatedCell>>
  _readClassifiedLegacyRelatedCells(DatabaseExecutor db) async {
    final rows = await db.rawQuery('''
      WITH $_legacyRelatedCellsCte
      SELECT
        source_word_id,
        source_column,
        target_raw_value,
        CASE
          WHEN ($_approvedLegacyRelatedDiscardPredicate)
            THEN 'approved_discard'
          WHEN EXISTS (
            SELECT 1
            FROM WORD_RELATION AS relation
            WHERE (
              relation.word_id_1 = legacy_cells.source_word_id AND
              relation.word_id_2 = legacy_cells.target_raw_value
            ) OR (
              relation.word_id_2 = legacy_cells.source_word_id AND
              relation.word_id_1 = legacy_cells.target_raw_value
            )
          )
            THEN 'normalized_relation'
          ELSE 'unresolved_legacy'
        END AS migration_classification
      FROM legacy_cells
      ORDER BY source_word_id, source_column
    ''');

    return rows
        .map(
          (row) => (
            sourceWordId: _requireLegacyRelatedText(row, 'source_word_id'),
            sourceColumn: _requireLegacyRelatedText(row, 'source_column'),
            targetRawValue: _requireLegacyRelatedText(row, 'target_raw_value'),
            classification: _requireLegacyRelatedText(
              row,
              'migration_classification',
            ),
          ),
        )
        .toList(growable: false);
  }

  static Future<List<_LegacyRelatedCell>> _readLegacyRelatedArchiveRows(
    DatabaseExecutor db,
  ) async {
    final rows = await db.query(
      _legacyRelatedArchiveTableName,
      columns: const [
        'source_word_id',
        'source_column',
        'target_raw_value',
        'preservation_state',
        'source_table',
      ],
      orderBy: 'source_word_id ASC, source_column ASC',
    );

    final result = <_LegacyRelatedCell>[];
    for (final row in rows) {
      final sourceWordId = _requireLegacyRelatedText(row, 'source_word_id');
      final sourceColumn = _requireLegacyRelatedText(row, 'source_column');
      final targetRawValue = _requireLegacyRelatedText(row, 'target_raw_value');
      final preservationState = _requireLegacyRelatedText(
        row,
        'preservation_state',
      );
      final sourceTable = _requireLegacyRelatedText(row, 'source_table');

      if (!_legacyRelatedColumns.contains(sourceColumn)) {
        throw StateError('허용되지 않은 legacy source column입니다: $sourceColumn');
      }
      if (preservationState != _legacyRelatedPreservationState) {
        throw StateError(
          '허용되지 않은 legacy preservation state입니다: '
          '$preservationState',
        );
      }
      if (sourceTable != _legacyRelatedSourceTable) {
        throw StateError('허용되지 않은 legacy source table입니다: $sourceTable');
      }

      final cell = (
        sourceWordId: sourceWordId,
        sourceColumn: sourceColumn,
        targetRawValue: targetRawValue,
      );
      if (_approvedLegacyRelatedDiscards.contains(cell)) {
        throw StateError(
          '승인된 폐기 셀이 archive에 존재합니다: '
          '$sourceWordId / $sourceColumn / $targetRawValue',
        );
      }
      result.add(cell);
    }
    return result;
  }

  static Future<void> _validateExistingArchiveRowsAgainstExpected(
    DatabaseExecutor db,
    List<_LegacyRelatedCell> expectedRows, {
    required bool requireComplete,
  }) async {
    final expectedByKey = <_LegacyRelatedCellKey, _LegacyRelatedCell>{
      for (final row in expectedRows)
        (sourceWordId: row.sourceWordId, sourceColumn: row.sourceColumn): row,
    };
    if (expectedByKey.length != expectedRows.length) {
      throw StateError('미해결 legacy 분류에 중복 source/slot이 있습니다.');
    }

    final actualRows = await _readLegacyRelatedArchiveRows(db);
    final actualByKey = <_LegacyRelatedCellKey, _LegacyRelatedCell>{};
    for (final actual in actualRows) {
      final key = (
        sourceWordId: actual.sourceWordId,
        sourceColumn: actual.sourceColumn,
      );
      final expected = expectedByKey[key];
      if (expected == null) {
        throw StateError(
          'archive에 원본 미해결 분류와 대응되지 않는 행이 있습니다: '
          '${actual.sourceWordId} / ${actual.sourceColumn}',
        );
      }
      if (actual != expected) {
        throw StateError(
          'archive 값이 원본과 충돌합니다: '
          '${actual.sourceWordId} / ${actual.sourceColumn}',
        );
      }
      actualByKey[key] = actual;
    }

    if (requireComplete && actualByKey.length != expectedByKey.length) {
      final missing = expectedByKey.keys
          .where((key) => !actualByKey.containsKey(key))
          .map((key) => '${key.sourceWordId}/${key.sourceColumn}')
          .join(', ');
      throw StateError('archive에 미해결 legacy 값이 누락됐습니다: $missing');
    }
  }

  static void _validateLegacyRelatedClassifications(
    List<_ClassifiedLegacyRelatedCell> cells,
  ) {
    const allowedClassifications = {
      'approved_discard',
      'normalized_relation',
      'unresolved_legacy',
    };
    for (final cell in cells) {
      if (!allowedClassifications.contains(cell.classification)) {
        throw StateError(
          '분류되지 않은 legacy 셀이 있습니다: '
          '${cell.sourceWordId} / ${cell.sourceColumn}',
        );
      }
    }
  }

  static String _requireLegacyRelatedText(
    Map<String, Object?> row,
    String key,
  ) {
    final value = row[key];
    if (value is! String) {
      throw StateError('legacy 값이 TEXT가 아닙니다: $key=$value');
    }
    return value;
  }

  static Future<String> _wordRelationSnapshot(DatabaseExecutor db) async {
    final rows = await db.rawQuery(
      'SELECT * FROM WORD_RELATION ORDER BY id ASC',
    );
    return jsonEncode(rows);
  }

  static String _quoteIdentifier(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }

  /// WORD_RELATION v2 컬럼 보장
  static Future<void> _ensureWordRelationV2Columns(Database db) async {
    final columns = await db.rawQuery("PRAGMA table_info('WORD_RELATION')");
    final names = columns.map((row) => row['name'] as String).toSet();

    if (!names.contains('direction_code')) {
      await db.execute('''
        ALTER TABLE WORD_RELATION
        ADD COLUMN direction_code TEXT NOT NULL DEFAULT 'unknown'
      ''');
    }

    if (!names.contains('description')) {
      await db.execute('''
        ALTER TABLE WORD_RELATION
        ADD COLUMN description TEXT
      ''');
    }

    if (!names.contains('relation_group_id')) {
      await db.execute('''
        ALTER TABLE WORD_RELATION
        ADD COLUMN relation_group_id TEXT
      ''');
    }
  }

  /// 새 UNIQUE 인덱스 기준과 동일한 signature 충돌 후보 조회
  static Future<List<Map<String, Object?>>> _findWordRelationSignatureConflicts(
    DatabaseExecutor db,
  ) async {
    return await db.rawQuery('''
      SELECT
        word_id_1,
        word_id_2,
        COALESCE(relation_type, '') AS relation_type_key,
        COALESCE(direction_code, 'unknown') AS direction_code_key,
        COUNT(*) AS duplicate_count
      FROM WORD_RELATION
      GROUP BY
        word_id_1,
        word_id_2,
        COALESCE(relation_type, ''),
        COALESCE(direction_code, 'unknown')
      HAVING COUNT(*) > 1
      ORDER BY duplicate_count DESC, word_id_1, word_id_2
    ''');
  }

  /// WORD_RELATION 테이블 v2 무결성/성능 보강
  /// 1) v1 pair-only 인덱스 제거
  /// 2) 정의가 다를 때만 signature 조회용 인덱스 교체
  /// 3) 충돌이 없을 때만 v2 UNIQUE 인덱스 생성
  /// 4) 조회 성능 인덱스 추가
  static Future<void> _ensureWordRelationIndexes(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('DROP INDEX IF EXISTS idx_word_relation_pair');
      await _ensureWordRelationIndex(txn, 'idx_word_relation_signature_lookup');

      final conflicts = await _findWordRelationSignatureConflicts(txn);

      // ignore: avoid_print
      print('[DB] WORD_RELATION v2 signature 충돌 후보: ${conflicts.length}건');

      if (conflicts.isEmpty) {
        await _ensureWordRelationIndex(
          txn,
          'idx_word_relation_pair_type_direction_unique',
        );
      } else {
        await _dropWordRelationIndexIfPresent(
          txn,
          'idx_word_relation_pair_type_direction_unique',
        );
      }

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

  static Future<void> _ensureWordRelationIndex(
    DatabaseExecutor db,
    String indexName,
  ) async {
    final expectedSql = _wordRelationIndexDefinitions[indexName]!;
    final existingSql = await _readIndexSql(db, indexName);
    if (existingSql != null &&
        _normalizeIndexSql(existingSql) == _normalizeIndexSql(expectedSql)) {
      return;
    }

    if (existingSql != null) {
      await db.execute('DROP INDEX $indexName');
    }
    await db.execute(expectedSql);
  }

  static Future<void> _dropWordRelationIndexIfPresent(
    DatabaseExecutor db,
    String indexName,
  ) async {
    if (await _readIndexSql(db, indexName) != null) {
      await db.execute('DROP INDEX $indexName');
    }
  }

  static Future<String?> _readIndexSql(
    DatabaseExecutor db,
    String indexName,
  ) async {
    final rows = await db.rawQuery(
      '''
      SELECT sql
      FROM sqlite_master
      WHERE type = 'index'
        AND name = ?
      ''',
      [indexName],
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.single['sql'] as String?;
  }

  static String _normalizeIndexSql(String sql) {
    final normalized = StringBuffer();
    var inStringLiteral = false;

    for (var index = 0; index < sql.length; index++) {
      final character = sql[index];
      if (character == "'") {
        normalized.write(character);
        final isEscapedQuote =
            inStringLiteral && index + 1 < sql.length && sql[index + 1] == "'";
        if (isEscapedQuote) {
          normalized.write(sql[index + 1]);
          index++;
        } else {
          inStringLiteral = !inStringLiteral;
        }
        continue;
      }

      if (inStringLiteral) {
        normalized.write(character);
      } else if (!_isSqlWhitespace(character)) {
        normalized.write(character.toLowerCase());
      }
    }

    return normalized.toString();
  }

  static bool _isSqlWhitespace(String character) {
    return character == ' ' ||
        character == '\n' ||
        character == '\r' ||
        character == '\t' ||
        character == '\f';
  }

  /// 변경 이력 테이블 보장
  static Future<void> _ensureHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS CHANGE_HISTORY (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id TEXT NOT NULL,
        action_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        before_json TEXT,
        after_json TEXT,
        created_at TEXT NOT NULL,
        undone_at TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_change_history_group
      ON CHANGE_HISTORY(group_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_change_history_undone
      ON CHANGE_HISTORY(undone_at, created_at)
    ''');
  }

  /// legacy seed/work DB에서도 현재 graph/read path가 요구하는
  /// normalized expression baseline을 사용할 수 있게 보장한다.
  static Future<void> _ensureWordExpressionSetSchema(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS word_expression_set (
          id INTEGER PRIMARY KEY,
          word_id TEXT NOT NULL,
          seq INTEGER NOT NULL,
          is_representative INTEGER NOT NULL,
          spelling TEXT NOT NULL,
          transliteration TEXT,
          pronunciation TEXT,
          pronunciation_notation TEXT CHECK (
            pronunciation_notation IS NULL OR pronunciation_notation IN (
              'strong_dictionary',
              'ipa_phonemic',
              'ipa_phonetic',
              'other',
              'unknown'
            )
          ),
          pronunciation_notation_name TEXT CHECK (
            pronunciation_notation_name IS NULL OR
            LENGTH(TRIM(pronunciation_notation_name)) > 0
          ),
          FOREIGN KEY (word_id) REFERENCES WORD_TABLE(id) ON DELETE CASCADE,
          CHECK (seq >= 1),
          CHECK (is_representative IN (0, 1)),
          CHECK (LENGTH(TRIM(spelling)) > 0),
          CHECK (transliteration IS NULL OR LENGTH(TRIM(transliteration)) > 0),
          CHECK (pronunciation IS NULL OR LENGTH(TRIM(pronunciation)) > 0)
        )
      ''');

      final columns = await txn.rawQuery(
        "PRAGMA table_info('word_expression_set')",
      );
      final columnNames = columns
          .map((row) => row['name'])
          .whereType<String>()
          .toSet();
      if (!columnNames.contains('pronunciation_notation')) {
        await txn.execute('''
          ALTER TABLE word_expression_set
          ADD COLUMN pronunciation_notation TEXT CHECK (
            pronunciation_notation IS NULL OR pronunciation_notation IN (
              'strong_dictionary',
              'ipa_phonemic',
              'ipa_phonetic',
              'other',
              'unknown'
            )
          )
        ''');
      }
      if (!columnNames.contains('pronunciation_notation_name')) {
        await txn.execute('''
          ALTER TABLE word_expression_set
          ADD COLUMN pronunciation_notation_name TEXT CHECK (
            pronunciation_notation_name IS NULL OR
            LENGTH(TRIM(pronunciation_notation_name)) > 0
          )
        ''');
      }

      await txn.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS ux_word_expression_set_word_seq
        ON word_expression_set(word_id, seq)
      ''');

      await txn.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS ux_word_expression_set_one_representative
        ON word_expression_set(word_id)
        WHERE is_representative = 1
      ''');

      final existingRows = await txn.rawQuery(
        'SELECT COUNT(*) AS row_count FROM word_expression_set',
      );
      final existingRowCount = existingRows.first['row_count'] as int;
      if (existingRowCount == 0) {
        await txn.execute('''
          WITH legacy_slots AS (
            SELECT
              id AS word_id,
              1 AS source_slot,
              TRIM(COALESCE([표기1], '')) AS spelling,
              TRIM(COALESCE([음역1], '')) AS transliteration,
              TRIM(COALESCE([발음1], '')) AS pronunciation
            FROM WORD_TABLE
            UNION ALL
            SELECT
              id,
              2,
              TRIM(COALESCE([표기2], '')),
              TRIM(COALESCE([음역2], '')),
              TRIM(COALESCE([발음2], ''))
            FROM WORD_TABLE
            UNION ALL
            SELECT
              id,
              3,
              TRIM(COALESCE([표기3], '')),
              TRIM(COALESCE([음역3], '')),
              TRIM(COALESCE([발음3], ''))
            FROM WORD_TABLE
            UNION ALL
            SELECT
              id,
              4,
              TRIM(COALESCE([표기4], '')),
              TRIM(COALESCE([음역4], '')),
              TRIM(COALESCE([발음4], ''))
            FROM WORD_TABLE
            UNION ALL
            SELECT
              id,
              5,
              TRIM(COALESCE([표기5], '')),
              TRIM(COALESCE([음역5], '')),
              TRIM(COALESCE([발음5], ''))
            FROM WORD_TABLE
            UNION ALL
            SELECT
              id,
              6,
              TRIM(COALESCE([표기6], '')),
              TRIM(COALESCE([음역6], '')),
              TRIM(COALESCE([발음6], ''))
            FROM WORD_TABLE
          ),
          expected_expression_set AS (
            SELECT
              word_id,
              ROW_NUMBER() OVER (PARTITION BY word_id ORDER BY source_slot)
                AS seq,
              spelling,
              NULLIF(transliteration, '') AS transliteration,
              NULLIF(pronunciation, '') AS pronunciation
            FROM legacy_slots
            WHERE spelling <> ''
          ),
          backfill_source AS (
            SELECT
              word_id,
              seq,
              CASE WHEN seq = 1 THEN 1 ELSE 0 END AS is_representative,
              spelling,
              transliteration,
              pronunciation
            FROM expected_expression_set
          )
          INSERT INTO word_expression_set (
            word_id,
            seq,
            is_representative,
            spelling,
            transliteration,
            pronunciation
          )
          SELECT
            word_id,
            seq,
            is_representative,
            spelling,
            transliteration,
            pronunciation
          FROM backfill_source
        ''');

        final backfilledRows = await txn.rawQuery(
          'SELECT COUNT(*) AS row_count FROM word_expression_set',
        );
        // ignore: avoid_print
        print(
          '[DB] word_expression_set baseline 보강: '
          '${backfilledRows.first['row_count']}건',
        );
      }

      final unknownBackfillCount = await txn.rawUpdate('''
        UPDATE word_expression_set
        SET pronunciation_notation = 'unknown'
        WHERE pronunciation IS NOT NULL
          AND pronunciation_notation IS NULL
      ''');
      final clearedMetadataCount = await txn.rawUpdate('''
        UPDATE word_expression_set
        SET pronunciation_notation = NULL,
            pronunciation_notation_name = NULL
        WHERE pronunciation IS NULL
          AND (
            pronunciation_notation IS NOT NULL OR
            pronunciation_notation_name IS NOT NULL
          )
      ''');
      // ignore: avoid_print
      print(
        '[DB] word_expression_set 발음 표기 방식 보강: '
        'unknown=$unknownBackfillCount건, metadata 정리=$clearedMetadataCount건',
      );
    });
  }

  /// legacy seed/work DB의 meaning slot을 필요할 때 한 번만 materialize한 뒤
  /// live schema에서 물리 컬럼을 제거한다.
  static Future<void> _ensureWordMeaningSetSchema(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS word_meaning_set (
          id INTEGER PRIMARY KEY,
          word_id TEXT NOT NULL,
          seq INTEGER NOT NULL,
          meaning TEXT NOT NULL,
          FOREIGN KEY (word_id) REFERENCES WORD_TABLE(id) ON DELETE CASCADE,
          CHECK (seq >= 1),
          CHECK (meaning <> '')
        )
      ''');

      await _rebuildWordMeaningSetIfSeqUpperBoundExists(txn);

      await txn.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS ux_word_meaning_set_word_seq
        ON word_meaning_set(word_id, seq)
      ''');

      final presentLegacyColumns = await _presentLegacyMeaningColumns(txn);
      if (presentLegacyColumns.isNotEmpty &&
          presentLegacyColumns.length != _legacyMeaningColumns.length) {
        throw StateError(
          'legacy 의미 컬럼이 일부만 존재합니다: '
          '${presentLegacyColumns.join(', ')}',
        );
      }
      if (presentLegacyColumns.isEmpty) {
        return;
      }

      final existingRows = await txn.rawQuery(
        'SELECT COUNT(*) AS row_count FROM word_meaning_set',
      );
      final existingRowCount = existingRows.first['row_count'] as int;
      if (existingRowCount == 0) {
        await txn.execute(_legacyMeaningMaterializationSql);
      }

      await _validateLegacyMeaningCoverage(txn);
      final canonicalSnapshotBefore = await _wordMeaningSnapshot(txn);

      for (final column in _legacyMeaningColumns) {
        await txn.execute(
          'ALTER TABLE WORD_TABLE DROP COLUMN ${_quoteIdentifier(column)}',
        );
      }

      final remainingLegacyColumns = await _presentLegacyMeaningColumns(txn);
      if (remainingLegacyColumns.isNotEmpty) {
        throw StateError(
          'legacy 의미 컬럼 제거가 완료되지 않았습니다: '
          '${remainingLegacyColumns.join(', ')}',
        );
      }

      final canonicalSnapshotAfter = await _wordMeaningSnapshot(txn);
      if (canonicalSnapshotAfter != canonicalSnapshotBefore) {
        throw StateError('canonical meaning이 물리 컬럼 제거 중 변경됐습니다.');
      }
    });
  }

  static const String _legacyMeaningMaterializationSql = '''
    WITH legacy_slots AS (
      SELECT id AS word_id, 1 AS seq, [의미1] AS meaning
      FROM WORD_TABLE
      UNION ALL
      SELECT id, 2, [의미2]
      FROM WORD_TABLE
      UNION ALL
      SELECT id, 3, [의미3]
      FROM WORD_TABLE
      UNION ALL
      SELECT id, 4, [의미4]
      FROM WORD_TABLE
      UNION ALL
      SELECT id, 5, [의미5]
      FROM WORD_TABLE
      UNION ALL
      SELECT id, 6, [의미6]
      FROM WORD_TABLE
      UNION ALL
      SELECT id, 7, [의미7]
      FROM WORD_TABLE
    )
    INSERT INTO word_meaning_set (word_id, seq, meaning)
    SELECT word_id, seq, meaning
    FROM legacy_slots
    WHERE meaning IS NOT NULL
      AND meaning <> ''
  ''';

  static Future<void> _validateLegacyMeaningSchemaState(
    DatabaseExecutor db, {
    required bool allowFullLegacy,
  }) async {
    final presentLegacyColumns = await _presentLegacyMeaningColumns(db);
    if (presentLegacyColumns.isNotEmpty &&
        presentLegacyColumns.length != _legacyMeaningColumns.length) {
      throw StateError(
        'legacy 의미 컬럼이 일부만 존재합니다: '
        '${presentLegacyColumns.join(', ')}',
      );
    }

    final canonicalTableExists = await _tableExists(db, 'word_meaning_set');
    if (presentLegacyColumns.isEmpty) {
      if (!canonicalTableExists) {
        throw StateError('legacy 의미 컬럼과 word_meaning_set이 모두 없습니다.');
      }
      return;
    }

    if (!allowFullLegacy) {
      throw StateError('legacy 의미 컬럼 7개가 migration 이후에도 남아 있습니다.');
    }
    if (!canonicalTableExists) {
      return;
    }

    final existingRows = await db.rawQuery(
      'SELECT COUNT(*) AS row_count FROM word_meaning_set',
    );
    if (existingRows.single['row_count'] == 0) {
      return;
    }
    await _validateLegacyMeaningCoverage(db);
  }

  static Future<Set<String>> _presentLegacyMeaningColumns(
    DatabaseExecutor db,
  ) async {
    final tableColumns = await db.rawQuery("PRAGMA table_info('WORD_TABLE')");
    final names = tableColumns
        .map((row) => row['name'])
        .whereType<String>()
        .toSet();
    return _legacyMeaningColumns.where(names.contains).toSet();
  }

  static Future<void> _validateLegacyMeaningCoverage(
    DatabaseExecutor db,
  ) async {
    final rows = await db.rawQuery('''
      WITH legacy_slots AS (
        SELECT id AS word_id, 1 AS seq, [의미1] AS meaning
        FROM WORD_TABLE
        UNION ALL
        SELECT id, 2, [의미2]
        FROM WORD_TABLE
        UNION ALL
        SELECT id, 3, [의미3]
        FROM WORD_TABLE
        UNION ALL
        SELECT id, 4, [의미4]
        FROM WORD_TABLE
        UNION ALL
        SELECT id, 5, [의미5]
        FROM WORD_TABLE
        UNION ALL
        SELECT id, 6, [의미6]
        FROM WORD_TABLE
        UNION ALL
        SELECT id, 7, [의미7]
        FROM WORD_TABLE
      )
      SELECT COUNT(*) AS conflict_count
      FROM legacy_slots legacy
      LEFT JOIN word_meaning_set canonical
        ON canonical.word_id = legacy.word_id
       AND canonical.seq = legacy.seq
      WHERE legacy.meaning IS NOT NULL
        AND legacy.meaning <> ''
        AND (
          canonical.word_id IS NULL OR
          canonical.meaning IS NOT legacy.meaning
        )
    ''');
    final conflictCount = rows.single['conflict_count'] as int;
    if (conflictCount != 0) {
      throw StateError(
        'canonical meaning으로 보존되지 않은 legacy 의미가 '
        '$conflictCount건 있습니다.',
      );
    }
  }

  static Future<String> _wordMeaningSnapshot(DatabaseExecutor db) async {
    final rows = await db.query(
      'word_meaning_set',
      columns: const ['id', 'word_id', 'seq', 'meaning'],
      orderBy: 'word_id ASC, seq ASC, id ASC',
    );
    return jsonEncode(rows);
  }

  static Future<void> _rebuildWordMeaningSetIfSeqUpperBoundExists(
    DatabaseExecutor txn,
  ) async {
    final schemaRows = await txn.rawQuery('''
      SELECT sql
      FROM sqlite_master
      WHERE type = 'table'
        AND name = 'word_meaning_set'
      LIMIT 1
    ''');
    if (schemaRows.isEmpty) {
      return;
    }

    final tableSql = (schemaRows.single['sql'] ?? '').toString();
    final normalizedSql = tableSql.replaceAll(RegExp(r'\s+'), ' ');
    final hasSeqUpperBound =
        normalizedSql.contains('seq <= 7') ||
        normalizedSql.contains('seq<=7') ||
        normalizedSql.contains('seq >= 1 AND seq <= 7') ||
        normalizedSql.contains('seq>=1 AND seq<=7');
    if (!hasSeqUpperBound) {
      return;
    }

    const backupTableName = 'word_meaning_set__phase32b_seq_limit_backup';
    await txn.execute(
      'ALTER TABLE word_meaning_set RENAME TO $backupTableName',
    );
    await txn.execute('''
      CREATE TABLE word_meaning_set (
        id INTEGER PRIMARY KEY,
        word_id TEXT NOT NULL,
        seq INTEGER NOT NULL,
        meaning TEXT NOT NULL,
        FOREIGN KEY (word_id) REFERENCES WORD_TABLE(id) ON DELETE CASCADE,
        CHECK (seq >= 1),
        CHECK (meaning <> '')
      )
    ''');
    await txn.execute('''
      INSERT INTO word_meaning_set (id, word_id, seq, meaning)
      SELECT id, word_id, seq, meaning
      FROM $backupTableName
      ORDER BY word_id ASC, seq ASC, id ASC
    ''');
    await txn.execute('DROP TABLE $backupTableName');
  }

  /// relation lookup 메타데이터 보정
  /// - 스키마 변경 없이 code 기준으로 label/description/category/sort_order를 정합화한다.
  /// - 기존 work DB와 seed에서 새로 복사한 work DB를 같은 메타데이터 체계로 맞춘다.
  static Future<void> _ensureRelationLookupMetadata(Database db) async {
    await db.transaction((txn) async {
      for (final category in _relationCategoryDefinitions) {
        await _upsertRelationCategory(
          txn,
          code: category.code,
          label: category.label,
          description: category.description,
          sortOrder: category.sortOrder,
        );
      }

      for (final relationType in _relationTypeDefinitions) {
        await _upsertRelationType(
          txn,
          code: relationType.code,
          categoryCode: relationType.categoryCode,
          label: relationType.label,
          description: relationType.description,
          sortOrder: relationType.sortOrder,
        );
      }

      for (final status in _relationStatusDefinitions) {
        await _upsertRelationStatus(
          txn,
          code: status.code,
          label: status.label,
          description: status.description,
          sortOrder: status.sortOrder,
        );
      }
    });
  }

  static Future<void> _upsertRelationCategory(
    DatabaseExecutor db, {
    required String code,
    required String label,
    required String description,
    required int sortOrder,
  }) async {
    final row = {
      'label': label,
      'description': description,
      'sort_order': sortOrder,
    };

    final updated = await db.update(
      'RELATION_CATEGORY',
      row,
      where: 'code = ?',
      whereArgs: [code],
    );
    if (updated > 0) {
      return;
    }

    await db.insert('RELATION_CATEGORY', {'code': code, ...row});
  }

  static Future<void> _upsertRelationType(
    DatabaseExecutor db, {
    required String code,
    required String categoryCode,
    required String label,
    required String description,
    required int sortOrder,
  }) async {
    final row = {
      'category_code': categoryCode,
      'label': label,
      'description': description,
      'sort_order': sortOrder,
    };

    final updated = await db.update(
      'RELATION_TYPE',
      row,
      where: 'code = ?',
      whereArgs: [code],
    );
    if (updated > 0) {
      return;
    }

    await db.insert('RELATION_TYPE', {'code': code, ...row});
  }

  static Future<void> _upsertRelationStatus(
    DatabaseExecutor db, {
    required String code,
    required String label,
    required String description,
    required int sortOrder,
  }) async {
    final row = {
      'label': label,
      'description': description,
      'sort_order': sortOrder,
    };

    final updated = await db.update(
      'RELATION_STATUS',
      row,
      where: 'code = ?',
      whereArgs: [code],
    );
    if (updated > 0) {
      return;
    }

    await db.insert('RELATION_STATUS', {'code': code, ...row});
  }
}
