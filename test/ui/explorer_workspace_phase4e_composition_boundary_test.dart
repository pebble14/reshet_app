import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 4-E ExplorerWorkspace preview-only composition boundary', () {
    late Map<String, String> productionSources;
    late Map<String, String> previewSources;
    late String mainSource;
    late String homeSource;
    late String wordExplorerSource;
    late String uxDocument;
    late String changelog;

    setUpAll(() {
      productionSources = _readDartSources(
        'lib',
        excludeNormalizedPrefix: 'lib/ui/explorer_workspace/',
        excludeNormalizedPaths: const {
          'lib/main_explorer_workspace_preview.dart',
        },
      );
      previewSources = _readDartSources('lib/ui/explorer_workspace');
      mainSource = _readText('lib/main.dart');
      homeSource = _readText('lib/ui/home_screen.dart');
      wordExplorerSource = _readText('lib/ui/word_explorer_screen.dart');
      uxDocument = _readText('docs/ux/explorer_workspace_unification.md');
      changelog = _readText('docs/logs/CHANGELOG.md');
    });

    test('production import tree does not reference preview composition', () {
      const forbiddenPreviewMarkers = <String>[
        'ExplorerWorkspacePreviewScreen',
        'ExplorerWorkspacePreviewInteractionHost',
        'ExplorerWorkspacePreviewInput',
        'ExplorerWorkspaceHistoryEntry',
        'explorer_workspace_preview_screen.dart',
        'explorer_workspace_preview_interaction_host.dart',
        'ui/explorer_workspace/',
        'explorer_workspace/',
      ];

      for (final source in productionSources.entries) {
        for (final forbiddenMarker in forbiddenPreviewMarkers) {
          expect(
            source.value,
            isNot(contains(forbiddenMarker)),
            reason:
                'Production import tree must not reference preview '
                'composition: ${source.key} -> $forbiddenMarker.',
          );
        }
      }
    });

    test(
      'production route default and explorer owner remain outside preview',
      () {
        expect(mainSource, contains('home: const HomeScreen()'));
        expect(homeSource, contains('WordExplorerScreen('));
        expect(homeSource, contains('Navigator.push'));
        expect(homeSource, contains('MaterialPageRoute'));

        expect(
          wordExplorerSource,
          contains('class WordExplorerScreen extends StatefulWidget'),
        );
        expect(wordExplorerSource, contains('WordRepository'));
        expect(wordExplorerSource, contains('WordGraphScreen('));
        expect(wordExplorerSource, contains('WordDetailScreen('));

        for (final source in [mainSource, homeSource, wordExplorerSource]) {
          expect(source, isNot(contains('ExplorerWorkspacePreviewScreen')));
          expect(
            source,
            isNot(contains('ExplorerWorkspacePreviewInteractionHost')),
          );
          expect(source, isNot(contains('ExplorerWorkspacePreviewInput')));
        }
      },
    );

    test('preview composition does not require repository ownership', () {
      const forbiddenRepositoryOwnerMarkers = <String>[
        'WordRepository',
        'word_repository.dart',
        '../data/',
        'data/repositories',
        'DatabaseService',
        'database_service.dart',
        'sqflite',
        'getVisibleGraphData',
        'getWordDetailLikeDisplayItem',
        'getGraphCenterWordDisplayItem',
        'wordExistsForGraphNavigation',
        'probeExistingWordIds',
        'getWordMap',
      ];

      for (final source in previewSources.entries) {
        for (final forbiddenMarker in forbiddenRepositoryOwnerMarkers) {
          expect(
            source.value,
            isNot(contains(forbiddenMarker)),
            reason:
                'Preview composition must not require repository/read '
                'ownership: ${source.key} -> $forbiddenMarker.',
          );
        }
      }
    });

    test('preview composition does not own Navigator or route history', () {
      const forbiddenNavigatorOwnerMarkers = <String>[
        'Navigator',
        'MaterialPageRoute',
        'PageRouteBuilder',
        'pushReplacement',
        'pushNamed',
        'pushAndRemoveUntil',
        'onGenerateRoute',
        'routes:',
        'RouteInformation',
        'RestorationMixin',
        'Restorable',
      ];

      for (final source in previewSources.entries) {
        for (final forbiddenMarker in forbiddenNavigatorOwnerMarkers) {
          expect(
            source.value,
            isNot(contains(forbiddenMarker)),
            reason:
                'Preview composition must not own Navigator route history: '
                '${source.key} -> $forbiddenMarker.',
          );
        }
      }
    });

    test('preview boundary does not synthesize dummy ids or display items', () {
      const forbiddenSyntheticDataMarkers = <String>[
        'dummy',
        'fallback',
        'DisplayItem',
        'displayItem',
        'WordDetailLikeDisplayItem',
        'GraphCenterWordDisplayItem',
        'HomeSearchResultDisplayItem',
        'Map<String, dynamic>',
      ];

      for (final source in previewSources.entries) {
        for (final forbiddenMarker in forbiddenSyntheticDataMarkers) {
          expect(
            source.value,
            isNot(contains(forbiddenMarker)),
            reason:
                'Preview composition must not synthesize data carriers: '
                '${source.key} -> $forbiddenMarker.',
          );
        }
      }
    });

    test('documents record preview composition and ownership boundary', () {
      expect(
        uxDocument,
        contains('### 17.19 Phase 4-E preview-only composition boundary 기준'),
      );
      expect(uxDocument, contains('production owner 또는 source of truth가 아니다'));
      expect(uxDocument, contains('Preview-only composition boundary'));
      expect(uxDocument, contains('Interaction과 orchestration은 분리해서 해석한다'));
      expect(
        uxDocument,
        contains(
          'Orchestration이 repository read owner, Navigator owner, '
          'canonical selection owner, route owner로 해석되면 안 된다',
        ),
      );
      expect(
        uxDocument,
        contains('Projection lifecycle은 UI-level lifecycle이다'),
      );
      expect(uxDocument, contains('repository/data lifecycle'));
      expect(uxDocument, contains('rollback 가능해야 한다'));

      expect(changelog, contains('Phase 4-E'));
      expect(changelog, contains('production replacement가 아니라'));
      expect(changelog, contains('preview-only composition boundary'));
    });
  });
}

Map<String, String> _readDartSources(
  String rootPath, {
  String? excludeNormalizedPrefix,
  Set<String> excludeNormalizedPaths = const {},
}) {
  final sources = <String, String>{};
  final root = Directory(rootPath);

  for (final file in root.listSync(recursive: true).whereType<File>()) {
    final normalizedPath = _normalizePath(file.path);
    if (!normalizedPath.endsWith('.dart')) {
      continue;
    }
    if (excludeNormalizedPrefix != null &&
        normalizedPath.startsWith(excludeNormalizedPrefix)) {
      continue;
    }
    if (excludeNormalizedPaths.contains(normalizedPath)) {
      continue;
    }

    sources[normalizedPath] = file.readAsStringSync();
  }

  return sources;
}

String _readText(String path) {
  return File(path).readAsStringSync();
}

String _normalizePath(String path) {
  final normalizedPath = path.replaceAll('\\', '/');
  final libIndex = normalizedPath.indexOf('lib/');
  if (libIndex >= 0) {
    return normalizedPath.substring(libIndex);
  }

  return normalizedPath;
}
