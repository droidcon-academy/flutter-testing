// Tests for Recipe ViewModel selection state management
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}

class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

void main() {
  late MockGetAllRecipes mockGetAllRecipes;
  late MockFavoriteRecipe mockFavoriteRecipe;
  late MockBookmarkRecipe mockBookmarkRecipe;
  late RecipeViewModel viewModel;

  setUpAll(() {
    registerFallbackValue(const GetAllRecipesParams(letter: 'A'));
    registerFallbackValue(const FavoriteRecipeParams(recipeId: '1'));
    registerFallbackValue(const BookmarkRecipeParams(recipeId: '1'));
  });

  final testRecipes = [
    const Recipe(
      id: '1',
      name: 'Apple Pie',
      ingredients: [Ingredient(name: 'Apple'), Ingredient(name: 'Sugar')],
    ),
    const Recipe(
      id: '2',
      name: 'Banana Bread',
      ingredients: [Ingredient(name: 'Banana'), Ingredient(name: 'Flour')],
    ),
    const Recipe(
      id: '3',
      name: 'Carrot Cake',
      ingredients: [Ingredient(name: 'Carrot'), Ingredient(name: 'Flour')],
    ),
  ];

  setUp(() {
    mockGetAllRecipes = MockGetAllRecipes();
    mockFavoriteRecipe = MockFavoriteRecipe();
    mockBookmarkRecipe = MockBookmarkRecipe();

    when(() => mockGetAllRecipes(any())).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 10));
      return Right(testRecipes);
    });

    when(() => mockFavoriteRecipe.getFavorites()).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 10));
      return const Right([]);
    });

    when(() => mockBookmarkRecipe.getBookmarks()).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 10));
      return const Right([]);
    });

    when(() => mockFavoriteRecipe(any())).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 10));
      return Right(testRecipes[0].copyWith(isFavorite: true));
    });
  });

  tearDown(() {
    try {
      viewModel.dispose();
    } catch (e) {
    }
  });

  RecipeViewModel createViewModel() {
    return RecipeViewModel(
      mockGetAllRecipes,
      mockFavoriteRecipe,
      mockBookmarkRecipe,
    );
  }

  Future<void> waitForViewModelInit() async {
    await Future.delayed(const Duration(milliseconds: 50));
  }

  group('Recipe Selection Management', () {
    test('selected recipe is initially null', () async {
      viewModel = createViewModel();
      await waitForViewModelInit();

      expect(viewModel.state.selectedRecipe, isNull);
    });

    test('setSelectedRecipe updates selected recipe state', () async {
      viewModel = createViewModel();
      await waitForViewModelInit();

      final recipe = testRecipes[0];
      viewModel.setSelectedRecipe(recipe);

      expect(viewModel.state.selectedRecipe, equals(recipe));
    });

    test('selecting same recipe does not trigger state update', () async {
      viewModel = createViewModel();
      await waitForViewModelInit();

      final recipe = testRecipes[0];
      viewModel.setSelectedRecipe(recipe);

      final initialState = viewModel.state;

      viewModel.setSelectedRecipe(recipe);

      expect(identical(viewModel.state, initialState), isTrue);
    });

    test('setSelectedRecipe can switch between recipes', () async {
      viewModel = createViewModel();
      await waitForViewModelInit();

      final recipe = testRecipes[0];
      viewModel.setSelectedRecipe(recipe);

      expect(viewModel.state.selectedRecipe, equals(recipe));

      final recipe2 = testRecipes[1];
      viewModel.setSelectedRecipe(recipe2);

      expect(viewModel.state.selectedRecipe, equals(recipe2));
    });

    test('setSelectedRecipe behavior with null recipes', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right([]));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => const Right([]));

      viewModel = createViewModel();
      await waitForViewModelInit();

      expect(viewModel.state.selectedRecipe, isNull);

      final initialState = viewModel.state;
      viewModel.setSelectedRecipe(null);

      expect(identical(viewModel.state, initialState), isTrue,
          reason: 'Setting null when already null should not change state');
    });

    test('selection state persists through letter filtering', () async {
      viewModel = createViewModel();
      await waitForViewModelInit();

      final recipe = testRecipes[0];
      viewModel.setSelectedRecipe(recipe);

      viewModel.setSelectedLetter('A');

      expect(viewModel.state.selectedRecipe, equals(recipe));
    });

    test('selection persists when selected recipe is filtered out', () async {
      viewModel = createViewModel();
      await waitForViewModelInit();

      final recipe = testRecipes[0];
      viewModel.setSelectedRecipe(recipe);

      viewModel.setSelectedLetter('B');

      expect(viewModel.state.selectedRecipe, equals(recipe));
    });

    test('selection is updated when recipe properties change', () async {
      viewModel = createViewModel();
      await waitForViewModelInit();

      final recipe = testRecipes[0];
      viewModel.setSelectedRecipe(recipe);

      when(() => mockFavoriteRecipe(any())).thenAnswer(
        (_) async => Right(recipe.copyWith(isFavorite: true)),
      );

      await viewModel.toggleFavorite(recipe.id);

      expect(viewModel.state.selectedRecipe?.id, equals(recipe.id));
      expect(viewModel.state.selectedRecipe?.isFavorite, isTrue);
    });

    test('selection updates in recipes list reflect in selectedRecipe',
        () async {
      viewModel = createViewModel();
      await waitForViewModelInit();

      final recipe = testRecipes[0];
      viewModel.setSelectedRecipe(recipe);

      await viewModel.toggleFavorite(recipe.id);

      expect(viewModel.state.selectedRecipe?.isFavorite, isTrue);

      final updatedRecipeInList =
          viewModel.state.recipes.firstWhere((r) => r.id == recipe.id);
      expect(updatedRecipeInList.isFavorite, isTrue);
    });

    test('selection updates in selectedRecipe reflect in recipes list',
        () async {
      viewModel = createViewModel();
      await waitForViewModelInit();

      final recipe = testRecipes[0];
      viewModel.setSelectedRecipe(recipe);

      await viewModel.toggleFavorite(recipe.id);

      final recipeInList =
          viewModel.state.recipes.firstWhere((r) => r.id == recipe.id);
      expect(recipeInList.isFavorite, isTrue);
    });
  });
}
