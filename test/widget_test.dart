// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:pressing_under_pressure/main.dart';

void main() {
  testWidgets('Main menu shows difficulty buttons', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const PressingUnderPressure());

    // Verify that difficulty buttons are present on the main menu.
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
  });
}
