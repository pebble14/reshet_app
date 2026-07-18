import '../../domain/expression/expression_read_models.dart';
import '../../domain/expression/pronunciation_notation.dart';

const String supplementalWithoutSpellingIssueCode =
    'supplemental_without_spelling';
const String manualCleanupRequiredResolution = 'manual_cleanup_required';

CanonicalExpressionReadResult readLegacyWordExpressionRow(
  Map<String, dynamic> row,
) {
  final sets = <ExpressionSet>[];
  final issues = <ExpressionSetIssue>[];

  for (var slot = 1; slot <= 6; slot++) {
    final spelling = _readTrimmedValue(row, '표기$slot');
    final transliteration = _readTrimmedValue(row, '음역$slot');
    final pronunciation = _readTrimmedValue(row, '발음$slot');

    if (spelling != null) {
      final seq = sets.length + 1;
      sets.add(
        ExpressionSet(
          spelling: spelling,
          transliteration: transliteration,
          pronunciation: pronunciation,
          pronunciationNotation: pronunciation == null
              ? null
              : PronunciationNotation.unknown,
          seq: seq,
          isRepresentative: sets.isEmpty,
        ),
      );
      continue;
    }

    if (transliteration != null || pronunciation != null) {
      issues.add(
        ExpressionSetIssue(
          issueCode: supplementalWithoutSpellingIssueCode,
          sourceSlot: slot,
          rawSpelling: _readRawValue(row, '표기$slot'),
          rawTransliteration: _readRawValue(row, '음역$slot'),
          rawPronunciation: _readRawValue(row, '발음$slot'),
          resolution: manualCleanupRequiredResolution,
        ),
      );
    }
  }

  return CanonicalExpressionReadResult(
    sets: List.unmodifiable(sets),
    issues: List.unmodifiable(issues),
  );
}

String? _readTrimmedValue(Map<String, dynamic> row, String key) {
  final trimmed = (row[key] ?? '').toString().trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String? _readRawValue(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value == null) {
    return null;
  }

  final stringValue = value.toString();
  if (stringValue.isEmpty) {
    return null;
  }

  return stringValue;
}
