import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/recipe.dart';

part 'recipe_model.freezed.dart';
part 'recipe_model.g.dart';

@freezed
class RecipeModel with _$RecipeModel {
  const RecipeModel._(); 

  factory RecipeModel({
    required String id,
    required String name,
    String? instructions,
    String? thumbnailUrl,
    @Default([]) List<IngredientModel> ingredients,
    @Default(false) bool isFavorite,
    @Default(false) bool isBookmarked,
  }) = _RecipeModel;

  Map<String, dynamic> toJson() {
    return {
      'idMeal': id,
      'strMeal': name,
      'strInstructions': instructions,
      'strMealThumb': thumbnailUrl,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'isFavorite': isFavorite,
      'isBookmarked': isBookmarked,
    };
  }

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['idMeal'];
      final name = json['strMeal'];
      
      if (id == null) {
        throw FormatException('Missing idMeal in recipe data');
      }
      
      final String stringId = id is String ? id : id.toString();
      if (stringId.isEmpty) {
        throw FormatException('Invalid empty idMeal in recipe data');
      }
      
      if (name == null) {
        throw FormatException('Missing strMeal in recipe data');
      }
      
      final String stringName = name is String ? name : name.toString();
      if (stringName.isEmpty) {
        throw FormatException('Invalid empty strMeal in recipe data');
      }
      
      final ingredients = <Map<String, dynamic>>[];
      for (int i = 1; i <= 20; i++) {
        final ingredient = json['strIngredient$i'];
        final measure = json['strMeasure$i'];
        
        if (ingredient != null && 
            ingredient.toString().trim().isNotEmpty) {
          ingredients.add({
            'name': ingredient.toString().trim(),
            'measure': measure != null ? measure.toString().trim() : '',
          });
        }
      }

      final transformedJson = <String, dynamic>{
        'idMeal': stringId, 
        'strMeal': stringName, 
        'strInstructions': json['strInstructions'] != null ? json['strInstructions'].toString() : null,
        'strMealThumb': json['strMealThumb'] != null ? json['strMealThumb'].toString() : null,
        'ingredients': ingredients,
        'isFavorite': false,
        'isBookmarked': false,
      };

      return _$RecipeModelFromJson(transformedJson);
    } catch (e) {
      print('Error parsing recipe data: $e');
      print('Problematic JSON: $json');
      rethrow; 
    }
  }

  Recipe toDomain() => Recipe(
        id: id,
        name: name,
        instructions: instructions ?? '',
        thumbnailUrl: thumbnailUrl ?? '',
        ingredients: ingredients
            .map((ingredient) => ingredient.toDomain())
            .toList(),
        isFavorite: isFavorite,
        isBookmarked: isBookmarked,
      );
}

@freezed
@JsonSerializable()
class IngredientModel with _$IngredientModel {
  const IngredientModel._(); 

  const factory IngredientModel({
    required String name,
    String? measure,
  }) = _IngredientModel;

  factory IngredientModel.fromJson(Map<String, dynamic> json) =>
      _$IngredientModelFromJson(json);

  Map<String, dynamic> toJson() => _$IngredientModelToJson(this);

  Ingredient toDomain() => Ingredient(
        name: name,
        measure: measure ?? '',
      );
}