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
  group('Loading Message Variants Golden Tests - Real App Context', () {
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

    Future<void> pumpLoadingMessageTest(
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

    group('DashboardScreen Loading Messages', () {
      testGoldens(
          'DashboardScreen - "Loading recipes and favorites..." message',
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

        await pumpLoadingMessageTest(
          tester,
          widget: widget,
          screenSize: const Size(390, 844),
          isLoadingState: true,
        );

        expect(find.text('Loading recipes and favorites...'), findsOneWidget,
            reason: 'Should show DashboardScreen loading message');
        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason: 'Should show loading indicator with message');

        await screenMatchesGolden(tester, 'dashboard_loading_message_mobile');
      });

      testGoldens('DashboardScreen - Loading message responsive behavior',
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

        await pumpLoadingMessageTest(
          tester,
          widget: widget,
          screenSize: const Size(1200, 800),
          isLoadingState: true,
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason: 'Should show loading indicator on desktop');

        await screenMatchesGolden(tester, 'dashboard_loading_message_desktop');
      });
    });

    group('FavoritesView Loading Messages', () {
      testGoldens('FavoritesView - "Loading favorites..." message',
          (tester) async {
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

        await pumpLoadingMessageTest(
          tester,
          widget: widget,
          screenSize: const Size(390, 844),
          isLoadingState: true,
        );

        expect(find.text('Loading favorites...'), findsOneWidget,
            reason: 'Should show FavoritesView-specific loading message');
        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason: 'Should show loading indicator with favorites message');

        await screenMatchesGolden(tester, 'favorites_loading_message_mobile');
      });

      testGoldens('FavoritesView - Loading message with theme styling',
          (tester) async {
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

        await pumpLoadingMessageTest(
          tester,
          widget: widget,
          screenSize: const Size(768, 1024),
          isLoadingState: true,
        );

        expect(find.text('Loading favorites...'), findsOneWidget,
            reason: 'Should show themed loading message on tablet');
        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason: 'Should show themed loading indicator');

        await screenMatchesGolden(tester, 'favorites_loading_message_tablet');
      });
    });

    group('BookmarksView Loading Messages', () {
      testGoldens('BookmarksView - "Loading bookmarks..." message',
          (tester) async {
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

        await pumpLoadingMessageTest(
          tester,
          widget: widget,
          screenSize: const Size(390, 844),
          isLoadingState: true,
        );

        expect(find.text('Loading bookmarks...'), findsOneWidget,
            reason: 'Should show BookmarksView-specific loading message');
        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason: 'Should show loading indicator with bookmarks message');

        await screenMatchesGolden(tester, 'bookmarks_loading_message_mobile');
      });
    });

    group('RecipeScreen Loading Messages', () {
      testGoldens('RecipeScreen - Simple loading state', (tester) async {
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
            matchesGoldenFile('goldens/recipe_loading_simple_mobile.png'));
      });

      testGoldens('RecipeScreen - Loading state responsive behavior',
          (tester) async {
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
            matchesGoldenFile('goldens/recipe_loading_simple_desktop.png'));
      });
    });

    group('Dark Theme Loading Messages', () {
      testGoldens('DashboardScreen - Loading message with dark theme',
          (tester) async {
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

        await pumpLoadingMessageTest(
          tester,
          widget: widget,
          screenSize: const Size(390, 844),
          isLoadingState: true,
        );

        expect(find.text('Loading recipes and favorites...'), findsOneWidget,
            reason: 'Should show loading message in dark theme');
        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason: 'Should show loading indicator in dark theme');

        await screenMatchesGolden(
            tester, 'dashboard_loading_message_dark_theme');
      });

      testGoldens('FavoritesView - Loading message with dark theme',
          (tester) async {
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

        await pumpLoadingMessageTest(
          tester,
          widget: widget,
          screenSize: const Size(390, 844),
          isLoadingState: true,
        );

        expect(find.text('Loading favorites...'), findsOneWidget,
            reason: 'Should show favorites loading message in dark theme');
        expect(find.byType(CircularProgressIndicator), findsOneWidget,
            reason: 'Should show loading indicator in dark theme');

        await screenMatchesGolden(
            tester, 'favorites_loading_message_dark_theme');
      });
    });

    group('Error State Messages', () {
      testGoldens('DashboardScreen - Error state with retry functionality',
          (tester) async {
        const errorState = DashboardState(
          isLoading: false,
          isPartiallyLoaded: false,
          recipes: [],
          favoriteIds: {},
          bookmarkIds: {},
          error: 'Failed to load recipes',
        );

        final widget = ProviderScope(
          overrides: [
            dashboardProvider.overrideWith((ref) {
              return TestDashboardViewModel(
                favoriteRecipe: MockFavoriteRecipe(),
                bookmarkRecipe: MockBookmarkRecipe(),
                recipeState: const RecipeState(),
                ref: ref,
              )..state = errorState;
            }),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              devicePixelRatio: 1.0,
            ),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const DashboardScreen(),
            ),
          ),
        );

        await pumpLoadingMessageTest(
          tester,
          widget: widget,
          screenSize: const Size(390, 844),
          isLoadingState: false,
        );

        expect(find.textContaining('Failed to load recipes:'), findsOneWidget,
            reason: 'Should show error message from DashboardScreen');
        expect(find.byIcon(Icons.error_outline), findsOneWidget,
            reason: 'Should show error icon');
        expect(find.text('Retry'), findsOneWidget,
            reason: 'Should show retry button');

        await screenMatchesGolden(tester, 'dashboard_error_message_mobile');
      });

      testGoldens('RecipeScreen - Error state message', (tester) async {
        const errorRecipeState = RecipeState(
          isLoading: false,
          recipes: [],
          error: 'Network connection failed',
        );

        final widget = ProviderScope(
          overrides: [
            recipeProvider.overrideWith((ref) {
              return TestRecipeViewModel(errorRecipeState);
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

        await pumpLoadingMessageTest(
          tester,
          widget: widget,
          screenSize: const Size(390, 844),
          isLoadingState: false,
        );

        expect(find.text('Network connection failed'), findsOneWidget,
            reason: 'Should show error message from RecipeScreen');
        expect(find.byIcon(Icons.error_outline), findsOneWidget,
            reason: 'Should show error icon');

        await screenMatchesGolden(tester, 'recipe_error_message_mobile');
      });
    });

    tearDownAll(() async {
    });
  });
}
