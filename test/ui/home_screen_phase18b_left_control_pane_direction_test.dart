import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 18-B HomeScreen left control pane direction', () {
    const homeSourcePath = 'lib/ui/home_screen.dart';
    const wordExplorerSourcePath = 'lib/ui/word_explorer_screen.dart';

    late String homeSource;
    late String wordExplorerSource;
    late String smallWidthBranch;
    late String largeWidthBranch;
    late String homeScreenWidgetSource;
    late String wordExplorerFieldSource;

    setUpAll(() {
      homeSource = _readText(homeSourcePath);
      wordExplorerSource = _readText(wordExplorerSourcePath);
      smallWidthBranch = _sourceBetween(
        homeSource,
        'if (!isLargeScreen) {',
        'return Row(',
      );
      largeWidthBranch = _sourceBetween(
        homeSource,
        'return Row(',
        '              },',
      );
      homeScreenWidgetSource = _sourceBetween(
        homeSource,
        'class HomeScreen extends StatefulWidget {',
        '/// HomeScreen',
      );
      wordExplorerFieldSource = _sourceBetween(
        wordExplorerSource,
        'class _WordExplorerScreenState extends State<WordExplorerScreen> {',
        'void initState() {',
      );
    });

    test('keeps the large-screen Home pane at the compact control width', () {
      expect(
        homeSource,
        contains(
          'static const double _largeScreenStrongControlSurfaceWidth = 160.0;',
        ),
      );
      expect(
        largeWidthBranch,
        contains('width: _largeScreenStrongControlSurfaceWidth'),
      );
      expect(
        largeWidthBranch,
        isNot(contains('Expanded(flex: 2, child: homePane)')),
      );
    });

    test(
      'widens the large-screen WordExplorerScreen pane after Phase 18-A',
      () {
        expect(largeWidthBranch, contains('flex: 6'));
        expect(largeWidthBranch, isNot(contains('flex: 5')));
        expect(largeWidthBranch, contains('WordExplorerScreen('));
        expect(
          largeWidthBranch,
          contains('key: ValueKey(_largeScreenExplorerWordId)'),
        );
        expect(
          largeWidthBranch,
          contains('initialWordId: _largeScreenExplorerWordId'),
        );
      },
    );

    test('keeps the small-screen branch free of embedded explorer panes', () {
      expect(smallWidthBranch, contains('return homePane;'));
      expect(smallWidthBranch, isNot(contains('WordExplorerScreen(')));
      expect(smallWidthBranch, isNot(contains('ExplorerWorkspace(')));
    });

    test('keeps ExplorerWorkspace out of the production Home shell', () {
      expect(homeSource, isNot(contains('ExplorerWorkspace(')));
      expect(homeSource, isNot(contains('ExplorerWorkspaceState')));
      expect(homeSource, isNot(contains('ExplorerWorkspacePreviewScreen')));
      expect(
        homeSource,
        isNot(contains('ExplorerWorkspacePreviewInteractionHost')),
      );
    });

    test('keeps the temporary large-screen default target private', () {
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
        homeScreenWidgetSource,
        isNot(contains('largeScreenDefaultExplorerWordId')),
      );
      expect(homeScreenWidgetSource, isNot(contains('defaultExplorerWordId')));
    });

    test('keeps WordExplorerScreen as the production owner state', () {
      expect(wordExplorerFieldSource, contains('late String _centerWordId;'));
      expect(wordExplorerFieldSource, contains('String? _selectedWordId;'));
      expect(
        wordExplorerFieldSource,
        contains('WordDetailLikeDisplayItem? _selectedWordDisplayItem;'),
      );
      expect(
        wordExplorerFieldSource,
        contains('final WordRepository _repository'),
      );
      expect(homeSource, isNot(contains('late String _centerWordId;')));
      expect(homeSource, isNot(contains('String? _selectedWordId;')));
      expect(homeSource, isNot(contains('ExplorerWorkspaceState')));
    });

    test(
      'does not add reads, queries, or public contracts in the split shell',
      () {
        expect(largeWidthBranch, isNot(contains('_repository.')));
        expect(largeWidthBranch, isNot(contains('DatabaseService.')));
        expect(largeWidthBranch, isNot(contains('DataSource')));
        expect(largeWidthBranch, isNot(contains('DTO')));
        expect(largeWidthBranch, isNot(contains('DisplayItem')));
        expect(
          homeScreenWidgetSource,
          equalsIgnoringWhitespace('''
          class HomeScreen extends StatefulWidget {
            const HomeScreen({super.key});

            @override
            State<HomeScreen> createState() => _HomeScreenState();
          }
          '''),
        );
      },
    );
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
