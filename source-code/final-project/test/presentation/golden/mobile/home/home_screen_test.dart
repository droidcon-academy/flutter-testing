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
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/presentation/views/home/home_screen.dart';
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
  group('HomeScreen Golden Tests', () {
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

    Future<void> pumpHomeScreen(
      WidgetTester tester, {
      String? selectedLetter,
      RecipeState? recipeState,
      ThemeData? theme,
      Size? surfaceSize,
    }) async {
      await tester.pumpWidgetBuilder(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),

            getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),
            favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
            bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),

            currentPageIndexProvider.overrideWith((ref) => 0),

            selectedLetterProvider.overrideWith((ref) => selectedLetter),

            if (recipeState != null)
              recipeProvider.overrideWith((ref) {
                return TestRecipeViewModel(recipeState, mockGetAllRecipes,
                    mockFavoriteRecipe, mockBookmarkRecipe);
              }),
          ],
          child: MaterialApp(
            theme: theme ?? AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
        surfaceSize: surfaceSize ?? const Size(390, 844),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testGoldens('HomeScreen - Initial State (Alphabet View)', (tester) async {
      await pumpHomeScreen(tester, selectedLetter: null);
      await screenMatchesGolden(tester, 'home_screen_initial_alphabet_view');
    });

    testGoldens('HomeScreen - Dark Theme (Alphabet View)', (tester) async {
      await pumpHomeScreen(
        tester,
        selectedLetter: null,
        theme: AppTheme.darkTheme,
      );
      await screenMatchesGolden(tester, 'home_screen_dark_theme_alphabet_view');
    });

    testGoldens('HomeScreen - Letter Selected Shows Recipe Screen',
        (tester) async {
      await pumpHomeScreen(
        tester,
        selectedLetter: 'A',
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [_mockRecipe],
          selectedLetter: 'A',
        ),
      );
      await screenMatchesGolden(
          tester, 'home_screen_letter_selected_recipe_view');
    });

    testGoldens('HomeScreen - Dark Theme (Recipe View)', (tester) async {
      await pumpHomeScreen(
        tester,
        selectedLetter: 'B',
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [_mockRecipe],
          selectedLetter: 'B',
        ),
        theme: AppTheme.darkTheme,
      );
      await screenMatchesGolden(tester, 'home_screen_dark_theme_recipe_view');
    });

    testGoldens('HomeScreen - Mobile Layout (Alphabet)', (tester) async {
      await pumpHomeScreen(
        tester,
        selectedLetter: null,
        surfaceSize: const Size(375, 667), 
      );
      await screenMatchesGolden(tester, 'home_screen_mobile_layout_alphabet');
    });

    testGoldens('HomeScreen - Tablet Layout (Alphabet)', (tester) async {
      await pumpHomeScreen(
        tester,
        selectedLetter: null,
        surfaceSize: const Size(768, 1024), 
      );
      await screenMatchesGolden(tester, 'home_screen_tablet_layout_alphabet');
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
