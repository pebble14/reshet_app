import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/domain/graph/graph_center_word_display_item.dart';
import 'package:reshet_app/domain/word/word_detail_like_display_item.dart';
import 'package:reshet_app/ui/word_explorer_screen.dart';

void main() {
  group('Phase 8-H-16 explorer bootstrap center display contract', () {
    test(
      'keeps graph center typed display semantics ahead of split-view fallback',
      () {
        const centerDisplayItem = GraphCenterWordDisplayItem(
          wordId: 'T9000_H16_EXPLORER_BOOTSTRAP_CENTER',
          language: 'test',
          displayStrongNumber: 'H82',
          representativeSpelling: 'phase8h16-center-spelling',
          representativeTransliteration: 'phase8h16-center-translit',
          representativePronunciation: 'phase8h16-center-pron',
          primaryMeaning: 'phase8h16-center-meaning',
        );
        const selectedDisplayItem = WordDetailLikeDisplayItem(
          representativeSpelling: 'split-view-fallback-spelling',
          displayStrongNumber: 'h00099',
          transliterations: <String>['split-view-fallback-translit'],
        );

        final tooltipDisplay =
            resolveExplorerBootstrapCenterTooltipDisplayForTesting(
              wordId: centerDisplayItem.wordId,
              centerDisplayItem: centerDisplayItem,
              selectedDisplayItem: selectedDisplayItem,
            );

        expect(tooltipDisplay.wordId, 'T9000_H16_EXPLORER_BOOTSTRAP_CENTER');
        expect(
          tooltipDisplay.representativeSpelling,
          'phase8h16-center-spelling',
        );
        expect(tooltipDisplay.displayStrongNumber, 'H82');
        expect(
          tooltipDisplay.representativeTransliteration,
          'phase8h16-center-translit',
        );
      },
    );

    test('preserves split-view fallback and id-only fallback ordering', () {
      const selectedDisplayItem = WordDetailLikeDisplayItem(
        representativeSpelling: 'phase8h16-split-fallback-spelling',
        displayStrongNumber: 'h00083',
        transliterations: <String>['phase8h16-split-fallback-translit'],
      );

      final splitViewFallback =
          resolveExplorerBootstrapCenterTooltipDisplayForTesting(
            wordId: 'T9000_H16_EXPLORER_SPLIT_FALLBACK',
            centerDisplayItem: null,
            selectedDisplayItem: selectedDisplayItem,
          );
      final idOnlyFallback =
          resolveExplorerBootstrapCenterTooltipDisplayForTesting(
            wordId: 'T9000_H16_EXPLORER_ID_ONLY',
            centerDisplayItem: null,
            selectedDisplayItem: null,
          );

      expect(splitViewFallback.wordId, 'T9000_H16_EXPLORER_SPLIT_FALLBACK');
      expect(
        splitViewFallback.representativeSpelling,
        'phase8h16-split-fallback-spelling',
      );
      expect(splitViewFallback.displayStrongNumber, 'H83');
      expect(
        splitViewFallback.representativeTransliteration,
        'phase8h16-split-fallback-translit',
      );

      expect(idOnlyFallback.wordId, 'T9000_H16_EXPLORER_ID_ONLY');
      expect(
        idOnlyFallback.representativeSpelling,
        'T9000_H16_EXPLORER_ID_ONLY',
      );
      expect(idOnlyFallback.displayStrongNumber, isEmpty);
      expect(idOnlyFallback.representativeTransliteration, isEmpty);
    });
  });
}
