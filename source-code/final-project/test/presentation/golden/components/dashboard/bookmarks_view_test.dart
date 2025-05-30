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
import 'package:recipevault/presentation/views/dashboard/components/bookmarks/bookmarks_view.dart';
import 'package:recipevault/presentation/views/dashboard/dashboard_screen.dart';

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

const _mockBookmarkRecipes = [
  Recipe(
    id: '1',
    name: 'Banana Bread',
    ingredients: [
      Ingredient(name: 'Bananas', measure: '3 ripe'),
      Ingredient(name: 'Flour', measure: '1.5 cups'),
      Ingredient(name: 'Sugar', measure: '3/4 cup'),
    ],
    instructions: 'Bake at 175°C for 60 minutes.',
    isFavorite: false,
    isBookmarked: true,
  ),
  Recipe(
    id: '2',
    name: 'Vegetable Soup',
    ingredients: [
      Ingredient(name: 'Mixed vegetables', measure: '2 cups'),
      Ingredient(name: 'Broth', measure: '4 cups'),
      Ingredient(name: 'Herbs', measure: '1 tsp'),
    ],
    instructions: 'Simmer vegetables in broth for 30 minutes.',
    isFavorite: false,
    isBookmarked: true,
  ),
  Recipe(
    id: '3',
    name: 'Pasta Salad',
    ingredients: [
      Ingredient(name: 'Pasta', measure: '2 cups'),
      Ingredient(name: 'Vegetables', measure: '1 cup'),
    ],
    instructions: 'Cook pasta, mix with vegetables.',
    isFavorite: false,
    isBookmarked: true,
  ),
];

void main() {
  group('Bookmarks View Golden Tests - Real Components', () {
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
          .thenAnswer((_) async => const Right(_mockBookmarkRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right([]));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => const Right(_mockBookmarkRecipes));
    });

    Future<Widget> createBookmarksTestHarness({
      DashboardState? dashboardState,
      RecipeState? recipeState,
      ThemeData? theme,
      bool useDashboardScreen = false,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final testDashboardState = dashboardState ??
          DashboardState(
            isLoading: false,
            recipes: _mockBookmarkRecipes,
            favoriteIds: const {},
            bookmarkIds: {
              _mockBookmarkRecipes[0].id,
              _mockBookmarkRecipes[1].id,
              _mockBookmarkRecipes[2].id
            },
          );

      final testRecipeState = recipeState ??
          const RecipeState(
            isLoading: false,
            recipes: _mockBookmarkRecipes,
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
          home: useDashboardScreen
              ? const DashboardScreen() 
              : const BookmarksView(),
          theme: theme ?? AppTheme.lightTheme,
        ),
      );
    }

    Future<void> pumpBookmarksView(
      WidgetTester tester, {
      required Size screenSize,
      DashboardState? dashboardState,
      RecipeState? recipeState,
      ThemeData? theme,
      bool useDashboardScreen = false,
    }) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;

      final widget = await createBookmarksTestHarness(
        dashboardState: dashboardState,
        recipeState: recipeState,
        theme: theme,
        useDashboardScreen: useDashboardScreen,
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    group('BookmarksView List and Grid Views', () {
      testGoldens('BookmarksView - List view with bookmarks', (tester) async {
        await pumpBookmarksView(
          tester,
          screenSize: const Size(375, 600), 
        );

        expect(find.byType(BookmarksView), findsOneWidget,
            reason: 'BookmarksView should be displayed');
        expect(find.text('Bookmarks'), findsOneWidget,
            reason: 'BookmarksView should show Bookmarks title');

        expect(find.text('Banana Bread'), findsOneWidget,
            reason: 'Should display bookmark recipe from dashboardState');
        expect(find.text('Vegetable Soup'), findsOneWidget,
            reason: 'Should display bookmark recipe from dashboardState');

        expect(find.byIcon(Icons.grid_view), findsOneWidget,
            reason: 'Should show grid view toggle button');

        await screenMatchesGolden(tester, 'bookmarks_list_view_standard');
      });

      testGoldens('BookmarksView - Grid view toggle', (tester) async {
        await pumpBookmarksView(
          tester,
          screenSize: const Size(375, 600), 
        );

        expect(find.byType(BookmarksView), findsOneWidget,
            reason: 'BookmarksView should be displayed');

        await tester.tap(find.byIcon(Icons.grid_view));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.view_list), findsOneWidget,
            reason:
                'Should show list view toggle button after switching to grid');

        await screenMatchesGolden(tester, 'bookmarks_grid_view_2_columns');
      });

      testGoldens('BookmarksView - Dark theme', (tester) async {
        await pumpBookmarksView(
          tester,
          screenSize: const Size(375, 600), 
          theme: AppTheme.darkTheme,
        );

        expect(find.byType(BookmarksView), findsOneWidget,
            reason: 'BookmarksView should be displayed in dark theme');

        await screenMatchesGolden(tester, 'bookmarks_view_dark_theme');
      });
    });

    group('BookmarksView Empty States', () {
      testGoldens('BookmarksView - Empty state', (tester) async {
        await pumpBookmarksView(
          tester,
          screenSize: const Size(375, 600),
          dashboardState: const DashboardState(
            isLoading: false,
            recipes: [],
            favoriteIds: {},
            bookmarkIds: {},
          ),
        );

        expect(find.byType(BookmarksView), findsOneWidget,
            reason: 'BookmarksView should be displayed');
        expect(find.text('No bookmarked recipes yet'), findsOneWidget,
            reason: 'Should show empty state message');
        expect(find.byIcon(Icons.bookmark_border), findsOneWidget,
            reason: 'Should show empty state icon');

        await screenMatchesGolden(tester, 'bookmarks_empty_state');
      });

      testGoldens('BookmarksView - Empty state dark theme', (tester) async {
        await pumpBookmarksView(
          tester,
          screenSize: const Size(375, 600), 
          theme: AppTheme.darkTheme,
          dashboardState: const DashboardState(
            isLoading: false,
            recipes: [],
            favoriteIds: {},
            bookmarkIds: {},
          ),
        );

        expect(find.byType(BookmarksView), findsOneWidget,
            reason: 'BookmarksView should be displayed in dark theme');

        await screenMatchesGolden(tester, 'bookmarks_empty_state_dark_theme');
      });
    });

    group('BookmarksView Responsive Layouts', () {
      testGoldens('BookmarksView - Tablet layout', (tester) async {
        await pumpBookmarksView(
          tester,
          screenSize: const Size(768, 1024), 
        );

        expect(find.byType(BookmarksView), findsOneWidget,
            reason: 'BookmarksView should be displayed on tablet');

        expect(find.text('Bookmarks'), findsOneWidget,
            reason: 'Should maintain title on tablet');

        await screenMatchesGolden(tester, 'bookmarks_tablet_layout');
      });

    });


    tearDownAll(() async {
    });
  });
}
