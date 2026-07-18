import '../expression/pronunciation_notation.dart';

class WordDetailLikeDisplayItem {
  final String? representativeSpelling;
  final String? displayStrongNumber;
  final String? language;
  final List<String> spellings;
  final List<String> transliterations;
  final List<String> pronunciations;
  final List<PronunciationValue> pronunciationItems;
  final List<String> meanings;
  final String? note;

  const WordDetailLikeDisplayItem({
    this.representativeSpelling,
    this.displayStrongNumber,
    this.language,
    this.spellings = const <String>[],
    this.transliterations = const <String>[],
    this.pronunciations = const <String>[],
    this.pronunciationItems = const <PronunciationValue>[],
    this.meanings = const <String>[],
    this.note,
  });

  List<PronunciationValue> get resolvedPronunciationItems {
    if (pronunciationItems.isNotEmpty) {
      return List<PronunciationValue>.unmodifiable(pronunciationItems);
    }

    return List<PronunciationValue>.unmodifiable(
      pronunciations
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .map(
            (value) => PronunciationValue(
              text: value,
              notation: PronunciationNotation.unknown,
            ),
          ),
    );
  }

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
        _samePronunciationList(other.pronunciationItems, pronunciationItems) &&
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
    Object.hashAll(pronunciationItems),
    Object.hashAll(meanings),
    note,
  );

  static bool _samePronunciationList(
    List<PronunciationValue> left,
    List<PronunciationValue> right,
  ) {
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
