class DuplicateCandidateDisplayItem {
  final String wordId;
  final String language;
  final String strongNumber;
  final String representativeSpelling;
  final String primaryMeaning;

  const DuplicateCandidateDisplayItem({
    required this.wordId,
    required this.language,
    required this.strongNumber,
    required this.representativeSpelling,
    required this.primaryMeaning,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is DuplicateCandidateDisplayItem &&
        other.wordId == wordId &&
        other.language == language &&
        other.strongNumber == strongNumber &&
        other.representativeSpelling == representativeSpelling &&
        other.primaryMeaning == primaryMeaning;
  }

  @override
  int get hashCode => Object.hash(
    wordId,
    language,
    strongNumber,
    representativeSpelling,
    primaryMeaning,
  );
}
