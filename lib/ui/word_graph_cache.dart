import 'dart:collection';

import '../data/models/word.dart';
import '../data/repositories/word_repository.dart';

class _GraphCacheEntry {
  final String centerWordId;
  final List<Word> connectedWords;
  final List<WordRelationEdgeInfo> relationEdges;
  final DateTime lastAccessedAt;

  const _GraphCacheEntry({
    required this.centerWordId,
    required this.connectedWords,
    required this.relationEdges,
    required this.lastAccessedAt,
  });

  _GraphCacheEntry touch(DateTime now) {
    return _GraphCacheEntry(
      centerWordId: centerWordId,
      connectedWords: connectedWords,
      relationEdges: relationEdges,
      lastAccessedAt: now,
    );
  }
}

typedef WordGraphCacheData = ({
  List<Word> connectedWords,
  List<WordRelationEdgeInfo> relationEdges,
});

class WordGraphDataCache {
  static const int _maxEntries = 8;
  static final LinkedHashMap<String, _GraphCacheEntry> _entries =
      LinkedHashMap<String, _GraphCacheEntry>();

  static WordGraphCacheData? get(String centerWordId) {
    final entry = _entries.remove(centerWordId);
    if (entry == null) return null;

    final touchedEntry = entry.touch(DateTime.now());
    _entries[centerWordId] = touchedEntry;

    return (
      connectedWords: List<Word>.from(touchedEntry.connectedWords),
      relationEdges: List<WordRelationEdgeInfo>.from(
        touchedEntry.relationEdges,
      ),
    );
  }

  static void put({
    required String centerWordId,
    required List<Word> connectedWords,
    required List<WordRelationEdgeInfo> relationEdges,
  }) {
    _entries.remove(centerWordId);
    _entries[centerWordId] = _GraphCacheEntry(
      centerWordId: centerWordId,
      connectedWords: List<Word>.unmodifiable(connectedWords),
      relationEdges: List<WordRelationEdgeInfo>.unmodifiable(relationEdges),
      lastAccessedAt: DateTime.now(),
    );

    while (_entries.length > _maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  static void invalidate(String centerWordId) {
    _entries.remove(centerWordId);
  }

  static void invalidateMany(Iterable<String> centerWordIds) {
    for (final centerWordId in centerWordIds.toSet()) {
      _entries.remove(centerWordId);
    }
  }

  static void clear() {
    _entries.clear();
  }
}
