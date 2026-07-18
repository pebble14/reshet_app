import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/data/adapters/normalized_word_expression_read_adapter.dart';
import 'package:reshet_app/domain/expression/pronunciation_notation.dart';
import 'package:reshet_app/domain/expression/read_source_policy.dart';

void main() {
  group('readNormalizedWordExpressionRows', () {
    test(
      'uses is_representative first while keeping deterministic seq order',
      () {
        final outcome = readNormalizedWordExpressionRows([
          {
            'id': 20,
            'word_id': 'E0000_0010',
            'seq': 2,
            'is_representative': 1,
            'spelling': 'Eve',
            'transliteration': '이브',
            'pronunciation': 'iːv',
          },
          {
            'id': 10,
            'word_id': 'E0000_0010',
            'seq': 1,
            'is_representative': 0,
            'spelling': 'Eva',
            'transliteration': '이바',
            'pronunciation': 'iːvə',
          },
        ]);

        expect(outcome.isSuccess, isTrue);
        expect(outcome.failureReason, isNull);
        expect(outcome.readResult!.sets, hasLength(2));
        expect(outcome.readResult!.sets[0].spelling, 'Eva');
        expect(outcome.readResult!.sets[0].isRepresentative, isFalse);
        expect(outcome.readResult!.sets[1].spelling, 'Eve');
        expect(outcome.readResult!.sets[1].isRepresentative, isTrue);
        expect(
          outcome.readResult!.sets[1].pronunciationNotation,
          PronunciationNotation.unknown,
        );
      },
    );

    test(
      'uses seq=1 only as recovery fallback when representative flag is missing',
      () {
        final outcome = readNormalizedWordExpressionRows([
          {
            'id': 1,
            'word_id': 'X0000_0001',
            'seq': 1,
            'is_representative': 0,
            'spelling': 'alpha',
            'transliteration': '알파',
            'pronunciation': '',
          },
          {
            'id': 2,
            'word_id': 'X0000_0001',
            'seq': 2,
            'is_representative': 0,
            'spelling': 'aleph',
            'transliteration': '',
            'pronunciation': 'a-leph',
          },
        ]);

        expect(outcome.isSuccess, isTrue);
        expect(outcome.readResult!.sets.first.isRepresentative, isTrue);
        expect(outcome.readResult!.sets.last.isRepresentative, isFalse);
        expect(outcome.readResult!.sets.first.transliteration, '알파');
        expect(outcome.readResult!.sets.last.transliteration, isNull);
      },
    );

    test(
      'returns minimumExpressionNotMet when no valid spelling can be built',
      () {
        final outcome = readNormalizedWordExpressionRows([
          {
            'id': 1,
            'word_id': 'X0000_EMPTY',
            'seq': 1,
            'is_representative': 1,
            'spelling': '   ',
            'transliteration': 'issue-only',
            'pronunciation': 'issue-only',
          },
        ]);

        expect(outcome.isSuccess, isFalse);
        expect(
          outcome.failureReason,
          ReadFallbackReason.minimumExpressionNotMet,
        );
      },
    );

    test('returns mappingInvalid for unsupported notation code', () {
      final outcome = readNormalizedWordExpressionRows([
        {
          'id': 1,
          'word_id': 'X0000_INVALID_NOTATION',
          'seq': 1,
          'is_representative': 1,
          'spelling': 'alpha',
          'pronunciation': 'a',
          'pronunciation_notation': 'unsupported',
          'pronunciation_notation_name': null,
        },
      ]);

      expect(outcome.isSuccess, isFalse);
      expect(outcome.failureReason, ReadFallbackReason.mappingInvalid);
      expect(outcome.detail, contains('unsupported'));
    });

    test('returns mappingInvalid for an invalid cross-field combination', () {
      final outcome = readNormalizedWordExpressionRows([
        {
          'id': 1,
          'word_id': 'X0000_INVALID_CROSS_FIELD',
          'seq': 1,
          'is_representative': 1,
          'spelling': 'alpha',
          'pronunciation': null,
          'pronunciation_notation': 'unknown',
          'pronunciation_notation_name': null,
        },
      ]);

      expect(outcome.isSuccess, isFalse);
      expect(outcome.failureReason, ReadFallbackReason.mappingInvalid);
    });

    test('returns mappingInvalid for duplicate seq rows', () {
      final outcome = readNormalizedWordExpressionRows([
        {
          'id': 1,
          'word_id': 'X0000_DUP',
          'seq': 1,
          'is_representative': 1,
          'spelling': 'alpha',
        },
        {
          'id': 2,
          'word_id': 'X0000_DUP',
          'seq': 1,
          'is_representative': 0,
          'spelling': 'aleph',
        },
      ]);

      expect(outcome.isSuccess, isFalse);
      expect(outcome.failureReason, ReadFallbackReason.mappingInvalid);
    });
  });
}
