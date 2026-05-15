import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 3-B ExplorerWorkspace coexistence boundary', () {
    const sourcePath = 'lib/ui/explorer_workspace/explorer_workspace.dart';
    late String source;

    setUpAll(() {
      source = File(sourcePath).readAsStringSync();
    });

    test(
      'does not import production explorer, graph, detail, or repository',
      () {
        const forbiddenImports = <String>[
          'word_explorer_screen.dart',
          'word_graph_screen.dart',
          'word_detail_screen.dart',
          '../data/repositories/',
          'word_repository.dart',
        ];

        for (final forbiddenImport in forbiddenImports) {
          expect(
            source,
            isNot(contains(forbiddenImport)),
            reason: 'ExplorerWorkspace must not import $forbiddenImport.',
          );
        }
      },
    );

    test('does not contain Navigator or route push wiring', () {
      const forbiddenRouteWiring = <String>[
        'Navigator',
        'MaterialPageRoute',
        'PageRouteBuilder',
        'pushNamed',
        'pushReplacement',
        'pushAndRemoveUntil',
        'onGenerateRoute',
        'routes:',
      ];

      for (final forbiddenWiring in forbiddenRouteWiring) {
        expect(
          source,
          isNot(contains(forbiddenWiring)),
          reason: 'ExplorerWorkspace must not own route wiring.',
        );
      }
    });

    test('does not directly reference production screen or panel classes', () {
      const forbiddenReferences = <String>[
        'WordExplorerScreen',
        'WordGraphScreen',
        'WordDetailScreen',
        'WordInfoPanel',
        'WordRepository',
      ];

      for (final forbiddenReference in forbiddenReferences) {
        expect(
          source,
          isNot(contains(forbiddenReference)),
          reason:
              'ExplorerWorkspace must not directly couple to '
              '$forbiddenReference.',
        );
      }
    });
  });
}
