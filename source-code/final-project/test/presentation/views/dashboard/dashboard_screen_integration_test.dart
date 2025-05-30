import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/presentation/views/dashboard/components/dashboard_panel.dart';

import 'test_helpers.dart';

void main() {
  group('Dashboard Screen Integration Tests', () {
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

    group('Tab Navigation Integration (Direct DashboardTabLayout)', () {
      testWidgets(
          'tab switching maintains state between Favorites and Bookmarks',
          (tester) async {
        await tester.pumpWidget(createTabLayoutTestWidget(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
        ));
        await tester.pumpAndSettle();

        expect(find.text('My Dashboard'), findsOneWidget);
        expect(find.byType(TabBar), findsOneWidget);

        final tabBar = find.byType(TabBar);
        final favoritesTab = find.descendant(
          of: tabBar,
          matching: find.text('Favorites'),
        );
        final bookmarksTab = find.descendant(
          of: tabBar,
          matching: find.text('Bookmarks'),
        );

        expect(favoritesTab, findsOneWidget);
        expect(bookmarksTab, findsOneWidget);

        final TabBar tabBarWidget = tester.widget(find.byType(TabBar));
        final TabController tabController = tabBarWidget.controller!;
        expect(tabController.index, 0, reason: 'Should start on Favorites tab');

        await tester.tap(bookmarksTab);
        await tester.pumpAndSettle();

        expect(tabController.index, 1,
            reason: 'Should switch to Bookmarks tab');

        await tester.tap(favoritesTab);
        await tester.pumpAndSettle();

        expect(tabController.index, 0,
            reason: 'Should switch back to Favorites tab');
      });

      testWidgets('tab controller lifecycle management', (tester) async {
        await tester.pumpWidget(createTabLayoutTestWidget(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
        ));
        await tester.pumpAndSettle();

        final TabBar tabBar = tester.widget(find.byType(TabBar));
        final TabController tabController = tabBar.controller!;

        expect(tabController.length, 2, reason: 'Should have 2 tabs');
        expect(tabController.index, 0, reason: 'Should start at index 0');

        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'No errors should occur during disposal');
      });
    });

    group('Component Integration', () {
      testWidgets('dashboard screen loads and shows expected structure',
          (tester) async {
        await tester.pumpWidget(createDashboardScreenTestHarness(
          mockFavoriteRecipe: mockFavoriteRecipe,
          mockBookmarkRecipe: mockBookmarkRecipe,
        ));
        await tester.pumpAndSettle();

        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.text('My Dashboard'), findsOneWidget);
        expect(find.byType(DashboardPanel), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}
