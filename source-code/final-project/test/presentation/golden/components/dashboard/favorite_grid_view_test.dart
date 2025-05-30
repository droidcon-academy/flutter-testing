import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recipevault/core/themes/app_theme.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/views/dashboard/components/favorites/favorite_grid_view.dart';
import 'package:recipevault/presentation/views/dashboard/components/favorites/favorites_view.dart';
import 'package:recipevault/presentation/views/dashboard/dashboard_screen.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';

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
  Future<void> initializeData() async {}
}

const _mockFavoriteRecipes = [
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

void main() {
  group('Favorite Grid View Golden Tests - Real Components', () {
    late MockGetAllRecipes mockGetAllRecipes;
    late MockFavoriteRecipe mockFavoriteRecipe;
    late MockBookmarkRecipe mockBookmarkRecipe;

    setUpAll(() async {
      await loadAppFonts();

      registerFallbackValue(FakeGetAllRecipesParams());
      registerFallbackValue(FakeFavoriteRecipeParams());
      registerFallbackValue(FakeBookmarkRecipeParams());
    });

    setUp(() async {
      mockGetAllRecipes = MockGetAllRecipes();
      mockFavoriteRecipe = MockFavoriteRecipe();
      mockBookmarkRecipe = MockBookmarkRecipe();

      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => const Right(_mockFavoriteRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right(_mockFavoriteRecipes));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => const Right([]));
    });

    Future<Widget> createFavoriteGridTestHarness({
      DashboardState? dashboardState,
      RecipeState? recipeState,
      ThemeData? theme,
      bool useFavoritesView = false,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final testDashboardState = dashboardState ??
          DashboardState(
            isLoading: false,
            recipes: _mockFavoriteRecipes,
            favoriteIds: {
              _mockFavoriteRecipes[0].id,
              _mockFavoriteRecipes[1].id,
              _mockFavoriteRecipes[2].id,
              _mockFavoriteRecipes[3].id,
            },
            bookmarkIds: const {},
          );

      final testRecipeState = recipeState ??
          const RecipeState(
            isLoading: false,
            recipes: _mockFavoriteRecipes,
          );

      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dashboardProvider.overrideWith((ref) => TestDashboardViewModel(
              testDashboardState,
              mockFavoriteRecipe,
              mockBookmarkRecipe,
              testRecipeState,
              ref)),
        ],
        child: MaterialApp(
          home: useFavoritesView
              ? const FavoritesView() 
              : FavoriteGridView(
                  recipes: testDashboardState.favoriteRecipes,
                  onRecipeSelected: (_) {},
                  storageKey: 'test_favorites_grid',
                ),
          theme: theme ?? AppTheme.lightTheme,
        ),
      );
    }

    Future<void> pumpFavoriteGridView(
      WidgetTester tester, {
      required Size screenSize,
      DashboardState? dashboardState,
      RecipeState? recipeState,
      ThemeData? theme,
      bool useFavoritesView = false,
    }) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;

      final widget = await createFavoriteGridTestHarness(
        dashboardState: dashboardState,
        recipeState: recipeState,
        theme: theme,
        useFavoritesView: useFavoritesView,
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    group('FavoriteGridView Responsive Grid Layouts', () {
      testGoldens('FavoriteGridView - Mobile 2 columns', (tester) async {
        await pumpFavoriteGridView(
          tester,
          screenSize: const Size(375, 667),
        );

        expect(find.byType(FavoriteGridView), findsOneWidget,
            reason: 'FavoriteGridView should be displayed');

        expect(find.text('Apple Pie'), findsOneWidget,
            reason: 'Should display favorite recipe from dashboardState');
        expect(find.text('Chocolate Cake'), findsOneWidget,
            reason: 'Should display favorite recipe from dashboardState');

        await screenMatchesGolden(tester, 'favorite_grid_view_2_columns');
      });

      testGoldens('FavoriteGridView - Tablet 3 columns', (tester) async {
        await pumpFavoriteGridView(
          tester,
          screenSize: const Size(768, 1024), 
        );

        expect(find.byType(FavoriteGridView), findsOneWidget,
            reason: 'FavoriteGridView should be displayed on tablet');

        expect(find.text('Apple Pie'), findsOneWidget,
            reason: 'Should display favorite recipes in tablet layout');

        await screenMatchesGolden(
            tester, 'favorite_grid_view_tablet_3_columns');
      });

      testGoldens('FavoriteGridView - Desktop responsive', (tester) async {
        await pumpFavoriteGridView(
          tester,
          screenSize: const Size(1200, 800), 
        );

        expect(find.byType(FavoriteGridView), findsOneWidget,
            reason: 'FavoriteGridView should be displayed on desktop');

        await screenMatchesGolden(
            tester, 'favorite_grid_view_desktop_responsive');
      });
    });

    group('FavoriteGridView within FavoritesView Context', () {
      testGoldens('FavoriteGridView - Within FavoritesView toggle context',
          (tester) async {
        await pumpFavoriteGridView(
          tester,
          screenSize: const Size(375, 600), 
          useFavoritesView: true,
        );

        expect(find.byType(FavoritesView), findsOneWidget,
            reason: 'FavoritesView should be displayed');

        await tester.tap(find.byIcon(Icons.grid_view));
        await tester.pumpAndSettle();

        expect(find.byType(FavoriteGridView), findsOneWidget,
            reason: 'Should show FavoriteGridView after toggle');
        expect(find.byIcon(Icons.view_list), findsOneWidget,
            reason:
                'Should show list view toggle button after switching to grid');

        await screenMatchesGolden(
            tester, 'favorite_grid_view_within_favorites_view');
      });
    });

    group('FavoriteGridView Different States', () {
      testGoldens('FavoriteGridView - Single row layout', (tester) async {
        await pumpFavoriteGridView(
          tester,
          screenSize: const Size(375, 500), 
          dashboardState: DashboardState(
            isLoading: false,
            recipes: [
              _mockFavoriteRecipes[0],
              _mockFavoriteRecipes[1]
            ],
            favoriteIds: {
              _mockFavoriteRecipes[0].id,
              _mockFavoriteRecipes[1].id
            },
            bookmarkIds: const {},
          ),
        );

        expect(find.byType(FavoriteGridView), findsOneWidget,
            reason: 'FavoriteGridView should be displayed');
        expect(find.text('Apple Pie'), findsOneWidget,
            reason: 'Should display first favorite recipe');

        await screenMatchesGolden(tester, 'favorite_grid_view_single_row');
      });

      testGoldens('FavoriteGridView - Dark theme', (tester) async {
        await pumpFavoriteGridView(
          tester,
          screenSize: const Size(375, 667), 
          theme: AppTheme.darkTheme,
        );

        expect(find.byType(FavoriteGridView), findsOneWidget,
            reason: 'FavoriteGridView should be displayed in dark theme');

        await screenMatchesGolden(tester, 'favorite_grid_view_dark_theme');
      });

      testGoldens('FavoriteGridView - Compact card layout', (tester) async {
        await pumpFavoriteGridView(
          tester,
          screenSize: const Size(375, 600), 
        );

        expect(find.byType(FavoriteGridView), findsOneWidget,
            reason: 'FavoriteGridView should be displayed in compact layout');

        await screenMatchesGolden(tester, 'favorite_grid_view_compact_cards');
      });
    });

    tearDownAll(() async {
    });
  });
}
