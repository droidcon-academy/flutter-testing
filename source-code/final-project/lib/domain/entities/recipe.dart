import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe.freezed.dart';

@freezed
class Recipe with _$Recipe {
  const factory Recipe({
    required String id,
    required String name,
    String? instructions,
    String? thumbnailUrl,
    required List<Ingredient> ingredients,
    @Default(false) bool isFavorite,
    @Default(false) bool isBookmarked,
  }) = _Recipe;
}

@freezed
class Ingredient with _$Ingredient {
  const factory Ingredient({
    required String name,
    String? measure,
  }) = _Ingredient;
}