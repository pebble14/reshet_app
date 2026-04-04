import '../../domain/expression/expression_read_models.dart';

List<Map<String, Object?>> toWordExpressionSetRows(
  String wordId,
  List<ExpressionSet> sets,
) {
  final normalizedWordId = wordId.trim();
  if (normalizedWordId.isEmpty) {
    throw ArgumentError.value(wordId, 'wordId', 'wordId는 비어 있을 수 없습니다.');
  }

  final normalizedSets = sets
      .where((set) => set.spelling.trim().isNotEmpty)
      .toList(growable: false);

  return List.generate(normalizedSets.length, (index) {
    final set = normalizedSets[index];
    final seq = index + 1;

    return {
      'word_id': normalizedWordId,
      'seq': seq,
      'is_representative': seq == 1 ? 1 : 0,
      'spelling': set.spelling.trim(),
      'transliteration': _trimToNull(set.transliteration),
      'pronunciation': _trimToNull(set.pronunciation),
    };
  }, growable: false);
}

String? _trimToNull(String? value) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
