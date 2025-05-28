import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/data/repositories/recipe_repository_impl.dart';

import '../../core/errors/failure.dart';
import '../entities/recipe.dart';
import '../repositories/recipe_repository.dart';

final favoriteRecipeProvider = Provider<FavoriteRecipe>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return FavoriteRecipe(repository);
});

class FavoriteRecipeParams {
  final String recipeId;

  const FavoriteRecipeParams({required this.recipeId});
}

class FavoriteRecipe {
  final RecipeRepository _repository;

  FavoriteRecipe(this._repository);

  Future<Either<Failure, Recipe>> call(FavoriteRecipeParams params) {
    return _repository.toggleFavorite(params.recipeId);
  }

  Future<Either<Failure, List<Recipe>>> getFavorites() {
    return _repository.getFavorites();
  }
}