import 'expression_read_models.dart';

enum ReadSourcePolicy {
  legacy,
  normalizedWithFallback,
  normalizedOnly;

  String get code {
    switch (this) {
      case ReadSourcePolicy.legacy:
        return 'LEGACY';
      case ReadSourcePolicy.normalizedWithFallback:
        return 'NORMALIZED_WITH_FALLBACK';
      case ReadSourcePolicy.normalizedOnly:
        return 'NORMALIZED_ONLY';
    }
  }
}

enum ResolvedReadSource { legacy, normalized }

enum FinalReadResultSource {
  legacy,
  normalized,
  legacyFallback,
  normalizedFailure;

  String get code {
    switch (this) {
      case FinalReadResultSource.legacy:
        return 'legacy';
      case FinalReadResultSource.normalized:
        return 'normalized';
      case FinalReadResultSource.legacyFallback:
        return 'legacy_fallback';
      case FinalReadResultSource.normalizedFailure:
        return 'normalized_failure';
    }
  }
}

enum ReadFallbackReason {
  queryFailed,
  emptyResult,
  mappingInvalid,
  minimumExpressionNotMet,
  userVisibleDisplayMismatch;

  String get code {
    switch (this) {
      case ReadFallbackReason.queryFailed:
        return 'query_failed';
      case ReadFallbackReason.emptyResult:
        return 'empty_result';
      case ReadFallbackReason.mappingInvalid:
        return 'mapping_invalid';
      case ReadFallbackReason.minimumExpressionNotMet:
        return 'minimum_expression_not_met';
      case ReadFallbackReason.userVisibleDisplayMismatch:
        return 'user_visible_display_mismatch';
    }
  }
}

class ReadFallbackObservation {
  final String wordId;
  final ReadSourcePolicy policy;
  final ReadFallbackReason reason;
  final String context;
  final String? detail;

  const ReadFallbackObservation({
    required this.wordId,
    required this.policy,
    required this.reason,
    required this.context,
    this.detail,
  });
}

class WordExpressionReadSnapshot {
  final String wordId;
  final String context;
  final ReadSourcePolicy requestedPolicy;
  final ResolvedReadSource resolvedSource;
  final FinalReadResultSource finalResultSource;
  final CanonicalExpressionReadResult readResult;
  final CanonicalExpressionReadResult? legacyReadResult;
  final CanonicalExpressionReadResult? normalizedReadResult;
  final ReadFallbackObservation? fallbackObservation;

  const WordExpressionReadSnapshot({
    required this.wordId,
    required this.context,
    required this.requestedPolicy,
    required this.resolvedSource,
    required this.finalResultSource,
    required this.readResult,
    this.legacyReadResult,
    this.normalizedReadResult,
    this.fallbackObservation,
  });

  bool get didFallback => fallbackObservation != null;

  bool get legacyResultAvailable => legacyReadResult != null;

  bool get normalizedResultAvailable => normalizedReadResult != null;

  WordExpressionReadSnapshot copyWith({
    String? wordId,
    String? context,
    ReadSourcePolicy? requestedPolicy,
    ResolvedReadSource? resolvedSource,
    FinalReadResultSource? finalResultSource,
    CanonicalExpressionReadResult? readResult,
    CanonicalExpressionReadResult? legacyReadResult,
    CanonicalExpressionReadResult? normalizedReadResult,
    ReadFallbackObservation? fallbackObservation,
    bool keepFallbackObservation = true,
    bool keepLegacyReadResult = true,
    bool keepNormalizedReadResult = true,
  }) {
    return WordExpressionReadSnapshot(
      wordId: wordId ?? this.wordId,
      context: context ?? this.context,
      requestedPolicy: requestedPolicy ?? this.requestedPolicy,
      resolvedSource: resolvedSource ?? this.resolvedSource,
      finalResultSource: finalResultSource ?? this.finalResultSource,
      readResult: readResult ?? this.readResult,
      legacyReadResult: keepLegacyReadResult
          ? legacyReadResult ?? this.legacyReadResult
          : legacyReadResult,
      normalizedReadResult: keepNormalizedReadResult
          ? normalizedReadResult ?? this.normalizedReadResult
          : normalizedReadResult,
      fallbackObservation: keepFallbackObservation
          ? fallbackObservation ?? this.fallbackObservation
          : fallbackObservation,
    );
  }
}
