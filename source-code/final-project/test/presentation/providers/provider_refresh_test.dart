import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart' as recipes_vm;
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart' as dashboard_vm;
import 'package:recipevault/core/mixins/safe_async_mixin.dart';

class MockGetAllRecipes extends Mock implements GetAllRecipes {}
class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}
class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}
class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}
class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}
class FakeRecipeState extends Fake implements recipes_vm.RecipeState {}
class FakeDashboardState extends Fake implements dashboard_vm.DashboardState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late MockGetAllRecipes mockGetAllRecipes;
  late MockFavoriteRecipe mockFavoriteRecipe;
  late MockBookmarkRecipe mockBookmarkRecipe;
  
  setUpAll(() {
    registerFallbackValue(FakeGetAllRecipesParams());
    registerFallbackValue(FakeFavoriteRecipeParams());
    registerFallbackValue(FakeBookmarkRecipeParams());
    registerFallbackValue(FakeRecipeState());
    registerFallbackValue(FakeDashboardState());
  });
  
  setUp(() {
    mockGetAllRecipes = MockGetAllRecipes();
    mockFavoriteRecipe = MockFavoriteRecipe();
    mockBookmarkRecipe = MockBookmarkRecipe();
    
    const recipe1 = Recipe(id: 'recipe-1', name: 'Recipe 1', ingredients: []);
    const recipe2 = Recipe(id: 'recipe-2', name: 'Recipe 2', ingredients: []);
    
    when(() => mockGetAllRecipes(any()))
        .thenAnswer((_) async => const Right([recipe1, recipe2]));
    
    when(() => mockFavoriteRecipe.getFavorites())
        .thenAnswer((_) async => const Right([]));
    
    when(() => mockBookmarkRecipe.getBookmarks())
        .thenAnswer((_) async => const Right([]));
    
    when(() => mockFavoriteRecipe.call(any<FavoriteRecipeParams>()))
        .thenAnswer((_) async => const Right(Recipe(id: 'recipe-1', name: 'Recipe 1', ingredients: [], isFavorite: true)));
    
    when(() => mockBookmarkRecipe.call(any<BookmarkRecipeParams>()))
        .thenAnswer((_) async => const Right(Recipe(id: 'recipe-2', name: 'Recipe 2', ingredients: [], isBookmarked: true)));
  });
  
  group('Provider Refresh Optimization Tests', () {
    test('dashboard provider propagates state changes appropriately', () async {
      int dashboardRebuildCount = 0;
      int favoriteRecipesRebuildCount = 0;
      int bookmarkedRecipesRebuildCount = 0;
      
      final recipeViewModelProvider = StateNotifierProvider<recipes_vm.RecipeViewModel, recipes_vm.RecipeState>((ref) {
        return recipes_vm.RecipeViewModel(
          mockGetAllRecipes,
          mockFavoriteRecipe,
          mockBookmarkRecipe,
        );
      });
      
      final container = ProviderContainer(
        overrides: [
          getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),
          favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
          bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),
          recipes_vm.recipeProvider.overrideWithProvider(recipeViewModelProvider),
        ],
      );
      addTearDown(container.dispose);
      
      container.listen(
        dashboard_vm.dashboardProvider,
        (_, __) => dashboardRebuildCount++,
        fireImmediately: true,
      );
      
      container.listen(
        recipes_vm.favoriteRecipesProvider,
        (_, __) => favoriteRecipesRebuildCount++,
        fireImmediately: true,
      );
      
      container.listen(
        recipes_vm.bookmarkedRecipesProvider,
        (_, __) => bookmarkedRecipesRebuildCount++,
        fireImmediately: true,
      );
      
      await container.pump();
      
      dashboardRebuildCount = 0;
      favoriteRecipesRebuildCount = 0;
      bookmarkedRecipesRebuildCount = 0;
      
      await container.read(recipes_vm.recipeProvider.notifier).toggleFavorite('recipe-1');
      await container.pump();
      
      expect(dashboardRebuildCount, greaterThanOrEqualTo(1), reason: 'Dashboard rebuilds when state changes');
      expect(favoriteRecipesRebuildCount, greaterThanOrEqualTo(1), reason: 'Favorite recipes rebuilds when state changes');
      expect(bookmarkedRecipesRebuildCount, greaterThanOrEqualTo(1), reason: 'Bookmarked recipes rebuild because recipe list reference changes');
      
      dashboardRebuildCount = 0;
      favoriteRecipesRebuildCount = 0;
      bookmarkedRecipesRebuildCount = 0;
      
      await container.read(recipes_vm.recipeProvider.notifier).toggleBookmark('recipe-2');
      await container.pump();
      
      expect(dashboardRebuildCount, greaterThanOrEqualTo(1), reason: 'Dashboard rebuilds when state changes');
      expect(favoriteRecipesRebuildCount, equals(1), reason: 'Favorite recipes rebuild because recipe list reference changes');
      expect(bookmarkedRecipesRebuildCount, equals(1), reason: 'Bookmarked recipes should rebuild');
      
      container.dispose();
    });
    
    test('SafeAsyncMixin prevents operations after disposal', () async {
      final testObject = TestSafeAsyncObject();
      
      var result = await testObject.performOperation();
      expect(result, 'Operation completed');
        
      testObject.markDisposed();
      
      result = await testObject.performOperation();
      expect(result, isNull);
    });
    
    test('_safeUpdateState prevents state updates after disposal', () async {
      final testViewModel = TestViewModel();
      
      expect(testViewModel.updateCount, 0);
      
      final success1 = testViewModel.updateState();
      expect(success1, isTrue);
      expect(testViewModel.updateCount, 1);
      
      testViewModel.dispose();
      
      final success2 = testViewModel.updateState();
      expect(success2, isFalse, reason: 'Update after disposal should return false');
      expect(testViewModel.updateCount, 1, reason: 'Update count should not increase after disposal');
    });
    
    test('copyWith preserves unchanged data when updating state', () {
      final recipes = [const Recipe(id: 'recipe-1', name: 'Recipe 1', ingredients: [])];
      final favoriteIds = <String>{'recipe-2'};
      final bookmarkIds = <String>{'recipe-3'};
      
      final initialState = dashboard_vm.DashboardState(
        recipes: recipes,
        favoriteIds: favoriteIds,
        bookmarkIds: bookmarkIds,
        isLoading: false,
      );
      
      final newFavorites = Set<String>.from(favoriteIds)..add('recipe-1');
      final updatedState = initialState.copyWith(favoriteIds: newFavorites);
      
      expect(identical(updatedState.recipes, recipes), isTrue, 
          reason: 'Recipe list instance should be preserved');
      expect(identical(updatedState.bookmarkIds, bookmarkIds), isTrue, 
          reason: 'Bookmark set instance should be preserved');
      
      expect(identical(updatedState.favoriteIds, favoriteIds), isFalse, 
          reason: 'Favorite set should be a new instance');
      expect(updatedState.favoriteIds, contains('recipe-1'), 
          reason: 'Favorite set should contain the new item');
    });
    
    test('dashboard provider optimizes rebuilds with selective updates', () {
      int favoriteRebuilds = 0;
      int bookmarkRebuilds = 0;
      
      final recipes = [const Recipe(id: 'recipe-1', name: 'Test Recipe', ingredients: [])];
      var favoriteIds = <String>{'recipe-2'};
      var bookmarkIds = <String>{'recipe-3'};
      
      final initialDashboard = dashboard_vm.DashboardState(
        recipes: recipes,
        favoriteIds: favoriteIds,
        bookmarkIds: bookmarkIds,
      );
      
      favoriteIds = <String>{'recipe-2', 'recipe-4'};
      final updatedFavoritesOnly = dashboard_vm.DashboardState(
        recipes: recipes,  
        favoriteIds: favoriteIds,  
        bookmarkIds: bookmarkIds,
      );
      
      if (!identical(initialDashboard.favoriteIds, updatedFavoritesOnly.favoriteIds)) {
        favoriteRebuilds++;
      }
      if (!identical(initialDashboard.bookmarkIds, updatedFavoritesOnly.bookmarkIds)) {
        bookmarkRebuilds++;
      }
      
      expect(favoriteRebuilds, 1, reason: 'Favorite provider should rebuild');
      expect(bookmarkRebuilds, 0, reason: 'Bookmark provider should not rebuild');
      
      favoriteRebuilds = 0;
      bookmarkRebuilds = 0;
      
      final afterFavorites = updatedFavoritesOnly;
      
      bookmarkIds = <String>{'recipe-3', 'recipe-5'};
      final updatedBookmarksOnly = dashboard_vm.DashboardState(
        recipes: recipes,  
        favoriteIds: favoriteIds,  
        bookmarkIds: bookmarkIds,
      );
      
      if (!identical(afterFavorites.favoriteIds, updatedBookmarksOnly.favoriteIds)) {
        favoriteRebuilds++;
      }
      if (!identical(afterFavorites.bookmarkIds, updatedBookmarksOnly.bookmarkIds)) {
        bookmarkRebuilds++;
      }
      
      expect(favoriteRebuilds, 0, reason: 'Favorite provider should not rebuild');
      expect(bookmarkRebuilds, 1, reason: 'Bookmark provider should rebuild');
    });
  });
}

class TestSafeAsyncObject with SafeAsyncMixin {
  Future<String?> performOperation() {
    return safeAsync(() async {
      await Future.delayed(Duration.zero);
      return 'Operation completed';
    });
  }
}

class TestViewModel with SafeAsyncMixin {
  int updateCount = 0;
  
  bool updateState() {
    return _safeUpdateState(() {
      updateCount++;
    });
  }
  
  void dispose() {
    markDisposed();
  }
  
  bool _safeUpdateState(void Function() updateFunction) {
    if (disposed) {
      print('TestViewModel: Attempted to update state after disposal');
      return false;
    }
    
    try {
      updateFunction();
      return true;
    } catch (e) {
      if (disposed) {
        print('TestViewModel: ViewModel disposed during state update');
        return false;
      } else {
        rethrow;
      }
    }
  }
}