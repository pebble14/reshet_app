import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/data/adapters/legacy_word_expression_write_adapter.dart';
import 'package:reshet_app/domain/word/word_write_models.dart';

void main() {
  test('toLegacyWordExpressionColumns writes canonical sets sequentially', () {
    final columns = toLegacyWordExpressionColumns([
      const CanonicalExpressionWriteSet(
        spelling: 'beta',
        transliteration: '베타',
        pronunciation: null,
        seq: 1,
        isRepresentative: true,
      ),
      const CanonicalExpressionWriteSet(
        spelling: 'gamma',
        transliteration: '',
        pronunciation: 'ga-ma',
        seq: 2,
        isRepresentative: false,
      ),
      const CanonicalExpressionWriteSet(
        spelling: '',
        transliteration: 'ignored',
        pronunciation: 'ignored',
        seq: 3,
        isRepresentative: false,
      ),
    ]);

    expect(columns['표기1'], 'beta');
    expect(columns['음역1'], '베타');
    expect(columns['발음1'], isNull);
    expect(columns['표기2'], 'gamma');
    expect(columns['음역2'], isNull);
    expect(columns['발음2'], 'ga-ma');
    expect(columns['표기3'], isNull);
    expect(columns['음역3'], isNull);
    expect(columns['발음3'], isNull);
  });
}
