import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/errors/failure.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';

class MockGetAllRecipes extends Mock implements GetAllRecipes {}
class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}
class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

void main() {
  setUpAll(() {
    registerFallbackValue(const GetAllRecipesParams(letter: ''));
    registerFallbackValue(const FavoriteRecipeParams(recipeId: 'test-id'));
    registerFallbackValue(const BookmarkRecipeParams(recipeId: 'test-id'));
  });
  
  late MockGetAllRecipes mockGetAllRecipes;
  late MockFavoriteRecipe mockFavoriteRecipe;
  late MockBookmarkRecipe mockBookmarkRecipe;
  late RecipeViewModel viewModel;
  
  Future<RecipeViewModel> createAndInitViewModel() async {
    final vm = RecipeViewModel(
      mockGetAllRecipes,
      mockFavoriteRecipe,
      mockBookmarkRecipe,
    );
    
    await Future.delayed(const Duration(milliseconds: 50));
    
    return vm;
  }
  
  Future<void> waitForViewModelInit() async {
    await Future.delayed(const Duration(milliseconds: 50));
  }
  
  Future<void> disposeViewModel(RecipeViewModel vm) async {
    try {
      vm.dispose();
      await Future.delayed(const Duration(milliseconds: 10));
    } catch (e) {
    }
  }
  
  tearDown(() async {
    try {
      await disposeViewModel(viewModel);
    } catch (e) {
    }
    
    clearInteractions(mockGetAllRecipes);
    clearInteractions(mockFavoriteRecipe);
    clearInteractions(mockBookmarkRecipe);
  });


  final testRecipes = [
    Recipe(
      id: '1',
      name: 'Apple Pie',
      ingredients: [Ingredient(name: 'Apple'), Ingredient(name: 'Sugar')],
    ),
    Recipe(
      id: '2',
      name: 'Banana Bread',
      ingredients: [Ingredient(name: 'Banana'), Ingredient(name: 'Flour')],
    ),
    Recipe(
      id: '3',
      name: 'Carrot Cake',
      ingredients: [Ingredient(name: 'Carrot'), Ingredient(name: 'Flour')],
    ),
  ];

  final favoriteRecipes = [
    Recipe(
      id: '1',
      name: 'Apple Pie',
      ingredients: [Ingredient(name: 'Apple'), Ingredient(name: 'Sugar')],
      isFavorite: true,
    ),
  ];

  final bookmarkedRecipes = [
    Recipe(
      id: '2',
      name: 'Banana Bread',
      ingredients: [Ingredient(name: 'Banana'), Ingredient(name: 'Flour')],
      isBookmarked: true,
    ),
  ];

  setUp(() {
    mockGetAllRecipes = MockGetAllRecipes();
    mockFavoriteRecipe = MockFavoriteRecipe();
    mockBookmarkRecipe = MockBookmarkRecipe();
    
    reset(mockGetAllRecipes);
    reset(mockFavoriteRecipe);
    reset(mockBookmarkRecipe);

    when(() => mockGetAllRecipes(any()))
        .thenAnswer((_) async => Right(testRecipes));
    when(() => mockFavoriteRecipe.getFavorites())
        .thenAnswer((_) async => Right(favoriteRecipes));
    when(() => mockBookmarkRecipe.getBookmarks())
        .thenAnswer((_) async => Right(bookmarkedRecipes));
    when(() => mockFavoriteRecipe(any()))
        .thenAnswer((_) async => Right(testRecipes[0]));
    when(() => mockBookmarkRecipe(any()))
        .thenAnswer((_) async => Right(testRecipes[1]));
        
    when(() => mockGetAllRecipes(any())).thenAnswer(
      (_) async => Right(testRecipes),
    );
    
    when(() => mockFavoriteRecipe.getFavorites()).thenAnswer(
      (_) async => Right(favoriteRecipes),
    );
    
    when(() => mockBookmarkRecipe.getBookmarks()).thenAnswer(
      (_) async => Right(bookmarkedRecipes),
    );
    
    when(() => mockFavoriteRecipe(any())).thenAnswer(
      (_) async => Right(testRecipes[0]),
    );
    
    when(() => mockBookmarkRecipe(any())).thenAnswer(
      (_) async => Right(testRecipes[1]),
    );
  });
  
  tearDown(() {
    try {
      viewModel.dispose();
    } catch (e) {
    }
  });

  RecipeViewModel createViewModel() {
    try {
      disposeViewModel(viewModel);
    } catch (e) {
    }
    
    final vm = RecipeViewModel(
      mockGetAllRecipes,
      mockFavoriteRecipe,
      mockBookmarkRecipe,
    );
    
    return vm;
  }
  
  group('Initialization and Loading States', () {
    test('auto-initializes and transitions to loaded state', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
          
      viewModel = createViewModel();
      expect(viewModel.state.isLoading, isTrue);
      await Future.delayed(Duration.zero);
      
      expect(viewModel.state.recipes, equals(testRecipes));
      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.error, isNull);
      expect(viewModel.state.selectedLetter, isNull);
    });
    
    test('has correct empty initial state before data load completes', () async {
      viewModel = createViewModel();
      
      expect(viewModel.state.recipes, isEmpty);
      expect(viewModel.state.isLoading, true, reason: 'ViewModel should be in loading state during initialization');
      expect(viewModel.state.error, isNull);
      expect(viewModel.state.selectedLetter, isNull);
      expect(viewModel.state.selectedRecipe, isNull);
      expect(viewModel.state.favoriteIds, isEmpty);
      expect(viewModel.state.bookmarkIds, isEmpty);
      
      await waitForViewModelInit();
    });

    test('loadRecipes sets loading state to true then false on success', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      
      final completer = Completer<Either<Failure, List<Recipe>>>();
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) => completer.future);
          
      viewModel = createViewModel();
      
      expect(viewModel.state.isLoading, isTrue);
      
      completer.complete(Right(testRecipes));
      await Future.delayed(Duration.zero);
      
      expect(viewModel.state.isLoading, isFalse);
      
      final nextCompleter = Completer<Either<Failure, List<Recipe>>>();
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) => nextCompleter.future);
          
      final loadingFuture = viewModel.loadRecipes();
      
      expect(viewModel.state.isLoading, isTrue);
      
      nextCompleter.complete(Right(testRecipes));
      await loadingFuture;
      
      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.recipes, equals(testRecipes));
      expect(viewModel.state.error, isNull);
    });

    test('loadRecipes sets loading state to true then false on error', () async {
      final completer = Completer<Either<Failure, List<Recipe>>>();
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) => completer.future);
          
      viewModel = createViewModel();
      
      expect(viewModel.state.isLoading, isTrue);
      
      completer.complete(Right(testRecipes));
      await Future.delayed(Duration.zero);
      
      expect(viewModel.state.isLoading, isFalse);
      
      final errorCompleter = Completer<Either<Failure, List<Recipe>>>();
      when(() => mockGetAllRecipes(any())).thenAnswer(
        (_) => errorCompleter.future,
      );
      
      final loadingFuture = viewModel.loadRecipes();
      
      expect(viewModel.state.isLoading, isTrue);
      
      errorCompleter.complete(Left(ServerFailure(message: 'Server error', statusCode: 500)));
      await loadingFuture;
      
      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.error, equals('Server error'));
    });  

    test('initializeData loads recipes, favorites, and bookmarks', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      
      viewModel = createViewModel();
      await Future.delayed(Duration.zero);
      
      clearInteractions(mockGetAllRecipes);
      clearInteractions(mockFavoriteRecipe);
      clearInteractions(mockBookmarkRecipe);
      
      await viewModel.initializeData();
      
      verify(() => mockGetAllRecipes(any())).called(1);
      verify(() => mockFavoriteRecipe.getFavorites()).called(1);
      verify(() => mockBookmarkRecipe.getBookmarks()).called(1);
      
      expect(viewModel.state.recipes, equals(testRecipes));
      expect(viewModel.state.favoriteIds, equals({'1'}));
      expect(viewModel.state.bookmarkIds, equals({'2'}));
    });
  });

  group('Letter Filtering', () {
    setUp(() {
      mockGetAllRecipes = MockGetAllRecipes();
      mockFavoriteRecipe = MockFavoriteRecipe();
      mockBookmarkRecipe = MockBookmarkRecipe();
    });
    
    test('filtering by letter shows only recipes starting with that letter', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(favoriteRecipes));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(bookmarkedRecipes));
          
      when(() => mockGetAllRecipes(any(that: predicate<GetAllRecipesParams>(
              (params) => params.letter == 'A'))))
          .thenAnswer((_) async => Right([testRecipes[0]])); 

      viewModel = createViewModel();
      await waitForViewModelInit();

      expect(viewModel.state.filteredRecipes.length, 3, reason: 'Should start with all recipes');
      
      viewModel.setSelectedLetter('A');
      
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(viewModel.state.filteredRecipes.length, 1, reason: 'Should have 1 recipe starting with A');
      expect(viewModel.state.filteredRecipes[0].name, 'Apple Pie', reason: 'The only recipe should be Apple Pie');
    });
    
    test('filtering is case-insensitive', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(favoriteRecipes));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(bookmarkedRecipes));
          
      when(() => mockGetAllRecipes(any(that: predicate<GetAllRecipesParams>(
              (params) => params.letter == 'A'))))
          .thenAnswer((_) async => Right([testRecipes[0]])); 

      viewModel = createViewModel();
      await waitForViewModelInit();

      viewModel.setSelectedLetter('a'); 
      
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(viewModel.state.filteredRecipes.length, 1, reason: 'Should have 1 recipe with case-insensitive filter');
      expect(viewModel.state.filteredRecipes[0].name, 'Apple Pie', reason: 'The only recipe should be Apple Pie');
    });
    
    test('null filter shows all recipes', () async {
      reset(mockGetAllRecipes);
      reset(mockFavoriteRecipe);
      reset(mockBookmarkRecipe);
      
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(<Recipe>[])); 
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(<Recipe>[])); 
      
      final viewModel = RecipeViewModel(
        mockGetAllRecipes,
        mockFavoriteRecipe,
        mockBookmarkRecipe,
      );
      
      await viewModel.initializeData();
      
      expect(viewModel.state.selectedLetter, isNull);
      expect(viewModel.state.recipes, equals(testRecipes));
      expect(viewModel.state.filteredRecipes, equals(testRecipes));
      expect(viewModel.state.filteredRecipes.length, equals(3));
      
      await disposeViewModel(viewModel);
    });
    

    test('changing letter filter triggers API call with filter', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(favoriteRecipes));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(bookmarkedRecipes));
          
      when(() => mockGetAllRecipes(any(that: predicate<GetAllRecipesParams>(
              (params) => params.letter == 'A'))))
          .thenAnswer((_) async => Right([testRecipes[0]])); 
          
      when(() => mockGetAllRecipes(any(that: predicate<GetAllRecipesParams>(
              (params) => params.letter == 'B'))))
          .thenAnswer((_) async => Right([testRecipes[1]]));
      
      viewModel = createViewModel();
      await waitForViewModelInit();
      
      clearInteractions(mockGetAllRecipes);
      
      viewModel.setSelectedLetter('B');
      
      await Future.delayed(const Duration(milliseconds: 50));
      
      verify(() => mockGetAllRecipes(any(that: predicate<GetAllRecipesParams>(
              (params) => params.letter == 'B'))))
        .called(1);
        
      await disposeViewModel(viewModel);
    });

    test('setting same letter filter does not trigger new API call', () async {
     
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(favoriteRecipes));
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(bookmarkedRecipes));
          
      when(() => mockGetAllRecipes(any(that: predicate<GetAllRecipesParams>(
              (params) => params.letter == 'B'))))
          .thenAnswer((_) async => Right([testRecipes[1]])); 
      
      viewModel = createViewModel();
      await waitForViewModelInit();
      
      viewModel.setSelectedLetter('B');
      await Future.delayed(const Duration(milliseconds: 50));
      
      clearInteractions(mockGetAllRecipes);
      
      viewModel.setSelectedLetter('B');
      await Future.delayed(const Duration(milliseconds: 50));
      
      verifyNever(() => mockGetAllRecipes(any()));
      
      await disposeViewModel(viewModel);
    });
  });

  group('Error Handling', () {
    test('loadRecipes captures error state on failure', () async {
      reset(mockGetAllRecipes);
      
      when(() => mockGetAllRecipes(any())).thenAnswer(
        (_) async => Left(ServerFailure(message: "Failed to load recipes", statusCode: 500)),
      );
      viewModel = createViewModel();
      await waitForViewModelInit();
      await viewModel.loadRecipes();
      
      expect(viewModel.state.error, equals('Failed to load recipes'));
      expect(viewModel.state.isLoading, false);
    });

    test('loadFavorites captures error state on failure', () async {
      reset(mockGetAllRecipes);
      reset(mockFavoriteRecipe);
      
      when(() => mockGetAllRecipes(any())).thenAnswer(
        (_) async => Right(testRecipes),
      );
      
      when(() => mockFavoriteRecipe.getFavorites()).thenAnswer(
        (_) async => Left(ServerFailure(message: 'Failed to load favorites', statusCode: 500)),
      );
      
      viewModel = createViewModel();
      await waitForViewModelInit();
      await viewModel.loadFavorites();
      
      expect(viewModel.state.error, equals('Failed to load favorites'));
    });

    test('loadBookmarks captures error state on failure', () async {
      reset(mockGetAllRecipes);
      reset(mockBookmarkRecipe);
      
      when(() => mockGetAllRecipes(any())).thenAnswer(
        (_) async => Right(testRecipes),
      );
      
      when(() => mockBookmarkRecipe.getBookmarks()).thenAnswer(
        (_) async => Left(ServerFailure(message: 'Failed to load bookmarks', statusCode: 500)),
      );
      
      viewModel = createViewModel();
      
      await waitForViewModelInit();

      reset(mockBookmarkRecipe);
      when(() => mockBookmarkRecipe.getBookmarks()).thenAnswer(
        (_) async => Left(ServerFailure(message: 'Failed to load bookmarks', statusCode: 500)),
      );
      
      await viewModel.loadBookmarks();
      
      expect(viewModel.state.error, equals('Failed to load bookmarks'));
      expect(viewModel.state.isLoading, false);
    });

    test('error is cleared on successful operations', () async {
      when(() => mockGetAllRecipes(any())).thenAnswer(
        (_) async => Left(ServerFailure(message: "Failed to load recipes", statusCode: 500)),
      );
      
      viewModel = createViewModel();
      await viewModel.loadRecipes();
      
      expect(viewModel.state.error, equals('Failed to load recipes'));
      when(() => mockGetAllRecipes(any())).thenAnswer(
        (_) async => Right(testRecipes),
      );
      
      await viewModel.loadRecipes();
      expect(viewModel.state.error, isNull);
    });
  });

  group('State Transitions', () {
    test('state transitions properly from loading to loaded', () async {
      reset(mockGetAllRecipes);
      reset(mockFavoriteRecipe);
      reset(mockBookmarkRecipe);
      
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(favoriteRecipes)); 
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(bookmarkedRecipes));
      
      final testViewModel = RecipeViewModel(
        mockGetAllRecipes,
        mockFavoriteRecipe,
        mockBookmarkRecipe,
      );
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(testViewModel.state.isLoading, false, 
          reason: 'ViewModel should not be loading after initialization');
      
      clearInteractions(mockGetAllRecipes);
      
      final completer = Completer<Either<Failure, List<Recipe>>>();
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) => completer.future);
      
      final loadFuture = testViewModel.loadRecipes();
      
      expect(testViewModel.state.isLoading, true, 
          reason: 'ViewModel should be in loading state during loadRecipes');
      
      completer.complete(Right(testRecipes));
      await loadFuture;

      expect(testViewModel.state.isLoading, false, 
          reason: 'ViewModel should not be loading after loadRecipes completes');
      expect(testViewModel.state.recipes, equals(testRecipes));
      
      testViewModel.dispose();
    });

    test('state transitions properly from loading to error', () async {
      reset(mockGetAllRecipes);
      reset(mockFavoriteRecipe);
      reset(mockBookmarkRecipe);
      
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(favoriteRecipes)); 
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(bookmarkedRecipes));
      
      final testViewModel = RecipeViewModel(
        mockGetAllRecipes,
        mockFavoriteRecipe,
        mockBookmarkRecipe,
      );
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(testViewModel.state.isLoading, false, 
          reason: 'ViewModel should not be loading after initialization');
      expect(testViewModel.state.error, isNull, 
          reason: 'No error should be present initially');
      
      clearInteractions(mockGetAllRecipes);
      
      final errorCompleter = Completer<Either<Failure, List<Recipe>>>();
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) => errorCompleter.future);
      
      final loadFuture = testViewModel.loadRecipes();
      
      expect(testViewModel.state.isLoading, true, 
          reason: 'ViewModel should be in loading state during API call');
      expect(testViewModel.state.error, isNull, 
          reason: 'Error should be null during loading');
      
      errorCompleter.complete(Left(ServerFailure(message: 'Error loading', statusCode: 500)));
      
      await loadFuture;
      
      expect(testViewModel.state.isLoading, false, 
          reason: 'Loading should be false after error');
      expect(testViewModel.state.error, equals('Error loading'), 
          reason: 'Error message should be captured in state');
      
      testViewModel.dispose();
    });

    test('state transitions maintain unrelated properties', () async {
   
      reset(mockGetAllRecipes);
      when(() => mockGetAllRecipes(any())).thenAnswer(
        (_) async => Right(testRecipes),
      );
      
      viewModel = createViewModel();
      
      await waitForViewModelInit();
      final selectedRecipe = testRecipes[0];
      viewModel.setSelectedRecipe(selectedRecipe);
      
      expect(viewModel.state.selectedRecipe, equals(selectedRecipe));
      
      clearInteractions(mockGetAllRecipes);
      
      await viewModel.loadRecipes();
      
      expect(viewModel.state.selectedRecipe, equals(selectedRecipe));
    });
  });

  group('Favorites Management', () {
    setUp(() {
      final favoriteRecipe = testRecipes[0].copyWith(isFavorite: true);
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right([favoriteRecipe])); 
      
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
    });
    
    test('toggleFavorite calls use case with correct recipe ID', () async {
      
      reset(mockFavoriteRecipe);
      
      when(() => mockFavoriteRecipe(any()))
          .thenAnswer((_) async => Right(testRecipes[0].copyWith(isFavorite: true)));
      
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(<Recipe>[]));
      
      viewModel = createViewModel();
      await waitForViewModelInit();
      
      await viewModel.toggleFavorite('1');
      
      final capturedParams = verify(() => mockFavoriteRecipe(captureAny())).captured;
      expect(capturedParams.length, 1, reason: 'FavoriteRecipe should be called exactly once');
      expect(capturedParams.first, isA<FavoriteRecipeParams>(), reason: 'Parameter should be a FavoriteRecipeParams');
      expect((capturedParams.first as FavoriteRecipeParams).recipeId, equals('1'), reason: 'RecipeId should be 1');
    });

    test('isFavorite returns correct status for a recipe', () async {
      viewModel = createViewModel();
      await waitForViewModelInit();
      
      await viewModel.loadFavorites();
      
      expect(viewModel.isFavorite('1'), isTrue);
      
      expect(viewModel.isFavorite('2'), isFalse);
    });

    test('favoriteRecipes getter returns only favorite recipes', () async {
      viewModel = createViewModel();
      await waitForViewModelInit();
      
      expect(viewModel.state.favoriteRecipes.length, 1, reason: 'Should only have one favorited recipe');
      expect(viewModel.state.favoriteRecipes.first.id, '1', reason: 'Recipe with ID 1 should be the favorite');
    });
  });

  group('Bookmarks Management', () {
    test('toggleBookmark calls use case with correct recipe ID', () async {
      viewModel = createViewModel();
      await viewModel.loadRecipes();
      
      await viewModel.toggleBookmark('2');
      
      final capturedParams = verify(() => mockBookmarkRecipe(captureAny())).captured;
      expect(capturedParams.length, 1, reason: 'BookmarkRecipe should be called exactly once');
      expect(capturedParams.first, isA<BookmarkRecipeParams>(), reason: 'Parameter should be a BookmarkRecipeParams');
      expect((capturedParams.first as BookmarkRecipeParams).recipeId, equals('2'), reason: 'RecipeId should be 2');
    });

    test('isBookmarked returns correct status for a recipe', () async {
      viewModel = createViewModel();
      await viewModel.initializeData();
      
      expect(viewModel.isBookmarked('2'), isTrue);
      expect(viewModel.isBookmarked('1'), isFalse);
    });

    test('bookmarkedRecipes getter returns only bookmarked recipes', () async {
      viewModel = createViewModel();
      await viewModel.initializeData();
      
      expect(viewModel.state.bookmarkedRecipes.length, 1);
      expect(viewModel.state.bookmarkedRecipes.first.id, '2');
    });
  });
  
  group('Optimistic Updates', () {
    setUp(() {
      mockGetAllRecipes = MockGetAllRecipes();
      mockFavoriteRecipe = MockFavoriteRecipe();
      mockBookmarkRecipe = MockBookmarkRecipe();
      
      reset(mockGetAllRecipes);
      reset(mockFavoriteRecipe);
      reset(mockBookmarkRecipe);
    });
    
    test('toggleFavorite immediately updates state before API call completes', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(<Recipe>[])); 
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(<Recipe>[])); 
      
      final completer = Completer<Either<Failure, Recipe>>();
      when(() => mockFavoriteRecipe(any()))
          .thenAnswer((_) => completer.future);
      
      viewModel = createViewModel();
      await waitForViewModelInit();
      
      expect(viewModel.isFavorite('3'), isFalse, reason: 'Recipe 3 should not be favorite initially');
      
      final toggleFuture = viewModel.toggleFavorite('3');
      
      expect(viewModel.isFavorite('3'), isTrue, reason: 'State should update optimistically');
      
      completer.complete(Right(testRecipes[2].copyWith(isFavorite: true)));
      await toggleFuture;
      
      expect(viewModel.isFavorite('3'), isTrue, reason: 'State should maintain the update after API success');
      
      await disposeViewModel(viewModel);
    });
    
    test('toggleFavorite reverts state update if API call fails', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(<Recipe>[])); 
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(<Recipe>[]));
      
      final completer = Completer<Either<Failure, Recipe>>();
      when(() => mockFavoriteRecipe(any()))
          .thenAnswer((_) => completer.future);
      
      viewModel = createViewModel();
      await waitForViewModelInit();
      
      expect(viewModel.isFavorite('3'), isFalse, reason: 'Recipe 3 should not be favorite initially');
      
      final toggleFuture = viewModel.toggleFavorite('3');
      
      expect(viewModel.isFavorite('3'), isTrue, reason: 'State should update optimistically');
      
      completer.complete(Left(ServerFailure(message: 'Failed to toggle favorite', statusCode: 500)));
      await toggleFuture;
      
      expect(viewModel.isFavorite('3'), isFalse, reason: 'State should revert after API failure');
      expect(viewModel.state.error, isNotNull, reason: 'Error should be set');
      
      await disposeViewModel(viewModel);
    });
    
    test('toggleBookmark immediately updates state before API call completes', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(<Recipe>[])); 
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(<Recipe>[])); 
      
      final completer = Completer<Either<Failure, Recipe>>();
      when(() => mockBookmarkRecipe(any()))
          .thenAnswer((_) => completer.future);
      
      viewModel = createViewModel();
      await waitForViewModelInit();

      expect(viewModel.isBookmarked('3'), isFalse, reason: 'Recipe 3 should not be bookmarked initially');
      
      final toggleFuture = viewModel.toggleBookmark('3');
      
      expect(viewModel.isBookmarked('3'), isTrue, reason: 'State should update optimistically');
      
      completer.complete(Right(testRecipes[2].copyWith(isBookmarked: true)));
      await toggleFuture;
      
      expect(viewModel.isBookmarked('3'), isTrue, reason: 'State should maintain the update after API success');
      
      await disposeViewModel(viewModel);
    });
    
    test('toggleBookmark reverts state update if API call fails', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(<Recipe>[])); 
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(<Recipe>[])); 
      
      final completer = Completer<Either<Failure, Recipe>>();
      when(() => mockBookmarkRecipe(any()))
          .thenAnswer((_) => completer.future);
      
      viewModel = createViewModel();
      await waitForViewModelInit();
      
      expect(viewModel.isBookmarked('3'), isFalse, reason: 'Recipe 3 should not be bookmarked initially');
      
      final toggleFuture = viewModel.toggleBookmark('3');
      
      expect(viewModel.isBookmarked('3'), isTrue, reason: 'State should update optimistically');
      
      completer.complete(Left(ServerFailure(message: 'Failed to toggle bookmark', statusCode: 500)));
      await toggleFuture;
      
      expect(viewModel.isBookmarked('3'), isFalse, reason: 'State should revert after API failure');
      expect(viewModel.state.error, isNotNull, reason: 'Error should be set');
      
      await disposeViewModel(viewModel);
    });
    
    test('toggleFavorite updates selectedRecipe if it matches the toggled recipe', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(<Recipe>[])); 
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(<Recipe>[])); 
      
      final updatedRecipe = testRecipes[1].copyWith(isFavorite: true);
      when(() => mockFavoriteRecipe(any()))
          .thenAnswer((_) async => Right(updatedRecipe));
      
      viewModel = createViewModel();
      await waitForViewModelInit();
      
      final selectedRecipe = testRecipes[1];
      viewModel.setSelectedRecipe(selectedRecipe);
      expect(viewModel.state.selectedRecipe?.id, equals('2'), reason: 'Recipe 2 should be selected');
      expect(viewModel.isFavorite('2'), isFalse, reason: 'Recipe 2 should not be favorite initially');
      
      await viewModel.toggleFavorite('2');
      
      expect(viewModel.isFavorite('2'), isTrue, reason: 'Recipe 2 should now be in favoriteIds');
      expect(viewModel.state.selectedRecipe?.id, equals('2'), reason: 'Recipe 2 should still be selected');
      expect(viewModel.state.selectedRecipe?.isFavorite, isTrue, reason: 'Selected recipe should be updated with favorite status');
      
      await disposeViewModel(viewModel);
    });
    
    test('toggleBookmark updates selectedRecipe if it matches the toggled recipe', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(<Recipe>[])); 
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(<Recipe>[])); 
      
      final updatedRecipe = testRecipes[0].copyWith(isBookmarked: true);
      when(() => mockBookmarkRecipe(any()))
          .thenAnswer((_) async => Right(updatedRecipe));
      
      viewModel = createViewModel();
      await waitForViewModelInit();
      
      final selectedRecipe = testRecipes[0];
      viewModel.setSelectedRecipe(selectedRecipe);
      expect(viewModel.state.selectedRecipe?.id, equals('1'), reason: 'Recipe 1 should be selected');
      expect(viewModel.isBookmarked('1'), isFalse, reason: 'Recipe 1 should not be bookmarked initially');
      
      await viewModel.toggleBookmark('1');
      
      expect(viewModel.isBookmarked('1'), isTrue, reason: 'Recipe 1 should now be in bookmarkIds');
      expect(viewModel.state.selectedRecipe?.id, equals('1'), reason: 'Recipe 1 should still be selected');
      expect(viewModel.state.selectedRecipe?.isBookmarked, isTrue, reason: 'Selected recipe should be updated with bookmark status');
      
      await disposeViewModel(viewModel);
    });
  });
  
  group('Recipe Selection', () {
    setUp(() {
      mockGetAllRecipes = MockGetAllRecipes();
      mockFavoriteRecipe = MockFavoriteRecipe();
      mockBookmarkRecipe = MockBookmarkRecipe();
      
      reset(mockGetAllRecipes);
      reset(mockFavoriteRecipe);
      reset(mockBookmarkRecipe);
      
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(favoriteRecipes)); 
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(bookmarkedRecipes)); 
    });
    
    test('setSelectedRecipe updates state with the selected recipe', () async {
      viewModel = createViewModel();
      await waitForViewModelInit();
      
      expect(viewModel.state.selectedRecipe, isNull, reason: 'No recipe should be selected initially');
      
      final selectedRecipe = testRecipes[0]; 
      viewModel.setSelectedRecipe(selectedRecipe);
      
      expect(viewModel.state.selectedRecipe, equals(selectedRecipe), reason: 'Selected recipe should be stored in state');
      
      await disposeViewModel(viewModel);
    });
    
    test('setSelectedRecipe updates and maintains the selection', () async {
      viewModel = createViewModel();
      await waitForViewModelInit();
      
      expect(viewModel.state.selectedRecipe, isNull, reason: 'No recipe should be selected initially');
      
      final selectedRecipe = testRecipes[0]; 
      viewModel.setSelectedRecipe(selectedRecipe);
      
      expect(viewModel.state.selectedRecipe, equals(selectedRecipe), reason: 'Selected recipe should be stored in state');

      final newSelectedRecipe = testRecipes[1]; 
      viewModel.setSelectedRecipe(newSelectedRecipe);
      
      expect(viewModel.state.selectedRecipe, equals(newSelectedRecipe), reason: 'Selected recipe should be updated');
      
      await disposeViewModel(viewModel);
    });
    
    test('selectedRecipe is preserved after toggling its favorite status', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(<Recipe>[])); 
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(<Recipe>[]));
      
      final favoritedRecipe = testRecipes[0].copyWith(isFavorite: true);
      when(() => mockFavoriteRecipe(any()))
          .thenAnswer((_) async => Right(favoritedRecipe));
          
      viewModel = createViewModel();
      await waitForViewModelInit();
      
      final selectedRecipe = testRecipes[0]; 
      viewModel.setSelectedRecipe(selectedRecipe);
      expect(viewModel.state.selectedRecipe?.id, equals('1'), reason: 'Recipe 1 should be selected');
      
      await viewModel.toggleFavorite('1');
      
      expect(viewModel.state.selectedRecipe?.id, equals('1'), reason: 'Recipe 1 should still be selected after toggle');
      expect(viewModel.state.selectedRecipe?.isFavorite, isTrue, reason: 'Selected recipe should show updated favorite status');
      
      await disposeViewModel(viewModel);
    });
    
    test('selectedRecipe is preserved after toggling its bookmark status', () async {
      when(() => mockGetAllRecipes(any()))
          .thenAnswer((_) async => Right(testRecipes));
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(<Recipe>[])); 
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(<Recipe>[]));
      
      final bookmarkedRecipe = testRecipes[0].copyWith(isBookmarked: true);
      when(() => mockBookmarkRecipe(any()))
          .thenAnswer((_) async => Right(bookmarkedRecipe));
          
      viewModel = createViewModel();
      await waitForViewModelInit();
      
      final selectedRecipe = testRecipes[0]; 
      viewModel.setSelectedRecipe(selectedRecipe);
      expect(viewModel.state.selectedRecipe?.id, equals('1'), reason: 'Recipe 1 should be selected');
      
      await viewModel.toggleBookmark('1');
      
      expect(viewModel.state.selectedRecipe?.id, equals('1'), reason: 'Recipe 1 should still be selected after toggle');
      expect(viewModel.state.selectedRecipe?.isBookmarked, isTrue, reason: 'Selected recipe should show updated bookmark status');
      
      await disposeViewModel(viewModel);
    });
  });
}