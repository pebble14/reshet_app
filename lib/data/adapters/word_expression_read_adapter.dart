import '../../domain/expression/expression_read_models.dart';
import '../../domain/expression/read_source_policy.dart';
import 'legacy_word_expression_read_adapter.dart';

CanonicalExpressionReadResult readWordExpressionFromWordMap(
  Map<String, dynamic> wordMap,
) {
  return readLegacyWordExpressionRow(wordMap);
}

CanonicalExpressionReadResult readWordExpressionFromSnapshot(
  WordExpressionReadSnapshot snapshot,
) {
  return snapshot.readResult;
}

ReadFallbackObservation? readFallbackObservationFromSnapshot(
  WordExpressionReadSnapshot snapshot,
) {
  return snapshot.fallbackObservation;
}
