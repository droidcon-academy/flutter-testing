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
import 'package:recipevault/presentation/views/recipe/components/recipe_detail_panel.dart';
import 'package:recipevault/presentation/widgets/recipe/detail/recipe_detail_view.dart';
import 'package:recipevault/presentation/widgets/common/layout/responsive_layout_builder.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';

const _testRecipeWithImage = Recipe(
  id: '1',
  name: 'Spaghetti Carbonara',
  ingredients: [
    Ingredient(name: 'spaghetti pasta', measure: '400g'),
    Ingredient(name: 'large eggs', measure: '3'),
    Ingredient(name: 'parmesan cheese', measure: '100g'),
    Ingredient(name: 'pancetta', measure: '150g'),
    Ingredient(name: 'black pepper', measure: '1 tsp'),
  ],
  instructions:
      'Cook pasta al dente. Mix eggs and cheese. Crisp pancetta. Combine off heat with pasta water.',
  isFavorite: true,
  isBookmarked: false,
);

const _testRecipeMinimal = Recipe(
  id: '2',
  name: 'Simple Avocado Toast',
  ingredients: [
    Ingredient(name: 'bread slices', measure: '2'),
    Ingredient(name: 'ripe avocado', measure: '1'),
    Ingredient(name: 'salt', measure: 'to taste'),
  ],
  instructions: 'Toast bread. Mash avocado. Spread and season.',
  isFavorite: false,
  isBookmarked: true,
);

const _testRecipeNoImage = Recipe(
  id: '3',
  name: 'Classic Caesar Salad',
  ingredients: [
    Ingredient(name: 'romaine lettuce', measure: '2 heads'),
    Ingredient(name: 'parmesan cheese', measure: '50g'),
    Ingredient(name: 'croutons', measure: '1 cup'),
    Ingredient(name: 'caesar dressing', measure: '1/4 cup'),
  ],
  instructions:
      'Chop lettuce. Add croutons and cheese. Toss with dressing. Serve immediately.',
  isFavorite: false,
  isBookmarked: false,
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

  @override
  void setSelectedRecipe(Recipe? recipe) {
    
  }
}

void main() {
  group('Tablet Recipe Detail Golden Tests - Real Component Tests', () {
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
          .thenAnswer((_) async => const Right([_testRecipeWithImage]));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right([]));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => const Right([]));
    });

    Future<Widget> createRecipeDetailTestHarness({
      Recipe? recipe,
      RecipeState? recipeState,
      ThemeData? theme,
      Widget? customContent,
    }) async {
      final prefs = await SharedPreferences.getInstance();

      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),
          favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
          bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),
          if (recipeState != null)
            recipeProvider.overrideWith((ref) => TestRecipeViewModel(
                recipeState,
                mockGetAllRecipes,
                mockFavoriteRecipe,
                mockBookmarkRecipe)),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.lightTheme,
          home: customContent ??
              (recipe != null
                  ? RecipeDetailPanel(recipe: recipe)
                  : const RecipeDetailView(recipe: _testRecipeWithImage)),
        ),
      );
    }

    Future<void> pumpRecipeDetailTest(
      WidgetTester tester, {
      required Size screenSize,
      Recipe? recipe,
      RecipeState? recipeState,
      ThemeData? theme,
      Widget? customContent,
    }) async {
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;

      final widget = await createRecipeDetailTestHarness(
        recipe: recipe,
        recipeState: recipeState,
        theme: theme,
        customContent: customContent,
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testGoldens('RecipeDetailPanel - Full recipe with favorite state',
        (tester) async {
      await pumpRecipeDetailTest(
        tester,
        screenSize: const Size(1024, 768), 
        recipe: _testRecipeWithImage,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [_testRecipeWithImage],
          selectedRecipe: _testRecipeWithImage,
        ),
      );

      expect(find.byType(RecipeDetailPanel), findsOneWidget,
          reason: 'Should display RecipeDetailPanel');
      expect(find.text(_testRecipeWithImage.name), findsOneWidget,
          reason: 'Should show recipe name in app bar');
      expect(find.byIcon(Icons.favorite), findsOneWidget,
          reason: 'Should show filled favorite icon for favorited recipe');

      expect(find.text('Ingredients'), findsOneWidget,
          reason: 'Should display Ingredients section');
      expect(find.text('Instructions'), findsOneWidget,
          reason: 'Should display Instructions section');

      expect(find.textContaining(_testRecipeWithImage.instructions!),
          findsOneWidget,
          reason: 'Should display recipe instructions');

      await screenMatchesGolden(tester, 'tablet_recipe_detail_full_favorited');
    });

    testGoldens('RecipeDetailPanel - Bookmarked recipe state', (tester) async {
      await pumpRecipeDetailTest(
        tester,
        screenSize: const Size(768, 1024), 
        recipe: _testRecipeMinimal,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [_testRecipeMinimal],
          selectedRecipe: _testRecipeMinimal,
        ),
      );

      expect(find.byType(RecipeDetailPanel), findsOneWidget,
          reason: 'Should display RecipeDetailPanel');
      expect(find.text(_testRecipeMinimal.name), findsOneWidget,
          reason: 'Should show recipe name');
      expect(find.byIcon(Icons.bookmark), findsOneWidget,
          reason: 'Should show filled bookmark icon for bookmarked recipe');
      expect(find.byIcon(Icons.favorite_outline), findsOneWidget,
          reason: 'Should show outline favorite icon for non-favorited recipe');

      await screenMatchesGolden(tester, 'tablet_recipe_detail_bookmarked');
    });

    testGoldens('RecipeDetailView - Simple recipe display', (tester) async {
      await pumpRecipeDetailTest(
        tester,
        screenSize: const Size(1024, 768), 
        customContent: const RecipeDetailView(recipe: _testRecipeNoImage),
      );

      expect(find.byType(RecipeDetailView), findsOneWidget,
          reason: 'Should display RecipeDetailView');
      expect(find.text(_testRecipeNoImage.name), findsOneWidget,
          reason: 'Should show recipe name in app bar');

      expect(find.byIcon(Icons.broken_image), findsNothing,
          reason: 'Should not show broken image icon when no thumbnailUrl');

      await screenMatchesGolden(tester, 'tablet_recipe_detail_simple_view');
    });

    testGoldens('RecipeDetailPanel - Dark theme with image error',
        (tester) async {
      await pumpRecipeDetailTest(
        tester,
        screenSize: const Size(768, 1024), 
        recipe: _testRecipeWithImage,
        theme: AppTheme.darkTheme,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [_testRecipeWithImage],
          selectedRecipe: _testRecipeWithImage,
        ),
      );

      expect(find.byType(RecipeDetailPanel), findsOneWidget,
          reason: 'Should display RecipeDetailPanel in dark theme');

      expect(find.byType(ResponsiveLayoutBuilder), findsNothing,
          reason:
              'RecipeDetailPanel itself does not contain ResponsiveLayoutBuilder');

      await screenMatchesGolden(tester, 'tablet_recipe_detail_dark_theme');
    });

    testGoldens('RecipeDetailPanel - Responsive layout context',
        (tester) async {
      const responsiveWrapper = ResponsiveLayoutBuilder(
        mobile: RecipeDetailPanel(recipe: _testRecipeMinimal),
        tablet: RecipeDetailPanel(recipe: _testRecipeWithImage),
        desktopWeb: RecipeDetailPanel(recipe: _testRecipeNoImage),
      );

      await pumpRecipeDetailTest(
        tester,
        screenSize: const Size(768, 1024), 
        customContent: responsiveWrapper,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [_testRecipeWithImage],
          selectedRecipe: _testRecipeWithImage,
        ),
      );

      expect(find.byType(ResponsiveLayoutBuilder), findsOneWidget,
          reason: 'Should use ResponsiveLayoutBuilder wrapper');
      expect(find.byType(RecipeDetailPanel), findsOneWidget,
          reason: 'Should display appropriate RecipeDetailPanel for tablet');

      expect(find.text(_testRecipeWithImage.name), findsOneWidget,
          reason: 'Should show tablet-specific recipe');

      await screenMatchesGolden(tester, 'tablet_recipe_detail_responsive');
    });

    testGoldens('RecipeDetailPanel - Large tablet layout', (tester) async {
      await pumpRecipeDetailTest(
        tester,
        screenSize: const Size(1366, 1024), 
        recipe: _testRecipeWithImage,
        recipeState: const RecipeState(
          isLoading: false,
          recipes: [_testRecipeWithImage],
          selectedRecipe: _testRecipeWithImage,
        ),
      );

      expect(find.byType(RecipeDetailPanel), findsOneWidget,
          reason: 'Should display RecipeDetailPanel on large tablet');


      await screenMatchesGolden(tester, 'tablet_recipe_detail_large_layout');
    });

    testGoldens('RecipeDetailPanel - Empty state handling', (tester) async {
      await pumpRecipeDetailTest(
        tester,
        screenSize: const Size(768, 1024), 
        recipe: null, 
        customContent: const RecipeDetailPanel(recipe: null),
      );

      expect(find.byType(RecipeDetailPanel), findsOneWidget,
          reason: 'Should display RecipeDetailPanel even with null recipe');
      expect(find.text('Select a recipe to view details'), findsOneWidget,
          reason: 'Should show placeholder message for null recipe');

      await screenMatchesGolden(tester, 'tablet_recipe_detail_empty_state');
    });

    testGoldens('RecipeDetailView - Navigation integration', (tester) async {
      await pumpRecipeDetailTest(
        tester,
        screenSize: const Size(1024, 768),
        customContent: const RecipeDetailView(recipe: _testRecipeNoImage),
      );

      expect(find.byType(RecipeDetailView), findsOneWidget,
          reason: 'Should display RecipeDetailView');
      expect(find.byIcon(Icons.arrow_back), findsOneWidget,
          reason: 'Should show back button for navigation');

      expect(find.text('Ingredients'), findsOneWidget,
          reason: 'Should show ingredients section title');
      expect(find.text('Instructions'), findsOneWidget,
          reason: 'Should show instructions section title');

      await screenMatchesGolden(tester, 'tablet_recipe_detail_navigation');
    });

    tearDownAll(() async {
      
    });
  });
}
