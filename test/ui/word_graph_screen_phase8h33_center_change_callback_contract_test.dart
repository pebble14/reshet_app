import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/data/models/word.dart';
import 'package:reshet_app/ui/word_graph_screen.dart';

void main() {
  group('Phase 8-H-33 graph center change callback contract', () {
    test(
      'exposes centerWordId callback as the primary center change contract',
      () {
        String? capturedCenterWordId;
        Word? capturedCompatibilityWord;

        final screen = WordGraphScreen(
          centerWordId: 'H33_CENTER',
          onChangeCenterWordId: (centerWordId) {
            capturedCenterWordId = centerWordId;
          },
          onChangeCenterWord: (word) {
            capturedCompatibilityWord = word;
          },
        );

        expect(screen.onChangeCenterWordId, isNotNull);

        screen.onChangeCenterWordId!.call('H33_NEXT_CENTER');

        expect(capturedCenterWordId, 'H33_NEXT_CENTER');
        expect(capturedCompatibilityWord, isNull);

        screen.onChangeCenterWord!.call(
          Word(id: 'H33_NEXT_CENTER', spelling1: 'compatibility spelling'),
        );

        expect(capturedCompatibilityWord?.id, 'H33_NEXT_CENTER');
        expect(capturedCompatibilityWord?.spelling1, 'compatibility spelling');
      },
    );
  });
}
