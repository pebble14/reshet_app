class HomeSearchResultDisplayItem {
  final String wordId;
  final String? displayStrongNumber;
  final String? representativeSpelling;
  final String? representativeTransliteration;
  final String? representativePronunciation;
  final String? subtitleMeaning;

  const HomeSearchResultDisplayItem({
    required this.wordId,
    this.displayStrongNumber,
    this.representativeSpelling,
    this.representativeTransliteration,
    this.representativePronunciation,
    this.subtitleMeaning,
  });
}
