class HomeSearchRankingValue {
  final String value;
  final int fieldIndex;

  const HomeSearchRankingValue({required this.value, required this.fieldIndex});
}

class HomeSearchRankingCandidate {
  final String wordId;
  final String strongNumber;
  final List<HomeSearchRankingValue> indexedSpellings;
  final List<HomeSearchRankingValue> indexedTransliterations;
  final List<HomeSearchRankingValue> indexedMeanings;

  const HomeSearchRankingCandidate({
    required this.wordId,
    required this.strongNumber,
    required this.indexedSpellings,
    required this.indexedTransliterations,
    required this.indexedMeanings,
  });
}
