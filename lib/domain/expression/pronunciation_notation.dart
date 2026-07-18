enum PronunciationNotation {
  strongDictionary('strong_dictionary', 'Strong 사전식'),
  ipaPhonemic('ipa_phonemic', 'IPA — 음소 표기'),
  ipaPhonetic('ipa_phonetic', 'IPA — 음성 표기'),
  other('other', '기타'),
  unknown('unknown', '표기 체계 미상');

  const PronunciationNotation(this.code, this.label);

  final String code;
  final String label;
}

PronunciationNotation parsePronunciationNotationCode(Object? rawCode) {
  if (rawCode == null) {
    throw const FormatException('발음 표기 방식 code가 없습니다.');
  }

  final code = rawCode.toString();
  for (final notation in PronunciationNotation.values) {
    if (notation.code == code) {
      return notation;
    }
  }

  throw FormatException('지원하지 않는 발음 표기 방식 code입니다: $code');
}

final class PronunciationValue {
  const PronunciationValue({
    required this.text,
    required this.notation,
    this.notationName,
  });

  final String text;
  final PronunciationNotation notation;
  final String? notationName;

  String get formattedText => formatPronunciation(this);

  String get notationLabel =>
      formatPronunciationNotationLabel(notation, notationName: notationName);

  @override
  bool operator ==(Object other) {
    return other is PronunciationValue &&
        other.text == text &&
        other.notation == notation &&
        other.notationName == notationName;
  }

  @override
  int get hashCode => Object.hash(text, notation, notationName);
}

PronunciationValue? normalizePronunciationForWrite({
  required String? pronunciation,
  required PronunciationNotation? notation,
  String? notationName,
}) {
  final text = (pronunciation ?? '').trim();
  if (text.isEmpty) {
    return null;
  }

  final resolvedNotation = notation ?? PronunciationNotation.unknown;
  final normalizedText = _normalizePronunciationText(text, resolvedNotation);
  final normalizedName = resolvedNotation == PronunciationNotation.other
      ? _trimToNull(notationName)
      : null;

  return PronunciationValue(
    text: normalizedText,
    notation: resolvedNotation,
    notationName: normalizedName,
  );
}

PronunciationValue? readStoredPronunciation({
  required Object? pronunciation,
  required Object? notationCode,
  required Object? notationName,
}) {
  if (pronunciation == null) {
    if (notationCode != null || notationName != null) {
      throw const FormatException('발음 본문 없이 표기 방식 metadata가 저장되어 있습니다.');
    }
    return null;
  }

  final text = pronunciation.toString().trim();
  if (text.isEmpty) {
    if (notationCode == null && notationName == null) {
      return null;
    }
    throw const FormatException('저장된 발음 본문이 비어 있습니다.');
  }

  final notation = notationCode == null
      ? PronunciationNotation.unknown
      : parsePronunciationNotationCode(notationCode);
  final normalizedName = _readStoredNotationName(
    notation: notation,
    rawName: notationName,
  );
  final normalizedText = _normalizePronunciationText(text, notation);
  if (normalizedText != text) {
    throw const FormatException('저장된 IPA 발음 본문에 outer delimiter가 남아 있습니다.');
  }

  return PronunciationValue(
    text: text,
    notation: notation,
    notationName: normalizedName,
  );
}

String formatPronunciation(PronunciationValue pronunciation) {
  switch (pronunciation.notation) {
    case PronunciationNotation.ipaPhonemic:
      return '/${pronunciation.text}/';
    case PronunciationNotation.ipaPhonetic:
      return '[${pronunciation.text}]';
    case PronunciationNotation.strongDictionary:
    case PronunciationNotation.other:
    case PronunciationNotation.unknown:
      return pronunciation.text;
  }
}

String formatPronunciationNotationLabel(
  PronunciationNotation notation, {
  String? notationName,
}) {
  if (notation != PronunciationNotation.other) {
    return notation.label;
  }

  final name = _trimToNull(notationName);
  return name == null ? notation.label : '${notation.label} — $name';
}

String _normalizePronunciationText(
  String text,
  PronunciationNotation notation,
) {
  switch (notation) {
    case PronunciationNotation.ipaPhonemic:
      return _normalizeIpaText(
        text,
        expectedOpening: '/',
        expectedClosing: '/',
        oppositeOpening: '[',
        oppositeClosing: ']',
        notationLabel: notation.label,
      );
    case PronunciationNotation.ipaPhonetic:
      return _normalizeIpaText(
        text,
        expectedOpening: '[',
        expectedClosing: ']',
        oppositeOpening: '/',
        oppositeClosing: '/',
        notationLabel: notation.label,
      );
    case PronunciationNotation.strongDictionary:
    case PronunciationNotation.other:
    case PronunciationNotation.unknown:
      return text;
  }
}

String _normalizeIpaText(
  String text, {
  required String expectedOpening,
  required String expectedClosing,
  required String oppositeOpening,
  required String oppositeClosing,
  required String notationLabel,
}) {
  final hasExpectedOpening = text.startsWith(expectedOpening);
  final hasExpectedClosing = text.endsWith(expectedClosing);
  final hasOppositeOpening = text.startsWith(oppositeOpening);
  final hasOppositeClosing = text.endsWith(oppositeClosing);

  if (hasOppositeOpening && hasOppositeClosing) {
    throw FormatException('$notationLabel과 outer delimiter가 일치하지 않습니다.');
  }
  if (hasOppositeOpening != hasOppositeClosing) {
    throw const FormatException('불완전한 IPA outer delimiter입니다.');
  }
  if (hasExpectedOpening != hasExpectedClosing) {
    throw const FormatException('불완전한 IPA outer delimiter입니다.');
  }

  final normalized = hasExpectedOpening && hasExpectedClosing
      ? text.substring(1, text.length - 1).trim()
      : text;
  if (normalized.isEmpty) {
    throw const FormatException('발음 본문은 비어 있을 수 없습니다.');
  }
  return normalized;
}

String? _readStoredNotationName({
  required PronunciationNotation notation,
  required Object? rawName,
}) {
  if (notation != PronunciationNotation.other) {
    if (rawName != null) {
      throw const FormatException('기타가 아닌 표기 방식에 체계명이 저장되어 있습니다.');
    }
    return null;
  }

  if (rawName == null) {
    return null;
  }
  final name = rawName.toString().trim();
  if (name.isEmpty) {
    throw const FormatException('저장된 기타 표기 체계명이 비어 있습니다.');
  }
  return name;
}

String? _trimToNull(String? value) {
  final trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}
