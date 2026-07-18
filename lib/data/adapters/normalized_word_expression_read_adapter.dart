import '../../domain/expression/expression_read_models.dart';
import '../../domain/expression/pronunciation_notation.dart';
import '../../domain/expression/read_source_policy.dart';

class NormalizedWordExpressionReadOutcome {
  final CanonicalExpressionReadResult? readResult;
  final ReadFallbackReason? failureReason;
  final String? detail;

  const NormalizedWordExpressionReadOutcome({
    this.readResult,
    this.failureReason,
    this.detail,
  });

  bool get isSuccess => readResult != null && failureReason == null;
}

NormalizedWordExpressionReadOutcome readNormalizedWordExpressionRows(
  List<Map<String, dynamic>> rows,
) {
  if (rows.isEmpty) {
    return const NormalizedWordExpressionReadOutcome(
      failureReason: ReadFallbackReason.emptyResult,
      detail: 'normalized rows are empty',
    );
  }

  final parsedRows = <_NormalizedExpressionRow>[];
  var sawBlankSpelling = false;

  for (var index = 0; index < rows.length; index++) {
    final row = rows[index];
    final seq = _readPositiveInt(row['seq']);
    if (seq == null) {
      return NormalizedWordExpressionReadOutcome(
        failureReason: ReadFallbackReason.mappingInvalid,
        detail: 'invalid seq at row index=$index',
      );
    }

    final isRepresentativeFlag = _readRepresentativeFlag(
      row['is_representative'],
    );
    if (isRepresentativeFlag == null) {
      return NormalizedWordExpressionReadOutcome(
        failureReason: ReadFallbackReason.mappingInvalid,
        detail: 'invalid representative flag at row index=$index',
      );
    }

    final spelling = _readRequiredTrimmedString(row['spelling']);
    if (spelling == null) {
      sawBlankSpelling = true;
      continue;
    }

    final pronunciation = _readPronunciation(row, index);
    if (pronunciation.error != null) {
      return NormalizedWordExpressionReadOutcome(
        failureReason: ReadFallbackReason.mappingInvalid,
        detail: pronunciation.error,
      );
    }

    parsedRows.add(
      _NormalizedExpressionRow(
        rowOrder: index,
        stableId: _readStableInt(row['id']),
        seq: seq,
        isRepresentative: isRepresentativeFlag,
        spelling: spelling,
        transliteration: _readOptionalTrimmedString(row['transliteration']),
        pronunciation: pronunciation.value,
      ),
    );
  }

  if (parsedRows.isEmpty) {
    return NormalizedWordExpressionReadOutcome(
      failureReason: sawBlankSpelling
          ? ReadFallbackReason.minimumExpressionNotMet
          : ReadFallbackReason.emptyResult,
      detail: sawBlankSpelling
          ? 'normalized rows do not contain a valid spelling'
          : 'normalized rows are empty after parsing',
    );
  }

  final seqSet = <int>{};
  for (final row in parsedRows) {
    if (!seqSet.add(row.seq)) {
      return const NormalizedWordExpressionReadOutcome(
        failureReason: ReadFallbackReason.mappingInvalid,
        detail: 'duplicate seq detected in normalized rows',
      );
    }
  }

  final representativeRows = parsedRows
      .where((row) => row.isRepresentative)
      .toList(growable: false);
  if (representativeRows.length > 1) {
    return const NormalizedWordExpressionReadOutcome(
      failureReason: ReadFallbackReason.mappingInvalid,
      detail: 'multiple representative rows detected',
    );
  }

  parsedRows.sort((left, right) {
    final bySeq = left.seq.compareTo(right.seq);
    if (bySeq != 0) {
      return bySeq;
    }

    final byStableId = left.stableId.compareTo(right.stableId);
    if (byStableId != 0) {
      return byStableId;
    }

    return left.rowOrder.compareTo(right.rowOrder);
  });

  final representativeSeq = representativeRows.isNotEmpty
      ? representativeRows.single.seq
      : parsedRows.first.seq;

  final sets = parsedRows
      .map(
        (row) => ExpressionSet(
          spelling: row.spelling,
          transliteration: row.transliteration,
          pronunciation: row.pronunciation?.text,
          pronunciationNotation: row.pronunciation?.notation,
          pronunciationNotationName: row.pronunciation?.notationName,
          seq: row.seq,
          isRepresentative: row.seq == representativeSeq,
        ),
      )
      .toList(growable: false);

  return NormalizedWordExpressionReadOutcome(
    readResult: CanonicalExpressionReadResult(
      sets: List.unmodifiable(sets),
      issues: const [],
    ),
  );
}

int? _readPositiveInt(Object? value) {
  final parsed = _readStableInt(value);
  if (parsed <= 0) {
    return null;
  }
  return parsed;
}

bool? _readRepresentativeFlag(Object? value) {
  final parsed = _readStableInt(value);
  if (parsed == 0) {
    return false;
  }
  if (parsed == 1) {
    return true;
  }
  return null;
}

int _readStableInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse((value ?? '').toString()) ?? 0;
}

String? _readRequiredTrimmedString(Object? value) {
  final trimmed = (value ?? '').toString().trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String? _readOptionalTrimmedString(Object? value) {
  final trimmed = (value ?? '').toString().trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

({PronunciationValue? value, String? error}) _readPronunciation(
  Map<String, dynamic> row,
  int rowIndex,
) {
  try {
    return (
      value: readStoredPronunciation(
        pronunciation: row['pronunciation'],
        notationCode: row['pronunciation_notation'],
        notationName: row['pronunciation_notation_name'],
      ),
      error: null,
    );
  } on FormatException catch (error) {
    return (
      value: null,
      error:
          'invalid pronunciation metadata at row index=$rowIndex: '
          '${error.message}',
    );
  }
}

class _NormalizedExpressionRow {
  final int rowOrder;
  final int stableId;
  final int seq;
  final bool isRepresentative;
  final String spelling;
  final String? transliteration;
  final PronunciationValue? pronunciation;

  const _NormalizedExpressionRow({
    required this.rowOrder,
    required this.stableId,
    required this.seq,
    required this.isRepresentative,
    required this.spelling,
    required this.transliteration,
    required this.pronunciation,
  });
}
