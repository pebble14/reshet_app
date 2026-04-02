import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/ui/word_info_panel.dart';

void main() {
  group('buildWordRepresentativeSpelling', () {
    test('returns the first valid spelling from canonical expressions', () {
      final representative = buildWordRepresentativeSpelling({
        'id': 'X0000_REP',
        '표기1': '',
        '음역1': 'issue-only',
        '표기2': 'beta',
        '음역2': '베타',
      });

      expect(representative, 'beta');
    });
  });

  group('WordInfoPanel', () {
    testWidgets(
      'hides the transliteration section when canonical sets have no transliteration',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WordInfoPanel(
                wordMap: {
                  'id': 'E0000_0076',
                  '표기1': 'hippopotamus',
                  '표기2': 'hippo',
                  '발음1': '|hɪpə|pɑːtəməs',
                  '발음2': 'ˈhɪpəʊ',
                  '의미1': 'hippo',
                },
              ),
            ),
          ),
        );

        expect(find.text('대표 표기'), findsOneWidget);
        expect(find.text('표기'), findsOneWidget);
        expect(find.text('발음'), findsOneWidget);
        expect(find.text('음역'), findsNothing);
        expect(find.text('hippopotamus'), findsOneWidget);
        expect(find.text('hippo'), findsWidgets);
      },
    );

    testWidgets('does not surface issue-only values in expression sections', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordInfoPanel(
              wordMap: {
                'id': 'H0000_0024',
                '표기1': 'כְּפַר נַחוּם',
                '음역1': '크파르 나훌',
                '표기2': '',
                '음역2': '케파르 나훌',
                '의미1': '가버나움',
              },
            ),
          ),
        ),
      );

      expect(find.text('대표 표기'), findsOneWidget);
      expect(find.text('표기'), findsOneWidget);
      expect(find.text('음역'), findsOneWidget);
      expect(find.text('발음'), findsNothing);
      expect(find.text('케파르 나훌'), findsNothing);
      expect(find.text('크파르 나훌'), findsOneWidget);
    });

    testWidgets('renders issue-bearing rows without crashing', (tester) async {
      final issueRows = [
        {
          'id': 'G0185_0000',
          '표기1': 'ἀκέραιος',
          '음역1': '아케라이오스',
          '발음1': 'ak-er-ah-yos',
          '표기2': '',
          '발음2': 'G2767',
        },
        {
          'id': 'H0000_0024',
          '표기1': 'כְּפַר נַחוּם',
          '음역1': '크파르 나훌',
          '표기2': '',
          '음역2': '케파르 나훌',
        },
        {
          'id': 'H0896_0000',
          '표기1': 'בַּבְלִי',
          '음역1': '바블리/바벨리',
          '표기2': '',
          '음역2': '바벨리',
          '발음1': 'bab-lee',
        },
        {
          'id': 'X0000_0001',
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
      ];

      for (final row in issueRows) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: WordInfoPanel(wordMap: row)),
          ),
        );

        await tester.pump();

        expect(find.byType(WordInfoPanel), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
