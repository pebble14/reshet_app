import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/domain/expression/expression_read_models.dart';
import 'package:reshet_app/domain/expression/pronunciation_notation.dart';
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

    test('preserves seven or more expression sets during canonicalization', () {
      final result = canonicalizeExpressionSetDrafts(
        List<WordExpressionSetDraft>.generate(
          7,
          (index) => WordExpressionSetDraft(
            spelling: 'phase33_spelling_${index + 1}',
            transliteration: 'phase33_trans_${index + 1}',
            pronunciation: 'phase33_pron_${index + 1}',
          ),
          growable: false,
        ),
      );

      expect(result.expressionSets, hasLength(7));
      for (var index = 0; index < result.expressionSets.length; index++) {
        final set = result.expressionSets[index];
        expect(set.seq, index + 1);
        expect(set.spelling, 'phase33_spelling_${index + 1}');
        expect(set.transliteration, 'phase33_trans_${index + 1}');
        expect(set.pronunciation, 'phase33_pron_${index + 1}');
        expect(set.isRepresentative, index == 0);
      }
    });
  });

  test('canonicalization normalizes IPA and keeps notation metadata', () {
    final result = canonicalizeExpressionSetDrafts(const [
      WordExpressionSetDraft(
        spelling: 'ahava',
        transliteration: '',
        pronunciation: '/ʔa.haˈva/',
        pronunciationNotation: PronunciationNotation.ipaPhonemic,
      ),
    ]);

    expect(result.expressionSets.single.pronunciation, 'ʔa.haˈva');
    expect(
      result.expressionSets.single.pronunciationNotation,
      PronunciationNotation.ipaPhonemic,
    );
    expect(result.expressionSets.single.pronunciationNotationName, isNull);
  });

  test('validation rejects opposite and incomplete IPA delimiters', () {
    final result = validateExpressionSetDrafts(const [
      WordExpressionSetDraft(
        spelling: 'opposite',
        transliteration: '',
        pronunciation: '[a]',
        pronunciationNotation: PronunciationNotation.ipaPhonemic,
      ),
      WordExpressionSetDraft(
        spelling: 'incomplete',
        transliteration: '',
        pronunciation: '[b',
        pronunciationNotation: PronunciationNotation.ipaPhonetic,
      ),
    ]);

    expect(result.errors, hasLength(2));
    expect(result.errors.map((issue) => issue.setIndex), [1, 2]);
  });

  test('controller defaults, clears, and seeds pronunciation metadata', () {
    final group = WordExpressionSetControllerGroup(
      spelling: 'seed',
      pronunciation: 'seed-pronunciation',
      pronunciationNotation: PronunciationNotation.other,
      pronunciationNotationName: '학술 관례',
    );
    try {
      expect(group.pronunciationNotation, PronunciationNotation.other);
      expect(group.pronunciationNotationNameController.text, '학술 관례');

      group.updatePronunciationNotation(PronunciationNotation.ipaPhonetic);
      expect(group.pronunciationNotationNameController.text, isEmpty);

      group.handlePronunciationChanged('');
      expect(group.pronunciationNotation, isNull);
      expect(group.pronunciationNotationNameController.text, isEmpty);

      group.handlePronunciationChanged('new pronunciation');
      expect(group.pronunciationNotation, PronunciationNotation.unknown);
    } finally {
      group.dispose();
    }
  });

  testWidgets(
    'common expression section exposes notation and optional other name',
    (tester) async {
      final group = WordExpressionSetControllerGroup(
        spelling: 'other notation',
        pronunciation: 'pronunciation',
        pronunciationNotation: PronunciationNotation.other,
      );
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WordExpressionSetSection(
                  controllerGroups: [group],
                  enabled: true,
                  onAddSet: () {},
                  onMakeRepresentative: (_) {},
                  onRemoveSet: (_) {},
                  onChanged: () {},
                  onSetFocusLost: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('발음 표기'), findsOneWidget);
        expect(find.text('표기 방식'), findsOneWidget);
        expect(find.text('기타 표기 체계명 (선택)'), findsOneWidget);
      } finally {
        group.dispose();
      }
    },
  );

  test('validateExpressionSetDrafts checks drafts after the sixth set', () {
    final drafts = List<WordExpressionSetDraft>.generate(
      7,
      (index) => WordExpressionSetDraft(
        spelling: index == 6 ? '' : 'phase33_spelling_${index + 1}',
        transliteration: index == 6 ? 'phase33_trans_7' : '',
        pronunciation: '',
      ),
      growable: false,
    );

    final result = validateExpressionSetDrafts(drafts);

    expect(result.hasErrors, isFalse);
    expect(result.warnings, hasLength(1));
    expect(result.warnings.single.setIndex, 7);
  });

  testWidgets('WordExpressionSetSection does not disable add after six sets', (
    tester,
  ) async {
    var addCount = 0;
    final groups = List<WordExpressionSetControllerGroup>.generate(
      6,
      (index) => WordExpressionSetControllerGroup(
        spelling: 'phase33_spelling_${index + 1}',
      ),
      growable: false,
    );

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WordExpressionSetSection(
                controllerGroups: groups,
                enabled: true,
                onAddSet: () => addCount += 1,
                onMakeRepresentative: (_) {},
                onRemoveSet: (_) {},
                onChanged: () {},
                onSetFocusLost: (_) {},
              ),
            ),
          ),
        ),
      );

      final addButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '+ 세트 추가'),
      );
      expect(addButton.onPressed, isNotNull);
      addButton.onPressed!();

      expect(addCount, 1);
    } finally {
      for (final group in groups) {
        group.dispose();
      }
    }
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
