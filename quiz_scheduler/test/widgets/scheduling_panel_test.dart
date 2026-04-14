import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:quiz_scheduler/widgets/scheduling_panel.dart';

void main() {
  group('SchedulingPanel Comprehensive Layout Tests', () {
    testWidgets('Renders SchedulingPanel allowing user input without crashing', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeDb = FakeFirebaseFirestore();
      DateTime targetDay = DateTime(2026, 4, 15);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SchedulingPanel(
            isMobile: false,
            selectedDay: targetDay,
            selectedCourseId: 'CSF314',
            isSubmitting: false,
            onSubmit: (title, time, duration) {},
            firestore: fakeDb, // Injected!
          ),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Schedule Quiz Details'), findsOneWidget);
      expect(find.text('Duration:'), findsOneWidget);
      expect(find.text('Confirm & Schedule'), findsOneWidget);

      // Verify the slots generator runs fully!
      expect(find.byType(FilterChip), findsWidgets); 
    });
  });
}
