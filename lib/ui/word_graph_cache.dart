import 'dart:collection';

import '../data/models/word.dart';
import '../data/repositories/word_repository.dart';

class _BaseGraphCacheEntry {
  final String centerWordId;
  final List<Word> connectedWords;
  final List<WordRelationEdgeInfo> relationEdges;
  final DateTime lastAccessedAt;

  const _BaseGraphCacheEntry({
    required this.centerWordId,
    required this.connectedWords,
    required this.relationEdges,
    required this.lastAccessedAt,
  });

  _BaseGraphCacheEntry touch(DateTime now) {
    return _BaseGraphCacheEntry(
      centerWordId: centerWordId,
      connectedWords: connectedWords,
      relationEdges: relationEdges,
      lastAccessedAt: now,
    );
  }
}

class _ExpansionGraphCacheEntry {
  final String centerWordId;
  final String sourceWordId;
  final List<Word> connectedWords;
  final List<WordRelationEdgeInfo> relationEdges;
  final DateTime lastAccessedAt;

  const _ExpansionGraphCacheEntry({
    required this.centerWordId,
    required this.sourceWordId,
    required this.connectedWords,
    required this.relationEdges,
    required this.lastAccessedAt,
  });

  _ExpansionGraphCacheEntry touch(DateTime now) {
    return _ExpansionGraphCacheEntry(
      centerWordId: centerWordId,
      sourceWordId: sourceWordId,
      connectedWords: connectedWords,
      relationEdges: relationEdges,
      lastAccessedAt: now,
    );
  }
}

typedef WordGraphBaseCacheData = ({
  List<Word> connectedWords,
  List<WordRelationEdgeInfo> relationEdges,
});

typedef WordGraphExpansionCacheData = ({
  List<Word> connectedWords,
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
      connectedWords: List<Word>.from(touchedEntry.connectedWords),
      relationEdges: List<WordRelationEdgeInfo>.from(
        touchedEntry.relationEdges,
      ),
    );
  }

  static void putBaseGraph({
    required String centerWordId,
    required List<Word> connectedWords,
    required List<WordRelationEdgeInfo> relationEdges,
  }) {
    final cacheKey = _baseCacheKey(centerWordId: centerWordId);
    _baseEntries.remove(cacheKey);
    _baseEntries[cacheKey] = _BaseGraphCacheEntry(
      centerWordId: centerWordId,
      connectedWords: List<Word>.unmodifiable(connectedWords),
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
      connectedWords: List<Word>.from(touchedEntry.connectedWords),
      relationEdges: List<WordRelationEdgeInfo>.from(
        touchedEntry.relationEdges,
      ),
    );
  }

  static void putExpansion({
    required String centerWordId,
    required String sourceWordId,
    required List<Word> connectedWords,
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
      connectedWords: List<Word>.unmodifiable(connectedWords),
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
