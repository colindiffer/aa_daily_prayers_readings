import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aa_readings_25/main.dart';
import 'package:aa_readings_25/widgets/consent_banner.dart';
import 'package:aa_readings_25/screens/about_page.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Since the app might show consent UI initially, just verify it loads
    await tester.pumpAndSettle();

    // The test should pass if the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('About page loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));

    expect(find.text("AA Readings App"), findsOneWidget);
  });

  testWidgets('Consent banner can be displayed', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConsentBanner(
          onConsentChanged: (bool analyticsConsent, bool marketingConsent) {},
        ),
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text("Privacy Preferences"), findsOneWidget);
  });
}
