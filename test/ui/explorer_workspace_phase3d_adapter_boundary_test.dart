import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 3-D ExplorerWorkspace adapter boundary', () {
    const sourcePath = 'lib/ui/explorer_workspace/explorer_workspace.dart';
    late String source;

    setUpAll(() {
      source = File(sourcePath).readAsStringSync();
    });

    test('does not directly reference production screens or panels', () {
      const forbiddenProductionReferences = <String>[
        'WordExplorerScreen',
        'WordGraphScreen',
        'WordDetailScreen',
        'WordInfoPanel',
      ];

      for (final forbiddenReference in forbiddenProductionReferences) {
        expect(
          source,
          isNot(contains(forbiddenReference)),
          reason:
              'ExplorerWorkspace adapter boundary must not reference '
              '$forbiddenReference.',
        );
      }
    });

    test('does not own repository or read API access', () {
      const forbiddenRepositoryReferences = <String>[
        'WordRepository',
        '../data/repositories/',
        'data/repositories',
        'word_repository.dart',
        'getVisibleGraphData',
        'getWordDetailLikeDisplayItem',
        'getGraphCenterWordDisplayItem',
        'wordExistsForGraphNavigation',
        'probeExistingWordIds',
      ];

      for (final forbiddenReference in forbiddenRepositoryReferences) {
        expect(
          source,
          isNot(contains(forbiddenReference)),
          reason:
              'ExplorerWorkspace adapter boundary must not own repository '
              'or read API access.',
        );
      }
    });

    test('does not own Navigator or route push wiring', () {
      const forbiddenRouteReferences = <String>[
        'Navigator',
        'MaterialPageRoute',
        'pushReplacement',
        'pushNamed',
        'pushAndRemoveUntil',
        'onGenerateRoute',
        'routes:',
      ];

      for (final forbiddenReference in forbiddenRouteReferences) {
        expect(
          source,
          isNot(contains(forbiddenReference)),
          reason:
              'ExplorerWorkspace adapter boundary must not own route wiring.',
        );
      }
    });
  });
}
