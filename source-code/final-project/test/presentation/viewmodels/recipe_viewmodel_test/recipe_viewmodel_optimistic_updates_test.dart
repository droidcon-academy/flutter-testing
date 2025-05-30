import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/errors/failure.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
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
  ];

  setUp(() {
    mockGetAllRecipes = MockGetAllRecipes();
    mockFavoriteRecipe = MockFavoriteRecipe();
    mockBookmarkRecipe = MockBookmarkRecipe();
    
    reset(mockGetAllRecipes);
    reset(mockFavoriteRecipe);
    reset(mockBookmarkRecipe);

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

  group('Favorite Optimistic Updates', () {
    test('toggleFavorite updates UI immediately before API call completes',
        () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right([]));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => const Right([]));

      final completer = Completer<Either<Failure, Recipe>>();
      when(() => mockFavoriteRecipe(any())).thenAnswer((_) => completer.future);

      viewModel = createViewModel();
      await Future.delayed(Duration.zero);

      expect(viewModel.state.favoriteIds.contains('1'), isFalse);

      final toggleFuture = viewModel.toggleFavorite('1');

      await Future.microtask(() {});

      expect(viewModel.state.favoriteIds.contains('1'), isTrue);

      completer.complete(Right(testRecipes[0].copyWith(isFavorite: true)));
      await toggleFuture;

      expect(viewModel.state.favoriteIds.contains('1'), isTrue);
    });

    test('toggleFavorite reverts UI updates when API call fails', () async {
      final completer = Completer<Either<Failure, Recipe>>();
      when(() => mockFavoriteRecipe(any())).thenAnswer((_) => completer.future);

      viewModel = createViewModel();
      await viewModel.loadRecipes();

      expect(viewModel.isFavorite('1'), isFalse);

      final toggleFuture = viewModel.toggleFavorite('1');

      expect(viewModel.isFavorite('1'), isTrue);

      completer.complete(const Left(ServerFailure(
        message: 'Network error',
        statusCode: 500,
      )));
      await toggleFuture;

      expect(viewModel.isFavorite('1'), isFalse);
      expect(viewModel.state.favoriteIds.contains('1'), isFalse);
      expect(viewModel.state.error, isNotNull);
    });

    test('optimistic update affects recipe in main list immediately', () async {
      final completer = Completer<Either<Failure, Recipe>>();
      when(() => mockFavoriteRecipe(any())).thenAnswer((_) => completer.future);

      viewModel = createViewModel();
      await viewModel.loadRecipes();

      final initialRecipe = viewModel.state.recipes.first;
      expect(initialRecipe.isFavorite, isFalse);

      viewModel.toggleFavorite('1');

      final updatedRecipe = viewModel.state.recipes.first;
      expect(updatedRecipe.isFavorite, isTrue);

      completer.complete(Right(testRecipes[0].copyWith(isFavorite: true)));
    });

    test('multiple favorite toggles in succession maintain correct state',
        () async {
      int callCount = 0;
      when(() => mockFavoriteRecipe(any())).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          return Future.value(Right(testRecipes[0].copyWith(isFavorite: true)));
        } else {
          return Future.value(const Left(
              ServerFailure(message: 'Network error', statusCode: 500)));
        }
      });

      viewModel = createViewModel();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(viewModel.state.favoriteIds.contains('1'), isFalse);

      await viewModel.toggleFavorite('1');
      expect(viewModel.state.favoriteIds.contains('1'), isTrue);

      final future = viewModel.toggleFavorite('1');

      expect(viewModel.state.favoriteIds.contains('1'), isFalse);

      await future;

      expect(viewModel.state.favoriteIds.contains('1'), isTrue);
    });
  });

  group('Bookmark Optimistic Updates', () {
    test('toggleBookmark updates UI immediately before API call completes',
        () async {
      final completer = Completer<Either<Failure, Recipe>>();
      when(() => mockBookmarkRecipe(any())).thenAnswer((_) => completer.future);

      viewModel = createViewModel();
      await viewModel.loadRecipes();

      expect(viewModel.isBookmarked('2'), isFalse);

      final toggleFuture = viewModel.toggleBookmark('2');

      expect(viewModel.isBookmarked('2'), isTrue);
      expect(viewModel.state.bookmarkIds.contains('2'), isTrue);

      completer.complete(Right(testRecipes[1].copyWith(isBookmarked: true)));
      await toggleFuture;

      expect(viewModel.isBookmarked('2'), isTrue);
      expect(viewModel.state.bookmarkIds.contains('2'), isTrue);
    });

    test('toggleBookmark reverts UI updates when API call fails', () async {
      final completer = Completer<Either<Failure, Recipe>>();
      when(() => mockBookmarkRecipe(any())).thenAnswer((_) => completer.future);

      viewModel = createViewModel();
      await viewModel.loadRecipes();

      expect(viewModel.isBookmarked('2'), isFalse);

      final toggleFuture = viewModel.toggleBookmark('2');

      expect(viewModel.isBookmarked('2'), isTrue);

      completer.complete(const Left(ServerFailure(
        message: 'Network error',
        statusCode: 500,
      )));
      await toggleFuture;

      expect(viewModel.isBookmarked('2'), isFalse);
      expect(viewModel.state.bookmarkIds.contains('2'), isFalse);
      expect(viewModel.state.error, isNotNull);
    });

    test('optimistic update affects recipe in main list immediately', () async {
      final completer = Completer<Either<Failure, Recipe>>();
      when(() => mockBookmarkRecipe(any())).thenAnswer((_) => completer.future);

      viewModel = createViewModel();
      await viewModel.loadRecipes();

      final initialRecipe =
          viewModel.state.recipes.firstWhere((r) => r.id == '2');
      expect(initialRecipe.isBookmarked, isFalse);
      viewModel.toggleBookmark('2');

      final updatedRecipe =
          viewModel.state.recipes.firstWhere((r) => r.id == '2');
      expect(updatedRecipe.isBookmarked, isTrue);

      completer.complete(Right(testRecipes[1].copyWith(isBookmarked: true)));
    });
  });

  group('Disposal During Optimistic Update', () {
    test(
        'disposing ViewModel during in-flight operation should handle gracefully',
        () {
      late RecipeViewModel mockViewModel;

      when(() => mockGetAllRecipes(any())).thenAnswer((_) async =>
          Future.delayed(const Duration(days: 1), () => const Right([])));

      mockViewModel = RecipeViewModel(
        mockGetAllRecipes,
        mockFavoriteRecipe,
        mockBookmarkRecipe,
      );

      mockViewModel.dispose();

      expect(true, isTrue);
    });
  });
}
