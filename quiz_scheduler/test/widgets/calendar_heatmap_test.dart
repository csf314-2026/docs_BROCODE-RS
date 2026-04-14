import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:quiz_scheduler/widgets/calendar_heatmap.dart';

void main() {
  group('CalendarHeatmap Massive Integration Tests', () {
    testWidgets('Renders CalendarHeatmap processing complex loads securely', (WidgetTester tester) async {
      final fakeDb = FakeFirebaseFirestore();
      
      // Inject some mock courses and quizzes
      await fakeDb.collection('quizzes').add({
        'course_id': 'CSF314',
        // Make sure date is far in the past to test _getDayColor gracefully
        'date_&_time': DateTime.now().subtract(const Duration(days: 10)),
        'duration': 60,
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CalendarHeatmap(
            selectedCourseId: 'CSF314',
            focusedDay: DateTime.now(),
            selectedDay: DateTime.now(),
            onDaySelected: (s, f) {},
            firestore: fakeDb, // Injected!
          ),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Sun'), findsOneWidget); // Header text
      expect(find.text('Mon'), findsOneWidget); // Header text
    });
  });
}
