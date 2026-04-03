const String supplementalWithoutSpellingWriteIssueCode =
    'supplemental_without_spelling';
const String excludedFromWriteResolution = 'excluded_from_write';

class CanonicalExpressionWriteSet {
  final String spelling;
  final String? transliteration;
  final String? pronunciation;
  final int seq;
  final bool isRepresentative;

  const CanonicalExpressionWriteSet({
    required this.spelling,
    required this.transliteration,
    required this.pronunciation,
    required this.seq,
    required this.isRepresentative,
  });
}

class WordWriteExclusionIssue {
  final String issueCode;
  final WordWriteExclusionSourceKind sourceKind;
  final int sourceIndex;
  final String? rawSpelling;
  final String? rawTransliteration;
  final String? rawPronunciation;
  final String resolution;

  const WordWriteExclusionIssue({
    required this.issueCode,
    required this.sourceKind,
    required this.sourceIndex,
    required this.rawSpelling,
    required this.rawTransliteration,
    required this.rawPronunciation,
    required this.resolution,
  });
}

enum WordWriteExclusionSourceKind { draft, legacyHiddenSlot }

class CanonicalizedExpressionSetWriteResult {
  final List<CanonicalExpressionWriteSet> expressionSets;
  final List<WordWriteExclusionIssue> exclusionIssues;

  const CanonicalizedExpressionSetWriteResult({
    this.expressionSets = const [],
    this.exclusionIssues = const [],
  });
}

class CanonicalWordWritePayload {
  final String language;
  final String? strongNumber;
  final List<CanonicalExpressionWriteSet> expressionSets;
  final List<String> meanings;
  final String? note;

  CanonicalWordWritePayload({
    required this.language,
    required this.strongNumber,
    required List<CanonicalExpressionWriteSet> expressionSets,
    List<String> meanings = const [],
    required this.note,
  }) : expressionSets = List.unmodifiable(expressionSets),
       meanings = List.unmodifiable(meanings);

  String get representativeSpelling {
    if (expressionSets.isEmpty) {
      return '';
    }
    return expressionSets.first.spelling;
  }

  String? get representativeTransliteration {
    if (expressionSets.isEmpty) {
      return null;
    }
    return expressionSets.first.transliteration;
  }

  String? get representativePronunciation {
    if (expressionSets.isEmpty) {
      return null;
    }
    return expressionSets.first.pronunciation;
  }
}

sealed class WordWriteCommand {
  const WordWriteCommand();
}

class CreateWordCommand extends WordWriteCommand {
  final CanonicalWordWritePayload payload;

  const CreateWordCommand({required this.payload});
}

class UpdateWordCommand extends WordWriteCommand {
  final String wordId;
  final CanonicalWordWritePayload payload;

  const UpdateWordCommand({required this.wordId, required this.payload});
}

class DeleteWordCommand extends WordWriteCommand {
  final String wordId;

  const DeleteWordCommand({required this.wordId});
}

enum WordWriteAction { create, update, delete }

class WordWriteResult {
  final WordWriteAction action;
  final String? wordId;

  const WordWriteResult({required this.action, this.wordId});
}
