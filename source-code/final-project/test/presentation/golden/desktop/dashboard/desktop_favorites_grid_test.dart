// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recipevault/core/themes/app_theme.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/presentation/views/dashboard/components/favorites/favorite_grid_view.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';

const _favoriteRecipes = [
  Recipe(
    id: '1',
    name: 'Spaghetti Carbonara',
    ingredients: [
      Ingredient(name: 'spaghetti', measure: '400g'),
      Ingredient(name: 'eggs', measure: '3 large'),
      Ingredient(name: 'parmesan cheese', measure: '100g'),
      Ingredient(name: 'pancetta', measure: '150g'),
    ],
    instructions: 'Cook pasta, mix with eggs and cheese, add pancetta.',
  ),
  Recipe(
    id: '2',
    name: 'Chicken Tikka Masala',
    ingredients: [
      Ingredient(name: 'chicken breast', measure: '500g'),
      Ingredient(name: 'tomatoes', measure: '400g'),
      Ingredient(name: 'cream', measure: '200ml'),
      Ingredient(name: 'spices', measure: 'mixed'),
    ],
    instructions: 'Marinate chicken, cook with tomatoes and cream.',
  ),
  Recipe(
    id: '3',
    name: 'Caesar Salad',
    ingredients: [
      Ingredient(name: 'romaine lettuce', measure: '2 heads'),
      Ingredient(name: 'parmesan cheese', measure: '50g'),
      Ingredient(name: 'croutons', measure: '1 cup'),
      Ingredient(name: 'dressing', measure: 'caesar'),
    ],
    instructions: 'Chop lettuce, add cheese, croutons, and dressing.',
  ),
];

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}

class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

class TestRecipeViewModel extends RecipeViewModel {
  final RecipeState _fixedState;

  TestRecipeViewModel(
    this._fixedState,
    GetAllRecipes getAllRecipes,
    FavoriteRecipe favoriteRecipe,
    BookmarkRecipe bookmarkRecipe,
  ) : super(getAllRecipes, favoriteRecipe, bookmarkRecipe);

  @override
  RecipeState get state => _fixedState;

  @override
  Future<void> loadRecipes() async {
  }

  @override
  void setSelectedLetter(String? letter) {
  }

  @override
  Future<void> toggleFavorite(String recipeId) async {
  }
}

void main() {
  group('Desktop Favorites Grid Golden Tests', () {
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
          .thenAnswer((_) async => const Right(_favoriteRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right(_favoriteRecipes));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => const Right([]));
    });

    Future<void> pumpDesktopFavoriteGridView(
      WidgetTester tester, {
      List<Recipe>? favoriteRecipes,
      ThemeData? theme,
      Size? screenSize,
    }) async {
      final size = screenSize ?? const Size(1200, 800);
      tester.binding.window.physicalSizeTestValue =
          Size(size.width * 2, size.height * 2);
      tester.binding.window.devicePixelRatioTestValue = 2.0;

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),

            getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),
            favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
            bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),

            currentPageIndexProvider.overrideWith((ref) => 1), 

            recipeProvider.overrideWith((ref) {
              return TestRecipeViewModel(
                RecipeState(
                  isLoading: false,
                  recipes: favoriteRecipes ?? _favoriteRecipes,
                ),
                mockGetAllRecipes,
                mockFavoriteRecipe,
                mockBookmarkRecipe,
              );
            }),
          ],
          child: MaterialApp(
            theme: theme ?? AppTheme.lightTheme,
            home: FavoriteGridView(
              recipes: favoriteRecipes ?? _favoriteRecipes,
              onRecipeSelected: (recipe) {
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testGoldens('Desktop favorites - Grid layout with responsive columns',
        (tester) async {
      await pumpDesktopFavoriteGridView(tester);

      expect(find.byType(FavoriteGridView), findsOneWidget,
          reason: 'FavoriteGridView should be displayed');

      final expectedColumns = ResponsiveHelper.recipeGridColumns(
        tester.element(find.byType(FavoriteGridView)),
      );
      expect(expectedColumns, greaterThan(2),
          reason: 'Desktop should use more than 2 columns for favorite grid');

      await screenMatchesGolden(tester, 'desktop_favorites_grid_layout');
    });

    testGoldens('Desktop favorites - Dark theme grid', (tester) async {
      await pumpDesktopFavoriteGridView(
        tester,
        theme: AppTheme.darkTheme,
      );

      await screenMatchesGolden(tester, 'desktop_favorites_grid_dark');
    });

    testGoldens('Desktop favorites - Wide screen responsive layout',
        (tester) async {
      await pumpDesktopFavoriteGridView(
        tester,
        screenSize: const Size(1600, 900), 
      );

      final expectedColumns = ResponsiveHelper.recipeGridColumns(
        tester.element(find.byType(FavoriteGridView)),
      );
      expect(expectedColumns, greaterThanOrEqualTo(3),
          reason:
              'Wide screen should use at least 3 columns for favorites grid');

      await screenMatchesGolden(tester, 'desktop_favorites_grid_wide');
    });

    testGoldens('Desktop favorites - Empty state', (tester) async {
      await pumpDesktopFavoriteGridView(
        tester,
        favoriteRecipes: [], 
      );

      expect(find.text('No favorite recipes yet'), findsOneWidget,
          reason: 'Empty state message should be displayed');
      expect(find.byIcon(Icons.favorite_border), findsOneWidget,
          reason: 'Empty state icon should be displayed');

      await screenMatchesGolden(tester, 'desktop_favorites_grid_empty');
    });

    testGoldens('Desktop favorites - Single favorite recipe', (tester) async {
      await pumpDesktopFavoriteGridView(
        tester,
        favoriteRecipes: [_favoriteRecipes.first], 
      );

      await screenMatchesGolden(tester, 'desktop_favorites_grid_single');
    });

    tearDownAll(() async {
     
    });
  });
}
