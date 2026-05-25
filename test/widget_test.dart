import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/main.dart';

void main() {
  testWidgets('ReshetApp root builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ReshetApp());

    expect(find.byType(ReshetApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
