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
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/presentation/views/dashboard/components/dashboard_split_view.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}

class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}

class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

const _testFavoriteRecipes = [
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

const _testBookmarkRecipes = [
  Recipe(
    id: '3',
    name: 'Banana Bread',
    ingredients: [
      Ingredient(name: 'bananas', measure: '3 ripe'),
      Ingredient(name: 'flour', measure: '2 cups'),
    ],
    instructions: 'Mash bananas and bake at 350°F for 60 minutes.',
  ),
];

class TestDashboardViewModel extends DashboardViewModel {
  final DashboardState _fixedState;

  TestDashboardViewModel(
    this._fixedState,
    FavoriteRecipe favoriteRecipe,
    BookmarkRecipe bookmarkRecipe,
    RecipeState recipeState,
    Ref ref,
  ) : super(favoriteRecipe, bookmarkRecipe, recipeState, ref);

  @override
  DashboardState get state => _fixedState;

  @override
  Future<void> initializeData() async {
    
  }
}

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
}

void main() {
  group('Tablet Dashboard Split View Golden Tests', () {
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
          .thenAnswer((_) async => const Right(_testFavoriteRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right(_testFavoriteRecipes));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => const Right(_testBookmarkRecipes));
    });

    Future<void> pumpTabletDashboardSplitView(
      WidgetTester tester, {
      DashboardState? dashboardState,
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

            currentPageIndexProvider.overrideWith((ref) => 1), 

            if (recipeState != null)
              recipeProvider.overrideWith((ref) {
                return TestRecipeViewModel(
                  recipeState,
                  mockGetAllRecipes,
                  mockFavoriteRecipe,
                  mockBookmarkRecipe,
                );
              }),

            if (dashboardState != null)
              dashboardProvider.overrideWith((ref) {
                return TestDashboardViewModel(
                  dashboardState,
                  mockFavoriteRecipe,
                  mockBookmarkRecipe,
                  recipeState ?? const RecipeState(),
                  ref,
                );
              }),
          ],
          child: MaterialApp(
            theme: theme ?? AppTheme.lightTheme,
            home: const DashboardSplitView(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testGoldens('Tablet dashboard split view - Content loaded', (tester) async {
      expect(ResponsiveHelper.isTablet, isTrue,
          reason: 'Should detect tablet screen size');

      await pumpTabletDashboardSplitView(
        tester,
        dashboardState: const DashboardState(
          isLoading: false,
          recipes: [..._testFavoriteRecipes, ..._testBookmarkRecipes],
          favoriteIds: {'1', '2'},
          bookmarkIds: {'3'},
        ),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [..._testFavoriteRecipes, ..._testBookmarkRecipes],
        ),
      );

      await screenMatchesGolden(tester, 'tablet_dashboard_split_view_content');
    });

    testGoldens('Tablet dashboard split view - Dark theme', (tester) async {
      await pumpTabletDashboardSplitView(
        tester,
        theme: AppTheme.darkTheme,
        dashboardState: const DashboardState(
          isLoading: false,
          recipes: [..._testFavoriteRecipes, ..._testBookmarkRecipes],
          favoriteIds: {'1'},
          bookmarkIds: {'3'},
        ),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [..._testFavoriteRecipes, ..._testBookmarkRecipes],
        ),
      );

      await screenMatchesGolden(tester, 'tablet_dashboard_split_view_dark');
    });

    testGoldens('Tablet dashboard split view - Empty favorites',
        (tester) async {
      await pumpTabletDashboardSplitView(
        tester,
        dashboardState: const DashboardState(
          isLoading: false,
          recipes: _testBookmarkRecipes,
          favoriteIds: {},
          bookmarkIds: {'3'},
        ),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testBookmarkRecipes,
        ),
      );

      await screenMatchesGolden(
          tester, 'tablet_dashboard_split_view_empty_favorites');
    });

    testGoldens('Tablet dashboard split view - Loading state', (tester) async {
      await pumpTabletDashboardSplitView(
        tester,
        dashboardState: const DashboardState(
          isLoading: true,
        ),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testFavoriteRecipes,
        ),
      );

      await screenMatchesGolden(tester, 'tablet_dashboard_split_view_loading');
    });

    tearDownAll(() async {
      
    });
  });
}
