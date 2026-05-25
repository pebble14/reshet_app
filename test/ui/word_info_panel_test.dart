import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/domain/word/word_detail_like_display_item.dart';
import 'package:reshet_app/ui/word_info_panel.dart';

void main() {
  group('WordInfoPanel', () {
    testWidgets(
      'hides the transliteration section when canonical sets have no transliteration',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WordInfoPanel(
                displayItem: WordDetailLikeDisplayItem(
                  representativeSpelling: 'hippopotamus',
                  spellings: ['hippopotamus', 'hippo'],
                  pronunciations: ['|hɪpə|pɑːtəməs', 'ˈhɪpəʊ'],
                  meanings: ['hippo'],
                ),
              ),
            ),
          ),
        );

        expect(find.text('대표 표기'), findsOneWidget);
        expect(find.text('표기'), findsOneWidget);
        expect(find.text('발음'), findsOneWidget);
        expect(find.text('음역'), findsNothing);
        expect(find.text('hippopotamus'), findsOneWidget);
        expect(find.text('hippopotamus\nhippo'), findsOneWidget);
        expect(find.text('hippo'), findsOneWidget);
      },
    );

    testWidgets(
      'renders transliteration and meaning sections from display item',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WordInfoPanel(
                displayItem: WordDetailLikeDisplayItem(
                  representativeSpelling: 'כְּפַר נַחוּם',
                  spellings: ['כְּפַר נַחוּם'],
                  transliterations: ['크파르 나훌'],
                  meanings: ['가버나움'],
                ),
              ),
            ),
          ),
        );

        expect(find.text('대표 표기'), findsOneWidget);
        expect(find.text('표기'), findsOneWidget);
        expect(find.text('음역'), findsOneWidget);
        expect(find.text('발음'), findsNothing);
        expect(find.text('크파르 나훌'), findsOneWidget);
        expect(find.text('가버나움'), findsOneWidget);
      },
    );

    testWidgets('renders issue-bearing rows without crashing', (tester) async {
      final displayItems = [
        WordDetailLikeDisplayItem(
          representativeSpelling: 'ἀκέραιος',
          transliterations: ['아케라이오스'],
          pronunciations: ['ak-er-ah-yos', 'G2767'],
        ),
        WordDetailLikeDisplayItem(
          representativeSpelling: 'כְּפַר נַחוּם',
          transliterations: ['크파르 나훌', '케파르 나훌'],
        ),
        WordDetailLikeDisplayItem(
          representativeSpelling: 'בַּבְלִי',
          transliterations: ['바블리/바벨리', '바벨리'],
          pronunciations: ['bab-lee'],
        ),
        WordDetailLikeDisplayItem(
          representativeSpelling: '아빠',
          spellings: ['아빠', '2', '3'],
          transliterations: ['아빠', '2', '3', '4'],
          pronunciations: ['아빠', '2', '3', '4'],
        ),
      ];

      for (final displayItem in displayItems) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: WordInfoPanel(displayItem: displayItem)),
          ),
        );

        await tester.pump();

        expect(find.byType(WordInfoPanel), findsOneWidget);
        expect(find.text(displayItem.representativeSpelling!), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
