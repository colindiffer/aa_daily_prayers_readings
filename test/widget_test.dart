import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aa_readings_25/main.dart';
import 'package:aa_readings_25/screens/about_page.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Since the app might show onboarding initially, just verify it loads
    await tester.pumpAndSettle();

    // The test should pass if the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('About page loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));

    await tester.pumpAndSettle();

    expect(find.text("AA Daily Readings & Prayers App"), findsOneWidget);
  });
}
