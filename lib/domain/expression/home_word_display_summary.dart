import '../../data/adapters/legacy_word_expression_read_adapter.dart';

class HomeWordDisplaySummary {
  final String representativeSpelling;
  final String representativeTransliteration;
  final String representativePronunciation;

  const HomeWordDisplaySummary({
    this.representativeSpelling = '',
    this.representativeTransliteration = '',
    this.representativePronunciation = '',
  });
}

HomeWordDisplaySummary buildHomeWordDisplaySummary(
  Map<String, dynamic> wordMap,
) {
  final readResult = readLegacyWordExpressionRow(wordMap);
  if (readResult.sets.isNotEmpty) {
    final representativeSet = readResult.sets.firstWhere(
      (set) => set.isRepresentative,
      orElse: () => readResult.sets.first,
    );

    return HomeWordDisplaySummary(
      representativeSpelling: representativeSet.spelling,
      representativeTransliteration: representativeSet.transliteration ?? '',
      representativePronunciation: representativeSet.pronunciation ?? '',
    );
  }

  // Emergency-only fallback for HomeScreen crash avoidance. Recover only the
  // representative spelling conservatively and keep transliteration /
  // pronunciation empty so issue-only values never surface in the title.
  return HomeWordDisplaySummary(
    representativeSpelling: _readFirstNonEmptyValue(wordMap, ['표기1', '표기2']),
  );
}

String buildStrongListTitle({
  required String strong,
  required HomeWordDisplaySummary summary,
}) {
  return _joinNonEmptySegments([strong, summary.representativeSpelling]);
}

String buildSearchResultTitle({
  required String strong,
  required HomeWordDisplaySummary summary,
}) {
  return _joinNonEmptySegments([
    strong,
    summary.representativeSpelling,
    summary.representativeTransliteration,
    summary.representativePronunciation,
  ]);
}

String _readFirstNonEmptyValue(
  Map<String, dynamic> wordMap,
  List<String> keys,
) {
  for (final key in keys) {
    final value = (wordMap[key] ?? '').toString().trim();
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

String _joinNonEmptySegments(Iterable<String> segments) {
  return segments.where((segment) => segment.isNotEmpty).join(' · ');
}
