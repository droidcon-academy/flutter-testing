// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeModel _$RecipeModelFromJson(Map<String, dynamic> json) => RecipeModel(
      id: json['idMeal'] as String,
      name: json['strMeal'] as String,
      instructions: json['strInstructions'] as String?,
      thumbnailUrl: json['strMealThumb'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => IngredientModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isFavorite: json['isFavorite'] as bool,
      isBookmarked: json['isBookmarked'] as bool,
    );

Map<String, dynamic> _$RecipeModelToJson(RecipeModel instance) =>
    <String, dynamic>{
      'idMeal': instance.id,
      'strMeal': instance.name,
      'strInstructions': instance.instructions,
      'strMealThumb': instance.thumbnailUrl,
      'ingredients': instance.ingredients,
      'isFavorite': instance.isFavorite,
      'isBookmarked': instance.isBookmarked,
    };


Map<String, dynamic> _$IngredientModelToJson(IngredientModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'measure': instance.measure,
    };

_$IngredientModelImpl _$$IngredientModelImplFromJson(
        Map<String, dynamic> json) =>
    _$IngredientModelImpl(
      name: json['name'] as String,
      measure: json['measure'] as String?,
    );

Map<String, dynamic> _$$IngredientModelImplToJson(
        _$IngredientModelImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'measure': instance.measure,
    };
