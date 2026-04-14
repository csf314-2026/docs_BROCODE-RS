import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:quiz_scheduler/web/admin_dashboard.dart';
import 'package:quiz_scheduler/widgets/admin_format_card.dart';
import 'package:quiz_scheduler/widgets/admin_upload_button.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() {
  group('AdminDashboard Massive View Tests', () {
    testWidgets('Renders AdminDashboard entirely fully without crashing', (WidgetTester tester) async {
      // 1. Create the Mock User exactly as recommended for authentic Flutter testing
      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'admin123',
        email: 'admin@bits-goa.ac.in',
        displayName: 'Professor Admin',
      );

      // 2. Initialize and pump the view
      await mockNetworkImagesFor(() async {
        tester.view.physicalSize = const Size(2000, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: AdminDashboard(user: mockUser),
          ),
        );

        await tester.pumpAndSettle();

        // 3. Verify it booted properly
        expect(find.text('Admin Dashboard'), findsOneWidget);
        expect(find.text('Bulk Data Upload'), findsOneWidget);

        // 4. Verify all upload buttons are generated
        expect(find.byType(AdminUploadButton), findsNWidgets(3));
        expect(find.text('Upload Users'), findsOneWidget);
        expect(find.text('Upload Courses'), findsOneWidget);
        expect(find.text('Upload Quizzes'), findsOneWidget);

        // 5. Verify format cards exist
        expect(find.byType(AdminFormatCard), findsNWidgets(3));
        expect(find.text('Users File Format'), findsOneWidget);
        expect(find.text('Courses File Format'), findsOneWidget);

        // 6. Verify basic user interaction doesn't crash constraints
        // Scrolling can test layout rendering stability
        final gesture = await tester.startGesture(const Offset(400, 400));
        await gesture.moveBy(const Offset(0, -200));
        await tester.pump();
        await gesture.up();
      });
    });
  });
}
