import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/domain/expression/pronunciation_notation.dart';
import 'package:reshet_app/domain/word/word_detail_like_display_item.dart';
import 'package:reshet_app/ui/word_detail_clipboard_payload.dart';
import 'package:reshet_app/ui/word_detail_screen.dart';
import 'package:reshet_app/ui/word_info_panel.dart';

void main() {
  group('buildWordDetailClipboardText', () {
    test('preserves more than six spelling values in display order', () {
      const displayItem = WordDetailLikeDisplayItem(
        representativeSpelling: 'canonical display',
        spellings: [
          'spelling 1',
          'spelling 2',
          'spelling 3',
          'spelling 4',
          'spelling 5',
          'spelling 6',
          'spelling 7',
          'spelling 8',
        ],
      );

      expect(
        buildWordDetailClipboardText(displayItem),
        [
          '대표 표기: canonical display',
          '',
          '표기:',
          '- spelling 1',
          '- spelling 2',
          '- spelling 3',
          '- spelling 4',
          '- spelling 5',
          '- spelling 6',
          '- spelling 7',
          '- spelling 8',
        ].join('\n'),
      );
    });

    test('preserves repeated meaning values without deduplication', () {
      const displayItem = WordDetailLikeDisplayItem(
        representativeSpelling: 'meaning anchor',
        meanings: ['same meaning', 'same meaning', 'later meaning'],
      );

      expect(
        buildWordDetailClipboardText(displayItem),
        [
          '대표 표기: meaning anchor',
          '',
          '의미:',
          '- same meaning',
          '- same meaning',
          '- later meaning',
        ].join('\n'),
      );
    });

    test('omits empty scalar, list, and note sections', () {
      const displayItem = WordDetailLikeDisplayItem(
        representativeSpelling: '  empty section anchor  ',
        displayStrongNumber: '  ',
        language: '',
        spellings: [],
        transliterations: ['  '],
        pronunciations: [],
        meanings: [],
        note: '   ',
      );

      final payload = buildWordDetailClipboardText(displayItem);
      final payloadLines = payload.split('\n');

      expect(payload, '대표 표기: empty section anchor');
      expect(payload, isNot(contains('스트롱 번호:')));
      expect(payload, isNot(contains('언어:')));
      expect(payloadLines, isNot(contains('표기:')));
      expect(payload, isNot(contains('- ')));
      expect(payload, isNot(contains('비고:')));
    });

    test('formats only canonical detail fields without relation sections', () {
      const displayItem = WordDetailLikeDisplayItem(
        representativeSpelling: 'alpha',
        displayStrongNumber: 'G1',
        language: 'Greek',
        spellings: ['alpha'],
        transliterations: ['alfa'],
        pronunciationItems: [
          PronunciationValue(
            text: 'al-fah',
            notation: PronunciationNotation.ipaPhonemic,
          ),
        ],
        meanings: ['first'],
        note: 'visible note',
      );

      expect(
        buildWordDetailClipboardText(displayItem),
        [
          '대표 표기: alpha',
          '스트롱 번호: G1',
          '언어: Greek',
          '',
          '표기:',
          '- alpha',
          '',
          '음역:',
          '- alfa',
          '',
          '발음 표기:',
          '- /al-fah/',
          '',
          '표기 방식:',
          '- IPA — 음소 표기',
          '',
          '의미:',
          '- first',
          '',
          '비고:',
          'visible note',
        ].join('\n'),
      );
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
        expect(find.text('발음 표기'), findsOneWidget);
        expect(find.text('표기 방식'), findsOneWidget);
        expect(find.text('음역'), findsNothing);
        expect(find.text('hippopotamus'), findsNWidgets(2));
        expect(find.text('hippopotamus\nhippo'), findsNothing);
        expect(find.text('hippo'), findsNWidgets(2));
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
        expect(find.text('발음 표기'), findsNothing);
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
        expect(find.text(displayItem.representativeSpelling!), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
      'wraps detail rows but not action controls in a selection area',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WordInfoPanel(
                displayItem: const WordDetailLikeDisplayItem(
                  representativeSpelling: 'selection anchor',
                  meanings: ['selectable meaning'],
                ),
                onEdit: () {},
                onOpenDetail: () {},
              ),
            ),
          ),
        );

        final selectionArea = find.byType(SelectionArea);

        expect(selectionArea, findsOneWidget);
        expect(
          find.descendant(of: selectionArea, matching: find.text('대표 표기')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: selectionArea,
            matching: find.text('selectable meaning'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: selectionArea,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is SelectableText &&
                  widget.data == 'selectable meaning',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: selectionArea, matching: find.text('복사')),
          findsNothing,
        );
        expect(
          find.descendant(of: selectionArea, matching: find.text('편집')),
          findsNothing,
        );
        expect(
          find.descendant(
            of: selectionArea,
            matching: find.text('상세 작업 화면 열기'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'clarifies the full-detail action without exposing delete or graph actions',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WordInfoPanel(
                displayItem: WordDetailLikeDisplayItem(
                  representativeSpelling: 'Phase 20-M 확인 단어',
                ),
                onEdit: () {},
                onOpenDetail: () {},
              ),
            ),
          ),
        );

        expect(find.text('편집'), findsOneWidget);
        expect(find.text('복사'), findsOneWidget);
        expect(find.text('상세 작업 화면 열기'), findsOneWidget);
        expect(find.text('상세 화면에서 열기'), findsNothing);
        expect(
          find.byTooltip('삭제·그래프 보기 등 전체 작업용 상세 화면을 엽니다.'),
          findsOneWidget,
        );
        expect(find.text('삭제'), findsNothing);
        expect(find.text('그래프 보기'), findsNothing);
      },
    );

    testWidgets(
      'shows item copy actions only when the small-layout flag is enabled',
      (tester) async {
        const displayItem = WordDetailLikeDisplayItem(
          representativeSpelling: 'copy anchor',
          displayStrongNumber: 'G1',
          spellings: ['copy spelling'],
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: WordInfoPanel(displayItem: displayItem)),
          ),
        );

        expect(
          find.byKey(const ValueKey('word-info-copy-대표 표기-0')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('word-info-copy-표기-0')), findsNothing);
        expect(find.text('복사'), findsOneWidget);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: WordInfoPanel(
                displayItem: displayItem,
                showItemCopyActions: true,
              ),
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey('word-info-copy-대표 표기-0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('word-info-copy-스트롱 번호-0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('word-info-copy-표기-0')),
          findsOneWidget,
        );
        expect(find.text('복사'), findsOneWidget);
      },
    );

    testWidgets(
      'derives item copy exposure from the existing detail responsive decision',
      (tester) async {
        const displayItem = WordDetailLikeDisplayItem(
          representativeSpelling: 'responsive anchor',
          spellings: ['responsive spelling'],
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(500, 800)),
              child: WordDetailScreen(
                wordId: 'responsive-word',
                initialDisplayItem: displayItem,
              ),
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey('word-info-copy-대표 표기-0')),
          findsOneWidget,
        );
        expect(find.text('복사'), findsOneWidget);

        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(1000, 800)),
              child: WordDetailScreen(
                wordId: 'responsive-word',
                initialDisplayItem: displayItem,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.byKey(const ValueKey('word-info-copy-대표 표기-0')),
          findsNothing,
        );
        expect(find.text('복사'), findsOneWidget);
      },
    );

    testWidgets(
      'copies the current display item payload through the common panel action',
      (tester) async {
        final clipboardCalls = <MethodCall>[];
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        addTearDown(
          () =>
              messenger.setMockMethodCallHandler(SystemChannels.platform, null),
        );
        messenger.setMockMethodCallHandler(SystemChannels.platform, (
          call,
        ) async {
          if (call.method == 'Clipboard.setData') {
            clipboardCalls.add(call);
          }
          return null;
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: WordInfoPanel(
                displayItem: WordDetailLikeDisplayItem(
                  representativeSpelling: 'previous item',
                  meanings: ['previous meaning'],
                ),
              ),
            ),
          ),
        );
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: WordInfoPanel(
                displayItem: WordDetailLikeDisplayItem(
                  representativeSpelling: 'current item',
                  meanings: ['current meaning'],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('복사'));
        await tester.pump();

        expect(clipboardCalls, hasLength(1));
        expect(
          (clipboardCalls.single.arguments as Map<Object?, Object?>)['text'],
          ['대표 표기: current item', '', '의미:', '- current meaning'].join('\n'),
        );
        expect(
          (clipboardCalls.single.arguments as Map<Object?, Object?>)['text'],
          isNot(contains('previous item')),
        );
        expect(find.text('상세 정보를 복사했습니다.'), findsOneWidget);
      },
    );

    testWidgets(
      'copies exactly one scalar or list display value per item action',
      (tester) async {
        final clipboardCalls = <MethodCall>[];
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        addTearDown(
          () =>
              messenger.setMockMethodCallHandler(SystemChannels.platform, null),
        );
        messenger.setMockMethodCallHandler(SystemChannels.platform, (
          call,
        ) async {
          if (call.method == 'Clipboard.setData') {
            clipboardCalls.add(call);
          }
          return null;
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: WordInfoPanel(
                displayItem: WordDetailLikeDisplayItem(
                  representativeSpelling: 'single scalar',
                  spellings: ['first spelling', 'second spelling'],
                  meanings: ['first meaning'],
                ),
                showItemCopyActions: true,
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const ValueKey('word-info-copy-대표 표기-0')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('word-info-copy-표기-1')));
        await tester.pump();

        expect(clipboardCalls, hasLength(2));
        expect(
          (clipboardCalls[0].arguments as Map<Object?, Object?>)['text'],
          'single scalar',
        );
        expect(
          (clipboardCalls[1].arguments as Map<Object?, Object?>)['text'],
          'second spelling',
        );
        expect(
          (clipboardCalls[1].arguments as Map<Object?, Object?>)['text'],
          isNot(contains('표기')),
        );
        expect(
          (clipboardCalls[1].arguments as Map<Object?, Object?>)['text'],
          isNot(contains('\n')),
        );
        expect(
          (clipboardCalls[1].arguments as Map<Object?, Object?>)['text'],
          isNot(contains('first spelling')),
        );
        expect(find.text('상세 정보를 복사했습니다.'), findsWidgets);
      },
    );

    testWidgets('copies formatted pronunciation from the item action', (
      tester,
    ) async {
      final clipboardCalls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardCalls.add(call);
        }
        return null;
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WordInfoPanel(
              displayItem: WordDetailLikeDisplayItem(
                pronunciationItems: [
                  PronunciationValue(
                    text: 'ʔa.haˈva',
                    notation: PronunciationNotation.ipaPhonemic,
                  ),
                ],
              ),
              showItemCopyActions: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('word-info-copy-발음 표기-0')));
      await tester.pump();

      expect(clipboardCalls, hasLength(1));
      expect(
        (clipboardCalls.single.arguments as Map<Object?, Object?>)['text'],
        '/ʔa.haˈva/',
      );
    });

    testWidgets(
      'keeps repeated meanings and many spellings as separate copyable rows',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: WordInfoPanel(
                displayItem: WordDetailLikeDisplayItem(
                  representativeSpelling: 'many values',
                  spellings: [
                    'spelling 1',
                    'spelling 2',
                    'spelling 3',
                    'spelling 4',
                    'spelling 5',
                    'spelling 6',
                    'spelling 7',
                    'spelling 8',
                  ],
                  meanings: ['same meaning', 'same meaning', 'later meaning'],
                ),
                showItemCopyActions: true,
              ),
            ),
          ),
        );

        for (var index = 0; index < 8; index++) {
          expect(
            find.byKey(ValueKey('word-info-copy-표기-$index')),
            findsOneWidget,
          );
        }
        expect(find.text('same meaning'), findsNWidgets(2));
        expect(
          find.byKey(const ValueKey('word-info-copy-의미-0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('word-info-copy-의미-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('word-info-copy-의미-2')),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows failure feedback when clipboard write fails', (
      tester,
    ) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'clipboard-failed');
        }
        return null;
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WordInfoPanel(
              displayItem: WordDetailLikeDisplayItem(
                representativeSpelling: 'failure item',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('복사'));
      await tester.pump();

      expect(find.text('복사에 실패했습니다.'), findsOneWidget);
    });

    testWidgets('shows the common failure feedback when item copy fails', (
      tester,
    ) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'clipboard-failed');
        }
        return null;
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WordInfoPanel(
              displayItem: WordDetailLikeDisplayItem(
                representativeSpelling: 'item failure',
              ),
              showItemCopyActions: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('word-info-copy-대표 표기-0')));
      await tester.pump();

      expect(find.text('복사에 실패했습니다.'), findsOneWidget);
    });
  });
}
