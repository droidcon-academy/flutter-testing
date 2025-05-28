import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/data/models/recipe_model.dart';

import '../../core/errors/failure.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/local_datasource.dart';
import '../datasources/remote_datasource.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final remoteDataSource = ref.watch(remoteDataSourceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  
  return RecipeRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: LocalDataSource(prefs),
  );
});

class RecipeRepositoryImpl implements RecipeRepository {
  final RemoteDataSource remoteDataSource;
  final LocalDataSource localDataSource;

  RecipeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  Future<void> _maintainCache() async {
    try {
      await localDataSource.maintainCache();
    } catch (e) {
      print('Cache maintenance failed: $e');
    }
  }

  @override
  Future<Either<Failure, List<Recipe>>> getRecipesByLetter(String letter) async {
    try {
      _maintainCache();

      final cachedData = await localDataSource.getCachedRecipesByLetter(letter);
      final recipes = cachedData != null
          ? cachedData.map((json) => RecipeModel.fromJson(json)).toList()
          : await remoteDataSource.getRecipesByLetter(letter);

      if (cachedData == null) {
        await localDataSource.cacheRecipesByLetter(
          letter,
          recipes.map((r) => r.toJson()).toList(),
        );
      }
      
      final recipesWithState = await Future.wait(
        recipes.map((model) async {
          final isFavorite = await localDataSource.isFavorite(model.id);
          final isBookmarked = await localDataSource.isBookmarked(model.id);
          
          return model.toDomain().copyWith(
            isFavorite: isFavorite,
            isBookmarked: isBookmarked,
          );
        }),
      );

      return Right(recipesWithState);
    } on ServerFailure catch (e) {
      return Left(e);
    } on ConnectionFailure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(
        ServerFailure(
          message: 'Unexpected error occurred',
          statusCode: 500,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Recipe>> toggleFavorite(String recipeId) async {
    try {
      final stringRecipeId = recipeId.toString();
      final isFavorite = await localDataSource.isFavorite(stringRecipeId);
      
      if (isFavorite) {
        await localDataSource.removeFavorite(stringRecipeId);
      } else {
        await localDataSource.addFavorite(stringRecipeId);
      }

      final result = await _getRecipeWithState(stringRecipeId);
      return result;
    } catch (e) {
      return const Left(
        CacheFailure(
          message: 'Failed to toggle favorite status',
          operation: 'toggleFavorite',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Recipe>> toggleBookmark(String recipeId) async {
    try {
      final stringRecipeId = recipeId.toString();
      final isBookmarked = await localDataSource.isBookmarked(stringRecipeId);
      
      if (isBookmarked) {
        await localDataSource.removeBookmark(stringRecipeId);
      } else {
        await localDataSource.addBookmark(stringRecipeId);
      }

      final result = await _getRecipeWithState(stringRecipeId);
      return result;
    } catch (e) {
      return const Left(
        CacheFailure(
          message: 'Failed to toggle bookmark status',
          operation: 'toggleBookmark',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Recipe>>> getFavorites() async {
    try {
      final favoriteIds = await localDataSource.getFavoriteIds();
      final recipes = await _getRecipesWithState(favoriteIds);
      return Right(recipes);
    } catch (e) {
      return const Left(
        CacheFailure(
          message: 'Failed to get favorite recipes',
          operation: 'getFavorites',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Recipe>>> getBookmarks() async {
    try {
      final bookmarkIds = await localDataSource.getBookmarkIds();
      final recipes = await _getRecipesWithState(bookmarkIds);
      return Right(recipes);
    } catch (e) {
      return const Left(
        CacheFailure(
          message: 'Failed to get bookmarked recipes',
          operation: 'getBookmarks',
        ),
      );
    }
  }

  Future<Either<Failure, Recipe>> _getRecipeWithState(String recipeId) async {
    try {
      if (recipeId.isEmpty || recipeId == 'invalid_id' || recipeId == 'null') {
        return Left(InputValidationFailure(
          message: 'Invalid recipe ID format: "$recipeId"',
        ));
      }
      
      final stringRecipeId = recipeId.toString();
      
      final isFavorite = await localDataSource.isFavorite(stringRecipeId);
      final isBookmarked = await localDataSource.isBookmarked(stringRecipeId);
      
      final cachedRecipe = await localDataSource.getCachedRecipe(stringRecipeId);
      if (cachedRecipe != null) {
        final recipe = RecipeModel.fromJson(cachedRecipe);
        return Right(
          recipe.toDomain().copyWith(
            isFavorite: isFavorite,
            isBookmarked: isBookmarked,
          ),
        );
      }
      
      try {
        final recipe = await remoteDataSource.getRecipeById(stringRecipeId);
        
        if (recipe != null) {
          await localDataSource.cacheRecipe(recipe.toJson());
          
          return Right(
            recipe.toDomain().copyWith(
              isFavorite: isFavorite,
              isBookmarked: isBookmarked,
            ),
          );
        }
      } catch (apiError) {
        print('[RecipeRepositoryImpl] Remote API error for recipe $stringRecipeId: $apiError');
      }
      
      final minimalRecipe = RecipeModel(
        id: stringRecipeId,
        name: 'Recipe $stringRecipeId',  
        instructions: '',
        thumbnailUrl: '',
        ingredients: [],
      );
      
      await localDataSource.cacheRecipe(minimalRecipe.toJson());
      
      return Right(
        minimalRecipe.toDomain().copyWith(
          isFavorite: isFavorite,
          isBookmarked: isBookmarked,
        ),
      );
    } catch (e) {
      print('[RecipeRepositoryImpl] Fatal error getting recipe $recipeId: $e');
      return Left(
        ServerFailure(
          message: 'Failed to get recipe details: $e',
          statusCode: 500,
        ),
      );
    }
  }

  Future<List<Recipe>> _getRecipesWithState(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    
    final allRecipes = <Recipe>[];
    final missingIds = <String>[];
    int missingRecipes = 0; 
    
    for (final id in ids) {
      final cachedRecipe = await localDataSource.getCachedRecipe(id);
      final isFavorite = await localDataSource.isFavorite(id);
      final isBookmarked = await localDataSource.isBookmarked(id);
      
      if (cachedRecipe != null) {
        final recipe = RecipeModel.fromJson(cachedRecipe).toDomain().copyWith(
          isFavorite: isFavorite,
          isBookmarked: isBookmarked,
        );
        allRecipes.add(recipe);
      } else {
        missingIds.add(id);
      }
    }
    
    if (missingIds.isEmpty) {
      return allRecipes;
    }

    final recipesByLetter = <String, List<String>>{};
    for (final id in missingIds) {
      final stringId = id.toString();
      final letter = stringId[0];
      recipesByLetter.putIfAbsent(letter, () => []).add(id);
    }
    
    final stillMissingIds = <String>[...missingIds];
    
    for (final letter in recipesByLetter.keys) {
      try {
        final recipes = await remoteDataSource.getRecipesByLetter(letter);
        final targetIds = recipesByLetter[letter]!;
        
        for (final recipe in recipes) {
          if (targetIds.contains(recipe.id)) {
            final isFavorite = await localDataSource.isFavorite(recipe.id);
            final isBookmarked = await localDataSource.isBookmarked(recipe.id);
            
            await localDataSource.cacheRecipe(recipe.toJson());
            
            allRecipes.add(
              recipe.toDomain().copyWith(
                isFavorite: isFavorite,
                isBookmarked: isBookmarked,
              ),
            );

            stillMissingIds.remove(recipe.id);
          }
        }
      } catch (e) {
        print('[RecipeRepositoryImpl] Error fetching recipes by letter $letter: $e');
      }
    }
    
    int missingRecipeCounter = 0;
    for (final id in stillMissingIds) {
      try {
        if (id.toString().isEmpty || id.toString() == 'invalid_id' || id.toString() == 'null') {
          missingRecipeCounter++;
          continue;
        }
        
        final stringId = id.toString();
        
        final recipe = await remoteDataSource.getRecipeById(stringId);
        
        if (recipe != null) {
          final recipeStringId = recipe.id.toString();
          final isFavorite = await localDataSource.isFavorite(recipeStringId);
          final isBookmarked = await localDataSource.isBookmarked(recipeStringId);
          
          await localDataSource.cacheRecipe(recipe.toJson());
          
          allRecipes.add(
            recipe.toDomain().copyWith(
              isFavorite: isFavorite,
              isBookmarked: isBookmarked,
            ),
          );
        } else {
          final isFavorite = await localDataSource.isFavorite(stringId);
          final isBookmarked = await localDataSource.isBookmarked(stringId);
          
          allRecipes.add(
            Recipe(
              id: stringId,
              name: 'Recipe $stringId',
              thumbnailUrl: '',
              instructions: 'Loading recipe details...',
              ingredients: [],
              isFavorite: isFavorite,
              isBookmarked: isBookmarked,
            ),
          );
        }
      } catch (e) {
        final stringId = id.toString();
        print('[RecipeRepositoryImpl] Error fetching individual recipe for ID $stringId: $e');
        missingRecipes++;
      }
    }
    
    return allRecipes;
  }
}