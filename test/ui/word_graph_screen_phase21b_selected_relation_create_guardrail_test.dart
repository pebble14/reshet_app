import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 21-B selected relation create guardrail', () {
    late String graphSource;
    late String createWordFlowSource;
    late String createRelationDialogSource;
    late String addRelationFlowSource;
    late String selectWordDialogSource;

    setUpAll(() {
      graphSource = File('lib/ui/word_graph_screen.dart').readAsStringSync();
      createWordFlowSource = _sourceBetween(
        graphSource,
        'Future<void> _showCreateWordFlow() async {',
        'Future<CreateWordPayload?> _showCreateWordDialog() async {',
      );
      createRelationDialogSource = _sourceBetween(
        graphSource,
        'Future<CreateRelationPayload?> _showCreateRelationDialog({',
        'void _fitToView(_GraphLayoutData layout) {',
      );
      addRelationFlowSource = _sourceBetween(
        graphSource,
        'Future<void> _showAddRelationFlow() async {',
        'Future<GraphRelationAddSearchResultItem?> _showSelectWordDialog({',
      );
      selectWordDialogSource = _sourceBetween(
        graphSource,
        'Future<GraphRelationAddSearchResultItem?> _showSelectWordDialog({',
        'String _graphRelationSearchResultLabel(',
      );
    });

    test('blocks direct relation add when no graph node is selected', () {
      final selectedSourceIndex = addRelationFlowSource.indexOf(
        "final relationSourceWordId = (_selectedWordId ?? '').trim();",
      );
      final emptyGuardIndex = addRelationFlowSource.indexOf(
        'if (relationSourceWordId.isEmpty)',
      );
      final messageIndex = addRelationFlowSource.indexOf(
        '관계를 추가할 단어를 그래프에서 먼저 선택하세요.',
      );
      final searchDialogIndex = addRelationFlowSource.indexOf(
        '_showSelectWordDialog(',
      );

      expect(selectedSourceIndex, greaterThanOrEqualTo(0));
      expect(emptyGuardIndex, greaterThan(selectedSourceIndex));
      expect(messageIndex, greaterThan(emptyGuardIndex));
      expect(searchDialogIndex, greaterThan(messageIndex));
    });

    test(
      'uses selected source for direct relation duplicate check and write',
      () {
        expect(addRelationFlowSource, contains('_showSelectWordDialog('));
        expect(
          addRelationFlowSource,
          contains('sourceWordId: relationSourceWordId'),
        );
        expect(
          addRelationFlowSource,
          contains('findExistingRelationIdBySignature('),
        );
        final duplicateCheckIndex = addRelationFlowSource.indexOf(
          'findExistingRelationIdBySignature(',
        );
        final duplicateSourceIndex = addRelationFlowSource.indexOf(
          'relationSourceWordId,',
          duplicateCheckIndex,
        );

        expect(duplicateSourceIndex, greaterThan(duplicateCheckIndex));
        expect(
          addRelationFlowSource,
          contains('wordId1: relationSourceWordId'),
        );
        expect(addRelationFlowSource, contains('relationSourceWordId,'));
        expect(
          addRelationFlowSource,
          isNot(contains('wordId1: _centerWordId')),
        );
      },
    );

    test(
      'uses source word for relation dialog direction and search exclusion',
      () {
        expect(
          createRelationDialogSource,
          contains('required String sourceWordId'),
        );
        expect(
          createRelationDialogSource,
          contains('centerWordId: sourceWordId'),
        );
        expect(createRelationDialogSource, contains('wordId1: sourceWordId'));

        expect(
          selectWordDialogSource,
          contains('required String sourceWordId'),
        );
        expect(
          selectWordDialogSource,
          contains('.where((item) => item.wordId != sourceWordId)'),
        );
        expect(
          selectWordDialogSource,
          isNot(contains('item.wordId != _centerWordId')),
        );
      },
    );

    test('keeps create-word relation option selected-source based', () {
      expect(
        createWordFlowSource,
        contains(
          "final relationSourceWordId = (_selectedWordId ?? '').trim();",
        ),
      );
      expect(createWordFlowSource, contains('관계를 추가할 단어를 그래프에서 먼저 선택하세요.'));
      expect(
        createWordFlowSource,
        contains('sourceWordId: relationSourceWordId'),
      );
      expect(
        createWordFlowSource,
        contains('findExistingRelationIdBySignature('),
      );
      final duplicateCheckIndex = createWordFlowSource.indexOf(
        'findExistingRelationIdBySignature(',
      );
      final duplicateSourceIndex = createWordFlowSource.indexOf(
        'relationSourceWordId,',
        duplicateCheckIndex,
      );

      expect(duplicateSourceIndex, greaterThan(duplicateCheckIndex));
      expect(createWordFlowSource, contains('wordId1: relationSourceWordId'));
      expect(
        createWordFlowSource,
        isNot(
          contains(
            'findExistingRelationIdBySignature(\n            _centerWordId',
          ),
        ),
      );
      expect(createWordFlowSource, isNot(contains('wordId1: _centerWordId')));
    });

    test(
      'keeps relation edit and delete paths in graph relation detail dialog',
      () {
        expect(graphSource, contains('await _repository.updateRelation('));
        expect(
          graphSource,
          contains('await _repository.deleteRelation(info.relationId)'),
        );
        expect(graphSource, isNot(contains('DeleteWordCommand(')));
      },
    );
  });
}

String _sourceBetween(String source, String start, String end) {
  final startIndex = source.indexOf(start);
  final endIndex = source.indexOf(end, startIndex + start.length);

  if (startIndex < 0 || endIndex < 0) {
    throw StateError('Cannot find source boundary: $start -> $end');
  }

  return source.substring(startIndex, endIndex);
}
