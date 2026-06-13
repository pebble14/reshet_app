import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 18-A HomeScreen large split shell', () {
    const mainSourcePath = 'lib/main.dart';
    const homeSourcePath = 'lib/ui/home_screen.dart';
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';
    const explorerWorkspaceSourcePath =
        'lib/ui/explorer_workspace/explorer_workspace.dart';
    const explorerWorkspaceContractSourcePath =
        'lib/ui/explorer_workspace/explorer_workspace_contract.dart';

    late String mainSource;
    late String homeSource;
    late String wordExplorerSource;
    late String explorerWorkspaceSource;
    late String explorerWorkspaceContractSource;

    setUpAll(() {
      mainSource = _readText(mainSourcePath);
      homeSource = _readText(homeSourcePath);
      wordExplorerSource = _readText(wordExplorerSourcePath);
      explorerWorkspaceSource = _readText(explorerWorkspaceSourcePath);
      explorerWorkspaceContractSource = _readText(
        explorerWorkspaceContractSourcePath,
      );
    });

    test(
      'keeps HomeScreen as app home while adding a large-screen explorer pane',
      () {
        expect(mainSource, contains('home: const HomeScreen()'));
        expect(homeSource, contains('LayoutBuilder('));
        expect(homeSource, contains('final homePane = Column('));
        expect(homeSource, contains('child: homePane'));
        expect(homeSource, contains('WordExplorerScreen('));
        expect(homeSource, contains('key: ValueKey('));
        expect(homeSource, contains('initialWordId:'));
        expect(homeSource, contains('_largeScreenExplorerWordId'));
      },
    );

    test('keeps small-screen detail and graph route entries available', () {
      expect(homeSource, contains('Navigator.push'));
      expect(homeSource, contains('MaterialPageRoute'));
      expect(homeSource, contains('await _openWordDetail(wordId);'));
      expect(
        homeSource,
        contains('await _openDefaultStrongWordDetail(item.wordId);'),
      );
      expect(homeSource, contains('_openDefaultStrongWordGraph(item.wordId)'));
      expect(homeSource, contains('WordGraphScreen(centerWordId: wordId)'));
    });

    test('does not mount the explorer pane in the small-width branch', () {
      final smallWidthBranch = _sourceBetween(
        homeSource,
        'if (!isLargeScreen) {',
        'return Row(',
      );

      expect(smallWidthBranch, contains('return homePane;'));
      expect(smallWidthBranch, isNot(contains('WordExplorerScreen(')));
      expect(
        smallWidthBranch,
        isNot(contains('ValueKey(_largeScreenExplorerWordId)')),
      );
    });

    test('uses a private replaceable default target without new public API', () {
      expect(
        homeSource,
        contains(
          "static const String _largeScreenDefaultExplorerWordId = 'H0001_0000';",
        ),
      );
      expect(
        homeSource,
        contains(
          'String _largeScreenExplorerWordId = _largeScreenDefaultExplorerWordId;',
        ),
      );
      expect(
        homeSource,
        isNot(contains('final String largeScreenDefaultExplorerWordId')),
      );
      expect(homeSource, isNot(contains('final String defaultExplorerWordId')));
    });

    test(
      'keeps ExplorerWorkspace out of production shell and route wiring',
      () {
        for (final entry in <String, String>{
          'lib/main.dart': mainSource,
          'lib/ui/home_screen.dart': homeSource,
        }.entries) {
          expect(
            entry.value,
            isNot(contains('ExplorerWorkspace(')),
            reason: '${entry.key} must not mount ExplorerWorkspace.',
          );
          expect(
            entry.value,
            isNot(contains('ExplorerWorkspacePreviewScreen')),
            reason: '${entry.key} must not connect preview shell.',
          );
          expect(
            entry.value,
            isNot(contains('ExplorerWorkspacePreviewInteractionHost')),
            reason: '${entry.key} must not connect preview host.',
          );
          expect(
            entry.value,
            isNot(contains('ExplorerWorkspaceState.fromPreviewInput')),
            reason: '${entry.key} must not promote preview state.',
          );
        }

        expect(explorerWorkspaceSource, contains('class ExplorerWorkspace'));
        expect(
          explorerWorkspaceContractSource,
          contains('class ExplorerWorkspaceState'),
        );
      },
    );

    test('keeps WordExplorerScreen as production owner', () {
      expect(wordExplorerSource, contains('late String _centerWordId;'));
      expect(wordExplorerSource, contains('String? _selectedWordId;'));
      expect(
        wordExplorerSource,
        contains('WordDetailLikeDisplayItem? _selectedWordDisplayItem;'),
      );
      expect(wordExplorerSource, contains('final WordRepository _repository'));
      expect(homeSource, isNot(contains('ExplorerWorkspaceState')));
    });

    test('keeps large-width pane update and small-width navigation split', () {
      expect(
        homeSource,
        contains('static const double _largeScreenSplitBreakpoint = 900.0;'),
      );
      expect(
        homeSource,
        contains(
          'final isLargeScreen = _isLargeScreenWidth(constraints.maxWidth);',
        ),
      );
      expect(homeSource, contains('if (!isLargeScreen)'));
      expect(homeSource, contains('return homePane;'));
      expect(
        homeSource,
        contains('_showWordInLargeScreenExplorerPane(item.wordId);'),
      );
      expect(homeSource, contains('_showWordInLargeScreenExplorerPane('));
      expect(homeSource, contains('wordId,'));
      expect(
        homeSource,
        contains('await _openDefaultStrongWordDetail(item.wordId);'),
      );
      expect(homeSource, contains('await _openWordDetail(wordId);'));
    });
  });
}

String _readText(String path) {
  return File(path).readAsStringSync();
}

String _sourceBetween(String source, String startMarker, String endMarker) {
  final start = source.indexOf(startMarker);
  expect(start, greaterThanOrEqualTo(0), reason: 'Missing $startMarker');

  final end = source.indexOf(endMarker, start);
  expect(end, greaterThan(start), reason: 'Missing $endMarker after marker.');

  return source.substring(start, end);
}
