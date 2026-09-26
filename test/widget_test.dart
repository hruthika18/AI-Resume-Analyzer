import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resume_analyzer/screens/login_screen.dart';

// This is a lightweight smoke test for the Login screen. It intentionally
// does not pump ResumeAnalyzerApp()/AuthGate directly, because AuthGate
// checks for a saved session via DatabaseService (sqflite), and plugin
// channels like sqflite aren't available in plain `flutter test` widget
// tests without extra platform-channel mocking. Testing LoginScreen in
// isolation keeps this test fast and reliable.
void main() {
  testWidgets('Login screen shows the expected fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Create one'), findsOneWidget);
  });
}
