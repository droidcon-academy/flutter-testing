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
import 'package:recipevault/presentation/views/dashboard/dashboard_screen.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';

const _mockRecipe = Recipe(
  id: '1',
  name: 'Spaghetti Carbonara',
  ingredients: [
    Ingredient(name: 'spaghetti', measure: '400g'),
    Ingredient(name: 'eggs', measure: '3 large'),
    Ingredient(name: 'parmesan cheese', measure: '100g'),
    Ingredient(name: 'pancetta', measure: '150g'),
  ],
  instructions: 'Cook pasta, mix with eggs and cheese, add pancetta.',
);

const _mockFavoriteRecipe = Recipe(
  id: '2',
  name: 'Chicken Tikka Masala',
  ingredients: [
    Ingredient(name: 'chicken breast', measure: '500g'),
    Ingredient(name: 'tomatoes', measure: '400g'),
    Ingredient(name: 'cream', measure: '200ml'),
    Ingredient(name: 'spices', measure: 'mixed'),
  ],
  instructions: 'Marinate chicken, cook with tomatoes and cream.',
);

const _mockBookmarkRecipe = Recipe(
  id: '3',
  name: 'Caesar Salad',
  ingredients: [
    Ingredient(name: 'romaine lettuce', measure: '2 heads'),
    Ingredient(name: 'parmesan cheese', measure: '50g'),
    Ingredient(name: 'croutons', measure: '1 cup'),
    Ingredient(name: 'dressing', measure: 'caesar'),
  ],
  instructions: 'Chop lettuce, add cheese, croutons, and dressing.',
);

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
}

class TestDashboardViewModel extends DashboardViewModel {
  final DashboardState _fixedState;

  TestDashboardViewModel(
    this._fixedState,
    FavoriteRecipe favoriteRecipe,
    BookmarkRecipe bookmarkRecipe,
    RecipeState recipeState,
    StateNotifierProviderRef<DashboardViewModel, DashboardState> ref,
  ) : super(favoriteRecipe, bookmarkRecipe, recipeState, ref);

  @override
  DashboardState get state => _fixedState;

  @override
  Future<void> initializeData() async {
    
  }
}

void main() {
  group('Desktop Dashboard Layout Golden Tests', () {
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

      when(() => mockGetAllRecipes(any())).thenAnswer((_) async =>
          const Right([_mockRecipe, _mockFavoriteRecipe, _mockBookmarkRecipe]));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right([_mockFavoriteRecipe]));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => const Right([_mockBookmarkRecipe]));
    });

    Future<void> pumpDesktopDashboardScreen(
      WidgetTester tester, {
      DashboardState? dashboardState,
      RecipeState? recipeState,
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
            home:
                const DashboardScreen(), 
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testGoldens('Desktop dashboard - Basic layout with navigation rail',
        (tester) async {
      await pumpDesktopDashboardScreen(
        tester,
        dashboardState: const DashboardState(
          isLoading: false,
          recipes: [_mockRecipe, _mockFavoriteRecipe, _mockBookmarkRecipe],
          favoriteIds: {'2'},
          bookmarkIds: {'3'},
        ),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [_mockRecipe, _mockFavoriteRecipe, _mockBookmarkRecipe],
        ),
      );

      expect(find.byType(DashboardScreen), findsOneWidget,
          reason: 'DashboardScreen should be displayed');

      expect(find.byType(VerticalDivider), findsWidgets,
          reason: 'Desktop layout should include vertical divider');

      await screenMatchesGolden(tester, 'desktop_dashboard_basic_layout');
    });

    testGoldens('Desktop dashboard - Dark theme', (tester) async {
      await pumpDesktopDashboardScreen(
        tester,
        theme: AppTheme.darkTheme,
        dashboardState: const DashboardState(
          isLoading: false,
          recipes: [_mockRecipe, _mockFavoriteRecipe, _mockBookmarkRecipe],
          favoriteIds: {'2'},
          bookmarkIds: {'3'},
        ),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [_mockRecipe, _mockFavoriteRecipe, _mockBookmarkRecipe],
        ),
      );

      await screenMatchesGolden(tester, 'desktop_dashboard_dark_theme');
    });

    testGoldens('Desktop dashboard - Wide screen layout', (tester) async {
      await pumpDesktopDashboardScreen(
        tester,
        screenSize: const Size(1600, 900), 
        dashboardState: const DashboardState(
          isLoading: false,
          recipes: [_mockRecipe, _mockFavoriteRecipe, _mockBookmarkRecipe],
          favoriteIds: {'2'},
          bookmarkIds: {'3'},
        ),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [_mockRecipe, _mockFavoriteRecipe, _mockBookmarkRecipe],
        ),
      );

      await screenMatchesGolden(tester, 'desktop_dashboard_wide_layout');
    });

    testGoldens('Desktop dashboard - Loading state', (tester) async {
      await pumpDesktopDashboardScreen(
        tester,
        dashboardState: const DashboardState(isLoading: true),
        recipeState: const RecipeState(isLoading: false, recipes: []),
      );

      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile('goldens/desktop_dashboard_loading.png'),
      );
    });

    testGoldens('Desktop dashboard - Empty state', (tester) async {
      await pumpDesktopDashboardScreen(
        tester,
        dashboardState: const DashboardState(
          isLoading: false,
          recipes: [],
          favoriteIds: {},
          bookmarkIds: {},
        ),
        recipeState: const RecipeState(isLoading: false, recipes: []),
      );

      await screenMatchesGolden(tester, 'desktop_dashboard_empty_state');
    });

    tearDownAll(() async {
    });
  });
}
