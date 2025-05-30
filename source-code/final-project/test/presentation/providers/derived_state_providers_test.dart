import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart' as recipes_vm;
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart' as dashboard_vm;

final testRecipeStateProvider = StateProvider<recipes_vm.RecipeState>((ref) {
  return const recipes_vm.RecipeState();
});

final testDashboardStateProvider = StateProvider<dashboard_vm.DashboardState>((ref) {
  return const dashboard_vm.DashboardState();
});

final testFilteredRecipesProvider = Provider<List<Recipe>>((ref) {
  final state = ref.watch(testRecipeStateProvider);
  return state.filteredRecipes;
});

final testFavoriteRecipesProvider = Provider<List<Recipe>>((ref) {
  final state = ref.watch(testRecipeStateProvider);
  return state.favoriteRecipes;
});

final testBookmarkedRecipesProvider = Provider<List<Recipe>>((ref) {
  final state = ref.watch(testRecipeStateProvider);
  return state.bookmarkedRecipes;
});

final testDashboardFavoriteRecipesProvider = Provider<List<Recipe>>((ref) {
  final state = ref.watch(testDashboardStateProvider);
  return state.favoriteRecipes;
});

final testDashboardBookmarkedRecipesProvider = Provider<List<Recipe>>((ref) {
  final state = ref.watch(testDashboardStateProvider);
  return state.bookmarkedRecipes;
});

void main() {
  group('Derived State Providers Test', () {
    late ProviderContainer container;

    test('filteredRecipesProvider correctly filters recipes by selected letter', () {
      final testRecipes = [
        const Recipe(id: '1', name: 'Apple Pie', ingredients: []),
        const Recipe(id: '2', name: 'Banana Bread', ingredients: []),
        const Recipe(id: '3', name: 'Carrot Cake', ingredients: []),
      ];
      
      container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(testRecipeStateProvider.notifier).state = recipes_vm.RecipeState(
        recipes: testRecipes,
        selectedLetter: 'B', 
      );
      
      final filtered = container.read(testFilteredRecipesProvider);
      
      expect(filtered.length, equals(1), reason: 'Should only include recipes starting with B');
      expect(filtered[0].name, equals('Banana Bread'), reason: 'Should show Banana Bread');
      
      container.read(testRecipeStateProvider.notifier).state = recipes_vm.RecipeState(
        recipes: testRecipes,
        selectedLetter: 'C',
      );
      
      final newFiltered = container.read(testFilteredRecipesProvider);
      
      expect(newFiltered.length, equals(1), reason: 'Should only include recipes starting with C');
      expect(newFiltered[0].name, equals('Carrot Cake'), reason: 'Should show Carrot Cake');
    });

    test('favoriteRecipesProvider from recipeProvider shows recipes marked as favorites', () {
      final testRecipes = [
        const Recipe(id: '1', name: 'Recipe 1', ingredients: [], isFavorite: true),
        const Recipe(id: '2', name: 'Recipe 2', ingredients: [], isFavorite: false),
        const Recipe(id: '3', name: 'Recipe 3', ingredients: [], isFavorite: true),
      ];
      
      container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(testRecipeStateProvider.notifier).state = recipes_vm.RecipeState(
        recipes: testRecipes,
        favoriteIds: {'1', '3'}, 
      );
      
      final favorites = container.read(testFavoriteRecipesProvider);
      
      expect(favorites.length, equals(2), reason: 'Should include only 2 favorite recipes');
      expect(favorites.map((r) => r.id).toList(), equals(['1', '3']), 
          reason: 'Should contain recipe IDs 1 and 3');
    });

    test('bookmarkedRecipesProvider from recipeProvider shows recipes that are bookmarked', () {
      final testRecipes = [
        const Recipe(id: '1', name: 'Recipe 1', ingredients: [], isBookmarked: false),
        const Recipe(id: '2', name: 'Recipe 2', ingredients: [], isBookmarked: true),
        const Recipe(id: '3', name: 'Recipe 3', ingredients: [], isBookmarked: true),
      ];
      
      container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(testRecipeStateProvider.notifier).state = recipes_vm.RecipeState(
        recipes: testRecipes,
        bookmarkIds: {'2', '3'},
      );
      
      final bookmarks = container.read(testBookmarkedRecipesProvider);
      
      expect(bookmarks.length, equals(2), reason: 'Should include only 2 bookmarked recipes');
      expect(bookmarks.map((r) => r.id).toList(), equals(['2', '3']), 
          reason: 'Should contain recipe IDs 2 and 3');
    });

    test('favoriteRecipesProvider from dashboardProvider shows recipes marked as favorites', () {
      final testRecipes = [
        const Recipe(id: '1', name: 'Recipe 1', ingredients: []),
        const Recipe(id: '2', name: 'Recipe 2', ingredients: []),
        const Recipe(id: '3', name: 'Recipe 3', ingredients: []),
      ];
      
      container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(testDashboardStateProvider.notifier).state = dashboard_vm.DashboardState(
        recipes: testRecipes,
        favoriteIds: {'1', '3'}, 
      );
      
      final favorites = container.read(testDashboardFavoriteRecipesProvider);
      
      expect(favorites.length, equals(2), reason: 'Should include only 2 favorite recipes');
      expect(favorites.map((r) => r.id).toList(), equals(['1', '3']), 
          reason: 'Should contain recipe IDs 1 and 3');
    });

    test('bookmarkedRecipesProvider from dashboardProvider shows recipes that are bookmarked', () {
      final testRecipes = [
        const Recipe(id: '1', name: 'Recipe 1', ingredients: []),
        const Recipe(id: '2', name: 'Recipe 2', ingredients: []),
        const Recipe(id: '3', name: 'Recipe 3', ingredients: []),
      ];
      
      container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(testDashboardStateProvider.notifier).state = dashboard_vm.DashboardState(
        recipes: testRecipes,
        bookmarkIds: {'2', '3'}, 
      );
      
      final bookmarks = container.read(testDashboardBookmarkedRecipesProvider);
      
      expect(bookmarks.length, equals(2), reason: 'Should include only 2 bookmarked recipes');
      expect(bookmarks.map((r) => r.id).toList(), equals(['2', '3']), 
          reason: 'Should contain recipe IDs 2 and 3');
    });

    test('filteredRecipesProvider handles null selected letter', () {
      final testRecipes = [
        const Recipe(id: '1', name: 'Apple Pie', ingredients: []),
        const Recipe(id: '2', name: 'Banana Bread', ingredients: []),
        const Recipe(id: '3', name: 'Carrot Cake', ingredients: []),
      ];
      
      container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(testRecipeStateProvider.notifier).state = recipes_vm.RecipeState(
        recipes: testRecipes,
        selectedLetter: null, 
      );
      
      final filtered = container.read(testFilteredRecipesProvider);
      
      expect(filtered.length, equals(3), reason: 'Should include all recipes when selectedLetter is null');
      expect(
        filtered.map((r) => r.name).toList(),
        equals(['Apple Pie', 'Banana Bread', 'Carrot Cake']),
        reason: 'Should contain all recipes in the original order'
      );
    });

    test('derived providers handle empty collections gracefully', () {
      container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(testRecipeStateProvider.notifier).state = const recipes_vm.RecipeState();
      container.read(testDashboardStateProvider.notifier).state = const dashboard_vm.DashboardState();
      
      final filteredRecipes = container.read(testFilteredRecipesProvider);
      final recipeFavorites = container.read(testFavoriteRecipesProvider);
      final recipeBookmarks = container.read(testBookmarkedRecipesProvider);
      final dashboardFavorites = container.read(testDashboardFavoriteRecipesProvider);
      final dashboardBookmarks = container.read(testDashboardBookmarkedRecipesProvider);
      
      expect(filteredRecipes, isEmpty, reason: 'filteredRecipesProvider should return empty list');
      expect(recipeFavorites, isEmpty, reason: 'favoriteRecipesProvider should return empty list');
      expect(recipeBookmarks, isEmpty, reason: 'bookmarkedRecipesProvider should return empty list');
      expect(dashboardFavorites, isEmpty, reason: 'dashboard favoriteRecipesProvider should return empty list');
      expect(dashboardBookmarks, isEmpty, reason: 'dashboard bookmarkedRecipesProvider should return empty list');
    });
  });
}