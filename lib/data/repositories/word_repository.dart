import 'dart:convert';
import 'package:sqflite_common/sqlite_api.dart';
import '../../database/database_service.dart';
import '../models/word.dart';

/// 단어(WORD_TABLE) 및 관계(WORD_RELATION) 조회 전용 Repository
/// 그래프 엣지(관계선) 표시를 위한 관계 메타 정보
/// - otherWordId: 중심 단어 기준으로 연결된 “상대 단어 id”
/// - categoryCode/categoryLabel: RELATION_CATEGORY 기반(없으면 null)
/// - relationType/relationTypeLabel: RELATION_TYPE 기반(없으면 null)
class WordRelationEdgeInfo {
  final int relationId;
  final String wordId1;
  final String wordId2;
  final String otherWordId;
  final String directionCode;
  final String centerRelativeDirection;
  final String? relationGroupId;
  final String? categoryCode;
  final String? categoryLabel;
  final String? relationType;
  final String? relationTypeLabel;
  final String? description;
  final String? note;
  final String? source;

  WordRelationEdgeInfo({
    required this.relationId,
    required this.wordId1,
    required this.wordId2,
    required this.otherWordId,
    required this.directionCode,
    required this.centerRelativeDirection,
    this.relationGroupId,
    this.categoryCode,
    this.categoryLabel,
    this.relationType,
    this.relationTypeLabel,
    this.description,
    this.note,
    this.source,
  });

  factory WordRelationEdgeInfo.fromMap(
    Map<String, dynamic> map, {
    required String centerWordId,
    required String centerRelativeDirection,
  }) {
    final wordId1 = map['word_id_1'] as String;
    final wordId2 = map['word_id_2'] as String;
    return WordRelationEdgeInfo(
      relationId: map['relation_id'] as int,
      wordId1: wordId1,
      wordId2: wordId2,
      otherWordId: wordId1 == centerWordId ? wordId2 : wordId1,
      directionCode: (map['direction_code'] as String?) ?? 'unknown',
      centerRelativeDirection: centerRelativeDirection,
      relationGroupId: map['relation_group_id'] as String?,
      categoryCode: map['category_code'] as String?,
      categoryLabel: map['category_label'] as String?,
      relationType: map['relation_type'] as String?,
      relationTypeLabel: map['relation_type_label'] as String?,
      description: map['description'] as String?,
      note: map['note'] as String?,
      source: map['source'] as String?,
    );
  }
}

class WordRepository {
  static final List<String> _homeSearchSpellingColumns = List.unmodifiable(
    List.generate(6, (index) => '표기${index + 1}'),
  );
  static final List<String> _homeSearchTransliterationColumns =
      List.unmodifiable(List.generate(6, (index) => '음역${index + 1}'));
  static final List<String> _homeSearchMeaningColumns = List.unmodifiable(
    List.generate(7, (index) => '의미${index + 1}'),
  );
  static final List<String> _homeSearchLikeColumns = List.unmodifiable([
    '스트롱넘버',
    ..._homeSearchSpellingColumns,
    ..._homeSearchTransliterationColumns,
    ..._homeSearchMeaningColumns,
  ]);
  static final RegExp _hebrewMarkPattern = RegExp(r'[\u0591-\u05C7]');
  static final RegExp _hebrewScriptPattern = RegExp(r'[\u0590-\u05FF]');
  static final RegExp _greekScriptPattern = RegExp(
    r'[\u0370-\u03FF\u1F00-\u1FFF]',
  );
  static final RegExp _combiningMarkPattern = RegExp(r'[\u0300-\u036F]');
  static final Map<String, String> _greekVariantGroups = {
    'α': 'άὰἀἁἂἃἄἅἆἇᾀᾁᾂᾃᾄᾅᾆᾇᾰᾱᾲᾳᾴᾶᾷ',
    'ε': 'έὲἐἑἒἓἔἕ',
    'η': 'ήὴἠἡἢἣἤἥἦἧῂῃῄῆῇ',
    'ι': 'ίὶϊΐἰἱἲἳἴἵἶἷῒΐῖῗῐῑ',
    'ο': 'όὸὀὁὂὃὄὅ',
    'υ': 'ύὺϋΰὐὑὒὓὔὕὖὗῢΰῦῧῠῡ',
    'ω': 'ώὼὠὡὢὣὤὥὦὧῲῳῴῶῷ',
    'ρ': 'ῤῥ',
  };

  String _normalizeGraphExpandMode(String? value) {
    switch ((value ?? '').trim()) {
      case 'incoming_only':
      case 'outgoing_limited':
      case 'full':
        return (value ?? '').trim();
      case 'default':
      default:
        return 'default';
    }
  }

  String _normalizeDirectionCode(String? value) {
    switch ((value ?? '').trim()) {
      case 'w1_to_w2':
      case 'w2_to_w1':
      case 'undirected':
      case 'unknown':
        return (value ?? '').trim();
      default:
        return 'unknown';
    }
  }

  String _swapDirectionCode(String directionCode) {
    switch (directionCode) {
      case 'w1_to_w2':
        return 'w2_to_w1';
      case 'w2_to_w1':
        return 'w1_to_w2';
      default:
        return directionCode;
    }
  }

  ({String wordId1, String wordId2, String directionCode})
  _normalizeRelationPair({
    required String wordId1,
    required String wordId2,
    required String? directionCode,
  }) {
    final normalizedDirectionCode = _normalizeDirectionCode(directionCode);

    if (wordId1.compareTo(wordId2) <= 0) {
      return (
        wordId1: wordId1,
        wordId2: wordId2,
        directionCode: normalizedDirectionCode,
      );
    }

    return (
      wordId1: wordId2,
      wordId2: wordId1,
      directionCode: _swapDirectionCode(normalizedDirectionCode),
    );
  }

  String _resolveCenterRelativeDirection({
    required String centerWordId,
    required String wordId1,
    required String wordId2,
    required String? directionCode,
  }) {
    final normalizedDirectionCode = _normalizeDirectionCode(directionCode);

    switch (normalizedDirectionCode) {
      case 'w1_to_w2':
        return centerWordId == wordId1 ? 'outgoing' : 'incoming';
      case 'w2_to_w1':
        return centerWordId == wordId1 ? 'incoming' : 'outgoing';
      case 'undirected':
        return 'undirected';
      default:
        return 'unknown';
    }
  }

  bool _shouldIncludeByGraphExpandMode({
    required String graphExpandMode,
    required String centerRelativeDirection,
    required int outgoingLimit,
    required int currentOutgoingCount,
  }) {
    switch (graphExpandMode) {
      case 'incoming_only':
        return centerRelativeDirection != 'outgoing';
      case 'outgoing_limited':
        if (centerRelativeDirection != 'outgoing') return true;
        return currentOutgoingCount < outgoingLimit;
      case 'full':
      case 'default':
      default:
        return true;
    }
  }

  /// id로 단어 1건 조회
  Future<Word?> getWordById(String id) async {
    final db = await DatabaseService.openDatabaseFile();

    final result = await db.query(
      'WORD_TABLE',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return Word.fromMap(result.first);
  }

  /// 특정 단어와 연결된 모든 단어 목록 조회 (WORD_RELATION 기반)
  /// - graph_expand_mode는 적용하지 않는다.
  /// - 그래프 표시용 필터링은 getVisibleConnectedWordsForGraph()에서 처리한다.
  Future<List<Word>> getConnectedWords(String wordId) async {
    final db = await DatabaseService.openDatabaseFile();

    final result = await db.rawQuery(
      '''
      SELECT * FROM WORD_TABLE
      WHERE id IN (
        SELECT CASE
          WHEN word_id_1 = ?
            THEN word_id_2
          ELSE word_id_1
        END
        FROM WORD_RELATION
        WHERE word_id_1 = ?
           OR word_id_2 = ?
      )
    ''',
      [wordId, wordId, wordId],
    );

    return result.map((map) => Word.fromMap(map)).toList();
  }

  /// 특정 단어(wordId)와 연결된 관계(엣지) 메타 정보 조회
  /// - WORD_RELATION + RELATION_TYPE + RELATION_CATEGORY를 조인한다.
  /// - WORD_RELATION에 존재하지만 코드 테이블에 없는 값(예: unspecified, related)은
  ///   조인 결과가 null이 될 수 있으므로 UI에서 fallback 처리한다.
  Future<List<WordRelationEdgeInfo>> getRelationEdges(String wordId) async {
    final db = await DatabaseService.openDatabaseFile();

    final rows = await db.rawQuery(
      '''
      SELECT
        wr.id AS relation_id,
        wr.word_id_1 AS word_id_1,
        wr.word_id_2 AS word_id_2,
        wr.direction_code AS direction_code,
        wr.description AS description,
        wr.relation_group_id AS relation_group_id,
        wr.category_code AS category_code,
        rc.label AS category_label,
        wr.relation_type AS relation_type,
        rt.label AS relation_type_label,
        wr.note AS note,
        wr.source AS source
      FROM WORD_RELATION wr
      LEFT JOIN RELATION_CATEGORY rc
        ON rc.code = wr.category_code
      LEFT JOIN RELATION_TYPE rt
        ON rt.code = wr.relation_type
      WHERE wr.word_id_1 = ?
         OR wr.word_id_2 = ?
      ORDER BY wr.id ASC
      ''',
      [wordId, wordId],
    );

    return rows
        .map((row) {
          final centerRelativeDirection = _resolveCenterRelativeDirection(
            centerWordId: wordId,
            wordId1: row['word_id_1'] as String,
            wordId2: row['word_id_2'] as String,
            directionCode: row['direction_code'] as String?,
          );

          return WordRelationEdgeInfo.fromMap(
            row,
            centerWordId: wordId,
            centerRelativeDirection: centerRelativeDirection,
          );
        })
        .toList(growable: false);
  }

  /// graph_expand_mode를 반영한 그래프 표시용 엣지 조회
  Future<List<WordRelationEdgeInfo>> getVisibleRelationEdgesForGraph(
    String centerWordId, {
    required int outgoingLimit,
  }) async {
    final centerWord = await getWordById(centerWordId);
    final graphExpandMode = _normalizeGraphExpandMode(
      centerWord?.graphExpandMode,
    );
    final edges = await getRelationEdges(centerWordId);
    final visibleEdges = <WordRelationEdgeInfo>[];
    var outgoingCount = 0;

    for (final edge in edges) {
      final include = _shouldIncludeByGraphExpandMode(
        graphExpandMode: graphExpandMode,
        centerRelativeDirection: edge.centerRelativeDirection,
        outgoingLimit: outgoingLimit,
        currentOutgoingCount: outgoingCount,
      );
      if (!include) continue;

      visibleEdges.add(edge);
      if (edge.centerRelativeDirection == 'outgoing') {
        outgoingCount++;
      }
    }

    return visibleEdges;
  }

  /// graph_expand_mode를 반영한 그래프 표시용 연결 단어 조회
  Future<List<Word>> getVisibleConnectedWordsForGraph(
    String centerWordId, {
    required int outgoingLimit,
  }) async {
    final visibleEdges = await getVisibleRelationEdgesForGraph(
      centerWordId,
      outgoingLimit: outgoingLimit,
    );
    if (visibleEdges.isEmpty) return const [];

    final orderedIds = <String>[];
    final seenIds = <String>{};
    for (final edge in visibleEdges) {
      if (seenIds.add(edge.otherWordId)) {
        orderedIds.add(edge.otherWordId);
      }
    }

    final db = await DatabaseService.openDatabaseFile();
    final placeholders = List.filled(orderedIds.length, '?').join(', ');
    final rows = await db.rawQuery(
      'SELECT * FROM WORD_TABLE WHERE id IN ($placeholders)',
      orderedIds,
    );

    final wordsById = <String, Word>{
      for (final row in rows) (row['id'] as String): Word.fromMap(row),
    };

    return orderedIds
        .map((id) => wordsById[id])
        .whereType<Word>()
        .toList(growable: false);
  }

  /// WORD_TABLE에서 단어 목록을 일부 조회한다 (홈 화면 기본 리스트용)
  /// - 상세 화면에서 모든 컬럼을 보여주기 위해 Map 그대로 반환한다.
  Future<List<Map<String, dynamic>>> getWordsMap({int limit = 50}) async {
    final db = await DatabaseService.openDatabaseFile();
    return await db.query('WORD_TABLE', limit: limit);
  }

  /// 홈 화면 기본 리스트용 Strong 사전형 목록 조회
  /// - 스트롱넘버가 있고 prefix가 H/G인 항목만 반환한다.
  /// - 정렬은 H -> G -> 숫자 오름차순 -> id 순서로 고정한다.
  Future<List<Map<String, dynamic>>> getStrongWordsMap({int? limit}) async {
    final db = await DatabaseService.openDatabaseFile();
    final sql = StringBuffer('''
      SELECT *
      FROM WORD_TABLE
      WHERE 스트롱넘버 IS NOT NULL
        AND TRIM(스트롱넘버) <> ''
        AND UPPER(SUBSTR(TRIM(스트롱넘버), 1, 1)) IN ('H', 'G')
      ORDER BY
        CASE UPPER(SUBSTR(TRIM(스트롱넘버), 1, 1))
          WHEN 'H' THEN 0
          WHEN 'G' THEN 1
          ELSE 2
        END,
        CAST(SUBSTR(TRIM(스트롱넘버), 2) AS INTEGER),
        id
      ''');
    final args = <Object?>[];

    if (limit != null) {
      sql.writeln('LIMIT ?');
      args.add(limit);
    }

    return await db.rawQuery(sql.toString(), args);
  }

  String _normalizeStrongValue(String strong) {
    final trimmed = strong.trim();
    final match = RegExp(r'^([A-Za-z])(\d+)$').firstMatch(trimmed);
    if (match == null) {
      return trimmed;
    }

    final prefix = match.group(1)!.toUpperCase();
    final numericPart = int.tryParse(match.group(2)!);
    if (numericPart == null) {
      return trimmed;
    }

    return '$prefix$numericPart';
  }

  String? _normalizeStrongSearchKeyword(String input) {
    final trimmed = input.trim();
    final match = RegExp(r'^([HhGg])(\d+)$').firstMatch(trimmed);
    if (match == null) {
      return null;
    }

    return _normalizeStrongValue(
      '${match.group(1)!.toUpperCase()}${match.group(2)!}',
    );
  }

  String _stripHebrewMarks(String value) {
    return value.replaceAll(_hebrewMarkPattern, '');
  }

  String _stripGreekDiacritics(String value) {
    var normalized = value;

    for (final entry in _greekVariantGroups.entries) {
      normalized = normalized.replaceAll(RegExp('[${entry.value}]'), entry.key);
    }

    return normalized
        .replaceAll(_combiningMarkPattern, '')
        .replaceAll('ς', 'σ');
  }

  String _normalizeHomeSearchText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final lowerCased = trimmed.toLowerCase();
    final withoutHebrewMarks = _stripHebrewMarks(lowerCased);
    final withoutGreekDiacritics = _stripGreekDiacritics(withoutHebrewMarks);

    return withoutGreekDiacritics.replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _containsHebrewScript(String value) {
    return _hebrewScriptPattern.hasMatch(value);
  }

  bool _containsGreekScript(String value) {
    return _greekScriptPattern.hasMatch(value);
  }

  List<({String value, int fieldIndex})> _readIndexedValues(
    Map<String, dynamic> row,
    List<String> columns,
  ) {
    final values = <({String value, int fieldIndex})>[];

    for (var index = 0; index < columns.length; index++) {
      final value = (row[columns[index]] ?? '').toString().trim();
      if (value.isEmpty) {
        continue;
      }
      values.add((value: value, fieldIndex: index + 1));
    }

    return values;
  }

  ({int priority, int fieldIndex, int valueLength}) _rankRecord(
    int priority,
    int fieldIndex,
    int valueLength,
  ) {
    return (
      priority: priority,
      fieldIndex: fieldIndex,
      valueLength: valueLength,
    );
  }

  int _compareSearchRank(
    ({int priority, int fieldIndex, int valueLength}) left,
    ({int priority, int fieldIndex, int valueLength}) right,
  ) {
    final byPriority = left.priority.compareTo(right.priority);
    if (byPriority != 0) {
      return byPriority;
    }

    final byFieldIndex = left.fieldIndex.compareTo(right.fieldIndex);
    if (byFieldIndex != 0) {
      return byFieldIndex;
    }

    return left.valueLength.compareTo(right.valueLength);
  }

  ({int priority, int fieldIndex, int valueLength})? _pickBetterRank(
    ({int priority, int fieldIndex, int valueLength})? current,
    ({int priority, int fieldIndex, int valueLength})? candidate,
  ) {
    if (candidate == null) {
      return current;
    }
    if (current == null || _compareSearchRank(candidate, current) < 0) {
      return candidate;
    }
    return current;
  }

  ({int priority, int fieldIndex, int valueLength})? _matchIndexedValues(
    List<({String value, int fieldIndex})> values, {
    required String normalizedKeyword,
    int? exactPriority,
    int? prefixPriority,
    int? partialPriority,
  }) {
    ({int priority, int fieldIndex, int valueLength})? bestRank;

    for (final entry in values) {
      final normalizedValue = _normalizeHomeSearchText(entry.value);
      if (normalizedValue.isEmpty) {
        continue;
      }

      if (exactPriority != null && normalizedValue == normalizedKeyword) {
        bestRank = _pickBetterRank(
          bestRank,
          _rankRecord(exactPriority, entry.fieldIndex, normalizedValue.length),
        );
      }

      if (prefixPriority != null &&
          normalizedValue.startsWith(normalizedKeyword)) {
        bestRank = _pickBetterRank(
          bestRank,
          _rankRecord(prefixPriority, entry.fieldIndex, normalizedValue.length),
        );
      }

      if (partialPriority != null &&
          normalizedValue.contains(normalizedKeyword)) {
        bestRank = _pickBetterRank(
          bestRank,
          _rankRecord(
            partialPriority,
            entry.fieldIndex,
            normalizedValue.length,
          ),
        );
      }
    }

    return bestRank;
  }

  ({int priority, int fieldIndex, int valueLength})? _matchStrongValue(
    Map<String, dynamic> row, {
    required String normalizedKeyword,
    required String? normalizedStrongKeyword,
  }) {
    final strong = (row['스트롱넘버'] ?? '').toString().trim();
    if (strong.isEmpty) {
      return null;
    }

    final normalizedStrong = _normalizeStrongValue(strong).toLowerCase();
    if (normalizedStrong.isEmpty) {
      return null;
    }

    if (normalizedStrongKeyword != null) {
      final normalizedSearchStrong = normalizedStrongKeyword.toLowerCase();
      if (normalizedStrong == normalizedSearchStrong) {
        return _rankRecord(0, 0, normalizedStrong.length);
      }
      if (normalizedStrong.startsWith(normalizedSearchStrong)) {
        return _rankRecord(1, 0, normalizedStrong.length);
      }
      if (normalizedStrong.contains(normalizedSearchStrong)) {
        return _rankRecord(9, 0, normalizedStrong.length);
      }
    }

    if (normalizedStrong.contains(normalizedKeyword)) {
      return _rankRecord(9, 0, normalizedStrong.length);
    }

    return null;
  }

  ({int priority, int fieldIndex, int valueLength})? _rankHomeSearchRow(
    Map<String, dynamic> row, {
    required String normalizedKeyword,
    required String? normalizedStrongKeyword,
  }) {
    var bestRank = _matchStrongValue(
      row,
      normalizedKeyword: normalizedKeyword,
      normalizedStrongKeyword: normalizedStrongKeyword,
    );
    final spellingValues = _readIndexedValues(row, _homeSearchSpellingColumns);
    final transliterationValues = _readIndexedValues(
      row,
      _homeSearchTransliterationColumns,
    );
    final meaningValues = _readIndexedValues(row, _homeSearchMeaningColumns);

    bestRank = _pickBetterRank(
      bestRank,
      _matchIndexedValues(
        spellingValues,
        normalizedKeyword: normalizedKeyword,
        exactPriority: 2,
        prefixPriority: 3,
        partialPriority: 7,
      ),
    );
    bestRank = _pickBetterRank(
      bestRank,
      _matchIndexedValues(
        transliterationValues,
        normalizedKeyword: normalizedKeyword,
        exactPriority: 4,
        prefixPriority: 5,
        partialPriority: 8,
      ),
    );
    bestRank = _pickBetterRank(
      bestRank,
      _matchIndexedValues(
        meaningValues,
        normalizedKeyword: normalizedKeyword,
        partialPriority: 6,
      ),
    );

    return bestRank;
  }

  Future<List<Map<String, dynamic>>> _queryHomeSearchLikeCandidates(
    Database db,
    Set<String> sqlTerms,
  ) async {
    if (sqlTerms.isEmpty) {
      return const [];
    }

    final whereParts = <String>[];
    final whereArgs = <Object?>[];

    for (final term in sqlTerms) {
      final like = '%$term%';
      for (final column in _homeSearchLikeColumns) {
        whereParts.add('LOWER(COALESCE("$column", \'\')) LIKE ?');
        whereArgs.add(like);
      }
    }

    return await db.query(
      'WORD_TABLE',
      where: whereParts.join(' OR '),
      whereArgs: whereArgs,
      orderBy: 'id',
    );
  }

  Future<List<Map<String, dynamic>>> _queryHomeSearchLanguageCandidates(
    Database db,
    String keyword,
  ) async {
    final whereParts = <String>[];
    final whereArgs = <Object?>[];

    if (_containsHebrewScript(keyword)) {
      whereParts.add('언어 LIKE ?');
      whereArgs.add('%히브리%');
      whereParts.add('언어 LIKE ?');
      whereArgs.add('%아람%');
    }

    if (_containsGreekScript(keyword)) {
      whereParts.add('언어 LIKE ?');
      whereArgs.add('%헬라%');
    }

    if (whereParts.isEmpty) {
      return const [];
    }

    return await db.query(
      'WORD_TABLE',
      where: whereParts.join(' OR '),
      whereArgs: whereArgs,
      orderBy: 'id',
    );
  }

  Future<List<Map<String, dynamic>>> _collectHomeSearchCandidates(
    Database db,
    String keyword,
    String normalizedKeyword,
  ) async {
    final sqlTerms = <String>{keyword.toLowerCase(), normalizedKeyword};
    final normalizedStrongKeyword = _normalizeStrongSearchKeyword(keyword);
    if (normalizedStrongKeyword != null) {
      sqlTerms.add(normalizedStrongKeyword.toLowerCase());
    }

    final candidatesById = <String, Map<String, dynamic>>{};

    void addRows(Iterable<Map<String, dynamic>> rows) {
      for (final row in rows) {
        final id = (row['id'] ?? '').toString();
        if (id.isEmpty) {
          continue;
        }
        candidatesById[id] = row;
      }
    }

    addRows(await _queryHomeSearchLikeCandidates(db, sqlTerms));
    addRows(await _queryHomeSearchLanguageCandidates(db, keyword));

    if (candidatesById.isEmpty &&
        (_containsHebrewScript(keyword) || _containsGreekScript(keyword))) {
      addRows(await db.query('WORD_TABLE', orderBy: 'id'));
    }

    return candidatesById.values.toList();
  }

  Future<List<Map<String, dynamic>>> searchStrongExactMap(
    String keyword, {
    int limit = 200,
  }) async {
    final normalizedStrong = _normalizeStrongSearchKeyword(keyword);
    if (normalizedStrong == null) {
      return const [];
    }

    final prefix = normalizedStrong.substring(0, 1);
    final numericPart = int.parse(normalizedStrong.substring(1));
    final db = await DatabaseService.openDatabaseFile();
    final rows = await db.rawQuery(
      '''
      SELECT *
      FROM WORD_TABLE
      WHERE 스트롱넘버 IS NOT NULL
        AND TRIM(스트롱넘버) <> ''
        AND UPPER(SUBSTR(TRIM(스트롱넘버), 1, 1)) = ?
        AND CAST(SUBSTR(TRIM(스트롱넘버), 2) AS INTEGER) = ?
      ORDER BY id
      ''',
      [prefix, numericPart],
    );

    return rows
        .where(
          (row) =>
              _normalizeStrongValue((row['스트롱넘버'] ?? '').toString()) ==
              normalizedStrong,
        )
        .take(limit)
        .toList();
  }

  /// 키워드로 단어 검색 (홈 검색용)
  /// - DB에서 1차 후보를 수집한 뒤 Dart에서 정규화 비교/정렬한다.
  /// - 표기1~6, 음역1~6, 의미1~7, 스트롱넘버를 대상으로 한다.
  /// - 결과는 exact/prefix/partial 우선순위를 적용한 뒤 limit를 건다.
  Future<List<Map<String, dynamic>>> searchWordsMap(
    String keyword, {
    int limit = 200,
  }) async {
    final db = await DatabaseService.openDatabaseFile();

    final q = keyword.trim();
    if (q.isEmpty) {
      return getWordsMap(limit: limit);
    }

    final normalizedKeyword = _normalizeHomeSearchText(q);
    if (normalizedKeyword.isEmpty) {
      return const [];
    }

    final normalizedStrongKeyword = _normalizeStrongSearchKeyword(q);
    final candidates = await _collectHomeSearchCandidates(
      db,
      q,
      normalizedKeyword,
    );
    final scoredRows =
        <
          ({
            Map<String, dynamic> row,
            int priority,
            int fieldIndex,
            int valueLength,
            String id,
          })
        >[];

    for (final row in candidates) {
      final rank = _rankHomeSearchRow(
        row,
        normalizedKeyword: normalizedKeyword,
        normalizedStrongKeyword: normalizedStrongKeyword,
      );
      if (rank == null) {
        continue;
      }

      scoredRows.add((
        row: row,
        priority: rank.priority,
        fieldIndex: rank.fieldIndex,
        valueLength: rank.valueLength,
        id: (row['id'] ?? '').toString(),
      ));
    }

    scoredRows.sort((left, right) {
      final byRank = _compareSearchRank(
        (
          priority: left.priority,
          fieldIndex: left.fieldIndex,
          valueLength: left.valueLength,
        ),
        (
          priority: right.priority,
          fieldIndex: right.fieldIndex,
          valueLength: right.valueLength,
        ),
      );
      if (byRank != 0) {
        return byRank;
      }
      return left.id.compareTo(right.id);
    });

    return scoredRows.take(limit).map((entry) => entry.row).toList();
  }

  /// WORD_RELATION 1건 삭제(트랜잭션)
  Future<void> deleteRelation(int relationId) async {
    final db = await DatabaseService.openDatabaseFile();
    final groupId = _newHistoryGroupId();

    await db.transaction((txn) async {
      final before = await _getRelationRowById(txn, relationId);
      if (before == null) {
        throw Exception('삭제할 관계를 찾을 수 없습니다: $relationId');
      }

      await _insertHistory(
        txn,
        groupId: groupId,
        actionType: 'delete',
        entityType: 'relation',
        entityId: relationId.toString(),
        beforeJson: before,
      );

      await txn.delete(
        'WORD_RELATION',
        where: 'id = ?',
        whereArgs: [relationId],
      );
    });
  }

  /// RELATION_CATEGORY 코드/라벨 목록
  Future<List<Map<String, dynamic>>> getRelationCategories() async {
    final db = await DatabaseService.openDatabaseFile();
    return await db.query(
      'RELATION_CATEGORY',
      columns: ['code', 'label'],
      orderBy: 'code',
    );
  }

  /// RELATION_TYPE 코드/라벨 목록
  Future<List<Map<String, dynamic>>> getRelationTypes() async {
    final db = await DatabaseService.openDatabaseFile();
    return await db.query(
      'RELATION_TYPE',
      columns: ['code', 'label'],
      orderBy: 'code',
    );
  }

  /// WORD_RELATION 1건 수정(트랜잭션)
  Future<void> updateRelation({
    required int relationId,
    required String? categoryCode,
    required String? relationType,
    String? directionCode,
    String? description,
    String? relationGroupId,
    required String? note,
    required String? source,
  }) async {
    final db = await DatabaseService.openDatabaseFile();
    final groupId = _newHistoryGroupId();
    final normalizedDirectionCode = _normalizeDirectionCode(directionCode);
    final trimmedDescription = (description ?? '').trim();
    final descriptionValue = trimmedDescription.isEmpty
        ? null
        : trimmedDescription;
    final trimmedRelationGroupId = (relationGroupId ?? '').trim();
    final relationGroupIdValue = trimmedRelationGroupId.isEmpty
        ? null
        : trimmedRelationGroupId;

    await db.transaction((txn) async {
      final before = await _getRelationRowById(txn, relationId);
      if (before == null) {
        throw Exception('수정할 관계를 찾을 수 없습니다: $relationId');
      }

      final existingId = await _findExistingRelationIdBySignatureOnExecutor(
        txn,
        wordIdA: before['word_id_1'] as String,
        wordIdB: before['word_id_2'] as String,
        relationType: relationType,
        directionCode: normalizedDirectionCode,
        excludeRelationId: relationId,
      );
      if (existingId != null) {
        throw Exception('동일한 pair/type/direction 관계가 이미 존재합니다: $existingId');
      }

      final after = Map<String, dynamic>.from(before);
      after['category_code'] = categoryCode;
      after['relation_type'] = relationType;
      after['direction_code'] = normalizedDirectionCode;
      after['description'] = descriptionValue;
      after['relation_group_id'] = relationGroupIdValue;
      after['note'] = note;
      after['source'] = source;
      after['updated_at'] = DateTime.now().toIso8601String();

      await txn.update(
        'WORD_RELATION',
        {
          'category_code': categoryCode,
          'relation_type': relationType,
          'direction_code': normalizedDirectionCode,
          'description': descriptionValue,
          'relation_group_id': relationGroupIdValue,
          'note': note,
          'source': source,
          'updated_at': after['updated_at'],
        },
        where: 'id = ?',
        whereArgs: [relationId],
      );

      await _insertHistory(
        txn,
        groupId: groupId,
        actionType: 'update',
        entityType: 'relation',
        entityId: relationId.toString(),
        beforeJson: before,
        afterJson: after,
      );
    });
  }

  /// 키워드로 단어 검색 (그래프에서 "관계 추가" 대상 단어 선택용)
  /// - 표기1, 의미1, 스트롱넘버 부분일치 검색
  /// - 결과를 Word 모델로 반환한다(그래프 노드에서 사용하기 쉬움)
  Future<List<Word>> searchWords(String keyword, {int limit = 200}) async {
    final db = await DatabaseService.openDatabaseFile();

    final q = keyword.trim();
    if (q.isEmpty) return [];

    final like = '%$q%';

    final rows = await db.query(
      'WORD_TABLE',
      where: '표기1 LIKE ? OR 의미1 LIKE ? OR 스트롱넘버 LIKE ?',
      whereArgs: [like, like, like],
      limit: limit,
    );

    return rows.map((m) => Word.fromMap(m)).toList();
  }

  /// 두 단어 사이에 이미 관계(WORD_RELATION)가 존재하는지 검사한다.
  /// - (A,B)와 (B,A)를 동일 관계로 본다.
  /// - 있으면 relation id를 반환하고, 없으면 null
  Future<int?> findExistingRelationId(String wordIdA, String wordIdB) async {
    final db = await DatabaseService.openDatabaseFile();

    // DB CHECK 제약(word_id_1 < word_id_2)에 맞게 정렬
    final a = wordIdA.compareTo(wordIdB) <= 0 ? wordIdA : wordIdB;
    final b = wordIdA.compareTo(wordIdB) <= 0 ? wordIdB : wordIdA;

    final rows = await db.rawQuery(
      '''
      SELECT id
      FROM WORD_RELATION
      WHERE word_id_1 = ? AND word_id_2 = ?
      LIMIT 1
      ''',
      [a, b],
    );

    if (rows.isEmpty) return null;
    return rows.first['id'] as int;
  }

  /// v2 signature 기준 관계 존재 여부 검사
  Future<int?> findExistingRelationIdBySignature(
    String wordIdA,
    String wordIdB, {
    required String? relationType,
    String? directionCode,
    int? excludeRelationId,
  }) async {
    final db = await DatabaseService.openDatabaseFile();
    return await _findExistingRelationIdBySignatureOnExecutor(
      db,
      wordIdA: wordIdA,
      wordIdB: wordIdB,
      relationType: relationType,
      directionCode: directionCode,
      excludeRelationId: excludeRelationId,
    );
  }

  Future<int?> _findExistingRelationIdBySignatureOnExecutor(
    DatabaseExecutor db, {
    required String wordIdA,
    required String wordIdB,
    required String? relationType,
    String? directionCode,
    int? excludeRelationId,
  }) async {
    final normalized = _normalizeRelationPair(
      wordId1: wordIdA,
      wordId2: wordIdB,
      directionCode: directionCode,
    );
    final sql = StringBuffer('''
      SELECT id
      FROM WORD_RELATION
      WHERE word_id_1 = ?
        AND word_id_2 = ?
        AND COALESCE(relation_type, '') = COALESCE(?, '')
        AND COALESCE(direction_code, 'unknown') = COALESCE(?, 'unknown')
    ''');
    final args = <Object?>[
      normalized.wordId1,
      normalized.wordId2,
      relationType,
      normalized.directionCode,
    ];

    if (excludeRelationId != null) {
      sql.writeln('AND id <> ?');
      args.add(excludeRelationId);
    }

    sql.writeln('LIMIT 1');

    final rows = await db.rawQuery(sql.toString(), args);
    if (rows.isEmpty) return null;
    return rows.first['id'] as int;
  }

  /// WORD_RELATION에 관계 1건을 추가한다(트랜잭션)
  /// - status_code/created_at/updated_at은 DB default를 활용하되,
  ///   updated_at은 명시적으로 ISO 문자열로 넣어준다.
  Future<int> createRelation({
    required String wordId1,
    required String wordId2,
    required String? categoryCode,
    required String? relationType,
    String? directionCode,
    String? description,
    String? relationGroupId,
    required String? note,
    required String? source,
  }) async {
    final db = await DatabaseService.openDatabaseFile();
    final groupId = _newHistoryGroupId();
    final normalized = _normalizeRelationPair(
      wordId1: wordId1,
      wordId2: wordId2,
      directionCode: directionCode,
    );
    final trimmedDescription = (description ?? '').trim();
    final descriptionValue = trimmedDescription.isEmpty
        ? null
        : trimmedDescription;
    final trimmedRelationGroupId = (relationGroupId ?? '').trim();
    final relationGroupIdValue = trimmedRelationGroupId.isEmpty
        ? null
        : trimmedRelationGroupId;

    return await db.transaction((txn) async {
      final existingId = await _findExistingRelationIdBySignatureOnExecutor(
        txn,
        wordIdA: normalized.wordId1,
        wordIdB: normalized.wordId2,
        relationType: relationType,
        directionCode: normalized.directionCode,
      );
      if (existingId != null) {
        throw Exception('동일한 pair/type/direction 관계가 이미 존재합니다: $existingId');
      }

      final row = {
        'word_id_1': normalized.wordId1,
        'word_id_2': normalized.wordId2,
        'category_code': categoryCode,
        'relation_type': relationType,
        'direction_code': normalized.directionCode,
        'description': descriptionValue,
        'relation_group_id': relationGroupIdValue,
        'note': note,
        'source': source,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final id = await txn.insert('WORD_RELATION', row);

      final after = Map<String, dynamic>.from(row);
      after['id'] = id;

      await _insertHistory(
        txn,
        groupId: groupId,
        actionType: 'create',
        entityType: 'relation',
        entityId: id.toString(),
        afterJson: after,
      );

      return id;
    });
  }

  /// 언어명을 Reshet 내부 id prefix로 변환한다.
  /// - 히브리어/아람어 -> H
  /// - 헬라어 -> G
  /// - 라틴어 -> L
  /// - 영어 -> E
  /// - 그 외 -> X
  String _languageCodeFromLanguage(String language) {
    if (language.contains('히브리')) return 'H';
    if (language.contains('아람')) return 'H';
    if (language.contains('헬라')) return 'G';
    if (language.contains('라틴')) return 'L';
    if (language.contains('영어')) return 'E';
    return 'X';
  }

  /// 중복 검사 비교용 표기 정규화
  /// - trim
  /// - NFC 수준 전체 정규화까지는 라이브러리 추가가 필요하므로,
  ///   현재 단계에서는 히브리어/아람어의 모음부호(niqqud) 제거 + 공백 정리만 적용
  String _normalizeSpellingForDuplicateCheck(String value) {
    final trimmed = value.trim();

    final withoutHebrewMarks = _stripHebrewMarks(trimmed);

    // 연속 공백 정리
    return withoutHebrewMarks.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 다음 WORD_TABLE.id 생성
  /// - Strong가 있으면: <STRONG>_<SEQ4>
  /// - Strong가 없으면: <LANGCODE>0000_<SEQ4>
  Future<String> generateNextWordId({
    required String language,
    String? strongNumber,
  }) async {
    final db = await DatabaseService.openDatabaseFile();

    final strong = (strongNumber ?? '').trim().toUpperCase();

    // 1) Strong가 있는 경우
    if (strong.isNotEmpty) {
      final rows = await db.rawQuery(
        '''
        SELECT id
        FROM WORD_TABLE
        WHERE id GLOB ?
        ''',
        ['${strong}_[0-9][0-9][0-9][0-9]'],
      );

      int maxSeq = -1;
      final re = RegExp('^${RegExp.escape(strong)}_(\\d{4})\$');

      for (final row in rows) {
        final id = row['id'] as String;
        final m = re.firstMatch(id);
        if (m != null) {
          final seq = int.tryParse(m.group(1)!) ?? 0;
          if (seq > maxSeq) maxSeq = seq;
        }
      }

      final nextSeq = maxSeq + 1;
      final seqText = nextSeq.toString().padLeft(4, '0');
      return '${strong}_$seqText';
    }

    // 2) Strong가 없는 경우
    final langCode = _languageCodeFromLanguage(language);
    final base = '${langCode}0000';

    final rows = await db.rawQuery(
      '''
      SELECT id
      FROM WORD_TABLE
      WHERE id GLOB ?
      ''',
      ['${base}_[0-9][0-9][0-9][0-9]'],
    );

    int maxSeq = 0;
    final re = RegExp('^${RegExp.escape(base)}_(\\d{4})\$');

    for (final row in rows) {
      final id = row['id'] as String;
      final m = re.firstMatch(id);
      if (m != null) {
        final seq = int.tryParse(m.group(1)!) ?? 0;
        if (seq > maxSeq) maxSeq = seq;
      }
    }

    final nextSeq = maxSeq + 1;
    final seqText = nextSeq.toString().padLeft(4, '0');
    return '${base}_$seqText';
  }

  /// 신규 단어 생성 전 중복 후보 검색
  /// - Strong가 있으면: 스트롱넘버 기준
  /// - Strong가 없으면: (언어, 표기1) 기준
  Future<List<Map<String, dynamic>>> findDuplicateCandidates({
    required String language,
    String? strongNumber,
    required String spelling1,
    String? excludeId,
  }) async {
    final db = await DatabaseService.openDatabaseFile();

    final strong = (strongNumber ?? '').trim();
    final spelling = spelling1.trim();

    if (strong.isNotEmpty) {
      final rows = await db.query(
        'WORD_TABLE',
        columns: ['id', '언어', '스트롱넘버', '표기1', '의미1'],
        where: '스트롱넘버 = ?',
        whereArgs: [strong],
        limit: 20,
      );

      return rows.where((row) {
        final id = (row['id'] ?? '').toString();
        return excludeId == null || id != excludeId;
      }).toList();
    }

    final rows = await db.query(
      'WORD_TABLE',
      columns: ['id', '언어', '스트롱넘버', '표기1', '의미1'],
      where: '언어 = ?',
      whereArgs: [language],
      limit: 200,
    );

    final target = _normalizeSpellingForDuplicateCheck(spelling);

    return rows.where((row) {
      final id = (row['id'] ?? '').toString();
      if (excludeId != null && id == excludeId) return false;

      final existingSpelling = (row['표기1'] ?? '').toString();
      final normalizedExisting = _normalizeSpellingForDuplicateCheck(
        existingSpelling,
      );

      return normalizedExisting == target;
    }).toList();
  }

  /// WORD_TABLE에 신규 단어를 추가한다.
  /// - 현재 단계에서는 핵심 컬럼만 입력하고, 나머지는 null로 둔다.
  Future<void> createWord({
    required String id,
    required String language,
    String? strongNumber,
    required String spelling1,
    String? transliteration1,
    String? pronunciation1,
    String? meaning1,
    String? note,
    String? graphExpandMode,
  }) async {
    final db = await DatabaseService.openDatabaseFile();
    final groupId = _newHistoryGroupId();

    await db.transaction((txn) async {
      final row = {
        'id': id,
        '언어': language,
        '스트롱넘버': (strongNumber ?? '').trim().isEmpty
            ? null
            : strongNumber!.trim(),
        '표기1': spelling1.trim(),
        '발음1': (pronunciation1 ?? '').trim().isEmpty
            ? null
            : pronunciation1!.trim(),
        '의미1': (meaning1 ?? '').trim().isEmpty ? null : meaning1!.trim(),
        '비고': (note ?? '').trim().isEmpty ? null : note!.trim(),
        'graph_expand_mode': _normalizeGraphExpandMode(graphExpandMode),
      };

      await txn.insert('WORD_TABLE', row);

      await _insertHistory(
        txn,
        groupId: groupId,
        actionType: 'create',
        entityType: 'word',
        entityId: id,
        afterJson: row,
      );
    });
  }

  /// 특정 단어와 연결된 관계 개수 조회
  Future<int> countRelationsForWord(String wordId) async {
    final db = await DatabaseService.openDatabaseFile();

    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS cnt
      FROM WORD_RELATION
      WHERE word_id_1 = ? OR word_id_2 = ?
      ''',
      [wordId, wordId],
    );

    if (rows.isEmpty) return 0;
    final value = rows.first['cnt'];
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  /// 단어 1건 삭제
  /// - 현재 구조에서는 연결 관계도 함께 삭제한다.
  /// - 관계 삭제 + 단어 삭제를 하나의 트랜잭션으로 묶는다.
  Future<void> deleteWord(String wordId) async {
    final db = await DatabaseService.openDatabaseFile();
    final groupId = _newHistoryGroupId();

    await db.transaction((txn) async {
      final wordRows = await txn.query(
        'WORD_TABLE',
        where: 'id = ?',
        whereArgs: [wordId],
        limit: 1,
      );
      if (wordRows.isEmpty) {
        throw Exception('삭제할 단어를 찾을 수 없습니다: $wordId');
      }

      final wordBefore = Map<String, dynamic>.from(wordRows.first);

      final relationRows = await txn.query(
        'WORD_RELATION',
        where: 'word_id_1 = ? OR word_id_2 = ?',
        whereArgs: [wordId, wordId],
      );

      for (final rel in relationRows) {
        final relMap = Map<String, dynamic>.from(rel);
        await _insertHistory(
          txn,
          groupId: groupId,
          actionType: 'delete',
          entityType: 'relation',
          entityId: relMap['id'].toString(),
          beforeJson: relMap,
        );
      }

      await _insertHistory(
        txn,
        groupId: groupId,
        actionType: 'delete',
        entityType: 'word',
        entityId: wordId,
        beforeJson: wordBefore,
      );

      await txn.delete(
        'WORD_RELATION',
        where: 'word_id_1 = ? OR word_id_2 = ?',
        whereArgs: [wordId, wordId],
      );

      await txn.delete('WORD_TABLE', where: 'id = ?', whereArgs: [wordId]);
    });
  }

  /// WORD_TABLE의 기존 단어 1건 수정
  /// - 현재 단계에서는 핵심 편집 필드만 수정한다.
  /// - id는 수정하지 않는다.
  Future<void> updateWord({
    required String id,
    required String language,
    String? strongNumber,
    required String spelling1,
    String? transliteration1,
    String? pronunciation1,
    String? meaning1,
    String? note,
    String? graphExpandMode,
  }) async {
    final db = await DatabaseService.openDatabaseFile();
    final groupId = _newHistoryGroupId();

    await db.transaction((txn) async {
      final before = await _getWordRowById(txn, id);
      if (before == null) {
        throw Exception('수정할 단어를 찾을 수 없습니다: $id');
      }

      final after = Map<String, dynamic>.from(before);
      after['언어'] = language;
      after['스트롱넘버'] = (strongNumber ?? '').trim().isEmpty
          ? null
          : strongNumber!.trim();
      after['표기1'] = spelling1.trim();
      after['발음1'] = (pronunciation1 ?? '').trim().isEmpty
          ? null
          : pronunciation1!.trim();
      after['의미1'] = (meaning1 ?? '').trim().isEmpty ? null : meaning1!.trim();
      after['비고'] = (note ?? '').trim().isEmpty ? null : note!.trim();
      after['음역1'] = (transliteration1 ?? '').trim().isEmpty
          ? null
          : transliteration1!.trim();
      after['graph_expand_mode'] = _normalizeGraphExpandMode(graphExpandMode);

      await txn.update(
        'WORD_TABLE',
        {
          '언어': after['언어'],
          '스트롱넘버': after['스트롱넘버'],
          '표기1': after['표기1'],
          '발음1': after['발음1'],
          '의미1': after['의미1'],
          '비고': after['비고'],
          '음역1': after['음역1'],
          'graph_expand_mode': after['graph_expand_mode'],
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await _insertHistory(
        txn,
        groupId: groupId,
        actionType: 'update',
        entityType: 'word',
        entityId: id,
        beforeJson: before,
        afterJson: after,
      );
    });
  }

  String _newHistoryGroupId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  Future<void> _insertHistory(
    DatabaseExecutor db, {
    required String groupId,
    required String actionType,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? beforeJson,
    Map<String, dynamic>? afterJson,
  }) async {
    await db.insert('CHANGE_HISTORY', {
      'group_id': groupId,
      'action_type': actionType,
      'entity_type': entityType,
      'entity_id': entityId,
      'before_json': beforeJson == null ? null : jsonEncode(beforeJson),
      'after_json': afterJson == null ? null : jsonEncode(afterJson),
      'created_at': DateTime.now().toIso8601String(),
      'undone_at': null,
    });
  }

  Future<Map<String, dynamic>?> _getWordRowById(
    DatabaseExecutor db,
    String id,
  ) async {
    final rows = await db.query(
      'WORD_TABLE',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  Future<Map<String, dynamic>?> _getRelationRowById(
    DatabaseExecutor db,
    int id,
  ) async {
    final rows = await db.query(
      'WORD_RELATION',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  int _requireIntValue(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is int) return value;
    if (value is num) return value.toInt();

    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;

    throw Exception('CHANGE_HISTORY relation 복원값이 잘못되었습니다: $key=$value');
  }

  String _requireStringValue(Map<String, dynamic> row, String key) {
    final value = row[key]?.toString() ?? '';
    if (value.isEmpty) {
      throw Exception('CHANGE_HISTORY relation 복원값이 비어 있습니다: $key');
    }
    return value;
  }

  Future<void> _restoreDeletedRelation(
    DatabaseExecutor txn,
    Map<String, dynamic> before,
  ) async {
    final relationId = _requireIntValue(before, 'id');
    final originalWordId1 = _requireStringValue(before, 'word_id_1');
    final originalWordId2 = _requireStringValue(before, 'word_id_2');
    final originalDirectionCode = _normalizeDirectionCode(
      before['direction_code'] as String?,
    );
    final originalRelationType = before['relation_type'] as String?;

    if (originalWordId1 == originalWordId2) {
      throw Exception('관계 Undo 복원 실패: 동일한 단어 id 쌍입니다. ($originalWordId1)');
    }

    final existingSameId = await _getRelationRowById(txn, relationId);
    if (existingSameId != null) {
      throw Exception('관계 Undo 복원 실패: 동일 id가 이미 존재합니다. ($relationId)');
    }

    final existingId = await _findExistingRelationIdBySignatureOnExecutor(
      txn,
      wordIdA: originalWordId1,
      wordIdB: originalWordId2,
      relationType: originalRelationType,
      directionCode: originalDirectionCode,
    );
    if (existingId != null) {
      throw Exception(
        '관계 Undo 복원 실패: 동일 pair/type/direction 관계가 이미 존재합니다. '
        '($originalWordId1, $originalWordId2 / existing id=$existingId)',
      );
    }

    await txn.insert('WORD_RELATION', {
      'id': relationId,
      'word_id_1': originalWordId1,
      'word_id_2': originalWordId2,
      'category_code': before['category_code'],
      'relation_type': originalRelationType,
      'direction_code': originalDirectionCode,
      'description': before['description'],
      'relation_group_id': before['relation_group_id'],
      'status_code': before['status_code'],
      'note': before['note'],
      'source': before['source'],
      'created_at': before['created_at'],
      'updated_at': before['updated_at'],
    });
  }

  /// 최근 1회 변경 실행 취소
  Future<bool> undoLastChange() async {
    final db = await DatabaseService.openDatabaseFile();

    return await db.transaction((txn) async {
      final latestRows = await txn.rawQuery('''
        SELECT group_id
        FROM CHANGE_HISTORY
        WHERE undone_at IS NULL
        ORDER BY created_at DESC, id DESC
        LIMIT 1
        ''');

      if (latestRows.isEmpty) return false;

      final groupId = latestRows.first['group_id'] as String;

      final rows = await txn.query(
        'CHANGE_HISTORY',
        where: 'group_id = ? AND undone_at IS NULL',
        whereArgs: [groupId],
        orderBy: 'id DESC',
      );

      if (rows.isEmpty) return false;

      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw);
        final actionType = row['action_type'].toString();
        final entityType = row['entity_type'].toString();
        final beforeJsonText = row['before_json'] as String?;
        final afterJsonText = row['after_json'] as String?;

        final before = beforeJsonText == null
            ? null
            : Map<String, dynamic>.from(jsonDecode(beforeJsonText));
        final after = afterJsonText == null
            ? null
            : Map<String, dynamic>.from(jsonDecode(afterJsonText));

        if (actionType == 'create') {
          // 생성 취소 => 삭제
          if (entityType == 'word') {
            await txn.delete(
              'WORD_TABLE',
              where: 'id = ?',
              whereArgs: [after!['id']],
            );
          } else if (entityType == 'relation') {
            await txn.delete(
              'WORD_RELATION',
              where: 'id = ?',
              whereArgs: [after!['id']],
            );
          }
        } else if (actionType == 'update') {
          // 수정 취소 => before 복원
          if (entityType == 'word') {
            await txn.update(
              'WORD_TABLE',
              before!,
              where: 'id = ?',
              whereArgs: [before['id']],
            );
          } else if (entityType == 'relation') {
            await txn.update(
              'WORD_RELATION',
              before!,
              where: 'id = ?',
              whereArgs: [before['id']],
            );
          }
        } else if (actionType == 'delete') {
          // 삭제 취소 => before 복원
          if (entityType == 'word') {
            await txn.insert('WORD_TABLE', before!);
          } else if (entityType == 'relation') {
            await _restoreDeletedRelation(txn, before!);
          }
        }

        await txn.update(
          'CHANGE_HISTORY',
          {'undone_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }

      return true;
    });
  }
}
