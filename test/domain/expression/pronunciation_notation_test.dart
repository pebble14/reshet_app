import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/domain/expression/pronunciation_notation.dart';

void main() {
  group('normalizePronunciationForWrite', () {
    test('removes one expected IPA phonemic delimiter pair', () {
      final bare = normalizePronunciationForWrite(
        pronunciation: '  ?a.ha?va  ',
        notation: PronunciationNotation.ipaPhonemic,
      );
      final wrapped = normalizePronunciationForWrite(
        pronunciation: ' /?a.ha?va/ ',
        notation: PronunciationNotation.ipaPhonemic,
      );

      expect(bare!.text, '?a.ha?va');
      expect(wrapped!.text, '?a.ha?va');
      expect(bare.formattedText, '/?a.ha?va/');
      expect(wrapped.formattedText, '/?a.ha?va/');
    });

    test('removes one expected IPA phonetic delimiter pair', () {
      final bare = normalizePronunciationForWrite(
        pronunciation: '?a.(?)a?va',
        notation: PronunciationNotation.ipaPhonetic,
      );
      final wrapped = normalizePronunciationForWrite(
        pronunciation: '[?a.(?)a?va]',
        notation: PronunciationNotation.ipaPhonetic,
      );

      expect(bare!.text, '?a.(?)a?va');
      expect(wrapped!.text, '?a.(?)a?va');
      expect(bare.formattedText, '[?a.(?)a?va]');
      expect(wrapped.formattedText, '[?a.(?)a?va]');
    });

    test('rejects opposite and incomplete IPA delimiters', () {
      expect(
        () => normalizePronunciationForWrite(
          pronunciation: '[?a.ha?va]',
          notation: PronunciationNotation.ipaPhonemic,
        ),
        throwsFormatException,
      );
      expect(
        () => normalizePronunciationForWrite(
          pronunciation: '/?a.(?)a?va/',
          notation: PronunciationNotation.ipaPhonetic,
        ),
        throwsFormatException,
      );
      expect(
        () => normalizePronunciationForWrite(
          pronunciation: '/?a.ha?va',
          notation: PronunciationNotation.ipaPhonemic,
        ),
        throwsFormatException,
      );
      expect(
        () => normalizePronunciationForWrite(
          pronunciation: '[]',
          notation: PronunciationNotation.ipaPhonetic,
        ),
        throwsFormatException,
      );
    });

    test('preserves internal symbols and non-IPA delimiters', () {
      final ipa = normalizePronunciationForWrite(
        pronunciation: 'a/(b)[c]d',
        notation: PronunciationNotation.ipaPhonemic,
      );
      final unknown = normalizePronunciationForWrite(
        pronunciation: '/dictionary-form/',
        notation: PronunciationNotation.unknown,
      );

      expect(ipa!.text, 'a/(b)[c]d');
      expect(unknown!.text, '/dictionary-form/');
    });

    test('clears metadata with an empty body and clears non-other name', () {
      expect(
        normalizePronunciationForWrite(
          pronunciation: '  ',
          notation: PronunciationNotation.other,
          notationName: 'Custom',
        ),
        isNull,
      );

      final ipa = normalizePronunciationForWrite(
        pronunciation: 'a',
        notation: PronunciationNotation.ipaPhonemic,
        notationName: 'removed',
      );
      expect(ipa!.notationName, isNull);
    });
  });

  group('storage and formatter contract', () {
    test('keeps missing legacy metadata distinct from unsupported code', () {
      final legacy = readStoredPronunciation(
        pronunciation: 'legacy',
        notationCode: null,
        notationName: null,
      );

      expect(legacy!.notation, PronunciationNotation.unknown);
      expect(
        () => readStoredPronunciation(
          pronunciation: 'invalid',
          notationCode: 'unsupported',
          notationName: null,
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid stored cross-field combinations', () {
      expect(
        () => readStoredPronunciation(
          pronunciation: null,
          notationCode: 'unknown',
          notationName: null,
        ),
        throwsFormatException,
      );
      expect(
        () => readStoredPronunciation(
          pronunciation: 'a',
          notationCode: 'unknown',
          notationName: 'invalid name',
        ),
        throwsFormatException,
      );
    });

    test('formats notation labels including optional other name', () {
      expect(
        formatPronunciationNotationLabel(PronunciationNotation.unknown),
        '표기 체계 미상',
      );
      expect(
        formatPronunciationNotationLabel(
          PronunciationNotation.other,
          notationName: '학술 관례',
        ),
        '기타 — 학술 관례',
      );
    });
  });
}
