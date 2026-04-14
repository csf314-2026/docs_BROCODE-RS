import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:quiz_scheduler/web/student_dashboard.dart';

void main() {
  group('StudentDashboard Authenticated Tests', () {
    testWidgets('Renders StudentDashboard and handles empty state properly via FakeFirestore', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'student123',
        email: 'test_student@bits-goa.ac.in',
        displayName: 'John Doe',
      );

      final fakeFirestore = FakeFirebaseFirestore();

      await fakeFirestore.collection('users').doc('test_student@bits-goa.ac.in').set({
        'courses': [], 
      });

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: StudentDashboard(
              user: mockUser,
              firestore: fakeFirestore,
            ),
          ),
        );
        await tester.pumpAndSettle(); 
        
        expect(find.text('My Schedule'), findsOneWidget);
        expect(find.text('Upcoming'), findsOneWidget);
        expect(find.text('Past'), findsOneWidget);
        expect(find.text('You are not enrolled in any courses yet.'), findsOneWidget);
      });
    });

    testWidgets('Displays fetched quizzes successfully from Fake DB', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockUser = MockUser(
        uid: 'student123',
        email: 'test_student@bits-goa.ac.in',
        displayName: 'John Doe',
      );

      final fakeFirestore = FakeFirebaseFirestore();

      await fakeFirestore.collection('users').doc('test_student@bits-goa.ac.in').set({
        'courses': ['CSF314'],
      });

      await fakeFirestore.collection('quizzes').add({
        'title': 'Advanced Midsem',
        'course_id': 'CSF314',
        'course_name': 'Software Engineering',
        'duration': 90,
        'date_&_time': DateTime.now().add(const Duration(days: 2)), 
      });

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: StudentDashboard(
              user: mockUser,
              firestore: fakeFirestore,
            ),
          ),
        );
        await tester.pumpAndSettle(); 

        expect(find.text('Advanced Midsem : Software Engineering'), findsOneWidget);
        expect(find.text('90 mins'), findsOneWidget);
      });
    });
  });
}
