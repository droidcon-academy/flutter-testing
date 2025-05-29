import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recipevault/core/mixins/safe_async_mixin.dart';
import 'package:recipevault/presentation/viewmodels/recipe_viewmodel.dart';
import '../../../domain/entities/recipe.dart';
import '../../../domain/usecases/favorite_recipe.dart';
import '../../../domain/usecases/bookmark_recipe.dart';
import '../../../data/models/recipe_model.dart';

class DashboardConstants {
  static const String recipeCacheKey = 'cached_recipes';
  static const String favoritesCacheKey = 'cached_favorites';
  static const String bookmarksCacheKey = 'cached_bookmarks';
  static const Duration cacheExpiration = Duration(days: 1);
}

enum LogLevel {
  info,
  warning,
  error,
  critical,
}

class DashboardState {
  final List<Recipe> recipes;
  final Set<String> favoriteIds;
  final Set<String> bookmarkIds;
  final bool isLoading;
  final bool isPartiallyLoaded; 
  final String? error;
  final DateTime? lastUpdated; 

  const DashboardState({
    this.recipes = const [],
    this.favoriteIds = const {},
    this.bookmarkIds = const {},
    this.isLoading = false,
    this.isPartiallyLoaded = false,
    this.error,
    this.lastUpdated,
  });

  DashboardState copyWith({
    List<Recipe>? recipes,
    Set<String>? favoriteIds,
    Set<String>? bookmarkIds,
    bool? isLoading,
    bool? isPartiallyLoaded,
    String? error,
    DateTime? lastUpdated,
  }) {
    return DashboardState(
      recipes: recipes ?? this.recipes,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      bookmarkIds: bookmarkIds ?? this.bookmarkIds,
      isLoading: isLoading ?? this.isLoading,
      isPartiallyLoaded: isPartiallyLoaded ?? this.isPartiallyLoaded,
      error: error, 
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  List<Recipe> get favoriteRecipes {
    return recipes.where((recipe) => favoriteIds.contains(recipe.id)).toList();
  }

  List<Recipe> get bookmarkedRecipes {
    return recipes.where((recipe) => bookmarkIds.contains(recipe.id)).toList();
  }
}

class DashboardViewModel extends StateNotifier<DashboardState> with SafeAsyncMixin {
  final FavoriteRecipe _favoriteRecipe;
  final BookmarkRecipe _bookmarkRecipe;
  final RecipeState _recipeState;
  final Ref _ref;
  
  DashboardViewModel(
    this._favoriteRecipe,
    this._bookmarkRecipe,
    this._recipeState,
    this._ref,
  ) : super(DashboardState(
          recipes: _recipeState.recipes,
          lastUpdated: DateTime.now(),
        )) {
    initializeDataProgressively();
    
    _setupRecipeStateListener();
  }
  
  factory DashboardViewModel.forTesting({
    required FavoriteRecipe favoriteRecipe,
    required BookmarkRecipe bookmarkRecipe,
    required RecipeState recipeState,
    required Ref ref,
  }) {
    return DashboardViewModel(favoriteRecipe, bookmarkRecipe, recipeState, ref);
  }
  
  void _setupRecipeStateListener() {
    _ref.listen<RecipeState>(recipeProvider, (previous, current) {
      if (disposed) {
        return;
      }
      
      final isEmptyLetterSelection = current.selectedLetter != null && 
                                   current.recipes.isEmpty && 
                                   !current.isLoading;
      
      if (isEmptyLetterSelection) {
        _safeUpdateState(() {
          state = state.copyWith(
            isLoading: false,
            error: null
          );
        });
        
        if (!disposed) {
          loadFavorites().then((_) {
            if (!disposed) loadBookmarks();
          });
        }
      }
      
      final recipesChanged = previous?.recipes != current.recipes && 
                            current.recipes.isNotEmpty;
                            
      final favoritesChanged = previous?.favoriteIds != current.favoriteIds && 
                              current.favoriteIds.isNotEmpty;
                              
      final bookmarksChanged = previous?.bookmarkIds != current.bookmarkIds && 
                              current.bookmarkIds.isNotEmpty;
      
      if (recipesChanged) {
        _safeUpdateState(() {
          state = state.copyWith(recipes: current.recipes);
        });
        if (current.recipes.isNotEmpty && !disposed) {
          _cacheRecipes(current.recipes);
          _validateDataConsistency();
        }
      }
      
      if (favoritesChanged) {
        _safeUpdateState(() {
          state = state.copyWith(favoriteIds: current.favoriteIds);
        });
        if (!disposed) {
          _validateDataConsistency();
        }
      }
      
      if (bookmarksChanged) {
        _safeUpdateState(() {
          state = state.copyWith(bookmarkIds: current.bookmarkIds);
        });
        if (!disposed) {
          _validateDataConsistency();
        }
      }
      
      if (previous != null && 
          previous.recipes.isNotEmpty && 
          current.recipes.isEmpty && 
          current.selectedLetter == null) { 
        _logAnalytics(LogLevel.info, 'Recipe state reset detected, re-initializing');
        if (!disposed) {
          initializeDataProgressively();
        }
      }
    });
  }

  Future<void> initializeDataProgressively() async {
    if (disposed) {
      return;
    }
    
    final recipeState = _ref.read(recipeProvider);
    final isEmptyLetterSelection = recipeState.selectedLetter != null && 
                                  recipeState.recipes.isEmpty && 
                                  !recipeState.isLoading;
                                  
    if (isEmptyLetterSelection) {
      _safeUpdateState(() {
        state = state.copyWith(
          isLoading: false,
          isPartiallyLoaded: true,
          error: null
        );
      });
      
      await loadFavorites();
      
      if (disposed) return;
      
      await loadBookmarks();
      
      if (!disposed) {
        _safeUpdateState(() {
          state = state.copyWith(isPartiallyLoaded: false);
        });
      }
      
      return; 
    }
    
    try {
      _safeUpdateState(() {
        state = state.copyWith(isLoading: true, error: null);
      });
      
      await _loadBasicDataFromCache();
      
      if (disposed) {
        return;
      }
      
      _safeUpdateState(() {
        state = state.copyWith(isPartiallyLoaded: true);
      });
      
      if (disposed) return;
      
      _loadDetailedDataInBackground();
      
    } catch (e) {
      _logAnalytics(LogLevel.error, 'Error in progressive data loading: $e');
      if (!disposed) {
        _safeUpdateState(() {
          state = state.copyWith(
            isLoading: false,
            error: 'Dashboard initialization failed: $e',
          );
        });
      }
    }
  }

  Future<void> _loadBasicDataFromCache() async {
    if (disposed) {
      return;
    }
    
    try {
      final cachedRecipes = await _loadRecipesFromCache();
      
      if (cachedRecipes.isNotEmpty) {
        _safeUpdateState(() {
          state = state.copyWith(
            recipes: cachedRecipes,
            lastUpdated: DateTime.now(),
          );
        });
      }
      
      final cachedFavorites = await _loadFavoritesFromCache();
      final cachedBookmarks = await _loadBookmarksFromCache();
      
      if (cachedFavorites.isNotEmpty || cachedBookmarks.isNotEmpty) {
        _safeUpdateState(() {
          state = state.copyWith(
            favoriteIds: cachedFavorites,
            bookmarkIds: cachedBookmarks,
          );
        });
      }
    } catch (e) {
      _logAnalytics(LogLevel.warning, 'Error loading from cache: $e');
    }
  }
  
  Future<void> _loadDetailedDataInBackground() async {
    if (disposed) {
      return;
    }
    
    try {
      if (_recipeState.recipes.isEmpty || _isCacheStale()) {
        try {
          await _ref.read(recipeProvider.notifier).loadRecipes();
          
          final recipes = _ref.read(recipeProvider).recipes;
          if (recipes.isNotEmpty) {
            _safeUpdateState(() {
              state = state.copyWith(
                recipes: recipes,
                lastUpdated: DateTime.now(),
              );
            });
            
            _cacheRecipes(recipes);
          } else {
            if (state.recipes.isEmpty) {
              _safeUpdateState(() {
                state = state.copyWith(
                  error: 'Unable to load recipes. Your favorites and bookmarks may not display correctly.',
                );
              });
            }
          }
        } catch (e) {
          _logAnalytics(LogLevel.error, 'Error loading recipes: $e');
          if (state.recipes.isEmpty) {
            _safeUpdateState(() {
              state = state.copyWith(
                error: 'Error loading recipes: $e',
              );
            });
          }
        }
      } else {
        _safeUpdateState(() {
          state = state.copyWith(recipes: _recipeState.recipes);
        });
      }
      
      await loadFavorites();
      await loadBookmarks();
      
      _validateDataConsistency();
      
      _safeUpdateState(() {
        state = state.copyWith(
          isLoading: false,
          isPartiallyLoaded: false,
        );
      });
    } catch (e) {
      _logAnalytics(LogLevel.error, 'Background loading error: $e');
      _safeUpdateState(() {
        state = state.copyWith(
          isLoading: false,
          error: 'Dashboard full initialization failed: $e',
        );
      });
    }
  }
  
  Future<void> initializeData() async {
    if (disposed) {
      return;
    }
    
    await initializeDataProgressively();
  }

  Future<void> loadFavorites() async {
    if (disposed) {
      return;
    }
    
    try {
      const maxRetries = 2;
      int attempts = 0;
      bool success = false;
      
      while (!success && attempts < maxRetries && !disposed) {
        attempts++;
        try {
          if (disposed) {
            return;
          }
          
          final result = await _favoriteRecipe.getFavorites();
          
          if (disposed) {
            return;
          }
          result.fold(
            (failure) {
              if (attempts >= maxRetries) {
                _safeUpdateState(() {
                  state = state.copyWith(
                    error: state.error == null 
                      ? 'Failed to load favorites: ${failure.message}' 
                      : state.error, 
                  );
                });
              }
              throw Exception(failure.message);
            },
            (recipes) {
              final favoriteIds = recipes.map((r) => r.id).toSet();
              
              final currentRecipes = List<Recipe>.from(state.recipes);
              
              for (final recipe in recipes) {
                if (!currentRecipes.any((r) => r.id == recipe.id)) {
                  currentRecipes.add(recipe);
                }
              }
              
              _safeUpdateState(() {
                state = state.copyWith(
                  favoriteIds: favoriteIds,
                  recipes: currentRecipes,
                );
              });
              success = true;
            },
          );
        } catch (e) {
          if (attempts < maxRetries) {
            await Future.delayed(Duration(milliseconds: 300 * attempts));
          } else {
            if (state.error == null) {
              _safeUpdateState(() {
                state = state.copyWith(error: 'Error loading favorites: $e');
              });
            }
          }
        }
      }
    } catch (e) {
      if (state.error == null) {
        _safeUpdateState(() {
          state = state.copyWith(error: 'Unexpected error loading favorites');
        });
      }
    }
  }

  Future<void> loadBookmarks() async {
    if (disposed) {
      return;
    }
    
    final recipeState = _ref.read(recipeProvider);
    final isEmptyLetterSelection = recipeState.selectedLetter != null && 
                                 recipeState.recipes.isEmpty;
    
  
    
    try {
      const maxRetries = 2;
      int attempts = 0;
      bool success = false;
      
      while (!success && attempts < maxRetries && !disposed) {
        attempts++;
        try {
          if (disposed) {
            return;
          }
          
          final result = await _bookmarkRecipe.getBookmarks();
          
          if (disposed) {
            return;
          }
          result.fold(
            (failure) {
              if (attempts >= maxRetries) {
                _safeUpdateState(() {
                  state = state.copyWith(
                    error: state.error == null 
                      ? 'Failed to load bookmarks: ${failure.message}' 
                      : state.error, 
                  );
                });
              }
              throw Exception(failure.message);
            },
            (recipes) {
              final bookmarkIds = recipes.map((r) => r.id).toSet();
              final currentRecipes = List<Recipe>.from(state.recipes);
              
              for (final recipe in recipes) {
                if (!currentRecipes.any((r) => r.id == recipe.id)) {
                  currentRecipes.add(recipe);
                }
              }

              _safeUpdateState(() {
                state = state.copyWith(
                  bookmarkIds: bookmarkIds,
                  recipes: currentRecipes,
                );
              });
              success = true;
            },
          );
        } catch (e) {
          if (attempts < maxRetries) {
            await Future.delayed(Duration(milliseconds: 300 * attempts));
          } else {
            if (state.error == null) {
              _safeUpdateState(() {
                state = state.copyWith(error: 'Error loading bookmarks: $e');
              });
            }
          }
        }
      }
    } catch (e) {
      if (state.error == null) {
        _safeUpdateState(() {
          state = state.copyWith(error: 'Unexpected error loading bookmarks');
        });
      }
    }
  }
  
  Future<List<Recipe>> _loadRecipesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(DashboardConstants.recipeCacheKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final recipes = jsonList.map((json) => 
          RecipeModel.fromJson(json as Map<String, dynamic>).toDomain()
        ).toList();
        
        _logAnalytics(LogLevel.info, 'Loaded ${recipes.length} recipes from cache');
        return recipes;
      }
    } catch (e) {
      _logAnalytics(LogLevel.warning, 'Error reading recipe cache: $e');
    }
    return [];
  }

  Future<void> _cacheRecipes(List<Recipe> recipes) async {
    if (disposed) {
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      if (disposed) {
        return;
      }
      
      final jsonList = recipes.map((recipe) => {
        'idMeal': recipe.id,
        'strMeal': recipe.name,
        'strInstructions': recipe.instructions,
        'strMealThumb': recipe.thumbnailUrl,
        'ingredients': recipe.ingredients.map((ingredient) => {
          'name': ingredient.name,
          'measure': ingredient.measure,
        }).toList(),
        'isFavorite': recipe.isFavorite,
        'isBookmarked': recipe.isBookmarked,
      }).toList();
      
      if (disposed) {
        return;
      }
      
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(DashboardConstants.recipeCacheKey, jsonString);
      
      if (!disposed) {
        _logAnalytics(LogLevel.info, 'Cached ${recipes.length} recipes');
      }
    } catch (e) {
      if (!disposed) {
        _logAnalytics(LogLevel.warning, 'Error caching recipes: $e');
      }
    }
  }
  
  Future<Set<String>> _loadFavoritesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(DashboardConstants.favoritesCacheKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((id) => id as String).toSet();
      }
    } catch (e) {
      _logAnalytics(LogLevel.warning, 'Error reading favorites cache: $e');
    }
    return {};
  }
  
  Future<Set<String>> _loadBookmarksFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(DashboardConstants.bookmarksCacheKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((id) => id as String).toSet();
      }
    } catch (e) {
      _logAnalytics(LogLevel.warning, 'Error reading bookmarks cache: $e');
    }
    return {};
  }
  
  Future<void> _cacheFavorites(Set<String> favoriteIds) async {
    if (disposed) {
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      if (disposed) {
        return;
      }
      
      final jsonString = jsonEncode(favoriteIds.toList());

      if (disposed) {
        return;
      }
      
      await prefs.setString(DashboardConstants.favoritesCacheKey, jsonString);
    } catch (e) {
      if (!disposed) {
        _logAnalytics(LogLevel.warning, 'Error caching favorites: $e');
      }
    }
  }
  
  Future<void> _cacheBookmarks(Set<String> bookmarkIds) async {
    if (disposed) {
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (disposed) {
        return;
      }
      
      final jsonString = jsonEncode(bookmarkIds.toList());
      
      if (disposed) {
        return;
      }
      
      await prefs.setString(DashboardConstants.bookmarksCacheKey, jsonString);
    } catch (e) {
      if (!disposed) {
        _logAnalytics(LogLevel.warning, 'Error caching bookmarks: $e');
      }
    }
  }
  
  bool _isCacheStale() {
    if (state.lastUpdated == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(state.lastUpdated!);
    return difference > DashboardConstants.cacheExpiration;
  }
  
  void _validateDataConsistency() {
    final recipeIds = state.recipes.map((recipe) => recipe.id).toSet();
    
    final validFavoriteIds = state.favoriteIds
        .where((id) => recipeIds.contains(id))
        .toSet();
        
    final validBookmarkIds = state.bookmarkIds
        .where((id) => recipeIds.contains(id))
        .toSet();
        
    if (validFavoriteIds.length != state.favoriteIds.length ||
        validBookmarkIds.length != state.bookmarkIds.length) {
      
      _logAnalytics(
        LogLevel.warning, 
        'Data inconsistency detected. Favorites: ${state.favoriteIds.length} -> ${validFavoriteIds.length}, ' +
        'Bookmarks: ${state.bookmarkIds.length} -> ${validBookmarkIds.length}'
      );
      
      state = state.copyWith(
        favoriteIds: validFavoriteIds,
        bookmarkIds: validBookmarkIds,
      );
      
      _cacheFavorites(validFavoriteIds);
      _cacheBookmarks(validBookmarkIds);
    }
  }
  
  void _logAnalytics(LogLevel level, String message) {
    if (disposed && !message.contains('disposed')) {
      return;
    }
    
    final timestamp = DateTime.now().toIso8601String();
    final logPrefix = level.toString().split('.').last.toUpperCase();
    
  }
  
  bool _safeUpdateState(void Function() updateFunction) {
    if (disposed) {
      return false;
    }
    
    try {
      updateFunction();
      return true;
    } catch (e) {
      if (disposed) {
        return false;
      } else {
        rethrow;
      }
    }
  }

  @override
  void dispose() {
    markDisposed();
    _logAnalytics(LogLevel.info, 'DashboardViewModel disposed');
    super.dispose();
  }
  
  bool get canPerformOperation => canUpdateState;
  
  Future<T?> safeOperation<T>(Future<T> Function() operation) async {
    return safeAsync(operation);
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>((ref) {
  return DashboardViewModel(
    ref.watch(favoriteRecipeProvider),
    ref.watch(bookmarkRecipeProvider),
    ref.watch(recipeProvider),
    ref,
  );
});

final favoriteRecipesProvider = Provider<List<Recipe>>((ref) {
  final state = ref.watch(dashboardProvider);
  return state.favoriteRecipes;
});

final bookmarkedRecipesProvider = Provider<List<Recipe>>((ref) {
  final state = ref.watch(dashboardProvider);
  return state.bookmarkedRecipes;
});