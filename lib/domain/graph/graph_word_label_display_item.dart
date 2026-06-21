class GraphWordLabelDisplayItem {
  final String wordId;
  final String representativeSpelling;
  final String representativeTransliteration;
  final String displayStrongNumber;
  final String language;
  final String primaryMeaning;

  const GraphWordLabelDisplayItem({
    required this.wordId,
    required this.representativeSpelling,
    required this.representativeTransliteration,
    required this.displayStrongNumber,
    required this.language,
    required this.primaryMeaning,
  });

  String get graphBuilderLabel {
    final spelling = representativeSpelling.trim();
    if (spelling.isNotEmpty) {
      return spelling;
    }

    final strongNumber = displayStrongNumber.trim();
    if (strongNumber.isNotEmpty) {
      return strongNumber;
    }

    return wordId.trim();
  }

  String get peripheralTitleLabel {
    final spelling = representativeSpelling.trim();
    return spelling.isNotEmpty ? spelling : wordId.trim();
  }

  String get relationDisplayName {
    final spelling = representativeSpelling.trim();
    return spelling.isNotEmpty ? spelling : wordId.trim();
  }

  String secondaryLabel({required bool showStrongNumber}) {
    final transliteration = representativeTransliteration.trim();
    final strongNumber = displayStrongNumber.trim();

    if (transliteration.isEmpty) {
      return strongNumber;
    }

    if (!showStrongNumber || strongNumber.isEmpty) {
      return transliteration;
    }

    return '$transliteration · $strongNumber';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is GraphWordLabelDisplayItem &&
        other.wordId == wordId &&
        other.representativeSpelling == representativeSpelling &&
        other.representativeTransliteration == representativeTransliteration &&
        other.displayStrongNumber == displayStrongNumber &&
        other.language == language &&
        other.primaryMeaning == primaryMeaning;
  }

  @override
  int get hashCode => Object.hash(
    wordId,
    representativeSpelling,
    representativeTransliteration,
    displayStrongNumber,
    language,
    primaryMeaning,
  );
}
