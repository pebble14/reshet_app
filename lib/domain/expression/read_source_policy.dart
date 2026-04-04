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

enum ReadFallbackReason {
  queryFailed,
  emptyResult,
  mappingInvalid,
  minimumExpressionNotMet;

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
  final CanonicalExpressionReadResult readResult;
  final ReadFallbackObservation? fallbackObservation;

  const WordExpressionReadSnapshot({
    required this.wordId,
    required this.context,
    required this.requestedPolicy,
    required this.resolvedSource,
    required this.readResult,
    this.fallbackObservation,
  });

  bool get didFallback => fallbackObservation != null;
}
