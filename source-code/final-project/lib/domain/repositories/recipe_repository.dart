import 'package:fpdart/fpdart.dart';
import '../../core/errors/failure.dart';
import '../entities/recipe.dart';

abstract class RecipeRepository {
  Future<Either<Failure, List<Recipe>>> getRecipesByLetter(String letter);

  Future<Either<Failure, Recipe>> toggleFavorite(String recipeId);

  Future<Either<Failure, Recipe>> toggleBookmark(String recipeId);

  Future<Either<Failure, List<Recipe>>> getFavorites();

  Future<Either<Failure, List<Recipe>>> getBookmarks();
}