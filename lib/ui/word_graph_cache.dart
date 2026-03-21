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

  static String _normalizeGraphExpandMode(String? graphExpandMode) {
    switch ((graphExpandMode ?? '').trim().toLowerCase()) {
      case 'incoming_only':
        return 'incoming_only';
      case 'outgoing_limited':
        return 'outgoing_limited';
      case 'full':
        return 'full';
      default:
        return 'default';
    }
  }

  static String _cacheKey({
    required String centerWordId,
    required String? graphExpandMode,
  }) {
    return '$centerWordId::${_normalizeGraphExpandMode(graphExpandMode)}';
  }

  static WordGraphCacheData? get({
    required String centerWordId,
    required String? graphExpandMode,
  }) {
    final cacheKey = _cacheKey(
      centerWordId: centerWordId,
      graphExpandMode: graphExpandMode,
    );
    final entry = _entries.remove(cacheKey);
    if (entry == null) return null;

    final touchedEntry = entry.touch(DateTime.now());
    _entries[cacheKey] = touchedEntry;

    return (
      connectedWords: List<Word>.from(touchedEntry.connectedWords),
      relationEdges: List<WordRelationEdgeInfo>.from(
        touchedEntry.relationEdges,
      ),
    );
  }

  static void put({
    required String centerWordId,
    required String? graphExpandMode,
    required List<Word> connectedWords,
    required List<WordRelationEdgeInfo> relationEdges,
  }) {
    final cacheKey = _cacheKey(
      centerWordId: centerWordId,
      graphExpandMode: graphExpandMode,
    );
    _entries.remove(cacheKey);
    _entries[cacheKey] = _GraphCacheEntry(
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
    _entries.removeWhere((_, entry) => entry.centerWordId == centerWordId);
  }

  static void invalidateMany(Iterable<String> centerWordIds) {
    final idSet = centerWordIds.toSet();
    _entries.removeWhere((_, entry) => idSet.contains(entry.centerWordId));
  }

  static void clear() {
    _entries.clear();
  }
}
