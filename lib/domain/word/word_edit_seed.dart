import '../expression/expression_read_models.dart';
import 'word_write_models.dart';

class WordEditSeed {
  final String wordId;
  final String language;
  final String strongNumber;
  final String note;
  final List<String> meanings;
  final CanonicalExpressionReadResult expressionReadResult;
  final List<WordWriteExclusionIssue> hiddenSlotIssues;

  WordEditSeed({
    required this.wordId,
    required this.language,
    required this.strongNumber,
    required this.note,
    required List<String> meanings,
    required this.expressionReadResult,
    required List<WordWriteExclusionIssue> hiddenSlotIssues,
  }) : meanings = List.unmodifiable(meanings),
       hiddenSlotIssues = List.unmodifiable(hiddenSlotIssues);
}

List<WordWriteExclusionIssue> buildWordEditHiddenSlotIssuesFromReadResult(
  CanonicalExpressionReadResult readResult,
) {
  return readResult.issues
      .map(
        (issue) => WordWriteExclusionIssue(
          issueCode: issue.issueCode,
          sourceKind: WordWriteExclusionSourceKind.legacyHiddenSlot,
          sourceIndex: issue.sourceSlot,
          rawSpelling: issue.rawSpelling,
          rawTransliteration: issue.rawTransliteration,
          rawPronunciation: issue.rawPronunciation,
          resolution: excludedFromWriteResolution,
        ),
      )
      .toList(growable: false);
}
