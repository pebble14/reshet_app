import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/data/models/word.dart';
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/domain/graph/graph_build_options.dart';
import 'package:reshet_app/domain/graph/graph_builder.dart';
import 'package:reshet_app/domain/graph/graph_visible_word.dart';

void main() {
  group('Phase 8-H-26 graph visible word carrier contract', () {
    test('keeps expansion and +N more calculation on the minimal carrier', () {
      const centerWordId = 'T9000_H26_BUILDER_CENTER';
      const sourceWordId = 'T9000_H26_BUILDER_SOURCE';
      final depthTwoWords = List<GraphVisibleWord>.generate(
        7,
        (index) => GraphVisibleWord(
          wordId: 'T9000_H26_BUILDER_DEPTH2_$index',
          fallbackSpelling: 'depth-$index',
          fallbackStrongNumber: '',
          fallbackTransliteration: '',
        ),
      );
      final builder = GraphBuilder();

      final result = builder.buildMergedVisibleGraphData(
        options: GraphBuildOptions(
          centerWordId: centerWordId,
          maxDepth: 2,
          maxNodes: 50,
        ),
        centerWord: Word(id: centerWordId, spelling1: 'center'),
        baseWords: const [
          GraphVisibleWord(
            wordId: sourceWordId,
            fallbackSpelling: 'source',
            fallbackStrongNumber: '',
            fallbackTransliteration: '',
          ),
        ],
        baseRelationEdges: [
          WordRelationEdgeInfo(
            relationId: 1,
            wordId1: centerWordId,
            wordId2: sourceWordId,
            otherWordId: sourceWordId,
            directionCode: 'unknown',
            centerRelativeDirection: 'unknown',
            relationType: 'translation',
          ),
        ],
        expansionDataBySourceId: {
          sourceWordId: (
            connectedWords: depthTwoWords,
            wordLabels: const [],
            relationEdges: [
              for (var index = 0; index < depthTwoWords.length; index++)
                WordRelationEdgeInfo(
                  relationId: index + 10,
                  wordId1: sourceWordId,
                  wordId2: depthTwoWords[index].wordId,
                  otherWordId: depthTwoWords[index].wordId,
                  directionCode: 'unknown',
                  centerRelativeDirection: 'unknown',
                  relationType: 'translation',
                ),
            ],
          ),
        },
      );

      final visibleDepthTwoNodes = result.viewData.nodes
          .where(
            (node) =>
                node.depth == 2 &&
                !node.isPlaceholderMoreNode &&
                node.expansionSourceId == sourceWordId,
          )
          .toList(growable: false);
      final placeholderNode = result.viewData.nodes.singleWhere(
        (node) =>
            node.isPlaceholderMoreNode &&
            node.placeholderSourceWordId == sourceWordId,
      );

      expect(visibleDepthTwoNodes, hasLength(6));
      expect(placeholderNode.label, '+1 more');
      expect(placeholderNode.hiddenCount, 1);
      expect(
        result.connectedWords.map((word) => word.id),
        contains(sourceWordId),
      );
      expect(
        result.connectedWords.map((word) => word.id),
        isNot(contains(depthTwoWords.last.wordId)),
      );
    });
  });
}
