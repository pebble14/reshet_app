import 'database_seed_asset_loader_io.dart'
    if (dart.library.ui) 'database_seed_asset_loader_flutter.dart'
    as implementation;

Future<List<int>> loadBundledDatabaseAsset(String assetPath) {
  return implementation.loadBundledDatabaseAsset(assetPath);
}
