import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}
class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}
class MockGetAllRecipes extends Mock implements GetAllRecipes {}
class MockProviderSubscription<T> extends Mock 
    implements ProviderSubscription<T> {}
class MockRecipeViewModel extends Mock implements RecipeViewModel {}

class FakeGetAllRecipesParams extends Fake implements GetAllRecipesParams {}

class MockRef extends Mock implements Ref {}

class ExtendedMockRef extends Mock implements Ref {
  final Map<ProviderListenable, Object?> _values = {};
  final Map<ProviderListenable, void Function(Object?, Object?)> _listeners = {};
  final Map<ProviderListenable, ProviderSubscription> _subscriptions = {};
  
  @override
  T read<T>(ProviderListenable<T> provider) {
    if (_values.containsKey(provider)) {
      return _values[provider] as T;
    }
    throw StateError('Provider $provider not mocked');
  }
  
  @override
  ProviderSubscription<T> listen<T>(
    ProviderListenable<T> provider,
    void Function(T?, T) listener, {
    void Function(Object, StackTrace)? onError,
    bool? fireImmediately,
  }) {
    _listeners[provider] = (prev, next) {
      listener(prev as T?, next as T);
    };
    
    final subscription = MockProviderSubscription<T>();
    _subscriptions[provider] = subscription;
    
    if (fireImmediately == true && _values.containsKey(provider)) {
      listener(null, _values[provider] as T);
    }
    
    return subscription;
  }
  
  void notifyListener<T>(ProviderListenable<T> provider, T newValue, {T? oldValue}) {
    if (!_listeners.containsKey(provider)) {
      throw StateError('No listener registered for $provider');
    }
    
    _values[provider] = newValue;
    _listeners[provider]!(oldValue, newValue);
  }
  
  void addMockedValue<T>(ProviderListenable<T> provider, T value) {
    _values[provider] = value;
  }
}

class TestHelper {
  static const String recipeCacheKey = 'recipe_cache';
  static const String favoritesCacheKey = 'favorites';
  static const String bookmarksCacheKey = 'bookmarks';
  static const String timestampKey = 'recipe_cache_timestamp';
  
  static List<Recipe> createTestRecipes(int count) {
    return List.generate(
      count,
      (index) => Recipe(
        id: 'recipe-$index',
        name: 'Recipe $index',
        instructions: 'Test instructions for recipe $index',
        ingredients: [
          const Ingredient(name: 'Ingredient 1', measure: '1 cup'),
          const Ingredient(name: 'Ingredient 2', measure: '2 tbsp'),
        ],
      ),
    );
  }
  
  static RecipeState createRecipeState({
    List<Recipe> recipes = const [],
    Set<String> favoriteIds = const {},
    Set<String> bookmarkIds = const {},
    bool isLoading = false,
    String? selectedLetter,
    String? error,
  }) {
    return RecipeState(
      recipes: recipes,
      favoriteIds: favoriteIds,
      bookmarkIds: bookmarkIds,
      isLoading: isLoading,
      selectedLetter: selectedLetter,
      error: error,
    );
  }
  
  static Future<void> setupCache({
    List<Recipe> recipes = const [],
    Set<String> favoriteIds = const {},
    Set<String> bookmarkIds = const {},
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (recipes.isNotEmpty) {
      final jsonList = recipes.map((recipe) => {
        'idMeal': recipe.id,
        'strMeal': recipe.name,
        'strInstructions': recipe.instructions,
        'strMealThumb': recipe.thumbnailUrl ?? '',
        'ingredients': recipe.ingredients
          .map((e) => ({'name': e.name, 'measure': e.measure}))
          .toList(),
      }).toList();
      
      await prefs.setString(recipeCacheKey, jsonEncode(jsonList));
      await prefs.setString(timestampKey, DateTime.now().toIso8601String());
    }
    
    if (favoriteIds.isNotEmpty) {
      await prefs.setString(
        favoritesCacheKey,
        jsonEncode(favoriteIds.toList())
      );
    }

    if (bookmarkIds.isNotEmpty) {
      await prefs.setString(
        bookmarksCacheKey,
        jsonEncode(bookmarkIds.toList())
      );
    }
  }
  
  static Future<Map<String, dynamic>> getCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final recipesJson = prefs.getString(recipeCacheKey);
    final List<Map<String, dynamic>> recipes = recipesJson != null 
        ? List<Map<String, dynamic>>.from(jsonDecode(recipesJson))
        : [];
    
    final favoritesJson = prefs.getString(favoritesCacheKey);
    final Set<String> favorites = favoritesJson != null
        ? Set<String>.from(jsonDecode(favoritesJson))
        : {};
    
    final bookmarksJson = prefs.getString(bookmarksCacheKey);
    final Set<String> bookmarks = bookmarksJson != null
        ? Set<String>.from(jsonDecode(bookmarksJson))
        : {};
    
    return {
      'recipes': recipes,
      'favoriteIds': favorites,
      'bookmarkIds': bookmarks,
    };
  }
  
  static Future<void> validateDataConsistency() async {
    final prefs = await SharedPreferences.getInstance();
    
    final recipesJson = prefs.getString(recipeCacheKey);
    if (recipesJson == null || recipesJson.isEmpty) {
      await prefs.setString(favoritesCacheKey, '[]');
      await prefs.setString(bookmarksCacheKey, '[]');
      return;
    }
    
    final recipes = List<Map<String, dynamic>>.from(jsonDecode(recipesJson));
    if (recipes.isEmpty) {
      await prefs.setString(favoritesCacheKey, '[]');
      await prefs.setString(bookmarksCacheKey, '[]');
      return;
    }
    
    final recipeIds = recipes.map((r) => r['idMeal'] as String).toSet();
    
    final favoritesJson = prefs.getString(favoritesCacheKey);
    if (favoritesJson != null) {
      final favoriteIds = Set<String>.from(jsonDecode(favoritesJson));
      final validFavorites = favoriteIds.where((id) => recipeIds.contains(id)).toSet();
      
      if (validFavorites.length != favoriteIds.length) {
        await prefs.setString(favoritesCacheKey, jsonEncode(validFavorites.toList()));
      }
    }
    
    final bookmarksJson = prefs.getString(bookmarksCacheKey);
    if (bookmarksJson != null) {
      final bookmarkIds = Set<String>.from(jsonDecode(bookmarksJson));
      final validBookmarks = bookmarkIds.where((id) => recipeIds.contains(id)).toSet();
      
      if (validBookmarks.length != bookmarkIds.length) {
        await prefs.setString(bookmarksCacheKey, jsonEncode(validBookmarks.toList()));
      }
    }
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });
  
  group('Data Consistency Validation', () {
    test('validates favorites reference valid recipes only', () async {
      final recipes = TestHelper.createTestRecipes(3); 
      
      await TestHelper.setupCache(
        recipes: recipes,
        favoriteIds: {'recipe-0', 'recipe-1', 'invalid-id'}, 
      );
      
      await TestHelper.validateDataConsistency();
      
      final cachedData = await TestHelper.getCachedData();
      final cachedFavorites = cachedData['favoriteIds'] as Set<String>;
      
      expect(cachedFavorites, hasLength(2));
      expect(cachedFavorites, contains('recipe-0'));
      expect(cachedFavorites, contains('recipe-1'));
      expect(cachedFavorites, isNot(contains('invalid-id')));
    });
    
    test('validates bookmarks reference valid recipes only', () async {
      final recipes = TestHelper.createTestRecipes(3);
      
      await TestHelper.setupCache(
        recipes: recipes,
        bookmarkIds: {'recipe-0', 'non-existent'}, 
      );
      
      await TestHelper.validateDataConsistency();
      
      final cachedData = await TestHelper.getCachedData();
      final cachedBookmarks = cachedData['bookmarkIds'] as Set<String>;
      
      expect(cachedBookmarks, hasLength(1));
      expect(cachedBookmarks, contains('recipe-0'));
      expect(cachedBookmarks, isNot(contains('non-existent')));
    });
    
    test('handles empty recipe list gracefully', () async {
      await TestHelper.setupCache(
        recipes: [], 
        favoriteIds: {'id1', 'id2'}, 
        bookmarkIds: {'id3', 'id4'}, 
      );
      
      await TestHelper.validateDataConsistency();
      
      final cachedData = await TestHelper.getCachedData();
      final cachedFavorites = cachedData['favoriteIds'] as Set<String>;
      final cachedBookmarks = cachedData['bookmarkIds'] as Set<String>;
      
      expect(cachedFavorites, isEmpty);
      expect(cachedBookmarks, isEmpty);
    });
  });
  
  group('Recipe Updates Impact on Favorites/Bookmarks', () {
    test('removes favorites for recipes that no longer exist', () async {
      final initialRecipes = TestHelper.createTestRecipes(3); 
      await TestHelper.setupCache(
        recipes: initialRecipes,
        favoriteIds: {'recipe-0', 'recipe-2'}, 
      );
      
      final updatedRecipes = [
        initialRecipes[0], 
        initialRecipes[1], 
        Recipe(id: 'recipe-3', name: 'New Recipe', instructions: 'New', ingredients: []),
      ];
      await TestHelper.setupCache(recipes: updatedRecipes);
      
      await TestHelper.validateDataConsistency();
      
      final cachedData = await TestHelper.getCachedData();
      final cachedFavorites = cachedData['favoriteIds'] as Set<String>;
      
      expect(cachedFavorites, hasLength(1));
      expect(cachedFavorites, contains('recipe-0'));
      expect(cachedFavorites, isNot(contains('recipe-2')));
    });
    
    test('removes bookmarks for recipes that no longer exist', () async {
      final initialRecipes = TestHelper.createTestRecipes(3); 
      await TestHelper.setupCache(
        recipes: initialRecipes,
        bookmarkIds: {'recipe-1', 'recipe-2'}, 
      );
      
      final updatedRecipes = [
        initialRecipes[0], 
        initialRecipes[1], 
        Recipe(id: 'recipe-3', name: 'New Recipe', instructions: 'New', ingredients: []),
      ];
      await TestHelper.setupCache(recipes: updatedRecipes);
      
      await TestHelper.validateDataConsistency();
      
      final cachedData = await TestHelper.getCachedData();
      final cachedBookmarks = cachedData['bookmarkIds'] as Set<String>;
      
      expect(cachedBookmarks, hasLength(1));
      expect(cachedBookmarks, contains('recipe-1'));
      expect(cachedBookmarks, isNot(contains('recipe-2')));
    });
  });
  
  group('Complex Scenarios', () {
    test('handles multiple operations while maintaining consistency', () async {
      final recipes = TestHelper.createTestRecipes(5); 
      await TestHelper.setupCache(
        recipes: recipes,
        favoriteIds: {'recipe-0', 'recipe-1'}, 
        bookmarkIds: {'recipe-2', 'recipe-3'}, 
      );
      
      await TestHelper.setupCache(
        favoriteIds: {'recipe-0', 'recipe-1', 'invalid-1', 'invalid-2'},
      );
      await TestHelper.validateDataConsistency();
      
      final updatedRecipes = recipes.where((r) => r.id != 'recipe-1').toList();
      await TestHelper.setupCache(recipes: updatedRecipes);
      await TestHelper.validateDataConsistency();
      
      await TestHelper.setupCache(
        bookmarkIds: {'recipe-2', 'recipe-3', 'recipe-4'},
      );
      await TestHelper.validateDataConsistency();
      
      final cachedData = await TestHelper.getCachedData();
      final cachedFavorites = cachedData['favoriteIds'] as Set<String>;
      final cachedBookmarks = cachedData['bookmarkIds'] as Set<String>;
      
      expect(cachedFavorites, hasLength(1));
      expect(cachedFavorites, contains('recipe-0'));
      expect(cachedFavorites, isNot(contains('recipe-1'))); 
      expect(cachedFavorites, isNot(contains('invalid-1')));
      
      expect(cachedBookmarks, hasLength(3));
      expect(cachedBookmarks, contains('recipe-2'));
      expect(cachedBookmarks, contains('recipe-3'));
      expect(cachedBookmarks, contains('recipe-4'));
    });
    
    test('preserves valid references when some references are invalid', () async {
      final recipes = TestHelper.createTestRecipes(3);
      await TestHelper.setupCache(
        recipes: recipes,
        favoriteIds: {'recipe-0', 'invalid-1', 'recipe-2', 'invalid-2'},
        bookmarkIds: {'invalid-3', 'recipe-1', 'invalid-4'},
      );
      
      await TestHelper.validateDataConsistency();
      
      final cachedData = await TestHelper.getCachedData();
      final cachedFavorites = cachedData['favoriteIds'] as Set<String>;
      final cachedBookmarks = cachedData['bookmarkIds'] as Set<String>;
      
      expect(cachedFavorites, hasLength(2));
      expect(cachedFavorites, contains('recipe-0'));
      expect(cachedFavorites, contains('recipe-2'));
      expect(cachedFavorites, isNot(contains('invalid-1')));
      expect(cachedFavorites, isNot(contains('invalid-2')));
      
      expect(cachedBookmarks, hasLength(1));
      expect(cachedBookmarks, contains('recipe-1'));
      expect(cachedBookmarks, isNot(contains('invalid-3')));
      expect(cachedBookmarks, isNot(contains('invalid-4')));
    });
  });
  
  group('Toggling and Operation Order', () {
    test('maintains data consistency when toggling favorites and bookmarks', () async {
      final recipes = TestHelper.createTestRecipes(1);
      SharedPreferences.setMockInitialValues({});
      await TestHelper.setupCache(
        recipes: recipes,
        favoriteIds: {},
        bookmarkIds: {},
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        TestHelper.favoritesCacheKey, 
        jsonEncode(['recipe-0'])
      );
      await TestHelper.validateDataConsistency();
      
      await prefs.setString(
        TestHelper.bookmarksCacheKey, 
        jsonEncode(['recipe-0'])
      );
      await TestHelper.validateDataConsistency();
      
      final data1 = await TestHelper.getCachedData();
      expect(data1['favoriteIds'], contains('recipe-0'));
      expect(data1['bookmarkIds'], contains('recipe-0'));
      
      await prefs.setString(TestHelper.bookmarksCacheKey, jsonEncode([]));
      await TestHelper.validateDataConsistency();
      
      await prefs.setString(TestHelper.favoritesCacheKey, jsonEncode([]));
      await TestHelper.validateDataConsistency();
      
      final data2 = await TestHelper.getCachedData();
      expect(data2['favoriteIds'], isEmpty);
      expect(data2['bookmarkIds'], isEmpty);
    });
    
    test('produces same result regardless of operation order', () async {
      final recipes = TestHelper.createTestRecipes(2);
      
      SharedPreferences.setMockInitialValues({});
      await TestHelper.setupCache(recipes: recipes);
      
      final prefsA = await SharedPreferences.getInstance();
      await prefsA.setString(TestHelper.favoritesCacheKey, jsonEncode(['recipe-0']));
      await TestHelper.validateDataConsistency();
      await prefsA.setString(TestHelper.bookmarksCacheKey, jsonEncode(['recipe-1']));
      await TestHelper.validateDataConsistency();
      final resultA = await TestHelper.getCachedData();
      
      SharedPreferences.setMockInitialValues({});
      await TestHelper.setupCache(recipes: recipes);
      
      final prefsB = await SharedPreferences.getInstance();
      await prefsB.setString(TestHelper.bookmarksCacheKey, jsonEncode(['recipe-1']));
      await TestHelper.validateDataConsistency();
      await prefsB.setString(TestHelper.favoritesCacheKey, jsonEncode(['recipe-0']));
      await TestHelper.validateDataConsistency();
      final resultB = await TestHelper.getCachedData();

      expect(resultA['favoriteIds'], equals(resultB['favoriteIds']));
      expect(resultA['bookmarkIds'], equals(resultB['bookmarkIds']));
    });
  });
  
  group('Race Conditions and Concurrency', () {
    test('handles race conditions in updates', () async {
      SharedPreferences.setMockInitialValues({});
      final recipes = TestHelper.createTestRecipes(5);
      await TestHelper.setupCache(recipes: recipes);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(TestHelper.favoritesCacheKey, jsonEncode(['recipe-0']));
      await prefs.setString(TestHelper.bookmarksCacheKey, jsonEncode(['recipe-1']));
      
      final future1 = () async {
        await prefs.setString(TestHelper.favoritesCacheKey, 
          jsonEncode(['recipe-0', 'recipe-2']));
      }();
      
      final future2 = () async {
        await prefs.setString(TestHelper.bookmarksCacheKey, 
          jsonEncode(['recipe-1', 'recipe-3']));
      }();
      
      await Future.wait([future1, future2]);
      
      await TestHelper.validateDataConsistency();
      
      final finalData = await TestHelper.getCachedData();
      expect(finalData['favoriteIds'], containsAll(['recipe-0', 'recipe-2']));
      expect(finalData['bookmarkIds'], containsAll(['recipe-1', 'recipe-3']));
    });
    
    test('maintains consistency during concurrent operations with failures', () async {
      SharedPreferences.setMockInitialValues({});
      final recipes = TestHelper.createTestRecipes(3);
      await TestHelper.setupCache(recipes: recipes);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(TestHelper.favoritesCacheKey, jsonEncode(['recipe-0']));
      await prefs.setString(TestHelper.bookmarksCacheKey, jsonEncode(['recipe-1']));
      
      final favOp = () async {
        await prefs.setString(TestHelper.favoritesCacheKey, 
          jsonEncode(['recipe-0', 'recipe-2', 'invalid-id']));
      }();
      
      final removeOp = () async {
        await Future.delayed(const Duration(milliseconds: 5));
        final updatedRecipes = recipes.where((r) => r.id != 'recipe-0').toList();
        await TestHelper.setupCache(recipes: updatedRecipes);
      }();
      
      await Future.wait([favOp, removeOp]);
      
      await TestHelper.validateDataConsistency();
      
      final finalData = await TestHelper.getCachedData();
      
      final finalFavorites = finalData['favoriteIds'] as Set<String>;
      expect(finalFavorites, isNot(contains('recipe-0')));
      expect(finalFavorites, contains('recipe-2'));
      expect(finalFavorites, isNot(contains('invalid-id')));
    });
  });
}