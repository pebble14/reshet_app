import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

Future<List<int>> loadBundledDatabaseAsset(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  return Uint8List.view(data.buffer, data.offsetInBytes, data.lengthInBytes);
}
