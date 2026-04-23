import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/data/models/word.dart';
import 'package:reshet_app/ui/word_graph_screen.dart';

void main() {
  group('Phase 8-H-30 graph selection callback contract', () {
    test(
      'exposes selectedWordId callback as the primary selection contract',
      () {
        String? capturedSelectedWordId;
        var legacyWordCallbackCalled = false;

        final screen = WordGraphScreen(
          centerWordId: 'H30_CENTER',
          onSelectWordId: (selectedWordId) {
            capturedSelectedWordId = selectedWordId;
          },
          onSelectWord: (_) {
            legacyWordCallbackCalled = true;
          },
        );

        expect(screen.onSelectWordId, isNotNull);

        screen.onSelectWordId!.call('H30_SELECTED');

        expect(capturedSelectedWordId, 'H30_SELECTED');
        expect(legacyWordCallbackCalled, isFalse);
      },
    );

    test('keeps Word callback as a compatibility fallback', () {
      Word? capturedLegacyWord;

      final screen = WordGraphScreen(
        centerWordId: 'H30_CENTER',
        onSelectWord: (word) {
          capturedLegacyWord = word;
        },
      );

      expect(screen.onSelectWordId, isNull);

      screen.onSelectWord!.call(
        Word(id: 'H30_LEGACY_SELECTED', spelling1: 'legacy spelling'),
      );

      expect(capturedLegacyWord?.id, 'H30_LEGACY_SELECTED');
      expect(capturedLegacyWord?.spelling1, 'legacy spelling');
    });
  });
}
