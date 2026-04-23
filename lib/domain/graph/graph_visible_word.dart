class GraphVisibleWord {
  final String wordId;
  final String fallbackSpelling;
  final String fallbackStrongNumber;
  final String fallbackTransliteration;

  const GraphVisibleWord({
    required this.wordId,
    required this.fallbackSpelling,
    required this.fallbackStrongNumber,
    required this.fallbackTransliteration,
  });

  String get graphBuilderFallbackLabel {
    final spelling = fallbackSpelling.trim();
    if (spelling.isNotEmpty) {
      return spelling;
    }

    final strongNumber = fallbackStrongNumber.trim();
    if (strongNumber.isNotEmpty) {
      return strongNumber;
    }

    return wordId.trim();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is GraphVisibleWord &&
        other.wordId == wordId &&
        other.fallbackSpelling == fallbackSpelling &&
        other.fallbackStrongNumber == fallbackStrongNumber &&
        other.fallbackTransliteration == fallbackTransliteration;
  }

  @override
  int get hashCode => Object.hash(
    wordId,
    fallbackSpelling,
    fallbackStrongNumber,
    fallbackTransliteration,
  );
}
