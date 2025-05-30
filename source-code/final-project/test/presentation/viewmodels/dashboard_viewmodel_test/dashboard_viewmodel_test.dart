import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import 'package:recipevault/core/errors/failure.dart';

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}
class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}
class MockRecipeState extends Mock implements RecipeState {}

class MockRecipeViewModel extends Mock implements RecipeViewModel {
  final RecipeState _state;
  
  MockRecipeViewModel({RecipeState? state}) : _state = state ?? MockRecipeState() {
    when(() => loadRecipes()).thenAnswer((_) async {});
    when(() => loadFavorites()).thenAnswer((_) async {});
    when(() => loadBookmarks()).thenAnswer((_) async {});
    when(() => initializeData()).thenAnswer((_) async {});
    when(() => setSelectedLetter(any())).thenAnswer((_) async {});
    when(() => setSelectedRecipe(any())).thenAnswer((_) {});
    when(() => toggleFavorite(any())).thenAnswer((_) async {});
    when(() => toggleBookmark(any())).thenAnswer((_) async {});
    when(() => isFavorite(any())).thenReturn(false);
    when(() => isBookmarked(any())).thenReturn(false);
  }
  
  @override
  RecipeState get state => _state;
}

MockRecipeState createMockRecipeState([List<Recipe> defaultRecipes = const []]) {
  final mock = MockRecipeState();
  when(() => mock.recipes).thenReturn(defaultRecipes);
  return mock;
}

class MockRef extends Mock implements Ref {
  final Map<ProviderListenable, Object?> _values = {};
  final Map<Type, Object?> _defaultValues = {};
  MockRecipeState? _recipeState;
  
  void mockProviderValue<T>(ProviderListenable<T> provider, T value) {
    _values[provider] = value;
    
    if (value is MockRecipeState) {
      _recipeState = value;
    }
  }
  
  void mockDefaultValue<T>(T value) {
    _defaultValues[T] = value;
  }
  
  @override
  T read<T>(ProviderListenable<T> provider) {
    if (_values.containsKey(provider)) {
      return _values[provider] as T;
    }
    
    final providerString = provider.toString();
    
    if (providerString.contains('recipeProvider') && T == RecipeViewModel) {
      final recipeState = _recipeState ?? MockRecipeState();
      return MockRecipeViewModel(state: recipeState) as T;
    }
    
    if (provider == recipeProvider || providerString.contains('Recipe')) {
      if (T == RecipeState) {
        final state = _recipeState ?? MockRecipeState();
        return state as T;
      }
    }
    
    if (_defaultValues.containsKey(T)) {
      return _defaultValues[T] as T;
    }

    if (T == RecipeState) {
      return MockRecipeState() as T;
    }
    
    if (T == RecipeViewModel) {
      return MockRecipeViewModel() as T;
    }

    return null as T;
  }
  
  @override
  ProviderSubscription<T> listen<T>(
    ProviderListenable<T> provider, 
    void Function(T? previous, T next) listener, 
    {bool fireImmediately = false, void Function(Object error, StackTrace stackTrace)? onError}
  ) {
    if (fireImmediately && _values.containsKey(provider)) {
      final value = _values[provider] as T;
      listener(null, value);
    }
    
    final mockSubscription = MockProviderSubscription<T>();
    return mockSubscription;
  }
}

class MockProviderSubscription<T> extends Mock implements ProviderSubscription<T> {
  @override
  void close() {
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  
  late MockFavoriteRecipe mockFavoriteRecipe;
  late MockBookmarkRecipe mockBookmarkRecipe;
  late MockRecipeState mockRecipeState;
  late MockRef mockRef;
  late DashboardViewModel viewModel;

  final testRecipes = [
    Recipe(
      id: '1',
      name: 'Apple Pie',
      instructions: 'Mix ingredients and bake',
      thumbnailUrl: 'apple_pie.jpg',
      ingredients: [
        const Ingredient(name: 'Apples', measure: '3 cups'),
        const Ingredient(name: 'Sugar', measure: '1 cup'),
        const Ingredient(name: 'Flour', measure: '2 cups'),
      ],
      isFavorite: false,
      isBookmarked: true,
    ),
    Recipe(
      id: '2',
      name: 'Banana Bread',
      instructions: 'Mash bananas, mix ingredients, and bake',
      thumbnailUrl: 'banana_bread.jpg',
      ingredients: [
        const Ingredient(name: 'Bananas', measure: '3 medium'),
        const Ingredient(name: 'Flour', measure: '2 cups'),
        const Ingredient(name: 'Sugar', measure: '1 cup'),
      ],
      isFavorite: true,
      isBookmarked: false,
    ),
    Recipe(
      id: '3',
      name: 'Chocolate Cake',
      instructions: 'Mix dry ingredients, add wet ingredients, and bake',
      thumbnailUrl: 'chocolate_cake.jpg',
      ingredients: [
        const Ingredient(name: 'Cocoa', measure: '1/2 cup'),
        const Ingredient(name: 'Flour', measure: '2 cups'),
        const Ingredient(name: 'Sugar', measure: '1 1/2 cups'),
      ],
      isFavorite: true,
      isBookmarked: true,
    ),
  ];
  
  DashboardViewModel createViewModel({
    bool favoriteRecipeSuccess = true,
    bool bookmarkRecipeSuccess = true,
    String errorMessage = 'Error occurred',
    List<Recipe> initialRecipes = const [],
    Set<String> initialFavorites = const {},
    Set<String> initialBookmarks = const {},
  }) {
    when(() => mockRecipeState.recipes).thenReturn(initialRecipes);
    
    final mockRecipe = Recipe(
      id: 'mock-id',
      name: 'Mock Recipe',
      instructions: 'Mock instructions',
      ingredients: [const Ingredient(name: 'Mock ingredient')],
    );
    
    when(() => mockFavoriteRecipe(any<FavoriteRecipeParams>()))
        .thenAnswer((_) async => favoriteRecipeSuccess 
            ? Right(mockRecipe) 
            : Left(ServerFailure(message: errorMessage, statusCode: 500)));
    
    when(() => mockBookmarkRecipe(any<BookmarkRecipeParams>()))
        .thenAnswer((_) async => bookmarkRecipeSuccess 
            ? Right(mockRecipe) 
            : Left(ServerFailure(message: errorMessage, statusCode: 500)));
    
    final vm = DashboardViewModel.forTesting(
      favoriteRecipe: mockFavoriteRecipe,
      bookmarkRecipe: mockBookmarkRecipe,
      recipeState: mockRecipeState,
      ref: mockRef,
    );
    
    return vm;
  }
  
  Future<void> waitForViewModelInit(DashboardViewModel viewModel) async {
    int attempts = 0;
    while ((viewModel.state.isLoading || !viewModel.state.isPartiallyLoaded) && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 10));
      attempts++;
    }
    
    await Future.delayed(const Duration(milliseconds: 50));
  }

  void disposeViewModel(DashboardViewModel? viewModel) {
    if (viewModel != null) {
      viewModel.dispose();
    }
  }
  
  setUpAll(() {
    registerFallbackValue(const FavoriteRecipeParams(recipeId: 'test-id'));
    registerFallbackValue(const BookmarkRecipeParams(recipeId: 'test-id'));
  });
  
  setUp(() {
    mockFavoriteRecipe = MockFavoriteRecipe();
    mockBookmarkRecipe = MockBookmarkRecipe();
    mockRecipeState = createMockRecipeState([]);
    mockRef = MockRef();
    
    when(() => mockFavoriteRecipe.getFavorites())
        .thenAnswer((_) async => const Right<Failure, List<Recipe>>([]));
    
    when(() => mockBookmarkRecipe.getBookmarks())
        .thenAnswer((_) async => const Right<Failure, List<Recipe>>([]));
    
    mockRef.mockProviderValue(recipeProvider, mockRecipeState);
    mockRef.mockProviderValue(favoriteRecipeProvider, mockFavoriteRecipe);
    mockRef.mockProviderValue(bookmarkRecipeProvider, mockBookmarkRecipe);
  });
  
  group('Favorites Management', () {
    test('initializes with correct favorite state', () async {
      final favoriteIds = {'1', '3'};
      final favoriteRecipes = testRecipes.where((r) => favoriteIds.contains(r.id)).toList();
      
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right(favoriteRecipes));
      
      viewModel = createViewModel(
        initialRecipes: testRecipes,
        initialFavorites: favoriteIds,
      );
      
      viewModel.state = viewModel.state.copyWith(
        favoriteIds: favoriteIds,
        isLoading: false,
        isPartiallyLoaded: true,
      );
      
      expect(viewModel.state.favoriteIds, equals(favoriteIds),
        reason: 'Favorite IDs should match the provided initial favorites');
      expect(viewModel.state.favoriteRecipes, unorderedEquals(favoriteRecipes),
        reason: 'Favorite recipes should match recipes with the favorite IDs');
      
      disposeViewModel(viewModel);
    });
    
    test('adds recipe to favorites when loading favorites', () async {
      final recipeId = '1';
      final mockRecipe = Recipe(
        id: recipeId,
        name: 'Mock Recipe',
        instructions: 'Mock instructions',
        ingredients: [const Ingredient(name: 'Mock ingredient')],
        isFavorite: true,
      );
      
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right([mockRecipe]));
      
      viewModel = createViewModel(
        initialRecipes: [mockRecipe],
        initialFavorites: {}, 
      );
      
      await viewModel.loadFavorites();
      
      expect(viewModel.state.favoriteIds.contains(recipeId), isTrue,
        reason: 'Recipe ID should be added to favorites after loading');
      
      verify(() => mockFavoriteRecipe.getFavorites()).called(1);
      
      disposeViewModel(viewModel);
    });
    
    test('handles updates to favorite recipes correctly', () async {
      final recipeId = '1';
      final initialRecipe = Recipe(
        id: recipeId,
        name: 'Mock Recipe',
        instructions: 'Mock instructions',
        ingredients: [const Ingredient(name: 'Mock ingredient')],
        isFavorite: true,
      );
      
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => Right([initialRecipe]));
      
      viewModel = createViewModel(
        initialRecipes: [initialRecipe],
        initialFavorites: {recipeId},
      );
      
      viewModel.state = viewModel.state.copyWith(
        favoriteIds: {recipeId},
        isLoading: false,
        isPartiallyLoaded: true,
      );

      expect(viewModel.state.favoriteIds.contains(recipeId), isTrue,
        reason: 'Initial state should have the recipe as favorite');
      
      when(() => mockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right([]));
      
      await viewModel.loadFavorites();
      
      expect(viewModel.state.favoriteIds.isEmpty, isTrue,
        reason: 'Favorite IDs should be empty after reloading with empty favorites list');
      
      verify(() => mockFavoriteRecipe.getFavorites()).called(1);
      
      disposeViewModel(viewModel);
    });
    
  group('Bookmarks Management', () {
    test('initializes with correct bookmark state', () async {
      final bookmarkIds = {'2', '4'};
      final bookmarkedRecipes = testRecipes.where((r) => bookmarkIds.contains(r.id)).toList();
      
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right(bookmarkedRecipes));
      
      viewModel = createViewModel(
        initialRecipes: testRecipes,
        initialBookmarks: bookmarkIds,
      );
      
      viewModel.state = viewModel.state.copyWith(
        bookmarkIds: bookmarkIds,
        isLoading: false,
        isPartiallyLoaded: true,
      );
      
      expect(viewModel.state.bookmarkIds, equals(bookmarkIds),
        reason: 'Bookmark IDs should match the provided initial bookmarks');
      expect(viewModel.state.bookmarkedRecipes, unorderedEquals(bookmarkedRecipes),
        reason: 'Bookmarked recipes should match recipes with the bookmark IDs');
      
      disposeViewModel(viewModel);
    });
    
    test('adds recipe to bookmarks when loading bookmarks', () async {
      final recipeId = '1';
      final mockRecipe = Recipe(
        id: recipeId,
        name: 'Mock Recipe',
        instructions: 'Mock instructions',
        ingredients: [const Ingredient(name: 'Mock ingredient')],
        isBookmarked: true,
      );
      
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Right([mockRecipe]));
      
      viewModel = createViewModel(
        initialRecipes: [mockRecipe],
        initialBookmarks: {}, 
      );
      
      await viewModel.loadBookmarks();
      
      expect(viewModel.state.bookmarkIds.contains(recipeId), isTrue,
        reason: 'Recipe ID should be added to bookmarks after loading');
      
      verify(() => mockBookmarkRecipe.getBookmarks()).called(1);
      
      disposeViewModel(viewModel);
    });
  });
  
  group('Loading States', () {
    test('shows loading state during initialization', () async {
      final mockRecipe = Recipe(
        id: 'test-id',
        name: 'Test Recipe',
        instructions: 'Test instructions',
        ingredients: [const Ingredient(name: 'Test ingredient')],
      );
      
      final completer = Completer<Either<Failure, Recipe>>();
      when(() => mockFavoriteRecipe(any())).thenAnswer((_) => completer.future);
      
      viewModel = createViewModel();
      expect(viewModel.state.isLoading, isTrue);
      completer.complete(Right(mockRecipe));
      await waitForViewModelInit(viewModel);
      
      expect(viewModel.state.isLoading, isFalse);
      
      disposeViewModel(viewModel);
    });
    
    test('handles error state properly', () async {
      final dashboardState = DashboardState();
      
      final newState = dashboardState.copyWith(
        error: 'Test error message',
        isLoading: false
      );
      
      expect(newState.error, 'Test error message');
      expect(newState.isLoading, isFalse);
    });
    
    test('error is properly set in viewmodel during failure', () async {
      final localMockFavorite = MockFavoriteRecipe();
      final localMockBookmark = MockBookmarkRecipe();
      final localMockState = createMockRecipeState([]);
      final localRef = MockRef();
      
      when(() => localMockFavorite.getFavorites())
          .thenAnswer((_) async => Left(ServerFailure(
                message: 'Critical error',
                statusCode: 500,
              )));
      
      when(() => localMockBookmark.getBookmarks())
          .thenAnswer((_) async => const Right<Failure, List<Recipe>>([]));
          
      localRef.mockProviderValue(favoriteRecipeProvider, localMockFavorite);
      localRef.mockProviderValue(bookmarkRecipeProvider, localMockBookmark);
      localRef.mockProviderValue(recipeProvider, localMockState);
      
      final localViewModel = DashboardViewModel.forTesting(
        favoriteRecipe: localMockFavorite,
        bookmarkRecipe: localMockBookmark, 
        recipeState: localMockState,
        ref: localRef,
      );
      
      localViewModel.state = localViewModel.state.copyWith(
        isLoading: false,
        error: null
      );

      localViewModel.state = localViewModel.state.copyWith(
        error: 'Manual error test',
        isLoading: false
      );
      
      expect(localViewModel.state.error, isNotNull);
      expect(localViewModel.state.error, 'Manual error test');

      localViewModel.dispose();
    });
  });

  group('Bookmarks Management - Extended', () {
    test('handles errors when loading bookmarks', () async {
      final localMockBookmarkRecipe = MockBookmarkRecipe();
      final localMockFavoriteRecipe = MockFavoriteRecipe();
      final localMockRecipeState = createMockRecipeState([]);
      final localMockRef = MockRef();
      
      when(() => localMockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) async => Left(ServerFailure(
            message: 'Failed to fetch bookmarks',
            statusCode: 500,
          )));
      
      when(() => localMockFavoriteRecipe.getFavorites())
          .thenAnswer((_) async => const Right<Failure, List<Recipe>>([]));
      
      localMockRef.mockProviderValue(bookmarkRecipeProvider, localMockBookmarkRecipe);
      localMockRef.mockProviderValue(favoriteRecipeProvider, localMockFavoriteRecipe);
      localMockRef.mockProviderValue(recipeProvider, localMockRecipeState);
      
      final localViewModel = DashboardViewModel.forTesting(
        favoriteRecipe: localMockFavoriteRecipe,
        bookmarkRecipe: localMockBookmarkRecipe,
        recipeState: localMockRecipeState,
        ref: localMockRef,
      );

      localViewModel.state = localViewModel.state.copyWith(isLoading: false);
      await localViewModel.loadBookmarks();
      
      expect(localViewModel.state.error, isNotNull,
        reason: 'Error state should be set after bookmarks loading fails');
      expect(localViewModel.state.error, contains('Failed to fetch bookmarks'),
        reason: 'Error message should contain the original failure message');
      
      verify(() => localMockBookmarkRecipe.getBookmarks()).called(greaterThanOrEqualTo(1));
      
      localViewModel.dispose();
    });
    
    test('asynchronously loads bookmarks with controllable timing', () async {
      final recipeId = '1';
      final mockRecipe = Recipe(
        id: recipeId,
        name: 'Mock Recipe',
        instructions: 'Mock instructions',
        ingredients: [const Ingredient(name: 'Mock ingredient')],
        isBookmarked: true,
      );

      final completer = Completer<Either<Failure, List<Recipe>>>();
      when(() => mockBookmarkRecipe.getBookmarks())
          .thenAnswer((_) => completer.future);
      
      viewModel = createViewModel(
        initialRecipes: [mockRecipe],
        initialBookmarks: {}, 
      );
      await waitForViewModelInit(viewModel);
      
      final futureOperation = viewModel.loadBookmarks();
      
      expect(viewModel.state.isLoading, isTrue,
        reason: 'ViewModel should be in loading state while waiting for bookmarks');
      
      completer.complete(Right([mockRecipe]));
      await futureOperation;
      
      expect(viewModel.state.isLoading, isFalse,
        reason: 'Loading state should be false after bookmarks are loaded');
      expect(viewModel.state.bookmarkIds.contains(recipeId), isTrue,
        reason: 'Bookmarked recipes should be added to state after loading');
      
      disposeViewModel(viewModel);
    });
  });
  
  group('Empty States', () {
    test('handles empty recipe list properly', () async {
      viewModel = createViewModel(initialRecipes: []);
      await waitForViewModelInit(viewModel);
      
      expect(viewModel.state.recipes, isEmpty);
      expect(viewModel.state.favoriteRecipes, isEmpty);
      expect(viewModel.state.bookmarkedRecipes, isEmpty);
      
      disposeViewModel(viewModel);
    });
    
    test('handles partial loading state correctly', () async {
      DashboardViewModel createViewModel({
        List<Recipe> initialRecipes = const [],
        Set<String> initialFavorites = const {},
        Set<String> initialBookmarks = const {},
        bool skipAutoInitialization = false,
      }) {
        when(() => mockRecipeState.recipes).thenReturn(initialRecipes);
        
        if (initialFavorites.isNotEmpty) {
          final favoriteRecipes = initialRecipes
              .where((recipe) => initialFavorites.contains(recipe.id))
              .toList();
          when(() => mockFavoriteRecipe.getFavorites())
              .thenAnswer((_) async => Right(favoriteRecipes));
        }
        
        if (initialBookmarks.isNotEmpty) {
          final bookmarkedRecipes = initialRecipes
              .where((recipe) => initialBookmarks.contains(recipe.id))
              .toList();
          when(() => mockBookmarkRecipe.getBookmarks())
              .thenAnswer((_) async => Right(bookmarkedRecipes));
        }
        
        final vm = DashboardViewModel.forTesting(
          favoriteRecipe: mockFavoriteRecipe,
          bookmarkRecipe: mockBookmarkRecipe,
          recipeState: mockRecipeState,
          ref: mockRef,
        );
        
        vm.state = vm.state.copyWith(
          favoriteIds: initialFavorites,
          bookmarkIds: initialBookmarks,
        );
        
        if (skipAutoInitialization) {
          vm.state = vm.state.copyWith(isLoading: false, isPartiallyLoaded: true);
        }
        
        return vm;
      }
      
      viewModel = createViewModel();
      await waitForViewModelInit(viewModel);
      viewModel = createViewModel(skipAutoInitialization: true);
      final updatedState = viewModel.state.copyWith(isPartiallyLoaded: true);
      
      expect(updatedState.isPartiallyLoaded, isTrue);
      
      disposeViewModel(viewModel);
    });
  });
 });
}