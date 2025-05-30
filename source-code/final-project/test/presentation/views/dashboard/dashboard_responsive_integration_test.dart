import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

void main() {
  group('Dashboard Responsive Integration Tests', () {
    late MockFavoriteRecipe mockFavoriteRecipe;
    late MockBookmarkRecipe mockBookmarkRecipe;

    setUpAll(() async {
      await initializeDashboardTestEnvironment();
    });

    setUp(() {
      mockFavoriteRecipe = MockFavoriteRecipe();
      mockBookmarkRecipe = MockBookmarkRecipe();
      setupCommonMockResponses(
        mockFavoriteRecipe: mockFavoriteRecipe,
        mockBookmarkRecipe: mockBookmarkRecipe,
      );
    });

    group('Mobile Layout', () {
      testWidgets('shows appropriate layout on mobile-sized screen', (tester) async {
        await tester.pumpWidget(createResponsiveTestWidget(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          screenSize: const Size(400, 800), 
        ));
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsWidgets);
        
        expect(find.text('My Dashboard'), findsOneWidget);
        
        expect(find.text('Favorites'), findsWidgets);
        expect(find.text('Bookmarks'), findsWidgets);
        
        expect(tester.takeException(), isNull);
      });

      testWidgets('mobile layout interaction works correctly',
          (tester) async {
        await tester.pumpWidget(createResponsiveTestWidget(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          screenSize: const Size(400, 800), 
        ));
        await tester.pumpAndSettle();

        final bookmarksText = find.text('Bookmarks');
        expect(bookmarksText, findsWidgets);
        
        if (bookmarksText.evaluate().isNotEmpty) {
          await tester.tap(bookmarksText.first);
          await tester.pumpAndSettle();
          
          expect(tester.takeException(), isNull);
        }
        
        expect(find.text('My Dashboard'), findsOneWidget);
      });
    });

    group('Tablet Layout', () {
      testWidgets('shows appropriate layout on tablet-sized screen', (tester) async {
        await tester.pumpWidget(createResponsiveTestWidget(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          screenSize: const Size(768, 1024),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsWidgets);

        expect(find.text('My Dashboard'), findsOneWidget);

        expect(tester.takeException(), isNull);
      });

      testWidgets('tablet layout handles content properly', (tester) async {
        await tester.pumpWidget(createResponsiveTestWidget(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          screenSize: const Size(768, 1024),
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        expect(find.text('My Dashboard'), findsOneWidget);
        
        expect(find.byType(IndexedStack), findsWidgets);
      });
    });

    group('Desktop Layout', () {
      testWidgets('shows appropriate layout on desktop-sized screen',
          (tester) async {
        await tester.pumpWidget(createResponsiveTestWidget(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          screenSize: const Size(1920, 1080),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsWidgets);
        
        expect(find.byType(VerticalDivider), findsWidgets);

        expect(find.text('My Dashboard'), findsOneWidget);

        expect(tester.takeException(), isNull);
      });

      testWidgets('desktop layout with wide screen dimensions', (tester) async {
        await tester.pumpWidget(createResponsiveTestWidget(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          screenSize: const Size(1920, 1080), 
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        
        expect(find.byType(Scaffold), findsWidgets);
        
        expect(find.byType(VerticalDivider), findsWidgets);
        
        expect(find.text('My Dashboard'), findsOneWidget);
      });
    });

    group('Layout Transitions', () {
      testWidgets('handles screen size changes gracefully', (tester) async {
        await tester.pumpWidget(createResponsiveTestWidget(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          screenSize: const Size(400, 800),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsWidgets);
        expect(find.text('My Dashboard'), findsOneWidget);

        await tester.pumpWidget(createResponsiveTestWidget(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          screenSize: const Size(768, 1024), 
        ));
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsWidgets);
        expect(find.text('My Dashboard'), findsOneWidget);
        expect(tester.takeException(), isNull);
        
        await tester.pumpWidget(createResponsiveTestWidget(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
          screenSize: const Size(1920, 1080), 
        ));
        await tester.pumpAndSettle();
        
        expect(find.byType(Scaffold), findsWidgets);
        expect(find.text('My Dashboard'), findsOneWidget);
        
        expect(find.byType(VerticalDivider), findsWidgets);
        
        expect(tester.takeException(), isNull);
      });
    });
  });
}
