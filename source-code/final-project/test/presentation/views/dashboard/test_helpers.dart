import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/presentation/views/dashboard/dashboard_screen.dart';
import 'package:recipevault/presentation/views/dashboard/components/dashboard_tab_layout.dart';

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}

class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

final testRecipes = [
  const Recipe(
    id: '1',
    name: 'Chocolate Cake',
    ingredients: [
      Ingredient(name: 'flour', measure: '2 cups'),
      Ingredient(name: 'sugar', measure: '1 cup'),
      Ingredient(name: 'chocolate', measure: '4 oz'),
    ],
    thumbnailUrl: '',
    instructions: 'Mix and bake',
  ),
  const Recipe(
    id: '2',
    name: 'Apple Pie',
    ingredients: [
      Ingredient(name: 'apples', measure: '6 medium'),
      Ingredient(name: 'flour', measure: '2 cups'),
      Ingredient(name: 'butter', measure: '1 stick'),
    ],
    thumbnailUrl: '',
    instructions: 'Roll and bake',
  ),
  const Recipe(
    id: '3',
    name: 'Banana Bread',
    ingredients: [
      Ingredient(name: 'bananas', measure: '3 ripe'),
      Ingredient(name: 'flour', measure: '2 cups'),
      Ingredient(name: 'butter', measure: '1/2 cup'),
    ],
    thumbnailUrl: '',
    instructions: 'Mash and bake',
  ),
  const Recipe(
    id: '4',
    name: 'Chicken Curry',
    ingredients: [
      Ingredient(name: 'chicken', measure: '1 lb'),
      Ingredient(name: 'curry powder', measure: '2 tbsp'),
      Ingredient(name: 'coconut milk', measure: '1 can'),
    ],
    thumbnailUrl: '',
    instructions: 'Cook and simmer',
  ),
  const Recipe(
    id: '5',
    name: 'Pasta Salad',
    ingredients: [
      Ingredient(name: 'pasta', measure: '1 lb'),
      Ingredient(name: 'vegetables', measure: '2 cups'),
      Ingredient(name: 'dressing', measure: '1/2 cup'),
    ],
    thumbnailUrl: '',
    instructions: 'Mix and chill',
  ),
];

class TestDashboardViewModel extends DashboardViewModel {
  TestDashboardViewModel({
    required FavoriteRecipe favoriteRecipe,
    required BookmarkRecipe bookmarkRecipe,
    required RecipeState recipeState,
    required Ref ref,
  }) : super(favoriteRecipe, bookmarkRecipe, recipeState, ref);

  @override
  set state(DashboardState newState) {
    super.state = newState;
  }

  @override
  Future<void> initializeDataProgressively() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await loadFavorites();
      await loadBookmarks();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

class TestRecipeViewModel extends RecipeViewModel {
  final RecipeState _fixedState;

  TestRecipeViewModel(this._fixedState)
      : super(
          MockGetAllRecipes(),
          MockFavoriteRecipe(),
          MockBookmarkRecipe(),
        );

  @override
  RecipeState get state => _fixedState;

  @override
  Future<void> loadRecipes() async {
  }

  @override
  Future<void> loadFavorites() async {
  }

  @override
  Future<void> loadBookmarks() async {
  }
}

void setupCommonMockResponses({
  required MockFavoriteRecipe mockFavoriteRecipe,
  required MockBookmarkRecipe mockBookmarkRecipe,
}) {
  when(() => mockFavoriteRecipe.getFavorites())
      .thenAnswer((_) async => Right(testRecipes));
  when(() => mockBookmarkRecipe.getBookmarks())
      .thenAnswer((_) async => Right(testRecipes.take(1).toList()));
}

Future<void> initializeDashboardTestEnvironment() async {
  SharedPreferences.setMockInitialValues({});
}

Widget createDashboardScreenTestHarness({
  required MockFavoriteRecipe mockFavoriteRecipe,
  required MockBookmarkRecipe mockBookmarkRecipe,
  List<Override> additionalOverrides = const [],
  RecipeState? mockRecipeState,
  DashboardState? mockDashboardState,
  bool forceMobileLayout = true,
}) {
  final recipeState = mockRecipeState ??
      RecipeState(
        recipes: testRecipes,
        favoriteIds: {'1'},
        bookmarkIds: {'1'},
        isLoading: false,
      );

  Widget child = const DashboardScreen();

  if (forceMobileLayout) {
    child = MediaQuery(
      data: const MediaQueryData(
        size: Size(400, 800), 
        devicePixelRatio: 1.0,
      ),
      child: child,
    );
  }

  return ProviderScope(
    overrides: [
      recipeProvider.overrideWith((ref) {
        return TestRecipeViewModel(recipeState);
      }),
      dashboardProvider.overrideWith((ref) {
        return TestDashboardViewModel(
          favoriteRecipe: mockFavoriteRecipe,
          bookmarkRecipe: mockBookmarkRecipe,
          recipeState: recipeState,
          ref: ref,
        );
      }),
      ...additionalOverrides,
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

Widget createTabLayoutTestWidget({
  required MockFavoriteRecipe mockFavoriteRecipe,
  required MockBookmarkRecipe mockBookmarkRecipe,
  RecipeState? customRecipeState,
  List<Override> additionalOverrides = const [],
}) {
  final recipeState = customRecipeState ??
      RecipeState(
        recipes: testRecipes,
        favoriteIds: {'1'},
        bookmarkIds: {'1'},
        isLoading: false,
      );

  return ProviderScope(
    overrides: [
      recipeProvider.overrideWith((ref) {
        return TestRecipeViewModel(recipeState);
      }),
      dashboardProvider.overrideWith((ref) {
        return TestDashboardViewModel(
          favoriteRecipe: mockFavoriteRecipe,
          bookmarkRecipe: mockBookmarkRecipe,
          recipeState: recipeState,
          ref: ref,
        );
      }),
      ...additionalOverrides,
    ],
    child: const MaterialApp(
      home: DashboardTabLayout(),
    ),
  );
}

Widget createResponsiveTestWidget({
  required MockFavoriteRecipe mockFavoriteRecipe,
  required MockBookmarkRecipe mockBookmarkRecipe,
  Size screenSize = const Size(800, 600),
  RecipeState? customRecipeState,
}) {
  final recipeState = customRecipeState ??
      RecipeState(
        recipes: testRecipes,
        favoriteIds: {'1'},
        bookmarkIds: {'2'},
        isLoading: false,
      );

  return ProviderScope(
    overrides: [
      recipeProvider.overrideWith((ref) {
        return TestRecipeViewModel(recipeState);
      }),
      dashboardProvider.overrideWith((ref) {
        return TestDashboardViewModel(
          favoriteRecipe: mockFavoriteRecipe,
          bookmarkRecipe: mockBookmarkRecipe,
          recipeState: recipeState,
          ref: ref,
        );
      }),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        devicePixelRatio: 1.0,
      ),
      child: const MaterialApp(
        home: DashboardScreen(),
      ),
    ),
  );
}
