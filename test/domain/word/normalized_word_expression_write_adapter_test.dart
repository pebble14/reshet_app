import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/data/adapters/normalized_word_expression_write_adapter.dart';
import 'package:reshet_app/domain/expression/expression_read_models.dart';
import 'package:reshet_app/domain/expression/pronunciation_notation.dart';

void main() {
  group('toWordExpressionSetRows', () {
    test('rewrites sets into sequential representative-first rows', () {
      final rows = toWordExpressionSetRows('T9000_0001', const [
        ExpressionSet(
          spelling: 'beta',
          transliteration: '베타',
          pronunciation: null,
          seq: 4,
          isRepresentative: false,
        ),
        ExpressionSet(
          spelling: 'gamma',
          transliteration: '',
          pronunciation: 'ga-ma',
          seq: 8,
          isRepresentative: true,
        ),
      ]);

      expect(rows, [
        {
          'word_id': 'T9000_0001',
          'seq': 1,
          'is_representative': 1,
          'spelling': 'beta',
          'transliteration': '베타',
          'pronunciation': null,
          'pronunciation_notation': null,
          'pronunciation_notation_name': null,
        },
        {
          'word_id': 'T9000_0001',
          'seq': 2,
          'is_representative': 0,
          'spelling': 'gamma',
          'transliteration': null,
          'pronunciation': 'ga-ma',
          'pronunciation_notation': 'unknown',
          'pronunciation_notation_name': null,
        },
      ]);
    });

    test('normalizes typed IPA metadata into storage columns', () {
      final rows = toWordExpressionSetRows('T9000_0002', const [
        ExpressionSet(
          spelling: 'ahava',
          transliteration: null,
          pronunciation: '/ʔa.haˈva/',
          pronunciationNotation: PronunciationNotation.ipaPhonemic,
          seq: 1,
          isRepresentative: true,
        ),
      ]);

      expect(rows.single['pronunciation'], 'ʔa.haˈva');
      expect(rows.single['pronunciation_notation'], 'ipa_phonemic');
      expect(rows.single['pronunciation_notation_name'], isNull);
    });

    test('rejects empty word ids', () {
      expect(
        () => toWordExpressionSetRows('   ', const []),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
