import 'dart:collection';
import 'dart:ui';

import '../graph_build_options.dart';
import '../graph_layout_result.dart';
import '../graph_view_data.dart';
import 'graph_layout_options.dart';

class _GraphLayoutCacheKey {
  final GraphLayoutMode layoutMode;
  final double layoutSpaceWidth;
  final double layoutSpaceHeight;
  final int? layoutSeed;
  final int viewDataSignature;
  final int seedPositionsSignature;

  const _GraphLayoutCacheKey({
    required this.layoutMode,
    required this.layoutSpaceWidth,
    required this.layoutSpaceHeight,
    required this.layoutSeed,
    required this.viewDataSignature,
    required this.seedPositionsSignature,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _GraphLayoutCacheKey &&
        other.layoutMode == layoutMode &&
        other.layoutSpaceWidth == layoutSpaceWidth &&
        other.layoutSpaceHeight == layoutSpaceHeight &&
        other.layoutSeed == layoutSeed &&
        other.viewDataSignature == viewDataSignature &&
        other.seedPositionsSignature == seedPositionsSignature;
  }

  @override
  int get hashCode => Object.hash(
    layoutMode,
    layoutSpaceWidth,
    layoutSpaceHeight,
    layoutSeed,
    viewDataSignature,
    seedPositionsSignature,
  );
}

class _GraphLayoutCacheEntry {
  final GraphLayoutResult result;

  const _GraphLayoutCacheEntry({required this.result});
}

class GraphLayoutCache {
  static const int _maxEntries = 24;
  static final LinkedHashMap<_GraphLayoutCacheKey, _GraphLayoutCacheEntry>
  _entries = LinkedHashMap<_GraphLayoutCacheKey, _GraphLayoutCacheEntry>();

  static GraphLayoutResult getOrCompute({
    required GraphLayoutMode layoutMode,
    required GraphViewData viewData,
    required GraphLayoutOptions options,
    required int? layoutSeed,
    required Map<String, Offset> seedPositions,
    required GraphLayoutResult Function() compute,
  }) {
    final cacheKey = _GraphLayoutCacheKey(
      layoutMode: layoutMode,
      layoutSpaceWidth: options.layoutSpaceSize.width,
      layoutSpaceHeight: options.layoutSpaceSize.height,
      layoutSeed: layoutSeed,
      viewDataSignature: _viewDataSignature(viewData),
      seedPositionsSignature: _seedPositionsSignature(viewData, seedPositions),
    );
    final cachedEntry = _entries.remove(cacheKey);
    if (cachedEntry != null) {
      _entries[cacheKey] = cachedEntry;
      return cachedEntry.result;
    }

    final result = compute();
    _entries[cacheKey] = _GraphLayoutCacheEntry(result: result);

    while (_entries.length > _maxEntries) {
      _entries.remove(_entries.keys.first);
    }

    return result;
  }

  static void clear() {
    _entries.clear();
  }

  static int _viewDataSignature(GraphViewData viewData) {
    var signature = 0x1f123bb5;

    void mixInt(int value) {
      signature = 0x1fffffff & (signature + value);
      signature = 0x1fffffff & (signature + ((0x0007ffff & signature) << 10));
      signature ^= (signature >> 6);
    }

    void mixString(String value) {
      for (final unit in value.codeUnits) {
        mixInt(unit);
      }
    }

    void mixDouble(double value) {
      mixString(value.toStringAsFixed(6));
    }

    mixString(viewData.centerNodeId);
    mixInt(viewData.nodes.length);
    mixInt(viewData.edges.length);

    for (final node in viewData.nodes) {
      mixString(node.id);
      mixString(node.label);
      mixInt(node.depth);
      mixDouble(node.weight);
      mixInt(node.isPinned ? 1 : 0);
    }

    for (final edge in viewData.edges) {
      mixString(edge.id);
      mixString(edge.sourceId);
      mixString(edge.targetId);
      mixDouble(edge.weight);
    }

    signature = 0x1fffffff & (signature + ((0x03ffffff & signature) << 3));
    signature ^= (signature >> 11);
    signature = 0x1fffffff & (signature + ((0x00003fff & signature) << 15));

    return signature & 0x7fffffff;
  }

  static int _seedPositionsSignature(
    GraphViewData viewData,
    Map<String, Offset> seedPositions,
  ) {
    var signature = 0x4c11db7;

    void mixInt(int value) {
      signature = 0x1fffffff & (signature + value);
      signature = 0x1fffffff & (signature + ((0x0007ffff & signature) << 10));
      signature ^= (signature >> 6);
    }

    void mixString(String value) {
      for (final unit in value.codeUnits) {
        mixInt(unit);
      }
    }

    void mixDouble(double value) {
      mixString(value.toStringAsFixed(4));
    }

    for (final node in viewData.nodes) {
      final seedPosition = seedPositions[node.id];
      if (seedPosition == null) {
        continue;
      }
      mixString(node.id);
      mixDouble(seedPosition.dx);
      mixDouble(seedPosition.dy);
    }

    signature = 0x1fffffff & (signature + ((0x03ffffff & signature) << 3));
    signature ^= (signature >> 11);
    signature = 0x1fffffff & (signature + ((0x00003fff & signature) << 15));

    return signature & 0x7fffffff;
  }
}
