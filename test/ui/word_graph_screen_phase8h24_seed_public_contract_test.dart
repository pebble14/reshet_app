// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package

import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/data/models/word.dart';
import 'package:reshet_app/ui/word_graph_screen.dart';

void main() {
  group('Phase 8-H-24 graph seed public API contract first slice', () {
    test('uses centerWordId as the primary public graph seed', () {
      final screen = WordGraphScreen(
        centerWordId: ' H24_PRIMARY_CENTER ',
        centerWord: Word(
          id: 'H24_COMPAT_CENTER',
          spelling1: 'caller display must be ignored',
        ),
      );

      expect(screen.centerWordId, 'H24_PRIMARY_CENTER');
    });

    test('keeps centerWord compatibility path as an id-only seed', () {
      final screen = WordGraphScreen(
        centerWord: Word(
          id: ' H24_COMPAT_CENTER ',
          strongNumber: 'H24',
          spelling1: 'caller spelling must be ignored',
          transliteration1: 'caller transliteration must be ignored',
        ),
      );

      expect(screen.centerWordId, 'H24_COMPAT_CENTER');
      expect(screen.centerWord.id, 'H24_COMPAT_CENTER');
      expect(screen.centerWord.strongNumber, isNull);
      expect(screen.centerWord.spelling1, isNull);
      expect(screen.centerWord.transliteration1, isNull);
    });

    test('requires a non-empty graph seed id', () {
      expect(() => WordGraphScreen(), throwsArgumentError);
      expect(
        () => WordGraphScreen(
          centerWordId: ' ',
          centerWord: Word(id: ' '),
        ),
        throwsArgumentError,
      );
    });
  });
}
