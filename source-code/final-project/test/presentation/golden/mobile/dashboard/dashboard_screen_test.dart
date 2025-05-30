import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/themes/app_theme.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/presentation/views/dashboard/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mockRecipe = Recipe(
  id: '1',
  name: 'Apple Pie',
  ingredients: [
    Ingredient(name: 'Apples', measure: '6 large'),
    Ingredient(name: 'Sugar', measure: '1 cup'),
  ],
  instructions: 'Bake at 350°F for 45 minutes.',
);

const _mockFavoriteRecipe = Recipe(
  id: '2',
  name: 'Chocolate Cake',
  ingredients: [
    Ingredient(name: 'Chocolate', measure: '200g'),
    Ingredient(name: 'Flour', measure: '2 cups'),
  ],
  instructions: 'Bake at 180°C for 30 minutes.',
);

const _mockBookmarkRecipe = Recipe(
  id: '3',
  name: 'Banana Bread',
  ingredients: [
    Ingredient(name: 'Bananas', measure: '3 ripe'),
    Ingredient(name: 'Flour', measure: '1.5 cups'),
  ],
  instructions: 'Bake at 175°C for 60 minutes.',
);

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}

class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

void main() {
  group('DashboardScreen Golden Tests', () {
    late SharedPreferences mockSharedPreferences;
    late MockGetAllRecipes mockGetAllRecipes;
    late MockFavoriteRecipe mockFavoriteRecipe;
    late MockBookmarkRecipe mockBookmarkRecipe;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await loadAppFonts();

      registerFallbackValue(FakeGetAllRecipesParams());
      registerFallbackValue(FakeFavoriteRecipeParams());
      registerFallbackValue(FakeBookmarkRecipeParams());
    });

    setUp(() async {
      mockSharedPreferences = await SharedPreferences.getInstance();
      mockGetAllRecipes = MockGetAllRecipes();
      mockFavoriteRecipe = MockFavoriteRecipe();
      mockBookmarkRecipe = MockBookmarkRecipe();

      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => const Right([_mockRecipe]));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right([_mockFavoriteRecipe]));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => const Right([_mockBookmarkRecipe]));
    });

    Future<void> pumpDashboardScreen(
      WidgetTester tester, {
      DashboardState? dashboardState,
      RecipeState? recipeState,
      ThemeData? theme,
      Size? surfaceSize,
      bool isLoadingState = false,
    }) async {
      await tester.pumpWidgetBuilder(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),

            getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),
            favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
            bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),

            currentPageIndexProvider.overrideWith((ref) => 0),

            if (recipeState != null)
              recipeProvider.overrideWith((ref) {
                return TestRecipeViewModel(recipeState, mockGetAllRecipes,
                    mockFavoriteRecipe, mockBookmarkRecipe);
              }),

            if (dashboardState != null)
              dashboardProvider.overrideWith((ref) {
                return TestDashboardViewModel(
                    dashboardState,
                    mockFavoriteRecipe,
                    mockBookmarkRecipe,
                    recipeState ?? const RecipeState(),
                    ref);
              }),
          ],
          child: MaterialApp(
            theme: theme ?? AppTheme.lightTheme,
            home: const DashboardScreen(),
          ),
        ),
        surfaceSize: surfaceSize ?? const Size(390, 844),
      );

      if (isLoadingState) {
        await tester.pump(const Duration(milliseconds: 100));
      } else {
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }
    }

    testGoldens('DashboardScreen - Loading State', (tester) async {
      await pumpDashboardScreen(
        tester,
        dashboardState: const DashboardState(isLoading: true),
        recipeState:
            const RecipeState(isLoading: false, recipes: [_mockRecipe]),
        isLoadingState: true,
      );

      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile('goldens/dashboard_screen_loading.png'),
      );
    });

    testGoldens('DashboardScreen - Content Loaded', (tester) async {
      await pumpDashboardScreen(
        tester,
        dashboardState: const DashboardState(
          isLoading: false,
          recipes: [
            _mockRecipe,
            _mockFavoriteRecipe,
            _mockBookmarkRecipe
          ],
          favoriteIds: {'2'},
          bookmarkIds: {'3'},
        ),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [_mockRecipe, _mockFavoriteRecipe, _mockBookmarkRecipe],
        ),
      );
      await screenMatchesGolden(tester, 'dashboard_screen_content');
    });

    testGoldens('DashboardScreen - Error State', (tester) async {
      await pumpDashboardScreen(
        tester,
        dashboardState: const DashboardState(
          isLoading: false,
          error: 'Failed to load dashboard data',
        ),
        recipeState: const RecipeState(isLoading: false, recipes: []),
      );
      await screenMatchesGolden(tester, 'dashboard_screen_error');
    });

    testGoldens('DashboardScreen - Empty State', (tester) async {
      await pumpDashboardScreen(
        tester,
        dashboardState: const DashboardState(
          isLoading: false,
          recipes: [],
          favoriteIds: {},
          bookmarkIds: {},
        ),
        recipeState: const RecipeState(isLoading: false, recipes: []),
      );
      await screenMatchesGolden(tester, 'dashboard_screen_empty');
    });

    testGoldens('DashboardScreen - Dark Theme', (tester) async {
      await pumpDashboardScreen(
        tester,
        dashboardState: const DashboardState(
          isLoading: false,
          recipes: [
            _mockRecipe,
            _mockFavoriteRecipe,
            _mockBookmarkRecipe
          ],
          favoriteIds: {'2'},
          bookmarkIds: {'3'},
        ),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [_mockRecipe, _mockFavoriteRecipe, _mockBookmarkRecipe],
        ),
        theme: AppTheme.darkTheme,
      );
      await screenMatchesGolden(tester, 'dashboard_screen_dark_theme');
    });

    testGoldens('DashboardScreen - Mobile Layout', (tester) async {
      await pumpDashboardScreen(
        tester,
        dashboardState: const DashboardState(
          isLoading: false,
          recipes: [
            _mockRecipe,
            _mockFavoriteRecipe,
            _mockBookmarkRecipe
          ],
          favoriteIds: {'2'},
          bookmarkIds: {'3'},
        ),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [_mockRecipe, _mockFavoriteRecipe, _mockBookmarkRecipe],
        ),
        surfaceSize: const Size(375, 667), 
      );
      await screenMatchesGolden(tester, 'dashboard_screen_mobile_layout');
    });

    testGoldens('DashboardScreen - Tablet Layout', (tester) async {
      await pumpDashboardScreen(
        tester,
        dashboardState: const DashboardState(
          isLoading: false,
          recipes: [
            _mockRecipe,
            _mockFavoriteRecipe,
            _mockBookmarkRecipe
          ],
          favoriteIds: {'2'},
          bookmarkIds: {'3'},
        ),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [_mockRecipe, _mockFavoriteRecipe, _mockBookmarkRecipe],
        ),
        surfaceSize: const Size(768, 1024), 
      );
      await screenMatchesGolden(tester, 'dashboard_screen_tablet_layout');
    });
  });
}

class TestRecipeViewModel extends RecipeViewModel {
  TestRecipeViewModel(RecipeState initialState, GetAllRecipes getAllRecipes,
      FavoriteRecipe favoriteRecipe, BookmarkRecipe bookmarkRecipe)
      : super(getAllRecipes, favoriteRecipe, bookmarkRecipe) {
    state = initialState; 
  }

  @override
  Future<void> initializeData() async {}

  @override
  Future<void> loadRecipes() async {}
  @override
  Future<void> loadFavorites() async {}
  @override
  Future<void> loadBookmarks() async {}
  @override
  void setSelectedLetter(String? letter) {}
  @override
  void setSelectedRecipe(Recipe? recipe) {}
  @override
  Future<void> toggleFavorite(String recipeId) async {}
  @override
  Future<void> toggleBookmark(String recipeId) async {}
}

class TestDashboardViewModel extends DashboardViewModel {
  TestDashboardViewModel(
      DashboardState initialState,
      FavoriteRecipe favoriteRecipe,
      BookmarkRecipe bookmarkRecipe,
      RecipeState recipeState,
      Ref ref)
      : super(favoriteRecipe, bookmarkRecipe, recipeState, ref) {
    state = initialState; 
  }

  @override
  Future<void> initializeDataProgressively() async {}

  @override
  Future<void> initializeData() async {}

  @override
  Future<void> loadFavorites() async {}
  @override
  Future<void> loadBookmarks() async {}
}
