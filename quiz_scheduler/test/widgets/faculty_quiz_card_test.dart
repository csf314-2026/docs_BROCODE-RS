import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_scheduler/widgets/faculty_quiz_card.dart';

void main() {
  group('FacultyQuizCard Tests', () {
    final Map<String, dynamic> sampleQuiz = {
      'title': 'Test Quiz Final',
      'course_name': 'Software Engineering',
      'course_id': 'CSF314',
      'duration': 45,
      // We avoid sending Timestamp directly to bypass Firebase initialization requirement in pure widget tests
      // Wait, Timestamp is from cloud_firestore, so we can use Timestamp.fromDate safely as it's a simple object
      'date_&_time': Timestamp.fromDate(DateTime(2026, 4, 15, 10, 0)),
    };

    final Map<String, dynamic> modifiedQuiz = {
      'title': 'Test Quiz Final',
      'course_name': 'Software Engineering',
      'course_id': 'CSF314',
      'duration': 45,
      'date_&_time': Timestamp.fromDate(DateTime(2026, 4, 15, 10, 0)),
      'is_modified': true,
      'previous_title': 'Old Title Draft',
      'previous_date_&_time': Timestamp.fromDate(DateTime(2026, 4, 14, 10, 0)),
      'previous_duration': 30,
    };

    testWidgets('Renders quiz title, course name and id', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FacultyQuizCard(
              quizId: '123',
              data: sampleQuiz,
              isUpcoming: true,
              isMobile: true,
            ),
          ),
        ),
      );

      // Matches "$title : $courseName : $courseId"
      expect(find.text('Test Quiz Final : Software Engineering : CSF314'), findsOneWidget);
    });

    testWidgets('Renders edit and delete buttons when isUpcoming is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FacultyQuizCard(
              quizId: '123',
              data: sampleQuiz,
              isUpcoming: true,
              isMobile: true,
            ),
          ),
        ),
      );

      expect(find.byTooltip('Modify'), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);
    });

    testWidgets('Hides edit and delete buttons when isUpcoming is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FacultyQuizCard(
              quizId: '123',
              data: sampleQuiz,
              isUpcoming: false,
              isMobile: true,
            ),
          ),
        ),
      );

      expect(find.byTooltip('Modify'), findsNothing);
      expect(find.byTooltip('Delete'), findsNothing);
    });

    testWidgets('Displays current duration info correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FacultyQuizCard(
              quizId: '123',
              data: sampleQuiz,
              isUpcoming: true,
              isMobile: false,
            ),
          ),
        ),
      );

      expect(find.text('45 mins'), findsOneWidget);
    });

    testWidgets('Shows strikethrough old title when is_modified is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FacultyQuizCard(
              quizId: '123',
              data: modifiedQuiz,
              isUpcoming: true,
              isMobile: true,
            ),
          ),
        ),
      );

      // The old title 'Old Title Draft' should be shown
      expect(find.text('Old Title Draft'), findsOneWidget);
      
      // And also the new title
      expect(find.text('Test Quiz Final : Software Engineering : CSF314'), findsOneWidget);
    });
  });
}
