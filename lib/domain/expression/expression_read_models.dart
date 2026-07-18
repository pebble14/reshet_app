import 'pronunciation_notation.dart';

class ExpressionSet {
  final String spelling;
  final String? transliteration;
  final String? pronunciation;
  final PronunciationNotation? pronunciationNotation;
  final String? pronunciationNotationName;
  final int seq;
  final bool isRepresentative;

  const ExpressionSet({
    required this.spelling,
    required this.transliteration,
    required this.pronunciation,
    this.pronunciationNotation,
    this.pronunciationNotationName,
    required this.seq,
    required this.isRepresentative,
  });

  PronunciationValue? get pronunciationValue => normalizePronunciationForWrite(
    pronunciation: pronunciation,
    notation: pronunciationNotation,
    notationName: pronunciationNotationName,
  );
}

class ExpressionSetIssue {
  final String issueCode;
  final int sourceSlot;
  final String? rawSpelling;
  final String? rawTransliteration;
  final String? rawPronunciation;
  final String resolution;

  const ExpressionSetIssue({
    required this.issueCode,
    required this.sourceSlot,
    required this.rawSpelling,
    required this.rawTransliteration,
    required this.rawPronunciation,
    required this.resolution,
  });
}

class CanonicalExpressionReadResult {
  final List<ExpressionSet> sets;
  final List<ExpressionSetIssue> issues;

  const CanonicalExpressionReadResult({
    this.sets = const [],
    this.issues = const [],
  });
}
