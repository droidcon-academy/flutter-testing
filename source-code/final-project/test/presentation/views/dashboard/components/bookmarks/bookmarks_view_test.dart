import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/core/constants/app_constants.dart';

void main() {
  group('BookmarksView Empty State Tests', () {
    testWidgets('correctly displays empty state UI elements', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bookmark_border,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: Sizes.spacing),
                    Text(
                      'No bookmarked recipes yet',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Sizes.spacing),
                    Text(
                      'Add recipes to your bookmarks to see them here',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('No bookmarked recipes yet'), findsOneWidget,
          reason: 'Empty state title should be displayed');
      
      expect(find.text('Add recipes to your bookmarks to see them here'), findsOneWidget,
          reason: 'Empty state guidance message should be displayed');
      
      final iconFinder = find.byIcon(Icons.bookmark_border);
      expect(iconFinder, findsOneWidget, reason: 'Empty bookmark icon should be displayed');
      
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.size, 64, reason: 'Icon should be size 64');
      expect(iconWidget.color, Colors.grey, reason: 'Icon should be grey');
    });
  });
  
  group('BookmarksView Loading State Tests', () {
    testWidgets('correctly displays loading state UI elements', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: Sizes.spacing),
                    Text(
                      'Loading bookmarks...',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      
      await tester.pump();
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget,
          reason: 'Loading indicator should be displayed');
      
      expect(find.text('Loading bookmarks...'), findsOneWidget,
          reason: 'Loading message should be displayed');
      
      final spacer = find.byType(SizedBox);
      expect(spacer, findsOneWidget, reason: 'Spacing element should exist');
      
      final spacerWidget = tester.widget<SizedBox>(spacer);
      expect(spacerWidget.height, Sizes.spacing, 
          reason: 'Spacer height should match Sizes.spacing constant');
      
      expect(find.byType(ListView), findsNothing,
          reason: 'List view should not be visible during loading');
      expect(find.byType(GridView), findsNothing,
          reason: 'Grid view should not be visible during loading');
      
      expect(find.text('No bookmarked recipes yet'), findsNothing,
          reason: 'Empty state title should not be visible during loading');
    });
  });
}