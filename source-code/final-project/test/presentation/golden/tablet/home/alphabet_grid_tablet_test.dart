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
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/presentation/views/home/components/alphabet_grid.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}

class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

const _testRecipesA = [
  Recipe(
    id: '1',
    name: 'Apple Pie',
    ingredients: [
      Ingredient(name: 'apples', measure: '6 medium'),
      Ingredient(name: 'flour', measure: '2 cups'),
    ],
    instructions: 'Roll dough, fill with apples, bake at 375°F for 45 minutes.',
  ),
  Recipe(
    id: '2',
    name: 'Avocado Toast',
    ingredients: [
      Ingredient(name: 'bread', measure: '2 slices'),
      Ingredient(name: 'avocado', measure: '1 ripe'),
    ],
    instructions: 'Toast bread, mash avocado, spread and season.',
  ),
];

const _testRecipesC = [
  Recipe(
    id: '3',
    name: 'Chocolate Cake',
    ingredients: [
      Ingredient(name: 'flour', measure: '2 cups'),
      Ingredient(name: 'chocolate', measure: '4 oz'),
    ],
    instructions: 'Mix dry ingredients, add chocolate, bake at 350°F.',
  ),
  Recipe(
    id: '4',
    name: 'Caesar Salad',
    ingredients: [
      Ingredient(name: 'romaine lettuce', measure: '2 heads'),
      Ingredient(name: 'parmesan cheese', measure: '1/2 cup'),
    ],
    instructions: 'Chop lettuce, add dressing and cheese, toss well.',
  ),
];

const _allTestRecipes = [..._testRecipesA, ..._testRecipesC];

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
}

void main() {
  group('Tablet Alphabet Grid Golden Tests', () {
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
          .thenAnswer((_) async => const Right(_allTestRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right([]));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => const Right([]));
    });

    Future<void> pumpTabletAlphabetGrid(
      WidgetTester tester, {
      RecipeState? recipeState,
      ThemeData? theme,
    }) async {
      tester.binding.window.physicalSizeTestValue =
          const Size(1024 * 2, 768 * 2);
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

            currentPageIndexProvider.overrideWith((ref) => 0), 

            if (recipeState != null)
              recipeProvider.overrideWith((ref) {
                return TestRecipeViewModel(
                  recipeState,
                  mockGetAllRecipes,
                  mockFavoriteRecipe,
                  mockBookmarkRecipe,
                );
              }),
          ],
          child: MaterialApp(
            theme: theme ?? AppTheme.lightTheme,
            home: const Scaffold(
              body: AlphabetGrid(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testGoldens('Tablet alphabet grid - 4 column layout', (tester) async {
      expect(ResponsiveHelper.isTablet, isTrue,
          reason: 'Should detect tablet screen size');
      expect(ResponsiveHelper.alphabetGridColumns, equals(4),
          reason: 'Tablet should use 4 columns for alphabet grid');

      await pumpTabletAlphabetGrid(
        tester,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _allTestRecipes,
        ),
      );

      expect(find.byType(AlphabetGrid), findsOneWidget,
          reason: 'AlphabetGrid should be displayed');

      await screenMatchesGolden(tester, 'tablet_alphabet_grid_4_columns');
    });

    testGoldens('Tablet alphabet grid - Dark theme', (tester) async {
      await pumpTabletAlphabetGrid(
        tester,
        theme: AppTheme.darkTheme,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _allTestRecipes,
        ),
      );

      await screenMatchesGolden(tester, 'tablet_alphabet_grid_dark');
    });

    testGoldens('Tablet alphabet grid - Loading state', (tester) async {
      await pumpTabletAlphabetGrid(
        tester,
        recipeState: const RecipeState(
          isLoading: true,
          recipes: [],
        ),
      );

      await screenMatchesGolden(tester, 'tablet_alphabet_grid_loading');
    });

    testGoldens('Tablet alphabet grid - Empty state', (tester) async {
      await pumpTabletAlphabetGrid(
        tester,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [],
        ),
      );

      await screenMatchesGolden(tester, 'tablet_alphabet_grid_empty');
    });

    testGoldens('Tablet alphabet grid - Portrait orientation', (tester) async {
      tester.binding.window.physicalSizeTestValue =
          const Size(768 * 2, 1024 * 2);
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
            currentPageIndexProvider.overrideWith((ref) => 0),
            recipeProvider.overrideWith((ref) {
              return TestRecipeViewModel(
                const RecipeState(
                  isLoading: false,
                  recipes: _allTestRecipes,
                ),
                mockGetAllRecipes,
                mockFavoriteRecipe,
                mockBookmarkRecipe,
              );
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: const AlphabetGrid(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(ResponsiveHelper.alphabetGridColumns, equals(4),
          reason: 'Tablet should use 4 columns for alphabet grid');

      await screenMatchesGolden(tester, 'tablet_alphabet_grid_portrait');
    });

    tearDownAll(() async {
     
    });
  });
}
