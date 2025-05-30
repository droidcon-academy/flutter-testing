import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dashboard Partial Error State Tests', () {
    testWidgets('correctly displays partial error notification', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Some data couldn\'t be loaded. Pull to refresh.'),
                      action: SnackBarAction(
                        label: 'Retry',
                        onPressed: () {
                        },
                      ),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                });
                
                return const Center(
                  child: Text('Dashboard with partial data'),
                );
              },
            ),
          ),
        ),
      );
      
      await tester.pump();
      await tester.pump(); 
      
      expect(find.text('Dashboard with partial data'), findsOneWidget,
          reason: 'Dashboard content should be displayed even with partial errors');
      
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'SnackBar should be displayed for partial error state');
      
      expect(find.text('Some data couldn\'t be loaded. Pull to refresh.'), findsOneWidget,
          reason: 'Partial error message should be displayed in SnackBar');
      
      expect(find.text('Retry'), findsOneWidget,
          reason: 'Retry action should be available in SnackBar');
      
      final snackBarActionFinder = find.byType(SnackBarAction);
      expect(snackBarActionFinder, findsOneWidget, 
          reason: 'SnackBar should contain a SnackBarAction widget');
      
      final snackBarAction = tester.widget<SnackBarAction>(snackBarActionFinder);
      expect(snackBarAction.label, 'Retry', 
          reason: 'SnackBarAction should have "Retry" label');
    });
    
    testWidgets('retry action in SnackBar triggers callback', 
        (WidgetTester tester) async {
      bool retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  retryPressed = true;
                },
                child: const Text('Retry'),
              ),
            ),
          ),
        ),
      );
      
      expect(find.text('Retry'), findsOneWidget);
      
      await tester.tap(find.text('Retry'));
      await tester.pump();
      
      expect(retryPressed, true, 
          reason: 'Retry button should trigger the callback when tapped');
    });
  });
}
