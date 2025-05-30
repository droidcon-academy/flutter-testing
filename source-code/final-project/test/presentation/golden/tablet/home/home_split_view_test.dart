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
import 'package:recipevault/presentation/views/home/home_screen.dart';
import 'package:recipevault/presentation/views/home/components/alphabet_grid.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}

class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

const _testRecipes = [
  Recipe(
    id: '1',
    name: 'Apple Cinnamon Pancakes',
    ingredients: [
      Ingredient(name: 'flour', measure: '2 cups'),
      Ingredient(name: 'apples', measure: '2 medium'),
    ],
    instructions: 'Mix dry ingredients, add wet ingredients, cook on griddle.',
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
  group('Tablet Home Split View Golden Tests', () {
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
          .thenAnswer((_) async => const Right(_testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right([]));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => const Right([]));
    });

    Future<void> pumpTabletHomeScreen(
      WidgetTester tester, {
      RecipeState? recipeState,
      String? selectedLetter,
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

            selectedLetterProvider.overrideWith((ref) => selectedLetter),

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
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testGoldens('Tablet home - Alphabet grid layout', (tester) async {
      expect(ResponsiveHelper.isTablet, isTrue,
          reason: 'Should detect tablet screen size');
      expect(ResponsiveHelper.alphabetGridColumns, equals(4),
          reason: 'Tablet should use 4 columns for alphabet grid');

      await pumpTabletHomeScreen(
        tester,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
        ),
        selectedLetter: null, 
      );

      expect(find.byType(AlphabetGrid), findsOneWidget,
          reason: 'Tablet should display AlphabetGrid');

      await screenMatchesGolden(tester, 'tablet_home_alphabet_grid');
    });

    testGoldens('Tablet home - Letter selected showing recipes',
        (tester) async {
      await pumpTabletHomeScreen(
        tester,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
          selectedLetter: 'A',
        ),
        selectedLetter: 'A', 
      );

      await screenMatchesGolden(tester, 'tablet_home_letter_selected');
    });

    testGoldens('Tablet home - Dark theme', (tester) async {
      await pumpTabletHomeScreen(
        tester,
        theme: AppTheme.darkTheme,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
        ),
        selectedLetter: null,
      );

      await screenMatchesGolden(tester, 'tablet_home_alphabet_grid_dark');
    });

    testGoldens('Tablet home - Loading state', (tester) async {
      await pumpTabletHomeScreen(
        tester,
        recipeState: const RecipeState(
          isLoading: true,
          recipes: [],
        ),
        selectedLetter: null,
      );

      await screenMatchesGolden(tester, 'tablet_home_loading');
    });

    testGoldens('Tablet home - Portrait orientation', (tester) async {
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
            selectedLetterProvider.overrideWith((ref) => null),
            recipeProvider.overrideWith((ref) {
              return TestRecipeViewModel(
                const RecipeState(
                  isLoading: false,
                  recipes: _testRecipes,
                ),
                mockGetAllRecipes,
                mockFavoriteRecipe,
                mockBookmarkRecipe,
              );
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await screenMatchesGolden(tester, 'tablet_home_portrait');
    });

    tearDownAll(() async {
      
    });
  });
}
