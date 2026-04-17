import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/ui/word_edit_screen.dart';
import 'package:reshet_app/ui/word_expression_set.dart';

void main() {
  group('WordEditScreen expression seed', () {
    testWidgets('seeds a single representative set for a basic word', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WordEditScreen(
            word: {
              'id': 'E0000_0003',
              '언어': '영어',
              '표기1': 'Adam',
              '음역1': '아담',
              '발음1': 'ǎdəm',
            },
          ),
        ),
      );

      final headingLabels = _expressionSetHeadingLabels(tester);
      final fieldValues = _expressionFieldValues(tester);

      expect(_representativeHeadingCount(headingLabels), 1);
      expect(headingLabels.first, '세트 1 (대표)');
      expect(_expressionSetCount(fieldValues), 1);
      expect(fieldValues[0], 'Adam');
      expect(fieldValues[1], '아담');
      expect(fieldValues[2], 'ǎdəm');
    });

    testWidgets(
      'seeds representative-first order for multiple expression sets',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: WordEditScreen(
              word: {
                'id': 'E0000_0010',
                '언어': '영어',
                '표기1': 'Eva',
                '표기2': 'Eve',
                '음역1': '이바',
                '음역2': '이브',
                '발음1': 'iːvə',
                '발음2': 'iːv',
              },
            ),
          ),
        );

        final headingLabels = _expressionSetHeadingLabels(tester);
        final fieldValues = _expressionFieldValues(tester);

        expect(_representativeHeadingCount(headingLabels), 1);
        expect(headingLabels.first, '세트 1 (대표)');
        expect(headingLabels[1], '세트 2');
        expect(_expressionSetCount(fieldValues), 2);
        expect(fieldValues[0], 'Eva');
        expect(fieldValues[3], 'Eve');
      },
    );

    testWidgets('keeps partial omissions as empty form fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WordEditScreen(
            word: {
              'id': 'E0000_0056',
              '언어': '영어',
              '표기1': 'demon',
              '표기2': 'daimon',
              '표기3': 'daemon',
              '음역1': '디먼',
              '발음1': 'ˈdiː.mən',
            },
          ),
        ),
      );

      final fieldValues = _expressionFieldValues(tester);

      expect(_expressionSetCount(fieldValues), 3);
      expect(fieldValues[0], 'demon');
      expect(fieldValues[1], '디먼');
      expect(fieldValues[2], 'ˈdiː.mən');
      expect(fieldValues[3], 'daimon');
      expect(fieldValues[4], '');
      expect(fieldValues[5], '');
      expect(fieldValues[6], 'daemon');
      expect(fieldValues[7], '');
      expect(fieldValues[8], '');
    });

    testWidgets(
      'does not mix issue-only slots into form seed and logs key fields',
      (tester) async {
        final logs = <String>[];
        final previousDebugPrint = debugPrint;

        try {
          debugPrint = (String? message, {int? wrapWidth}) {
            if (message != null) {
              logs.add(message);
            }
          };

          await tester.pumpWidget(
            MaterialApp(
              home: WordEditScreen(
                word: {
                  'id': 'H0000_0024',
                  '언어': '히브리어',
                  '표기1': 'כְּפַר נַחוּם',
                  '음역1': '크파르 나훌',
                  '표기2': '',
                  '음역2': '케파르 나훌',
                },
              ),
            ),
          );

          final headingLabels = _expressionSetHeadingLabels(tester);
          final fieldValues = _expressionFieldValues(tester);

          expect(_expressionSetCount(fieldValues), 1);
          expect(_representativeHeadingCount(headingLabels), 1);
          expect(headingLabels.first, '세트 1 (대표)');
          expect(fieldValues[0], 'כְּפַר נַחוּם');
          expect(fieldValues[1], '크파르 나훌');
          expect(fieldValues[2], '');
          expect(fieldValues, isNot(contains('케파르 나훌')));

          final matchingLogs = logs
              .where((log) => log.contains('wordId=H0000_0024'))
              .toList(growable: false);

          expect(matchingLogs, hasLength(1));
          expect(matchingLogs.single, contains('issueCount=1'));
          expect(matchingLogs.single, contains('sourceSlots=2'));
        } finally {
          debugPrint = previousDebugPrint;
        }
      },
    );

    testWidgets(
      'renders issue-bearing rows without creating extra edit cards',
      (tester) async {
        final issueRows = [
          (
            word: {
              'id': 'G0185_0000',
              '언어': '그리스어',
              '표기1': 'ἀκέραιος',
              '음역1': '아케라이오스',
              '발음1': "ak-er'-ah-yos",
              '표기2': '',
              '발음2': 'G2767',
            },
            expectedSetCount: 1,
            expectedIssueLog: 'sourceSlots=2',
          ),
          (
            word: {
              'id': 'H0896_0000',
              '언어': '히브리어',
              '표기1': 'בַּבְלִי',
              '음역1': '바블리/바벨리',
              '표기2': '',
              '음역2': '바벨리',
              '발음1': "bab-lee'",
            },
            expectedSetCount: 1,
            expectedIssueLog: 'sourceSlots=2',
          ),
          (
            word: {
              'id': 'X0000_0001',
              '언어': '테스트',
              '표기1': '아빠',
              '표기2': '2',
              '표기3': '3',
              '음역1': '아빠',
              '음역2': '2',
              '음역3': '3',
              '음역4': '4',
              '발음1': '아빠',
              '발음2': '2',
              '발음3': '3',
              '발음4': '4',
            },
            expectedSetCount: 3,
            expectedIssueLog: 'sourceSlots=4',
          ),
        ];

        final logs = <String>[];
        final previousDebugPrint = debugPrint;

        try {
          debugPrint = (String? message, {int? wrapWidth}) {
            if (message != null) {
              logs.add(message);
            }
          };

          for (final entry in issueRows) {
            logs.clear();
            final wordId = entry.word['id'] as String;

            await tester.pumpWidget(
              MaterialApp(
                home: WordEditScreen(key: ValueKey(wordId), word: entry.word),
              ),
            );

            await tester.pump();

            final fieldValues = _expressionFieldValues(tester);
            final headingLabels = _expressionSetHeadingLabels(tester);
            final matchingLogs = logs
                .where((log) => log.contains('wordId=$wordId'))
                .toList(growable: false);

            expect(_expressionSetCount(fieldValues), entry.expectedSetCount);
            expect(_representativeHeadingCount(headingLabels), 1);
            expect(headingLabels.first, '세트 1 (대표)');
            expect(matchingLogs, hasLength(1));
            expect(matchingLogs.single, contains('issueCount=1'));
            expect(matchingLogs.single, contains(entry.expectedIssueLog));
            expect(tester.takeException(), isNull);
          }
        } finally {
          debugPrint = previousDebugPrint;
        }
      },
    );
  });

  group('WordEditScreen edit seed contract', () {
    testWidgets('seeds language, strong number, meanings, and note unchanged', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: WordEditScreen(
            word: {
              'id': 'G0000_0204',
              '언어': '영어',
              '스트롱넘버': ' g2040 ',
              '표기1': 'seed-title',
              '의미1': ' first meaning ',
              '의미2': '',
              '의미3': 'first meaning',
              '비고': ' note seed ',
            },
          ),
        ),
      );

      final languageDropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );

      expect(languageDropdown.initialValue, '영어');
      expect(
        _textFieldByLabel(tester, '스트롱넘버 (없으면 비워둠)').controller?.text,
        ' g2040 ',
      );
      expect(
        _textFieldByLabel(tester, '의미 1').controller?.text,
        'first meaning',
      );
      expect(
        _textFieldByLabel(tester, '의미 2').controller?.text,
        'first meaning',
      );
      expect(_textFieldByLabel(tester, '비고').controller?.text, ' note seed ');
    });
  });
}

List<String> _expressionSetHeadingLabels(WidgetTester tester) {
  final headingFinder = find.descendant(
    of: find.byType(WordExpressionSetSection),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data != null &&
          RegExp(r'^세트 \d+( \(대표\))?$').hasMatch(widget.data!),
    ),
  );

  return tester
      .widgetList<Text>(headingFinder)
      .map((widget) => widget.data ?? '')
      .toList(growable: false);
}

List<String> _expressionFieldValues(WidgetTester tester) {
  final fieldFinder = find.descendant(
    of: find.byType(WordExpressionSetSection),
    matching: find.byType(TextField),
  );

  return tester
      .widgetList<TextField>(fieldFinder)
      .map((field) => field.controller?.text ?? '')
      .toList(growable: false);
}

int _expressionSetCount(List<String> fieldValues) {
  return fieldValues.length ~/ 3;
}

int _representativeHeadingCount(List<String> headingLabels) {
  return headingLabels.where((label) => label.contains('(대표)')).length;
}

TextField _textFieldByLabel(WidgetTester tester, String label) {
  final finder = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
  expect(finder, findsOneWidget);
  return tester.widget<TextField>(finder);
}
