import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import 'package:recipevault/core/themes/app_theme.dart';
import 'package:recipevault/core/utils/responsive_helper.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/views/recipe/recipe_screen.dart';
import 'package:recipevault/presentation/widgets/navigation/nav_rail.dart';
import 'package:recipevault/presentation/widgets/navigation/bottom_nav_bar.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';
import 'package:recipevault/presentation/viewmodels/navigation_viewmodel.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mockRecipes = [
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
}

void main() {
  group('Desktop Recipe Layout Golden Tests', () {
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
          .thenAnswer((_) async => Right([_mockRecipes[1]]));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right([_mockRecipes[2]]));
    });

    Future<Widget> createDesktopRecipeTestHarness({
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

          currentPageIndexProvider.overrideWith((ref) => 0),

          if (initialRecipeState != null)
            recipeProvider.overrideWith((ref) => TestRecipeViewModel(
                initialRecipeState,
                mockGetAllRecipes,
                mockFavoriteRecipe,
                mockBookmarkRecipe)),
        ],
        child: MaterialApp(
          home: const RecipeScreen(), 
          theme: theme ?? AppTheme.lightTheme,
        ),
      );
    }

    Future<void> pumpDesktopRecipeScreen(
      WidgetTester tester, {
      RecipeState? recipeState,
      ThemeData? theme,
      Size? screenSize,
    }) async {
      final size = screenSize ?? const Size(1200, 800);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      addTearDown(tester.view.resetPhysicalSize);

      final widget = await createDesktopRecipeTestHarness(
        initialRecipeState: recipeState,
        theme: theme,
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testGoldens('Desktop recipe - Grid layout with navigation rail',
        (tester) async {
      await pumpDesktopRecipeScreen(
        tester,
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

      expect(find.byType(Row), findsWidgets,
          reason: 'Desktop layout should use Row layout');
      expect(find.byType(VerticalDivider), findsAtLeastNWidgets(1),
          reason: 'Desktop layout should include vertical divider');

      expect(find.byType(IndexedStack), findsOneWidget,
          reason: 'Should have IndexedStack for page navigation');

      await screenMatchesGolden(tester, 'desktop_recipe_grid_layout');
    });

    testGoldens('Desktop recipe - Dark theme layout', (tester) async {
      await pumpDesktopRecipeScreen(
        tester,
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

      await screenMatchesGolden(tester, 'desktop_recipe_dark_theme');
    });

    testGoldens('Desktop recipe - Wide screen responsive layout',
        (tester) async {
      await pumpDesktopRecipeScreen(
        tester,
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

      final expectedColumns = ResponsiveHelper.recipeGridColumns(
        tester.element(find.byType(RecipeScreen)),
      );
      expect(expectedColumns, greaterThan(2),
          reason:
              'Wide desktop should use more than 2 columns for recipe grid');

      await screenMatchesGolden(tester, 'desktop_recipe_wide_layout');
    });

    testGoldens('Desktop recipe - Loading state', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final widget = await createDesktopRecipeTestHarness(
        initialRecipeState: const RecipeState(isLoading: true, recipes: []),
        theme: AppTheme.lightTheme,
      );
      await tester.pumpWidget(widget);

      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byType(RecipeScreen),
        matchesGoldenFile('goldens/desktop_recipe_loading.png'),
      );
    });

    testGoldens('Desktop recipe - Empty state', (tester) async {
      await pumpDesktopRecipeScreen(
        tester,
        recipeState: const RecipeState(isLoading: false, recipes: []),
      );

      expect(find.byType(NavRail), findsOneWidget,
          reason: 'Empty state should still show navigation rail on desktop');
      expect(find.byType(NavBar), findsNothing,
          reason: 'Empty state should not show bottom navigation on desktop');

      await screenMatchesGolden(tester, 'desktop_recipe_empty_state');
    });

    tearDownAll(() async {
      
    });
  });
}
