import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/domain/graph/graph_visible_node.dart';

void main() {
  group('Phase 8-H-28 graph UI state visible node contract', () {
    test('keeps fallback display on the visible node carrier fields', () {
      const spellingNode = GraphVisibleNode(
        wordId: 'H28_VISIBLE_NODE_1',
        fallbackSpelling: 'visible spelling',
        fallbackStrongNumber: 'H28',
        fallbackTransliteration: 'visible transliteration',
      );
      const strongNode = GraphVisibleNode(
        wordId: 'H28_VISIBLE_NODE_2',
        fallbackSpelling: ' ',
        fallbackStrongNumber: 'H2828',
        fallbackTransliteration: 'visible transliteration',
      );
      const idNode = GraphVisibleNode(
        wordId: 'H28_VISIBLE_NODE_3',
        fallbackSpelling: '',
        fallbackStrongNumber: '',
        fallbackTransliteration: '',
      );

      expect(spellingNode.fallbackDisplayName, 'visible spelling');
      expect(strongNode.fallbackDisplayName, 'H2828');
      expect(idNode.fallbackDisplayName, 'H28_VISIBLE_NODE_3');
    });

    test('compares every visible node fallback carrier field', () {
      const left = GraphVisibleNode(
        wordId: 'H28_VISIBLE_NODE_COMPARE',
        fallbackSpelling: 'visible spelling',
        fallbackStrongNumber: 'H28',
        fallbackTransliteration: 'visible transliteration',
      );
      const right = GraphVisibleNode(
        wordId: 'H28_VISIBLE_NODE_COMPARE',
        fallbackSpelling: 'visible spelling',
        fallbackStrongNumber: 'H28',
        fallbackTransliteration: 'visible transliteration',
      );
      const differentTransliteration = GraphVisibleNode(
        wordId: 'H28_VISIBLE_NODE_COMPARE',
        fallbackSpelling: 'visible spelling',
        fallbackStrongNumber: 'H28',
        fallbackTransliteration: 'different transliteration',
      );

      expect(left, right);
      expect(left, isNot(differentTransliteration));
    });
  });
}
