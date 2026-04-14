import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_scheduler/widgets/admin_upload_button.dart';

void main() {
  group('AdminUploadButton Tests', () {
    testWidgets('Renders the label correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminUploadButton(
              label: 'Upload File',
              icon: Icons.upload,
              color: Colors.blue,
              isUploading: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Upload File'), findsOneWidget);
    });

    testWidgets('Renders the correct icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminUploadButton(
              label: 'Upload',
              icon: Icons.cloud_upload,
              color: Colors.green,
              isUploading: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
    });

    testWidgets('Calls onPressed when tapped and not uploading', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminUploadButton(
              label: 'Upload',
              icon: Icons.upload,
              color: Colors.red,
              isUploading: false,
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, true);
    });

    testWidgets('Does not call onPressed when isUploading is true', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminUploadButton(
              label: 'Uploading...',
              icon: Icons.sync,
              color: Colors.purple,
              isUploading: true,
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, false);
    });

    testWidgets('Has correct rigid sizing of 220x50', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminUploadButton(
              label: 'Sized Button',
              icon: Icons.aspect_ratio,
              color: Colors.orange,
              isUploading: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      final sizedBoxFinder = find.byType(SizedBox).first;
      final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
      
      expect(sizedBox.width, 220);
      expect(sizedBox.height, 50);
    });
  });
}
