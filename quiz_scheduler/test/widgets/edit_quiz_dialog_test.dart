import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_scheduler/widgets/edit_quiz_dialog.dart';

void main() {
  group('EditQuizDialog Tests', () {
    final Map<String, dynamic> currentData = {
      'title': 'Midterm Exam',
      'date_&_time': Timestamp.fromDate(DateTime(2026, 5, 20, 14, 30)),
      'duration': 90,
    };

    testWidgets('Renders dialog title Modify Quiz', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditQuizDialog(
              quizId: '123',
              currentData: currentData,
            ),
          ),
        ),
      );

      expect(find.text('Modify Quiz'), findsOneWidget);
    });

    testWidgets('Renders text field with initial title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditQuizDialog(
              quizId: '123',
              currentData: currentData,
            ),
          ),
        ),
      );

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, 'Midterm Exam');
    });

    testWidgets('Renders OutlinedButton with calendar icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditQuizDialog(
              quizId: '123',
              currentData: currentData,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('Renders correct initial duration in slider text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditQuizDialog(
              quizId: '123',
              currentData: currentData,
            ),
          ),
        ),
      );

      // It should display '90 mins'
      expect(find.text('90 mins'), findsOneWidget);
    });

    testWidgets('Renders Save Changes and Cancel buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditQuizDialog(
              quizId: '123',
              currentData: currentData,
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });
}
