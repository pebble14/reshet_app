import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/main_explorer_workspace_preview.dart';

void main() {
  group('Phase 5-A-1 route-disconnected preview access boundary', () {
    testWidgets('launches preview access app with fixed preview-only input', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const ExplorerWorkspacePreviewAccessApp());
      await tester.pumpAndSettle();

      expect(find.text('PreviewLayoutOrchestration'), findsOneWidget);
      expect(
        find.text('selected word: PREVIEW_SELECTED_ALPHA'),
        findsOneWidget,
      );
      expect(
        find.text('graph center word: PREVIEW_CENTER_BETA'),
        findsOneWidget,
      );
      expect(
        find.text('detail target word: PREVIEW_DETAIL_GAMMA'),
        findsOneWidget,
      );
      expect(find.text('active preset: balanced'), findsOneWidget);
      expect(find.text('active origin: initialEntry'), findsOneWidget);
      expect(find.text('UsePreset:graphFocused'), findsOneWidget);
      expect(find.text('UsePreset:detailFocused'), findsOneWidget);
      expect(find.text('ToggleGraphPanel'), findsOneWidget);
      expect(find.text('ToggleDetailPane'), findsOneWidget);
    });

    test('entry point stays outside production route and owner boundaries', () {
      final previewEntrySource = _readText(
        'lib/main_explorer_workspace_preview.dart',
      );
      final mainSource = _readText('lib/main.dart');
      final homeSource = _readText('lib/ui/home_screen.dart');
      final explorerSource = _readText('lib/ui/word_explorer_screen.dart');
      final uxDocument = _readText('docs/ux/explorer_workspace_unification.md');
      final constitutionDocument = _readText(
        'docs/architecture/explorer_workspace_constitution.md',
      );
      final changelog = _readText('docs/logs/CHANGELOG.md');

      expect(
        previewEntrySource,
        contains('runApp(const ExplorerWorkspacePreviewAccessApp())'),
      );
      expect(
        previewEntrySource,
        contains('ExplorerWorkspacePreviewInteractionHost.fromInput'),
      );
      expect(previewEntrySource, contains('ExplorerWorkspacePreviewInput('));
      expect(
        previewEntrySource,
        contains("selectedWordId: 'PREVIEW_SELECTED_ALPHA'"),
      );
      expect(
        previewEntrySource,
        contains("graphCenterWordId: 'PREVIEW_CENTER_BETA'"),
      );
      expect(
        previewEntrySource,
        contains("detailTargetWordId: 'PREVIEW_DETAIL_GAMMA'"),
      );
      expect(
        previewEntrySource,
        contains('home: const ExplorerWorkspacePreviewAccessRoot()'),
      );

      const forbiddenPreviewEntryMarkers = <String>[
        'HomeScreen',
        'WordExplorerScreen',
        'WordGraphScreen',
        'WordDetailScreen',
        'WordRepository',
        'word_repository.dart',
        'DatabaseService',
        'Navigator.push',
        'MaterialPageRoute',
        'pushNamed',
        'pushReplacement',
        'pushAndRemoveUntil',
        'onGenerateRoute',
        'routes:',
        'initialRoute',
        'DisplayItem',
        'displayItem',
        'Map<String, dynamic>',
        'history',
        'persistence',
      ];

      for (final forbiddenMarker in forbiddenPreviewEntryMarkers) {
        expect(
          previewEntrySource,
          isNot(contains(forbiddenMarker)),
          reason:
              'Phase 5-A-1 preview access entry must stay route-disconnected '
              'and outside production ownership: $forbiddenMarker.',
        );
      }

      expect(mainSource, contains('home: const HomeScreen()'));
      expect(mainSource, isNot(contains('ExplorerWorkspacePreviewAccessApp')));
      expect(mainSource, isNot(contains('main_explorer_workspace_preview')));
      expect(homeSource, contains('WordExplorerScreen('));
      expect(homeSource, isNot(contains('ExplorerWorkspacePreviewAccessApp')));
      expect(homeSource, isNot(contains('main_explorer_workspace_preview')));
      expect(
        explorerSource,
        contains('class WordExplorerScreen extends StatefulWidget'),
      );
      expect(explorerSource, contains('WordRepository'));

      expect(
        uxDocument,
        contains('### 17.21 Phase 5-A-1 route 미연결 preview access boundary 기준'),
      );
      expect(
        uxDocument,
        contains('flutter run -t lib/main_explorer_workspace_preview.dart'),
      );
      expect(uxDocument, contains('production route에 연결하지 않는다'));
      expect(
        uxDocument,
        contains('production Navigator tree에 preview를 연결하지 않는다'),
      );

      expect(
        constitutionDocument,
        contains('## 7. Phase 5-A-1 route 미연결 preview access boundary 보강'),
      );
      expect(
        constitutionDocument,
        contains('route 미연결 preview access boundary'),
      );
      expect(constitutionDocument, contains('별도 실행 엔트리 포인트'));

      expect(changelog, contains('2026-05-19 Phase 5-A-1'));
      expect(changelog, contains('route 미연결 preview access boundary'));
    });
  });
}

String _readText(String path) {
  return File(path).readAsStringSync();
}
