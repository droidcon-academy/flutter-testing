import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late LocalDataSource localDataSource;
  late MockSharedPreferences mockPrefs;

  final testRecipe = {
    'idMeal': '12345',
    'strMeal': 'Test Recipe',
    'strIngredient1': 'Test Ingredient',
    'strMeasure1': '1 cup',
    'strInstructions': 'Test instructions',
    'strMealThumb': 'https://example.com/image.jpg',
  };

  final testRecipesList = [
    {'idMeal': '1', 'strMeal': 'Recipe 1'},
    {'idMeal': '2', 'strMeal': 'Recipe 2'},
  ];

  //final corruptedJson = '{\'invalid json';

  setUp(() {
    mockPrefs = MockSharedPreferences();
    localDataSource = LocalDataSource(mockPrefs);
  });

  void setUpFavorites(List<String> favorites) {
    when(() => mockPrefs.getString(PreferenceKeys.favorites))
        .thenReturn(json.encode(favorites));
  }

  void setUpBookmarks(List<String> bookmarks) {
    when(() => mockPrefs.getString(PreferenceKeys.bookmarks))
        .thenReturn(json.encode(bookmarks));
  }

  void setUpRecipeCache(String letter, List<Map<String, dynamic>> recipes, DateTime timestamp) {
    final cacheKey = '${PreferenceKeys.recipeCache}_$letter';
    final timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_$letter';
    
    when(() => mockPrefs.getString(cacheKey)).thenReturn(json.encode(recipes));
    when(() => mockPrefs.getInt(timestampKey)).thenReturn(timestamp.millisecondsSinceEpoch);
  }

  void setUpRecipeDetailCache(String recipeId, Map<String, dynamic> recipe, DateTime timestamp) {
    final cacheKey = '${PreferenceKeys.recipeDetail}_$recipeId';
    final timestampKey = '${PreferenceKeys.recipeDetailTimestamp}_$recipeId';
    
    when(() => mockPrefs.getString(cacheKey)).thenReturn(json.encode(recipe));
    when(() => mockPrefs.getInt(timestampKey)).thenReturn(timestamp.millisecondsSinceEpoch);
  }

  group('Shared Preferences Operations', () {
    test('should add recipe to favorites correctly', () async {
      setUpFavorites([]);
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

      await localDataSource.addFavorite('12345');

      verify(() => mockPrefs.setString(
        PreferenceKeys.favorites,
        json.encode(['12345']),
      ));
    });

    test('should not add duplicate recipe to favorites', () async {
      setUpFavorites(['12345']);
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

      await localDataSource.addFavorite('12345');

      verifyNever(() => mockPrefs.setString(any(), any()));
    });

    test('should remove recipe from favorites correctly', () async {
      setUpFavorites(['12345', '67890']);
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

      await localDataSource.removeFavorite('12345');

      verify(() => mockPrefs.setString(
        PreferenceKeys.favorites,
        json.encode(['67890']),
      ));
    });

    test('should retrieve favorite IDs correctly', () async {
      setUpFavorites(['12345', '67890']);

      final result = await localDataSource.getFavoriteIds();

      expect(result, ['12345', '67890']);
    });

    test('should check if recipe is favorite correctly', () async {
      setUpFavorites(['12345', '67890']);

      final isFavorite1 = await localDataSource.isFavorite('12345');
      final isFavorite2 = await localDataSource.isFavorite('11111');

      expect(isFavorite1, true);
      expect(isFavorite2, false);
    });

    test('should add recipe to bookmarks correctly', () async {
      setUpBookmarks([]);
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

      await localDataSource.addBookmark('12345');
      verify(() => mockPrefs.setString(
        PreferenceKeys.bookmarks,
        json.encode(['12345']),
      ));
    });

    test('should remove recipe from bookmarks correctly', () async {
      setUpBookmarks(['12345', '67890']);
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

      await localDataSource.removeBookmark('12345');
      verify(() => mockPrefs.setString(
        PreferenceKeys.bookmarks,
        json.encode(['67890']),
      ));
    });

    test('should retrieve bookmark IDs correctly', () async {
      setUpBookmarks(['12345', '67890']);

      final result = await localDataSource.getBookmarkIds();

      expect(result, ['12345', '67890']);
    });

    test('should check if recipe is bookmarked correctly', () async {
      setUpBookmarks(['12345', '67890']);

      final isBookmarked1 = await localDataSource.isBookmarked('12345');
      final isBookmarked2 = await localDataSource.isBookmarked('11111');

      expect(isBookmarked1, true);
      expect(isBookmarked2, false);
    });
  });

  group('Caching Logic and Effectiveness', () {
    test('should cache recipe correctly', () async {
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);

      await localDataSource.cacheRecipe(testRecipe);
      verify(() => mockPrefs.setString(
        '${PreferenceKeys.recipeDetail}_12345',
        json.encode(testRecipe),
      ));
      verify(() => mockPrefs.setInt(
        '${PreferenceKeys.recipeDetailTimestamp}_12345',
        any(),
      ));
    });

    test('should retrieve cached recipe correctly', () async {
      final now = DateTime.now();
      setUpRecipeDetailCache('12345', testRecipe, now);

      final result = await localDataSource.getCachedRecipe('12345');
      final expectedResult = Map<String, dynamic>.from(testRecipe);
      expectedResult['id'] = '12345';
      expect(result, expectedResult);
    });

    test('should return null for non-existent cached recipe', () async {
      when(() => mockPrefs.getString(any())).thenReturn(null);

      final result = await localDataSource.getCachedRecipe('99999');
      expect(result, null);
    });

    test('should cache recipes by letter correctly', () async {
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.getKeys()).thenReturn({});
      when(() => mockPrefs.getString(any())).thenReturn(null);
      await localDataSource.cacheRecipesByLetter('A', testRecipesList);

      final expectedProcessedRecipes = testRecipesList.map((recipe) {
        final processed = Map<String, dynamic>.from(recipe);
        processed['id'] = processed['idMeal'].toString();
        return processed;
      }).toList();
      
      verify(() => mockPrefs.setString(
        '${PreferenceKeys.recipeCache}_A',
        json.encode(expectedProcessedRecipes),
      ));
      verify(() => mockPrefs.setInt(
        '${PreferenceKeys.recipeCacheTimestamp}_A',
        any(),
      ));
    });

    test('should retrieve recipes by letter correctly', () async {
      final now = DateTime.now();
      const cacheKey = '${PreferenceKeys.recipeCache}_A';
      const timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_A';
      
      when(() => mockPrefs.getString(cacheKey))
          .thenReturn(json.encode(testRecipesList));
      
      when(() => mockPrefs.get(timestampKey))
          .thenReturn(now.millisecondsSinceEpoch);

      final result = await localDataSource.getCachedRecipesByLetter('A');
      final expectedProcessedRecipes = testRecipesList.map((recipe) {
        final processed = Map<String, dynamic>.from(recipe);
        processed['id'] = processed['idMeal'].toString();
        return processed;
      }).toList();
      
      expect(result, expectedProcessedRecipes);
    });
  });

  group('Cache Invalidation and Refresh Strategies', () {
    test('should not return expired cache items', () async {
      final expiredTime = DateTime.now().subtract(LocalDataSource.cacheDuration * 2);
      setUpRecipeCache('A', testRecipesList, expiredTime);

      final result = await localDataSource.getCachedRecipesByLetter('A');
      expect(result, null);
    });

    test('should clean expired cache entries', () async {
      final expiredTime = DateTime.now().subtract(LocalDataSource.cacheDuration * 2);
      final freshTime = DateTime.now();
      
      when(() => mockPrefs.getKeys()).thenReturn(
        {'${PreferenceKeys.recipeCache}_A', '${PreferenceKeys.recipeCacheTimestamp}_A',
         '${PreferenceKeys.recipeCache}_B', '${PreferenceKeys.recipeCacheTimestamp}_B'}
      );
      
      when(() => mockPrefs.get('${PreferenceKeys.recipeCacheTimestamp}_A'))
          .thenReturn(expiredTime.millisecondsSinceEpoch);
      when(() => mockPrefs.get('${PreferenceKeys.recipeCacheTimestamp}_B'))
          .thenReturn(freshTime.millisecondsSinceEpoch);
      when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

      await localDataSource.cleanExpiredCache();

      verify(() => mockPrefs.remove('${PreferenceKeys.recipeCache}_A')).called(1);
      verify(() => mockPrefs.remove('${PreferenceKeys.recipeCacheTimestamp}_A')).called(1);
      verifyNever(() => mockPrefs.remove('${PreferenceKeys.recipeCache}_B'));
      verifyNever(() => mockPrefs.remove('${PreferenceKeys.recipeCacheTimestamp}_B'));
    });
    
    test('should clear specific letter cache', () async {
      when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);
      
      await localDataSource.clearLetterCache('A');
      
      verify(() => mockPrefs.remove('${PreferenceKeys.recipeCache}_A')).called(1);
      verify(() => mockPrefs.remove('${PreferenceKeys.recipeCacheTimestamp}_A')).called(1);
    });
    
    test('should clear all cache', () async {
      when(() => mockPrefs.getKeys()).thenReturn(
        {'${PreferenceKeys.recipeCache}_A', '${PreferenceKeys.recipeCacheTimestamp}_A',
         '${PreferenceKeys.recipeCache}_B', '${PreferenceKeys.recipeCacheTimestamp}_B'}
      );
      when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);
      
      await localDataSource.clearAllCache();
      
      verify(() => mockPrefs.remove('${PreferenceKeys.recipeCache}_A')).called(1);
      verify(() => mockPrefs.remove('${PreferenceKeys.recipeCache}_B')).called(1);
    });
  });

  group('Cache Capacity Management', () {
    test('should calculate cache size correctly', () async {
      when(() => mockPrefs.getKeys()).thenReturn(
        {'${PreferenceKeys.recipeCache}_A', '${PreferenceKeys.recipeCache}_B'}
      );
      when(() => mockPrefs.getString('${PreferenceKeys.recipeCache}_A'))
          .thenReturn('A'.padRight(1000, 'A')); 
      when(() => mockPrefs.getString('${PreferenceKeys.recipeCache}_B'))
          .thenReturn('B'.padRight(2000, 'B')); 
      
      final size = await localDataSource.getCacheSize();
      
      expect(size, 3000); 
    });
    
    test('should clean cache when size exceeds limit', () async {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      
      final removedKeys = <String>[];
      var removedA = false;
      var removedB = false;
      
      reset(mockPrefs);
      
      when(() => mockPrefs.getKeys()).thenAnswer((_) {
        final keys = <String>{};
        
        if (!removedA) {
          keys.add('${PreferenceKeys.recipeCache}_A');
          keys.add('${PreferenceKeys.recipeCacheTimestamp}_A');
        }
        if (!removedB) {
          keys.add('${PreferenceKeys.recipeCache}_B');
          keys.add('${PreferenceKeys.recipeCacheTimestamp}_B');
        }
        keys.add('${PreferenceKeys.recipeCache}_C');
        keys.add('${PreferenceKeys.recipeCacheTimestamp}_C');
        
        return keys;
      });
      
      when(() => mockPrefs.getString(any())).thenAnswer((invocation) {
        final key = invocation.positionalArguments[0] as String;
        
        if (key == '${PreferenceKeys.recipeCache}_A') {
          return 'A'.padRight(3000000, 'A'); 
        } else if (key == '${PreferenceKeys.recipeCache}_B') {
          return 'B'.padRight(2000000, 'B'); 
        } else if (key == '${PreferenceKeys.recipeCache}_C') {
          return 'C'.padRight(1000000, 'C'); 
        } else {
          return ''; 
        }
      });
      
      when(() => mockPrefs.get('${PreferenceKeys.recipeCacheTimestamp}_A'))
          .thenReturn(twoHoursAgo.millisecondsSinceEpoch);
      when(() => mockPrefs.get('${PreferenceKeys.recipeCacheTimestamp}_B'))
          .thenReturn(oneHourAgo.millisecondsSinceEpoch);
      when(() => mockPrefs.get('${PreferenceKeys.recipeCacheTimestamp}_C'))
          .thenReturn(now.millisecondsSinceEpoch);
      
      when(() => mockPrefs.remove(any())).thenAnswer((invocation) {
        final key = invocation.positionalArguments[0] as String;
        removedKeys.add(key);
        
        if (key == '${PreferenceKeys.recipeCache}_A') {
          removedA = true;
        } else if (key == '${PreferenceKeys.recipeCache}_B') {
          removedB = true;
        }
        
        return Future.value(true);
      });

      await localDataSource.cleanCacheIfNeeded();
      
      expect(removedKeys, contains('${PreferenceKeys.recipeCache}_A'));
      expect(removedKeys, contains('${PreferenceKeys.recipeCacheTimestamp}_A'));
      
      expect(removedKeys, isNot(contains('${PreferenceKeys.recipeCache}_B')));
      expect(removedKeys, isNot(contains('${PreferenceKeys.recipeCacheTimestamp}_B')));
      
      expect(removedKeys, isNot(contains('${PreferenceKeys.recipeCache}_C')));
      expect(removedKeys, isNot(contains('${PreferenceKeys.recipeCacheTimestamp}_C')));
    });
    
    test('should remove oldest entries first when cleaning cache', () async {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      
      final removedKeys = <String>[];
      var removedB = false;
      
      reset(mockPrefs);
      
      when(() => mockPrefs.getKeys()).thenReturn(
        {'${PreferenceKeys.recipeCache}_A', '${PreferenceKeys.recipeCacheTimestamp}_A',
         '${PreferenceKeys.recipeCache}_B', '${PreferenceKeys.recipeCacheTimestamp}_B',
         '${PreferenceKeys.recipeCache}_C', '${PreferenceKeys.recipeCacheTimestamp}_C'}
      );
      
      when(() => mockPrefs.getString(any())).thenAnswer((invocation) {
        final key = invocation.positionalArguments[0] as String;
        
        if (key == '${PreferenceKeys.recipeCache}_A') {
          return 'A'.padRight(2000000, 'A'); 
        } else if (key == '${PreferenceKeys.recipeCache}_B') {
          return 'B'.padRight(3000000, 'B');  
        } else if (key == '${PreferenceKeys.recipeCache}_C') {
          return 'C'.padRight(1000000, 'C'); 
        } else {
          return ''; 
        }
      });
      
      when(() => mockPrefs.getKeys()).thenAnswer((_) {
        if (removedB) {
          return {'${PreferenceKeys.recipeCache}_A', '${PreferenceKeys.recipeCacheTimestamp}_A',
                 '${PreferenceKeys.recipeCache}_C', '${PreferenceKeys.recipeCacheTimestamp}_C'};
        } else {
          return {'${PreferenceKeys.recipeCache}_A', '${PreferenceKeys.recipeCacheTimestamp}_A',
                 '${PreferenceKeys.recipeCache}_B', '${PreferenceKeys.recipeCacheTimestamp}_B',
                 '${PreferenceKeys.recipeCache}_C', '${PreferenceKeys.recipeCacheTimestamp}_C'};
        }
      });
      
      when(() => mockPrefs.get('${PreferenceKeys.recipeCacheTimestamp}_A'))
          .thenReturn(oneHourAgo.millisecondsSinceEpoch);
      when(() => mockPrefs.get('${PreferenceKeys.recipeCacheTimestamp}_B'))
          .thenReturn(twoHoursAgo.millisecondsSinceEpoch);
      when(() => mockPrefs.get('${PreferenceKeys.recipeCacheTimestamp}_C'))
          .thenReturn(now.millisecondsSinceEpoch);
      
      when(() => mockPrefs.remove(any())).thenAnswer((invocation) {
        final key = invocation.positionalArguments[0] as String;
        removedKeys.add(key);
        
        if (key == '${PreferenceKeys.recipeCache}_B') {
          removedB = true;
        }
        
        return Future.value(true);
      });
      
      await localDataSource.cleanCacheIfNeeded();
      
      expect(removedKeys, contains('${PreferenceKeys.recipeCache}_B'));
      expect(removedKeys, contains('${PreferenceKeys.recipeCacheTimestamp}_B'));
      
      expect(removedKeys, isNot(contains('${PreferenceKeys.recipeCache}_A')));
      expect(removedKeys, isNot(contains('${PreferenceKeys.recipeCacheTimestamp}_A')));
      expect(removedKeys, isNot(contains('${PreferenceKeys.recipeCache}_C')));
      expect(removedKeys, isNot(contains('${PreferenceKeys.recipeCacheTimestamp}_C')));
    });
  });
}