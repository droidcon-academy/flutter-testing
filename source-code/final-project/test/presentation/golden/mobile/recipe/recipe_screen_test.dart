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
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/views/recipe/recipe_screen.dart';
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

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}

class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

void main() {
  group('RecipeScreen Golden Tests', () {
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
          .thenAnswer((_) async => const Right([]));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => const Right([]));
    });

    Future<void> pumpRecipeScreen(
      WidgetTester tester, {
      required RecipeState recipeState,
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

            recipeProvider.overrideWith((ref) {
              return TestRecipeViewModel(recipeState, mockGetAllRecipes,
                  mockFavoriteRecipe, mockBookmarkRecipe);
            }),
          ],
          child: MaterialApp(
            theme: theme ?? AppTheme.lightTheme,
            home: const RecipeScreen(),
          ),
        ),
        surfaceSize: surfaceSize ?? const Size(390, 844),
      );

      if (isLoadingState) {
        await tester.pump();
      } else {
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }
    }

    testGoldens('RecipeScreen - Loading State', (tester) async {
      await tester.pumpWidgetBuilder(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),

            getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),
            favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
            bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),

            currentPageIndexProvider.overrideWith((ref) => 0),

            recipeProvider.overrideWith((ref) {
              return TestRecipeViewModel(const RecipeState(isLoading: true),
                  mockGetAllRecipes, mockFavoriteRecipe, mockBookmarkRecipe);
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RecipeScreen(),
          ),
        ),
        surfaceSize: const Size(390, 844),
      );

      await tester.pump();
      await screenMatchesGolden(tester, 'recipe_screen_loading_state');
    }, skip: true);

    testGoldens('RecipeScreen - Content Loaded (Light Theme)', (tester) async {
      await pumpRecipeScreen(
        tester,
        recipeState:
            const RecipeState(isLoading: false, recipes: [_mockRecipe]),
        theme: AppTheme.lightTheme,
      );
      await screenMatchesGolden(tester, 'recipe_screen_content_light_theme');
    });

    testGoldens('RecipeScreen - Content Loaded (Dark Theme)', (tester) async {
      await pumpRecipeScreen(
        tester,
        recipeState:
            const RecipeState(isLoading: false, recipes: [_mockRecipe]),
        theme: AppTheme.darkTheme,
      );
      await screenMatchesGolden(tester, 'recipe_screen_content_dark_theme');
    });

    testGoldens('RecipeScreen - Empty State', (tester) async {
      await pumpRecipeScreen(tester,
          recipeState: const RecipeState(isLoading: false, recipes: []));
      await screenMatchesGolden(tester, 'recipe_screen_empty_state');
    });

    testGoldens('RecipeScreen - Error State', (tester) async {
      await pumpRecipeScreen(tester,
          recipeState:
              const RecipeState(isLoading: false, error: 'Failed to load'));
      await screenMatchesGolden(tester, 'recipe_screen_error_state');
    });

    testGoldens('RecipeScreen - Mobile Layout (Content)', (tester) async {
      await pumpRecipeScreen(
        tester,
        recipeState:
            const RecipeState(isLoading: false, recipes: [_mockRecipe]),
        surfaceSize: const Size(375, 667),
      );
      await screenMatchesGolden(tester, 'recipe_screen_mobile_layout_content');
    });

    testGoldens('RecipeScreen - Larger Mobile Layout (Content)',
        (tester) async {
      await pumpRecipeScreen(
        tester,
        recipeState:
            const RecipeState(isLoading: false, recipes: [_mockRecipe]),
        surfaceSize: const Size(414, 896),
      );
      await screenMatchesGolden(
          tester, 'recipe_screen_large_mobile_layout_content');
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
