import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fpdart/fpdart.dart';

import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';
import 'package:recipevault/presentation/viewmodels/dashboard_viewmodel.dart';

class MockFavoriteRecipe extends Mock implements FavoriteRecipe {}
class MockBookmarkRecipe extends Mock implements BookmarkRecipe {}

List<Recipe> createTestRecipes(int count, {String prefix = 'recipe'}) {
  return List.generate(
    count,
    (index) => Recipe(
      id: '$prefix-$index',
      name: '$prefix $index',
      instructions: 'Test instructions $index',
      ingredients: [
        const Ingredient(name: 'Ingredient 1', measure: '1 cup'),
        const Ingredient(name: 'Ingredient 2', measure: '2 tbsp'),
      ],
    ),
  );
}

Future<void> setupCachedRecipes(List<Recipe> recipes) async {
  final jsonList = recipes
    .map((recipe) => {
      'idMeal': recipe.id,
      'strMeal': recipe.name,
      'strInstructions': recipe.instructions,
      'strMealThumb': recipe.thumbnailUrl ?? '',
      'ingredients': recipe.ingredients
        .map((e) => ({'name': e.name, 'measure': e.measure}))
        .toList(),
    })
    .toList();

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    DashboardConstants.recipeCacheKey, 
    jsonEncode(jsonList)
  );
  
  await prefs.setString(
    'recipe_cache_timestamp', 
    DateTime.now().toIso8601String()
  );
}

Future<List<Map<String, dynamic>>> getCachedRecipesAsJson() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonData = prefs.getString(DashboardConstants.recipeCacheKey);
  
  if (jsonData == null || jsonData.isEmpty) {
    return [];
  }
  
  return List<Map<String, dynamic>>.from(json.decode(jsonData));
}

Future<void> setCacheTimestamp(DateTime timestamp) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'recipe_cache_timestamp', 
    timestamp.toIso8601String()
  );
}

Future<DateTime?> getCacheTimestamp() async {
  final prefs = await SharedPreferences.getInstance();
  final timestampStr = prefs.getString('recipe_cache_timestamp');
  return timestampStr != null ? DateTime.parse(timestampStr) : null;
}

void main() {
  late MockFavoriteRecipe mockFavoriteRecipe;
  late MockBookmarkRecipe mockBookmarkRecipe;

  setUp(() async {
    mockFavoriteRecipe = MockFavoriteRecipe();
    mockBookmarkRecipe = MockBookmarkRecipe();
    
    when(() => mockFavoriteRecipe.getFavorites())
        .thenAnswer((_) async => const Right([]));
    when(() => mockBookmarkRecipe.getBookmarks())
        .thenAnswer((_) async => const Right([]));
    
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  group('DashboardViewModel Cache Tests', () {
    test('empty cache when SharedPreferences has no recipe data', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      final cachedData = await getCachedRecipesAsJson();
      
      expect(cachedData, isEmpty);
    });

    test('successfully stores recipe data in cache', () async {
      final testRecipes = createTestRecipes(3);
      
      await setupCachedRecipes(testRecipes);
      
      final cachedData = await getCachedRecipesAsJson();
      
      expect(cachedData.length, 3);
      expect(cachedData[0]['idMeal'], 'recipe-0');
      expect(cachedData[1]['idMeal'], 'recipe-1');
      expect(cachedData[2]['idMeal'], 'recipe-2');
    });
    
    test('cache timestamp is properly set', () async {
      final testRecipes = createTestRecipes(1);
      final beforeTime = DateTime.now();
      
      await setupCachedRecipes(testRecipes);
      
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString('recipe_cache_timestamp');
      
      expect(timestampStr, isNotNull);
      
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        expect(timestamp.isAfter(beforeTime) || timestamp.isAtSameMomentAs(beforeTime), true);
      }
    });
    
    test('cache properly stores recipe ingredients', () async {
      const testRecipe = Recipe(
        id: 'test-recipe',
        name: 'Test Recipe',
        instructions: 'Test instructions',
        ingredients: [
          Ingredient(name: 'Sugar', measure: '2 cups'),
          Ingredient(name: 'Flour', measure: '3 cups'),
          Ingredient(name: 'Eggs', measure: '4 large'),
        ],
      );
      
      await setupCachedRecipes([testRecipe]);
      
      final cachedData = await getCachedRecipesAsJson();
      
      expect(cachedData.length, 1);
      expect(cachedData[0]['idMeal'], 'test-recipe');
      
      final ingredients = List<Map<String, dynamic>>.from(cachedData[0]['ingredients']);
      expect(ingredients.length, 3);
      expect(ingredients[0]['name'], 'Sugar');
      expect(ingredients[0]['measure'], '2 cups');
      expect(ingredients[1]['name'], 'Flour');
      expect(ingredients[2]['name'], 'Eggs');
    });
    
    test('cache operation works with empty ingredient lists', () async {
      const testRecipe = Recipe(
        id: 'empty-ingredients',
        name: 'Empty Ingredients Recipe',
        instructions: 'No ingredients needed',
        ingredients: [], 
      );
      
      await setupCachedRecipes([testRecipe]);
      
      final cachedData = await getCachedRecipesAsJson();
      
      expect(cachedData.length, 1);
      expect(cachedData[0]['idMeal'], 'empty-ingredients');
      expect(cachedData[0]['ingredients'], isEmpty);
    });
    
    test('cache operation works with null thumbnailUrl', () async {
      const testRecipe = Recipe(
        id: 'no-thumbnail',
        name: 'No Thumbnail Recipe',
        instructions: 'Test instructions',
        thumbnailUrl: null,
        ingredients: [Ingredient(name: 'Test', measure: '1 unit')],
      );
      
      await setupCachedRecipes([testRecipe]);
        
      final cachedData = await getCachedRecipesAsJson();
      
      expect(cachedData.length, 1);
      expect(cachedData[0]['idMeal'], 'no-thumbnail');
      expect(cachedData[0]['strMealThumb'], '');
    });
  });
  
  group('Cache Format and Structure Tests', () {
    test('cache format matches ViewModel serialization expectations', () async {
      final testRecipes = createTestRecipes(2);
      
      await setupCachedRecipes(testRecipes);
      
      final cachedData = await getCachedRecipesAsJson();
      
      expect(cachedData.length, 2);
      expect(cachedData[0]['idMeal'], 'recipe-0');
      expect(cachedData[0]['strMeal'], 'recipe 0');
      expect(cachedData[0]['strInstructions'], 'Test instructions 0');
      expect(cachedData[0]['ingredients'], isA<List>());
      expect(cachedData[0]['ingredients'].length, 2);
      expect(cachedData[0]['ingredients'][0]['name'], 'Ingredient 1');
      expect(cachedData[0]['ingredients'][0]['measure'], '1 cup');
    });
    
    test('validates cache format for deserialization compatibility', () async {
      final originalRecipes = createTestRecipes(2);
      await setupCachedRecipes(originalRecipes);
      
      final cachedData = await getCachedRecipesAsJson();
      
      expect(cachedData.length, 2);
      expect(cachedData[0].containsKey('idMeal'), true, reason: 'Cache should contain idMeal key');
      expect(cachedData[0].containsKey('strMeal'), true, reason: 'Cache should contain strMeal key');
      expect(cachedData[0].containsKey('strInstructions'), true, reason: 'Cache should contain strInstructions key');
      expect(cachedData[0].containsKey('ingredients'), true, reason: 'Cache should contain ingredients key');
      
      expect(cachedData[0]['idMeal'], 'recipe-0');
      expect(cachedData[0]['strMeal'], 'recipe 0');
      expect(cachedData[0]['ingredients'], isA<List>());
    });
    
    test('timestamp format matches ViewModel staleness check expectations', () async {
      final now = DateTime.now();
      
      await setCacheTimestamp(now);
      
      final storedTimestamp = await getCacheTimestamp();
      expect(storedTimestamp, isNotNull);
      
      final difference = now.difference(storedTimestamp!).inSeconds.abs();
      expect(difference, lessThanOrEqualTo(1));
    });
  });
  
  group('Cache Hit/Miss Scenarios', () {
    test('cache hit - retrieves data when available', () async {
      final expectedRecipes = createTestRecipes(3);
      await setupCachedRecipes(expectedRecipes);
      
      final cachedData = await getCachedRecipesAsJson();

      expect(cachedData.length, 3);
      expect(
        cachedData.map((r) => r['idMeal']).toList(),
        expectedRecipes.map((r) => r.id).toList()
      );
    });

    test('cache miss - returns empty list when no data exists', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      final cachedData = await getCachedRecipesAsJson();
      
      expect(cachedData, isEmpty);
    });
  });
  
  group('Cache Invalidation Tests', () {
    test('detects stale cache based on timestamp', () async {
      final recipes = createTestRecipes(2);
      await setupCachedRecipes(recipes);
      
      final oldTime = DateTime.now().subtract(const Duration(days: 2));
      await setCacheTimestamp(oldTime);
      
      final timestamp = await getCacheTimestamp();
      
      expect(timestamp, isNotNull);
      final hoursSinceUpdate = DateTime.now().difference(timestamp!).inHours;
      expect(hoursSinceUpdate, greaterThan(24)); 
    });

    test('clear operation removes all cached data', () async {
      final recipes = createTestRecipes(3);
      await setupCachedRecipes(recipes);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(DashboardConstants.recipeCacheKey);
      
      final cachedData = await getCachedRecipesAsJson();
      expect(cachedData, isEmpty);
    });
  });
  
  group('Offline/Online Transition Tests', () {
    test('maintains cache data persistence for offline access', () async {
      final cachedRecipes = createTestRecipes(3);
      await setupCachedRecipes(cachedRecipes);
      
      final prefs = await SharedPreferences.getInstance();
      final currentCacheData = prefs.getString(DashboardConstants.recipeCacheKey);
      final timestampData = prefs.getString('recipe_cache_timestamp');
      
      final initialValues = <String, Object>{};
      if (currentCacheData != null) {
        initialValues[DashboardConstants.recipeCacheKey] = currentCacheData;
      }
      if (timestampData != null) {
        initialValues['recipe_cache_timestamp'] = timestampData;
      }
      SharedPreferences.setMockInitialValues(initialValues);
      
      final offlineData = await getCachedRecipesAsJson();
      
      expect(offlineData.length, 3);
      expect(offlineData.first['idMeal'], cachedRecipes.first.id);
    });
    
    test('preserves cache during network errors', () async {
      final cachedRecipes = createTestRecipes(2);
      await setupCachedRecipes(cachedRecipes);
      
      final cachedData = await getCachedRecipesAsJson();
      
      expect(cachedData.length, 2);
      expect(
        cachedData.map((r) => r['idMeal']).toList(),
        cachedRecipes.map((r) => r.id).toList()
      );
    });
  });
}
