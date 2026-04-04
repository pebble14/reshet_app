import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/domain/expression/expression_read_models.dart';
import 'package:reshet_app/domain/expression/read_source_debug_collector.dart';
import 'package:reshet_app/domain/expression/read_source_policy.dart';

void main() {
  group('ReadSourceDebugCollector', () {
    setUp(() {
      ReadSourceDebugCollector.instance.debugReset();
    });

    test(
      'keeps only the most recent 200 raw events while summary totals remain cumulative',
      () {
        final collector = ReadSourceDebugCollector.instance;

        for (var index = 1; index <= 205; index++) {
          collector.record(
            _buildSnapshot(
              wordId: 'W_RING',
              context: 'ring-buffer-test',
              finalResultSource: FinalReadResultSource.normalized,
            ),
          );
        }

        final summary = collector.summaryForWord('W_RING');
        final recentEvents = collector.recentEvents(limit: 300);
        final recentSnapshots = collector.debugRecentSnapshots(limit: 300);

        expect(summary, isNotNull);
        expect(summary!.totalEvents, 205);
        expect(summary.normalizedSuccessEvents, 205);
        expect(summary.fallbackEvents, 0);
        expect(recentEvents, hasLength(200));
        expect(recentSnapshots, hasLength(200));
        expect(recentEvents.first.sequence, 205);
        expect(recentEvents.last.sequence, 6);
      },
    );

    test('formats word summaries, reason summaries, and recent raw events', () {
      final collector = ReadSourceDebugCollector.instance;

      collector.record(
        _buildSnapshot(
          wordId: 'W_NORMALIZED',
          context: 'detail',
          finalResultSource: FinalReadResultSource.normalized,
        ),
      );
      collector.record(
        _buildSnapshot(
          wordId: 'W_EMPTY',
          context: 'detail',
          finalResultSource: FinalReadResultSource.legacyFallback,
          resolvedSource: ResolvedReadSource.legacy,
          fallbackReason: ReadFallbackReason.emptyResult,
          fallbackDetail: 'normalized rows are empty',
          includeNormalizedResult: false,
        ),
      );
      collector.record(
        _buildSnapshot(
          wordId: 'W_MISMATCH',
          context: 'detail',
          finalResultSource: FinalReadResultSource.legacyFallback,
          resolvedSource: ResolvedReadSource.legacy,
          fallbackReason: ReadFallbackReason.userVisibleDisplayMismatch,
          fallbackDetail: 'display fields mismatch: representative_spelling',
        ),
      );

      final wordLines = collector.formatWordSummaryLines();
      final reasonLines = collector.formatReasonSummaryLines();
      final eventLines = collector.formatRecentEventLines(limit: 5);

      expect(wordLines.join('\n'), contains('[read-summary:word]'));
      expect(wordLines.join('\n'), contains('wordId=W_EMPTY'));
      expect(reasonLines.join('\n'), contains('reason=empty_result'));
      expect(
        reasonLines.join('\n'),
        contains('reason=user_visible_display_mismatch'),
      );
      expect(eventLines.first, contains('[read-event]'));
      expect(eventLines.first, contains('wordId=W_MISMATCH'));
      expect(
        eventLines.first,
        contains('reason=user_visible_display_mismatch'),
      );
    });
  });
}

WordExpressionReadSnapshot _buildSnapshot({
  required String wordId,
  required String context,
  required FinalReadResultSource finalResultSource,
  ResolvedReadSource? resolvedSource,
  ReadFallbackReason? fallbackReason,
  String? fallbackDetail,
  bool includeLegacyResult = true,
  bool includeNormalizedResult = true,
}) {
  final legacyResult = includeLegacyResult
      ? CanonicalExpressionReadResult(
          sets: const [
            ExpressionSet(
              spelling: 'legacy',
              transliteration: 'legacy',
              pronunciation: 'legacy',
              seq: 1,
              isRepresentative: true,
            ),
          ],
        )
      : null;
  final normalizedResult = includeNormalizedResult
      ? CanonicalExpressionReadResult(
          sets: const [
            ExpressionSet(
              spelling: 'normalized',
              transliteration: 'normalized',
              pronunciation: 'normalized',
              seq: 1,
              isRepresentative: true,
            ),
          ],
        )
      : null;

  return WordExpressionReadSnapshot(
    wordId: wordId,
    context: context,
    requestedPolicy: ReadSourcePolicy.normalizedWithFallback,
    resolvedSource:
        resolvedSource ??
        (fallbackReason == null
            ? ResolvedReadSource.normalized
            : ResolvedReadSource.legacy),
    finalResultSource: finalResultSource,
    readResult: switch (finalResultSource) {
      FinalReadResultSource.legacy =>
        legacyResult ?? const CanonicalExpressionReadResult(),
      FinalReadResultSource.normalized =>
        normalizedResult ?? const CanonicalExpressionReadResult(),
      FinalReadResultSource.legacyFallback =>
        legacyResult ?? const CanonicalExpressionReadResult(),
      FinalReadResultSource.normalizedFailure =>
        const CanonicalExpressionReadResult(),
    },
    legacyReadResult: legacyResult,
    normalizedReadResult: normalizedResult,
    fallbackObservation: fallbackReason == null
        ? null
        : ReadFallbackObservation(
            wordId: wordId,
            policy: ReadSourcePolicy.normalizedWithFallback,
            reason: fallbackReason,
            context: context,
            detail: fallbackDetail,
          ),
  );
}
