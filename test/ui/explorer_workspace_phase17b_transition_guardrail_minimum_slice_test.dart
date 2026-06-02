import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 17-B production route transition guardrail minimum slice', () {
    const mainSourcePath = 'lib/main.dart';
    const homeSourcePath = 'lib/ui/home_screen.dart';

    late String mainSource;
    late String homeSource;

    setUpAll(() {
      mainSource = _readText(mainSourcePath);
      homeSource = _readText(homeSourcePath);
    });

    test('keeps HomeScreen as the production app home', () {
      expect(mainSource, contains("import 'ui/home_screen.dart';"));
      expect(mainSource, contains('class ReshetApp extends StatelessWidget'));
      expect(mainSource, contains('home: const HomeScreen()'));
      expect(mainSource, isNot(contains('main_explorer_workspace_preview')));
    });

    test('keeps the default explorer entry owned by WordExplorerScreen', () {
      expect(homeSource, contains("import 'word_explorer_screen.dart';"));
      expect(homeSource, contains('Navigator.push'));
      expect(homeSource, contains('MaterialPageRoute'));
      expect(
        homeSource,
        contains('WordExplorerScreen(initialWordId: normalizedWordId)'),
      );
    });

    test('does not mount ExplorerWorkspace from production entry files', () {
      const forbiddenWorkspaceMountMarkers = <String>[
        'ExplorerWorkspace(',
        "explorer_workspace/explorer_workspace.dart",
        'ExplorerWorkspaceState.fromPreviewInput',
      ];

      for (final entry in _productionEntrySources(
        mainSource: mainSource,
        homeSource: homeSource,
      ).entries) {
        for (final forbiddenMarker in forbiddenWorkspaceMountMarkers) {
          expect(
            entry.value,
            isNot(contains(forbiddenMarker)),
            reason:
                '${entry.key} must not mount ExplorerWorkspace as a '
                'production shell or route target: $forbiddenMarker.',
          );
        }
      }
    });

    test('keeps preview entrypoints outside production entry files', () {
      const forbiddenPreviewMarkers = <String>[
        'ExplorerWorkspacePreviewScreen',
        'ExplorerWorkspacePreviewInteractionHost',
        'ExplorerWorkspacePreviewAccessApp',
        'ExplorerWorkspacePreviewAccessRoot',
        'main_explorer_workspace_preview',
        'explorer_workspace_preview_screen.dart',
        'explorer_workspace_preview_interaction_host.dart',
      ];

      for (final entry in _productionEntrySources(
        mainSource: mainSource,
        homeSource: homeSource,
      ).entries) {
        for (final forbiddenMarker in forbiddenPreviewMarkers) {
          expect(
            entry.value,
            isNot(contains(forbiddenMarker)),
            reason:
                '${entry.key} must not connect preview-only workspace entry '
                'or host surfaces to production: $forbiddenMarker.',
          );
        }
      }
    });

    test('does not add named route wiring for ExplorerWorkspace', () {
      const forbiddenRouteWiringMarkers = <String>[
        'routes:',
        'onGenerateRoute',
        'onUnknownRoute',
        'initialRoute',
        'pushNamed',
        'pushReplacementNamed',
        'pushNamedAndRemoveUntil',
        'restorablePushNamed',
      ];

      for (final entry in _productionEntrySources(
        mainSource: mainSource,
        homeSource: homeSource,
      ).entries) {
        for (final forbiddenMarker in forbiddenRouteWiringMarkers) {
          expect(
            entry.value,
            isNot(contains(forbiddenMarker)),
            reason:
                '${entry.key} must not add named route wiring for '
                'ExplorerWorkspace transition: $forbiddenMarker.',
          );
        }
      }
    });
  });
}

String _readText(String path) {
  return File(path).readAsStringSync();
}

Map<String, String> _productionEntrySources({
  required String mainSource,
  required String homeSource,
}) {
  return <String, String>{
    'lib/main.dart': mainSource,
    'lib/ui/home_screen.dart': homeSource,
  };
}
