import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/domain/expression/home_word_display_summary.dart';

void main() {
  group('buildHomeWordDisplaySummary', () {
    test('uses the representative canonical set when expressions exist', () {
      final summary = buildHomeWordDisplaySummary({
        'id': 'E0000_0010',
        '표기1': 'Eva',
        '표기2': 'Eve',
        '음역1': '이바',
        '음역2': '이브',
        '발음1': 'iːvə',
        '발음2': 'iːv',
      });

      expect(summary.representativeSpelling, 'Eva');
      expect(summary.representativeTransliteration, '이바');
      expect(summary.representativePronunciation, 'iːvə');
    });

    test(
      'uses the emergency fallback only for spelling when canonical sets are empty',
      () {
        final summary = buildHomeWordDisplaySummary({
          'id': 'X0000_EMPTY',
          '표기1': '',
          '표기2': '',
          '음역1': 'issue-only',
          '발음1': 'issue-only',
        });

        expect(summary.representativeSpelling, '');
        expect(summary.representativeTransliteration, '');
        expect(summary.representativePronunciation, '');
      },
    );

    test(
      'ignores issue-only slots when building the representative summary',
      () {
        final summary = buildHomeWordDisplaySummary({
          'id': 'G0185_0000',
          '표기1': 'ἀγριος',
          '음역1': '아그리오스',
          '발음1': 'ak-er-ah-yos',
          '표기2': '',
          '음역2': '',
          '발음2': 'G2767',
        });

        expect(summary.representativeSpelling, 'ἀγριος');
        expect(summary.representativeTransliteration, '아그리오스');
        expect(summary.representativePronunciation, 'ak-er-ah-yos');
        expect(summary.representativePronunciation, isNot('G2767'));
      },
    );
  });

  group('title builders', () {
    test('buildStrongListTitle joins only non-empty segments', () {
      final title = buildStrongListTitle(
        strong: 'G4572',
        summary: const HomeWordDisplaySummary(representativeSpelling: 'agrios'),
      );

      expect(title, 'G4572 · agrios');
    });

    test('buildSearchResultTitle omits empty transliteration segments', () {
      final title = buildSearchResultTitle(
        strong: 'E76',
        summary: const HomeWordDisplaySummary(
          representativeSpelling: 'hippopotamus',
          representativePronunciation: '|hɪpə|pɒtəməs',
        ),
      );

      expect(title, 'E76 · hippopotamus · |hɪpə|pɒtəməs');
      expect(title, isNot(contains('·  ·')));
    });

    test('buildSearchResultTitle omits issue-only fallback values', () {
      final title = buildSearchResultTitle(
        strong: 'H24',
        summary: const HomeWordDisplaySummary(),
      );

      expect(title, 'H24');
    });
  });
}
