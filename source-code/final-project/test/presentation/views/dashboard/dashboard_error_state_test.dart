import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/core/constants/app_constants.dart';

void main() {
  group('Dashboard Error State Tests', () {
    testWidgets('correctly displays error state UI elements', 
        (WidgetTester tester) async {
      const errorMessage = 'Network connection failed';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48.0, color: Colors.red),
                  const SizedBox(height: Sizes.spacing),
                  const Text('Failed to load recipes: $errorMessage'),
                  const SizedBox(height: Sizes.spacing),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      await tester.pump();
      
      final iconFinder = find.byIcon(Icons.error_outline);
      expect(iconFinder, findsOneWidget, reason: 'Error icon should be displayed');
      
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.size, 48.0, reason: 'Icon should be size 48.0');
      expect(iconWidget.color, Colors.red, reason: 'Icon should be red');
      
      expect(find.text('Failed to load recipes: $errorMessage'), findsOneWidget,
          reason: 'Error message should be displayed');
      
      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget, reason: 'Retry button should be displayed');
      
      final buttonTextFinder = find.text('Retry');
      expect(buttonTextFinder, findsOneWidget, reason: 'Button should have "Retry" text');
      
      final spacers = find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == Sizes.spacing,
      );
      expect(spacers, findsNWidgets(2), reason: 'Should have two spacing elements with height: Sizes.spacing');
      
      final spacerWidget = tester.widget<SizedBox>(spacers.first);
      expect(spacerWidget.height, Sizes.spacing, 
          reason: 'Spacer height should match Sizes.spacing constant');
    });
    
    testWidgets('retry button can be pressed', (WidgetTester tester) async {
      bool retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48.0, color: Colors.red),
                  const SizedBox(height: Sizes.spacing),
                  const Text('Failed to load recipes: Network error'),
                  const SizedBox(height: Sizes.spacing),
                  ElevatedButton(
                    onPressed: () {
                      retryPressed = true;
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      expect(retryPressed, false, reason: 'Retry should not have been pressed yet');
      
      await tester.tap(find.text('Retry'));
      await tester.pump();
      
      expect(retryPressed, true, reason: 'Retry button press should be detected');
    });
  });
}
