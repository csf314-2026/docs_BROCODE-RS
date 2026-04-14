import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_scheduler/login_page.dart';

void main() {
  group('LoginPage Tests', () {
    testWidgets('Renders the university name', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      expect(find.text('BITS Pilani'), findsOneWidget);
      expect(find.text('K K Birla Goa Campus'), findsOneWidget);
    });

    testWidgets('Renders the app title Evals-BPGC', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      expect(find.text('Evals-BPGC'), findsOneWidget);
      expect(find.text('view-schedule-analyze'), findsOneWidget);
    });

    testWidgets('Renders the Google login button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      
      // Ensure the "Google" text inside the button is found
      expect(find.text('Google'), findsOneWidget);
      // Ensure ElevatedButton is found
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Renders the Admin Login text button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      
      final adminButtonFinder = find.text('Admin Login');
      expect(adminButtonFinder, findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('Renders copyright text at bottom', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      
      expect(find.text('© 2026 BITS Pilani, K K Birla Goa Campus'), findsOneWidget);
    });
  });
}
