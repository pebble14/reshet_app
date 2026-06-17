import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 21-D selected node delete guardrail', () {
    late String deleteFlowSource;
    late String detailOpenGraphSource;
    late String explorerDeleteCallbackSource;
    late String explorerDeleteRecoverySource;
    late String explorerSource;
    late String graphSource;
    late String graphWidgetSource;
    late String splitBodySource;

    setUpAll(() {
      graphSource = File('lib/ui/word_graph_screen.dart').readAsStringSync();
      graphWidgetSource = _sourceBetween(
        graphSource,
        'class WordGraphScreen extends StatefulWidget {',
        'class _WordGraphScreenState extends State<WordGraphScreen> {',
      );
      deleteFlowSource = _sourceBetween(
        graphSource,
        'Future<void> _confirmDeleteSelectedWord() async {',
        'Future<void> _showCreateWordFlow() async {',
      );

      explorerSource = File(
        'lib/ui/word_explorer_screen.dart',
      ).readAsStringSync();
      splitBodySource = _sourceBetween(
        explorerSource,
        'Widget _buildResizableExplorerBody() {',
        'Widget _buildDetailPane() {',
      );
      explorerDeleteCallbackSource = _sourceBetween(
        explorerSource,
        'Future<void> _handleGraphDeletedSelectedWord(',
        'Future<void> _handleDeletedSelectedWord({required bool wasCenterWord}) '
            'async {',
      );
      explorerDeleteRecoverySource = _sourceBetween(
        explorerSource,
        'Future<void> _handleDeletedSelectedWord({required bool wasCenterWord}) '
            'async {',
        'void _clearSelectedWordPanel({bool refreshGraph = false}) {',
      );

      final detailSource = File(
        'lib/ui/word_detail_screen.dart',
      ).readAsStringSync();
      detailOpenGraphSource = _sourceBetween(
        detailSource,
        'Future<void> _openGraph() async {',
        'Future<void> _confirmDelete() async {',
      );
    });

    test(
      'exposes selected-word delete on the existing graph action surface',
      () {
        expect(
          graphWidgetSource,
          contains(
            'final WordGraphSelectedWordDeletedCallback? onDeletedSelectedWord;',
          ),
        );
        expect(graphSource, contains("tooltip: '선택 단어 삭제'"));
        expect(graphSource, contains('icon: const Icon(Icons.delete_outline)'));
        expect(graphSource, contains('onPressed: _confirmDeleteSelectedWord'));
      },
    );

    test(
      'uses selected word id and blocks writes when no node is selected',
      () {
        final selectedWordIndex = deleteFlowSource.indexOf(
          "final selectedWordId = (_selectedWordId ?? '').trim();",
        );
        final emptyGuardIndex = deleteFlowSource.indexOf(
          'if (selectedWordId.isEmpty)',
        );
        final relationCountIndex = deleteFlowSource.indexOf(
          '_repository.countRelationsForWord(',
        );
        final deleteCommandIndex = deleteFlowSource.indexOf(
          'DeleteWordCommand(wordId: selectedWordId)',
        );

        expect(selectedWordIndex, greaterThanOrEqualTo(0));
        expect(emptyGuardIndex, greaterThan(selectedWordIndex));
        expect(relationCountIndex, greaterThan(emptyGuardIndex));
        expect(deleteCommandIndex, greaterThan(relationCountIndex));
        expect(
          deleteFlowSource,
          isNot(contains('DeleteWordCommand(wordId: _centerWordId)')),
        );
      },
    );

    test(
      'keeps relation count, confirm, write service, and graph cache order',
      () {
        final relationCountIndex = deleteFlowSource.indexOf(
          '_repository.countRelationsForWord(',
        );
        final dialogIndex = deleteFlowSource.indexOf('showDialog<bool>');
        final confirmedGuardIndex = deleteFlowSource.indexOf(
          'if (confirmed != true) return;',
        );
        final writeServiceIndex = deleteFlowSource.indexOf(
          '_wordWriteService.execute(',
        );
        final cacheClearIndex = deleteFlowSource.indexOf(
          'WordGraphDataCache.clear()',
        );

        expect(relationCountIndex, greaterThanOrEqualTo(0));
        expect(dialogIndex, greaterThan(relationCountIndex));
        expect(confirmedGuardIndex, greaterThan(dialogIndex));
        expect(writeServiceIndex, greaterThan(confirmedGuardIndex));
        expect(cacheClearIndex, greaterThan(writeServiceIndex));
      },
    );

    test('separates center and peripheral delete recovery paths', () {
      expect(
        deleteFlowSource,
        contains('final wasCenterWord = selectedWordId == _centerWordId;'),
      );
      expect(deleteFlowSource, contains('widget.onDeletedSelectedWord'));
      expect(
        deleteFlowSource,
        contains('WordDetailDeletedResult(wordId: selectedWordId)'),
      );
      expect(
        deleteFlowSource,
        contains('setState(() => _selectedWordId = null);'),
      );
      expect(deleteFlowSource, contains('widget.onClearSelection?.call();'));
      expect(deleteFlowSource, contains('await _loadConnectedWords();'));
    });

    test('keeps explorer as result interpreter instead of delete executor', () {
      expect(
        splitBodySource,
        contains('onDeletedSelectedWord: _handleGraphDeletedSelectedWord'),
      );
      expect(
        explorerDeleteCallbackSource,
        contains(
          'await _handleDeletedSelectedWord(wasCenterWord: wasCenterWord);',
        ),
      );
      expect(explorerSource, contains('_resolveFallbackCenterWordId('));
      expect(
        explorerSource,
        contains('_repository.getStrongWordsMap(limit: 12)'),
      );
      expect(
        explorerDeleteRecoverySource,
        contains(
          'await _selectWord(fallbackCenterWordId, changeCenterWord: true)',
        ),
      );
      expect(explorerSource, isNot(contains('DeleteWordCommand')));
      expect(explorerSource, isNot(contains('WordWriteService')));
    });

    test(
      'lets detail route close when its graph route deletes the detail word',
      () {
        expect(
          detailOpenGraphSource,
          contains(
            'final graphResult = await Navigator.push<WordDetailRouteResult>(',
          ),
        );
        expect(
          detailOpenGraphSource,
          contains('if (graphResult is WordDetailDeletedResult &&'),
        );
        expect(
          detailOpenGraphSource,
          contains('Navigator.pop(context, graphResult);'),
        );
      },
    );

    test('does not remove relation edit or delete paths from graph dialog', () {
      expect(graphSource, contains('await _repository.updateRelation('));
      expect(
        graphSource,
        contains('await _repository.deleteRelation(info.relationId)'),
      );
    });
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
