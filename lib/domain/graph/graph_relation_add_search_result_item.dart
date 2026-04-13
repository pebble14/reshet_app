class GraphRelationAddSearchResultItem {
  final String wordId;
  final String representativeSpelling;
  final String primaryMeaning;
  final String displayStrongNumber;

  const GraphRelationAddSearchResultItem({
    required this.wordId,
    required this.representativeSpelling,
    required this.primaryMeaning,
    required this.displayStrongNumber,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is GraphRelationAddSearchResultItem &&
        other.wordId == wordId &&
        other.representativeSpelling == representativeSpelling &&
        other.primaryMeaning == primaryMeaning &&
        other.displayStrongNumber == displayStrongNumber;
  }

  @override
  int get hashCode => Object.hash(
    wordId,
    representativeSpelling,
    primaryMeaning,
    displayStrongNumber,
  );
}
