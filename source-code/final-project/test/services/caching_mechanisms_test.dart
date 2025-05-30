import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late LocalDataSource localDataSource;
  late MockSharedPreferences mockPrefs;
  
  final testRecipe = {
    'idMeal': '52772',
    'strMeal': 'Teriyaki Chicken Casserole',
    'strCategory': 'Chicken',
    'strArea': 'Japanese',
  };
  
  final testRecipes = [
    testRecipe,
    {
      'idMeal': '52773',
      'strMeal': 'Honey Teriyaki Salmon',
      'strCategory': 'Seafood',
      'strArea': 'Japanese',
    }
  ];

  setUp(() {
    mockPrefs = MockSharedPreferences();
    localDataSource = LocalDataSource(mockPrefs);
  });

  group('Cache policy implementation', () {

    test('TTL validation - returns null when cache is expired', () async {
     
      final letterKey = '${PreferenceKeys.recipeCache}_A';
      final timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_A';
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final cacheTime = currentTime - (LocalDataSource.cacheDuration.inMilliseconds * 2); // Twice TTL passed
      
     
      when(() => mockPrefs.getString(letterKey))
          .thenReturn(json.encode(testRecipes));
      when(() => mockPrefs.get(timestampKey))
          .thenReturn(cacheTime);
      when(() => mockPrefs.remove(letterKey))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.remove(timestampKey))
          .thenAnswer((_) async => true);
      
     
      final result = await localDataSource.getCachedRecipesByLetter('A');
      
      expect(result, isNull, reason: 'Cache should be null when expired');
      
      verify(() => mockPrefs.remove(letterKey)).called(1);
      verify(() => mockPrefs.remove(timestampKey)).called(1);
    });

    test('TTL is properly set when caching data', () async {
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.setInt(any(), any()))
          .thenAnswer((_) async => true);
      
      await localDataSource.cacheRecipesByLetter('A', testRecipes);
      
      verify(() => mockPrefs.setString('${PreferenceKeys.recipeCache}_A', any())).called(1);
      
      final verificationResult = verify(() => mockPrefs.setInt('${PreferenceKeys.recipeCacheTimestamp}_A', captureAny()));
      verificationResult.called(1);
      
      final capturedTimestamp = verificationResult.captured.first as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(capturedTimestamp, closeTo(now, 5000)); 
    });
  });

  group('Cache hit/miss behavior', () {

    test('Cache miss - returns null if cache not available', () async {
      final letterKey = '${PreferenceKeys.recipeCache}_A';
      
      when(() => mockPrefs.getString(letterKey))
          .thenReturn(null);
      
      final result = await localDataSource.getCachedRecipesByLetter('A');
      
      expect(result, isNull);
      verify(() => mockPrefs.getString(letterKey)).called(1);
    });

    test('Cache miss with corrupted data - handles gracefully', () async {
      final letterKey = '${PreferenceKeys.recipeCache}_A';
      final timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_A';
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      when(() => mockPrefs.getString(letterKey))
          .thenReturn('This is not valid JSON');
      when(() => mockPrefs.get(timestampKey))
          .thenReturn(currentTime);
      when(() => mockPrefs.remove(letterKey))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.remove(timestampKey))
          .thenAnswer((_) async => true);
      
      final result = await localDataSource.getCachedRecipesByLetter('A');
      
      expect(result, isNull, reason: 'Cache should be null when data is corrupted');
      
      verify(() => mockPrefs.remove(letterKey)).called(1);
      verify(() => mockPrefs.remove(timestampKey)).called(1);
    });
  });

  group('Cache invalidation', () {
    test('clearLetterCache removes specific letter cache', () async {
      final letterKey = '${PreferenceKeys.recipeCache}_A';
      final timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_A';
      
      when(() => mockPrefs.remove(any()))
          .thenAnswer((_) async => true);
      
      await localDataSource.clearLetterCache('A');
      
      verify(() => mockPrefs.remove(letterKey)).called(1);
      verify(() => mockPrefs.remove(timestampKey)).called(1);
    });

    test('clearAllCache removes all recipe caches', () async {
      final keys = {
        '${PreferenceKeys.recipeCache}_A': 'data1',
        '${PreferenceKeys.recipeCache}_B': 'data2',
        'some_other_key': 'other_data',
      };
      
      when(() => mockPrefs.getKeys())
          .thenReturn(keys.keys.toSet());
      when(() => mockPrefs.remove(any()))
          .thenAnswer((_) async => true);
      
      await localDataSource.clearAllCache();
      
      verify(() => mockPrefs.remove('${PreferenceKeys.recipeCache}_A')).called(1);
      verify(() => mockPrefs.remove('${PreferenceKeys.recipeCache}_B')).called(1);
      verifyNever(() => mockPrefs.remove('some_other_key'));
    });
  });

  group('Offline mode support', () {

    test('Individual recipe fetching from cache', () async {
      
      final recipeId = '52772';
      final recipeKey = '${PreferenceKeys.recipeDetail}_$recipeId';
      final timestampKey = '${PreferenceKeys.recipeDetailTimestamp}_$recipeId';
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      when(() => mockPrefs.getString(recipeKey))
          .thenReturn(json.encode(testRecipe));
      when(() => mockPrefs.getInt(timestampKey))
          .thenReturn(currentTime);
      when(() => mockPrefs.remove(any()))
          .thenAnswer((_) async => true);
      
      final result = await localDataSource.getCachedRecipe(recipeId);
      
      expect(result, isNotNull, reason: 'Individual recipe should be retrievable from cache');
      expect(result!['strMeal'], equals('Teriyaki Chicken Casserole'));
    });
  });

  group('Cache synchronization', () {

    test('Cache is properly updated when new data is available', () async {

      final letterKey = '${PreferenceKeys.recipeCache}_A';
      final timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_A';
      
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.setInt(any(), any()))
          .thenAnswer((_) async => true);
      
      final originalRecipes = [testRecipe];
      
      final updatedRecipes = [
        testRecipe,
        {
          'idMeal': '52774',
          'strMeal': 'New Recipe',
          'strCategory': 'Dessert',
        }
      ];
      
      await localDataSource.cacheRecipesByLetter('A', originalRecipes);
      
      await localDataSource.cacheRecipesByLetter('A', updatedRecipes);
      
      verify(() => mockPrefs.setString(letterKey, any())).called(2);
      
      verify(() => mockPrefs.setInt(timestampKey, any())).called(2);
    });
  });

  group('Cache size management', () {
    test('cleanCacheIfNeeded removes oldest entries when size exceeds limit', () async {
     
      final recipeKeys = {
        '${PreferenceKeys.recipeCache}_A',
        '${PreferenceKeys.recipeCache}_B',
        '${PreferenceKeys.recipeCache}_C'
      };
      
      final timestampKeys = {
        '${PreferenceKeys.recipeCacheTimestamp}_A',
        '${PreferenceKeys.recipeCacheTimestamp}_B',
        '${PreferenceKeys.recipeCacheTimestamp}_C'
      };
      
      final allKeys = {...recipeKeys, ...timestampKeys};
      final now = DateTime.now().millisecondsSinceEpoch;
      
      when(() => mockPrefs.getKeys()).thenReturn(allKeys);
      
      when(() => mockPrefs.get('${PreferenceKeys.recipeCacheTimestamp}_A'))
          .thenReturn(now - 10000);
      when(() => mockPrefs.get('${PreferenceKeys.recipeCacheTimestamp}_B'))
          .thenReturn(now - 5000);
      when(() => mockPrefs.get('${PreferenceKeys.recipeCacheTimestamp}_C'))
          .thenReturn(now);
      
      when(() => mockPrefs.getString('${PreferenceKeys.recipeCache}_A'))
          .thenReturn(List.filled(2000000, 'a').join());
      when(() => mockPrefs.getString('${PreferenceKeys.recipeCache}_B'))
          .thenReturn(List.filled(2000000, 'b').join());
      when(() => mockPrefs.getString('${PreferenceKeys.recipeCache}_C'))
          .thenReturn(List.filled(2000000, 'c').join());
      
      when(() => mockPrefs.remove('${PreferenceKeys.recipeCache}_A'))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.remove('${PreferenceKeys.recipeCacheTimestamp}_A'))
          .thenAnswer((_) async => true);
      
      await localDataSource.cleanCacheIfNeeded();
      
      verify(() => mockPrefs.remove('${PreferenceKeys.recipeCache}_A')).called(1);
      verify(() => mockPrefs.remove('${PreferenceKeys.recipeCacheTimestamp}_A')).called(1);
    });

    test('cleanExpiredCache removes only expired entries', () async {
      final allKeys = <String>{
        '${PreferenceKeys.recipeCache}_A',
        '${PreferenceKeys.recipeCache}_B',
        '${PreferenceKeys.recipeCache}_C',
        '${PreferenceKeys.recipeCacheTimestamp}_A',
        '${PreferenceKeys.recipeCacheTimestamp}_B',
        '${PreferenceKeys.recipeCacheTimestamp}_C'
      };

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final cacheDuration = LocalDataSource.cacheDuration.inMilliseconds;
      
      when(() => mockPrefs.getKeys()).thenReturn(allKeys);
      
      when(() => mockPrefs.get('${PreferenceKeys.recipeCacheTimestamp}_A'))
          .thenReturn(currentTime - (cacheDuration * 2)); 
      when(() => mockPrefs.get('${PreferenceKeys.recipeCacheTimestamp}_B'))
          .thenReturn(currentTime - (cacheDuration ~/ 2)); 
      when(() => mockPrefs.get('${PreferenceKeys.recipeCacheTimestamp}_C'))
          .thenReturn(currentTime); 
      
      when(() => mockPrefs.remove('${PreferenceKeys.recipeCache}_A'))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.remove('${PreferenceKeys.recipeCacheTimestamp}_A'))
          .thenAnswer((_) async => true);
      
      await localDataSource.cleanExpiredCache();
      
      verify(() => mockPrefs.remove('${PreferenceKeys.recipeCache}_A')).called(1);
      verify(() => mockPrefs.remove('${PreferenceKeys.recipeCacheTimestamp}_A')).called(1);
      
      verifyNever(() => mockPrefs.remove('${PreferenceKeys.recipeCache}_B'));
      verifyNever(() => mockPrefs.remove('${PreferenceKeys.recipeCacheTimestamp}_B'));
      verifyNever(() => mockPrefs.remove('${PreferenceKeys.recipeCache}_C'));
      verifyNever(() => mockPrefs.remove('${PreferenceKeys.recipeCacheTimestamp}_C'));
    });
  });
}
