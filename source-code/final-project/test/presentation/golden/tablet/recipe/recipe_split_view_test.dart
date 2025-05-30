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
import 'package:recipevault/presentation/views/recipe/components/recipe_split_view.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_list_view.dart';
import 'package:recipevault/presentation/views/recipe/components/recipe_grid_view.dart';
import 'package:recipevault/presentation/views/home/home_screen.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';

const _testRecipes = [
  Recipe(
    id: '1',
    name: 'Spaghetti Carbonara',
    ingredients: [
      Ingredient(name: 'spaghetti pasta', measure: '400g'),
      Ingredient(name: 'large eggs', measure: '3'),
      Ingredient(name: 'parmesan cheese', measure: '100g'),
      Ingredient(name: 'pancetta', measure: '150g'),
    ],
    instructions: 'Cook pasta, mix with eggs and cheese, add pancetta.',
    isFavorite: true,
    isBookmarked: false,
  ),
  Recipe(
    id: '2',
    name: 'Chicken Teriyaki',
    ingredients: [
      Ingredient(name: 'chicken breast', measure: '500g'),
      Ingredient(name: 'teriyaki sauce', measure: '3 tbsp'),
      Ingredient(name: 'soy sauce', measure: '2 tbsp'),
    ],
    instructions: 'Marinate chicken, cook with teriyaki sauce.',
    isFavorite: false,
    isBookmarked: true,
  ),
  Recipe(
    id: '3',
    name: 'Caesar Salad',
    ingredients: [
      Ingredient(name: 'romaine lettuce', measure: '2 heads'),
      Ingredient(name: 'parmesan cheese', measure: '50g'),
      Ingredient(name: 'croutons', measure: '1 cup'),
    ],
    instructions: 'Chop lettuce, add dressing and cheese.',
    isFavorite: false,
    isBookmarked: false,
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

  @override
  void setSelectedRecipe(Recipe? recipe) {
  }
}

void main() {
  group('Tablet Recipe Split View Golden Tests - Real Component Tests', () {
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

    Future<Widget> createRecipeSplitViewTestHarness({
      RecipeState? recipeState,
      ThemeData? theme,
      String? selectedLetter,
      Widget? customContent,
    }) async {
      final prefs = await SharedPreferences.getInstance();

      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),
          favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
          bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),
          selectedLetterProvider.overrideWith((ref) => selectedLetter),
          currentPageIndexProvider.overrideWith((ref) => 0),
          if (recipeState != null)
            recipeProvider.overrideWith((ref) => TestRecipeViewModel(
                recipeState,
                mockGetAllRecipes,
                mockFavoriteRecipe,
                mockBookmarkRecipe)),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.lightTheme,
          home: customContent ?? const RecipeSplitView(),
        ),
      );
    }

    Future<void> pumpRecipeSplitViewTest(
      WidgetTester tester, {
      required Size screenSize,
      RecipeState? recipeState,
      ThemeData? theme,
      String? selectedLetter,
      Widget? customContent,
    }) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;

      final widget = await createRecipeSplitViewTestHarness(
        recipeState: recipeState,
        theme: theme,
        selectedLetter: selectedLetter,
        customContent: customContent,
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testGoldens('RecipeSplitView - Full layout with recipes', (tester) async {
      await pumpRecipeSplitViewTest(
        tester,
        screenSize: const Size(1024, 768),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
        ),
      );

      expect(find.byType(RecipeSplitView), findsOneWidget,
          reason: 'Should display RecipeSplitView');
      expect(find.byType(RecipeListView), findsOneWidget,
          reason: 'Should display RecipeListView in left panel');
      expect(find.byType(RecipeGridView), findsOneWidget,
          reason: 'Should display RecipeGridView in right panel');

      for (final recipe in _testRecipes) {
        expect(find.textContaining(recipe.name), findsAtLeast(1),
            reason: 'Should display recipe: ${recipe.name}');
      }

      expect(find.byType(Row), findsWidgets,
          reason: 'Should use Row layout for split view');
      expect(find.byType(VerticalDivider), findsOneWidget,
          reason: 'Should show vertical divider between panels');

      await screenMatchesGolden(tester, 'tablet_recipe_split_view_full');
    });

    testGoldens('RecipeSplitView - Empty state handling', (tester) async {
      await pumpRecipeSplitViewTest(
        tester,
        screenSize: const Size(1024, 768),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [],
        ),
      );

      expect(find.byType(RecipeSplitView), findsOneWidget,
          reason: 'Should display RecipeSplitView even when empty');
      expect(find.byType(RecipeListView), findsOneWidget,
          reason: 'Should display RecipeListView in empty state');
      expect(find.byType(RecipeGridView), findsOneWidget,
          reason: 'Should display RecipeGridView in empty state');

      expect(find.textContaining('No recipes found'), findsAtLeast(1),
          reason: 'Should show empty state message');

      await screenMatchesGolden(tester, 'tablet_recipe_split_view_empty');
    });

    testGoldens('RecipeSplitView - Dark theme integration', (tester) async {
      await pumpRecipeSplitViewTest(
        tester,
        screenSize: const Size(1024, 768), 
        theme: AppTheme.darkTheme,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
        ),
      );

      expect(find.byType(RecipeSplitView), findsOneWidget,
          reason: 'Should display RecipeSplitView in dark theme');

      expect(find.byType(RecipeListView), findsOneWidget,
          reason: 'Should display RecipeListView in dark theme');
      expect(find.byType(RecipeGridView), findsOneWidget,
          reason: 'Should display RecipeGridView in dark theme');

      await screenMatchesGolden(tester, 'tablet_recipe_split_view_dark');
    });

    testGoldens('RecipeSplitView - Tablet portrait layout', (tester) async {
      await pumpRecipeSplitViewTest(
        tester,
        screenSize: const Size(768, 1024),
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
        ),
      );

      expect(find.byType(RecipeSplitView), findsOneWidget,
          reason: 'Should display RecipeSplitView in portrait');

      expect(find.byType(RecipeListView), findsOneWidget,
          reason: 'Should maintain RecipeListView in portrait');
      expect(find.byType(RecipeGridView), findsOneWidget,
          reason: 'Should maintain RecipeGridView in portrait');

      await screenMatchesGolden(tester, 'tablet_recipe_split_view_portrait');
    });

    testGoldens('RecipeSplitView - Responsive layout context', (tester) async {
      const responsiveWrapper = ResponsiveLayoutBuilder(
        mobile: Center(child: Text('Mobile: Single View')),
        tablet: RecipeSplitView(),
        desktopWeb: RecipeSplitView(),
      );

      await pumpRecipeSplitViewTest(
        tester,
        screenSize: const Size(768, 1024), 
        customContent: responsiveWrapper,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
        ),
      );

      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'Should use ResponsiveLayoutBuilder wrapper');
      expect(find.byType(RecipeSplitView), findsOneWidget,
          reason: 'Should display RecipeSplitView for tablet');

      expect(find.text('Mobile: Single View'), findsNothing,
          reason: 'Should not show mobile layout on tablet');

      await screenMatchesGolden(tester, 'tablet_recipe_split_view_responsive');
    });

    testGoldens('RecipeSplitView - Recipe selection interaction',
        (tester) async {
      Recipe? selectedRecipe;

      final splitViewWithCallback = RecipeSplitView(
        onRecipeSelected: (recipe) => selectedRecipe = recipe,
      );

      await pumpRecipeSplitViewTest(
        tester,
        screenSize: const Size(1024, 768),
        customContent: splitViewWithCallback,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
        ),
      );

      expect(find.byType(RecipeSplitView), findsOneWidget,
          reason: 'Should display RecipeSplitView with callback');

      expect(find.byType(RecipeListView), findsOneWidget,
          reason: 'Should have list view for selection');
      expect(find.byType(RecipeGridView), findsOneWidget,
          reason: 'Should have grid view for selection');

      await screenMatchesGolden(tester, 'tablet_recipe_split_view_interactive');
    });

    testGoldens('RecipeSplitView - Large tablet boundary', (tester) async {
      await pumpRecipeSplitViewTest(
        tester,
        screenSize: const Size(1366, 1024), 
        recipeState: const RecipeState(
          isLoading: false,
          recipes: _testRecipes,
        ),
      );

      expect(find.byType(RecipeSplitView), findsOneWidget,
          reason: 'Should display RecipeSplitView on large tablet');

      expect(find.byType(RecipeListView), findsOneWidget,
          reason: 'Should maintain split view at large sizes');
      expect(find.byType(RecipeGridView), findsOneWidget,
          reason: 'Should maintain split view at large sizes');

      await screenMatchesGolden(tester, 'tablet_recipe_split_view_large');
    });

    tearDownAll(() async {
     
    });
  });
}
