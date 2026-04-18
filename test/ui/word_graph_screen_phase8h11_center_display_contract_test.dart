import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/domain/graph/graph_center_word_display_item.dart';

void main() {
  group('Phase 8-H-11 graph center display helper', () {
    testWidgets('renders center full display from typed contract fields', (
      tester,
    ) async {
      const displayItem = GraphCenterWordDisplayItem(
        wordId: 'T9000_H11_CENTER_HELPER',
        language: 'helper-language',
        displayStrongNumber: 'H77',
        representativeSpelling: 'helper-spelling',
        representativeTransliteration: 'helper-translit',
        representativePronunciation: 'helper-pron',
        primaryMeaning: 'helper meaning',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: _GraphCenterDisplayProbe(displayItem: displayItem),
        ),
      );

      expect(find.text('helper-language'), findsOneWidget);
      expect(find.text('H77'), findsOneWidget);
      expect(find.text('helper-spelling'), findsOneWidget);
      expect(find.text('helper-translit'), findsOneWidget);
      expect(find.text('helper-pron'), findsOneWidget);
      expect(find.text('helper meaning'), findsOneWidget);
    });
  });
}

class _GraphCenterDisplayProbe extends StatelessWidget {
  final GraphCenterWordDisplayItem displayItem;

  const _GraphCenterDisplayProbe({required this.displayItem});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Text(displayItem.language),
          Text(displayItem.displayStrongNumber),
          Text(displayItem.representativeSpelling),
          Text(displayItem.representativeTransliteration),
          Text(displayItem.representativePronunciation),
          Text(displayItem.primaryMeaning),
        ],
      ),
    );
  }
}
