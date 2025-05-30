import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const largeSize = 60.0;
  const customColor = Colors.blue;
  
  group('CircularProgressIndicator Widget Tests', () {
    testWidgets('displays with default properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );

      final progressIndicator = find.byType(CircularProgressIndicator);

      expect(progressIndicator, findsOneWidget);
      
      final widget = tester.widget<CircularProgressIndicator>(progressIndicator);
      expect(widget, isNotNull);
      expect(widget.backgroundColor, null); 
    });

    testWidgets('displays with custom size using SizedBox', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                height: largeSize,
                width: largeSize,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );

      final sizedBox = find.byType(SizedBox);

      expect(sizedBox, findsOneWidget);
      final widget = tester.widget<SizedBox>(sizedBox);
      expect(widget.height, largeSize);
      expect(widget.width, largeSize);
    });

    testWidgets('displays with custom color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(customColor),
              ),
            ),
          ),
        ),
      );

      final progressIndicator = find.byType(CircularProgressIndicator);

      expect(progressIndicator, findsOneWidget);
      final widget = tester.widget<CircularProgressIndicator>(progressIndicator);
      expect(widget.valueColor, isA<AlwaysStoppedAnimation<Color>>());
      expect((widget.valueColor as AlwaysStoppedAnimation<Color>).value, customColor);
    });
  });

  group('Loading Indicator Context Tests', () {
    testWidgets('centers in the parent container', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );

      final centerWidget = find.byType(Center);

      expect(centerWidget, findsWidgets); 
      expect(find.descendant(
        of: find.byType(Center).last,
        matching: find.byType(CircularProgressIndicator),
      ), findsOneWidget);
    });

    testWidgets('animation is running', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );

      final progressIndicator = find.byType(CircularProgressIndicator);
      expect(progressIndicator, findsOneWidget);
      
      final animatedWidget = find.descendant(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(AnimatedBuilder),
      );
      expect(animatedWidget, findsWidgets, 
          reason: 'CircularProgressIndicator should contain animation widgets');
      
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      
    });
  });
}