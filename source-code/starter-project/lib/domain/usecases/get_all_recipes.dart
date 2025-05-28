import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/data/repositories/recipe_repository_impl.dart';

import '../../core/errors/failure.dart';
import '../entities/recipe.dart';
import '../repositories/recipe_repository.dart';

final getAllRecipesProvider = Provider<GetAllRecipes>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return GetAllRecipes(repository);
});

class GetAllRecipesParams {
  final String letter;

  const GetAllRecipesParams({required this.letter});
}

class GetAllRecipes {
  final RecipeRepository _repository;

  GetAllRecipes(this._repository);

  Future<Either<Failure, List<Recipe>>> call(GetAllRecipesParams params) {
    return _repository.getRecipesByLetter(params.letter);
  }
}