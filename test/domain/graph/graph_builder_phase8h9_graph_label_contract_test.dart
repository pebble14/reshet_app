import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/data/models/word.dart';
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/domain/graph/graph_build_options.dart';
import 'package:reshet_app/domain/graph/graph_builder.dart';
import 'package:reshet_app/domain/graph/graph_word_label_display_item.dart';

void main() {
  group('Phase 8-H-9 graph builder label contract first slice', () {
    test('builds graph node labels from the typed label contract first', () {
      const centerWordId = 'T9000_H9_BUILDER_CENTER';
      const childWordId = 'T9000_H9_BUILDER_CHILD';
      final builder = GraphBuilder();
      final result = builder.buildMergedVisibleGraphData(
        options: GraphBuildOptions(centerWordId: centerWordId),
        centerWord: Word(id: centerWordId, spelling1: 'legacy-center-title'),
        baseWords: [Word(id: childWordId, spelling1: 'legacy-child-title')],
        wordLabels: const [
          GraphWordLabelDisplayItem(
            wordId: centerWordId,
            representativeSpelling: 'representative-center-title',
            representativeTransliteration: 'representative-center-translit',
            displayStrongNumber: '',
          ),
          GraphWordLabelDisplayItem(
            wordId: childWordId,
            representativeSpelling: 'representative-child-title',
            representativeTransliteration: 'representative-child-translit',
            displayStrongNumber: 'H42',
          ),
        ],
        baseRelationEdges: [
          WordRelationEdgeInfo(
            relationId: 1,
            wordId1: centerWordId,
            wordId2: childWordId,
            otherWordId: childWordId,
            directionCode: 'unknown',
            centerRelativeDirection: 'unknown',
            relationType: 'translation',
          ),
        ],
      );

      expect(
        result.viewData.nodeById(centerWordId)!.label,
        'representative-center-title',
      );
      expect(
        result.viewData.nodeById(childWordId)!.label,
        'representative-child-title',
      );
      expect(result.connectedWords.single.id, childWordId);
      expect(
        result.wordLabels.singleWhere((label) => label.wordId == childWordId),
        const GraphWordLabelDisplayItem(
          wordId: childWordId,
          representativeSpelling: 'representative-child-title',
          representativeTransliteration: 'representative-child-translit',
          displayStrongNumber: 'H42',
        ),
      );
    });

    test('uses display strong number as graph builder label fallback', () {
      const centerWordId = 'T9000_H9_BUILDER_STRONG_CENTER';
      const childWordId = 'T9000_H9_BUILDER_STRONG_CHILD';
      final builder = GraphBuilder();
      final result = builder.buildMergedVisibleGraphData(
        options: GraphBuildOptions(centerWordId: centerWordId),
        centerWord: Word(id: centerWordId, spelling1: 'legacy-center-title'),
        baseWords: [Word(id: childWordId, spelling1: 'legacy-child-title')],
        wordLabels: const [
          GraphWordLabelDisplayItem(
            wordId: centerWordId,
            representativeSpelling: 'representative-center-title',
            representativeTransliteration: '',
            displayStrongNumber: '',
          ),
          GraphWordLabelDisplayItem(
            wordId: childWordId,
            representativeSpelling: '',
            representativeTransliteration: '',
            displayStrongNumber: 'H88',
          ),
        ],
        baseRelationEdges: [
          WordRelationEdgeInfo(
            relationId: 2,
            wordId1: centerWordId,
            wordId2: childWordId,
            otherWordId: childWordId,
            directionCode: 'unknown',
            centerRelativeDirection: 'unknown',
            relationType: 'translation',
          ),
        ],
      );

      expect(result.viewData.nodeById(childWordId)!.label, 'H88');
    });
  });
}
