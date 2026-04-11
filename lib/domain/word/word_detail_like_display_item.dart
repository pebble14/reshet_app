class WordDetailLikeDisplayItem {
  final String? representativeSpelling;
  final String? displayStrongNumber;
  final String? language;
  final List<String> spellings;
  final List<String> transliterations;
  final List<String> pronunciations;
  final List<String> meanings;
  final String? note;

  const WordDetailLikeDisplayItem({
    this.representativeSpelling,
    this.displayStrongNumber,
    this.language,
    this.spellings = const <String>[],
    this.transliterations = const <String>[],
    this.pronunciations = const <String>[],
    this.meanings = const <String>[],
    this.note,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is WordDetailLikeDisplayItem &&
        other.representativeSpelling == representativeSpelling &&
        other.displayStrongNumber == displayStrongNumber &&
        other.language == language &&
        _sameStringList(other.spellings, spellings) &&
        _sameStringList(other.transliterations, transliterations) &&
        _sameStringList(other.pronunciations, pronunciations) &&
        _sameStringList(other.meanings, meanings) &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(
    representativeSpelling,
    displayStrongNumber,
    language,
    Object.hashAll(spellings),
    Object.hashAll(transliterations),
    Object.hashAll(pronunciations),
    Object.hashAll(meanings),
    note,
  );

  static bool _sameStringList(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }
}
