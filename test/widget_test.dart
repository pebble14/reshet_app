import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/main.dart';

void main() {
  testWidgets('ReshetApp root builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ReshetApp());

    expect(find.byType(ReshetApp), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme?.brightness, Brightness.light);
    expect(app.darkTheme?.brightness, Brightness.dark);
    expect(tester.takeException(), isNull);
  });
}
