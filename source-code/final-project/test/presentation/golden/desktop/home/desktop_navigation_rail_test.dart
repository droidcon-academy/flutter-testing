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
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/presentation/views/recipe/recipe_screen.dart';
import 'package:recipevault/presentation/widgets/navigation/nav_rail.dart';
import 'package:recipevault/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';

const _mockRecipes = [
  Recipe(
    id: '1',
    name: 'Spaghetti Carbonara',
    ingredients: [
      Ingredient(name: 'spaghetti', measure: '400g'),
      Ingredient(name: 'eggs', measure: '3 large'),
    ],
    instructions: 'Cook pasta, mix with eggs and cheese.',
  ),
  Recipe(
    id: '2',
    name: 'Chicken Tikka Masala',
    ingredients: [
      Ingredient(name: 'chicken breast', measure: '500g'),
      Ingredient(name: 'tomatoes', measure: '400g'),
    ],
    instructions: 'Marinate chicken, cook with tomatoes.',
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
  Future<void> loadRecipes() async {}

  @override
  void setSelectedLetter(String? letter) {}
}

void main() {
  group('Desktop Navigation Rail Golden Tests', () {
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
          .thenAnswer((_) async => const Right(_mockRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right([_mockRecipes[0]]));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right([_mockRecipes[1]]));
    });

    Future<Widget> createNavRailTestHarness({
      required int selectedNavIndex,
      RecipeState? initialRecipeState,
      ThemeData? theme,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      return ProviderScope(
        overrides: [
          favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
          bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),
          getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentPageIndexProvider.overrideWith((ref) => selectedNavIndex),

          if (initialRecipeState != null)
            recipeProvider.overrideWith((ref) => TestRecipeViewModel(
                initialRecipeState,
                mockGetAllRecipes,
                mockFavoriteRecipe,
                mockBookmarkRecipe)),
        ],
        child: MaterialApp(
          home:
              const RecipeScreen(), 
          theme: theme ?? AppTheme.lightTheme,
        ),
      );
    }

    Future<void> pumpNavRailInRecipeScreen(
      WidgetTester tester, {
      required int selectedNavIndex,
      required Size screenSize,
      RecipeState? recipeState,
      ThemeData? theme,
    }) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final widget = await createNavRailTestHarness(
        selectedNavIndex: selectedNavIndex,
        initialRecipeState: recipeState,
        theme: theme,
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testGoldens('Desktop NavRail - Recipe selected at 1200px', (tester) async {
      await pumpNavRailInRecipeScreen(
        tester,
        selectedNavIndex: 0, 
        screenSize: const Size(1200, 800), 
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
      );

      expect(find.byType(RecipeScreen), findsOneWidget,
          reason: 'RecipeScreen should be displayed');
      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'RecipeScreen should use ResponsiveLayoutBuilder');

      expect(find.byType(NavRail), findsOneWidget,
          reason: 'Desktop layout should show navigation rail');
      expect(find.byType(NavBar), findsNothing,
          reason: 'Desktop layout should not show bottom navigation');

      final navRail = tester.widget<NavRail>(find.byType(NavRail));
      expect(navRail.selectedIndex, equals(0),
          reason: 'Recipe destination should be selected');

      expect(find.byType(Row), findsWidgets,
          reason: 'Desktop layout should use Row layout');
      expect(find.byType(VerticalDivider), findsAtLeastNWidgets(1),
          reason: 'Desktop layout should include vertical divider');

      await screenMatchesGolden(tester, 'desktop_nav_rail_recipe_selected');
    });

    testGoldens('Desktop NavRail - Dashboard selected at 1200px',
        (tester) async {
      await pumpNavRailInRecipeScreen(
        tester,
        selectedNavIndex: 1, 
        screenSize: const Size(1200, 800), 
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
      );

      expect(find.byType(NavRail), findsOneWidget,
          reason: 'Desktop layout should show navigation rail');
      expect(find.byType(NavBar), findsNothing,
          reason: 'Desktop layout should not show bottom navigation');

      final navRail = tester.widget<NavRail>(find.byType(NavRail));
      expect(navRail.selectedIndex, equals(1),
          reason: 'Dashboard destination should be selected');

      await screenMatchesGolden(tester, 'desktop_nav_rail_dashboard_selected');
    });

    testGoldens('Desktop NavRail - Dark theme at 1200px', (tester) async {
      await pumpNavRailInRecipeScreen(
        tester,
        selectedNavIndex: 0,
        screenSize: const Size(1200, 800),
        theme: AppTheme.darkTheme,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
      );

      expect(find.byType(NavRail), findsOneWidget,
          reason: 'Dark theme should still show navigation rail on desktop');
      expect(find.byType(NavBar), findsNothing,
          reason: 'Dark theme should not show bottom navigation on desktop');

      await screenMatchesGolden(tester, 'desktop_nav_rail_dark_theme');
    });

    testGoldens('Desktop NavRail - Wide screen at 1600px', (tester) async {
      await pumpNavRailInRecipeScreen(
        tester,
        selectedNavIndex: 1,
        screenSize: const Size(1600, 900),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
      );

      expect(find.byType(NavRail), findsOneWidget,
          reason: 'Wide desktop should still show navigation rail');
      expect(find.byType(NavBar), findsNothing,
          reason: 'Wide desktop should not show bottom navigation');

      await screenMatchesGolden(tester, 'desktop_nav_rail_wide_screen');
    });

    testGoldens('Responsive - NavRail disappears on tablet at 1024px',
        (tester) async {
      await pumpNavRailInRecipeScreen(
        tester,
        selectedNavIndex: 0,
        screenSize: const Size(1024, 768), 
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
      );

      expect(find.byType(NavBar), findsOneWidget,
          reason: 'Tablet size should show bottom navigation');
      expect(find.byType(NavRail), findsNothing,
          reason: 'Tablet size should not show navigation rail');

      await screenMatchesGolden(tester, 'desktop_nav_rail_tablet_responsive');
    });

    testGoldens('Responsive - NavRail disappears on mobile at 600px',
        (tester) async {
      await pumpNavRailInRecipeScreen(
        tester,
        selectedNavIndex: 0,
        screenSize: const Size(600, 800), 
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
      );

      expect(find.byType(NavBar), findsOneWidget,
          reason: 'Mobile size should show bottom navigation');
      expect(find.byType(NavRail), findsNothing,
          reason: 'Mobile size should not show navigation rail');

      await screenMatchesGolden(tester, 'desktop_nav_rail_mobile_responsive');
    });

    testGoldens('Desktop NavRail - Breakpoint boundary at 1025px',
        (tester) async {
      await pumpNavRailInRecipeScreen(
        tester,
        selectedNavIndex: 1,
        screenSize: const Size(1025, 768), 
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _mockRecipes,
        ),
      );

      expect(find.byType(NavRail), findsOneWidget,
          reason: 'At 1025px should show NavRail (desktop layout)');
      expect(find.byType(NavBar), findsNothing,
          reason: 'At 1025px should not show NavBar');

      await screenMatchesGolden(tester, 'desktop_nav_rail_boundary_1025');
    });

    tearDownAll(() async {
      
    });
  });
}
