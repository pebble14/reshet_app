import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/data/adapters/legacy_word_expression_read_adapter.dart';
import 'package:reshet_app/ui/word_expression_set.dart';

void main() {
  group('readLegacyWordExpressionRow', () {
    test('reads a single representative set from a legacy row', () {
      final result = readLegacyWordExpressionRow({
        'id': 'E0000_0003',
        '표기1': 'Adam',
        '음역1': '아담',
        '발음1': 'a-dam',
      });

      expect(result.sets, hasLength(1));
      expect(result.issues, isEmpty);
      expect(result.sets.first.spelling, 'Adam');
      expect(result.sets.first.transliteration, '아담');
      expect(result.sets.first.pronunciation, 'a-dam');
      expect(result.sets.first.seq, 1);
      expect(result.sets.first.isRepresentative, isTrue);
    });

    test(
      'compacts seq while preserving the first valid spelling as representative',
      () {
        final result = readLegacyWordExpressionRow({
          'id': 'X0000_SEQ',
          '표기1': '',
          '음역1': 'slot-one-issue',
          '표기2': 'beta',
          '음역2': '베타',
          '표기4': 'gamma',
          '발음4': 'ga-ma',
        });

        expect(result.sets, hasLength(2));
        expect(result.issues, hasLength(1));
        expect(result.sets[0].spelling, 'beta');
        expect(result.sets[0].seq, 1);
        expect(result.sets[0].isRepresentative, isTrue);
        expect(result.sets[1].spelling, 'gamma');
        expect(result.sets[1].seq, 2);
        expect(result.sets[1].isRepresentative, isFalse);
        expect(result.issues.single.sourceSlot, 1);
      },
    );

    test('separates supplemental-only slots into issues', () {
      final result = readLegacyWordExpressionRow({
        'id': 'G0185_0000',
        '표기1': 'ἀκέραιος',
        '음역1': '아케라이오스',
        '발음1': 'ak-er-ah-yos',
        '표기2': '',
        '음역2': '',
        '발음2': 'G2767',
      });

      expect(result.sets, hasLength(1));
      expect(result.issues, hasLength(1));
      expect(
        result.issues.single.issueCode,
        supplementalWithoutSpellingIssueCode,
      );
      expect(result.issues.single.resolution, manualCleanupRequiredResolution);
      expect(result.issues.single.sourceSlot, 2);
      expect(result.issues.single.rawPronunciation, 'G2767');
    });
  });

  group('createExpressionSetControllerGroups', () {
    testWidgets(
      'logs issue-bearing rows without mixing them into the form seed',
      (tester) async {
        final logs = <String>[];
        final previousDebugPrint = debugPrint;
        final controllerGroups = <WordExpressionSetControllerGroup>[];

        try {
          debugPrint = (String? message, {int? wrapWidth}) {
            if (message != null) {
              logs.add(message);
            }
          };

          controllerGroups.addAll(
            createExpressionSetControllerGroups({
              'id': 'H0000_0024',
              '표기1': '苦斂玲壘囹淚 囹灘 玲殼',
              '음역1': '스파루 후월',
              '표기2': '',
              '음역2': '케루 후월',
            }),
          );

          expect(controllerGroups, hasLength(1));
          expect(
            controllerGroups.single.spellingController.text,
            '苦斂玲壘囹淚 囹灘 玲殼',
          );
          expect(
            controllerGroups.single.transliterationController.text,
            '스파루 후월',
          );
          expect(logs, hasLength(1));
          expect(logs.single, contains('wordId=H0000_0024'));
          expect(logs.single, contains('issueCount=1'));
          expect(logs.single, contains('sourceSlots=2'));
        } finally {
          debugPrint = previousDebugPrint;
          for (final controllerGroup in controllerGroups) {
            controllerGroup.dispose();
          }
        }
      },
    );
  });
}
