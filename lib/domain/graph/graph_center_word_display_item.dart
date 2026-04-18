class GraphCenterWordDisplayItem {
  final String wordId;
  final String language;
  final String displayStrongNumber;
  final String representativeSpelling;
  final String representativeTransliteration;
  final String representativePronunciation;
  final String primaryMeaning;

  const GraphCenterWordDisplayItem({
    required this.wordId,
    required this.language,
    required this.displayStrongNumber,
    required this.representativeSpelling,
    required this.representativeTransliteration,
    required this.representativePronunciation,
    required this.primaryMeaning,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is GraphCenterWordDisplayItem &&
        other.wordId == wordId &&
        other.language == language &&
        other.displayStrongNumber == displayStrongNumber &&
        other.representativeSpelling == representativeSpelling &&
        other.representativeTransliteration == representativeTransliteration &&
        other.representativePronunciation == representativePronunciation &&
        other.primaryMeaning == primaryMeaning;
  }

  @override
  int get hashCode => Object.hash(
    wordId,
    language,
    displayStrongNumber,
    representativeSpelling,
    representativeTransliteration,
    representativePronunciation,
    primaryMeaning,
  );
}
