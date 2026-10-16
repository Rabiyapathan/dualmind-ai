import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('DualMind home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const DualMindApp());

    expect(find.text('DualMind'), findsOneWidget);
    expect(find.text('A QUIETER WAY TO THINK'), findsOneWidget);
    expect(find.text('Ideas deserve\nroom to grow.'), findsOneWidget);
  });
}
