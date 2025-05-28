import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'Initialize SharedPreferences in main.dart before running the app',
  );
});

class PreferenceKeys {
  static const String favorites = 'favorites';
  static const String bookmarks = 'bookmarks';
  static const String recipeCache = 'recipe_cache';
  static const String recipeCacheTimestamp = 'recipe_cache_timestamp';
  static const String recipeDetail = 'recipe_detail';
  static const String recipeDetailTimestamp = 'recipe_detail_timestamp';
  
  PreferenceKeys._();
}

class LocalDataSource {
  final SharedPreferences _prefs;
  static const cacheDuration = Duration(hours: 1);
  static const maxCacheSize = 5 * 1024 * 1024;

  LocalDataSource(this._prefs);

  Future<bool> isFavorite(String recipeId) async {
    final stringId = recipeId.toString();
    if (stringId.isEmpty) {
      return false;
    }
    
    final favorites = await getFavoriteIds();
    return favorites.contains(stringId);
  }

  Future<bool> isBookmarked(String recipeId) async {
    final stringId = recipeId.toString();
    if (stringId.isEmpty) {
      return false;
    }
    
    final bookmarks = await getBookmarkIds();
    return bookmarks.contains(stringId);
  }

  Future<void> addFavorite(String recipeId) async {
    final stringId = recipeId.toString();
    if (stringId.isEmpty) {
      return;
    }
    
    final favorites = await getFavoriteIds();
    if (!favorites.contains(stringId)) {
      favorites.add(stringId);
      await _saveFavorites(favorites);
    }
  }

  Future<void> removeFavorite(String recipeId) async {
    final stringId = recipeId.toString();
    if (stringId.isEmpty) {
      return;
    }
    
    final favorites = await getFavoriteIds();
    if (favorites.remove(stringId)) {
      await _saveFavorites(favorites);
    }
  }

  Future<void> addBookmark(String recipeId) async {
    final stringId = recipeId.toString();
    if (stringId.isEmpty) {
      return;
    }
    
    final bookmarks = await getBookmarkIds();
    if (!bookmarks.contains(stringId)) {
      bookmarks.add(stringId);
      await _saveBookmarks(bookmarks);
    }
  }

  Future<void> removeBookmark(String recipeId) async {
    final stringId = recipeId.toString();
    if (stringId.isEmpty) {
      return;
    }
    
    final bookmarks = await getBookmarkIds();
    if (bookmarks.remove(stringId)) {
      await _saveBookmarks(bookmarks);
    }
  }

  Future<List<String>> getFavoriteIds() async {
    try {
      final favoritesJson = _prefs.getString(PreferenceKeys.favorites);
      if (favoritesJson == null) {
        return [];
      }

      final List<dynamic> decoded = json.decode(favoritesJson);
      final results = decoded.map((id) {
        if (id == null) {
          return 'invalid_id';
        }
        return id is String ? id : id.toString();
      }).toList();
      
      final validResults = results.where((id) => id != 'invalid_id' && id.isNotEmpty).toList();
      if (validResults.length != results.length) {
      }
      
      return validResults;
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getBookmarkIds() async {
    try {
      final bookmarksJson = _prefs.getString(PreferenceKeys.bookmarks);
      if (bookmarksJson == null) {
        return [];
      }

      final List<dynamic> decoded = json.decode(bookmarksJson);
      final results = decoded.map((id) {
        if (id == null) {
          return 'invalid_id';
        }
        return id is String ? id : id.toString();
      }).toList();
      
      final validResults = results.where((id) => id != 'invalid_id' && id.isNotEmpty).toList();
      if (validResults.length != results.length) {
      }
      
      return validResults;
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveFavorites(List<String> favorites) async {
    final validIds = favorites.where((id) => id.isNotEmpty).toList();
    final encodedList = json.encode(validIds);
    final success = await _prefs.setString(PreferenceKeys.favorites, encodedList);
  }

  Future<void> _saveBookmarks(List<String> bookmarks) async {
    final validIds = bookmarks.where((id) => id.isNotEmpty).toList();
    final encodedList = json.encode(validIds);
    final success = await _prefs.setString(PreferenceKeys.bookmarks, encodedList);
  }

  Future<void> cacheRecipesByLetter(String letter, List<Map<String, dynamic>> recipes) async {
    try {
      final letterStr = letter.toString();
      
      final processedRecipes = recipes.map((recipe) {
        final recipeMap = Map<String, dynamic>.from(recipe);
        final rawId = recipeMap['idMeal'] ?? recipeMap['id'];
        if (rawId != null) {
          recipeMap['idMeal'] = rawId.toString();
          recipeMap['id'] = rawId.toString();
        }
        return recipeMap;
      }).toList();
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cacheKey = '${PreferenceKeys.recipeCache}_$letterStr';
      final timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_$letterStr';

      try {
        final jsonStr = json.encode(processedRecipes);
        final success = await _prefs.setString(cacheKey, jsonStr);
        if (!success) {
          return;
        }
      } catch (jsonError) {
        return;
      }
      
      final timestampSuccess = await _prefs.setInt(timestampKey, timestamp);
      if (!timestampSuccess) {
        await _prefs.remove(cacheKey);
        return;
      }
      await cleanCacheIfNeeded();
    } catch (e) {
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedRecipesByLetter(String letter) async {
    try {
      final letterStr = letter.toString();
      
      final cacheKey = '${PreferenceKeys.recipeCache}_$letterStr';
      final timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_$letterStr';

      String? cachedData;
      try {
        cachedData = _prefs.getString(cacheKey);
        if (cachedData == null) {
          return null;
        }
      } catch (e) {
        await _prefs.remove(cacheKey);
        return null;
      }
      
      int? timestamp;
      try {
        final dynamic timestampValue = _prefs.get(timestampKey);
        
        if (timestampValue is int) {
          timestamp = timestampValue;
        } else if (timestampValue != null) {
          try {
            timestamp = int.parse(timestampValue.toString());
            await _prefs.setInt(timestampKey, timestamp);
          } catch (parseError) {
            await _prefs.remove(timestampKey);
            await _prefs.remove(cacheKey);
            return null;
          }
        }
      } catch (e) {
        await _prefs.remove(timestampKey);
        return null;
      }

      if (timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (age < cacheDuration.inMilliseconds) {
          try {
            final List<dynamic> decoded = json.decode(cachedData);
            
            final recipes = decoded.map((item) {
              if (item is Map<String, dynamic>) {
                final recipeMap = Map<String, dynamic>.from(item);
                final rawId = recipeMap['idMeal'] ?? recipeMap['id'];
                if (rawId != null) {
                  recipeMap['idMeal'] = rawId.toString();
                  recipeMap['id'] = rawId.toString();
                }
                return recipeMap;
              } else {
                return <String, dynamic>{}; 
              }
            }).where((map) => map.isNotEmpty).toList(); 
          } catch (e) {
            await _prefs.remove(cacheKey);
            await _prefs.remove(timestampKey);
            return null;
          }
        } else {
          await clearLetterCache(letterStr);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearLetterCache(String letter) async {
    final cacheKey = '${PreferenceKeys.recipeCache}_$letter';
    final timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_$letter';

    await _prefs.remove(cacheKey);
    await _prefs.remove(timestampKey);
  }

  Future<void> clearAllCache() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(PreferenceKeys.recipeCache)) {
        await _prefs.remove(key);
      }
    }
  }

  Future<void> clear() async {
    await _prefs.remove(PreferenceKeys.favorites);
    await _prefs.remove(PreferenceKeys.bookmarks);
    await clearAllCache();
  }

  Future<int> getCacheSize() async {
    int totalSize = 0;
    final keys = _prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(PreferenceKeys.recipeCache)) {
        final data = _prefs.getString(key);
        if (data != null) {
          totalSize += data.length;
        }
      }
    }
    return totalSize;
  }

  Future<void> cleanExpiredCache() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final keys = _prefs.getKeys().toList();
      
      for (final key in keys) {
        if (key.startsWith(PreferenceKeys.recipeCache) && !key.startsWith(PreferenceKeys.recipeCacheTimestamp)) {
          try {
            final parts = key.split('_');
            if (parts.length < 2) {
              continue;
            }
            
            final letterPart = parts.last;
            final letterStr = letterPart.toString(); 
            
            final timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_$letterStr';
            
            int? timestamp;
            try {
              final dynamic timestampValue = _prefs.get(timestampKey);
              
              if (timestampValue is int) {
                timestamp = timestampValue;
              } else if (timestampValue != null) {
                try {
                  timestamp = int.parse(timestampValue.toString());
                  await _prefs.setInt(timestampKey, timestamp);
                } catch (parseError) {
                  await _prefs.remove(timestampKey);
                  await _prefs.remove(key);
                  continue;
                }
              }
              
              if (timestamp != null) {
                final age = now - timestamp;
                if (age >= cacheDuration.inMilliseconds) {
                  await clearLetterCache(letterStr); 
                }
              } else {
                await clearLetterCache(letterStr);
              }
            } catch (timestampError) {
              await _prefs.remove(timestampKey);
              await _prefs.remove(key);
            }
          } catch (keyError) {
            await _prefs.remove(key);
          }
        }
      }
    } catch (e) {
    }
  }

  Future<void> cleanCacheIfNeeded() async {
    try {
      final size = await getCacheSize();
      
      if (size > maxCacheSize) {
        
        final entries = <MapEntry<String, int>>[];
        final keys = _prefs.getKeys();
        
        for (final key in keys) {
          if (key.startsWith(PreferenceKeys.recipeCache) && !key.startsWith(PreferenceKeys.recipeCacheTimestamp)) {
            try {
              final parts = key.split('_');
              if (parts.length < 2) continue;
              
              final letterPart = parts.last;
              final letterStr = letterPart.toString(); 
              
              final timestampKey = '${PreferenceKeys.recipeCacheTimestamp}_$letterStr';
              
              try {
                final dynamic timestampValue = _prefs.get(timestampKey);
                int? timestamp;
                
                if (timestampValue is int) {
                  timestamp = timestampValue;
                } else if (timestampValue != null) {
                  try {
                    timestamp = int.parse(timestampValue.toString());
                    await _prefs.setInt(timestampKey, timestamp);
                  } catch (parseError) {
                    await _prefs.remove(timestampKey);
                    continue;
                  }
                }
                
                if (timestamp != null) {
                  entries.add(MapEntry(letterStr, timestamp));
                }
              } catch (e) {
                await _prefs.remove(timestampKey);
                await _prefs.remove(key);
              }
            } catch (keyProcessingError) {
              await _prefs.remove(key);
            }
          }
        }
        
        if (entries.isEmpty) {
          return;
        }
        
        entries.sort((a, b) => a.value.compareTo(b.value));
        
        for (final entry in entries) {
          try {
            await clearLetterCache(entry.key);
            
            final newSize = await getCacheSize();
            
            if (newSize <= maxCacheSize) {
              break;
            }
          } catch (clearError) {
          }
        }
      } else {
      }
    } catch (e) {
      try {
        await clearEmergencyCache();
      } catch (emergencyError) {
      }
    }
  }

  Future<bool> cleanIdLists() async {
    bool hasChanges = false;
    
    try {
      final favorites = await getFavoriteIds();
      final validFavorites = favorites.where((id) => id.isNotEmpty).toList();
      
      if (validFavorites.length != favorites.length) {
        await _saveFavorites(validFavorites);
        hasChanges = true;
      }
      
      final bookmarks = await getBookmarkIds();
      final validBookmarks = bookmarks.where((id) => id.isNotEmpty).toList();
      
      if (validBookmarks.length != bookmarks.length) {
        await _saveBookmarks(validBookmarks);
        hasChanges = true;
      }
      
      if (hasChanges) {
      } else {
      }
      
      return hasChanges;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> maintainCache() async {
    try {
      await cleanExpiredCache();
      await cleanCacheIfNeeded();
      await cleanIdLists();
    } catch (e) {
      try {
        await clearEmergencyCache();
      } catch (clearError) {
      }
    }
  }
  
  Future<void> clearEmergencyCache() async {
    final keys = _prefs.getKeys().toList();
    
    for (final key in keys) {
      if (key.startsWith(PreferenceKeys.recipeCache) || 
          key.startsWith(PreferenceKeys.recipeCacheTimestamp) ||
          key.startsWith(PreferenceKeys.recipeDetail) ||
          key.startsWith(PreferenceKeys.recipeDetailTimestamp)) {
        await _prefs.remove(key);
      }
    }
  }

  Future<void> cacheRecipe(Map<String, dynamic> recipe) async {
    final rawId = recipe['idMeal'] ?? recipe['id'];
    if (rawId == null) {
      return;
    }

    final recipeId = rawId.toString();
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cacheKey = '${PreferenceKeys.recipeDetail}_$recipeId';
    final timestampKey = '${PreferenceKeys.recipeDetailTimestamp}_$recipeId';

    await _prefs.setString(cacheKey, json.encode(recipe));
    await _prefs.setInt(timestampKey, timestamp);
    
    await cleanCacheIfNeeded();
  }

  Future<Map<String, dynamic>?> getCachedRecipe(String recipeId) async {
    try {
      final String stringId = recipeId.toString();
      if (stringId.isEmpty) {
        return null;
      }
      
      final cacheKey = '${PreferenceKeys.recipeDetail}_$stringId';
      final timestampKey = '${PreferenceKeys.recipeDetailTimestamp}_$stringId';

      String? cachedData;
      int? timestamp;
      
      try {
        cachedData = _prefs.getString(cacheKey);
      } catch (e) {
        await _prefs.remove(cacheKey);
        return null;
      }
      
      try {
        timestamp = _prefs.getInt(timestampKey);
      } catch (e) {
        await _prefs.remove(timestampKey);
        await _prefs.remove(cacheKey);
        return null;
      }

      if (cachedData != null && timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (age < cacheDuration.inMilliseconds) {
          try {
            final Map<String, dynamic> decodedData = json.decode(cachedData) as Map<String, dynamic>;
            
            final rawId = decodedData['idMeal'] ?? decodedData['id'];
            if (rawId != null) {
              decodedData['idMeal'] = rawId.toString();
              decodedData['id'] = rawId.toString();
            }
            
            return decodedData;
          } catch (e) {
            await _prefs.remove(cacheKey);
            await _prefs.remove(timestampKey);
            return null;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}