import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/data/repositories/recipe_repository_impl.dart';

import '../../core/errors/failure.dart';
import '../entities/recipe.dart';
import '../repositories/recipe_repository.dart';

final bookmarkRecipeProvider = Provider<BookmarkRecipe>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return BookmarkRecipe(repository);
});

class BookmarkRecipeParams {
  final String recipeId;

  const BookmarkRecipeParams({required this.recipeId});
}

class BookmarkRecipe {
  final RecipeRepository _repository;

  BookmarkRecipe(this._repository);

  Future<Either<Failure, Recipe>> call(BookmarkRecipeParams params) {
    return _repository.toggleBookmark(params.recipeId);
  }

  Future<Either<Failure, List<Recipe>>> getBookmarks() {
    return _repository.getBookmarks();
  }
}