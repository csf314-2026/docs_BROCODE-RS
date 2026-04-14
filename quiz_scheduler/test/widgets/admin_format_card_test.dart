import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_scheduler/widgets/admin_format_card.dart';

void main() {
  group('AdminFormatCard Tests', () {
    testWidgets('Renders the title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminFormatCard(
              title: 'Format Title',
              icon: Icons.settings,
              color: Colors.blue,
              details: 'Format Details Info',
            ),
          ),
        ),
      );

      expect(find.text('Format Title'), findsOneWidget);
    });

    testWidgets('Renders the icon with the correct color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminFormatCard(
              title: 'Title',
              icon: Icons.backup,
              color: Colors.green,
              details: 'Details',
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.backup);
      expect(iconFinder, findsOneWidget);
      
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.color, Colors.green);
    });

    testWidgets('Renders an ExpansionTile', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminFormatCard(
              title: 'Title',
              icon: Icons.add,
              color: Colors.red,
              details: 'Details',
            ),
          ),
        ),
      );

      expect(find.byType(ExpansionTile), findsOneWidget);
    });

    testWidgets('Details text is hidden by default and shown when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminFormatCard(
              title: 'Title',
              icon: Icons.info,
              color: Colors.black,
              details: 'Hidden details string',
            ),
          ),
        ),
      );

      // ExpansionTile starts closed, so children might be offstage. 
      // The text technically exists in the tree but is hidden.
      // We will tap the tile and wait for the animation to complete.
      await tester.tap(find.text('Title'));
      await tester.pumpAndSettle();

      expect(find.text('Hidden details string'), findsOneWidget);
    });

    testWidgets('The card uses the correct shape and zero elevation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminFormatCard(
              title: 'Card Shape',
              icon: Icons.crop_square,
              color: Colors.pink,
              details: 'Details',
            ),
          ),
        ),
      );

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);

      final cardWidget = tester.widget<Card>(cardFinder);
      expect(cardWidget.elevation, 0);
      expect(cardWidget.color, Colors.white);
    });
  });
}
