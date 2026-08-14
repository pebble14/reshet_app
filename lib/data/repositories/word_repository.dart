import 'dart:convert';
import 'package:sqflite_common/sqlite_api.dart';
import '../../database/database_service.dart';
import '../adapters/legacy_word_expression_read_adapter.dart';
import '../adapters/normalized_word_expression_read_adapter.dart';
import '../adapters/legacy_word_expression_write_adapter.dart';
import '../adapters/normalized_word_expression_write_adapter.dart';
import '../models/approved_content_batch_models.dart';
import '../models/relation_category_lookup.dart';
import '../models/relation_status_lookup.dart';
import '../models/relation_type_lookup.dart';
import '../models/word.dart';
import '../../domain/expression/expression_read_models.dart';
import '../../domain/expression/pronunciation_notation.dart';
import '../../domain/graph/graph_center_word_display_item.dart';
import '../../domain/graph/graph_create_post_save_payload.dart';
import '../../domain/graph/graph_relation_add_search_result_item.dart';
import '../../domain/graph/graph_visible_word.dart';
import '../../domain/graph/graph_word_label_display_item.dart';
import '../../domain/expression/read_source_debug_collector.dart';
import '../../domain/expression/read_source_policy.dart';
import '../../domain/home/home_default_strong_list_item.dart';
import '../../domain/home/home_search_ranking_candidate.dart';
import '../../domain/home/home_search_result_display_item.dart';
import '../../domain/word/duplicate_candidate_display_item.dart';
import '../../domain/word/word_detail_like_display_item.dart';
import '../../domain/word/word_edit_seed.dart';
import '../../domain/word/word_write_models.dart';

/// 그래프 엣지(관계선) 표시를 위한 관계 메타 정보다.
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
  final String? statusCode;
  final String? statusLabel;
  final String? statusDescription;
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
    this.statusCode,
    this.statusLabel,
    this.statusDescription,
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
      statusCode: map['status_code'] as String?,
      statusLabel: map['status_label'] as String?,
      statusDescription: map['status_description'] as String?,
      description: map['description'] as String?,
      note: map['note'] as String?,
      source: map['source'] as String?,
    );
  }
}

typedef VisibleWordGraphData = ({
  List<GraphVisibleWord> connectedWords,
  List<GraphWordLabelDisplayItem> wordLabels,
  List<WordRelationEdgeInfo> relationEdges,
});

class UndoLastChangeResult {
  final bool didUndo;

  const UndoLastChangeResult({required this.didUndo});
}

final class _ApprovedMeaningPreparedChange {
  const _ApprovedMeaningPreparedChange({
    required this.replacement,
    required this.beforeHistory,
    required this.afterHistory,
    required this.afterRows,
  });

  final ApprovedContentMeaningReplacement replacement;
  final Map<String, dynamic> beforeHistory;
  final Map<String, dynamic> afterHistory;
  final List<Map<String, Object?>> afterRows;
}

final class _ApprovedWordNotePreparedChange {
  const _ApprovedWordNotePreparedChange({
    required this.replacement,
    required this.beforeHistory,
    required this.afterHistory,
  });

  final ApprovedContentWordNoteReplacement replacement;
  final Map<String, dynamic> beforeHistory;
  final Map<String, dynamic> afterHistory;
}

final class _ApprovedRelationPreparedChange {
  const _ApprovedRelationPreparedChange({required this.replacement});

  final ApprovedContentRelationReplacement replacement;
}

final class _RelationUpdateOutcome {
  const _RelationUpdateOutcome({required this.before, required this.after});

  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
}

final class _ApprovedContentBatchPreparedState {
  const _ApprovedContentBatchPreparedState({
    required this.meaningChanges,
    required this.wordNoteChanges,
    required this.relationChanges,
  });

  final List<_ApprovedMeaningPreparedChange> meaningChanges;
  final List<_ApprovedWordNotePreparedChange> wordNoteChanges;
  final List<_ApprovedRelationPreparedChange> relationChanges;
}

class _HomeStrongExactCandidate {
  final String wordId;
  final String strongNumber;

  const _HomeStrongExactCandidate({
    required this.wordId,
    required this.strongNumber,
  });
}

/// 단어·표현·의미·관계의 조회·쓰기 경계를 제공한다.
/// 화면별 typed contract를 구성하고 legacy map 경계의 호환을 유지한다.
class WordRepository {
  static const ReadSourcePolicy _defaultReadSourcePolicy =
      ReadSourcePolicy.legacy;
  static const String _detailScreenDisplayItemReadContext =
      'getWordDetailLikeDisplayItemByIdForDetailScreen';
  static const String _readForDetailEditSeedContext = 'readForDetailEditSeed';
  static const String _readForExplorerEditSeedContext =
      'readForExplorerEditSeed';
  static const String _readForGraphCreateEditSeedContext =
      'readForGraphCreateEditSeed';
  static const String _readForGraphCenterSingleWordContext =
      'readForGraphCenterSingleWord';
  static const String _readForGraphBatchContext = 'readForGraphBatch';
  static const String _readForGraphCreatePostSavePayloadContext =
      'readForGraphCreatePostSavePayload';
  static const String _readForSplitViewSingleWordContext =
      'readForSplitViewSingleWord';
  static const Set<String> _phase32HomeDisplayContexts = {
    'getStrongWordsMap',
    'searchStrongExactMap',
    'searchWordsMap',
  };
  static const Set<String> _phase4SplitViewSingleWordContexts = {
    _readForSplitViewSingleWordContext,
  };
  static const Set<String> _phase4GraphCenterSingleWordContexts = {
    _readForGraphCenterSingleWordContext,
  };
  static const Set<String> _phase4GraphBatchContexts = {
    _readForGraphBatchContext,
  };
  static const Set<String> _phaseGraphCreatePostSavePayloadContexts = {
    _readForGraphCreatePostSavePayloadContext,
  };
  static const Set<String> _canonicalExpressionAuthorityContexts = {
    _detailScreenDisplayItemReadContext,
    _readForDetailEditSeedContext,
    _readForExplorerEditSeedContext,
    _readForGraphCreateEditSeedContext,
    _readForGraphCenterSingleWordContext,
    _readForGraphBatchContext,
    _readForGraphCreatePostSavePayloadContext,
    _readForSplitViewSingleWordContext,
    'getStrongWordsMap',
    'searchStrongExactMap',
    'searchWordsMap',
  };
  static ReadSourcePolicy? _debugReadSourcePolicyOverride;
  static final List<String> _homeSearchSpellingColumns = List.unmodifiable(
    List.generate(6, (index) => '표기${index + 1}'),
  );
  static final List<String> _homeSearchTransliterationColumns =
      List.unmodifiable(List.generate(6, (index) => '음역${index + 1}'));
  static final List<String> _homeSearchLikeColumns = List.unmodifiable([
    '스트롱넘버',
  ]);
  static const List<String> _activeNormalizedWordTableColumns = [
    'id',
    '언어',
    '스트롱넘버',
    '비고',
    'graph_expand_mode',
  ];
  static const List<String> _wordCoreSnapshotColumns = [
    'id',
    '언어',
    '스트롱넘버',
    '비고',
  ];
  static const String _historyNormalizedExpressionRowsKey =
      '_normalized_expression_rows';
  static const String _historyNormalizedMeaningRowsKey =
      '_normalized_meaning_rows';
  static const String _materializedCanonicalMeaningValuesKey =
      '_canonical_meaning_values';
  static const String _materializedCanonicalExpressionSetsKey =
      '_canonical_expression_sets';
  static const List<String> _wordExpressionSetSnapshotColumns = [
    'word_id',
    'seq',
    'is_representative',
    'spelling',
    'transliteration',
    'pronunciation',
    'pronunciation_notation',
    'pronunciation_notation_name',
  ];
  static const List<String> _wordMeaningSetSnapshotColumns = [
    'word_id',
    'seq',
    'meaning',
  ];
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

  static ReadSourcePolicy get debugCurrentReadSourcePolicy =>
      _debugReadSourcePolicyOverride ?? _defaultReadSourcePolicy;

  static ReadSourceDebugCollector get debugReadSourceCollector =>
      ReadSourceDebugCollector.instance;

  static void debugSetReadSourcePolicyOverride(ReadSourcePolicy? policy) {
    _debugReadSourcePolicyOverride = policy;
  }

  Map<String, WordExpressionReadSnapshot>
  get debugLastWordExpressionReadSnapshots =>
      debugReadSourceCollector.debugLastSnapshotsByWord();

  List<WordExpressionReadSnapshot> get debugWordExpressionReadObservationLog =>
      debugReadSourceCollector.debugRecentSnapshots();

  void debugClearWordExpressionReadObservations() {
    debugReadSourceCollector.debugReset();
  }

  bool _usesCanonicalExpressionAuthority(String context) {
    return _canonicalExpressionAuthorityContexts.contains(context);
  }

  WordExpressionReadSnapshot? debugLastWordExpressionReadSnapshotFor(
    String wordId,
  ) {
    return debugReadSourceCollector.debugLastSnapshotForWord(wordId);
  }

  ReadSourcePolicy _resolveReadSourcePolicyForContext(String context) {
    final override = _debugReadSourcePolicyOverride;
    if (override != null) {
      return override;
    }

    if (context == _detailScreenDisplayItemReadContext ||
        context == _readForDetailEditSeedContext ||
        context == _readForExplorerEditSeedContext ||
        context == _readForGraphCreateEditSeedContext ||
        _phase32HomeDisplayContexts.contains(context) ||
        _phase4SplitViewSingleWordContexts.contains(context) ||
        _phase4GraphCenterSingleWordContexts.contains(context) ||
        _phase4GraphBatchContexts.contains(context) ||
        _phaseGraphCreatePostSavePayloadContexts.contains(context)) {
      return ReadSourcePolicy.normalizedOnly;
    }

    return _defaultReadSourcePolicy;
  }

  List<String>? _wordTableColumnsForExpressionReadContext(String context) {
    if (_resolveReadSourcePolicyForContext(context) ==
        ReadSourcePolicy.normalizedOnly) {
      return _activeNormalizedWordTableColumns;
    }
    return null;
  }

  String _wordTableProjectionForExpressionReadContext(String context) {
    final columns = _wordTableColumnsForExpressionReadContext(context);
    if (columns == null) {
      return 'wt.*';
    }
    return _wordTableProjectionSql(columns);
  }

  void _recordWordExpressionReadSnapshots(
    Iterable<WordExpressionReadSnapshot> snapshots,
  ) {
    debugReadSourceCollector.recordAll(snapshots);
  }

  Future<WordExpressionReadSnapshot?> debugInspectWordExpressionReadByWordId(
    String wordId, {
    String context = 'debugInspectWordExpressionReadByWordId',
  }) async {
    final normalizedId = wordId.trim();
    if (normalizedId.isEmpty) {
      return null;
    }

    final db = await DatabaseService.openDatabaseFile();
    final rows = await db.query(
      'WORD_TABLE',
      where: 'id = ?',
      whereArgs: [normalizedId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    final snapshots = await _resolveWordExpressionReadSnapshots(
      db,
      rows.map((row) => Map<String, dynamic>.from(row)),
      context: context,
    );
    _recordWordExpressionReadSnapshots(snapshots.values);
    return snapshots[normalizedId];
  }

  Map<String, dynamic> _copyWordCoreSnapshot(Map<String, dynamic> row) {
    final sanitized = <String, dynamic>{};
    for (final entry in row.entries) {
      if (_wordCoreSnapshotColumns.contains(entry.key)) {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }

  Map<String, dynamic> _sanitizeNewWordHistoryCoreSnapshot(
    Map<String, dynamic> row,
  ) {
    return _copyWordCoreSnapshot(row);
  }

  Map<String, dynamic> _sanitizeWordTableCoreDmlSnapshot(
    Map<String, dynamic> historySnapshot,
  ) {
    return _copyWordCoreSnapshot(historySnapshot);
  }

  Map<String, dynamic> _buildWordHistorySnapshot({
    required Map<String, dynamic> compatibilityWordSnapshot,
    required List<Map<String, dynamic>> normalizedExpressionRows,
    required List<Map<String, dynamic>> normalizedMeaningRows,
  }) {
    final snapshot = _sanitizeNewWordHistoryCoreSnapshot(
      Map<String, dynamic>.from(compatibilityWordSnapshot),
    );
    snapshot[_historyNormalizedExpressionRowsKey] =
        _cloneWordExpressionRowsForHistory(normalizedExpressionRows);
    snapshot[_historyNormalizedMeaningRowsKey] =
        _cloneWordMeaningRowsForHistory(normalizedMeaningRows);
    return snapshot;
  }

  List<Map<String, dynamic>> _cloneWordExpressionRowsForHistory(
    Iterable<Map<String, dynamic>> rows,
  ) {
    return List<Map<String, dynamic>>.unmodifiable(
      rows.map(
        (row) => {
          for (final column in _wordExpressionSetSnapshotColumns)
            column: row[column],
        },
      ),
    );
  }

  List<Map<String, dynamic>> _cloneWordMeaningRowsForHistory(
    Iterable<Map<String, dynamic>> rows,
  ) {
    return List<Map<String, dynamic>>.unmodifiable(
      rows.map(
        (row) => {
          for (final column in _wordMeaningSetSnapshotColumns)
            column: row[column],
        },
      ),
    );
  }

  List<Map<String, Object?>>? _readNormalizedExpressionRowsFromHistorySnapshot(
    Map<String, dynamic> historySnapshot,
  ) {
    if (!historySnapshot.containsKey(_historyNormalizedExpressionRowsKey)) {
      return null;
    }

    final rawRows = historySnapshot[_historyNormalizedExpressionRowsKey];
    if (rawRows is! List) {
      return const <Map<String, Object?>>[];
    }

    return List<Map<String, Object?>>.unmodifiable(
      rawRows.whereType<Map>().map((rawRow) {
        final row = Map<String, dynamic>.from(rawRow);
        return {
          for (final column in _wordExpressionSetSnapshotColumns)
            column: row[column],
        };
      }),
    );
  }

  List<Map<String, Object?>>? _readNormalizedMeaningRowsFromHistorySnapshot(
    Map<String, dynamic> historySnapshot,
  ) {
    if (!historySnapshot.containsKey(_historyNormalizedMeaningRowsKey)) {
      return null;
    }

    final rawRows = historySnapshot[_historyNormalizedMeaningRowsKey];
    if (rawRows is! List) {
      return const <Map<String, Object?>>[];
    }

    return List<Map<String, Object?>>.unmodifiable(
      rawRows.whereType<Map>().map((rawRow) {
        final row = Map<String, dynamic>.from(rawRow);
        return {
          for (final column in _wordMeaningSetSnapshotColumns)
            column: row[column],
        };
      }),
    );
  }

  Future<List<Map<String, dynamic>>> _loadWordExpressionSetRowsForHistory(
    DatabaseExecutor txn,
    String wordId,
  ) async {
    final rows = await txn.query(
      'word_expression_set',
      columns: _wordExpressionSetSnapshotColumns,
      where: 'word_id = ?',
      whereArgs: [wordId],
      orderBy: 'seq ASC, id ASC',
    );

    return _cloneWordExpressionRowsForHistory(
      rows.map((row) => Map<String, dynamic>.from(row)),
    );
  }

  Future<List<Map<String, dynamic>>> _loadWordMeaningSetRowsForHistory(
    DatabaseExecutor txn,
    String wordId,
  ) async {
    final rows = await txn.query(
      'word_meaning_set',
      columns: _wordMeaningSetSnapshotColumns,
      where: 'word_id = ?',
      whereArgs: [wordId],
      orderBy: 'seq ASC, id ASC',
    );

    return _cloneWordMeaningRowsForHistory(
      rows.map((row) => Map<String, dynamic>.from(row)),
    );
  }

  List<CanonicalExpressionWriteSet> _normalizeCanonicalExpressionSetsForWrite(
    List<CanonicalExpressionWriteSet> expressionSets,
  ) {
    final normalizedSets = <CanonicalExpressionWriteSet>[];

    for (final set in expressionSets) {
      final spelling = set.spelling.trim();
      if (spelling.isEmpty) {
        continue;
      }

      final seq = normalizedSets.length + 1;
      final pronunciation = normalizePronunciationForWrite(
        pronunciation: set.pronunciation,
        notation: set.pronunciationNotation,
        notationName: set.pronunciationNotationName,
      );
      normalizedSets.add(
        CanonicalExpressionWriteSet(
          spelling: spelling,
          transliteration: _trimWriteValueToNull(set.transliteration),
          pronunciation: pronunciation?.text,
          pronunciationNotation: pronunciation?.notation,
          pronunciationNotationName: pronunciation?.notationName,
          seq: seq,
          isRepresentative: seq == 1,
        ),
      );
    }

    return List<CanonicalExpressionWriteSet>.unmodifiable(normalizedSets);
  }

  List<Map<String, Object?>> _buildNormalizedExpressionRowsForWrite(
    String wordId,
    List<CanonicalExpressionWriteSet> canonicalExpressionSets,
  ) {
    final normalizedSets = canonicalExpressionSets
        .map(
          (set) => ExpressionSet(
            spelling: set.spelling,
            transliteration: set.transliteration,
            pronunciation: set.pronunciation,
            pronunciationNotation: set.pronunciationNotation,
            pronunciationNotationName: set.pronunciationNotationName,
            seq: set.seq,
            isRepresentative: set.isRepresentative,
          ),
        )
        .toList(growable: false);

    return toWordExpressionSetRows(wordId, normalizedSets);
  }

  List<Map<String, dynamic>> _buildNormalizedExpressionHistoryRows(
    Iterable<Map<String, Object?>> rows,
  ) {
    return _cloneWordExpressionRowsForHistory(
      rows.map((row) => Map<String, dynamic>.from(row)),
    );
  }

  List<String> _normalizeMeaningValuesForWrite(Iterable<String> meanings) {
    return meanings
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  List<Map<String, Object?>> _buildNormalizedMeaningRowsForWrite(
    String wordId,
    List<String> normalizedMeanings,
  ) {
    return List<Map<String, Object?>>.generate(
      normalizedMeanings.length,
      (index) => {
        'word_id': wordId,
        'seq': index + 1,
        'meaning': normalizedMeanings[index],
      },
      growable: false,
    );
  }

  String? _trimWriteValueToNull(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
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

  String? _normalizeNullableCode(String? value) {
    final normalized = (value ?? '').trim();
    return normalized.isEmpty ? null : normalized;
  }

  ReadFallbackObservation _buildFallbackObservation({
    required String wordId,
    required ReadSourcePolicy policy,
    required ReadFallbackReason reason,
    required String context,
    String? detail,
  }) {
    return ReadFallbackObservation(
      wordId: wordId,
      policy: policy,
      reason: reason,
      context: context,
      detail: detail,
    );
  }

  Future<void> _captureWordExpressionReadSnapshots(
    Database db,
    Iterable<Map<String, dynamic>> rows, {
    required String context,
  }) async {
    final snapshots = await _resolveWordExpressionReadSnapshots(
      db,
      rows,
      context: context,
    );
    _recordWordExpressionReadSnapshots(snapshots.values);
  }

  Future<Map<String, WordExpressionReadSnapshot>>
  _resolveWordExpressionReadSnapshots(
    Database db,
    Iterable<Map<String, dynamic>> rows, {
    required String context,
  }) async {
    final rowsByWordId = <String, Map<String, dynamic>>{};

    for (final rawRow in rows) {
      final row = Map<String, dynamic>.from(rawRow);
      final wordId = (row['id'] ?? '').toString().trim();
      if (wordId.isEmpty) {
        continue;
      }
      rowsByWordId[wordId] = row;
    }

    if (rowsByWordId.isEmpty) {
      return const {};
    }

    final policy = _resolveReadSourcePolicyForContext(context);
    final legacyResultsByWordId = <String, CanonicalExpressionReadResult>{};
    if (policy != ReadSourcePolicy.normalizedOnly) {
      for (final entry in rowsByWordId.entries) {
        legacyResultsByWordId[entry.key] = readLegacyWordExpressionRow(
          entry.value,
        );
      }
    }

    if (policy == ReadSourcePolicy.legacy) {
      return {
        for (final entry in rowsByWordId.entries)
          entry.key: WordExpressionReadSnapshot(
            wordId: entry.key,
            context: context,
            requestedPolicy: policy,
            resolvedSource: ResolvedReadSource.legacy,
            finalResultSource: FinalReadResultSource.legacy,
            readResult: legacyResultsByWordId[entry.key]!,
            legacyReadResult: legacyResultsByWordId[entry.key]!,
          ),
      };
    }

    late final Map<String, List<Map<String, dynamic>>> normalizedRowsByWordId;
    try {
      normalizedRowsByWordId = await _loadNormalizedExpressionRowsByWordIds(
        db,
        rowsByWordId.keys,
      );
    } catch (error) {
      return {
        for (final entry in rowsByWordId.entries)
          entry.key: _snapshotForNormalizedQueryFailure(
            wordId: entry.key,
            context: context,
            policy: policy,
            legacyResult: legacyResultsByWordId[entry.key],
            error: error,
          ),
      };
    }

    return {
      for (final entry in rowsByWordId.entries)
        entry.key: _resolveSnapshotFromPolicy(
          wordId: entry.key,
          context: context,
          policy: policy,
          legacyResult: legacyResultsByWordId[entry.key],
          normalizedRows: normalizedRowsByWordId[entry.key] ?? const [],
        ),
    };
  }

  Future<Map<String, List<Map<String, dynamic>>>>
  _loadNormalizedExpressionRowsByWordIds(
    Database db,
    Iterable<String> wordIds,
  ) async {
    final orderedWordIds = <String>[];
    final seenWordIds = <String>{};

    for (final wordId in wordIds) {
      final normalizedWordId = wordId.trim();
      if (normalizedWordId.isEmpty || !seenWordIds.add(normalizedWordId)) {
        continue;
      }
      orderedWordIds.add(normalizedWordId);
    }

    if (orderedWordIds.isEmpty) {
      return const {};
    }

    final placeholders = List.filled(orderedWordIds.length, '?').join(', ');
    final rows = await db.rawQuery('''
      SELECT
        id,
        word_id,
        seq,
        is_representative,
        spelling,
        transliteration,
        pronunciation,
        pronunciation_notation,
        pronunciation_notation_name
      FROM word_expression_set
      WHERE word_id IN ($placeholders)
      ORDER BY word_id ASC, seq ASC, id ASC
      ''', orderedWordIds);

    final rowsByWordId = <String, List<Map<String, dynamic>>>{};
    for (final rawRow in rows) {
      final row = Map<String, dynamic>.from(rawRow);
      final wordId = (row['word_id'] ?? '').toString().trim();
      if (wordId.isEmpty) {
        continue;
      }
      rowsByWordId.putIfAbsent(wordId, () => <Map<String, dynamic>>[]).add(row);
    }

    return rowsByWordId;
  }

  Future<List<Map<String, dynamic>>>
  _materializeCanonicalExpressionsForNormalRuntime(
    Database db,
    Iterable<Map<String, dynamic>> rows, {
    required String context,
  }) async {
    final rowList = rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
    if (rowList.isEmpty) {
      return const [];
    }

    final snapshots = await _resolveWordExpressionReadSnapshots(
      db,
      rowList,
      context: context,
    );

    return List<Map<String, dynamic>>.unmodifiable(
      rowList.map((row) {
        final wordId = (row['id'] ?? '').toString().trim();
        final snapshot = snapshots[wordId];
        if (snapshot == null ||
            snapshot.finalResultSource != FinalReadResultSource.normalized ||
            snapshot.normalizedReadResult == null) {
          return row;
        }

        return _materializeWordRowForDisplay(
          row,
          snapshot.normalizedReadResult!,
        );
      }),
    );
  }

  Future<List<Map<String, dynamic>>>
  _materializeCanonicalExpressionsForLegacyShapedCompatibility(
    Database db,
    Iterable<Map<String, dynamic>> rows,
  ) async {
    final rowList = rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
    if (rowList.isEmpty) {
      return const [];
    }

    final normalizedRowsByWordId = await _loadNormalizedExpressionRowsByWordIds(
      db,
      rowList.map((row) => (row['id'] ?? '').toString()),
    );

    return List<Map<String, dynamic>>.unmodifiable(
      rowList.map((row) {
        final wordId = (row['id'] ?? '').toString().trim();
        final normalizedRows = normalizedRowsByWordId[wordId] ?? const [];
        if (normalizedRows.isEmpty) {
          return _materializeWordRowForDisplay(
            row,
            const CanonicalExpressionReadResult(),
          );
        }

        final normalizedOutcome = readNormalizedWordExpressionRows(
          normalizedRows,
        );
        if (!normalizedOutcome.isSuccess) {
          return row;
        }

        return _materializeWordRowForDisplay(
          row,
          normalizedOutcome.readResult!,
        );
      }),
    );
  }

  WordExpressionReadSnapshot _snapshotForNormalizedQueryFailure({
    required String wordId,
    required String context,
    required ReadSourcePolicy policy,
    required CanonicalExpressionReadResult? legacyResult,
    required Object error,
  }) {
    final fallbackObservation = _buildFallbackObservation(
      wordId: wordId,
      policy: policy,
      reason: ReadFallbackReason.queryFailed,
      context: context,
      detail: error.toString(),
    );

    if (policy == ReadSourcePolicy.normalizedWithFallback) {
      final fallbackResult = legacyResult!;
      return WordExpressionReadSnapshot(
        wordId: wordId,
        context: context,
        requestedPolicy: policy,
        resolvedSource: ResolvedReadSource.legacy,
        finalResultSource: FinalReadResultSource.legacyFallback,
        readResult: fallbackResult,
        legacyReadResult: fallbackResult,
        fallbackObservation: fallbackObservation,
      );
    }

    return WordExpressionReadSnapshot(
      wordId: wordId,
      context: context,
      requestedPolicy: policy,
      resolvedSource: ResolvedReadSource.normalized,
      finalResultSource: FinalReadResultSource.normalizedFailure,
      readResult: const CanonicalExpressionReadResult(),
      legacyReadResult: legacyResult,
      fallbackObservation: fallbackObservation,
    );
  }

  WordExpressionReadSnapshot _resolveSnapshotFromPolicy({
    required String wordId,
    required String context,
    required ReadSourcePolicy policy,
    required CanonicalExpressionReadResult? legacyResult,
    required List<Map<String, dynamic>> normalizedRows,
  }) {
    final normalizedOutcome = readNormalizedWordExpressionRows(normalizedRows);
    if (normalizedOutcome.isSuccess) {
      return WordExpressionReadSnapshot(
        wordId: wordId,
        context: context,
        requestedPolicy: policy,
        resolvedSource: ResolvedReadSource.normalized,
        finalResultSource: FinalReadResultSource.normalized,
        readResult: normalizedOutcome.readResult!,
        legacyReadResult: legacyResult,
        normalizedReadResult: normalizedOutcome.readResult!,
      );
    }

    if (_usesCanonicalExpressionAuthority(context) &&
        normalizedOutcome.failureReason == ReadFallbackReason.emptyResult) {
      const emptyReadResult = CanonicalExpressionReadResult();
      return WordExpressionReadSnapshot(
        wordId: wordId,
        context: context,
        requestedPolicy: policy,
        resolvedSource: ResolvedReadSource.normalized,
        finalResultSource: FinalReadResultSource.normalized,
        readResult: emptyReadResult,
        legacyReadResult: legacyResult,
        normalizedReadResult: emptyReadResult,
      );
    }

    final fallbackObservation = _buildFallbackObservation(
      wordId: wordId,
      policy: policy,
      reason:
          normalizedOutcome.failureReason ?? ReadFallbackReason.mappingInvalid,
      context: context,
      detail: normalizedOutcome.detail,
    );

    if (policy == ReadSourcePolicy.normalizedWithFallback) {
      final fallbackResult = legacyResult!;
      return WordExpressionReadSnapshot(
        wordId: wordId,
        context: context,
        requestedPolicy: policy,
        resolvedSource: ResolvedReadSource.legacy,
        finalResultSource: FinalReadResultSource.legacyFallback,
        readResult: fallbackResult,
        legacyReadResult: fallbackResult,
        fallbackObservation: fallbackObservation,
      );
    }

    return WordExpressionReadSnapshot(
      wordId: wordId,
      context: context,
      requestedPolicy: policy,
      resolvedSource: ResolvedReadSource.normalized,
      finalResultSource: FinalReadResultSource.normalizedFailure,
      readResult: const CanonicalExpressionReadResult(),
      legacyReadResult: legacyResult,
      fallbackObservation: fallbackObservation,
    );
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

  List<ExpressionSet> _cloneExpressionSetsForMaterialization(
    Iterable<ExpressionSet> sets,
  ) {
    return List<ExpressionSet>.unmodifiable(
      sets.map(
        (set) => ExpressionSet(
          spelling: set.spelling,
          transliteration: set.transliteration,
          pronunciation: set.pronunciation,
          pronunciationNotation: set.pronunciationNotation,
          pronunciationNotationName: set.pronunciationNotationName,
          seq: set.seq,
          isRepresentative: set.isRepresentative,
        ),
      ),
    );
  }

  List<ExpressionSet>? _readMaterializedCanonicalExpressionSets(
    Map<String, dynamic> wordRow,
  ) {
    if (!wordRow.containsKey(_materializedCanonicalExpressionSetsKey)) {
      return null;
    }

    final rawSets = wordRow[_materializedCanonicalExpressionSetsKey];
    if (rawSets is List<ExpressionSet>) {
      return List<ExpressionSet>.unmodifiable(rawSets);
    }

    if (rawSets is List) {
      return List<ExpressionSet>.unmodifiable(
        rawSets.whereType<Map>().map((rawSet) {
          final set = Map<String, dynamic>.from(rawSet);
          final pronunciation = readStoredPronunciation(
            pronunciation: set['pronunciation'],
            notationCode: set['pronunciation_notation'],
            notationName: set['pronunciation_notation_name'],
          );
          return ExpressionSet(
            spelling: (set['spelling'] ?? '').toString(),
            transliteration: set['transliteration'] as String?,
            pronunciation: pronunciation?.text,
            pronunciationNotation: pronunciation?.notation,
            pronunciationNotationName: pronunciation?.notationName,
            seq: set['seq'] is int
                ? set['seq'] as int
                : int.tryParse((set['seq'] ?? '').toString()) ?? 0,
            isRepresentative:
                set['is_representative'] == true ||
                set['is_representative'] == 1,
          );
        }),
      );
    }

    return const [];
  }

  CanonicalExpressionReadResult _readExpressionReadResultFromWordRow(
    Map<String, dynamic> wordRow,
  ) {
    final materializedSets = _readMaterializedCanonicalExpressionSets(wordRow);
    if (materializedSets != null) {
      return CanonicalExpressionReadResult(sets: materializedSets);
    }

    return readLegacyWordExpressionRow(wordRow);
  }

  ExpressionSet? _primaryExpressionSetForDisplay(List<ExpressionSet> sets) {
    if (sets.isEmpty) {
      return null;
    }

    return sets.firstWhere(
      (set) => set.isRepresentative,
      orElse: () => sets.first,
    );
  }

  Map<String, dynamic> _materializeWordRowForDisplay(
    Map<String, dynamic> legacyWordRow,
    CanonicalExpressionReadResult readResult,
  ) {
    final orderedSets = _cloneExpressionSetsForMaterialization(readResult.sets);
    final materializedRow = Map<String, dynamic>.from(legacyWordRow);
    final legacyExpressionColumns = toLegacyWordExpressionColumns(
      orderedSets
          .map(
            (set) => CanonicalExpressionWriteSet(
              spelling: set.spelling,
              transliteration: set.transliteration,
              pronunciation: set.pronunciation,
              pronunciationNotation: set.pronunciationNotation,
              pronunciationNotationName: set.pronunciationNotationName,
              seq: set.seq,
              isRepresentative: set.isRepresentative,
            ),
          )
          .toList(growable: false),
    );

    materializedRow[_materializedCanonicalExpressionSetsKey] = orderedSets;
    materializedRow.addAll(legacyExpressionColumns);
    return materializedRow;
  }

  Future<Map<String, List<Map<String, dynamic>>>>
  _loadNormalizedMeaningRowsByWordIds(
    DatabaseExecutor db,
    Iterable<String> wordIds,
  ) async {
    final orderedWordIds = <String>[];
    final seenWordIds = <String>{};

    for (final wordId in wordIds) {
      final normalizedWordId = wordId.trim();
      if (normalizedWordId.isEmpty || !seenWordIds.add(normalizedWordId)) {
        continue;
      }
      orderedWordIds.add(normalizedWordId);
    }

    if (orderedWordIds.isEmpty) {
      return const {};
    }

    final placeholders = List.filled(orderedWordIds.length, '?').join(', ');
    final rows = await db.rawQuery('''
      SELECT id, word_id, seq, meaning
      FROM word_meaning_set
      WHERE word_id IN ($placeholders)
      ORDER BY word_id ASC, seq ASC, id ASC
      ''', orderedWordIds);

    final rowsByWordId = <String, List<Map<String, dynamic>>>{};
    for (final rawRow in rows) {
      final row = Map<String, dynamic>.from(rawRow);
      final wordId = (row['word_id'] ?? '').toString().trim();
      if (wordId.isEmpty) {
        continue;
      }
      rowsByWordId.putIfAbsent(wordId, () => <Map<String, dynamic>>[]).add(row);
    }

    return rowsByWordId;
  }

  List<String> _meaningValuesFromNormalizedRows(
    Iterable<Map<String, dynamic>> rows,
  ) {
    return List<String>.unmodifiable(
      rows
          .map((row) => (row['meaning'] ?? '').toString().trim())
          .where((meaning) => meaning.isNotEmpty),
    );
  }

  Map<String, dynamic> _materializeCanonicalMeaningsForDisplay(
    Map<String, dynamic> wordRow,
    List<String> meanings,
  ) {
    final materializedRow = Map<String, dynamic>.from(wordRow);
    materializedRow[_materializedCanonicalMeaningValuesKey] =
        List<String>.unmodifiable(meanings);

    final projectionCount = meanings.length > 7 ? meanings.length : 7;
    for (var index = 1; index <= projectionCount; index++) {
      materializedRow['의미$index'] = index <= meanings.length
          ? meanings[index - 1]
          : null;
    }

    return materializedRow;
  }

  Future<List<Map<String, dynamic>>>
  _materializeCanonicalMeaningsForNormalRuntime(
    DatabaseExecutor db,
    Iterable<Map<String, dynamic>> rows,
  ) async {
    final rowList = rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
    if (rowList.isEmpty) {
      return const [];
    }

    late final Map<String, List<Map<String, dynamic>>> rowsByWordId;
    try {
      rowsByWordId = await _loadNormalizedMeaningRowsByWordIds(
        db,
        rowList.map((row) => (row['id'] ?? row['word_id'] ?? '').toString()),
      );
    } on DatabaseException catch (error) {
      final message = error.toString();
      if (message.contains('no such table') &&
          message.contains('word_meaning_set')) {
        return List<Map<String, dynamic>>.unmodifiable(rowList);
      }
      rethrow;
    }

    return List<Map<String, dynamic>>.unmodifiable(
      rowList.map((row) {
        final wordId = (row['id'] ?? row['word_id'] ?? '').toString().trim();
        final meanings = _meaningValuesFromNormalizedRows(
          rowsByWordId[wordId] ?? const <Map<String, dynamic>>[],
        );
        return _materializeCanonicalMeaningsForDisplay(row, meanings);
      }),
    );
  }

  List<String> _readMeaningValuesFromWordRow(Map<String, dynamic> wordRow) {
    if (wordRow.containsKey(_materializedCanonicalMeaningValuesKey)) {
      final rawValues = wordRow[_materializedCanonicalMeaningValuesKey];
      if (rawValues is List) {
        return List<String>.unmodifiable(
          rawValues
              .map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty),
        );
      }
      return const [];
    }

    return const [];
  }

  List<HomeSearchRankingValue> _readHomeSearchMeaningRankingValues(
    Map<String, dynamic> row,
  ) {
    final meanings = _readMeaningValuesFromWordRow(row);
    return List<HomeSearchRankingValue>.unmodifiable(
      List.generate(
        meanings.length,
        (index) => HomeSearchRankingValue(
          value: meanings[index],
          fieldIndex: index + 1,
        ),
        growable: false,
      ),
    );
  }

  String _readPrimaryMeaningFromWordRow(Map<String, dynamic> wordRow) {
    final meanings = _readMeaningValuesFromWordRow(wordRow);
    return meanings.isEmpty ? '' : meanings.first;
  }

  String _readTrimmedWordValue(Map<String, dynamic> wordRow, String key) {
    return (wordRow[key] ?? '').toString().trim();
  }

  List<String> _collectWordEditSeedMeanings(Map<String, dynamic> wordRow) {
    return _readMeaningValuesFromWordRow(wordRow);
  }

  WordEditSeed buildWordEditSeedFromWordRow(Map<String, dynamic> wordRow) {
    final expressionReadResult = _readExpressionReadResultFromWordRow(wordRow);

    return WordEditSeed(
      wordId: (wordRow['id'] ?? '').toString(),
      language: (wordRow['언어'] ?? '').toString(),
      strongNumber: (wordRow['스트롱넘버'] ?? '').toString(),
      note: (wordRow['비고'] ?? '').toString(),
      meanings: _collectWordEditSeedMeanings(wordRow),
      expressionReadResult: expressionReadResult,
      hiddenSlotIssues: buildWordEditHiddenSlotIssuesFromReadResult(
        expressionReadResult,
      ),
    );
  }

  List<String> _collectUniqueNonEmptyWordValues(Iterable<String?> values) {
    final normalizedValues = <String>[];
    for (final value in values) {
      final trimmed = (value ?? '').trim();
      if (trimmed.isEmpty || normalizedValues.contains(trimmed)) {
        continue;
      }
      normalizedValues.add(trimmed);
    }
    return List<String>.unmodifiable(normalizedValues);
  }

  ({
    String representativeSpelling,
    List<String> spellings,
    List<String> transliterations,
    List<String> pronunciations,
    List<String> meanings,
    String language,
    String strongNumber,
    String note,
  })
  _buildWordDetailDisplaySignature(Map<String, dynamic> wordRow) {
    final readResult = _readExpressionReadResultFromWordRow(wordRow);
    final representativeSpelling =
        (_primaryExpressionSetForDisplay(readResult.sets)?.spelling ?? '')
            .trim();

    return (
      representativeSpelling: representativeSpelling,
      spellings: _collectUniqueNonEmptyWordValues(
        readResult.sets.map((set) => set.spelling),
      ),
      transliterations: _collectUniqueNonEmptyWordValues(
        readResult.sets.map((set) => set.transliteration),
      ),
      pronunciations: _collectUniqueNonEmptyWordValues(
        readResult.sets.map((set) => set.pronunciationValue?.formattedText),
      ),
      meanings: _readMeaningValuesFromWordRow(wordRow),
      language: _readTrimmedWordValue(wordRow, '언어'),
      strongNumber: _readTrimmedWordValue(wordRow, '스트롱넘버'),
      note: _readTrimmedWordValue(wordRow, '비고'),
    );
  }

  bool _sameTrimmedStringLists(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }

  ({String strongNumber, String representativeSpelling})
  _buildStrongListDisplaySignature(Map<String, dynamic> wordRow) {
    final readResult = _readExpressionReadResultFromWordRow(wordRow);
    final representativeSpelling =
        (_primaryExpressionSetForDisplay(readResult.sets)?.spelling ?? '')
            .trim();

    return (
      strongNumber: _readTrimmedWordValue(wordRow, '스트롱넘버'),
      representativeSpelling: representativeSpelling,
    );
  }

  bool _sameStrongListDisplaySignature(
    ({String strongNumber, String representativeSpelling}) left,
    ({String strongNumber, String representativeSpelling}) right,
  ) {
    return left.strongNumber == right.strongNumber;
  }

  String _describeStrongListDisplayMismatch(
    ({String strongNumber, String representativeSpelling}) legacyDisplay,
    ({String strongNumber, String representativeSpelling}) normalizedDisplay,
  ) {
    final mismatchedFields = <String>[];

    if (legacyDisplay.strongNumber != normalizedDisplay.strongNumber) {
      mismatchedFields.add('strong_number');
    }

    if (mismatchedFields.isEmpty) {
      return 'strong-list display signature mismatch';
    }

    return 'strong-list display fields mismatch: ${mismatchedFields.join(', ')}';
  }

  HomeDefaultStrongListItem _buildHomeDefaultStrongListDisplayContract(
    Map<String, dynamic> wordRow,
  ) {
    final displaySignature = _buildStrongListDisplaySignature(wordRow);

    return HomeDefaultStrongListItem(
      wordId: _readTrimmedWordValue(wordRow, 'id'),
      displayStrongNumber: _normalizeStrongValue(displaySignature.strongNumber),
      representativeSpelling: displaySignature.representativeSpelling,
    );
  }

  bool _sameHomeDefaultStrongListDisplayContract(
    HomeDefaultStrongListItem left,
    HomeDefaultStrongListItem right,
  ) {
    if (left.wordId != right.wordId) {
      return false;
    }

    return _sameStrongListDisplaySignature(
      (
        strongNumber: left.displayStrongNumber,
        representativeSpelling: left.representativeSpelling,
      ),
      (
        strongNumber: right.displayStrongNumber,
        representativeSpelling: right.representativeSpelling,
      ),
    );
  }

  String _describeHomeDefaultStrongListDisplayMismatch(
    HomeDefaultStrongListItem legacyDisplay,
    HomeDefaultStrongListItem normalizedDisplay,
  ) {
    final signatureDetail = _describeStrongListDisplayMismatch(
      (
        strongNumber: legacyDisplay.displayStrongNumber,
        representativeSpelling: legacyDisplay.representativeSpelling,
      ),
      (
        strongNumber: normalizedDisplay.displayStrongNumber,
        representativeSpelling: normalizedDisplay.representativeSpelling,
      ),
    );

    if (legacyDisplay.wordId == normalizedDisplay.wordId) {
      return signatureDetail
          .replaceFirst(
            'strong-list display signature',
            'home default strong-list display contract',
          )
          .replaceFirst(
            'strong-list display fields',
            'home default strong-list display contract fields',
          );
    }

    return 'home default strong-list display contract fields mismatch: word_id, '
        '${signatureDetail.replaceFirst('strong-list display fields mismatch: ', '')}';
  }

  ({
    String strongNumber,
    String representativeSpelling,
    String representativeTransliteration,
    String representativePronunciation,
    String subtitleMeaning,
  })
  _buildSearchResultDisplaySignature(Map<String, dynamic> wordRow) {
    final readResult = _readExpressionReadResultFromWordRow(wordRow);
    final representativeSet = _primaryExpressionSetForDisplay(readResult.sets);

    return (
      strongNumber: _readTrimmedWordValue(wordRow, '스트롱넘버'),
      representativeSpelling: (representativeSet?.spelling ?? '').trim(),
      representativeTransliteration: (representativeSet?.transliteration ?? '')
          .trim(),
      representativePronunciation:
          representativeSet?.pronunciationValue?.formattedText ?? '',
      subtitleMeaning: _readPrimaryMeaningFromWordRow(wordRow),
    );
  }

  bool _sameSearchResultDisplaySignature(
    ({
      String strongNumber,
      String representativeSpelling,
      String representativeTransliteration,
      String representativePronunciation,
      String subtitleMeaning,
    })
    left,
    ({
      String strongNumber,
      String representativeSpelling,
      String representativeTransliteration,
      String representativePronunciation,
      String subtitleMeaning,
    })
    right,
  ) {
    return left.strongNumber == right.strongNumber &&
        left.representativeSpelling == right.representativeSpelling &&
        left.representativeTransliteration ==
            right.representativeTransliteration &&
        left.representativePronunciation == right.representativePronunciation &&
        left.subtitleMeaning == right.subtitleMeaning;
  }

  String _describeSearchResultDisplayMismatch(
    ({
      String strongNumber,
      String representativeSpelling,
      String representativeTransliteration,
      String representativePronunciation,
      String subtitleMeaning,
    })
    legacyDisplay,
    ({
      String strongNumber,
      String representativeSpelling,
      String representativeTransliteration,
      String representativePronunciation,
      String subtitleMeaning,
    })
    normalizedDisplay,
  ) {
    final mismatchedFields = <String>[];

    if (legacyDisplay.strongNumber != normalizedDisplay.strongNumber) {
      mismatchedFields.add('strong_number');
    }
    if (legacyDisplay.representativeSpelling !=
        normalizedDisplay.representativeSpelling) {
      mismatchedFields.add('representative_spelling');
    }
    if (legacyDisplay.representativeTransliteration !=
        normalizedDisplay.representativeTransliteration) {
      mismatchedFields.add('representative_transliteration');
    }
    if (legacyDisplay.representativePronunciation !=
        normalizedDisplay.representativePronunciation) {
      mismatchedFields.add('representative_pronunciation');
    }
    if (legacyDisplay.subtitleMeaning != normalizedDisplay.subtitleMeaning) {
      mismatchedFields.add('subtitle_meaning');
    }

    if (mismatchedFields.isEmpty) {
      return 'search-result display signature mismatch';
    }

    return 'search-result display fields mismatch: ${mismatchedFields.join(', ')}';
  }

  bool _sameWordDetailDisplaySignature(
    ({
      String representativeSpelling,
      List<String> spellings,
      List<String> transliterations,
      List<String> pronunciations,
      List<String> meanings,
      String language,
      String strongNumber,
      String note,
    })
    left,
    ({
      String representativeSpelling,
      List<String> spellings,
      List<String> transliterations,
      List<String> pronunciations,
      List<String> meanings,
      String language,
      String strongNumber,
      String note,
    })
    right,
  ) {
    return left.representativeSpelling == right.representativeSpelling &&
        _sameTrimmedStringLists(left.spellings, right.spellings) &&
        _sameTrimmedStringLists(
          left.transliterations,
          right.transliterations,
        ) &&
        _sameTrimmedStringLists(left.pronunciations, right.pronunciations) &&
        _sameTrimmedStringLists(left.meanings, right.meanings) &&
        left.language == right.language &&
        left.strongNumber == right.strongNumber &&
        left.note == right.note;
  }

  String _describeWordDetailDisplayMismatch(
    ({
      String representativeSpelling,
      List<String> spellings,
      List<String> transliterations,
      List<String> pronunciations,
      List<String> meanings,
      String language,
      String strongNumber,
      String note,
    })
    legacyDisplay,
    ({
      String representativeSpelling,
      List<String> spellings,
      List<String> transliterations,
      List<String> pronunciations,
      List<String> meanings,
      String language,
      String strongNumber,
      String note,
    })
    normalizedDisplay,
  ) {
    final mismatchedFields = <String>[];

    if (legacyDisplay.representativeSpelling !=
        normalizedDisplay.representativeSpelling) {
      mismatchedFields.add('representative_spelling');
    }
    if (!_sameTrimmedStringLists(
      legacyDisplay.spellings,
      normalizedDisplay.spellings,
    )) {
      mismatchedFields.add('spelling_list');
    }
    if (!_sameTrimmedStringLists(
      legacyDisplay.transliterations,
      normalizedDisplay.transliterations,
    )) {
      mismatchedFields.add('transliteration_list');
    }
    if (!_sameTrimmedStringLists(
      legacyDisplay.pronunciations,
      normalizedDisplay.pronunciations,
    )) {
      mismatchedFields.add('pronunciation_list');
    }
    if (!_sameTrimmedStringLists(
      legacyDisplay.meanings,
      normalizedDisplay.meanings,
    )) {
      mismatchedFields.add('meaning_list');
    }
    if (legacyDisplay.language != normalizedDisplay.language) {
      mismatchedFields.add('language');
    }
    if (legacyDisplay.strongNumber != normalizedDisplay.strongNumber) {
      mismatchedFields.add('strong_number');
    }
    if (legacyDisplay.note != normalizedDisplay.note) {
      mismatchedFields.add('note');
    }

    if (mismatchedFields.isEmpty) {
      return 'display signature mismatch';
    }

    return 'display fields mismatch: ${mismatchedFields.join(', ')}';
  }

  ({Map<String, dynamic> wordRow, WordExpressionReadSnapshot snapshot})
  _resolveWordRowForDetailLikeDisplay({
    required Map<String, dynamic> legacyWordRow,
    required WordExpressionReadSnapshot snapshot,
  }) {
    if (snapshot.finalResultSource != FinalReadResultSource.normalized ||
        snapshot.normalizedReadResult == null) {
      return (
        wordRow: Map<String, dynamic>.from(legacyWordRow),
        snapshot: snapshot,
      );
    }

    final normalizedWordRow = _materializeWordRowForDisplay(
      legacyWordRow,
      snapshot.normalizedReadResult!,
    );

    if (snapshot.requestedPolicy != ReadSourcePolicy.normalizedWithFallback ||
        _usesCanonicalExpressionAuthority(snapshot.context)) {
      return (wordRow: normalizedWordRow, snapshot: snapshot);
    }

    final legacyDisplay = _buildWordDetailDisplaySignature(legacyWordRow);
    final normalizedDisplay = _buildWordDetailDisplaySignature(
      normalizedWordRow,
    );

    if (_sameWordDetailDisplaySignature(legacyDisplay, normalizedDisplay)) {
      return (wordRow: normalizedWordRow, snapshot: snapshot);
    }

    final fallbackObservation = _buildFallbackObservation(
      wordId: snapshot.wordId,
      policy: snapshot.requestedPolicy,
      reason: ReadFallbackReason.userVisibleDisplayMismatch,
      context: snapshot.context,
      detail: _describeWordDetailDisplayMismatch(
        legacyDisplay,
        normalizedDisplay,
      ),
    );

    return (
      wordRow: Map<String, dynamic>.from(legacyWordRow),
      snapshot: snapshot.copyWith(
        resolvedSource: ResolvedReadSource.legacy,
        finalResultSource: FinalReadResultSource.legacyFallback,
        readResult:
            snapshot.legacyReadResult ?? const CanonicalExpressionReadResult(),
        fallbackObservation: fallbackObservation,
      ),
    );
  }

  ({Map<String, dynamic> wordRow, WordExpressionReadSnapshot snapshot})
  _resolveWordRowForHomeDisplayPhase32({
    required Map<String, dynamic> legacyWordRow,
    required WordExpressionReadSnapshot snapshot,
  }) {
    if (snapshot.finalResultSource != FinalReadResultSource.normalized ||
        snapshot.normalizedReadResult == null) {
      return (
        wordRow: Map<String, dynamic>.from(legacyWordRow),
        snapshot: snapshot,
      );
    }

    final normalizedWordRow = _materializeWordRowForDisplay(
      legacyWordRow,
      snapshot.normalizedReadResult!,
    );

    if (snapshot.requestedPolicy != ReadSourcePolicy.normalizedWithFallback ||
        _usesCanonicalExpressionAuthority(snapshot.context)) {
      return (wordRow: normalizedWordRow, snapshot: snapshot);
    }

    if (snapshot.context == 'getStrongWordsMap') {
      final legacyDisplay = _buildHomeDefaultStrongListDisplayContract(
        legacyWordRow,
      );
      final normalizedDisplay = _buildHomeDefaultStrongListDisplayContract(
        normalizedWordRow,
      );

      if (_sameHomeDefaultStrongListDisplayContract(
        legacyDisplay,
        normalizedDisplay,
      )) {
        return (wordRow: normalizedWordRow, snapshot: snapshot);
      }

      final fallbackObservation = _buildFallbackObservation(
        wordId: snapshot.wordId,
        policy: snapshot.requestedPolicy,
        reason: ReadFallbackReason.userVisibleDisplayMismatch,
        context: snapshot.context,
        detail: _describeHomeDefaultStrongListDisplayMismatch(
          legacyDisplay,
          normalizedDisplay,
        ),
      );

      return (
        wordRow: Map<String, dynamic>.from(legacyWordRow),
        snapshot: snapshot.copyWith(
          resolvedSource: ResolvedReadSource.legacy,
          finalResultSource: FinalReadResultSource.legacyFallback,
          readResult:
              snapshot.legacyReadResult ??
              const CanonicalExpressionReadResult(),
          fallbackObservation: fallbackObservation,
        ),
      );
    }

    final legacyDisplay = _buildSearchResultDisplaySignature(legacyWordRow);
    final normalizedDisplay = _buildSearchResultDisplaySignature(
      normalizedWordRow,
    );

    if (_sameSearchResultDisplaySignature(legacyDisplay, normalizedDisplay)) {
      return (wordRow: normalizedWordRow, snapshot: snapshot);
    }

    final fallbackObservation = _buildFallbackObservation(
      wordId: snapshot.wordId,
      policy: snapshot.requestedPolicy,
      reason: ReadFallbackReason.userVisibleDisplayMismatch,
      context: snapshot.context,
      detail: _describeSearchResultDisplayMismatch(
        legacyDisplay,
        normalizedDisplay,
      ),
    );

    return (
      wordRow: Map<String, dynamic>.from(legacyWordRow),
      snapshot: snapshot.copyWith(
        resolvedSource: ResolvedReadSource.legacy,
        finalResultSource: FinalReadResultSource.legacyFallback,
        readResult:
            snapshot.legacyReadResult ?? const CanonicalExpressionReadResult(),
        fallbackObservation: fallbackObservation,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _resolveHomeDisplayRowsForPhase32(
    Database db,
    List<Map<String, dynamic>> legacyRows, {
    required String context,
  }) async {
    if (legacyRows.isEmpty) {
      return const [];
    }

    final snapshots = await _resolveWordExpressionReadSnapshots(
      db,
      legacyRows,
      context: context,
    );
    final resolvedRows = <Map<String, dynamic>>[];
    final resolvedSnapshots = <WordExpressionReadSnapshot>[];

    for (final legacyRow in legacyRows) {
      final wordId = (legacyRow['id'] ?? '').toString().trim();
      final snapshot = snapshots[wordId];
      if (snapshot == null) {
        resolvedRows.add(Map<String, dynamic>.from(legacyRow));
        continue;
      }

      final resolved = _resolveWordRowForHomeDisplayPhase32(
        legacyWordRow: legacyRow,
        snapshot: snapshot,
      );
      resolvedRows.add(resolved.wordRow);
      resolvedSnapshots.add(resolved.snapshot);
    }

    _recordWordExpressionReadSnapshots(resolvedSnapshots);
    return await _materializeCanonicalMeaningsForNormalRuntime(
      db,
      resolvedRows,
    );
  }

  String? _nullIfEmptyDisplayValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  WordDetailLikeDisplayItem _buildWordDetailLikeDisplayItem(
    Map<String, dynamic> wordRow,
  ) {
    final displaySignature = _buildWordDetailDisplaySignature(wordRow);
    final pronunciationItems = _readExpressionReadResultFromWordRow(wordRow)
        .sets
        .map((set) => set.pronunciationValue)
        .whereType<PronunciationValue>()
        .toList(growable: false);

    return WordDetailLikeDisplayItem(
      representativeSpelling: _nullIfEmptyDisplayValue(
        displaySignature.representativeSpelling,
      ),
      displayStrongNumber: _nullIfEmptyDisplayValue(
        _normalizeStrongValue(displaySignature.strongNumber),
      ),
      language: _nullIfEmptyDisplayValue(displaySignature.language),
      spellings: List<String>.unmodifiable(displaySignature.spellings),
      transliterations: List<String>.unmodifiable(
        displaySignature.transliterations,
      ),
      pronunciations: List<String>.unmodifiable(
        displaySignature.pronunciations,
      ),
      pronunciationItems: List<PronunciationValue>.unmodifiable(
        pronunciationItems,
      ),
      meanings: List<String>.unmodifiable(displaySignature.meanings),
      note: _nullIfEmptyDisplayValue(displaySignature.note),
    );
  }

  HomeDefaultStrongListItem _buildHomeDefaultStrongListItem(
    Map<String, dynamic> wordRow,
  ) {
    return _buildHomeDefaultStrongListDisplayContract(wordRow);
  }

  HomeSearchResultDisplayItem _buildHomeSearchResultDisplayItem(
    Map<String, dynamic> wordRow,
  ) {
    final displaySignature = _buildSearchResultDisplaySignature(wordRow);

    return HomeSearchResultDisplayItem(
      wordId: _readTrimmedWordValue(wordRow, 'id'),
      displayStrongNumber: _nullIfEmptyDisplayValue(
        _normalizeStrongValue(displaySignature.strongNumber),
      ),
      representativeSpelling: _nullIfEmptyDisplayValue(
        displaySignature.representativeSpelling,
      ),
      representativeTransliteration: _nullIfEmptyDisplayValue(
        displaySignature.representativeTransliteration,
      ),
      representativePronunciation: _nullIfEmptyDisplayValue(
        displaySignature.representativePronunciation,
      ),
      subtitleMeaning: _nullIfEmptyDisplayValue(
        displaySignature.subtitleMeaning,
      ),
    );
  }

  DuplicateCandidateDisplayItem _buildDuplicateCandidateDisplayItem(
    Map<String, dynamic> row,
  ) {
    return DuplicateCandidateDisplayItem(
      wordId: (row['word_id'] ?? '').toString().trim(),
      language: (row['language'] ?? '').toString().trim(),
      strongNumber: (row['strong_number'] ?? '').toString().trim(),
      representativeSpelling: (row['representative_spelling'] ?? '')
          .toString()
          .trim(),
      primaryMeaning: (row['primary_meaning'] ?? '').toString().trim(),
    );
  }

  GraphRelationAddSearchResultItem _buildGraphRelationAddSearchResultItem(
    Map<String, dynamic> row,
  ) {
    return GraphRelationAddSearchResultItem(
      wordId: (row['id'] ?? '').toString().trim(),
      representativeSpelling: (row['representative_spelling'] ?? '')
          .toString()
          .trim(),
      primaryMeaning: (row['primary_meaning'] ?? '').toString().trim(),
      displayStrongNumber: (row['display_strong_number'] ?? '')
          .toString()
          .trim(),
    );
  }

  GraphCenterWordDisplayItem _buildGraphCenterWordDisplayItem(
    Map<String, dynamic> row,
  ) {
    return GraphCenterWordDisplayItem(
      wordId: (row['word_id'] ?? '').toString().trim(),
      language: (row['language'] ?? '').toString().trim(),
      displayStrongNumber: _normalizeStrongValue(
        (row['display_strong_number'] ?? '').toString(),
      ),
      representativeSpelling: (row['representative_spelling'] ?? '')
          .toString()
          .trim(),
      representativeTransliteration:
          (row['representative_transliteration'] ?? '').toString().trim(),
      representativePronunciation: (row['representative_pronunciation'] ?? '')
          .toString()
          .trim(),
      primaryMeaning: (row['primary_meaning'] ?? '').toString().trim(),
    );
  }

  GraphWordLabelDisplayItem _buildGraphWordLabelDisplayItem(
    Map<String, dynamic> row,
  ) {
    return GraphWordLabelDisplayItem(
      wordId: (row['word_id'] ?? '').toString().trim(),
      representativeSpelling: (row['representative_spelling'] ?? '')
          .toString()
          .trim(),
      representativeTransliteration:
          (row['representative_transliteration'] ?? '').toString().trim(),
      displayStrongNumber: _normalizeStrongValue(
        (row['display_strong_number'] ?? '').toString(),
      ),
      language: (row['language'] ?? '').toString().trim(),
      primaryMeaning: (row['primary_meaning'] ?? '').toString().trim(),
    );
  }

  GraphCreatePostSavePayload _buildGraphCreatePostSavePayload(
    Map<String, dynamic> wordRow,
  ) {
    return GraphCreatePostSavePayload(
      wordId: (wordRow['id'] ?? '').toString().trim(),
      representativeSpelling: (wordRow['\uD45C\uAE301'] ?? '')
          .toString()
          .trim(),
    );
  }

  GraphVisibleWord _buildGraphVisibleWordFromRow(Map<String, dynamic> row) {
    return GraphVisibleWord(
      wordId: (row['id'] ?? '').toString().trim(),
      fallbackSpelling: (row['표기1'] ?? '').toString().trim(),
      fallbackStrongNumber: (row['스트롱넘버'] ?? '').toString().trim(),
      fallbackTransliteration: (row['음역1'] ?? '').toString().trim(),
    );
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Word _buildFallbackWordFromGraphVisibleWord(GraphVisibleWord word) {
    return Word(
      id: word.wordId,
      spelling1: _blankToNull(word.fallbackSpelling),
      strongNumber: _blankToNull(word.fallbackStrongNumber),
      transliteration1: _blankToNull(word.fallbackTransliteration),
    );
  }

  Future<List<HomeSearchResultDisplayItem>>
  _resolveHomeSearchDisplayItemsForPhase32(
    Database db,
    List<Map<String, dynamic>> legacyRows, {
    required String context,
  }) async {
    final displayRows = await _resolveHomeDisplayRowsForPhase32(
      db,
      legacyRows,
      context: context,
    );

    return List<HomeSearchResultDisplayItem>.unmodifiable(
      displayRows.map(_buildHomeSearchResultDisplayItem),
    );
  }

  Future<WordEditSeed?> getWordEditSeedForDetailEdit(String id) async {
    return _getWordEditSeedWithContext(
      id,
      context: _readForDetailEditSeedContext,
    );
  }

  Future<WordEditSeed?> getWordEditSeedForExplorerEdit(String id) async {
    return _getWordEditSeedWithContext(
      id,
      context: _readForExplorerEditSeedContext,
    );
  }

  Future<WordEditSeed?> getWordEditSeedForGraphCreateEdit(String id) async {
    return _getWordEditSeedWithContext(
      id,
      context: _readForGraphCreateEditSeedContext,
    );
  }

  Future<GraphCreatePostSavePayload?> getGraphCreatePostSavePayloadAfterEdit(
    String id,
  ) async {
    final wordRow = await _getResolvedWordRowForDetailLikeSingleWordRead(
      id,
      context: _readForGraphCreatePostSavePayloadContext,
    );
    if (wordRow == null) {
      return null;
    }

    final payload = _buildGraphCreatePostSavePayload(wordRow);
    if (payload.wordId.isEmpty) {
      return null;
    }
    return payload;
  }

  Future<WordEditSeed?> _getWordEditSeedWithContext(
    String id, {
    required String context,
  }) async {
    final wordRow = await _getResolvedWordRowForDetailLikeSingleWordRead(
      id,
      context: context,
      failClosedOnNormalizedFailure: true,
    );
    if (wordRow == null) {
      return null;
    }

    return buildWordEditSeedFromWordRow(wordRow);
  }

  Future<Map<String, dynamic>?> _getResolvedWordRowForDetailLikeSingleWordRead(
    String id, {
    required String context,
    bool failClosedOnNormalizedFailure = false,
  }) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return null;

    final db = await DatabaseService.openDatabaseFile();
    final rows = await db.query(
      'WORD_TABLE',
      columns: _wordTableColumnsForExpressionReadContext(context),
      where: 'id = ?',
      whereArgs: [normalizedId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final legacyWordRow = Map<String, dynamic>.from(rows.first);
    final snapshots = await _resolveWordExpressionReadSnapshots(db, [
      legacyWordRow,
    ], context: context);
    final snapshot = snapshots[normalizedId];
    if (snapshot == null) {
      final materializedRows =
          await _materializeCanonicalMeaningsForNormalRuntime(db, [
            legacyWordRow,
          ]);
      return materializedRows.single;
    }

    final resolvedResult = _resolveWordRowForDetailLikeDisplay(
      legacyWordRow: legacyWordRow,
      snapshot: snapshot,
    );
    _recordWordExpressionReadSnapshots([resolvedResult.snapshot]);
    if (failClosedOnNormalizedFailure &&
        resolvedResult.snapshot.requestedPolicy ==
            ReadSourcePolicy.normalizedOnly &&
        resolvedResult.snapshot.finalResultSource ==
            FinalReadResultSource.normalizedFailure) {
      return null;
    }
    final materializedRows =
        await _materializeCanonicalMeaningsForNormalRuntime(db, [
          resolvedResult.wordRow,
        ]);
    return materializedRows.single;
  }

  Future<WordDetailLikeDisplayItem?>
  _getWordDetailLikeDisplayItemByIdWithContext(
    String id, {
    required String context,
  }) async {
    final wordRow = await _getResolvedWordRowForDetailLikeSingleWordRead(
      id,
      context: context,
    );
    if (wordRow == null) {
      return null;
    }

    return _buildWordDetailLikeDisplayItem(wordRow);
  }

  /// Graph center display is graph-owned and stays separate from both the
  /// graph batch zone and the create-follow-up single-word path.
  Future<Map<String, dynamic>?> getWordMapByIdForGraphCenterSingleWord(
    String id,
  ) async {
    return _getResolvedWordRowForDetailLikeSingleWordRead(
      id,
      context: _readForGraphCenterSingleWordContext,
    );
  }

  Future<bool> wordExistsForGraphNavigation(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return false;

    final db = await DatabaseService.openDatabaseFile();
    final rows = await db.query(
      'WORD_TABLE',
      columns: const ['id'],
      where: 'id = ?',
      whereArgs: [normalizedId],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<GraphCenterWordDisplayItem?>
  getGraphCenterWordDisplayItemByIdForGraphCenterSingleWord(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return null;

    final db = await DatabaseService.openDatabaseFile();
    final rows = await db.rawQuery(
      '''
      WITH graph_center_display_projection AS (
        SELECT
          wt.id AS word_id,
          CASE
            WHEN representative_row.word_id IS NOT NULL
              THEN TRIM(COALESCE(representative_row.spelling, ''))
            WHEN fallback_row.word_id IS NOT NULL
              THEN TRIM(COALESCE(fallback_row.spelling, ''))
            ELSE ''
          END AS representative_spelling,
          CASE
            WHEN representative_row.word_id IS NOT NULL
              THEN TRIM(COALESCE(representative_row.transliteration, ''))
            WHEN fallback_row.word_id IS NOT NULL
              THEN TRIM(COALESCE(fallback_row.transliteration, ''))
            ELSE ''
          END AS representative_transliteration,
          CASE
            WHEN representative_row.word_id IS NOT NULL
              THEN TRIM(COALESCE(representative_row.pronunciation, ''))
            WHEN fallback_row.word_id IS NOT NULL
              THEN TRIM(COALESCE(fallback_row.pronunciation, ''))
            ELSE ''
          END AS representative_pronunciation
        FROM WORD_TABLE wt
        LEFT JOIN word_expression_set representative_row
          ON representative_row.word_id = wt.id
         AND representative_row.is_representative = 1
        LEFT JOIN word_expression_set fallback_row
          ON fallback_row.id = (
               SELECT wes.id
               FROM word_expression_set wes
               WHERE wes.word_id = wt.id
               ORDER BY wes.seq ASC, wes.id ASC
               LIMIT 1
             )
         AND representative_row.word_id IS NULL
      )
      SELECT
        wt.id AS word_id,
        TRIM(COALESCE(wt.\u{C5B8}\u{C5B4}, '')) AS language,
        TRIM(COALESCE(wt.\u{C2A4}\u{D2B8}\u{B871}\u{B118}\u{BC84}, ''))
          AS display_strong_number,
        graph_center_display_projection.representative_spelling
          AS representative_spelling,
        graph_center_display_projection.representative_transliteration
          AS representative_transliteration,
        graph_center_display_projection.representative_pronunciation
          AS representative_pronunciation,
        ${_canonicalPrimaryMeaningSql()} AS primary_meaning
      FROM WORD_TABLE wt
      INNER JOIN graph_center_display_projection
        ON graph_center_display_projection.word_id = wt.id
      WHERE wt.id = ?
      LIMIT 1
      ''',
      [normalizedId],
    );

    if (rows.isEmpty) return null;
    return _buildGraphCenterWordDisplayItem(rows.first);
  }

  Future<WordDetailLikeDisplayItem?>
  getWordDetailLikeDisplayItemByIdForSplitView(String id) async {
    return _getWordDetailLikeDisplayItemByIdWithContext(
      id,
      context: _readForSplitViewSingleWordContext,
    );
  }

  /// Detail screen-owned detail-like display read path.
  /// WordDetailScreen에서만 사용하고 다른 화면에서는 재사용하지 않는다.
  Future<WordDetailLikeDisplayItem?>
  getWordDetailLikeDisplayItemByIdForDetailScreen(String id) async {
    return _getWordDetailLikeDisplayItemByIdWithContext(
      id,
      context: _detailScreenDisplayItemReadContext,
    );
  }

  Future<Set<String>> probeExistingWordIdsForExplorerHistory(
    Iterable<String> candidateWordIds,
  ) async {
    final orderedIds = <String>[];
    final seenIds = <String>{};

    for (final candidateWordId in candidateWordIds) {
      final normalizedId = candidateWordId.trim();
      if (normalizedId.isEmpty || !seenIds.add(normalizedId)) {
        continue;
      }
      orderedIds.add(normalizedId);
    }

    if (orderedIds.isEmpty) {
      return const <String>{};
    }

    final db = await DatabaseService.openDatabaseFile();
    final placeholders = List.filled(orderedIds.length, '?').join(', ');
    // Probe 조회는 현재 collector에 기록하지 않는 의도된 관측 경계다.
    final rows = await db.rawQuery(
      'SELECT id FROM WORD_TABLE WHERE id IN ($placeholders)',
      orderedIds,
    );

    return rows
        .map((row) => (row['id'] ?? '').toString().trim())
        .where((wordId) => wordId.isNotEmpty)
        .toSet();
  }

  Future<List<Map<String, dynamic>>> getWordsByIds(List<String> wordIds) async {
    return _getWordsByIdsWithContext(wordIds, context: 'getWordsByIds');
  }

  Future<List<Map<String, dynamic>>> getWordsByIdsForGraphBatch(
    List<String> wordIds,
  ) async {
    return _getWordsByIdsForGraphBatchAdapter(
      wordIds,
      context: _readForGraphBatchContext,
    );
  }

  Future<List<Map<String, dynamic>>> _getWordsByIdsForGraphBatchAdapter(
    List<String> wordIds, {
    required String context,
  }) async {
    final orderedIds = <String>[];
    final seenIds = <String>{};

    for (final wordId in wordIds) {
      final normalizedId = wordId.trim();
      if (normalizedId.isEmpty) continue;
      if (seenIds.add(normalizedId)) {
        orderedIds.add(normalizedId);
      }
    }

    if (orderedIds.isEmpty) return const [];

    final db = await DatabaseService.openDatabaseFile();
    final placeholders = List.filled(orderedIds.length, '?').join(', ');
    final projectionSql = _wordTableProjectionForExpressionReadContext(context);
    final rawRows = await db.rawQuery('''
      SELECT
      $projectionSql
      FROM WORD_TABLE wt
      WHERE wt.id IN ($placeholders)
      ''', orderedIds);
    final legacyRows = rawRows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
    final legacyRowsById = <String, Map<String, dynamic>>{
      for (final row in legacyRows)
        (row['id'] as String): Map<String, dynamic>.from(row),
    };
    final snapshots = await _resolveWordExpressionReadSnapshots(
      db,
      legacyRows,
      context: context,
    );
    final resolvedRows = <Map<String, dynamic>>[];
    final resolvedSnapshots = <WordExpressionReadSnapshot>[];

    // Phase 4-E graph batch stays in its own adapter so the shared safe zone
    // can be reused without leaking detail/split collector context.
    for (final wordId in orderedIds) {
      final legacyWordRow = legacyRowsById[wordId];
      if (legacyWordRow == null) {
        continue;
      }

      final snapshot = snapshots[wordId];
      if (snapshot == null) {
        resolvedRows.add(Map<String, dynamic>.from(legacyWordRow));
        continue;
      }

      final resolved = _resolveWordRowForDetailLikeDisplay(
        legacyWordRow: legacyWordRow,
        snapshot: snapshot,
      );
      resolvedRows.add(resolved.wordRow);
      resolvedSnapshots.add(resolved.snapshot);
    }

    _recordWordExpressionReadSnapshots(resolvedSnapshots);
    return List<Map<String, dynamic>>.unmodifiable(resolvedRows);
  }

  Future<List<GraphWordLabelDisplayItem>>
  getWordLabelDisplayItemsByIdsForGraphBatch(List<String> wordIds) async {
    final orderedIds = <String>[];
    final seenIds = <String>{};

    for (final wordId in wordIds) {
      final normalizedId = wordId.trim();
      if (normalizedId.isEmpty) continue;
      if (seenIds.add(normalizedId)) {
        orderedIds.add(normalizedId);
      }
    }

    if (orderedIds.isEmpty) return const [];

    final db = await DatabaseService.openDatabaseFile();
    final placeholders = List.filled(orderedIds.length, '?').join(', ');
    final rows = await db.rawQuery('''
      WITH ${_representativeQueryProjectionCte()}
      SELECT
        wt.id AS word_id,
        representative_query_projection.representative_spelling
          AS representative_spelling,
        representative_query_projection.representative_transliteration
          AS representative_transliteration,
        TRIM(COALESCE(wt.스트롱넘버, '')) AS display_strong_number,
        TRIM(COALESCE(wt.언어, '')) AS language,
        ${_canonicalPrimaryMeaningSql()} AS primary_meaning
      FROM WORD_TABLE wt
      INNER JOIN representative_query_projection
        ON representative_query_projection.word_id = wt.id
      WHERE wt.id IN ($placeholders)
      ''', orderedIds);
    final labelsById = <String, GraphWordLabelDisplayItem>{
      for (final row in rows)
        (row['word_id'] ?? '').toString().trim():
            _buildGraphWordLabelDisplayItem(row),
    };

    return List<GraphWordLabelDisplayItem>.unmodifiable(
      orderedIds
          .map((wordId) => labelsById[wordId])
          .whereType<GraphWordLabelDisplayItem>(),
    );
  }

  Future<List<Map<String, dynamic>>> _getWordsByIdsWithContext(
    List<String> wordIds, {
    required String context,
  }) async {
    final orderedIds = <String>[];
    final seenIds = <String>{};

    for (final wordId in wordIds) {
      final normalizedId = wordId.trim();
      if (normalizedId.isEmpty) continue;
      if (seenIds.add(normalizedId)) {
        orderedIds.add(normalizedId);
      }
    }

    if (orderedIds.isEmpty) return const [];

    final db = await DatabaseService.openDatabaseFile();
    final placeholders = List.filled(orderedIds.length, '?').join(', ');
    final rawRows = await db.rawQuery(
      'SELECT * FROM WORD_TABLE WHERE id IN ($placeholders)',
      orderedIds,
    );
    final rows = rawRows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
    await _captureWordExpressionReadSnapshots(db, rows, context: context);
    final compatibilityRows =
        await _materializeCanonicalExpressionsForLegacyShapedCompatibility(
          db,
          rows,
        );

    final rowsById = <String, Map<String, dynamic>>{
      for (final row in compatibilityRows)
        (row['id'] as String): Map<String, dynamic>.from(row),
    };

    return orderedIds
        .map((rowId) => rowsById[rowId])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getRelationsForWord(String wordId) async {
    final normalizedId = wordId.trim();
    if (normalizedId.isEmpty) return const [];

    final db = await DatabaseService.openDatabaseFile();
    final rows = await db.rawQuery(
      '''
      SELECT
        id,
        word_id_1,
        word_id_2,
        category_code,
        relation_type,
        status_code,
        direction_code,
        description,
        relation_group_id,
        note,
        source,
        created_at,
        updated_at
      FROM WORD_RELATION
      WHERE word_id_1 = ?
         OR word_id_2 = ?
      ORDER BY id ASC
      ''',
      [normalizedId, normalizedId],
    );

    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
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
        COALESCE(rt.category_code, wr.category_code) AS category_code,
        rc.label AS category_label,
        wr.relation_type AS relation_type,
        rt.label AS relation_type_label,
        wr.status_code AS status_code,
        rs.label AS status_label,
        rs.description AS status_description,
        wr.note AS note,
        wr.source AS source
      FROM WORD_RELATION wr
      LEFT JOIN RELATION_TYPE rt
        ON rt.code = wr.relation_type
      LEFT JOIN RELATION_CATEGORY rc
        ON rc.code = COALESCE(rt.category_code, wr.category_code)
      LEFT JOIN RELATION_STATUS rs
        ON rs.code = wr.status_code
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

  /// 그래프의 최종 가시 단어 집합 내부에 존재하는 관계(엣지) 메타 정보 조회
  /// - 호출자는 synthetic placeholder를 제외한 실제 단어 id만 전달한다.
  /// - WORD_RELATION + RELATION_TYPE + RELATION_CATEGORY 조인 계약은
  ///   [getRelationEdges]와 동일하게 유지한다.
  Future<List<WordRelationEdgeInfo>> getRelationEdgesWithinWordIdsForGraph(
    Iterable<String> wordIds,
  ) async {
    final orderedWordIds =
        wordIds
            .map((wordId) => wordId.trim())
            .where((wordId) => wordId.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    if (orderedWordIds.length < 2) {
      return const <WordRelationEdgeInfo>[];
    }

    final db = await DatabaseService.openDatabaseFile();
    final placeholders = List<String>.filled(
      orderedWordIds.length,
      '?',
    ).join(', ');

    final rows = await db.rawQuery(
      '''
      SELECT
        wr.id AS relation_id,
        wr.word_id_1 AS word_id_1,
        wr.word_id_2 AS word_id_2,
        wr.direction_code AS direction_code,
        wr.description AS description,
        wr.relation_group_id AS relation_group_id,
        COALESCE(rt.category_code, wr.category_code) AS category_code,
        rc.label AS category_label,
        wr.relation_type AS relation_type,
        rt.label AS relation_type_label,
        wr.status_code AS status_code,
        rs.label AS status_label,
        rs.description AS status_description,
        wr.note AS note,
        wr.source AS source
      FROM WORD_RELATION wr
      LEFT JOIN RELATION_TYPE rt
        ON rt.code = wr.relation_type
      LEFT JOIN RELATION_CATEGORY rc
        ON rc.code = COALESCE(rt.category_code, wr.category_code)
      LEFT JOIN RELATION_STATUS rs
        ON rs.code = wr.status_code
      WHERE wr.word_id_1 IN ($placeholders)
        AND wr.word_id_2 IN ($placeholders)
      ORDER BY wr.id ASC
      ''',
      [...orderedWordIds, ...orderedWordIds],
    );

    return rows
        .map((row) {
          final wordId1 = row['word_id_1'] as String;
          final wordId2 = row['word_id_2'] as String;
          return WordRelationEdgeInfo.fromMap(
            row,
            centerWordId: wordId1,
            centerRelativeDirection: _resolveCenterRelativeDirection(
              centerWordId: wordId1,
              wordId1: wordId1,
              wordId2: wordId2,
              directionCode: row['direction_code'] as String?,
            ),
          );
        })
        .toList(growable: false);
  }

  /// 그래프 표시용 엣지 조회
  Future<List<WordRelationEdgeInfo>> getVisibleRelationEdgesForGraph(
    String centerWordId,
  ) async {
    return await getRelationEdges(centerWordId);
  }

  /// 그래프 표시용 연결 단어 조회
  /// - 숨김 정책은 builder/UI의 +N more와 maxNodes가 담당한다.
  Future<VisibleWordGraphData> getVisibleGraphData(String centerWordId) async {
    return _getVisibleGraphDataWithBatchLoader(
      centerWordId,
      loadWordRows: getWordsByIds,
    );
  }

  Future<VisibleWordGraphData> getVisibleGraphDataForGraph(
    String centerWordId,
  ) async {
    return _getVisibleGraphDataWithBatchLoader(
      centerWordId,
      loadWordRows: getWordsByIdsForGraphBatch,
    );
  }

  Future<VisibleWordGraphData> _getVisibleGraphDataWithBatchLoader(
    String centerWordId, {
    required Future<List<Map<String, dynamic>>> Function(List<String>)
    loadWordRows,
  }) async {
    final visibleEdges = await getVisibleRelationEdgesForGraph(centerWordId);
    if (visibleEdges.isEmpty) {
      final wordLabels = await getWordLabelDisplayItemsByIdsForGraphBatch([
        centerWordId,
      ]);
      return (
        connectedWords: const <GraphVisibleWord>[],
        wordLabels: wordLabels,
        relationEdges: visibleEdges,
      );
    }

    final orderedIds = <String>[];
    final seenIds = <String>{};
    for (final edge in visibleEdges) {
      if (seenIds.add(edge.otherWordId)) {
        orderedIds.add(edge.otherWordId);
      }
    }

    final rows = await loadWordRows(orderedIds);
    final wordLabels = await getWordLabelDisplayItemsByIdsForGraphBatch([
      centerWordId,
      ...orderedIds,
    ]);
    final wordsById = <String, GraphVisibleWord>{
      for (final row in rows)
        (row['id'] as String): _buildGraphVisibleWordFromRow(row),
    };
    final connectedWords = orderedIds
        .map((id) => wordsById[id])
        .whereType<GraphVisibleWord>()
        .toList(growable: false);

    return (
      connectedWords: connectedWords,
      wordLabels: wordLabels,
      relationEdges: visibleEdges,
    );
  }

  Future<List<Word>> getVisibleConnectedWordsForGraph(
    String centerWordId,
  ) async {
    final visibleGraphData = await getVisibleGraphDataForGraph(centerWordId);
    return visibleGraphData.connectedWords
        .map(_buildFallbackWordFromGraphVisibleWord)
        .toList(growable: false);
  }

  /// 주어진 단어 ID들 중에서
  /// DB 전체 기준 `(언어, representative spelling, representative transliteration)`
  /// 충돌군에 속한 ID 집합을 반환한다.
  /// - representative row가 있으면 해당 row를 그대로 사용한다.
  /// - representative row가 없을 때만 seq 우선 normalized row, 마지막으로 legacy slot을 검토한다.
  /// - representative transliteration이 비어 있는 항목은 기존 strong fallback 대상이므로 제외한다.
  Future<Set<String>>
  findWordIdsInDbWideLanguageSpellingTransliterationCollisionGroups(
    Iterable<String> wordIds,
  ) async {
    final normalizedWordIds = <String>[];
    final seenWordIds = <String>{};

    for (final wordId in wordIds) {
      final normalizedWordId = wordId.trim();
      if (normalizedWordId.isEmpty) continue;
      if (seenWordIds.add(normalizedWordId)) {
        normalizedWordIds.add(normalizedWordId);
      }
    }

    if (normalizedWordIds.isEmpty) {
      return const <String>{};
    }

    final db = await DatabaseService.openDatabaseFile();
    final placeholders = List.filled(normalizedWordIds.length, '?').join(', ');
    final rows = await db.rawQuery('''
      WITH ${_representativeQueryProjectionCte()},
      selected_words AS (
        SELECT
          word_id AS id,
          language_key,
          representative_spelling AS spelling_key,
          representative_transliteration AS transliteration_key
        FROM representative_query_projection
        WHERE word_id IN ($placeholders)
      ),
      db_collision_groups AS (
        SELECT
          language_key,
          representative_spelling AS spelling_key,
          representative_transliteration AS transliteration_key
        FROM representative_query_projection
        WHERE representative_spelling <> ''
          AND representative_transliteration <> ''
        GROUP BY
          language_key,
          representative_spelling,
          representative_transliteration
        HAVING COUNT(*) > 1
      )
      SELECT sw.id
      FROM selected_words sw
      INNER JOIN db_collision_groups dcg
        ON sw.language_key = dcg.language_key
       AND sw.spelling_key = dcg.spelling_key
       AND sw.transliteration_key = dcg.transliteration_key
      WHERE sw.spelling_key <> ''
        AND sw.transliteration_key <> ''
      ''', normalizedWordIds);

    return rows
        .map((row) => (row['id'] ?? '').toString().trim())
        .where((wordId) => wordId.isNotEmpty)
        .toSet();
  }

  /// WORD_TABLE에서 단어 목록을 일부 조회한다 (홈 화면 기본 리스트용)
  /// - 상세 화면에서 모든 컬럼을 보여주기 위해 Map 그대로 반환한다.
  Future<List<Map<String, dynamic>>> getWordsMap({int limit = 50}) async {
    final db = await DatabaseService.openDatabaseFile();
    final rows = await db.query('WORD_TABLE', limit: limit);
    final normalizedRows = rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
    await _captureWordExpressionReadSnapshots(
      db,
      normalizedRows,
      context: 'getWordsMap',
    );
    return normalizedRows;
  }

  /// 홈 화면 기본 리스트용 Strong 사전형 목록 조회
  /// - 스트롱넘버가 있고 prefix가 H/G인 항목만 반환한다.
  /// - 정렬은 H -> G -> 숫자 오름차순 -> id 순서로 고정한다.
  Future<List<HomeDefaultStrongListItem>> getStrongWordsMap({
    int? limit,
  }) async {
    final db = await DatabaseService.openDatabaseFile();
    final projectionSql = _wordTableProjectionForExpressionReadContext(
      'getStrongWordsMap',
    );
    final sql = StringBuffer('''
      SELECT
      $projectionSql
      FROM WORD_TABLE wt
      WHERE wt.스트롱넘버 IS NOT NULL
        AND TRIM(wt.스트롱넘버) <> ''
        AND UPPER(SUBSTR(TRIM(wt.스트롱넘버), 1, 1)) IN ('H', 'G')
      ORDER BY
        CASE UPPER(SUBSTR(TRIM(wt.스트롱넘버), 1, 1))
          WHEN 'H' THEN 0
          WHEN 'G' THEN 1
          ELSE 2
        END,
        CAST(SUBSTR(TRIM(wt.스트롱넘버), 2) AS INTEGER),
        wt.id
      ''');
    final args = <Object?>[];

    if (limit != null) {
      sql.writeln('LIMIT ?');
      args.add(limit);
    }

    final rows = await db.rawQuery(sql.toString(), args);
    final legacyRows = rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
    final displayRows = await _resolveHomeDisplayRowsForPhase32(
      db,
      legacyRows,
      context: 'getStrongWordsMap',
    );
    return List<HomeDefaultStrongListItem>.unmodifiable(
      displayRows.map(_buildHomeDefaultStrongListItem),
    );
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

  List<HomeSearchRankingValue> _readHomeSearchRankingValues(
    Map<String, dynamic> row,
    List<String> columns,
  ) {
    final values = <HomeSearchRankingValue>[];

    for (var index = 0; index < columns.length; index++) {
      final value = (row[columns[index]] ?? '').toString().trim();
      if (value.isEmpty) {
        continue;
      }
      values.add(HomeSearchRankingValue(value: value, fieldIndex: index + 1));
    }

    return List<HomeSearchRankingValue>.unmodifiable(values);
  }

  List<HomeSearchRankingValue> _readHomeSearchExpressionRankingValues(
    Map<String, dynamic> row,
    String? Function(ExpressionSet set) readValue,
  ) {
    final materializedSets = _readMaterializedCanonicalExpressionSets(row);
    if (materializedSets == null) {
      return const [];
    }

    final values = <HomeSearchRankingValue>[];
    for (final set in materializedSets) {
      final value = (readValue(set) ?? '').trim();
      if (value.isEmpty) {
        continue;
      }

      values.add(HomeSearchRankingValue(value: value, fieldIndex: set.seq));
    }

    return List<HomeSearchRankingValue>.unmodifiable(values);
  }

  HomeSearchRankingCandidate _buildHomeSearchRankingCandidate(
    Map<String, dynamic> row,
  ) {
    final materializedExpressionSets = _readMaterializedCanonicalExpressionSets(
      row,
    );

    return HomeSearchRankingCandidate(
      wordId: (row['id'] ?? '').toString(),
      strongNumber: (row['스트롱넘버'] ?? '').toString().trim(),
      indexedSpellings: materializedExpressionSets == null
          ? _readHomeSearchRankingValues(row, _homeSearchSpellingColumns)
          : _readHomeSearchExpressionRankingValues(row, (set) => set.spelling),
      indexedTransliterations: materializedExpressionSets == null
          ? _readHomeSearchRankingValues(row, _homeSearchTransliterationColumns)
          : _readHomeSearchExpressionRankingValues(
              row,
              (set) => set.transliteration,
            ),
      indexedMeanings: _readHomeSearchMeaningRankingValues(row),
    );
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
    List<HomeSearchRankingValue> values, {
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
    HomeSearchRankingCandidate candidate, {
    required String normalizedKeyword,
    required String? normalizedStrongKeyword,
  }) {
    final strong = candidate.strongNumber;
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

  ({int priority, int fieldIndex, int valueLength})? _rankHomeSearchCandidate(
    HomeSearchRankingCandidate candidate, {
    required String normalizedKeyword,
    required String? normalizedStrongKeyword,
  }) {
    var bestRank = _matchStrongValue(
      candidate,
      normalizedKeyword: normalizedKeyword,
      normalizedStrongKeyword: normalizedStrongKeyword,
    );

    bestRank = _pickBetterRank(
      bestRank,
      _matchIndexedValues(
        candidate.indexedSpellings,
        normalizedKeyword: normalizedKeyword,
        exactPriority: 2,
        prefixPriority: 3,
        partialPriority: 7,
      ),
    );
    bestRank = _pickBetterRank(
      bestRank,
      _matchIndexedValues(
        candidate.indexedTransliterations,
        normalizedKeyword: normalizedKeyword,
        exactPriority: 4,
        prefixPriority: 5,
        partialPriority: 8,
      ),
    );
    bestRank = _pickBetterRank(
      bestRank,
      _matchIndexedValues(
        candidate.indexedMeanings,
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
      columns: _wordTableColumnsForExpressionReadContext('searchWordsMap'),
      where: whereParts.join(' OR '),
      whereArgs: whereArgs,
      orderBy: 'id',
    );
  }

  Future<List<Map<String, dynamic>>> _queryHomeSearchMeaningCandidates(
    Database db,
    Set<String> sqlTerms,
  ) async {
    if (sqlTerms.isEmpty) {
      return const [];
    }

    final whereParts = <String>[];
    final whereArgs = <Object?>[];
    for (final term in sqlTerms) {
      whereParts.add('LOWER(COALESCE(wms.meaning, \'\')) LIKE ?');
      whereArgs.add('%$term%');
    }

    final projectionSql = _wordTableProjectionForExpressionReadContext(
      'searchWordsMap',
    );
    final rows = await db.rawQuery('''
      SELECT DISTINCT
      $projectionSql
      FROM WORD_TABLE wt
      INNER JOIN word_meaning_set wms
        ON wms.word_id = wt.id
      WHERE ${whereParts.join(' OR ')}
      ORDER BY wt.id
    ''', whereArgs);

    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _queryHomeSearchExpressionCandidates(
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
      whereParts.add('LOWER(COALESCE(wes.spelling, \'\')) LIKE ?');
      whereArgs.add(like);
      whereParts.add('LOWER(COALESCE(wes.transliteration, \'\')) LIKE ?');
      whereArgs.add(like);
    }

    final projectionSql = _wordTableProjectionForExpressionReadContext(
      'searchWordsMap',
    );
    final rows = await db.rawQuery('''
      SELECT DISTINCT
      $projectionSql
      FROM WORD_TABLE wt
      INNER JOIN word_expression_set wes
        ON wes.word_id = wt.id
      WHERE ${whereParts.join(' OR ')}
      ORDER BY wt.id
    ''', whereArgs);

    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
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
      columns: _wordTableColumnsForExpressionReadContext('searchWordsMap'),
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
    addRows(await _queryHomeSearchExpressionCandidates(db, sqlTerms));
    addRows(await _queryHomeSearchMeaningCandidates(db, sqlTerms));
    addRows(await _queryHomeSearchLanguageCandidates(db, keyword));

    if (candidatesById.isEmpty &&
        (_containsHebrewScript(keyword) || _containsGreekScript(keyword))) {
      addRows(
        await db.query(
          'WORD_TABLE',
          columns: _wordTableColumnsForExpressionReadContext('searchWordsMap'),
          orderBy: 'id',
        ),
      );
    }

    final expressionMaterializedRows =
        await _materializeCanonicalExpressionsForNormalRuntime(
          db,
          candidatesById.values,
          context: 'searchWordsMap',
        );

    return await _materializeCanonicalMeaningsForNormalRuntime(
      db,
      expressionMaterializedRows,
    );
  }

  _HomeStrongExactCandidate _buildHomeStrongExactCandidate(
    Map<String, dynamic> row,
  ) {
    return _HomeStrongExactCandidate(
      wordId: (row['word_id'] ?? '').toString().trim(),
      strongNumber: (row['strong_number'] ?? '').toString().trim(),
    );
  }

  String _wordTableProjectionSql(Iterable<String> columns) {
    return columns.map((column) => 'wt."$column" AS "$column"').join(',\n');
  }

  Future<List<Map<String, dynamic>>>
  _loadHomeSearchDisplayRowsForStrongExactCandidates(
    Database db,
    List<_HomeStrongExactCandidate> candidates,
  ) async {
    if (candidates.isEmpty) {
      return const [];
    }

    final candidateWordIds = candidates
        .map((candidate) => candidate.wordId)
        .where((wordId) => wordId.isNotEmpty)
        .toList(growable: false);
    if (candidateWordIds.isEmpty) {
      return const [];
    }

    final placeholders = List.filled(candidateWordIds.length, '?').join(', ');
    final projectionSql = _wordTableProjectionForExpressionReadContext(
      'searchStrongExactMap',
    );
    final rows = await db.rawQuery('''
      SELECT
      $projectionSql
      FROM WORD_TABLE wt
      WHERE wt.id IN ($placeholders)
      ''', candidateWordIds);
    final rowsById = <String, Map<String, dynamic>>{
      for (final row in rows)
        (row['id'] ?? '').toString().trim(): Map<String, dynamic>.from(row),
    };

    return List<Map<String, dynamic>>.unmodifiable(
      candidateWordIds.map((wordId) => rowsById[wordId]).whereType(),
    );
  }

  Future<List<HomeSearchResultDisplayItem>> searchStrongExactMap(
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
      SELECT
        wt.id AS word_id,
        TRIM(COALESCE(wt.스트롱넘버, '')) AS strong_number
      FROM WORD_TABLE wt
      WHERE wt.스트롱넘버 IS NOT NULL
        AND TRIM(wt.스트롱넘버) <> ''
        AND UPPER(SUBSTR(TRIM(wt.스트롱넘버), 1, 1)) = ?
        AND CAST(SUBSTR(TRIM(wt.스트롱넘버), 2) AS INTEGER) = ?
      ORDER BY wt.id
      ''',
      [prefix, numericPart],
    );
    final candidates = rows
        .map(_buildHomeStrongExactCandidate)
        .where(
          (candidate) =>
              _normalizeStrongValue(candidate.strongNumber) == normalizedStrong,
        )
        .take(limit)
        .toList(growable: false);
    final displayRows =
        await _loadHomeSearchDisplayRowsForStrongExactCandidates(
          db,
          candidates,
        );
    return await _resolveHomeSearchDisplayItemsForPhase32(
      db,
      displayRows,
      context: 'searchStrongExactMap',
    );
  }

  /// 키워드로 단어 검색 (홈 검색용)
  /// - DB에서 1차 후보를 수집한 뒤 Dart에서 정규화 비교/정렬한다.
  /// - canonical expression rows, canonical meaning rows, 스트롱넘버를 대상으로 한다.
  /// - 결과는 exact/prefix/partial 우선순위를 적용한 뒤 limit를 건다.
  Future<List<HomeSearchResultDisplayItem>> searchWordsMap(
    String keyword, {
    int limit = 200,
  }) async {
    final db = await DatabaseService.openDatabaseFile();

    final q = keyword.trim();
    if (q.isEmpty) {
      return const [];
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
      final rankingCandidate = _buildHomeSearchRankingCandidate(row);
      final rank = _rankHomeSearchCandidate(
        rankingCandidate,
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
        id: rankingCandidate.wordId,
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

    final resultRows = scoredRows
        .take(limit)
        .map((entry) => Map<String, dynamic>.from(entry.row))
        .toList(growable: false);
    return await _resolveHomeSearchDisplayItemsForPhase32(
      db,
      resultRows,
      context: 'searchWordsMap',
    );
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

  /// RELATION_CATEGORY lookup 목록
  Future<List<RelationCategoryLookup>> getRelationCategories() async {
    final db = await DatabaseService.openDatabaseFile();
    final rows = await db.query(
      'RELATION_CATEGORY',
      columns: ['code', 'label', 'description', 'sort_order'],
      orderBy: 'sort_order ASC, label ASC, code ASC',
    );

    return rows
        .map(
          (row) =>
              RelationCategoryLookup.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  /// RELATION_TYPE lookup 목록
  Future<List<RelationTypeLookup>> getRelationTypes() async {
    final db = await DatabaseService.openDatabaseFile();
    final rows = await db.query(
      'RELATION_TYPE',
      columns: ['code', 'category_code', 'label', 'description', 'sort_order'],
      orderBy: 'category_code ASC, sort_order ASC, label ASC, code ASC',
    );

    return rows
        .map(
          (row) => RelationTypeLookup.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  /// RELATION_STATUS lookup 목록
  Future<List<RelationStatusLookup>> getRelationStatuses() async {
    final db = await DatabaseService.openDatabaseFile();
    final rows = await db.query(
      'RELATION_STATUS',
      columns: ['code', 'label', 'description', 'sort_order'],
      orderBy: 'sort_order ASC, label ASC, code ASC',
    );

    return rows
        .map(
          (row) => RelationStatusLookup.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  Future<String> _requireValidRelationStatusCodeOnExecutor(
    DatabaseExecutor db,
    String statusCode,
  ) async {
    final normalizedStatusCode = statusCode.trim();
    if (normalizedStatusCode.isEmpty) {
      throw ArgumentError.value(statusCode, 'statusCode', '관계 상태가 비어 있습니다.');
    }

    final rows = await db.query(
      'RELATION_STATUS',
      columns: ['code'],
      where: 'code = ?',
      whereArgs: [normalizedStatusCode],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw ArgumentError.value(statusCode, 'statusCode', '정의되지 않은 관계 상태입니다.');
    }

    return normalizedStatusCode;
  }

  Future<RelationTypeLookup?> _getRelationTypeLookupByCodeOnExecutor(
    DatabaseExecutor db,
    String? relationTypeCode,
  ) async {
    final normalizedRelationTypeCode = _normalizeNullableCode(relationTypeCode);
    if (normalizedRelationTypeCode == null) {
      return null;
    }

    final rows = await db.query(
      'RELATION_TYPE',
      columns: ['code', 'category_code', 'label', 'description', 'sort_order'],
      where: 'code = ?',
      whereArgs: [normalizedRelationTypeCode],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return RelationTypeLookup.fromMap(Map<String, dynamic>.from(rows.first));
  }

  Future<String?> _resolveStoredCategoryCode({
    required DatabaseExecutor db,
    required String? requestedCategoryCode,
    required String? relationTypeCode,
  }) async {
    final relationTypeLookup = await _getRelationTypeLookupByCodeOnExecutor(
      db,
      relationTypeCode,
    );
    if (relationTypeLookup != null) {
      return relationTypeLookup.categoryCode;
    }

    return _normalizeNullableCode(requestedCategoryCode);
  }

  /// WORD_RELATION 1건 수정(트랜잭션)
  Future<void> updateRelation({
    required int relationId,
    required String? categoryCode,
    required String? relationType,
    required String statusCode,
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
      await _updateRelationOnExecutor(
        db: txn,
        groupId: groupId,
        relationId: relationId,
        categoryCode: categoryCode,
        relationType: relationType,
        statusCode: statusCode,
        directionCode: normalizedDirectionCode,
        description: descriptionValue,
        relationGroupId: relationGroupIdValue,
        note: note,
        source: source,
      );
    });
  }

  Future<_RelationUpdateOutcome> _updateRelationOnExecutor({
    required DatabaseExecutor db,
    required String groupId,
    required int relationId,
    required String? categoryCode,
    required String? relationType,
    required String statusCode,
    required String directionCode,
    required String? description,
    required String? relationGroupId,
    required String? note,
    required String? source,
  }) async {
    final before = await _getRelationRowById(db, relationId);
    if (before == null) {
      throw Exception('수정할 관계를 찾을 수 없습니다: $relationId');
    }

    final normalizedStatusCode =
        await _requireValidRelationStatusCodeOnExecutor(db, statusCode);
    final normalizedRelationType = _normalizeNullableCode(relationType);
    final effectiveCategoryCode = await _resolveStoredCategoryCode(
      db: db,
      requestedCategoryCode: categoryCode,
      relationTypeCode: normalizedRelationType,
    );

    final existingId = await _findExistingRelationIdBySignatureOnExecutor(
      db,
      wordIdA: before['word_id_1'] as String,
      wordIdB: before['word_id_2'] as String,
      relationType: normalizedRelationType,
      directionCode: directionCode,
      excludeRelationId: relationId,
    );
    if (existingId != null) {
      throw Exception('동일한 pair/type/direction 관계가 이미 존재합니다: $existingId');
    }

    final after = Map<String, dynamic>.from(before)
      ..['category_code'] = effectiveCategoryCode
      ..['relation_type'] = normalizedRelationType
      ..['status_code'] = normalizedStatusCode
      ..['direction_code'] = directionCode
      ..['description'] = description
      ..['relation_group_id'] = relationGroupId
      ..['note'] = note
      ..['source'] = source
      ..['updated_at'] = DateTime.now().toIso8601String();

    final updatedRows = await db.update(
      'WORD_RELATION',
      {
        'category_code': effectiveCategoryCode,
        'relation_type': normalizedRelationType,
        'status_code': normalizedStatusCode,
        'direction_code': directionCode,
        'description': description,
        'relation_group_id': relationGroupId,
        'note': note,
        'source': source,
        'updated_at': after['updated_at'],
      },
      where: 'id = ?',
      whereArgs: [relationId],
    );
    if (updatedRows != 1) {
      throw StateError(
        'relation을 exact 1건 수정하지 못했습니다: $relationId/$updatedRows',
      );
    }

    await _insertHistory(
      db,
      groupId: groupId,
      actionType: 'update',
      entityType: 'relation',
      entityId: relationId.toString(),
      beforeJson: before,
      afterJson: after,
    );
    return _RelationUpdateOutcome(before: before, after: after);
  }

  /// 키워드로 단어 검색 (그래프에서 "관계 추가" 대상 단어 선택용)
  /// - canonical expression spelling, canonical meaning rows, 스트롱넘버 부분일치 검색
  /// - 검색 semantics는 유지하고 graph relation add dialog용 최소 contract만 반환한다.
  Future<List<GraphRelationAddSearchResultItem>> searchWords(
    String keyword, {
    int limit = 200,
  }) async {
    final db = await DatabaseService.openDatabaseFile();

    final q = keyword.trim();
    if (q.isEmpty) return const [];

    final like = '%$q%';

    final rows = await db.rawQuery(
      '''
      WITH ${_representativeQueryProjectionCte()}
      SELECT
        wt.id AS id,
        representative_query_projection.representative_spelling AS representative_spelling,
        ${_canonicalPrimaryMeaningSql()} AS primary_meaning,
        TRIM(COALESCE(wt.스트롱넘버, '')) AS display_strong_number
      FROM WORD_TABLE wt
      INNER JOIN representative_query_projection
        ON representative_query_projection.word_id = wt.id
      WHERE EXISTS (
               SELECT 1
               FROM word_expression_set wes_search
               WHERE wes_search.word_id = wt.id
                 AND wes_search.spelling LIKE ?
            )
          OR EXISTS (
               SELECT 1
               FROM word_expression_set wes_search
               WHERE wes_search.word_id = wt.id
                 AND wes_search.transliteration LIKE ?
            )
          OR EXISTS (
               SELECT 1
               FROM word_meaning_set wms_search
              WHERE wms_search.word_id = wt.id
                AND wms_search.meaning LIKE ?
            )
         OR wt.스트롱넘버 LIKE ?
      LIMIT ?
      ''',
      [like, like, like, like, limit],
    );

    return List<GraphRelationAddSearchResultItem>.unmodifiable(
      rows.map(_buildGraphRelationAddSearchResultItem),
    );
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
  /// - status_code는 유효한 lookup code를 검증해 명시적으로 저장한다.
  /// - created_at은 DB default를 활용하고 updated_at은 ISO 문자열로 넣어준다.
  Future<int> createRelation({
    required String wordId1,
    required String wordId2,
    required String? categoryCode,
    required String? relationType,
    required String statusCode,
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
      final normalizedStatusCode =
          await _requireValidRelationStatusCodeOnExecutor(txn, statusCode);
      final normalizedRelationType = _normalizeNullableCode(relationType);
      final effectiveCategoryCode = await _resolveStoredCategoryCode(
        db: txn,
        requestedCategoryCode: categoryCode,
        relationTypeCode: normalizedRelationType,
      );

      final existingId = await _findExistingRelationIdBySignatureOnExecutor(
        txn,
        wordIdA: normalized.wordId1,
        wordIdB: normalized.wordId2,
        relationType: normalizedRelationType,
        directionCode: normalized.directionCode,
      );
      if (existingId != null) {
        throw Exception('동일한 pair/type/direction 관계가 이미 존재합니다: $existingId');
      }

      final row = {
        'word_id_1': normalized.wordId1,
        'word_id_2': normalized.wordId2,
        'category_code': effectiveCategoryCode,
        'relation_type': normalizedRelationType,
        'status_code': normalizedStatusCode,
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

  String _canonicalPrimaryMeaningSql({String wordTableAlias = 'wt'}) {
    return '''
      TRIM(COALESCE((
        SELECT wms.meaning
        FROM word_meaning_set wms
        WHERE wms.word_id = $wordTableAlias.id
        ORDER BY wms.seq ASC, wms.id ASC
        LIMIT 1
      ), ''))
    ''';
  }

  String _representativeQueryProjectionCte({
    String cteName = 'representative_query_projection',
  }) {
    return '''
      $cteName AS (
        SELECT
          wt.id AS word_id,
          TRIM(COALESCE(wt.언어, '')) AS language_key,
          TRIM(COALESCE(wt.스트롱넘버, '')) AS strong_number_key,
          CASE
            WHEN representative_row.word_id IS NOT NULL
              THEN TRIM(COALESCE(representative_row.spelling, ''))
            WHEN fallback_row.word_id IS NOT NULL
              THEN TRIM(COALESCE(fallback_row.spelling, ''))
            ELSE ''
          END AS representative_spelling,
          CASE
            WHEN representative_row.word_id IS NOT NULL
              THEN TRIM(COALESCE(representative_row.transliteration, ''))
            WHEN fallback_row.word_id IS NOT NULL
              THEN TRIM(COALESCE(fallback_row.transliteration, ''))
            ELSE ''
          END AS representative_transliteration
        FROM WORD_TABLE wt
        LEFT JOIN word_expression_set representative_row
          ON representative_row.word_id = wt.id
         AND representative_row.is_representative = 1
        LEFT JOIN word_expression_set fallback_row
          ON fallback_row.id = (
               SELECT wes.id
               FROM word_expression_set wes
               WHERE wes.word_id = wt.id
               ORDER BY wes.seq ASC, wes.id ASC
               LIMIT 1
             )
         AND representative_row.word_id IS NULL
      )
    ''';
  }

  /// 다음 WORD_TABLE.id 생성
  /// - Strong가 있으면: `<STRONG>_<SEQ4>`
  /// - Strong가 없으면: `<LANGCODE>0000_<SEQ4>`
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
  /// - Strong가 있으면: 스트롱넘버 기준(기존 strong 우선 규칙 유지)
  /// - Strong가 없으면: (언어, representative spelling) 기준
  Future<List<DuplicateCandidateDisplayItem>>
  _findDuplicateCandidatesByNormalizedStrong(
    Database db,
    String normalizedStrong,
  ) async {
    final match = RegExp(r'^([A-Z])(\d+)$').firstMatch(normalizedStrong);
    if (match == null) {
      return const [];
    }

    final prefix = match.group(1)!;
    final numericPart = int.tryParse(match.group(2)!);
    if (numericPart == null) {
      return const [];
    }

    final rows = await db.rawQuery(
      '''
      WITH ${_representativeQueryProjectionCte()}
      SELECT
        wt.id AS word_id,
        TRIM(COALESCE(wt.\u{C5B8}\u{C5B4}, '')) AS language,
        TRIM(COALESCE(wt.\u{C2A4}\u{D2B8}\u{B871}\u{B118}\u{BC84}, ''))
          AS strong_number,
        representative_query_projection.representative_spelling
          AS representative_spelling,
        ${_canonicalPrimaryMeaningSql()} AS primary_meaning
      FROM WORD_TABLE wt
      INNER JOIN representative_query_projection
        ON representative_query_projection.word_id = wt.id
      WHERE UPPER(SUBSTR(
              TRIM(COALESCE(wt.\u{C2A4}\u{D2B8}\u{B871}\u{B118}\u{BC84}, '')),
              1,
              1
            )) = ?
        AND CAST(SUBSTR(
              TRIM(COALESCE(wt.\u{C2A4}\u{D2B8}\u{B871}\u{B118}\u{BC84}, '')),
              2
            ) AS INTEGER) = ?
      LIMIT 200
      ''',
      [prefix, numericPart],
    );

    return List<DuplicateCandidateDisplayItem>.unmodifiable(
      rows.map(_buildDuplicateCandidateDisplayItem),
    );
  }

  Future<List<DuplicateCandidateDisplayItem>> findDuplicateCandidates({
    required String language,
    String? strongNumber,
    required String spelling1,
    String? excludeId,
  }) async {
    final db = await DatabaseService.openDatabaseFile();

    final strong = (strongNumber ?? '').trim();
    final spelling = spelling1.trim();

    if (strong.isNotEmpty) {
      final normalizedStrong = _normalizeStrongValue(strong);
      final rows = await db.rawQuery(
        '''
        WITH ${_representativeQueryProjectionCte()}
        SELECT
          wt.id AS word_id,
          TRIM(COALESCE(wt.언어, '')) AS language,
          TRIM(COALESCE(wt.스트롱넘버, '')) AS strong_number,
          representative_query_projection.representative_spelling
            AS representative_spelling,
          ${_canonicalPrimaryMeaningSql()} AS primary_meaning
        FROM WORD_TABLE wt
        INNER JOIN representative_query_projection
          ON representative_query_projection.word_id = wt.id
        WHERE wt.스트롱넘버 = ?
        LIMIT 20
        ''',
        [strong],
      );
      final exactCandidates = rows.map(_buildDuplicateCandidateDisplayItem);
      final candidatesById = <String, DuplicateCandidateDisplayItem>{
        for (final candidate in exactCandidates) candidate.wordId: candidate,
        for (final candidate
            in await _findDuplicateCandidatesByNormalizedStrong(
              db,
              normalizedStrong,
            ))
          candidate.wordId: candidate,
      };

      return List<DuplicateCandidateDisplayItem>.unmodifiable(
        candidatesById.values.where((candidate) {
          if (excludeId != null && candidate.wordId == excludeId) {
            return false;
          }

          return _normalizeStrongValue(candidate.strongNumber) ==
              normalizedStrong;
        }),
      );
    }

    final rows = await db.rawQuery(
      '''
      WITH ${_representativeQueryProjectionCte()}
      SELECT
        wt.id AS word_id,
        TRIM(COALESCE(wt.언어, '')) AS language,
        TRIM(COALESCE(wt.스트롱넘버, '')) AS strong_number,
        representative_query_projection.representative_spelling
          AS representative_spelling,
        ${_canonicalPrimaryMeaningSql()} AS primary_meaning
      FROM WORD_TABLE wt
      INNER JOIN representative_query_projection
        ON representative_query_projection.word_id = wt.id
      WHERE TRIM(COALESCE(wt.\u{C5B8}\u{C5B4}, '')) = ?
      ''',
      [language.trim()],
    );

    final target = _normalizeSpellingForDuplicateCheck(spelling);

    return List<DuplicateCandidateDisplayItem>.unmodifiable(
      rows
          .map(_buildDuplicateCandidateDisplayItem)
          .where((candidate) {
            final id = candidate.wordId;
            if (excludeId != null && id == excludeId) return false;

            final existingSpelling = candidate.representativeSpelling;
            final normalizedExisting = _normalizeSpellingForDuplicateCheck(
              existingSpelling,
            );

            return normalizedExisting == target;
          })
          .take(20),
    );
  }

  /// WORD_TABLE에 신규 단어를 추가한다.
  /// - 현재 단계에서는 핵심 컬럼만 입력하고, 나머지는 null로 둔다.
  Future<void> createWord({
    required String id,
    required CanonicalWordWritePayload payload,
  }) async {
    final db = await DatabaseService.openDatabaseFile();
    final groupId = _newHistoryGroupId();
    final canonicalExpressionSets = _normalizeCanonicalExpressionSetsForWrite(
      payload.expressionSets,
    );
    final normalizedExpressionRows = _buildNormalizedExpressionRowsForWrite(
      id,
      canonicalExpressionSets,
    );
    final normalizedExpressionRowsForHistory =
        _buildNormalizedExpressionHistoryRows(normalizedExpressionRows);
    final normalizedMeanings = _normalizeMeaningValuesForWrite(
      payload.meanings,
    );
    final normalizedMeaningRows = _buildNormalizedMeaningRowsForWrite(
      id,
      normalizedMeanings,
    );

    await db.transaction((txn) async {
      await _replaceWordExpressionSetRows(txn, id, normalizedExpressionRows);
      await _replaceWordMeaningSetRows(txn, id, normalizedMeaningRows);

      final row = {
        'id': id,
        '언어': payload.language,
        '스트롱넘버': (payload.strongNumber ?? '').trim().isEmpty
            ? null
            : payload.strongNumber!.trim(),
        '비고': (payload.note ?? '').trim().isEmpty ? null : payload.note!.trim(),
      };
      final historyAfter = _buildWordHistorySnapshot(
        compatibilityWordSnapshot: row,
        normalizedExpressionRows: normalizedExpressionRowsForHistory,
        normalizedMeaningRows: _cloneWordMeaningRowsForHistory(
          normalizedMeaningRows.map((row) => Map<String, dynamic>.from(row)),
        ),
      );

      await txn.insert('WORD_TABLE', row);

      await _insertHistory(
        txn,
        groupId: groupId,
        actionType: 'create',
        entityType: 'word',
        entityId: id,
        afterJson: historyAfter,
      );
    });
  }

  bool _isGraphCreateDiscardEligibleHistoryRow(
    Map<String, dynamic> historyRow,
    String wordId,
  ) {
    if ((historyRow['action_type'] ?? '').toString() != 'create') {
      return false;
    }
    if ((historyRow['entity_type'] ?? '').toString() != 'word') {
      return false;
    }
    if ((historyRow['entity_id'] ?? '').toString().trim() != wordId) {
      return false;
    }
    if (historyRow['before_json'] != null) {
      return false;
    }
    if (historyRow['undone_at'] != null) {
      return false;
    }

    final afterJsonText = historyRow['after_json'] as String?;
    if (afterJsonText == null || afterJsonText.trim().isEmpty) {
      return false;
    }

    try {
      final afterJson = jsonDecode(afterJsonText);
      if (afterJson is! Map) {
        return false;
      }
      final after = Map<String, dynamic>.from(afterJson);
      if ((after['id'] ?? '').toString().trim() != wordId) {
        return false;
      }
      final normalizedRows = after[_historyNormalizedExpressionRowsKey];
      if (normalizedRows != null && normalizedRows is! List) {
        return false;
      }
      final normalizedMeaningRows = after[_historyNormalizedMeaningRowsKey];
      if (normalizedMeaningRows != null && normalizedMeaningRows is! List) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Graph create flow에서 post-create edit 화면을 저장 없이 닫은 경우만
  /// 방금 생성된 word를 확정 생성 전 상태로 되돌린다.
  Future<bool> discardCreatedWordForGraphCreateFlow(String wordId) async {
    final normalizedId = wordId.trim();
    if (normalizedId.isEmpty) {
      return false;
    }

    final db = await DatabaseService.openDatabaseFile();
    return await db.transaction((txn) async {
      final wordRows = await txn.query(
        'WORD_TABLE',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [normalizedId],
        limit: 1,
      );
      if (wordRows.isEmpty) {
        return false;
      }

      final relationRows = await txn.query(
        'WORD_RELATION',
        columns: ['id'],
        where: 'word_id_1 = ? OR word_id_2 = ?',
        whereArgs: [normalizedId, normalizedId],
        limit: 1,
      );
      if (relationRows.isNotEmpty) {
        return false;
      }

      final latestActiveWordHistoryRows = await txn.query(
        'CHANGE_HISTORY',
        where: 'entity_type = ? AND entity_id = ? AND undone_at IS NULL',
        whereArgs: ['word', normalizedId],
        orderBy: 'id DESC',
        limit: 1,
      );
      if (latestActiveWordHistoryRows.isEmpty) {
        return false;
      }

      final createHistoryRow = Map<String, dynamic>.from(
        latestActiveWordHistoryRows.single,
      );
      if (!_isGraphCreateDiscardEligibleHistoryRow(
        createHistoryRow,
        normalizedId,
      )) {
        return false;
      }

      final groupId = (createHistoryRow['group_id'] ?? '').toString().trim();
      if (groupId.isEmpty) {
        return false;
      }
      final activeGroupRows = await txn.query(
        'CHANGE_HISTORY',
        columns: ['id'],
        where: 'group_id = ? AND undone_at IS NULL',
        whereArgs: [groupId],
      );
      if (activeGroupRows.length != 1 ||
          activeGroupRows.single['id'] != createHistoryRow['id']) {
        return false;
      }

      final latestRows = await txn.query(
        'CHANGE_HISTORY',
        columns: ['id'],
        where: 'undone_at IS NULL',
        orderBy: 'id DESC',
        limit: 1,
      );
      if (latestRows.isEmpty ||
          latestRows.single['id'] != createHistoryRow['id']) {
        return false;
      }

      await _deleteWordExpressionSetRows(txn, normalizedId);
      await _deleteWordMeaningSetRows(txn, normalizedId);
      await txn.delete(
        'WORD_TABLE',
        where: 'id = ?',
        whereArgs: [normalizedId],
      );
      await txn.update(
        'CHANGE_HISTORY',
        {'undone_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [createHistoryRow['id']],
      );

      return true;
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
        columns: _wordCoreSnapshotColumns,
        where: 'id = ?',
        whereArgs: [wordId],
        limit: 1,
      );
      if (wordRows.isEmpty) {
        throw Exception('삭제할 단어를 찾을 수 없습니다: $wordId');
      }

      final wordBefore = _sanitizeNewWordHistoryCoreSnapshot(
        Map<String, dynamic>.from(wordRows.first),
      );
      final normalizedExpressionRowsBefore =
          await _loadWordExpressionSetRowsForHistory(txn, wordId);
      final normalizedMeaningRowsBefore =
          await _loadWordMeaningSetRowsForHistory(txn, wordId);
      final wordBeforeHistory = _buildWordHistorySnapshot(
        compatibilityWordSnapshot: wordBefore,
        normalizedExpressionRows: normalizedExpressionRowsBefore,
        normalizedMeaningRows: normalizedMeaningRowsBefore,
      );

      final relationRows = await txn.query(
        'WORD_RELATION',
        where: 'word_id_1 = ? OR word_id_2 = ?',
        whereArgs: [wordId, wordId],
      );

      await txn.delete(
        'WORD_RELATION',
        where: 'word_id_1 = ? OR word_id_2 = ?',
        whereArgs: [wordId, wordId],
      );
      await _deleteWordExpressionSetRows(txn, wordId);
      await _deleteWordMeaningSetRows(txn, wordId);
      await txn.delete('WORD_TABLE', where: 'id = ?', whereArgs: [wordId]);

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
        beforeJson: wordBeforeHistory,
      );
    });
  }

  /// WORD_TABLE의 기존 단어 1건 수정
  /// - 현재 단계에서는 핵심 편집 필드만 수정한다.
  /// - id는 수정하지 않는다.
  Future<void> updateWord({
    required String id,
    required CanonicalWordWritePayload payload,
  }) async {
    final db = await DatabaseService.openDatabaseFile();
    final groupId = _newHistoryGroupId();
    final canonicalExpressionSets = _normalizeCanonicalExpressionSetsForWrite(
      payload.expressionSets,
    );
    final normalizedExpressionRows = _buildNormalizedExpressionRowsForWrite(
      id,
      canonicalExpressionSets,
    );
    final normalizedExpressionRowsForHistory =
        _buildNormalizedExpressionHistoryRows(normalizedExpressionRows);
    final normalizedMeanings = _normalizeMeaningValuesForWrite(
      payload.meanings,
    );
    final normalizedMeaningRows = _buildNormalizedMeaningRowsForWrite(
      id,
      normalizedMeanings,
    );

    await db.transaction((txn) async {
      final beforeRaw = await _getWordRowById(txn, id);
      if (beforeRaw == null) {
        throw Exception('수정할 단어를 찾을 수 없습니다: $id');
      }

      final beforeNormalizedExpressionRows =
          await _loadWordExpressionSetRowsForHistory(txn, id);
      final beforeNormalizedMeaningRows =
          await _loadWordMeaningSetRowsForHistory(txn, id);
      final beforeWordSnapshot = _sanitizeNewWordHistoryCoreSnapshot(beforeRaw);
      final before = _buildWordHistorySnapshot(
        compatibilityWordSnapshot: beforeWordSnapshot,
        normalizedExpressionRows: beforeNormalizedExpressionRows,
        normalizedMeaningRows: beforeNormalizedMeaningRows,
      );
      final after = Map<String, dynamic>.from(beforeWordSnapshot);

      await _replaceWordExpressionSetRows(txn, id, normalizedExpressionRows);
      await _replaceWordMeaningSetRows(txn, id, normalizedMeaningRows);

      after['언어'] = payload.language;
      after['스트롱넘버'] = (payload.strongNumber ?? '').trim().isEmpty
          ? null
          : payload.strongNumber!.trim();
      after['비고'] = (payload.note ?? '').trim().isEmpty
          ? null
          : payload.note!.trim();

      await txn.update(
        'WORD_TABLE',
        {'언어': after['언어'], '스트롱넘버': after['스트롱넘버'], '비고': after['비고']},
        where: 'id = ?',
        whereArgs: [id],
      );
      final afterHistory = _buildWordHistorySnapshot(
        compatibilityWordSnapshot: after,
        normalizedExpressionRows: normalizedExpressionRowsForHistory,
        normalizedMeaningRows: _cloneWordMeaningRowsForHistory(
          normalizedMeaningRows.map((row) => Map<String, dynamic>.from(row)),
        ),
      );

      await _insertHistory(
        txn,
        groupId: groupId,
        actionType: 'update',
        entityType: 'word',
        entityId: id,
        beforeJson: before,
        afterJson: afterHistory,
      );
    });
  }

  /// 승인된 content manifest가 요청한 meaning·word note·relation 교체와
  /// relation 생성을 기존 history/undo 형식으로 한 transaction에 기록한다.
  Future<ApprovedContentBatchWriteResult> applyApprovedContentBatch(
    ApprovedContentBatchWriteRequest request, {
    Database? database,
  }) async {
    _validateApprovedContentBatchRequestShape(request);
    final db = database ?? await DatabaseService.openDatabaseFile();
    final groupId = _newHistoryGroupId();

    return db.transaction((txn) async {
      final existingGroup = await txn.query(
        'CHANGE_HISTORY',
        columns: ['id'],
        where: 'group_id = ?',
        whereArgs: [groupId],
        limit: 1,
      );
      if (existingGroup.isNotEmpty) {
        throw StateError('새 history group_id가 기존 값과 충돌했습니다: $groupId');
      }

      final prepared = await _prepareApprovedContentBatch(txn, request);
      final createdRelations = <ApprovedContentCreatedRelation>[];
      final replacedRelations = <ApprovedContentReplacedRelation>[];

      for (final change in prepared.meaningChanges) {
        await _replaceWordMeaningSetRows(
          txn,
          change.replacement.wordId,
          change.afterRows,
        );
        await _insertHistory(
          txn,
          groupId: groupId,
          actionType: 'update',
          entityType: 'word',
          entityId: change.replacement.wordId,
          beforeJson: change.beforeHistory,
          afterJson: change.afterHistory,
        );
      }

      for (final change in prepared.wordNoteChanges) {
        final updatedRows = await txn.update(
          'WORD_TABLE',
          {'비고': change.replacement.after},
          where: 'id = ?',
          whereArgs: [change.replacement.wordId],
        );
        if (updatedRows != 1) {
          throw StateError(
            'note 대상 word를 exact 1건 수정하지 못했습니다: '
            '${change.replacement.wordId}/$updatedRows',
          );
        }
        await _insertHistory(
          txn,
          groupId: groupId,
          actionType: 'update',
          entityType: 'word',
          entityId: change.replacement.wordId,
          beforeJson: change.beforeHistory,
          afterJson: change.afterHistory,
        );
      }

      for (final relation in request.relationCreates) {
        final updatedAt = DateTime.now().toIso8601String();
        final historyAfter = Map<String, dynamic>.from(
          relation.toDatabaseRow(updatedAt: updatedAt),
        );
        final id = await txn.insert('WORD_RELATION', historyAfter);
        historyAfter['id'] = id;

        await _insertHistory(
          txn,
          groupId: groupId,
          actionType: 'create',
          entityType: 'relation',
          entityId: id.toString(),
          afterJson: historyAfter,
        );

        final actualRow = await _getRelationRowById(txn, id);
        if (actualRow == null) {
          throw StateError('생성한 관계를 transaction 내부에서 다시 읽을 수 없습니다: $id');
        }
        createdRelations.add(
          ApprovedContentCreatedRelation(
            id: id,
            row: Map<String, Object?>.unmodifiable(actualRow),
          ),
        );
      }

      for (final change in prepared.relationChanges) {
        final replacement = change.replacement;
        final outcome = await _updateRelationOnExecutor(
          db: txn,
          groupId: groupId,
          relationId: replacement.relationId,
          categoryCode: replacement.after.categoryCode,
          relationType: replacement.after.relationType,
          statusCode: replacement.after.statusCode,
          directionCode: replacement.after.directionCode,
          description: replacement.after.description,
          relationGroupId: replacement.after.relationGroupId,
          note: replacement.after.note,
          source: replacement.after.source,
        );
        if (!replacement.before.matchesDatabaseRow(outcome.before)) {
          throw StateError(
            'relation before projection이 update 직전 DB와 exact 일치하지 않습니다: '
            '${replacement.relationId}',
          );
        }
        if (!replacement.after.matchesDatabaseRow(outcome.after)) {
          throw StateError(
            'relation after projection이 update 결과와 exact 일치하지 않습니다: '
            '${replacement.relationId}',
          );
        }
        final actualAfter = await _getRelationRowById(
          txn,
          replacement.relationId,
        );
        if (actualAfter == null ||
            !replacement.after.matchesDatabaseRow(actualAfter) ||
            actualAfter['id'] != outcome.before['id'] ||
            actualAfter['word_id_1'] != outcome.before['word_id_1'] ||
            actualAfter['word_id_2'] != outcome.before['word_id_2'] ||
            actualAfter['created_at'] != outcome.before['created_at'] ||
            actualAfter['updated_at'] != outcome.after['updated_at']) {
          throw StateError(
            'relation replacement 실제 row가 승인 after/identity와 exact '
            '일치하지 않습니다: ${replacement.relationId}',
          );
        }
        replacedRelations.add(
          ApprovedContentReplacedRelation(
            id: replacement.relationId,
            before: Map<String, Object?>.unmodifiable(outcome.before),
            after: Map<String, Object?>.unmodifiable(actualAfter),
          ),
        );
      }

      final historyRows = await txn.query(
        'CHANGE_HISTORY',
        columns: ['id'],
        where: 'group_id = ? AND undone_at IS NULL',
        whereArgs: [groupId],
      );
      if (historyRows.length != request.operationCount) {
        throw StateError(
          'batch history 행 수가 operation 수와 다릅니다: '
          '${historyRows.length}/${request.operationCount}',
        );
      }

      return ApprovedContentBatchWriteResult(
        groupId: groupId,
        createdRelations: List<ApprovedContentCreatedRelation>.unmodifiable(
          createdRelations,
        ),
        replacedRelations: List<ApprovedContentReplacedRelation>.unmodifiable(
          replacedRelations,
        ),
        historyRowCount: historyRows.length,
      );
    }, exclusive: true);
  }

  /// 원본 DB read-only preflight와 transaction 직전 검증이 같은 계약을
  /// 사용하도록 batch DB precondition을 공유한다.
  Future<void> validateApprovedContentBatchPreconditions({
    required ApprovedContentBatchWriteRequest request,
    required DatabaseExecutor database,
  }) async {
    _validateApprovedContentBatchRequestShape(request);
    await _prepareApprovedContentBatch(database, request);
  }

  void _validateApprovedContentBatchRequestShape(
    ApprovedContentBatchWriteRequest request,
  ) {
    if (request.batchId.isEmpty) {
      throw ArgumentError.value(
        request.batchId,
        'batchId',
        'batch_id가 비어 있습니다.',
      );
    }
    if (request.operationCount == 0) {
      throw ArgumentError('batch operation이 최소 1개 필요합니다.');
    }

    final meaningWordIds = <String>{};
    for (final replacement in request.meaningReplacements) {
      if (replacement.wordId.isEmpty) {
        throw ArgumentError('meaning replacement word_id가 비어 있습니다.');
      }
      if (!meaningWordIds.add(replacement.wordId)) {
        throw ArgumentError(
          '동일 word의 meaning replacement가 중복됐습니다: ${replacement.wordId}',
        );
      }
      _validateApprovedMeaningRows(
        replacement.wordId,
        'before',
        replacement.before,
      );
      _validateApprovedMeaningRows(
        replacement.wordId,
        'after',
        replacement.after,
      );
      if (_sameApprovedMeaningRows(replacement.before, replacement.after)) {
        throw ArgumentError(
          'meaning before와 after가 동일합니다: ${replacement.wordId}',
        );
      }
    }

    final noteWordIds = <String>{};
    for (final replacement in request.wordNoteReplacements) {
      if (replacement.wordId.isEmpty) {
        throw ArgumentError('note replacement word_id가 비어 있습니다.');
      }
      if (!noteWordIds.add(replacement.wordId)) {
        throw ArgumentError(
          '동일 word의 note replacement가 중복됐습니다: ${replacement.wordId}',
        );
      }
      _validateApprovedWordNote(
        replacement.wordId,
        'before',
        replacement.before,
      );
      _validateApprovedWordNote(replacement.wordId, 'after', replacement.after);
      if (replacement.before == replacement.after) {
        throw ArgumentError('note before와 after가 동일합니다: ${replacement.wordId}');
      }
    }

    final relationCreatePairs = <String>{};
    const directionCodes = {'w1_to_w2', 'w2_to_w1', 'undirected', 'unknown'};
    for (final relation in request.relationCreates) {
      if (relation.wordId1.isEmpty || relation.wordId2.isEmpty) {
        throw ArgumentError('relation word_id가 비어 있습니다.');
      }
      if (relation.wordId1.compareTo(relation.wordId2) >= 0) {
        throw ArgumentError(
          'relation pair는 word_id_1 < word_id_2 canonical 순서여야 합니다: '
          '${relation.wordId1}, ${relation.wordId2}',
        );
      }
      if (!directionCodes.contains(relation.directionCode)) {
        throw ArgumentError(
          '정의되지 않은 direction_code입니다: ${relation.directionCode}',
        );
      }
      if (relation.categoryCode.isEmpty ||
          relation.relationType.isEmpty ||
          relation.statusCode.isEmpty ||
          relation.source.isEmpty) {
        throw ArgumentError('relation lookup code와 source는 비어 있을 수 없습니다.');
      }
      final pairKey = '${relation.wordId1}\u0000${relation.wordId2}';
      if (!relationCreatePairs.add(pairKey)) {
        throw ArgumentError(
          '동일 unordered relation pair가 중복됐습니다: '
          '${relation.wordId1}, ${relation.wordId2}',
        );
      }
    }

    final replacementIds = <int>{};
    final replacementPairs = <String>{};
    for (final replacement in request.relationReplacements) {
      if (replacement.relationId <= 0) {
        throw ArgumentError.value(
          replacement.relationId,
          'relationId',
          'relation_id는 양수여야 합니다.',
        );
      }
      if (!replacementIds.add(replacement.relationId)) {
        throw ArgumentError(
          '동일 relation_id replacement가 중복됐습니다: '
          '${replacement.relationId}',
        );
      }
      if (replacement.wordId1.isEmpty || replacement.wordId2.isEmpty) {
        throw ArgumentError('relation replacement word_id가 비어 있습니다.');
      }
      if (replacement.wordId1.compareTo(replacement.wordId2) >= 0) {
        throw ArgumentError(
          'relation replacement pair는 word_id_1 < word_id_2 canonical '
          '순서여야 합니다: ${replacement.wordId1}, ${replacement.wordId2}',
        );
      }
      final pairKey = '${replacement.wordId1}\u0000${replacement.wordId2}';
      if (!replacementPairs.add(pairKey)) {
        throw ArgumentError(
          '동일 unordered relation replacement pair가 중복됐습니다: '
          '${replacement.wordId1}, ${replacement.wordId2}',
        );
      }
      if (relationCreatePairs.contains(pairKey)) {
        throw ArgumentError(
          '같은 unordered pair를 create와 replacement에 동시에 지정했습니다: '
          '${replacement.wordId1}, ${replacement.wordId2}',
        );
      }
      _validateApprovedRelationProjection(
        replacement.relationId,
        'before',
        replacement.before,
        directionCodes,
      );
      _validateApprovedRelationProjection(
        replacement.relationId,
        'after',
        replacement.after,
        directionCodes,
      );
      if (replacement.before.hasSameValues(replacement.after)) {
        throw ArgumentError(
          'relation before와 after가 동일합니다: ${replacement.relationId}',
        );
      }
    }
  }

  void _validateApprovedRelationProjection(
    int relationId,
    String projectionName,
    ApprovedContentRelationProjection projection,
    Set<String> directionCodes,
  ) {
    final codes = <String, String>{
      'category_code': projection.categoryCode,
      'relation_type': projection.relationType,
      'status_code': projection.statusCode,
    };
    for (final entry in codes.entries) {
      if (entry.value.isEmpty || entry.value.trim() != entry.value) {
        throw ArgumentError(
          'relation $relationId $projectionName ${entry.key}는 '
          'trim 없는 non-empty canonical 값이어야 합니다.',
        );
      }
    }
    if (!directionCodes.contains(projection.directionCode)) {
      throw ArgumentError(
        'relation $relationId $projectionName direction_code가 '
        '정의되지 않았습니다: ${projection.directionCode}',
      );
    }
  }

  void _validateApprovedMeaningRows(
    String wordId,
    String projectionName,
    List<ApprovedContentMeaningRow> rows,
  ) {
    var previousSeq = 0;
    for (final row in rows) {
      if (row.seq < 1 || row.seq <= previousSeq) {
        throw ArgumentError(
          '$wordId meaning $projectionName seq는 양수이며 엄격한 오름차순이어야 합니다: '
          '${row.seq}',
        );
      }
      if (row.meaning.isEmpty) {
        throw ArgumentError('$wordId meaning $projectionName 문자열이 비어 있습니다.');
      }
      previousSeq = row.seq;
    }
  }

  void _validateApprovedWordNote(
    String wordId,
    String projectionName,
    String? value,
  ) {
    if (value != null && (value.isEmpty || value.trim().isEmpty)) {
      throw ArgumentError(
        '$wordId note $projectionName 값은 빈 문자열 또는 공백 문자열일 수 없습니다.',
      );
    }
  }

  bool _sameApprovedMeaningRows(
    List<ApprovedContentMeaningRow> left,
    List<ApprovedContentMeaningRow> right,
  ) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index].seq != right[index].seq ||
          left[index].meaning != right[index].meaning) {
        return false;
      }
    }
    return true;
  }

  bool _matchesApprovedMeaningProjection(
    List<Map<String, dynamic>> actual,
    List<ApprovedContentMeaningRow> expected,
  ) {
    if (actual.length != expected.length) return false;
    for (var index = 0; index < actual.length; index++) {
      if (actual[index]['seq'] != expected[index].seq ||
          actual[index]['meaning'] != expected[index].meaning) {
        return false;
      }
    }
    return true;
  }

  Future<_ApprovedContentBatchPreparedState> _prepareApprovedContentBatch(
    DatabaseExecutor db,
    ApprovedContentBatchWriteRequest request,
  ) async {
    final meaningChanges = <_ApprovedMeaningPreparedChange>[];

    for (final replacement in request.meaningReplacements) {
      final wordCore = await _getWordRowById(db, replacement.wordId);
      if (wordCore == null) {
        throw StateError('meaning 대상 word가 존재하지 않습니다: ${replacement.wordId}');
      }
      final expressionRows = await _loadWordExpressionSetRowsForHistory(
        db,
        replacement.wordId,
      );
      final meaningRows = await _loadWordMeaningSetRowsForHistory(
        db,
        replacement.wordId,
      );
      if (!_matchesApprovedMeaningProjection(meaningRows, replacement.before)) {
        throw StateError(
          'meaning before projection이 DB와 exact 일치하지 않습니다: ${replacement.wordId}',
        );
      }

      final afterRows = List<Map<String, Object?>>.unmodifiable(
        replacement.after.map((row) => row.toDatabaseRow(replacement.wordId)),
      );
      final beforeHistory = _buildWordHistorySnapshot(
        compatibilityWordSnapshot: wordCore,
        normalizedExpressionRows: expressionRows,
        normalizedMeaningRows: meaningRows,
      );
      final afterHistory = _buildWordHistorySnapshot(
        compatibilityWordSnapshot: wordCore,
        normalizedExpressionRows: expressionRows,
        normalizedMeaningRows: afterRows
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false),
      );
      meaningChanges.add(
        _ApprovedMeaningPreparedChange(
          replacement: replacement,
          beforeHistory: beforeHistory,
          afterHistory: afterHistory,
          afterRows: afterRows,
        ),
      );
    }

    final meaningAfterByWordId = <String, List<Map<String, dynamic>>>{
      for (final change in meaningChanges)
        change.replacement.wordId: change.afterRows
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false),
    };
    final wordNoteChanges = <_ApprovedWordNotePreparedChange>[];
    for (final replacement in request.wordNoteReplacements) {
      final wordCore = await _getWordRowById(db, replacement.wordId);
      if (wordCore == null) {
        throw StateError('note 대상 word가 존재하지 않습니다: ${replacement.wordId}');
      }
      if (wordCore['비고'] != replacement.before) {
        throw StateError(
          'note before projection이 DB와 exact 일치하지 않습니다: '
          '${replacement.wordId}',
        );
      }
      final expressionRows = await _loadWordExpressionSetRowsForHistory(
        db,
        replacement.wordId,
      );
      final meaningRows =
          meaningAfterByWordId[replacement.wordId] ??
          await _loadWordMeaningSetRowsForHistory(db, replacement.wordId);
      final afterWordCore = Map<String, dynamic>.from(wordCore)
        ..['비고'] = replacement.after;
      wordNoteChanges.add(
        _ApprovedWordNotePreparedChange(
          replacement: replacement,
          beforeHistory: _buildWordHistorySnapshot(
            compatibilityWordSnapshot: wordCore,
            normalizedExpressionRows: expressionRows,
            normalizedMeaningRows: meaningRows,
          ),
          afterHistory: _buildWordHistorySnapshot(
            compatibilityWordSnapshot: afterWordCore,
            normalizedExpressionRows: expressionRows,
            normalizedMeaningRows: meaningRows,
          ),
        ),
      );
    }

    for (final relation in request.relationCreates) {
      for (final wordId in [relation.wordId1, relation.wordId2]) {
        if (await _getWordRowById(db, wordId) == null) {
          throw StateError('relation 대상 word가 존재하지 않습니다: $wordId');
        }
      }

      final categoryRows = await db.query(
        'RELATION_CATEGORY',
        columns: ['code'],
        where: 'code = ?',
        whereArgs: [relation.categoryCode],
        limit: 1,
      );
      if (categoryRows.isEmpty) {
        throw StateError(
          'relation category lookup이 존재하지 않습니다: ${relation.categoryCode}',
        );
      }
      final typeRows = await db.query(
        'RELATION_TYPE',
        columns: ['code', 'category_code'],
        where: 'code = ?',
        whereArgs: [relation.relationType],
        limit: 1,
      );
      if (typeRows.isEmpty) {
        throw StateError(
          'relation type lookup이 존재하지 않습니다: ${relation.relationType}',
        );
      }
      if (typeRows.single['category_code'] != relation.categoryCode) {
        throw StateError(
          'relation type의 category가 manifest와 다릅니다: '
          '${relation.relationType}/${relation.categoryCode}',
        );
      }
      final statusRows = await db.query(
        'RELATION_STATUS',
        columns: ['code'],
        where: 'code = ?',
        whereArgs: [relation.statusCode],
        limit: 1,
      );
      if (statusRows.isEmpty) {
        throw StateError(
          'relation status lookup이 존재하지 않습니다: ${relation.statusCode}',
        );
      }

      final existingPair = await db.query(
        'WORD_RELATION',
        columns: ['id'],
        where:
            '(word_id_1 = ? AND word_id_2 = ?) OR '
            '(word_id_1 = ? AND word_id_2 = ?)',
        whereArgs: [
          relation.wordId1,
          relation.wordId2,
          relation.wordId2,
          relation.wordId1,
        ],
        limit: 1,
      );
      if (existingPair.isNotEmpty) {
        throw StateError(
          '동일 unordered relation pair가 DB에 이미 존재합니다: '
          '${relation.wordId1}, ${relation.wordId2} / id=${existingPair.single['id']}',
        );
      }
    }

    final relationChanges = <_ApprovedRelationPreparedChange>[];
    for (final replacement in request.relationReplacements) {
      final before = await _getRelationRowById(db, replacement.relationId);
      if (before == null) {
        throw StateError(
          'relation replacement 대상 id가 존재하지 않습니다: '
          '${replacement.relationId}',
        );
      }
      if (before['word_id_1'] != replacement.wordId1 ||
          before['word_id_2'] != replacement.wordId2) {
        throw StateError(
          'relation replacement id의 word pair가 manifest와 exact '
          '일치하지 않습니다: ${replacement.relationId}',
        );
      }
      if (!replacement.before.matchesDatabaseRow(before)) {
        throw StateError(
          'relation before projection이 DB와 exact 일치하지 않습니다: '
          '${replacement.relationId}',
        );
      }

      final categoryRows = await db.query(
        'RELATION_CATEGORY',
        columns: ['code'],
        where: 'code = ?',
        whereArgs: [replacement.after.categoryCode],
        limit: 1,
      );
      if (categoryRows.isEmpty) {
        throw StateError(
          'relation replacement category lookup이 존재하지 않습니다: '
          '${replacement.after.categoryCode}',
        );
      }
      final typeRows = await db.query(
        'RELATION_TYPE',
        columns: ['code', 'category_code'],
        where: 'code = ?',
        whereArgs: [replacement.after.relationType],
        limit: 1,
      );
      if (typeRows.isEmpty) {
        throw StateError(
          'relation replacement type lookup이 존재하지 않습니다: '
          '${replacement.after.relationType}',
        );
      }
      if (typeRows.single['category_code'] != replacement.after.categoryCode) {
        throw StateError(
          'relation replacement type의 category가 manifest와 다릅니다: '
          '${replacement.after.relationType}/'
          '${replacement.after.categoryCode}',
        );
      }
      final statusRows = await db.query(
        'RELATION_STATUS',
        columns: ['code'],
        where: 'code = ?',
        whereArgs: [replacement.after.statusCode],
        limit: 1,
      );
      if (statusRows.isEmpty) {
        throw StateError(
          'relation replacement status lookup이 존재하지 않습니다: '
          '${replacement.after.statusCode}',
        );
      }

      final existingId = await _findExistingRelationIdBySignatureOnExecutor(
        db,
        wordIdA: replacement.wordId1,
        wordIdB: replacement.wordId2,
        relationType: replacement.after.relationType,
        directionCode: replacement.after.directionCode,
        excludeRelationId: replacement.relationId,
      );
      if (existingId != null) {
        throw StateError(
          'relation replacement target signature가 기존 relation과 '
          '충돌합니다: ${replacement.relationId}/$existingId',
        );
      }
      relationChanges.add(
        _ApprovedRelationPreparedChange(replacement: replacement),
      );
    }

    return _ApprovedContentBatchPreparedState(
      meaningChanges: List<_ApprovedMeaningPreparedChange>.unmodifiable(
        meaningChanges,
      ),
      wordNoteChanges: List<_ApprovedWordNotePreparedChange>.unmodifiable(
        wordNoteChanges,
      ),
      relationChanges: List<_ApprovedRelationPreparedChange>.unmodifiable(
        relationChanges,
      ),
    );
  }

  /// Legacy compatibility fallback for older history rows.
  Future<void> _syncWordExpressionSetFromLegacySnapshot(
    DatabaseExecutor txn,
    Map<String, dynamic> legacyWordRow,
  ) async {
    final wordId = (legacyWordRow['id'] ?? '').toString().trim();
    if (wordId.isEmpty) {
      throw Exception('word_expression_set 동기화 실패: word id가 비어 있습니다.');
    }

    final readResult = readLegacyWordExpressionRow(legacyWordRow);
    final rows = toWordExpressionSetRows(wordId, readResult.sets);

    await _replaceWordExpressionSetRows(txn, wordId, rows);
  }

  Future<void> _replaceWordExpressionSetRows(
    DatabaseExecutor txn,
    String wordId,
    List<Map<String, Object?>> rows,
  ) async {
    final validatedRows = rows
        .map((row) {
          final pronunciation = readStoredPronunciation(
            pronunciation: row['pronunciation'],
            notationCode: row['pronunciation_notation'],
            notationName: row['pronunciation_notation_name'],
          );
          return <String, Object?>{
            ...row,
            'pronunciation': pronunciation?.text,
            'pronunciation_notation': pronunciation?.notation.code,
            'pronunciation_notation_name': pronunciation?.notationName,
          };
        })
        .toList(growable: false);

    await _deleteWordExpressionSetRows(txn, wordId);

    for (final row in validatedRows) {
      await txn.insert('word_expression_set', row);
    }
  }

  /// New history rows restore the normalized snapshot first. Older history rows
  /// keep the legacy compatibility fallback.
  Future<void> _restoreWordExpressionSetRowsFromHistorySnapshot(
    DatabaseExecutor txn,
    Map<String, dynamic> historySnapshot,
  ) async {
    final wordId = (historySnapshot['id'] ?? '').toString().trim();
    if (wordId.isEmpty) {
      throw Exception('word_expression_set 복원 실패: word id가 비어 있습니다.');
    }

    final normalizedRows = _readNormalizedExpressionRowsFromHistorySnapshot(
      historySnapshot,
    );
    if (normalizedRows != null) {
      final restoredRows = List<Map<String, Object?>>.unmodifiable(
        normalizedRows.map(
          (row) => {
            'word_id': wordId,
            'seq': row['seq'],
            'is_representative': row['is_representative'],
            'spelling': row['spelling'],
            'transliteration': row['transliteration'],
            'pronunciation': row['pronunciation'],
            'pronunciation_notation': row['pronunciation_notation'],
            'pronunciation_notation_name': row['pronunciation_notation_name'],
          },
        ),
      );
      await _replaceWordExpressionSetRows(txn, wordId, restoredRows);
      return;
    }

    await _syncWordExpressionSetFromLegacySnapshot(txn, historySnapshot);
  }

  List<Map<String, Object?>> _buildWordMeaningRowsFromLegacySnapshot(
    Map<String, dynamic> legacyWordRow,
  ) {
    final wordId = (legacyWordRow['id'] ?? '').toString().trim();
    if (wordId.isEmpty) {
      throw Exception('word_meaning_set 동기화 실패: word id가 비어 있습니다.');
    }

    final rows = <Map<String, Object?>>[];
    for (var index = 1; index <= 7; index++) {
      final rawMeaning = legacyWordRow['의미$index'];
      if (rawMeaning == null) {
        continue;
      }

      final meaning = rawMeaning.toString();
      if (meaning.isEmpty) {
        continue;
      }

      rows.add({'word_id': wordId, 'seq': index, 'meaning': meaning});
    }

    return List<Map<String, Object?>>.unmodifiable(rows);
  }

  Future<void> _syncWordMeaningSetFromLegacySnapshot(
    DatabaseExecutor txn,
    Map<String, dynamic> legacyWordRow,
  ) async {
    final wordId = (legacyWordRow['id'] ?? '').toString().trim();
    if (wordId.isEmpty) {
      throw Exception('word_meaning_set 동기화 실패: word id가 비어 있습니다.');
    }

    await _replaceWordMeaningSetRows(
      txn,
      wordId,
      _buildWordMeaningRowsFromLegacySnapshot(legacyWordRow),
    );
  }

  Future<void> _replaceWordMeaningSetRows(
    DatabaseExecutor txn,
    String wordId,
    List<Map<String, Object?>> rows,
  ) async {
    await _deleteWordMeaningSetRows(txn, wordId);

    for (final row in rows) {
      await txn.insert('word_meaning_set', row);
    }
  }

  Future<void> _restoreWordMeaningSetRowsFromHistorySnapshot(
    DatabaseExecutor txn,
    Map<String, dynamic> historySnapshot,
  ) async {
    final wordId = (historySnapshot['id'] ?? '').toString().trim();
    if (wordId.isEmpty) {
      throw Exception('word_meaning_set 복원 실패: word id가 비어 있습니다.');
    }

    final normalizedRows = _readNormalizedMeaningRowsFromHistorySnapshot(
      historySnapshot,
    );
    if (normalizedRows != null) {
      final restoredRows = List<Map<String, Object?>>.unmodifiable(
        normalizedRows.map(
          (row) => {
            'word_id': wordId,
            'seq': row['seq'],
            'meaning': row['meaning'],
          },
        ),
      );
      await _replaceWordMeaningSetRows(txn, wordId, restoredRows);
      return;
    }

    await _syncWordMeaningSetFromLegacySnapshot(txn, historySnapshot);
  }

  Future<void> _deleteWordExpressionSetRows(
    DatabaseExecutor txn,
    String wordId,
  ) async {
    await txn.delete(
      'word_expression_set',
      where: 'word_id = ?',
      whereArgs: [wordId],
    );
  }

  Future<void> _deleteWordMeaningSetRows(
    DatabaseExecutor txn,
    String wordId,
  ) async {
    await txn.delete(
      'word_meaning_set',
      where: 'word_id = ?',
      whereArgs: [wordId],
    );
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
      columns: _wordCoreSnapshotColumns,
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
  Future<UndoLastChangeResult> undoLastChange() async {
    final db = await DatabaseService.openDatabaseFile();

    return await db.transaction((txn) async {
      final latestRows = await txn.rawQuery('''
        SELECT group_id
        FROM CHANGE_HISTORY
        WHERE undone_at IS NULL
        ORDER BY created_at DESC, id DESC
        LIMIT 1
        ''');

      if (latestRows.isEmpty) {
        return const UndoLastChangeResult(didUndo: false);
      }

      final groupId = latestRows.first['group_id'] as String;

      final rows = await txn.query(
        'CHANGE_HISTORY',
        where: 'group_id = ? AND undone_at IS NULL',
        whereArgs: [groupId],
        orderBy: 'id DESC',
      );

      if (rows.isEmpty) {
        return const UndoLastChangeResult(didUndo: false);
      }

      final undoRows = rows
          .map((raw) => Map<String, dynamic>.from(raw))
          .toList(growable: false);

      for (final row in undoRows) {
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
            final createdWordId = after!['id'].toString();
            await _deleteWordExpressionSetRows(txn, createdWordId);
            await _deleteWordMeaningSetRows(txn, createdWordId);
            await txn.delete(
              'WORD_TABLE',
              where: 'id = ?',
              whereArgs: [createdWordId],
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
            final beforeWordSnapshot = _sanitizeWordTableCoreDmlSnapshot(
              before!,
            );
            await txn.update(
              'WORD_TABLE',
              beforeWordSnapshot,
              where: 'id = ?',
              whereArgs: [beforeWordSnapshot['id']],
            );
            await _restoreWordExpressionSetRowsFromHistorySnapshot(txn, before);
            await _restoreWordMeaningSetRowsFromHistorySnapshot(txn, before);
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
            final beforeWordSnapshot = _sanitizeWordTableCoreDmlSnapshot(
              before!,
            );
            await txn.insert('WORD_TABLE', beforeWordSnapshot);
            await _restoreWordExpressionSetRowsFromHistorySnapshot(txn, before);
            await _restoreWordMeaningSetRowsFromHistorySnapshot(txn, before);
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

      return const UndoLastChangeResult(didUndo: true);
    });
  }
}
