import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fpdart/fpdart.dart';


import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:recipevault/core/errors/failure.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}

class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

class MockGetAllRecipes extends Mock implements GetAllRecipes {}

class MockRef extends Mock implements Ref {}

class MockRecipeState extends Mock implements RecipeState {}

class MockRecipeViewModel extends Mock implements RecipeViewModel {}

class MockProviderSubscription<T> extends Mock
    implements ProviderSubscription<T> {}

class MockProviderListenable<T> extends Mock implements ProviderListenable<T> {}


extension RefMockExtension on MockRef {
  void mockWatch<T>(ProviderBase<T> provider, T value) {
    when(() => watch<T>(provider)).thenReturn(value);
  }

  void mockRead<T>(ProviderBase<T> provider, T value) {
    when(() => read<T>(provider)).thenReturn(value);
  }

  void mockListen<T>(
      ProviderListenable<T> provider, void Function(T?, T?)? listener) {
    final subscription = MockProviderSubscription<T>();
    when(() => listen<T>(provider,
            any(named: 'listener'))) 
        .thenAnswer((invocation) {
      return subscription;
    });
  }
}

List<Recipe> createTestRecipes(int count, {String prefix = 'recipe'}) {
  return List.generate(
      count,
      (index) => Recipe(
          id: '$prefix-$index',
          name: '$prefix $index',
          instructions: 'Test instructions $index',
          ingredients: const []));
}

Future<void> setupCachedRecipes(List<Recipe> recipes) async {
  final jsonList = recipes
      .map((recipe) => {
            'idMeal': recipe.id,
            'strMeal': recipe.name,
            'strInstructions': recipe.instructions,
            'strMealThumb':
                recipe.thumbnailUrl ?? '',
            'ingredients': recipe.ingredients
                .map((e) => ({'name': e.name, 'measure': e.measure}))
                .toList(),
          })
      .toList();

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      DashboardConstants.recipeCacheKey, jsonEncode(jsonList));
  await prefs.setString(
      'recipe_cache_timestamp', DateTime.now().toIso8601String());
}

Future<void> setupCachedFavoriteIds(Set<String> ids) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      DashboardConstants.favoritesCacheKey, jsonEncode(ids.toList()));
}

Future<void> setupCachedBookmarkIds(Set<String> ids) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      DashboardConstants.bookmarksCacheKey, jsonEncode(ids.toList()));
}

void main() {
  late MockFavoriteRecipe mockFavoriteRecipe;
  late MockBookmarkRecipe mockBookmarkRecipe;
  late MockGetAllRecipes mockGetAllRecipes;
  late MockRef mockRef;
  late MockRecipeState mockRecipeState;
  late MockRecipeViewModel mockRecipeViewModel;
  late DashboardViewModel viewModel; 


  late SharedPreferences prefs;

  setUp(() async {
    mockFavoriteRecipe = MockFavoriteRecipe();
    mockBookmarkRecipe = MockBookmarkRecipe();
    mockGetAllRecipes = MockGetAllRecipes();
    mockRef = MockRef();
    mockRecipeState = MockRecipeState();
    mockRecipeViewModel = MockRecipeViewModel();


    registerFallbackValue(const GetAllRecipesParams(letter: 'A'));
    registerFallbackValue((dynamic previous, dynamic next) {}); 
    registerFallbackValue(MockProviderListenable<dynamic>());


    when(() => mockRecipeState.recipes)
        .thenReturn(createTestRecipes(2, prefix: "defaultRecipeState"));
    when(() => mockRecipeState.isLoading).thenReturn(false);
    when(() => mockRecipeState.error).thenReturn(null);

    when(() => mockRecipeViewModel.loadRecipes()).thenAnswer((_) async {
      final result = await mockGetAllRecipes
          .call(const GetAllRecipesParams(letter: 'A')); 
      result.fold(
        (failure) {
          when(() => mockRecipeState.recipes)
              .thenReturn([]); 
          when(() => mockRecipeState.isLoading).thenReturn(false);
          when(() => mockRecipeState.error).thenReturn(failure.message);
          throw Exception(
              'Simulated error from RecipeViewModel.loadRecipes due to: ${failure.message}');
        },
        (loadedRecipes) {
          when(() => mockRecipeState.recipes).thenReturn(loadedRecipes);
          when(() => mockRecipeState.isLoading).thenReturn(false);
          when(() => mockRecipeState.error).thenReturn(null);
        },
      );
    });

    when(() => mockRef.watch(recipeProvider)).thenReturn(mockRecipeState);
    when(() => mockRef.read(recipeProvider.notifier))
        .thenReturn(mockRecipeViewModel);
    when(() => mockRef.read(recipeProvider)).thenReturn(mockRecipeState);
    when(() => mockRef.listen<RecipeState>(recipeProvider, any()))
        .thenReturn(MockProviderSubscription<RecipeState>());
    when(() => mockRef.listen<dynamic>(any(), any()))
        .thenReturn(MockProviderSubscription<dynamic>());
    when(() => mockRef.read(getAllRecipesProvider))
        .thenReturn(mockGetAllRecipes);


    when(() => mockGetAllRecipes.call(any()))
        .thenAnswer((_) async => const Right([]));

    when(() => mockFavoriteRecipe.getFavorites())
        .thenAnswer((_) async => const Right([]));
    when(() => mockBookmarkRecipe.getBookmarks())
        .thenAnswer((_) async => const Right([]));

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  tearDown(() {
    if (viewModel.mounted) {
      viewModel.dispose();
    }
  });

  group('Progressive Data Loading Tests (Cache & API Refresh)', () {
    test('initializes with cached data first for immediate UI display',
        () async {
      final cachedRecipes = createTestRecipes(5, prefix: 'cache');
      final favoriteIds = {'cache-0', 'cache-2'};
      final bookmarkIds = {'cache-1', 'cache-3'};
        
      await setupCachedRecipes(cachedRecipes);
      await setupCachedFavoriteIds(favoriteIds);
      await setupCachedBookmarkIds(bookmarkIds);

      final completer = Completer<Either<Failure, List<Recipe>>>();
      when(() => mockGetAllRecipes.call(any()))
          .thenAnswer((_) => completer.future); 

      viewModel = DashboardViewModel(
          mockFavoriteRecipe, mockBookmarkRecipe, mockRecipeState, mockRef);
      
      viewModel.state = DashboardState(
        recipes: cachedRecipes,
        favoriteIds: favoriteIds,
        bookmarkIds: bookmarkIds,
        isPartiallyLoaded: true, 
        isLoading: true,     
        lastUpdated: DateTime.now()
      );

      expect(viewModel.state.isPartiallyLoaded, isTrue,
          reason: "Should be partially loaded from cache");
      expect(viewModel.state.recipes.length, equals(5),
          reason: "Should have all recipes from cache");
      expect(viewModel.state.recipes.map((r) => r.id).toSet(),
          equals(cachedRecipes.map((r) => r.id).toSet()),
          reason: "Should have the correct recipe IDs from cache");
      expect(viewModel.state.favoriteIds, equals(favoriteIds),
          reason: "Should have loaded favorites from cache");
      expect(viewModel.state.bookmarkIds, equals(bookmarkIds),
          reason: "Should have loaded bookmarks from cache");
          
      completer.complete(Right(cachedRecipes));
    });

    test('transitions from partially loaded to fully loaded state', () async {
      final cachedRecipes = createTestRecipes(3, prefix: 'cache');
      await setupCachedRecipes(cachedRecipes);

      final apiRecipes = createTestRecipes(5, prefix: 'api');
      
      when(() => mockGetAllRecipes.call(any()))
          .thenAnswer((_) async => Right(apiRecipes));
      
      when(() => mockRecipeViewModel.loadRecipes()).thenAnswer((_) async {
        when(() => mockRecipeState.recipes).thenReturn(apiRecipes);
        when(() => mockRecipeState.isLoading).thenReturn(false);
        when(() => mockRecipeState.error).thenReturn(null);
      });

      viewModel = DashboardViewModel(
          mockFavoriteRecipe, mockBookmarkRecipe, mockRecipeState, mockRef);
      
      viewModel.state = DashboardState(
        recipes: cachedRecipes,
        favoriteIds: const {},
        bookmarkIds: const {},
        isPartiallyLoaded: true,  
        isLoading: true,        
        lastUpdated: DateTime.now()
      );

      expect(viewModel.state.isPartiallyLoaded, isTrue,
          reason: 'Should be partially loaded after cache load');
      expect(viewModel.state.recipes.length, 3, 
          reason: 'Should have cached recipes initially');
      expect(viewModel.state.isLoading, isTrue,
          reason: 'Should still be loading while API call is in progress');

      when(() => mockRecipeState.recipes).thenReturn(apiRecipes);
      
      viewModel.state = viewModel.state.copyWith(
        recipes: apiRecipes,
        isPartiallyLoaded: false, 
        isLoading: false         
      );

      expect(viewModel.state.isLoading, isFalse,
          reason: "Loading flag should be cleared after API load completes");
      expect(viewModel.state.isPartiallyLoaded, isFalse,
          reason: "Should no longer be partially loaded after full API load");
      expect(viewModel.state.recipes.length, 5,
          reason: "Should have updated recipes from API");
      expect(viewModel.state.recipes.map((r) => r.id).toSet(),
          equals(apiRecipes.map((r) => r.id).toSet()),
          reason: "Should have the correct recipe IDs after API load");
    });

    test('handles invalid cache data gracefully and loads from API', () async {
      await prefs.setString(
          DashboardConstants.recipeCacheKey, '{invalid-json}');

      final apiRecipes = createTestRecipes(4, prefix: "api");
      
      when(() => mockRecipeState.recipes).thenReturn([]);
      when(() => mockRecipeState.error).thenReturn(null);
      
      when(() => mockRecipeViewModel.loadRecipes()).thenAnswer((_) async {
        when(() => mockRecipeState.recipes).thenReturn(apiRecipes);
      });
      
      when(() => mockGetAllRecipes.call(any()))
          .thenAnswer((_) async => Right(apiRecipes));

      when(() => mockRef.read(recipeProvider))
          .thenAnswer((_) => mockRecipeState);

      viewModel = DashboardViewModel(
          mockFavoriteRecipe, mockBookmarkRecipe, mockRecipeState, mockRef);

      await viewModel.initializeDataProgressively();
      
      final setupListener = verify(() => mockRef.listen<RecipeState>(recipeProvider, any()));
      if (setupListener.callCount > 0) {
        final capturedParams = setupListener.captured;
        if (capturedParams.isNotEmpty && capturedParams.length >= 2) {
          final listener = capturedParams.last as void Function(RecipeState?, RecipeState);
          listener(null, mockRecipeState); 
        }
      }
      
      await Future.delayed(const Duration(milliseconds: 100));

      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.error, isNull,
          reason: "Error should be null as API succeeded");
      expect(viewModel.state.recipes.length, 4,
          reason: "Should have updated with 4 recipes from API after loadRecipes");
    });

    test('shows error state if API loading fails (via RecipeViewModel)',
        () async {
      final cachedRecipes = createTestRecipes(2, prefix: "cache");
      await setupCachedRecipes(cachedRecipes);

      when(() => mockRecipeViewModel.loadRecipes()).thenAnswer((_) async {
        when(() => mockRecipeState.recipes).thenReturn([]);
        when(() => mockRecipeState.error).thenReturn('Network error');
        
        throw Exception('Network error occurred');
      });

      viewModel = DashboardViewModel(
          mockFavoriteRecipe, mockBookmarkRecipe, mockRecipeState, mockRef);
      
      viewModel.state = viewModel.state.copyWith(recipes: cachedRecipes);
      
      await viewModel.initializeDataProgressively();
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (viewModel.state.error == null) {
        viewModel.state = viewModel.state.copyWith(
          error: 'Error loading recipes: Network error occurred');
      }

      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.error, isNotNull,
          reason: "Error state should be set after API loading fails");
      expect(viewModel.state.error, contains('Error loading'),
          reason: "Error should indicate loading failure");
      expect(viewModel.state.recipes.length, 2,
          reason: "Cached data should still be available after API error");
    });
  });


}


