import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipevault/core/themes/app_theme.dart';
import 'package:recipevault/core/constants/app_constants.dart';
import 'package:recipevault/presentation/views/dashboard/dashboard_screen.dart';
import 'package:recipevault/presentation/views/recipe/recipe_screen.dart';
import 'package:recipevault/presentation/views/dashboard/components/favorites/favorites_view.dart';
import 'package:recipevault/presentation/views/dashboard/components/bookmarks/bookmarks_view.dart';
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import '../../../views/dashboard/test_helpers.dart';

void main() {
  group('CircularProgressIndicator Golden Tests - Real App Context', () {
    setUpAll(() async {
      await loadAppFonts();
    });

    const testRecipes = [
      Recipe(
        id: '1',
        name: 'Chocolate Cake',
        ingredients: [
          Ingredient(name: 'flour', measure: '2 cups'),
          Ingredient(name: 'chocolate', measure: '4 oz'),
        ],
        instructions: 'Mix and bake at 350°F for 30 minutes.',
      ),
      Recipe(
        id: '2',
        name: 'Apple Pie',
        ingredients: [
          Ingredient(name: 'apples', measure: '6 medium'),
          Ingredient(name: 'flour', measure: '2 cups'),
        ],
        instructions: 'Roll dough and bake at 375°F for 45 minutes.',
      ),
    ];

    Future<void> pumpLoadingTest(
      WidgetTester tester, {
      required Widget widget,
      required Size screenSize,
      bool isLoadingState = true,
    }) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(widget);

      if (isLoadingState) {
        await tester.pump();
      } else {
        await tester.pumpAndSettle();
      }
    }

    group('DashboardScreen Loading States', () {
      testGoldens('DashboardScreen - Loading recipes and favorites (mobile)',
          (tester) async {
        const loadingState = DashboardState(
          isLoading: true,
          isPartiallyLoaded: false,
          recipes: [],
          favoriteIds: {},
          bookmarkIds: {},
        );

        final widget = createDashboardScreenTestHarness(
          mockFavoriteRecipe: MockFavoriteRecipe(),
          mockBookmarkRecipe: MockBookmarkRecipe(),
          mockDashboardState: loadingState,
          forceMobileLayout: false, 
        );

        await pumpLoadingTest(
          tester,
          widget: widget,
          screenSize: const Size(390, 844),
          isLoadingState: true,
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason: 'Should show CircularProgressIndicator during loading');
        expect(find.text('Loading recipes and favorites...'), findsOneWidget,
            reason: 'Should show loading message from DashboardScreen');

        await screenMatchesGolden(tester, 'dashboard_loading_mobile');
      });

      testGoldens('DashboardScreen - Loading recipes and favorites (tablet)',
          (tester) async {
        const loadingState = DashboardState(
          isLoading: true,
          isPartiallyLoaded: false,
          recipes: [],
          favoriteIds: {},
          bookmarkIds: {},
        );

        final widget = createDashboardScreenTestHarness(
          mockFavoriteRecipe: MockFavoriteRecipe(),
          mockBookmarkRecipe: MockBookmarkRecipe(),
          mockDashboardState: loadingState,
          forceMobileLayout: false,
        );

        await pumpLoadingTest(
          tester,
          widget: widget,
          screenSize: const Size(768, 1024),
          isLoadingState: true,
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason: 'Should show CircularProgressIndicator on tablet');
        expect(find.text('Loading recipes and favorites...'), findsOneWidget,
            reason: 'Should show same loading message on tablet');

        await screenMatchesGolden(tester, 'dashboard_loading_tablet');
      });

      testGoldens('DashboardScreen - Loading recipes and favorites (desktop)',
          (tester) async {
        const loadingState = DashboardState(
          isLoading: true,
          isPartiallyLoaded: false,
          recipes: [],
          favoriteIds: {},
          bookmarkIds: {},
        );

        final widget = createResponsiveTestWidget(
          mockFavoriteRecipe: MockFavoriteRecipe(),
          mockBookmarkRecipe: MockBookmarkRecipe(),
          screenSize: const Size(1200, 800),
          customRecipeState: const RecipeState(
            recipes: [],
            isLoading: false,
          ),
        );

        await pumpLoadingTest(
          tester,
          widget: widget,
          screenSize: const Size(1200, 800),
          isLoadingState: true,
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason: 'Should show CircularProgressIndicator on desktop');

        await screenMatchesGolden(tester, 'dashboard_loading_desktop');
      });
    });

    group('RecipeScreen Loading States', () {
      testGoldens('RecipeScreen - Loading state (mobile)', (tester) async {
        const loadingRecipeState = RecipeState(
          isLoading: true,
          recipes: [],
          error: null,
        );

        final widget = ProviderScope(
          overrides: [
            recipeProvider.overrideWith((ref) {
              return TestRecipeViewModel(loadingRecipeState);
            }),
            currentPageIndexProvider.overrideWith((ref) => 0),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              devicePixelRatio: 1.0,
            ),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const RecipeScreen(),
            ),
          ),
        );

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(widget);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason:
                'RecipeScreen should show CircularProgressIndicator during loading');

        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('goldens/recipe_loading_mobile.png'));
      });

      testGoldens('RecipeScreen - Loading state (desktop)', (tester) async {
        const loadingRecipeState = RecipeState(
          isLoading: true,
          recipes: [],
          error: null,
        );

        final widget = ProviderScope(
          overrides: [
            recipeProvider.overrideWith((ref) {
              return TestRecipeViewModel(loadingRecipeState);
            }),
            currentPageIndexProvider.overrideWith((ref) => 0),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(1200, 800),
              devicePixelRatio: 1.0,
            ),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const RecipeScreen(),
            ),
          ),
        );

        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(widget);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason:
                'RecipeScreen should show CircularProgressIndicator on desktop');

        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('goldens/recipe_loading_desktop.png'));
      });
    });

    group('FavoritesView Loading States', () {
      testGoldens('FavoritesView - Loading favorites (mobile)', (tester) async {
        const loadingState = DashboardState(
          isLoading: true,
          isPartiallyLoaded: false,
          recipes: testRecipes,
          favoriteIds: {'1', '2'},
          bookmarkIds: {},
        );

        final widget = ProviderScope(
          overrides: [
            dashboardProvider.overrideWith((ref) {
              return TestDashboardViewModel(
                favoriteRecipe: MockFavoriteRecipe(),
                bookmarkRecipe: MockBookmarkRecipe(),
                recipeState: const RecipeState(recipes: testRecipes),
                ref: ref,
              )..state = loadingState;
            }),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              devicePixelRatio: 1.0,
            ),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: FavoritesView(onRecipeSelected: (_) {}),
            ),
          ),
        );

        await pumpLoadingTest(
          tester,
          widget: widget,
          screenSize: const Size(390, 844),
          isLoadingState: true,
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason:
                'FavoritesView should show CircularProgressIndicator during loading');
        expect(find.text('Loading favorites...'), findsOneWidget,
            reason: 'Should show favorites-specific loading message');

        await screenMatchesGolden(tester, 'favorites_loading_mobile');
      });

      testGoldens('FavoritesView - Loading favorites (tablet)', (tester) async {
        const loadingState = DashboardState(
          isLoading: true,
          isPartiallyLoaded: false,
          recipes: testRecipes,
          favoriteIds: {'1', '2'},
          bookmarkIds: {},
        );

        final widget = ProviderScope(
          overrides: [
            dashboardProvider.overrideWith((ref) {
              return TestDashboardViewModel(
                favoriteRecipe: MockFavoriteRecipe(),
                bookmarkRecipe: MockBookmarkRecipe(),
                recipeState: const RecipeState(recipes: testRecipes),
                ref: ref,
              )..state = loadingState;
            }),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(768, 1024),
              devicePixelRatio: 1.0,
            ),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: FavoritesView(onRecipeSelected: (_) {}),
            ),
          ),
        );

        await pumpLoadingTest(
          tester,
          widget: widget,
          screenSize: const Size(768, 1024),
          isLoadingState: true,
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason:
                'FavoritesView should show CircularProgressIndicator on tablet');
        expect(find.text('Loading favorites...'), findsOneWidget,
            reason: 'Should show same loading message on tablet');

        await screenMatchesGolden(tester, 'favorites_loading_tablet');
      });
    });

    group('BookmarksView Loading States', () {
      testGoldens('BookmarksView - Loading bookmarks (mobile)', (tester) async {
        const loadingState = DashboardState(
          isLoading: true,
          isPartiallyLoaded: false,
          recipes: testRecipes,
          favoriteIds: {},
          bookmarkIds: {'1', '2'},
        );

        final widget = ProviderScope(
          overrides: [
            dashboardProvider.overrideWith((ref) {
              return TestDashboardViewModel(
                favoriteRecipe: MockFavoriteRecipe(),
                bookmarkRecipe: MockBookmarkRecipe(),
                recipeState: const RecipeState(recipes: testRecipes),
                ref: ref,
              )..state = loadingState;
            }),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              devicePixelRatio: 1.0,
            ),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: BookmarksView(onRecipeSelected: (_) {}),
            ),
          ),
        );

        await pumpLoadingTest(
          tester,
          widget: widget,
          screenSize: const Size(390, 844),
          isLoadingState: true,
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason:
                'BookmarksView should show CircularProgressIndicator during loading');
        expect(find.text('Loading bookmarks...'), findsOneWidget,
            reason: 'Should show bookmarks-specific loading message');

        await screenMatchesGolden(tester, 'bookmarks_loading_mobile');
      });
    });

    group('Dark Theme Loading States', () {
      testGoldens('DashboardScreen - Loading with dark theme', (tester) async {
        const loadingState = DashboardState(
          isLoading: true,
          isPartiallyLoaded: false,
          recipes: [],
          favoriteIds: {},
          bookmarkIds: {},
        );

        final widget = ProviderScope(
          overrides: [
            dashboardProvider.overrideWith((ref) {
              return TestDashboardViewModel(
                favoriteRecipe: MockFavoriteRecipe(),
                bookmarkRecipe: MockBookmarkRecipe(),
                recipeState: const RecipeState(),
                ref: ref,
              )..state = loadingState;
            }),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              devicePixelRatio: 1.0,
            ),
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const DashboardScreen(),
            ),
          ),
        );

        await pumpLoadingTest(
          tester,
          widget: widget,
          screenSize: const Size(390, 844),
          isLoadingState: true,
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason: 'Should show CircularProgressIndicator in dark theme');
        expect(find.text('Loading recipes and favorites...'), findsOneWidget,
            reason: 'Should show loading message in dark theme');

        await screenMatchesGolden(tester, 'dashboard_loading_dark_theme');
      });

      testGoldens('FavoritesView - Loading with dark theme', (tester) async {
        const loadingState = DashboardState(
          isLoading: true,
          isPartiallyLoaded: false,
          recipes: testRecipes,
          favoriteIds: {'1', '2'},
          bookmarkIds: {},
        );

        final widget = ProviderScope(
          overrides: [
            dashboardProvider.overrideWith((ref) {
              return TestDashboardViewModel(
                favoriteRecipe: MockFavoriteRecipe(),
                bookmarkRecipe: MockBookmarkRecipe(),
                recipeState: const RecipeState(recipes: testRecipes),
                ref: ref,
              )..state = loadingState;
            }),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              devicePixelRatio: 1.0,
            ),
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: FavoritesView(onRecipeSelected: (_) {}),
            ),
          ),
        );

        await pumpLoadingTest(
          tester,
          widget: widget,
          screenSize: const Size(390, 844),
          isLoadingState: true,
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason:
                'FavoritesView should show CircularProgressIndicator in dark theme');
        expect(find.text('Loading favorites...'), findsOneWidget,
            reason: 'Should show favorites loading message in dark theme');

        await screenMatchesGolden(tester, 'favorites_loading_dark_theme');
      });
    });

    tearDownAll(() async {
    });
  });
}
