import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recipevault/core/themes/app_theme.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/views/dashboard/components/favorites/favorites_view.dart';
import 'package:recipevault/presentation/views/dashboard/components/bookmarks/bookmarks_view.dart';
import 'package:recipevault/presentation/views/dashboard/dashboard_screen.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}

class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

class TestDashboardViewModel extends DashboardViewModel {
  final DashboardState _fixedState;

  TestDashboardViewModel(
    this._fixedState,
    FavoriteRecipe favoriteRecipe,
    BookmarkRecipe bookmarkRecipe,
    RecipeState recipeState,
    Ref ref,
  ) : super(favoriteRecipe, bookmarkRecipe, recipeState, ref) {
    state = _fixedState;
  }

  @override
  DashboardState get state => _fixedState;

  @override
  set state(DashboardState newState) {
    if (newState == _fixedState) {
      super.state = newState;
    }
  }

  @override
  Future<void> initializeData() async {
  }

  @override
  Future<void> loadFavorites() async {
  }

  @override
  Future<void> loadBookmarks() async {
  }
}

const _mockFavoriteRecipes = [
  Recipe(
    id: '1',
    name: 'Apple Pie',
    ingredients: [
      Ingredient(name: 'Apples', measure: '6 large'),
      Ingredient(name: 'Sugar', measure: '1 cup'),
    ],
    instructions: 'Bake at 350°F for 45 minutes.',
    isFavorite: true,
    isBookmarked: false,
  ),
  Recipe(
    id: '2',
    name: 'Chocolate Cake',
    ingredients: [
      Ingredient(name: 'Chocolate', measure: '200g'),
      Ingredient(name: 'Flour', measure: '2 cups'),
    ],
    instructions: 'Bake at 180°C for 30 minutes.',
    isFavorite: true,
    isBookmarked: false,
  ),
];

const _mockBookmarkRecipes = [
  Recipe(
    id: '3',
    name: 'Banana Bread',
    ingredients: [
      Ingredient(name: 'Bananas', measure: '3 ripe'),
      Ingredient(name: 'Flour', measure: '1.5 cups'),
    ],
    instructions: 'Bake at 175°C for 60 minutes.',
    isFavorite: false,
    isBookmarked: true,
  ),
  Recipe(
    id: '4',
    name: 'Vegetable Soup',
    ingredients: [
      Ingredient(name: 'Mixed vegetables', measure: '2 cups'),
      Ingredient(name: 'Broth', measure: '4 cups'),
    ],
    instructions: 'Simmer vegetables in broth for 30 minutes.',
    isFavorite: false,
    isBookmarked: true,
  ),
];

void main() {
  group('Favorites View Golden Tests - Real Components', () {
    late MockGetAllRecipes mockGetAllRecipes;
    late MockFavoriteRecipe mockFavoriteRecipe;
    late MockBookmarkRecipe mockBookmarkRecipe;

    setUpAll(() async {
      await loadAppFonts();

      registerFallbackValue(FakeGetAllRecipesParams());
      registerFallbackValue(FakeFavoriteRecipeParams());
      registerFallbackValue(FakeBookmarkRecipeParams());
    });

    setUp(() async {
      mockGetAllRecipes = MockGetAllRecipes();
      mockFavoriteRecipe = MockFavoriteRecipe();
      mockBookmarkRecipe = MockBookmarkRecipe();

      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => const Right(_mockFavoriteRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right(_mockFavoriteRecipes));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => const Right(_mockBookmarkRecipes));
    });

    Future<Widget> createFavoritesViewTestHarness({
      DashboardState? dashboardState,
      RecipeState? recipeState,
      ThemeData? theme,
      bool testBookmarks = false,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final testDashboardState = dashboardState ??
          DashboardState(
            isLoading: false,
            recipes: [..._mockFavoriteRecipes, ..._mockBookmarkRecipes],
            favoriteIds: {
              _mockFavoriteRecipes[0].id,
              _mockFavoriteRecipes[1].id,
            },
            bookmarkIds: {
              _mockBookmarkRecipes[0].id,
              _mockBookmarkRecipes[1].id,
            },
          );

      final testRecipeState = recipeState ??
          RecipeState(
            isLoading: false,
            recipes: [..._mockFavoriteRecipes, ..._mockBookmarkRecipes],
          );

      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),

          dashboardProvider.overrideWith((ref) => TestDashboardViewModel(
              testDashboardState,
              mockFavoriteRecipe,
              mockBookmarkRecipe,
              testRecipeState,
              ref)),
        ],
        child: MaterialApp(
          home: testBookmarks ? const BookmarksView() : const FavoritesView(),
          theme: theme ?? AppTheme.lightTheme,
        ),
      );
    }

    Future<void> pumpFavoritesView(
      WidgetTester tester, {
      required Size screenSize,
      DashboardState? dashboardState,
      RecipeState? recipeState,
      ThemeData? theme,
      bool testBookmarks = false,
    }) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;

      final widget = await createFavoritesViewTestHarness(
        dashboardState: dashboardState,
        recipeState: recipeState,
        theme: theme,
        testBookmarks: testBookmarks,
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    group('FavoritesView Real Component Tests', () {
      testGoldens('FavoritesView - List view with favorites', (tester) async {
        await pumpFavoritesView(
          tester,
          screenSize: const Size(375, 600),
        );

        expect(find.byType(FavoritesView), findsOneWidget,
            reason: 'FavoritesView should be displayed');

        expect(find.text('Apple Pie'), findsOneWidget,
            reason: 'Should display favorite recipe from dashboardState');
        expect(find.text('Chocolate Cake'), findsOneWidget,
            reason: 'Should display favorite recipe from dashboardState');

        expect(find.byIcon(Icons.grid_view), findsOneWidget,
            reason: 'Should show grid view toggle button');

        await screenMatchesGolden(tester, 'favorites_view_list_view');
      });

      testGoldens('FavoritesView - Grid view after toggle', (tester) async {
        await pumpFavoritesView(
          tester,
          screenSize: const Size(375, 600),
        );

        expect(find.byType(FavoritesView), findsOneWidget,
            reason: 'FavoritesView should be displayed');

        await tester.tap(find.byIcon(Icons.grid_view));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.view_list), findsOneWidget,
            reason:
                'Should show list view toggle button after switching to grid');

        await screenMatchesGolden(tester, 'favorites_view_grid_view');
      });

      testGoldens('FavoritesView - Empty state', (tester) async {
        await pumpFavoritesView(
          tester,
          screenSize: const Size(375, 600),
          dashboardState: const DashboardState(
            isLoading: false,
            recipes: [],
            favoriteIds: {},
            bookmarkIds: {},
          ),
        );

        expect(find.byType(FavoritesView), findsOneWidget,
            reason: 'FavoritesView should be displayed');
        expect(find.text('No favorite recipes yet'), findsOneWidget,
            reason: 'Should display empty state message');
        expect(find.byIcon(Icons.favorite_border), findsOneWidget,
            reason: 'Should display empty state icon');

        await screenMatchesGolden(tester, 'favorites_view_empty_state');
      });

      testGoldens('FavoritesView - Dark theme', (tester) async {
        await pumpFavoritesView(
          tester,
          screenSize: const Size(375, 600), 
          theme: AppTheme.darkTheme,
        );

        expect(find.byType(FavoritesView), findsOneWidget,
            reason: 'FavoritesView should be displayed in dark theme');

        await screenMatchesGolden(tester, 'favorites_view_dark_theme');
      });
    });

    group('BookmarksView Real Component Tests', () {
      testGoldens('BookmarksView - List view with bookmarks', (tester) async {
        await pumpFavoritesView(
          tester,
          screenSize: const Size(375, 600),
          testBookmarks: true,
        );

        expect(find.byType(BookmarksView), findsOneWidget,
            reason: 'BookmarksView should be displayed');

        expect(find.text('Banana Bread'), findsOneWidget,
            reason: 'Should display bookmark recipe from dashboardState');
        expect(find.text('Vegetable Soup'), findsOneWidget,
            reason: 'Should display bookmark recipe from dashboardState');

        await screenMatchesGolden(tester, 'bookmarks_view_list_view');
      });

      testGoldens('BookmarksView - Grid view after toggle', (tester) async {
        await pumpFavoritesView(
          tester,
          screenSize: const Size(375, 600),
          testBookmarks: true,
        );

        expect(find.byType(BookmarksView), findsOneWidget,
            reason: 'BookmarksView should be displayed');

        await tester.tap(find.byIcon(Icons.grid_view));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.view_list), findsOneWidget,
            reason:
                'Should show list view toggle button after switching to grid');

        await screenMatchesGolden(tester, 'bookmarks_view_grid_view');
      });

      testGoldens('BookmarksView - Empty state', (tester) async {
        await pumpFavoritesView(
          tester,
          screenSize: const Size(375, 600), 
          dashboardState: const DashboardState(
            isLoading: false,
            recipes: [],
            favoriteIds: {},
            bookmarkIds: {},
          ),
          testBookmarks: true,
        );

        expect(find.byType(BookmarksView), findsOneWidget,
            reason: 'BookmarksView should be displayed');
        expect(find.text('No bookmarked recipes yet'), findsOneWidget,
            reason: 'Should display empty state message');
        expect(find.byIcon(Icons.bookmark_border), findsOneWidget,
            reason: 'Should display empty state icon');

        await screenMatchesGolden(tester, 'bookmarks_view_empty_state');
      });
    });

    group('Dashboard State Integration Tests', () {
      testGoldens('FavoritesView - Within DashboardScreen context',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final testDashboardState = DashboardState(
          isLoading: false,
          recipes: [..._mockFavoriteRecipes, ..._mockBookmarkRecipes],
          favoriteIds: {
            _mockFavoriteRecipes[0].id,
            _mockFavoriteRecipes[1].id,
          },
          bookmarkIds: {
            _mockBookmarkRecipes[0].id,
            _mockBookmarkRecipes[1].id,
          },
        );

        tester.view.physicalSize = const Size(375, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              dashboardProvider.overrideWith((ref) => TestDashboardViewModel(
                  testDashboardState,
                  mockFavoriteRecipe,
                  mockBookmarkRecipe,
                  const RecipeState(
                    isLoading: false,
                    recipes: [..._mockFavoriteRecipes, ..._mockBookmarkRecipes],
                  ),
                  ref)),
            ],
            child: MaterialApp(
              home: const DashboardScreen(),
              theme: AppTheme.lightTheme,
            ),
          ),
        );

        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.byType(DashboardScreen), findsOneWidget,
            reason: 'DashboardScreen should be displayed');

        await screenMatchesGolden(tester, 'favorites_dashboard_screen_context');
      });
    });

    tearDownAll(() async {
    });
  });
}
