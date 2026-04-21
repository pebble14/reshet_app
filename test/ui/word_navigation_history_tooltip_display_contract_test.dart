import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/ui/word_navigation_history.dart';

void main() {
  group('WordNavigationHistoryTooltipDisplay', () {
    test('keeps tooltip display order and trims display fields', () {
      const display = WordNavigationHistoryTooltipDisplay(
        wordId: 'W_H18_001',
        representativeSpelling: '  representative-spelling  ',
        displayStrongNumber: '  H18  ',
        representativeTransliteration: '  representative-translit  ',
      );

      expect(display.tooltipLines, [
        'representative-spelling',
        'representative-translit',
        'H18',
      ]);
    });

    test(
      'omits blank tooltip display fields without changing fallback owner',
      () {
        const display = WordNavigationHistoryTooltipDisplay(
          wordId: 'W_H18_002',
          representativeSpelling: ' ',
          displayStrongNumber: '',
          representativeTransliteration: '  representative-translit  ',
        );

        expect(display.tooltipLines, ['representative-translit']);
      },
    );
  });

  group('WordNavigationHistoryEntry', () {
    test('keeps legacy accessors and preserves payload ownership', () {
      const payload = _NavigationPayload(
        centerWordId: 'W_H18_CENTER',
        selectedWordId: 'W_H18_SELECTED',
      );
      const entry = WordNavigationHistoryEntry<_NavigationPayload>(
        tooltipDisplay: WordNavigationHistoryTooltipDisplay(
          wordId: 'W_H18_ENTRY',
          representativeSpelling: 'entry-spelling',
          displayStrongNumber: 'H1818',
          representativeTransliteration: 'entry-translit',
        ),
        payload: payload,
      );

      expect(entry.wordId, 'W_H18_ENTRY');
      expect(entry.representativeSpelling, 'entry-spelling');
      expect(entry.strongNumber, 'H1818');
      expect(identical(entry.payload, payload), isTrue);
      expect(entry.payload.centerWordId, 'W_H18_CENTER');
      expect(entry.payload.selectedWordId, 'W_H18_SELECTED');
    });
  });
}

class _NavigationPayload {
  final String centerWordId;
  final String? selectedWordId;

  const _NavigationPayload({
    required this.centerWordId,
    required this.selectedWordId,
  });
}
