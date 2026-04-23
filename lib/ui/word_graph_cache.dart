import 'dart:collection';

import '../data/repositories/word_repository.dart';
import '../domain/graph/graph_visible_word.dart';
import '../domain/graph/graph_word_label_display_item.dart';

class _BaseGraphCacheEntry {
  final String centerWordId;
  final List<GraphVisibleWord> connectedWords;
  final List<GraphWordLabelDisplayItem> wordLabels;
  final List<WordRelationEdgeInfo> relationEdges;
  final DateTime lastAccessedAt;

  const _BaseGraphCacheEntry({
    required this.centerWordId,
    required this.connectedWords,
    required this.wordLabels,
    required this.relationEdges,
    required this.lastAccessedAt,
  });

  _BaseGraphCacheEntry touch(DateTime now) {
    return _BaseGraphCacheEntry(
      centerWordId: centerWordId,
      connectedWords: connectedWords,
      wordLabels: wordLabels,
      relationEdges: relationEdges,
      lastAccessedAt: now,
    );
  }
}

class _ExpansionGraphCacheEntry {
  final String centerWordId;
  final String sourceWordId;
  final List<GraphVisibleWord> connectedWords;
  final List<GraphWordLabelDisplayItem> wordLabels;
  final List<WordRelationEdgeInfo> relationEdges;
  final DateTime lastAccessedAt;

  const _ExpansionGraphCacheEntry({
    required this.centerWordId,
    required this.sourceWordId,
    required this.connectedWords,
    required this.wordLabels,
    required this.relationEdges,
    required this.lastAccessedAt,
  });

  _ExpansionGraphCacheEntry touch(DateTime now) {
    return _ExpansionGraphCacheEntry(
      centerWordId: centerWordId,
      sourceWordId: sourceWordId,
      connectedWords: connectedWords,
      wordLabels: wordLabels,
      relationEdges: relationEdges,
      lastAccessedAt: now,
    );
  }
}

typedef WordGraphBaseCacheData = ({
  List<GraphVisibleWord> connectedWords,
  List<GraphWordLabelDisplayItem> wordLabels,
  List<WordRelationEdgeInfo> relationEdges,
});

typedef WordGraphExpansionCacheData = ({
  List<GraphVisibleWord> connectedWords,
  List<GraphWordLabelDisplayItem> wordLabels,
  List<WordRelationEdgeInfo> relationEdges,
});

class WordGraphDataCache {
  static const int _maxBaseEntries = 8;
  static const int _maxExpansionEntries = 24;
  static final LinkedHashMap<String, _BaseGraphCacheEntry> _baseEntries =
      LinkedHashMap<String, _BaseGraphCacheEntry>();
  static final LinkedHashMap<String, _ExpansionGraphCacheEntry>
  _expansionEntries = LinkedHashMap<String, _ExpansionGraphCacheEntry>();

  static String _baseCacheKey({required String centerWordId}) {
    return centerWordId;
  }

  static String _expansionCacheKey({
    required String centerWordId,
    required String sourceWordId,
  }) {
    return '$centerWordId::$sourceWordId';
  }

  static WordGraphBaseCacheData? getBaseGraph({required String centerWordId}) {
    final cacheKey = _baseCacheKey(centerWordId: centerWordId);
    final entry = _baseEntries.remove(cacheKey);
    if (entry == null) {
      return null;
    }

    final touchedEntry = entry.touch(DateTime.now());
    _baseEntries[cacheKey] = touchedEntry;
    return (
      connectedWords: List<GraphVisibleWord>.from(touchedEntry.connectedWords),
      wordLabels: List<GraphWordLabelDisplayItem>.from(touchedEntry.wordLabels),
      relationEdges: List<WordRelationEdgeInfo>.from(
        touchedEntry.relationEdges,
      ),
    );
  }

  static void putBaseGraph({
    required String centerWordId,
    required List<GraphVisibleWord> connectedWords,
    required List<GraphWordLabelDisplayItem> wordLabels,
    required List<WordRelationEdgeInfo> relationEdges,
  }) {
    final cacheKey = _baseCacheKey(centerWordId: centerWordId);
    _baseEntries.remove(cacheKey);
    _baseEntries[cacheKey] = _BaseGraphCacheEntry(
      centerWordId: centerWordId,
      connectedWords: List<GraphVisibleWord>.unmodifiable(connectedWords),
      wordLabels: List<GraphWordLabelDisplayItem>.unmodifiable(wordLabels),
      relationEdges: List<WordRelationEdgeInfo>.unmodifiable(relationEdges),
      lastAccessedAt: DateTime.now(),
    );
    _trimEntries(_baseEntries, _maxBaseEntries);
  }

  static WordGraphExpansionCacheData? getExpansion({
    required String centerWordId,
    required String sourceWordId,
  }) {
    final cacheKey = _expansionCacheKey(
      centerWordId: centerWordId,
      sourceWordId: sourceWordId,
    );
    final entry = _expansionEntries.remove(cacheKey);
    if (entry == null) {
      return null;
    }

    final touchedEntry = entry.touch(DateTime.now());
    _expansionEntries[cacheKey] = touchedEntry;
    return (
      connectedWords: List<GraphVisibleWord>.from(touchedEntry.connectedWords),
      wordLabels: List<GraphWordLabelDisplayItem>.from(touchedEntry.wordLabels),
      relationEdges: List<WordRelationEdgeInfo>.from(
        touchedEntry.relationEdges,
      ),
    );
  }

  static void putExpansion({
    required String centerWordId,
    required String sourceWordId,
    required List<GraphVisibleWord> connectedWords,
    required List<GraphWordLabelDisplayItem> wordLabels,
    required List<WordRelationEdgeInfo> relationEdges,
  }) {
    final cacheKey = _expansionCacheKey(
      centerWordId: centerWordId,
      sourceWordId: sourceWordId,
    );
    _expansionEntries.remove(cacheKey);
    _expansionEntries[cacheKey] = _ExpansionGraphCacheEntry(
      centerWordId: centerWordId,
      sourceWordId: sourceWordId,
      connectedWords: List<GraphVisibleWord>.unmodifiable(connectedWords),
      wordLabels: List<GraphWordLabelDisplayItem>.unmodifiable(wordLabels),
      relationEdges: List<WordRelationEdgeInfo>.unmodifiable(relationEdges),
      lastAccessedAt: DateTime.now(),
    );
    _trimEntries(_expansionEntries, _maxExpansionEntries);
  }

  static void clearExpansionsForCenter(String centerWordId) {
    _expansionEntries.removeWhere(
      (_, entry) => entry.centerWordId == centerWordId,
    );
  }

  static void invalidate(String centerWordId) {
    _baseEntries.removeWhere((_, entry) => entry.centerWordId == centerWordId);
    _expansionEntries.removeWhere(
      (_, entry) =>
          entry.centerWordId == centerWordId ||
          entry.sourceWordId == centerWordId,
    );
  }

  static void invalidateMany(Iterable<String> centerWordIds) {
    final idSet = centerWordIds.toSet();
    _baseEntries.removeWhere((_, entry) => idSet.contains(entry.centerWordId));
    _expansionEntries.removeWhere(
      (_, entry) =>
          idSet.contains(entry.centerWordId) ||
          idSet.contains(entry.sourceWordId),
    );
  }

  static void clear() {
    _baseEntries.clear();
    _expansionEntries.clear();
  }

  static void _trimEntries<K, V>(LinkedHashMap<K, V> entries, int maxEntries) {
    while (entries.length > maxEntries) {
      entries.remove(entries.keys.first);
    }
  }
}
