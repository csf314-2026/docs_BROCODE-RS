import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_scheduler/android/widgets/empty_state_widget.dart';

void main() {
  group('EmptyStateWidget Tests', () {
    testWidgets('Renders the provided message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              message: 'No quizzes found',
              icon: Icons.search_off,
            ),
          ),
        ),
      );

      expect(find.text('No quizzes found'), findsOneWidget);
    });

    testWidgets('Renders the provided icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              message: 'Empty',
              icon: Icons.inbox,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('Icon has correct grey color and size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              message: 'Empty',
              icon: Icons.inbox,
            ),
          ),
        ),
      );

      final iconFinder = find.byType(Icon);
      expect(iconFinder, findsOneWidget);
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.size, 50.0);
      expect(iconWidget.color, Colors.grey[300]);
    });

    testWidgets('Message text has proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              message: 'Test Message',
              icon: Icons.info,
            ),
          ),
        ),
      );

      final textFinder = find.text('Test Message');
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, Colors.grey);
      expect(textWidget.style?.fontSize, 16);
      expect(textWidget.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('Widget is centered with padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              message: 'Center Test',
              icon: Icons.circle,
            ),
          ),
        ),
      );

      expect(find.byType(Center), findsWidgets);
      expect(find.byType(Padding), findsWidgets);
    });
  });
}
