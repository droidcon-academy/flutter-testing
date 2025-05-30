import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart' hide favoriteRecipesProvider, bookmarkedRecipesProvider;
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';

class MockGetAllRecipes extends Mock implements GetAllRecipes {}
class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}
class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

class Listener<T> extends Mock {
  void call(T? previous, T next);
}

class FakeRecipeState extends Fake implements RecipeState {}
class FakeDashboardState extends Fake implements DashboardState {}
class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}
class FakeFavoriteRecipeParams extends Fake implements FavoriteRecipeParams {}
class FakeBookmarkRecipeParams extends Fake implements BookmarkRecipeParams {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockGetAllRecipes mockGetAllRecipes;
  late MockFavoriteRecipe mockFavoriteRecipe;
  late MockBookmarkRecipe mockBookmarkRecipe;
  
  setUpAll(() {
    registerFallbackValue(FakeRecipeState());
    registerFallbackValue(FakeDashboardState());
    registerFallbackValue(FakeGetAllRecipesParams());
    registerFallbackValue(FakeFavoriteRecipeParams());
    registerFallbackValue(FakeBookmarkRecipeParams());
  });
  
  setUp(() {
    mockGetAllRecipes = MockGetAllRecipes();
    mockFavoriteRecipe = MockFavoriteRecipe();
    mockBookmarkRecipe = MockBookmarkRecipe();
    
    when(() => mockGetAllRecipes(any()))
        .thenAnswer((_) async => const Right([Recipe(id: 'recipe-id', name: 'Test Recipe', ingredients: [])]));
        
    const favoriteRecipe = Recipe(id: 'recipe-id', name: 'Test Recipe', ingredients: [], isFavorite: true);
    when(() => mockFavoriteRecipe.getFavorites())
        .thenAnswer((_) async => const Right([favoriteRecipe]));
        
    when(() => mockBookmarkRecipe.getBookmarks())
        .thenAnswer((_) async => const Right([]));
        
    const unfavoritedRecipe = Recipe(id: 'recipe-id', name: 'Test Recipe', ingredients: [], isFavorite: false);
    when(() => mockFavoriteRecipe(any()))
        .thenAnswer((_) async => const Right(unfavoritedRecipe));
        
    when(() => mockFavoriteRecipe.getFavorites())
        .thenAnswer((_) async => const Right([]));
        
    when(() => mockBookmarkRecipe(any()))
        .thenAnswer((_) async => const Right(Recipe(id: 'recipe-id', name: 'Test Recipe', ingredients: [])));
  });
  
  group('Provider Propagation Tests', () {
    test('changes in recipeProvider propagate to dashboardProvider', () async {
      final container = ProviderContainer(
        overrides: [
          getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),
          favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
          bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),
        ],
      );
      
      final recipeListener = Listener<RecipeState>();
      final dashboardListener = Listener<DashboardState>();
      
      container.listen<RecipeState>(
        recipeProvider,
        (previous, next) {
          recipeListener(previous, next);
        },
        fireImmediately: true,
      );
      
      container.listen<DashboardState>(
        dashboardProvider,
        (previous, next) {
          dashboardListener(previous, next);
        },
        fireImmediately: true,
      );
      
      await container.pump();
      
      await Future.delayed(Duration.zero);
      await container.pump();
      
      reset(recipeListener);
      reset(dashboardListener);

      when(() => mockFavoriteRecipe.call(const FavoriteRecipeParams(recipeId: 'recipe-id')))
          .thenAnswer((_) async => const Right(Recipe(id: 'recipe-id', name: 'Test Recipe', ingredients: [], isFavorite: false)));
          
      await container.read(recipeProvider.notifier).toggleFavorite('recipe-id');

      await container.pump();
      await container.pump();
      
      verify(() => dashboardListener(any(), any())).called(greaterThan(0));
      
      final dashboardState = container.read(dashboardProvider);
      expect(dashboardState.favoriteIds.contains('recipe-id'), isFalse, reason: 'Recipe should be removed from favorites');
      
      container.dispose();
    });
    
    test('dashboard state updates trigger derived provider updates', () async {
      final container = ProviderContainer(
        overrides: [
          getAllRecipesProvider.overrideWithValue(mockGetAllRecipes),
          favoriteRecipeProvider.overrideWithValue(mockFavoriteRecipe),
          bookmarkRecipeProvider.overrideWithValue(mockBookmarkRecipe),
        ],
      );
      
      final favoritesListener = Listener<List<Recipe>>();
      container.listen<List<Recipe>>(
        favoriteRecipesProvider,
        (previous, next) {
          favoritesListener(previous, next);
        },
        fireImmediately: true,
      );
      
      await container.pump();
      
      await Future.delayed(Duration.zero);
      await container.pump();
      
      reset(favoritesListener);
      when(() => mockFavoriteRecipe.call(const FavoriteRecipeParams(recipeId: 'recipe-id')))
          .thenAnswer((_) async => const Right(Recipe(id: 'recipe-id', name: 'Test Recipe', ingredients: [], isFavorite: false)));
      
      await container.read(recipeProvider.notifier).toggleFavorite('recipe-id');

      await container.pump(); 
      await container.pump(); 
      
      verify(() => favoritesListener(any(), any())).called(greaterThan(0));
      
      final favoriteRecipes = container.read(favoriteRecipesProvider);
      expect(favoriteRecipes.length, equals(0), reason: 'Expected no favorite recipes after toggling');
      final hasMatchingRecipe = favoriteRecipes.any((recipe) => recipe.id == 'recipe-id');
      expect(hasMatchingRecipe, isFalse, reason: 'Recipe should be removed from favorites');
      
      container.dispose();
    });
  });
}
