import 'dart:collection';

import 'read_source_policy.dart';

class ReadSourceRawEvent {
  final int sequence;
  final DateTime observedAt;
  final String wordId;
  final String context;
  final ReadSourcePolicy requestedPolicy;
  final ResolvedReadSource resolvedSource;
  final FinalReadResultSource finalResultSource;
  final bool didFallback;
  final ReadFallbackReason? fallbackReason;
  final String? fallbackDetail;
  final bool legacyResultAvailable;
  final bool normalizedResultAvailable;
  final int legacySetCount;
  final int normalizedSetCount;
  final int finalSetCount;

  const ReadSourceRawEvent({
    required this.sequence,
    required this.observedAt,
    required this.wordId,
    required this.context,
    required this.requestedPolicy,
    required this.resolvedSource,
    required this.finalResultSource,
    required this.didFallback,
    required this.fallbackReason,
    required this.fallbackDetail,
    required this.legacyResultAvailable,
    required this.normalizedResultAvailable,
    required this.legacySetCount,
    required this.normalizedSetCount,
    required this.finalSetCount,
  });

  String formatLine() {
    return '[read-event] '
        'seq=$sequence '
        'at=${observedAt.toIso8601String()} '
        'wordId=$wordId '
        'context=$context '
        'policy=${requestedPolicy.code} '
        'resolved=${resolvedSource.name} '
        'final=${finalResultSource.code} '
        'fallback=$didFallback '
        'reason=${fallbackReason?.code ?? "-"} '
        'legacyAvailable=$legacyResultAvailable '
        'normalizedAvailable=$normalizedResultAvailable '
        'legacySets=$legacySetCount '
        'normalizedSets=$normalizedSetCount '
        'finalSets=$finalSetCount '
        'detail=${_formatValue(fallbackDetail)}';
  }
}

class ReadSourceWordSummary {
  final String wordId;
  final List<String> contexts;
  final int totalEvents;
  final int fallbackEvents;
  final int normalizedSuccessEvents;
  final int legacyOnlyEvents;
  final int legacyFallbackEvents;
  final int normalizedFailureEvents;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final DateTime? firstFallbackAt;
  final DateTime? lastFallbackAt;
  final ReadFallbackReason? firstFallbackReason;
  final ReadFallbackReason? lastFallbackReason;
  final String? lastFallbackDetail;
  final Map<ReadFallbackReason, int> reasonCounts;
  final Map<FinalReadResultSource, int> finalSourceCounts;

  const ReadSourceWordSummary({
    required this.wordId,
    required this.contexts,
    required this.totalEvents,
    required this.fallbackEvents,
    required this.normalizedSuccessEvents,
    required this.legacyOnlyEvents,
    required this.legacyFallbackEvents,
    required this.normalizedFailureEvents,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.firstFallbackAt,
    required this.lastFallbackAt,
    required this.firstFallbackReason,
    required this.lastFallbackReason,
    required this.lastFallbackDetail,
    required this.reasonCounts,
    required this.finalSourceCounts,
  });

  String formatLine() {
    return '[read-summary:word] '
        'wordId=$wordId '
        'total=$totalEvents '
        'fallback=$fallbackEvents '
        'normalized=$normalizedSuccessEvents '
        'legacyOnly=$legacyOnlyEvents '
        'legacyFallback=$legacyFallbackEvents '
        'normalizedFailure=$normalizedFailureEvents '
        'reasons=${_formatReasonCounts(reasonCounts)} '
        'contexts=${contexts.isEmpty ? "-" : contexts.join("|")} '
        'first=${firstSeenAt.toIso8601String()} '
        'last=${lastSeenAt.toIso8601String()} '
        'lastDetail=${_formatValue(lastFallbackDetail)}';
  }
}

class ReadSourceReasonSummary {
  final ReadFallbackReason reason;
  final int eventCount;
  final int uniqueWordCount;
  final List<String> contexts;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final List<String> sampleWordIds;

  const ReadSourceReasonSummary({
    required this.reason,
    required this.eventCount,
    required this.uniqueWordCount,
    required this.contexts,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.sampleWordIds,
  });

  String formatLine() {
    return '[read-summary:reason] '
        'reason=${reason.code} '
        'events=$eventCount '
        'uniqueWords=$uniqueWordCount '
        'contexts=${contexts.isEmpty ? "-" : contexts.join("|")} '
        'first=${firstSeenAt.toIso8601String()} '
        'last=${lastSeenAt.toIso8601String()} '
        'sampleWords=${sampleWordIds.isEmpty ? "-" : sampleWordIds.join(",")}';
  }
}

class ReadSourceDebugCollector {
  ReadSourceDebugCollector._();

  static const int maxRecentRawEvents = 200;
  static final ReadSourceDebugCollector instance = ReadSourceDebugCollector._();

  final Map<String, WordExpressionReadSnapshot> _lastSnapshotsByWordId = {};
  final ListQueue<WordExpressionReadSnapshot> _recentSnapshots =
      ListQueue<WordExpressionReadSnapshot>();
  final ListQueue<ReadSourceRawEvent> _recentRawEvents =
      ListQueue<ReadSourceRawEvent>();
  final Map<String, _ReadSourceWordSummaryAccumulator> _wordAccumulators = {};
  final Map<ReadFallbackReason, _ReadSourceReasonSummaryAccumulator>
  _reasonAccumulators = {};

  int _nextSequence = 0;

  void recordAll(Iterable<WordExpressionReadSnapshot> snapshots) {
    for (final snapshot in snapshots) {
      record(snapshot);
    }
  }

  void record(WordExpressionReadSnapshot snapshot) {
    final wordId = snapshot.wordId.trim();
    if (wordId.isEmpty) {
      return;
    }

    final normalizedSnapshot = snapshot.copyWith(wordId: wordId);
    final observedAt = DateTime.now();
    final event = ReadSourceRawEvent(
      sequence: ++_nextSequence,
      observedAt: observedAt,
      wordId: wordId,
      context: normalizedSnapshot.context,
      requestedPolicy: normalizedSnapshot.requestedPolicy,
      resolvedSource: normalizedSnapshot.resolvedSource,
      finalResultSource: normalizedSnapshot.finalResultSource,
      didFallback: normalizedSnapshot.didFallback,
      fallbackReason: normalizedSnapshot.fallbackObservation?.reason,
      fallbackDetail: _normalizeOptionalDetail(
        normalizedSnapshot.fallbackObservation?.detail,
      ),
      legacyResultAvailable: normalizedSnapshot.legacyResultAvailable,
      normalizedResultAvailable: normalizedSnapshot.normalizedResultAvailable,
      legacySetCount: normalizedSnapshot.legacyReadResult?.sets.length ?? 0,
      normalizedSetCount:
          normalizedSnapshot.normalizedReadResult?.sets.length ?? 0,
      finalSetCount: normalizedSnapshot.readResult.sets.length,
    );

    _lastSnapshotsByWordId[wordId] = normalizedSnapshot;
    _recentSnapshots.addLast(normalizedSnapshot);
    if (_recentSnapshots.length > maxRecentRawEvents) {
      _recentSnapshots.removeFirst();
    }

    _recentRawEvents.addLast(event);
    if (_recentRawEvents.length > maxRecentRawEvents) {
      _recentRawEvents.removeFirst();
    }

    _wordAccumulators
        .putIfAbsent(
          wordId,
          () => _ReadSourceWordSummaryAccumulator(wordId: wordId),
        )
        .record(event);

    if (event.fallbackReason != null) {
      _reasonAccumulators
          .putIfAbsent(
            event.fallbackReason!,
            () => _ReadSourceReasonSummaryAccumulator(
              reason: event.fallbackReason!,
            ),
          )
          .record(event);
    }
  }

  void debugReset() {
    _lastSnapshotsByWordId.clear();
    _recentSnapshots.clear();
    _recentRawEvents.clear();
    _wordAccumulators.clear();
    _reasonAccumulators.clear();
    _nextSequence = 0;
  }

  Map<String, WordExpressionReadSnapshot> debugLastSnapshotsByWord() {
    return Map.unmodifiable(_lastSnapshotsByWordId);
  }

  WordExpressionReadSnapshot? debugLastSnapshotForWord(String wordId) {
    return _lastSnapshotsByWordId[wordId.trim()];
  }

  List<WordExpressionReadSnapshot> debugRecentSnapshots({
    int limit = maxRecentRawEvents,
  }) {
    if (limit <= 0 || _recentSnapshots.isEmpty) {
      return const [];
    }

    final snapshots = _recentSnapshots.toList(growable: false);
    if (limit >= snapshots.length) {
      return List.unmodifiable(snapshots);
    }

    return List.unmodifiable(snapshots.sublist(snapshots.length - limit));
  }

  ReadSourceWordSummary? summaryForWord(String wordId) {
    final accumulator = _wordAccumulators[wordId.trim()];
    return accumulator?.build();
  }

  List<ReadSourceWordSummary> summariesByWord() {
    final summaries = _wordAccumulators.values
        .map((accumulator) => accumulator.build())
        .toList(growable: false);

    summaries.sort((left, right) {
      final byFallback = right.fallbackEvents.compareTo(left.fallbackEvents);
      if (byFallback != 0) {
        return byFallback;
      }

      final byLastSeen = right.lastSeenAt.compareTo(left.lastSeenAt);
      if (byLastSeen != 0) {
        return byLastSeen;
      }

      return left.wordId.compareTo(right.wordId);
    });

    return List.unmodifiable(summaries);
  }

  List<ReadSourceReasonSummary> summariesByReason() {
    final summaries = _reasonAccumulators.values
        .map((accumulator) => accumulator.build())
        .toList(growable: false);

    summaries.sort((left, right) {
      final byEventCount = right.eventCount.compareTo(left.eventCount);
      if (byEventCount != 0) {
        return byEventCount;
      }

      return left.reason.code.compareTo(right.reason.code);
    });

    return List.unmodifiable(summaries);
  }

  List<ReadSourceRawEvent> recentEvents({int limit = 20}) {
    if (limit <= 0 || _recentRawEvents.isEmpty) {
      return const [];
    }

    final events = _recentRawEvents.toList(growable: false);
    final startIndex = limit >= events.length ? 0 : events.length - limit;
    final selected = events
        .sublist(startIndex)
        .reversed
        .toList(growable: false);
    return List.unmodifiable(selected);
  }

  List<String> formatWordSummaryLines({String? wordId}) {
    if (wordId != null) {
      final summary = summaryForWord(wordId);
      return summary == null ? const [] : [summary.formatLine()];
    }

    return summariesByWord()
        .map((summary) => summary.formatLine())
        .toList(growable: false);
  }

  List<String> formatReasonSummaryLines() {
    return summariesByReason()
        .map((summary) => summary.formatLine())
        .toList(growable: false);
  }

  List<String> formatRecentEventLines({int limit = 20}) {
    return recentEvents(
      limit: limit,
    ).map((event) => event.formatLine()).toList(growable: false);
  }
}

class _ReadSourceWordSummaryAccumulator {
  final String wordId;
  final Set<String> _contexts = <String>{};
  final Map<ReadFallbackReason, int> _reasonCounts =
      <ReadFallbackReason, int>{};
  final Map<FinalReadResultSource, int> _finalSourceCounts =
      <FinalReadResultSource, int>{};

  int _totalEvents = 0;
  int _fallbackEvents = 0;
  int _normalizedSuccessEvents = 0;
  int _legacyOnlyEvents = 0;
  int _legacyFallbackEvents = 0;
  int _normalizedFailureEvents = 0;
  DateTime? _firstSeenAt;
  DateTime? _lastSeenAt;
  DateTime? _firstFallbackAt;
  DateTime? _lastFallbackAt;
  ReadFallbackReason? _firstFallbackReason;
  ReadFallbackReason? _lastFallbackReason;
  String? _lastFallbackDetail;

  _ReadSourceWordSummaryAccumulator({required this.wordId});

  void record(ReadSourceRawEvent event) {
    _totalEvents += 1;
    _contexts.add(event.context);
    _firstSeenAt ??= event.observedAt;
    _lastSeenAt = event.observedAt;

    _finalSourceCounts.update(
      event.finalResultSource,
      (count) => count + 1,
      ifAbsent: () => 1,
    );

    switch (event.finalResultSource) {
      case FinalReadResultSource.legacy:
        _legacyOnlyEvents += 1;
        break;
      case FinalReadResultSource.normalized:
        _normalizedSuccessEvents += 1;
        break;
      case FinalReadResultSource.legacyFallback:
        _legacyFallbackEvents += 1;
        break;
      case FinalReadResultSource.normalizedFailure:
        _normalizedFailureEvents += 1;
        break;
    }

    if (!event.didFallback || event.fallbackReason == null) {
      return;
    }

    _fallbackEvents += 1;
    _firstFallbackAt ??= event.observedAt;
    _lastFallbackAt = event.observedAt;
    _firstFallbackReason ??= event.fallbackReason;
    _lastFallbackReason = event.fallbackReason;
    _lastFallbackDetail = event.fallbackDetail;
    _reasonCounts.update(
      event.fallbackReason!,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }

  ReadSourceWordSummary build() {
    return ReadSourceWordSummary(
      wordId: wordId,
      contexts: _sortedStrings(_contexts),
      totalEvents: _totalEvents,
      fallbackEvents: _fallbackEvents,
      normalizedSuccessEvents: _normalizedSuccessEvents,
      legacyOnlyEvents: _legacyOnlyEvents,
      legacyFallbackEvents: _legacyFallbackEvents,
      normalizedFailureEvents: _normalizedFailureEvents,
      firstSeenAt: _firstSeenAt!,
      lastSeenAt: _lastSeenAt!,
      firstFallbackAt: _firstFallbackAt,
      lastFallbackAt: _lastFallbackAt,
      firstFallbackReason: _firstFallbackReason,
      lastFallbackReason: _lastFallbackReason,
      lastFallbackDetail: _lastFallbackDetail,
      reasonCounts: Map.unmodifiable(_sortedReasonCounts(_reasonCounts)),
      finalSourceCounts: Map.unmodifiable(
        _sortedFinalSourceCounts(_finalSourceCounts),
      ),
    );
  }
}

class _ReadSourceReasonSummaryAccumulator {
  static const int _maxSampleWordIds = 5;

  final ReadFallbackReason reason;
  final Set<String> _contexts = <String>{};
  final Set<String> _uniqueWordIds = <String>{};
  final List<String> _sampleWordIds = <String>[];

  int _eventCount = 0;
  DateTime? _firstSeenAt;
  DateTime? _lastSeenAt;

  _ReadSourceReasonSummaryAccumulator({required this.reason});

  void record(ReadSourceRawEvent event) {
    _eventCount += 1;
    _contexts.add(event.context);
    _firstSeenAt ??= event.observedAt;
    _lastSeenAt = event.observedAt;

    if (_uniqueWordIds.add(event.wordId) &&
        _sampleWordIds.length < _maxSampleWordIds) {
      _sampleWordIds.add(event.wordId);
    }
  }

  ReadSourceReasonSummary build() {
    return ReadSourceReasonSummary(
      reason: reason,
      eventCount: _eventCount,
      uniqueWordCount: _uniqueWordIds.length,
      contexts: _sortedStrings(_contexts),
      firstSeenAt: _firstSeenAt!,
      lastSeenAt: _lastSeenAt!,
      sampleWordIds: List.unmodifiable(_sampleWordIds),
    );
  }
}

String _formatReasonCounts(Map<ReadFallbackReason, int> reasonCounts) {
  if (reasonCounts.isEmpty) {
    return '-';
  }

  return reasonCounts.entries
      .map((entry) => '${entry.key.code}:${entry.value}')
      .join('|');
}

String _formatValue(String? value) {
  final normalized = _normalizeOptionalDetail(value);
  if (normalized == null) {
    return '-';
  }

  return '"${normalized.replaceAll('"', "'")}"';
}

String? _normalizeOptionalDetail(String? value) {
  final trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _sortedStrings(Set<String> values) {
  final sorted = values.toList(growable: false)..sort();
  return List.unmodifiable(sorted);
}

Map<ReadFallbackReason, int> _sortedReasonCounts(
  Map<ReadFallbackReason, int> reasonCounts,
) {
  final entries = reasonCounts.entries.toList(growable: false)
    ..sort((left, right) => left.key.code.compareTo(right.key.code));

  return {for (final entry in entries) entry.key: entry.value};
}

Map<FinalReadResultSource, int> _sortedFinalSourceCounts(
  Map<FinalReadResultSource, int> finalSourceCounts,
) {
  final entries = finalSourceCounts.entries.toList(growable: false)
    ..sort((left, right) => left.key.code.compareTo(right.key.code));

  return {for (final entry in entries) entry.key: entry.value};
}
