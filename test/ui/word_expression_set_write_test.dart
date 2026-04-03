import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/domain/expression/expression_read_models.dart';
import 'package:reshet_app/domain/word/word_write_models.dart';
import 'package:reshet_app/ui/word_expression_set.dart';

void main() {
  group('canonicalizeExpressionSetDrafts', () {
    test('drops issue-only drafts and reassigns representative to seq 1', () {
      final result = canonicalizeExpressionSetDrafts([
        const WordExpressionSetDraft(
          spelling: '',
          transliteration: 'draft-only',
          pronunciation: '',
        ),
        const WordExpressionSetDraft(
          spelling: 'beta',
          transliteration: '베타',
          pronunciation: '',
        ),
        const WordExpressionSetDraft(
          spelling: 'gamma',
          transliteration: '',
          pronunciation: 'ga-ma',
        ),
      ]);

      expect(result.expressionSets, hasLength(2));
      expect(result.expressionSets[0].spelling, 'beta');
      expect(result.expressionSets[0].seq, 1);
      expect(result.expressionSets[0].isRepresentative, isTrue);
      expect(result.expressionSets[1].spelling, 'gamma');
      expect(result.expressionSets[1].seq, 2);
      expect(result.expressionSets[1].isRepresentative, isFalse);
      expect(result.exclusionIssues, hasLength(1));
      expect(
        result.exclusionIssues.single.sourceKind,
        WordWriteExclusionSourceKind.draft,
      );
      expect(result.exclusionIssues.single.sourceIndex, 1);
      expect(result.exclusionIssues.single.rawTransliteration, 'draft-only');
    });

    test('preserves legacy hidden-slot cleanup issues in the write result', () {
      final legacyIssues =
          buildLegacyHiddenSlotWriteExclusionIssuesFromReadResult(
            const CanonicalExpressionReadResult(
              issues: [
                ExpressionSetIssue(
                  issueCode: 'supplemental_without_spelling',
                  sourceSlot: 4,
                  rawSpelling: null,
                  rawTransliteration: 'legacy-only',
                  rawPronunciation: null,
                  resolution: 'manual_cleanup_required',
                ),
              ],
            ),
          );

      final result = canonicalizeExpressionSetDrafts(const [
        WordExpressionSetDraft(
          spelling: 'kept',
          transliteration: '유지',
          pronunciation: '',
        ),
      ], legacyHiddenSlotIssues: legacyIssues);

      expect(result.expressionSets, hasLength(1));
      expect(result.exclusionIssues, hasLength(1));
      expect(
        result.exclusionIssues.single.sourceKind,
        WordWriteExclusionSourceKind.legacyHiddenSlot,
      );
      expect(result.exclusionIssues.single.sourceIndex, 4);
      expect(result.exclusionIssues.single.rawTransliteration, 'legacy-only');
    });
  });

  testWidgets(
    'showWordWriteExclusionDialog renders draft and legacy sections',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    showWordWriteExclusionDialog(context, const [
                      WordWriteExclusionIssue(
                        issueCode: supplementalWithoutSpellingWriteIssueCode,
                        sourceKind: WordWriteExclusionSourceKind.draft,
                        sourceIndex: 2,
                        rawSpelling: null,
                        rawTransliteration: 'draft-only',
                        rawPronunciation: null,
                        resolution: excludedFromWriteResolution,
                      ),
                      WordWriteExclusionIssue(
                        issueCode: supplementalWithoutSpellingWriteIssueCode,
                        sourceKind:
                            WordWriteExclusionSourceKind.legacyHiddenSlot,
                        sourceIndex: 5,
                        rawSpelling: null,
                        rawTransliteration: null,
                        rawPronunciation: 'legacy-only',
                        resolution: excludedFromWriteResolution,
                      ),
                    ]);
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('저장 제외 항목 확인'), findsOneWidget);
      expect(find.text('이번 입력에서 제외될 세트'), findsOneWidget);
      expect(find.text('기존 데이터에서 함께 정리될 숨김 슬롯'), findsOneWidget);
      expect(find.textContaining('세트 2'), findsOneWidget);
      expect(find.textContaining('숨김 슬롯 5'), findsOneWidget);
      expect(find.text('제외하고 저장'), findsOneWidget);
    },
  );
}
