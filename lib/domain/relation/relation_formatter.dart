import 'relation_patterns.dart';

export 'relation_patterns.dart' show RelationDirection;

class RelationText {
  final String shortLabel;
  final String phrase;
  final String sentence;

  const RelationText({
    required this.shortLabel,
    required this.phrase,
    required this.sentence,
  });
}

class RelationFormatter {
  static const RelationPattern _nullRelationPattern = RelationPattern(
    neutral: RelationPatternText(
      shortLabel: '관계',
      phraseTemplate: '{target:with_of} 관계',
      sentenceTemplate: '{center:with} {target} 사이의 관계이다',
    ),
  );

  static const RelationPattern _unknownRelationPattern = RelationPattern(
    neutral: RelationPatternText(
      shortLabel: '관계',
      phraseTemplate: '{target:with_of} 관계',
      sentenceTemplate: '{center:with} {target} 사이에 정의되지 않은 관계가 있다',
    ),
  );

  static const RelationText _selfReferenceText = RelationText(
    shortLabel: '',
    phrase: '(자기 참조)',
    sentence: '(자기 참조)',
  );

  static RelationText format({
    required String? relationType,
    required RelationDirection direction,
    required String centerWord,
    required String targetWord,
  }) {
    if (_isSelfReference(centerWord: centerWord, targetWord: targetWord)) {
      return _selfReferenceText;
    }

    final pattern = _patternFor(relationType);
    final template = pattern.resolve(direction);

    return RelationText(
      shortLabel: template.shortLabel.trim(),
      phrase: _bindTemplate(
        template.phraseTemplate,
        centerWord: centerWord,
        targetWord: targetWord,
      ),
      sentence: _bindTemplate(
        template.sentenceTemplate,
        centerWord: centerWord,
        targetWord: targetWord,
      ),
    );
  }

  static RelationText formatForPair({
    required String? relationType,
    required String directionCode,
    required String wordId1,
    required String wordId2,
    required String centerWordId,
    required String centerWord,
    required String targetWord,
  }) {
    if (_isSelfReference(
      centerWord: centerWord,
      targetWord: targetWord,
      wordId1: wordId1,
      wordId2: wordId2,
    )) {
      return _selfReferenceText;
    }

    return format(
      relationType: relationType,
      direction: resolveDirectionForPair(
        directionCode: directionCode,
        wordId1: wordId1,
        wordId2: wordId2,
        centerWordId: centerWordId,
      ),
      centerWord: centerWord,
      targetWord: targetWord,
    );
  }

  static RelationDirection resolveDirectionForPair({
    required String directionCode,
    required String wordId1,
    required String wordId2,
    required String centerWordId,
  }) {
    final normalizedDirectionCode = normalizeDirectionCode(directionCode);
    final normalizedCenterWordId = centerWordId.trim();
    final normalizedWordId1 = wordId1.trim();
    final normalizedWordId2 = wordId2.trim();

    switch (normalizedDirectionCode) {
      case 'w1_to_w2':
        if (normalizedCenterWordId == normalizedWordId1) {
          return RelationDirection.forward;
        }
        if (normalizedCenterWordId == normalizedWordId2) {
          return RelationDirection.reverse;
        }
        return RelationDirection.neutral;
      case 'w2_to_w1':
        if (normalizedCenterWordId == normalizedWordId2) {
          return RelationDirection.forward;
        }
        if (normalizedCenterWordId == normalizedWordId1) {
          return RelationDirection.reverse;
        }
        return RelationDirection.neutral;
      case 'unknown':
      case 'undirected':
        return RelationDirection.neutral;
      default:
        return RelationDirection.neutral;
    }
  }

  static String normalizeDirectionCode(String? directionCode) {
    switch ((directionCode ?? '').trim()) {
      case 'w1_to_w2':
      case 'w2_to_w1':
      case 'unknown':
      case 'undirected':
        return (directionCode ?? '').trim();
      default:
        return 'unknown';
    }
  }

  static RelationPattern _patternFor(String? relationType) {
    final normalizedRelationType = (relationType ?? '').trim();
    if (normalizedRelationType.isEmpty) {
      return _nullRelationPattern;
    }

    return RelationPatterns.lookup(normalizedRelationType) ??
        _unknownRelationPattern;
  }

  static String _bindTemplate(
    String template, {
    required String centerWord,
    required String targetWord,
  }) {
    final normalizedCenterWord = centerWord.trim();
    final normalizedTargetWord = targetWord.trim();
    final placeholderPattern = RegExp(r'\{(center|target)(?::([a-z_]+))?\}');

    return template.replaceAllMapped(placeholderPattern, (match) {
      final key = match.group(1);
      final role = match.group(2);
      final word = key == 'center'
          ? normalizedCenterWord
          : normalizedTargetWord;
      if (role == null || role.isEmpty) {
        return word;
      }

      return _applyParticle(word, role);
    });
  }

  static bool _isSelfReference({
    required String centerWord,
    required String targetWord,
    String? wordId1,
    String? wordId2,
  }) {
    final normalizedCenterWord = centerWord.trim();
    final normalizedTargetWord = targetWord.trim();
    final normalizedWordId1 = (wordId1 ?? '').trim();
    final normalizedWordId2 = (wordId2 ?? '').trim();

    if (normalizedWordId1.isNotEmpty &&
        normalizedWordId1 == normalizedWordId2) {
      return true;
    }

    return normalizedCenterWord.isNotEmpty &&
        normalizedCenterWord == normalizedTargetWord;
  }

  static String _applyParticle(String word, String role) {
    final normalizedWord = word.trim();
    if (normalizedWord.isEmpty) {
      return word;
    }

    switch (role) {
      case 'topic':
        return '$normalizedWord${_topicParticle(normalizedWord)}';
      case 'object':
        return '$normalizedWord${_objectParticle(normalizedWord)}';
      case 'with':
        return '$normalizedWord${_withParticle(normalizedWord)}';
      case 'with_of':
        return '$normalizedWord${_withOfParticle(normalizedWord)}';
      case 'to':
        return '$normalizedWord${_toParticle(normalizedWord)}';
      default:
        return normalizedWord;
    }
  }

  static String _topicParticle(String word) {
    return _hasFinalConsonant(word) ? '은' : '는';
  }

  static String _objectParticle(String word) {
    return _hasFinalConsonant(word) ? '을' : '를';
  }

  static String _withParticle(String word) {
    return _hasFinalConsonant(word) ? '과' : '와';
  }

  static String _withOfParticle(String word) {
    return _hasFinalConsonant(word) ? '과의' : '와의';
  }

  static String _toParticle(String word) {
    final finalConsonantIndex = _finalConsonantIndex(word);
    if (finalConsonantIndex == null) {
      return '로';
    }
    if (finalConsonantIndex == 0 || finalConsonantIndex == 8) {
      return '로';
    }
    return '으로';
  }

  static bool _hasFinalConsonant(String word) {
    final finalConsonantIndex = _finalConsonantIndex(word);
    if (finalConsonantIndex == null) {
      return false;
    }
    return finalConsonantIndex != 0;
  }

  static int? _finalConsonantIndex(String word) {
    if (word.isEmpty) {
      return null;
    }

    for (var index = word.length - 1; index >= 0; index--) {
      final codeUnit = word.codeUnitAt(index);
      if (_isHangulSyllable(codeUnit)) {
        return (codeUnit - 0xAC00) % 28;
      }
      if (_isAsciiAlphaNumeric(codeUnit)) {
        return null;
      }
    }

    return null;
  }

  static bool _isHangulSyllable(int codeUnit) {
    return codeUnit >= 0xAC00 && codeUnit <= 0xD7A3;
  }

  static bool _isAsciiAlphaNumeric(int codeUnit) {
    return (codeUnit >= 0x30 && codeUnit <= 0x39) ||
        (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
        (codeUnit >= 0x61 && codeUnit <= 0x7A);
  }
}
