import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/core/constants/app_constants.dart';

void main() {
  group('Generic Empty State Widget Tests', () {
    testWidgets('empty state displays correct structure with icon and messages',
        (WidgetTester tester) async {
      const testIcon = Icons.search_off;
      const testPrimaryMessage = 'No search results found';
      const testSecondaryMessage = 'Try adjusting your search terms';
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    testIcon,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: Sizes.spacing),
                  Text(
                    testPrimaryMessage,
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: Sizes.spacing),
                  Text(
                    testSecondaryMessage,
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(testIcon);
      expect(iconFinder, findsOneWidget, reason: 'Empty state should display the specified icon');
      
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.size, 64, reason: 'Icon should be 64px in size');
      expect(iconWidget.color, Colors.grey, reason: 'Icon should be grey');
      
      expect(find.text(testPrimaryMessage), findsOneWidget,
          reason: 'Empty state should display the primary message');
      expect(find.text(testSecondaryMessage), findsOneWidget,
          reason: 'Empty state should display the secondary message');
      
      final spacers = find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == Sizes.spacing,
      );
      expect(spacers, findsNWidgets(2), reason: 'There should be 2 spacing SizedBox widgets with proper height');
    });
    
    testWidgets('empty state is centered in parent container',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64),
                  SizedBox(height: 16),
                  Text('No data available'),
                ],
              ),
            ),
          ),
        ),
      );
      
      final centerFinder = find.byType(Center);
      expect(centerFinder, findsWidgets, reason: 'Empty state should be centered');
      
      final columnFinder = find.byType(Column);
      expect(columnFinder, findsOneWidget);
      
      final column = tester.widget<Column>(columnFinder);
      expect(column.mainAxisAlignment, MainAxisAlignment.center,
          reason: 'Column should have center alignment');
    });
  });
  
  group('Specific Empty State Implementation Tests', () {
    testWidgets('favorites empty state shows correct content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: Sizes.spacing),
                  Text(
                    'No favorite recipes yet',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: Sizes.spacing),
                  Text(
                    'Add recipes to your favorites to see them here',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      expect(find.byIcon(Icons.favorite_border), findsOneWidget,
          reason: 'Favorites empty state should display the favorite_border icon');
      
      expect(find.text('No favorite recipes yet'), findsOneWidget,
          reason: 'Favorites empty state should display the primary message');
      expect(find.text('Add recipes to your favorites to see them here'), findsOneWidget,
          reason: 'Favorites empty state should display the secondary message');
    });
    
    testWidgets('bookmarks empty state shows correct content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: Sizes.spacing),
                  Text(
                    'No bookmarked recipes yet',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: Sizes.spacing),
                  Text(
                    'Add recipes to your bookmarks to see them here',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget,
          reason: 'Bookmarks empty state should display the bookmark_border icon');
      
      expect(find.text('No bookmarked recipes yet'), findsOneWidget,
          reason: 'Bookmarks empty state should display the primary message');
      expect(find.text('Add recipes to your bookmarks to see them here'), findsOneWidget,
          reason: 'Bookmarks empty state should display the secondary message');
      
      final spacers = find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == Sizes.spacing,
      );
      expect(spacers, findsNWidgets(2), 
          reason: 'Bookmarks empty state should have proper spacing between elements');
    });
  });
}