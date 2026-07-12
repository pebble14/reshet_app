import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/main.dart';
import 'package:reshet_app/ui/home_screen.dart';

void main() {
  testWidgets('초기 테마 모드가 MaterialApp에 반영된다', (WidgetTester tester) async {
    await tester.pumpWidget(const ReshetApp(initialThemeMode: ThemeMode.dark));

    expect(find.byType(ReshetApp), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.theme?.brightness, Brightness.light);
    expect(app.darkTheme?.brightness, Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('테마 변경 callback이 MaterialApp을 즉시 rebuild한다', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ReshetApp());

    var homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));
    homeScreen.onThemeModeChanged!(ThemeMode.light);
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    homeScreen = tester.widget<HomeScreen>(find.byType(HomeScreen));
    expect(homeScreen.themeMode, ThemeMode.light);
  });
}
