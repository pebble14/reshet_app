import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/ui/legal_document_dialog.dart';

void main() {
  for (final document in [
    ('개인정보처리방침', 'docs/legal/privacy_policy.md', 'reshetcontact@gmail.com'),
    (
      '자료 출처',
      'docs/legal/data_attributions.md',
      'Open Scriptures Hebrew Bible Project',
    ),
  ]) {
    testWidgets('${document.$1}를 작은 화면에서 읽고 닫을 수 있다', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showLegalDocumentDialog(
                  context,
                  title: document.$1,
                  assetPath: document.$2,
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      for (
        var i = 0;
        i < 20 && find.byType(SelectableText).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(SelectableText), findsOneWidget);
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        contains(document.$3),
      );
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsNothing);
    });
  }
}
