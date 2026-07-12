import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/ui/explorer_workspace/explorer_workspace_preview_screen.dart';

void main() {
  group('Phase 4-A ExplorerWorkspace production-hidden preview wrapper', () {
    testWidgets('renders explorer entry semantic contract only', (
      tester,
    ) async {
      await _pumpPreview(
        tester,
        ExplorerWorkspacePreviewScreen.forExplorerEntry(
          initialWordId: '  W_PHASE4A_EXPLORER_001  ',
        ),
      );

      expect(find.text('StrongRail'), findsOneWidget);
      expect(find.text('GlobalSearch'), findsOneWidget);
      expect(find.text('GraphPanel'), findsOneWidget);
      expect(find.text('DetailPane'), findsOneWidget);
      expect(find.text('AddWordFixedAction'), findsOneWidget);
      expect(find.text('center: none'), findsOneWidget);
      expect(find.text('target: W_PHASE4A_EXPLORER_001'), findsOneWidget);
      expect(find.text('selected: W_PHASE4A_EXPLORER_001'), findsNWidgets(2));
      expect(find.text('preset: balanced'), findsOneWidget);
      expect(find.text('origin: routeAlias'), findsOneWidget);
    });

    testWidgets('renders graph route alias without selected or detail target', (
      tester,
    ) async {
      await _pumpPreview(
        tester,
        ExplorerWorkspacePreviewScreen.forGraphRouteAlias(
          centerWordId: '  W_PHASE4A_GRAPH_001  ',
        ),
      );

      expect(find.text('center: W_PHASE4A_GRAPH_001'), findsOneWidget);
      expect(find.text('target: none'), findsOneWidget);
      expect(find.text('selected: none'), findsNWidgets(2));
      expect(find.text('preset: graphFocused'), findsOneWidget);
      expect(find.text('origin: routeAlias'), findsOneWidget);
    });

    testWidgets('renders detail route alias without graph center ownership', (
      tester,
    ) async {
      await _pumpPreview(
        tester,
        ExplorerWorkspacePreviewScreen.forDetailRouteAlias(
          wordId: '  W_PHASE4A_DETAIL_001  ',
        ),
      );

      expect(find.text('center: none'), findsOneWidget);
      expect(find.text('target: W_PHASE4A_DETAIL_001'), findsOneWidget);
      expect(find.text('selected: W_PHASE4A_DETAIL_001'), findsNWidgets(2));
      expect(find.text('preset: detailFocused'), findsOneWidget);
      expect(find.text('origin: routeAlias'), findsOneWidget);
    });

    test('rejects empty semantic input instead of creating dummy ids', () {
      expect(
        () => ExplorerWorkspacePreviewScreen.forExplorerEntry(
          initialWordId: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () =>
            ExplorerWorkspacePreviewScreen.forGraphRouteAlias(centerWordId: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ExplorerWorkspacePreviewScreen.forDetailRouteAlias(wordId: '\t'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Phase 4-A source-level production isolation', () {
    const previewSourcePath =
        'lib/ui/explorer_workspace/explorer_workspace_preview_screen.dart';
    const mainSourcePath = 'lib/main.dart';
    const homeSourcePath = 'lib/ui/home_screen.dart';
    late String previewSource;
    late String mainSource;
    late String homeSource;

    setUpAll(() {
      previewSource = File(previewSourcePath).readAsStringSync();
      mainSource = File(mainSourcePath).readAsStringSync();
      homeSource = File(homeSourcePath).readAsStringSync();
    });

    test(
      'preview wrapper does not own production screen or repository reads',
      () {
        const forbiddenReferences = <String>[
          'WordExplorerScreen',
          'WordGraphScreen',
          'WordDetailScreen',
          'WordInfoPanel',
          'WordRepository',
          '../data/repositories/',
          'data/repositories',
          'word_repository.dart',
          'getVisibleGraphData',
          'getWordDetailLikeDisplayItem',
          'getGraphCenterWordDisplayItem',
          'probeExistingWordIds',
        ];

        for (final forbiddenReference in forbiddenReferences) {
          expect(
            previewSource,
            isNot(contains(forbiddenReference)),
            reason:
                'Preview wrapper must not own production screen or read '
                'boundary: $forbiddenReference.',
          );
        }
      },
    );

    test('preview wrapper stays a stateless semantic host', () {
      const forbiddenOwnerMarkers = <String>[
        'StatefulWidget',
        'State<',
        'setState',
        'initState',
        'dispose',
        'WordNavigationHistory',
        'Navigator',
        'MaterialPageRoute',
        'PageRouteBuilder',
        'pushNamed',
        'pushReplacement',
        'pushAndRemoveUntil',
        'onGenerateRoute',
        'routes:',
      ];

      for (final forbiddenMarker in forbiddenOwnerMarkers) {
        expect(
          previewSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'Preview wrapper must not become an owner or route surface: '
              '$forbiddenMarker.',
        );
      }
    });

    test('preview wrapper does not create dummy ids or display items', () {
      const forbiddenDummyMarkers = <String>[
        'dummy',
        'fallback',
        'WordDetailLikeDisplayItem',
        'GraphCenterWordDisplayItem',
        'displayItem',
        'W_PHASE',
      ];

      for (final forbiddenMarker in forbiddenDummyMarkers) {
        expect(
          previewSource,
          isNot(contains(forbiddenMarker)),
          reason:
              'Preview wrapper must use caller-provided semantic input only: '
              '$forbiddenMarker.',
        );
      }
    });

    test('production entry does not reference preview wrapper', () {
      for (final productionSource in [mainSource, homeSource]) {
        expect(
          productionSource,
          isNot(contains('ExplorerWorkspacePreviewScreen')),
        );
        expect(
          productionSource,
          isNot(contains('explorer_workspace_preview_screen.dart')),
        );
      }

      expect(mainSource, matches(RegExp(r'home:\s*HomeScreen\s*\(')));
    });
  });
}

Future<void> _pumpPreview(
  WidgetTester tester,
  ExplorerWorkspacePreviewScreen previewScreen,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        textTheme: const TextTheme(
          titleMedium: TextStyle(fontSize: 9),
          bodySmall: TextStyle(fontSize: 7),
          labelLarge: TextStyle(fontSize: 8),
        ),
      ),
      home: previewScreen,
    ),
  );
}
