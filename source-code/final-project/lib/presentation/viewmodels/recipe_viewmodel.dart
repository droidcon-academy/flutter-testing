import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/usecases/bookmark_recipe.dart';
import '../../domain/usecases/favorite_recipe.dart';
import '../../domain/usecases/get_all_recipes.dart';

class RecipeState {
  final List<Recipe> recipes;
  final String? selectedLetter;
  final Set<String> favoriteIds;
  final Set<String> bookmarkIds;
  final bool isLoading;
  final String? error;
  final Recipe? selectedRecipe;

  const RecipeState({
    this.recipes = const [],
    this.selectedLetter,
    this.favoriteIds = const {},
    this.bookmarkIds = const {},
    this.isLoading = false,
    this.error,
    this.selectedRecipe,
  });

  RecipeState copyWith({
    List<Recipe>? recipes,
    String? selectedLetter,
    Set<String>? favoriteIds,
    Set<String>? bookmarkIds,
    bool? isLoading,
    String? error,
    Recipe? selectedRecipe,
  }) {
    return RecipeState(
      recipes: recipes ?? this.recipes,
      selectedLetter: selectedLetter ?? this.selectedLetter,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      bookmarkIds: bookmarkIds ?? this.bookmarkIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,  
      selectedRecipe: selectedRecipe ?? this.selectedRecipe,
    );
  }

  List<Recipe> get filteredRecipes {
    if (selectedLetter == null) return recipes;
    return recipes
        .where((recipe) =>
            recipe.name.toLowerCase().startsWith(selectedLetter!.toLowerCase()))
        .toList();
  }

  List<Recipe> get favoriteRecipes {
    return recipes.where((recipe) => favoriteIds.contains(recipe.id)).toList();
  }

  List<Recipe> get bookmarkedRecipes {
    return recipes.where((recipe) => bookmarkIds.contains(recipe.id)).toList();
  }
}

class RecipeViewModel extends StateNotifier<RecipeState> {
  final GetAllRecipes _getAllRecipes;
  final FavoriteRecipe _favoriteRecipe;
  final BookmarkRecipe _bookmarkRecipe;

  RecipeViewModel(
    this._getAllRecipes,
    this._favoriteRecipe,
    this._bookmarkRecipe,
  ) : super(const RecipeState()) {
    initializeData();
  }
  
  Future<void> initializeData() async {
    await loadRecipes();
    
    await loadFavorites();
    
    await loadBookmarks();
  }

  Future<void> loadRecipes() async {
    if (state.selectedLetter == null) {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final result = await _getAllRecipes(const GetAllRecipesParams(letter: ''));
      
      result.fold(
        (failure) => state = state.copyWith(
          error: failure.message,
          isLoading: false,
        ),
        (recipes) => state = state.copyWith(
          recipes: recipes,
          isLoading: false,
        ),
      );
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getAllRecipes(
      GetAllRecipesParams(letter: state.selectedLetter!),
    );
    
    result.fold(
      (failure) => state = state.copyWith(
        error: failure.message,
        isLoading: false,
      ),
      (recipes) => state = state.copyWith(
        recipes: recipes,
        isLoading: false,
      ),
    );
  }

  Future<void> loadFavorites() async {
    final result = await _favoriteRecipe.getFavorites();
    result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
      },
      (recipes) {
        final favoriteIds = recipes.map((r) => r.id).toSet();
        state = state.copyWith(favoriteIds: favoriteIds);
      },
    );
  }

  Future<void> loadBookmarks() async {
    final result = await _bookmarkRecipe.getBookmarks();
    result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
      },
      (recipes) {
        final bookmarkIds = recipes.map((r) => r.id).toSet();
        state = state.copyWith(bookmarkIds: bookmarkIds);
      },
    );
  }

  void setSelectedLetter(String? letter) {
    if (letter == state.selectedLetter) return;
    state = state.copyWith(
      selectedLetter: letter,
      error: null,
    );
    loadRecipes();
  }

  void setSelectedRecipe(Recipe? recipe) {
    if (recipe?.id == state.selectedRecipe?.id) return;
    state = state.copyWith(
      selectedRecipe: recipe,
      error: null,
    );
  }

  bool _disposed = false;
  
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeUpdateState(RecipeState Function(RecipeState) updater) {
    if (!_disposed) {
      state = updater(state);
    } else {
      print('[RecipeViewModel] Skipping state update. ViewModel already disposed');
    }
  }
  
  Future<void> toggleFavorite(String recipeId) async {
    final stringRecipeId = recipeId.toString();
    
    final newFavorites = Set<String>.from(state.favoriteIds);
    final wasAdded = !newFavorites.contains(stringRecipeId);
    
    if (wasAdded) {
      newFavorites.add(stringRecipeId);
    } else {
      newFavorites.remove(stringRecipeId);
    }

    Recipe? updatedSelectedRecipe = state.selectedRecipe;
    if (state.selectedRecipe != null && state.selectedRecipe!.id == stringRecipeId) {
      updatedSelectedRecipe = state.selectedRecipe!.copyWith(
        isFavorite: wasAdded,
      );
    }

    final updatedRecipes = state.recipes.map((recipe) {
      if (recipe.id == recipeId) {
        return recipe.copyWith(isFavorite: wasAdded);
      }
      return recipe;
    }).toList();

    _safeUpdateState((currentState) => currentState.copyWith(
      favoriteIds: newFavorites,
      selectedRecipe: updatedSelectedRecipe,
      recipes: updatedRecipes,
      error: null,
    ));
    
    if (_disposed) {
      return;
    }
    
    final result = await _favoriteRecipe(FavoriteRecipeParams(recipeId: stringRecipeId));
    
    result.fold(
      (failure) {
        if (_disposed) {
          return;
        }
        
        final revertedFavorites = Set<String>.from(state.favoriteIds);
        if (wasAdded) {
          revertedFavorites.remove(stringRecipeId);
        } else {
          revertedFavorites.add(stringRecipeId);
        }

        Recipe? revertedSelectedRecipe = state.selectedRecipe;
        if (state.selectedRecipe != null && state.selectedRecipe!.id == stringRecipeId) {
          revertedSelectedRecipe = state.selectedRecipe!.copyWith(
            isFavorite: !wasAdded,
          );
        }

        final revertedRecipes = state.recipes.map((recipe) {
          if (recipe.id == stringRecipeId) {
            return recipe.copyWith(isFavorite: !wasAdded);
          }
          return recipe;
        }).toList();

        _safeUpdateState((currentState) => currentState.copyWith(
          favoriteIds: revertedFavorites,
          selectedRecipe: revertedSelectedRecipe,
          recipes: revertedRecipes,
          error: failure.message,
        ));
      },
      (_) {
      }
    );
  }

  Future<void> toggleBookmark(String recipeId) async {
    final stringRecipeId = recipeId.toString();
    
    final newBookmarks = Set<String>.from(state.bookmarkIds);
    final wasAdded = !newBookmarks.contains(stringRecipeId);
    
    
    if (wasAdded) {
      newBookmarks.add(stringRecipeId);
    } else {
      newBookmarks.remove(stringRecipeId);
    }

    Recipe? updatedSelectedRecipe = state.selectedRecipe;
    if (state.selectedRecipe != null && state.selectedRecipe!.id == stringRecipeId) {
      updatedSelectedRecipe = state.selectedRecipe!.copyWith(
        isBookmarked: wasAdded,
      );
    }

    final updatedRecipes = state.recipes.map((recipe) {
      if (recipe.id == stringRecipeId) {
        return recipe.copyWith(isBookmarked: wasAdded);
      }
      return recipe;
    }).toList();

    _safeUpdateState((currentState) => currentState.copyWith(
      bookmarkIds: newBookmarks,
      selectedRecipe: updatedSelectedRecipe,
      recipes: updatedRecipes,
      error: null,
    ));
    
    if (_disposed) {
      return;
    }
    
    final result = await _bookmarkRecipe(BookmarkRecipeParams(recipeId: stringRecipeId));
    
    result.fold(
      (failure) {
        if (_disposed) {
          return;
        }

        final revertedBookmarks = Set<String>.from(state.bookmarkIds);
        if (wasAdded) {
          revertedBookmarks.remove(stringRecipeId);
        } else {
          revertedBookmarks.add(stringRecipeId);
        }

        Recipe? revertedSelectedRecipe = state.selectedRecipe;
        if (state.selectedRecipe != null && state.selectedRecipe!.id == stringRecipeId) {
          revertedSelectedRecipe = state.selectedRecipe!.copyWith(
            isBookmarked: !wasAdded,
          );
        }

        final revertedRecipes = state.recipes.map((recipe) {
          if (recipe.id == stringRecipeId) {
            return recipe.copyWith(isBookmarked: !wasAdded);
          }
          return recipe;
        }).toList();

        _safeUpdateState((currentState) => currentState.copyWith(
          bookmarkIds: revertedBookmarks,
          selectedRecipe: revertedSelectedRecipe,
          recipes: revertedRecipes,
          error: failure.message,
        ));
      },
      (_) {
      }
    );
  }

  bool isFavorite(String recipeId) => state.favoriteIds.contains(recipeId.toString());
  
  bool isBookmarked(String recipeId) => state.bookmarkIds.contains(recipeId.toString());
}

final recipeProvider =
    StateNotifierProvider<RecipeViewModel, RecipeState>((ref) {
  return RecipeViewModel(
    ref.watch(getAllRecipesProvider),
    ref.watch(favoriteRecipeProvider),
    ref.watch(bookmarkRecipeProvider),
  );
});

final filteredRecipesProvider = Provider<List<Recipe>>((ref) {
  final state = ref.watch(recipeProvider);
  return state.filteredRecipes;
});

final favoriteRecipesProvider = Provider<List<Recipe>>((ref) {
  final state = ref.watch(recipeProvider);
  return state.favoriteRecipes;
});

final bookmarkedRecipesProvider = Provider<List<Recipe>>((ref) {
  final state = ref.watch(recipeProvider);
  return state.bookmarkedRecipes;
});