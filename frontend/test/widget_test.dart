
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('DualMind AI home screen renders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DualMindApp());

    expect(find.text('DualMind AI'), findsOneWidget);
    expect(find.text('Think deeper.\nDiscover more.'), findsOneWidget);
    expect(find.text('Upload a document'), findsOneWidget);
    expect(find.text('Ask DualMind'), findsOneWidget);
  });
}
