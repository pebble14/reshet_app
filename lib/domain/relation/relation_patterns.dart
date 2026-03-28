enum RelationDirection { forward, reverse, neutral }

class RelationPatternText {
  final String shortLabel;
  final String phraseTemplate;
  final String sentenceTemplate;

  const RelationPatternText({
    required this.shortLabel,
    required this.phraseTemplate,
    required this.sentenceTemplate,
  });
}

class RelationPattern {
  final RelationPatternText neutral;
  final RelationPatternText? forward;
  final RelationPatternText? reverse;

  const RelationPattern({required this.neutral, this.forward, this.reverse});

  RelationPatternText resolve(RelationDirection direction) {
    switch (direction) {
      case RelationDirection.forward:
        return forward ?? neutral;
      case RelationDirection.reverse:
        return reverse ?? neutral;
      case RelationDirection.neutral:
        return neutral;
    }
  }
}

class RelationPatterns {
  static const RelationPattern compound = RelationPattern(
    neutral: RelationPatternText(
      shortLabel: '합성',
      phraseTemplate: '{target:with} 합성 관계',
      sentenceTemplate: '{center:with} {target:topic} 합성 관계로 연결된다',
    ),
    forward: RelationPatternText(
      shortLabel: '구성',
      phraseTemplate: '{target:object} 구성하는 요소',
      sentenceTemplate: '{center:topic} {target:object} 이루는 구성 요소이다',
    ),
    reverse: RelationPatternText(
      shortLabel: '합성',
      phraseTemplate: '{target:to} 이루어진 합성어',
      sentenceTemplate: '{center:topic} {target:object} 포함하는 합성어이다',
    ),
  );

  static const RelationPattern related = RelationPattern(
    neutral: RelationPatternText(
      shortLabel: '관련',
      phraseTemplate: '{target:with} 관련',
      sentenceTemplate: '{center:with} {target:topic} 의미적으로 관련이 있다',
    ),
    forward: RelationPatternText(
      shortLabel: '관련',
      phraseTemplate: '{target:with} 관련',
      sentenceTemplate: '{center:with} {target:topic} 의미적으로 관련이 있다',
    ),
    reverse: RelationPatternText(
      shortLabel: '관련',
      phraseTemplate: '{target:with} 관련',
      sentenceTemplate: '{center:with} {target:topic} 의미적으로 관련이 있다',
    ),
  );

  static const RelationPattern rootRelated = RelationPattern(
    neutral: RelationPatternText(
      shortLabel: '어근',
      phraseTemplate: '{target:with} 어근 관련',
      sentenceTemplate: '{center:with} {target:topic} 어근상 관련이 있다',
    ),
    forward: RelationPatternText(
      shortLabel: '어근',
      phraseTemplate: '{target:with} 같은 어근',
      sentenceTemplate: '{center:topic} {target:with} 같은 어근을 가진다',
    ),
    reverse: RelationPatternText(
      shortLabel: '어근',
      phraseTemplate: '{target}에서 파생',
      sentenceTemplate: '{center:topic} {target}에서 파생된 어근 관련 표현이다',
    ),
  );

  static const RelationPattern variant = RelationPattern(
    neutral: RelationPatternText(
      shortLabel: '변이',
      phraseTemplate: '{target:with} 형태 변이',
      sentenceTemplate: '{center:with} {target:topic} 서로 다른 형태로 나타나는 변이 관계이다',
    ),
    forward: RelationPatternText(
      shortLabel: '변이',
      phraseTemplate: '{target:with} 형태 변이',
      sentenceTemplate: '{center:with} {target:topic} 서로 다른 형태로 나타나는 변이 관계이다',
    ),
    reverse: RelationPatternText(
      shortLabel: '변이',
      phraseTemplate: '{target:with} 형태 변이',
      sentenceTemplate: '{center:with} {target:topic} 서로 다른 형태로 나타나는 변이 관계이다',
    ),
  );

  static const RelationPattern approxTransliteration = RelationPattern(
    neutral: RelationPatternText(
      shortLabel: '근사음역',
      phraseTemplate: '{target:with} 근사 음역 관계',
      sentenceTemplate: '{center:with} {target:topic} 근사 음역 관계이다',
    ),
    forward: RelationPatternText(
      shortLabel: '근사음역',
      phraseTemplate: '{target:to} 근사 음역됨',
      sentenceTemplate: '{center:topic} {target:to} 가깝게 음역된다',
    ),
    reverse: RelationPatternText(
      shortLabel: '근사음역',
      phraseTemplate: '{target}의 근사 음역',
      sentenceTemplate: '{center:topic} {target:object} 가깝게 옮긴 음역 표현이다',
    ),
  );

  static const RelationPattern conventionalTransliteration = RelationPattern(
    neutral: RelationPatternText(
      shortLabel: '관용음역',
      phraseTemplate: '{target:with} 관용 음역 관계',
      sentenceTemplate: '{center:with} {target:topic} 관용 음역 관계이다',
    ),
    forward: RelationPatternText(
      shortLabel: '관용음역',
      phraseTemplate: '{target:to} 관용 음역됨',
      sentenceTemplate: '{center:topic} {target:to} 관용적으로 음역된다',
    ),
    reverse: RelationPatternText(
      shortLabel: '관용음역',
      phraseTemplate: '{target}의 관용 음역',
      sentenceTemplate: '{center:topic} {target}의 관용적 음역 표현이다',
    ),
  );

  static const RelationPattern directTransliteration = RelationPattern(
    neutral: RelationPatternText(
      shortLabel: '직음역',
      phraseTemplate: '{target:with} 직접 음역 관계',
      sentenceTemplate: '{center:with} {target:topic} 직접 음역 관계이다',
    ),
    forward: RelationPatternText(
      shortLabel: '직음역',
      phraseTemplate: '{target:to} 직접 음역됨',
      sentenceTemplate: '{center:topic} {target:to} 직접 음역된다',
    ),
    reverse: RelationPatternText(
      shortLabel: '직음역',
      phraseTemplate: '{target}의 직접 음역',
      sentenceTemplate: '{center:topic} {target:object} 직접 음역한 표현이다',
    ),
  );

  static const Map<String, RelationPattern> _patterns = {
    'compound': compound,
    'related': related,
    'root-related': rootRelated,
    'variant': variant,
    'approx_transliteration': approxTransliteration,
    'conventional_transliteration': conventionalTransliteration,
    'direct_transliteration': directTransliteration,
  };

  static RelationPattern? lookup(String? relationType) {
    final normalized = (relationType ?? '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    return _patterns[normalized];
  }
}
