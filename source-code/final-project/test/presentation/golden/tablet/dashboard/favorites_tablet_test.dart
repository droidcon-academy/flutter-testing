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
import 'package:recipevault/presentation/views/dashboard/components/favorites/favorites_view.dart';
import 'package:recipevault/presentation/views/dashboard/components/dashboard_split_view.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';

const _testFavoriteRecipes = [
  Recipe(
    id: '1',
    name: 'Apple Pie',
    ingredients: [
      Ingredient(name: 'Apples', measure: '6 large'),
      Ingredient(name: 'Sugar', measure: '1 cup'),
      Ingredient(name: 'Cinnamon', measure: '1 tsp'),
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
      Ingredient(name: 'Sugar', measure: '1.5 cups'),
    ],
    instructions: 'Bake at 180°C for 30 minutes.',
    isFavorite: true,
    isBookmarked: false,
  ),
  Recipe(
    id: '3',
    name: 'Banana Bread',
    ingredients: [
      Ingredient(name: 'Bananas', measure: '3 ripe'),
      Ingredient(name: 'Flour', measure: '1.5 cups'),
      Ingredient(name: 'Sugar', measure: '3/4 cup'),
    ],
    instructions: 'Bake at 175°C for 60 minutes.',
    isFavorite: true,
    isBookmarked: false,
  ),
  Recipe(
    id: '4',
    name: 'Vegetable Soup',
    ingredients: [
      Ingredient(name: 'Mixed vegetables', measure: '2 cups'),
      Ingredient(name: 'Broth', measure: '4 cups'),
      Ingredient(name: 'Herbs', measure: '1 tsp'),
    ],
    instructions: 'Simmer vegetables in broth for 30 minutes.',
    isFavorite: true,
    isBookmarked: false,
  ),
];

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
  group('Tablet FavoritesView Golden Tests - Real Component Tests', () {
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
          .thenAnswer((_) async => const Right([]));
    });

    Future<Widget> createTabletFavoritesTestHarness({
      DashboardState? dashboardState,
      RecipeState? recipeState,
      ThemeData? theme,
      bool useDashboardSplitView = false,
    }) async {
      final prefs = await SharedPreferences.getInstance();

      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),
          favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
          bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),
          currentPageIndexProvider.overrideWith((ref) => 1), 

          if (recipeState != null)
            recipeProvider.overrideWith((ref) => TestRecipeViewModel(
                recipeState,
                mockGetAllRecipes,
                mockFavoriteRecipe,
                mockBookmarkRecipe)),

          if (dashboardState != null)
            dashboardProvider.overrideWith((ref) => TestDashboardViewModel(
                dashboardState,
                mockFavoriteRecipe,
                mockBookmarkRecipe,
                recipeState ?? const RecipeState(),
                ref)),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.lightTheme,
          home: useDashboardSplitView
              ? const DashboardSplitView()
              : const FavoritesView(),
        ),
      );
    }

    Future<void> pumpTabletFavoritesTest(
      WidgetTester tester, {
      required Size screenSize,
      DashboardState? dashboardState,
      RecipeState? recipeState,
      ThemeData? theme,
      bool useDashboardSplitView = false,
    }) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;

      final widget = await createTabletFavoritesTestHarness(
        dashboardState: dashboardState,
        recipeState: recipeState,
        theme: theme,
        useDashboardSplitView: useDashboardSplitView,
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testGoldens('Tablet FavoritesView - List view with favorites',
        (tester) async {
      expect(ResponsiveHelper.isTablet, isTrue,
          reason: 'Should detect tablet screen size for this test');

      await pumpTabletFavoritesTest(
        tester,
        screenSize: const Size(768, 1024), 
        dashboardState: DashboardState(
          isLoading: false,
          recipes: _testFavoriteRecipes,
          favoriteIds: {for (final recipe in _testFavoriteRecipes) recipe.id},
          bookmarkIds: const {},
        ),
      );

      expect(find.byType(FavoritesView), findsOneWidget,
          reason: 'FavoritesView should be displayed');
      expect(find.text('Favorites'), findsOneWidget,
          reason: 'FavoritesView should show Favorites title');

      expect(find.text('Apple Pie'), findsOneWidget,
          reason: 'Should display favorite recipe from dashboardState');
      expect(find.text('Chocolate Cake'), findsOneWidget,
          reason: 'Should display favorite recipe from dashboardState');

      expect(find.byIcon(Icons.grid_view), findsOneWidget,
          reason: 'Should show grid view toggle button');

      await screenMatchesGolden(tester, 'tablet_favorites_list_view');
    });

    testGoldens('Tablet FavoritesView - Grid view after toggle',
        (tester) async {
      await pumpTabletFavoritesTest(
        tester,
        screenSize: const Size(1024, 768), 
        dashboardState: DashboardState(
          isLoading: false,
          recipes: _testFavoriteRecipes,
          favoriteIds: {for (final recipe in _testFavoriteRecipes) recipe.id},
          bookmarkIds: const {},
        ),
      );

      expect(find.byType(FavoritesView), findsOneWidget,
          reason: 'FavoritesView should be displayed');

      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.view_list), findsOneWidget,
          reason: 'Should show list view toggle after switching to grid');

      await screenMatchesGolden(tester, 'tablet_favorites_grid_view');
    });

    testGoldens('Tablet FavoritesView - Empty state', (tester) async {
      await pumpTabletFavoritesTest(
        tester,
        screenSize: const Size(768, 1024), 
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
          reason: 'Should show empty state message');
      expect(find.byIcon(Icons.favorite_border), findsOneWidget,
          reason: 'Should show favorite outline icon in empty state');

      await screenMatchesGolden(tester, 'tablet_favorites_empty_state');
    });

    testGoldens('Tablet FavoritesView - Dark theme', (tester) async {
      await pumpTabletFavoritesTest(
        tester,
        screenSize: const Size(768, 1024),
        theme: AppTheme.darkTheme,
        dashboardState: DashboardState(
          isLoading: false,
          recipes: _testFavoriteRecipes,
          favoriteIds: {for (final recipe in _testFavoriteRecipes) recipe.id},
          bookmarkIds: const {},
        ),
      );

      expect(find.byType(FavoritesView), findsOneWidget,
          reason: 'FavoritesView should be displayed in dark theme');

      await screenMatchesGolden(tester, 'tablet_favorites_dark_theme');
    });

    testGoldens('Tablet FavoritesView - Within DashboardSplitView context',
        (tester) async {
      await pumpTabletFavoritesTest(
        tester,
        screenSize: const Size(1024, 768), 
        useDashboardSplitView: true,
        dashboardState: DashboardState(
          isLoading: false,
          recipes: _testFavoriteRecipes,
          favoriteIds: {for (final recipe in _testFavoriteRecipes) recipe.id},
          bookmarkIds: const {},
        ),
      );

      expect(find.byType(DashboardSplitView), findsOneWidget,
          reason: 'DashboardSplitView should be displayed');
      expect(find.byType(FavoritesView), findsOneWidget,
          reason: 'FavoritesView should be within DashboardSplitView');

      expect(find.byType(Row), findsWidgets,
          reason: 'DashboardSplitView should use Row layout');
      expect(find.byType(VerticalDivider), findsOneWidget,
          reason: 'Should show vertical divider between panels');

      await screenMatchesGolden(tester, 'tablet_favorites_split_view_context');
    });

    testGoldens('Tablet FavoritesView - Responsive grid columns',
        (tester) async {
      await pumpTabletFavoritesTest(
        tester,
        screenSize: const Size(1200, 800), 
        dashboardState: DashboardState(
          isLoading: false,
          recipes: _testFavoriteRecipes,
          favoriteIds: {for (final recipe in _testFavoriteRecipes) recipe.id},
          bookmarkIds: const {},
        ),
      );

      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesView), findsOneWidget,
          reason: 'FavoritesView should be displayed');

      await screenMatchesGolden(tester, 'tablet_favorites_responsive_columns');
    });

    tearDownAll(() async {
      
    });
  });
}
