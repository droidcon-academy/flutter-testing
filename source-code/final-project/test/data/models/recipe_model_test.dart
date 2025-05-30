import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/data/models/recipe_model.dart';
import 'package:recipevault/domain/entities/recipe.dart';

void main() {
  group('RecipeModel', () {
    final Map<String, dynamic> testRecipeJson = {
      'idMeal': '12345',
      'strMeal': 'Test Recipe',
      'strInstructions': 'Test Instructions',
      'strMealThumb': 'https://example.com/thumb.jpg',
      'strIngredient1': 'Ingredient 1',
      'strMeasure1': '100g',
      'strIngredient2': 'Ingredient 2',
      'strMeasure2': '2 tbsp',
      'strIngredient3': 'Ingredient 3',
      'strMeasure3': '1 cup',
      'strIngredient4': '',
      'strMeasure4': '',
      'strIngredient5': null,
      'strMeasure5': null,
    };

    final RecipeModel expectedRecipeModel = RecipeModel(
      id: '12345',
      name: 'Test Recipe',
      instructions: 'Test Instructions',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      ingredients: const [
        IngredientModel(name: 'Ingredient 1', measure: '100g'),
        IngredientModel(name: 'Ingredient 2', measure: '2 tbsp'),
        IngredientModel(name: 'Ingredient 3', measure: '1 cup'),
      ],
      isFavorite: false,
      isBookmarked: false,
    );

    final Map<String, dynamic> minimalRecipeJson = {
      'idMeal': '12345',
      'strMeal': 'Test Recipe',
    };

    group('fromJson', () {
      test('should correctly deserialize from complete JSON', () {
        final result = RecipeModel.fromJson(testRecipeJson);

        expect(result.id, equals('12345'));
        expect(result.name, equals('Test Recipe'));
        expect(result.instructions, equals('Test Instructions'));
        expect(result.thumbnailUrl, equals('https://example.com/thumb.jpg'));
        expect(result.ingredients.length, equals(3));
        expect(result.ingredients[0].name, equals('Ingredient 1'));
        expect(result.ingredients[0].measure, equals('100g'));
        expect(result.ingredients[1].name, equals('Ingredient 2'));
        expect(result.ingredients[1].measure, equals('2 tbsp'));
        expect(result.ingredients[2].name, equals('Ingredient 3'));
        expect(result.ingredients[2].measure, equals('1 cup'));
        expect(result.isFavorite, equals(false));
        expect(result.isBookmarked, equals(false));
      });

      test('should deserialize JSON with minimal fields', () {
        final result = RecipeModel.fromJson(minimalRecipeJson);

        expect(result.id, equals('12345'));
        expect(result.name, equals('Test Recipe'));
        expect(result.instructions, isNull);
        expect(result.thumbnailUrl, isNull);
        expect(result.ingredients, isEmpty);
        expect(result.isFavorite, equals(false));
        expect(result.isBookmarked, equals(false));
      });

      test('should filter out empty and null ingredients', () {
        final json = Map<String, dynamic>.from(testRecipeJson);
        json['strIngredient3'] = '';  
        json['strIngredient2'] = null; 

        final result = RecipeModel.fromJson(json);
        expect(result.ingredients.length, equals(1));
        expect(result.ingredients[0].name, equals('Ingredient 1'));
      });

      test('should handle numeric or boolean values for fields', () {
        final json = Map<String, dynamic>.from(testRecipeJson);
        json['idMeal'] = 12345;   
        json['strMeal'] = true;   

        final result = RecipeModel.fromJson(json);
  
        expect(result.id, equals('12345'));  
        expect(result.name, equals('true'));  
      });

      test('should throw FormatException for missing idMeal', () {
        final json = Map<String, dynamic>.from(testRecipeJson);
        json.remove('idMeal');

        expect(() => RecipeModel.fromJson(json), throwsA(isA<FormatException>()));
      });

      test('should throw FormatException for missing strMeal', () {
        final json = Map<String, dynamic>.from(testRecipeJson);
        json.remove('strMeal');

        expect(() => RecipeModel.fromJson(json), throwsA(isA<FormatException>()));
      });

      test('should throw FormatException for empty idMeal', () {
        final json = Map<String, dynamic>.from(testRecipeJson);
        json['idMeal'] = '';

        expect(() => RecipeModel.fromJson(json), throwsA(isA<FormatException>()));
      });

      test('should throw FormatException for empty strMeal', () {
        final json = Map<String, dynamic>.from(testRecipeJson);
        json['strMeal'] = '';

        expect(() => RecipeModel.fromJson(json), throwsA(isA<FormatException>()));
      });

      test('should handle all 20 possible ingredients', () {
        final json = <String, dynamic>{
          'idMeal': '12345',
          'strMeal': 'Test Recipe',
        };
        
        for (int i = 1; i <= 20; i++) {
          json['strIngredient$i'] = 'Ingredient $i';
          json['strMeasure$i'] = 'Measure $i';
        }

        final result = RecipeModel.fromJson(json);

        expect(result.ingredients.length, equals(20));
        for (int i = 0; i < 20; i++) {
          expect(result.ingredients[i].name, equals('Ingredient ${i + 1}'));
          expect(result.ingredients[i].measure, equals('Measure ${i + 1}'));
        }
      });

      test('should trim whitespace from ingredient names and measures', () {
        final json = Map<String, dynamic>.from(minimalRecipeJson);
        json['strIngredient1'] = '  Flour  ';
        json['strMeasure1'] = '  200g  ';
        final result = RecipeModel.fromJson(json);

        expect(result.ingredients.length, equals(1));
        expect(result.ingredients[0].name, equals('Flour'));
        expect(result.ingredients[0].measure, equals('200g'));
      });
    });

    group('toJson', () {
      test('should correctly serialize to JSON', () {
        final json = expectedRecipeModel.toJson();

        expect(json['idMeal'], equals('12345'));
        expect(json['strMeal'], equals('Test Recipe'));
        expect(json['strInstructions'], equals('Test Instructions'));
        expect(json['strMealThumb'], equals('https://example.com/thumb.jpg'));
        expect(json['ingredients'], isA<List>());
        expect(json['ingredients'].length, equals(3));
        expect(json['ingredients'][0]['name'], equals('Ingredient 1'));
        expect(json['ingredients'][0]['measure'], equals('100g'));
        expect(json['isFavorite'], equals(false));
        expect(json['isBookmarked'], equals(false));
      });

      test('should handle null instructions and thumbnailUrl', () {
        final recipeModel = RecipeModel(
          id: '12345',
          name: 'Test Recipe',
          instructions: null,
          thumbnailUrl: null,
          ingredients: const [],
        );

        final json = recipeModel.toJson();

        expect(json['idMeal'], equals('12345'));
        expect(json['strMeal'], equals('Test Recipe'));
        expect(json['strInstructions'], isNull);
        expect(json['strMealThumb'], isNull);
      });
    });

    group('toDomain', () {
      test('should correctly convert to domain entity', () {
        final domainEntity = expectedRecipeModel.toDomain();

        expect(domainEntity, isA<Recipe>());
        expect(domainEntity.id, equals('12345'));
        expect(domainEntity.name, equals('Test Recipe'));
        expect(domainEntity.instructions, equals('Test Instructions'));
        expect(domainEntity.thumbnailUrl, equals('https://example.com/thumb.jpg'));
        expect(domainEntity.ingredients.length, equals(3));
        expect(domainEntity.ingredients[0].name, equals('Ingredient 1'));
        expect(domainEntity.ingredients[0].measure, equals('100g'));
        expect(domainEntity.isFavorite, equals(false));
        expect(domainEntity.isBookmarked, equals(false));
      });

      test('should convert null fields to empty strings in domain entity', () {
        final recipeModel = RecipeModel(
          id: '12345',
          name: 'Test Recipe',
          instructions: null,
          thumbnailUrl: null,
        );

        final domainEntity = recipeModel.toDomain();

        expect(domainEntity.instructions, equals(''));
        expect(domainEntity.thumbnailUrl, equals(''));
      });

      test('should properly convert ingredient models to domain ingredients', () {
        const ingredientModel = IngredientModel(
          name: 'Sugar',
          measure: null,
        );
        final domainIngredient = ingredientModel.toDomain();

        expect(domainIngredient.name, equals('Sugar'));
        expect(domainIngredient.measure, equals(''));
      });
    });

    group('IngredientModel', () {
      test('should correctly deserialize from JSON', () {
        final json = {
          'name': 'Salt',
          'measure': '1 tsp',
        };
        final result = IngredientModel.fromJson(json);

        expect(result.name, equals('Salt'));
        expect(result.measure, equals('1 tsp'));
      });

      test('should correctly serialize to JSON', () {
        const ingredient = IngredientModel(
          name: 'Sugar',
          measure: '2 tbsp',
        );
        final json = ingredient.toJson();

        expect(json['name'], equals('Sugar'));
        expect(json['measure'], equals('2 tbsp'));
      });

      test('should handle null measure in JSON', () {
        final json = {
          'name': 'Pepper',
          'measure': null,
        };
        final result = IngredientModel.fromJson(json);

        expect(result.name, equals('Pepper'));
        expect(result.measure, isNull);
      });
    });

    group('Edge Cases', () {
      test('should handle unusually long ingredient lists', () {
        final json = Map<String, dynamic>.from(minimalRecipeJson);
        for (int i = 1; i <= 30; i++) {
          json['strIngredient$i'] = 'Ingredient $i';
          json['strMeasure$i'] = 'Measure $i';
        }
        final result = RecipeModel.fromJson(json);

        expect(result.ingredients.length, equals(20));
      });

      test('should handle unusual field values', () {
        final json = Map<String, dynamic>.from(minimalRecipeJson);
        json['strInstructions'] = List.filled(1000, 'a').join(); 
        json['strIngredient1'] = List.filled(100, 'b').join(); 

        final result = RecipeModel.fromJson(json);

        expect(result.instructions?.length, equals(1000));
        expect(result.ingredients[0].name.length, equals(100));
      });

      test('should handle JSON with mismatched ingredient/measure indices', () {
        final json = Map<String, dynamic>.from(minimalRecipeJson);
        json['strMeasure7'] = '3 cups';
        final result = RecipeModel.fromJson(json);

        expect(result.ingredients, isEmpty);
      });

      test('should handle empty ingredients list', () {
        final json = Map<String, dynamic>.from(minimalRecipeJson);
        for (int i = 1; i <= 20; i++) {
          json['strIngredient$i'] = '';
          json['strMeasure$i'] = '';
        }

        final result = RecipeModel.fromJson(json);

        expect(result.ingredients, isEmpty);
      });

      test('should handle measures without ingredients', () {
        final json = Map<String, dynamic>.from(minimalRecipeJson);
        json['strMeasure1'] = '1 cup';

        final result = RecipeModel.fromJson(json);

        expect(result.ingredients, isEmpty);
      });
    });
      
    group('IngredientModel', () {
      test('should correctly deserialize from JSON', () {
        final json = {
          'name': 'Salt',
          'measure': '1 tsp'
        };
        
        final result = IngredientModel.fromJson(json);
        
        expect(result.name, equals('Salt'));
        expect(result.measure, equals('1 tsp'));
      });
      
      test('should correctly serialize to JSON', () {
        const ingredient = IngredientModel(name: 'Pepper', measure: '2 tbsp');
        
        final json = ingredient.toJson();
        
        expect(json['name'], equals('Pepper'));
        expect(json['measure'], equals('2 tbsp'));
      });
      
      test('should correctly convert to domain entity', () {
        const ingredient = IngredientModel(name: 'Garlic', measure: '3 cloves');
        
        final domainEntity = ingredient.toDomain();
        
        expect(domainEntity, isA<Ingredient>());
        expect(domainEntity.name, equals('Garlic'));
        expect(domainEntity.measure, equals('3 cloves'));
      });
      
      test('should convert null measure to empty string in domain entity', () {
        const ingredient = IngredientModel(name: 'Onion', measure: null);
        
        final domainEntity = ingredient.toDomain();
        
        expect(domainEntity.measure, equals(''));
      });
    });
    
    group('RecipeModel - Edge Cases', () {
      test('should handle extremely long strings', () {
        final longString = 'a' * 10000;
        final json = {
          'idMeal': '12345',
          'strMeal': 'Test Recipe',
          'strInstructions': longString,
          'strIngredient1': longString,
          'strMeasure1': longString
        };
        
        final result = RecipeModel.fromJson(json);
        
        expect(result.instructions, equals(longString));
        expect(result.ingredients[0].name, equals(longString));
        expect(result.ingredients[0].measure, equals(longString));
      });
      
      test('should preserve whitespace in the middle of text', () {
        final json = {
          'idMeal': '12345',
          'strMeal': 'Test Recipe',
          'strIngredient1': 'Black  Pepper',
          'strMeasure1': '1/2  tsp'
        };
        
        final result = RecipeModel.fromJson(json);
        
        expect(result.ingredients[0].name, equals('Black  Pepper'));
        expect(result.ingredients[0].measure, equals('1/2  tsp'));
      });
      
      test('should handle unusual but valid input combinations', () {
        final json = {
          'idMeal': '0',
          'strMeal': ' Just Spaces ',
          'strIngredient1': '0',      
          'strMeasure1': '-'         
        };
        
        final result = RecipeModel.fromJson(json);
        
        expect(result.id, equals('0'));
        expect(result.name, equals(' Just Spaces '));
        expect(result.ingredients[0].name, equals('0'));
        expect(result.ingredients[0].measure, equals('-'));
      });
      
      test('should test error handling in the try/catch block', () {
        final invalidJson = <String, dynamic>{
          'idMeal': '12345',
          'strMeal': 'Test Recipe',
          'ingredients': 'not a list but should be'
        };
        
        final result = RecipeModel.fromJson(invalidJson);
        
        expect(result.id, equals('12345'));
        expect(result.name, equals('Test Recipe'));
      });
      
      test('should handle more than 20 ingredients if API structure changes', () {
        final json = <String, dynamic>{
          'idMeal': '12345',
          'strMeal': 'Test Recipe',
        };
        
        for (int i = 1; i <= 30; i++) {
          json['strIngredient$i'] = 'Ingredient $i';
          json['strMeasure$i'] = 'Measure $i';
        }
        
        final result = RecipeModel.fromJson(json);
        
        expect(result.ingredients.length, equals(20));
        expect(result.ingredients[19].name, equals('Ingredient 20'));
      });
    });
  });
}