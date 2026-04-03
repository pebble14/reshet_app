import '../../domain/word/word_write_models.dart';

Map<String, String?> toLegacyWordExpressionColumns(
  List<CanonicalExpressionWriteSet> sets,
) {
  final normalizedSets = sets
      .where((set) => set.spelling.trim().isNotEmpty)
      .take(6)
      .toList(growable: false);

  final columns = <String, String?>{};

  for (var index = 1; index <= 6; index++) {
    final set = index <= normalizedSets.length
        ? normalizedSets[index - 1]
        : null;

    columns['표기$index'] = _trimToNull(set?.spelling);
    columns['음역$index'] = _trimToNull(set?.transliteration);
    columns['발음$index'] = _trimToNull(set?.pronunciation);
  }

  return columns;
}

String? _trimToNull(String? value) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
