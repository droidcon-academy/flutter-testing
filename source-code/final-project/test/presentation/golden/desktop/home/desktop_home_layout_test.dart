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
import 'package:recipevault/presentation/views/recipe/recipe_screen.dart';
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
    name: 'Beef Wellington',
    ingredients: [
      Ingredient(name: 'beef tenderloin', measure: '2 lbs'),
      Ingredient(name: 'puff pastry', measure: '1 sheet'),
    ],
    instructions:
        'Sear beef, wrap in pastry, and bake at 425°F for 25 minutes.',
  ),
  Recipe(
    id: '2',
    name: 'Caesar Salad',
    ingredients: [
      Ingredient(name: 'romaine lettuce', measure: '2 heads'),
      Ingredient(name: 'parmesan cheese', measure: '1/2 cup'),
    ],
    instructions: 'Chop lettuce, add dressing and cheese, toss well.',
  ),
  Recipe(
    id: '3',
    name: 'Chocolate Soufflé',
    ingredients: [
      Ingredient(name: 'dark chocolate', measure: '6 oz'),
      Ingredient(name: 'eggs', measure: '6 large'),
    ],
    instructions:
        'Melt chocolate, fold in egg whites, bake at 375°F for 12 minutes.',
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
  group('Desktop Home Layout Golden Tests', () {
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

    Future<void> pumpDesktopRecipeScreen(
      WidgetTester tester, {
      RecipeState? recipeState,
      int selectedNavIndex = 0,
      ThemeData? theme,
    }) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

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

            currentPageIndexProvider.overrideWith((ref) => selectedNavIndex),

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
            home: const RecipeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testGoldens('Desktop home layout - Recipe screen with nav rail',
        (tester) async {
      await pumpDesktopRecipeScreen(
        tester,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
        ),
        selectedNavIndex: 0, 
      );

      expect(ResponsiveHelper.isDesktop, isTrue,
          reason: 'Should detect desktop screen size');

      await screenMatchesGolden(tester, 'desktop_home_layout_recipe');
    });

    testGoldens('Desktop home layout - Dashboard selected', (tester) async {
      await pumpDesktopRecipeScreen(
        tester,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
        ),
        selectedNavIndex: 1, 
      );

      await screenMatchesGolden(tester, 'desktop_home_layout_dashboard');
    });

    testGoldens('Desktop home layout - Dark theme', (tester) async {
      await pumpDesktopRecipeScreen(
        tester,
        theme: AppTheme.darkTheme,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
        ),
        selectedNavIndex: 0,
      );

      await screenMatchesGolden(tester, 'desktop_home_layout_dark');
    });

    testGoldens('Desktop home layout - Loading state', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

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
                  isLoading: true,
                  recipes: [],
                ),
                mockGetAllRecipes,
                mockFavoriteRecipe,
                mockBookmarkRecipe,
              );
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RecipeScreen(),
          ),
        ),
      );

      await tester.pump();

      await expectLater(
        find.byType(RecipeScreen),
        matchesGoldenFile('goldens/desktop_home_layout_loading.png'),
      );
    });

    testGoldens('Desktop home layout - Wide screen', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(2560, 1440);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

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
            home: const RecipeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await screenMatchesGolden(tester, 'desktop_home_layout_wide');
    });

    tearDownAll(() async {
      
    });
  });
}
