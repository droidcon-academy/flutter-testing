import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/domain/entities/recipe.dart';

void main() {
  group('Recipe Entity', () {
    const ingredient1 = Ingredient(name: 'Sugar', measure: '1 cup');
    const ingredient2 = Ingredient(name: 'Flour', measure: '2 cups');
    const ingredientNoMeasure = Ingredient(name: 'Salt');
    
    const basicRecipe = Recipe(
      id: '1',
      name: 'Chocolate Cake',
      ingredients: [ingredient1, ingredient2],
    );

    group('Creation and equality', () {
      test('should create Recipe with required properties', () {
        const recipe = Recipe(
          id: '1',
          name: 'Chocolate Cake',
          ingredients: [ingredient1, ingredient2],
        );

        expect(recipe.id, '1');
        expect(recipe.name, 'Chocolate Cake');
        expect(recipe.ingredients.length, 2);
        expect(recipe.ingredients[0], ingredient1);
        expect(recipe.ingredients[1], ingredient2);
      });

      test('should create Recipe with all properties', () {
        const recipe = Recipe(
          id: '1',
          name: 'Chocolate Cake',
          instructions: 'Mix and bake at 350F',
          thumbnailUrl: 'https://example.com/cake.jpg',
          ingredients: [ingredient1, ingredient2],
          isFavorite: true,
          isBookmarked: true,
        );

        expect(recipe.id, '1');
        expect(recipe.name, 'Chocolate Cake');
        expect(recipe.instructions, 'Mix and bake at 350F');
        expect(recipe.thumbnailUrl, 'https://example.com/cake.jpg');
        expect(recipe.ingredients.length, 2);
        expect(recipe.isFavorite, true);
        expect(recipe.isBookmarked, true);
      });

      test('should consider two recipes with same properties as equal', () {
        const recipe1 = Recipe(
          id: '1',
          name: 'Chocolate Cake',
          instructions: 'Mix and bake',
          ingredients: [ingredient1, ingredient2],
        );

        const recipe2 = Recipe(
          id: '1',
          name: 'Chocolate Cake',
          instructions: 'Mix and bake',
          ingredients: [ingredient1, ingredient2],
        );

        expect(recipe1, equals(recipe2));
        expect(recipe1.hashCode, equals(recipe2.hashCode));
      });

      test('should consider recipes with different properties as not equal', () {
        const recipe1 = Recipe(
          id: '1',
          name: 'Chocolate Cake',
          ingredients: [ingredient1, ingredient2],
        );

        const recipe2 = Recipe(
          id: '2',
          name: 'Chocolate Cake',
          ingredients: [ingredient1, ingredient2],
        );

        expect(recipe1, isNot(equals(recipe2)));
      });

      test('should create Recipe with empty ingredients list', () {
        const recipe = Recipe(
          id: '1',
          name: 'Empty Recipe',
          ingredients: [],
        );

        expect(recipe.ingredients, isEmpty);
      });
      
      test('should handle empty strings for text fields', () {
        const recipe = Recipe(
          id: '',
          name: '',
          instructions: '',
          thumbnailUrl: '',
          ingredients: [ingredient1],
        );

        expect(recipe.id, '');
        expect(recipe.name, '');
        expect(recipe.instructions, '');
        expect(recipe.thumbnailUrl, '');
      });
    });

    group('Default properties', () {
      test('should have default value false for isFavorite', () {
        const recipe = basicRecipe;
        expect(recipe.isFavorite, false);
      });

      test('should have default value false for isBookmarked', () {
        const recipe = basicRecipe;
        expect(recipe.isBookmarked, false);
      });

      test('should override default values when specified', () {
        const recipe = Recipe(
          id: '1',
          name: 'Favorite Recipe',
          ingredients: [ingredient1],
          isFavorite: true,
          isBookmarked: true,
        );

        expect(recipe.isFavorite, true);
        expect(recipe.isBookmarked, true);
      });
      
      test('should handle null for optional fields', () {
        const recipe = Recipe(
          id: '1',
          name: 'Minimal Recipe',
          instructions: null,
          thumbnailUrl: null,
          ingredients: [ingredient1],
        );

        expect(recipe.instructions, isNull);
        expect(recipe.thumbnailUrl, isNull);
      });
    });

    group('Ingredient handling', () {
      test('should store Ingredient objects correctly', () {
        const recipe = Recipe(
          id: '1',
          name: 'Test Recipe',
          ingredients: [ingredient1, ingredient2],
        );

        expect(recipe.ingredients[0].name, 'Sugar');
        expect(recipe.ingredients[0].measure, '1 cup');
        expect(recipe.ingredients[1].name, 'Flour');
        expect(recipe.ingredients[1].measure, '2 cups');
      });

      test('should handle Ingredient with missing measure', () {
        const recipe = Recipe(
          id: '1',
          name: 'Test Recipe',
          ingredients: [ingredientNoMeasure],
        );

        expect(recipe.ingredients[0].name, 'Salt');
        expect(recipe.ingredients[0].measure, isNull);
      });
      
      test('should correctly compare ingredients for equality', () {
        const ingredient1a = Ingredient(name: 'Sugar', measure: '1 cup');
        const ingredient1b = Ingredient(name: 'Sugar', measure: '1 cup');
        const ingredient2 = Ingredient(name: 'Sugar', measure: '2 cups');
        expect(ingredient1a, equals(ingredient1b));
        expect(ingredient1a, isNot(equals(ingredient2)));
      });
      
      test('should correctly handle complex recipes with many ingredients', () {
        final manyIngredients = List.generate(
          10, 
          (index) => Ingredient(
            name: 'Ingredient $index', 
            measure: index % 2 == 0 ? '$index cups' : null
          )
        );
        
        final recipe = Recipe(
          id: '1',
          name: 'Complex Recipe',
          ingredients: manyIngredients,
        );
        
        expect(recipe.ingredients.length, 10);
        expect(recipe.ingredients[0].measure, '0 cups');
        expect(recipe.ingredients[1].measure, isNull);
      });
    });
    
    group('CopyWith functionality', () {
      test('should copy with new values correctly', () {
        const original = basicRecipe;
        
        final updated = original.copyWith(
          name: 'Updated Recipe',
          isFavorite: true,
        );
        
        expect(updated.id, original.id); 
        expect(updated.name, 'Updated Recipe'); 
        expect(updated.ingredients, original.ingredients); 
        expect(updated.isFavorite, true); 
        expect(updated.isBookmarked, original.isBookmarked);
      });
      
      test('should copy with new ingredients correctly', () {
        const original = basicRecipe;
        const newIngredients = [Ingredient(name: 'New Ingredient')];
        
        final updated = original.copyWith(
          ingredients: newIngredients,
        );
        
        expect(updated.ingredients, newIngredients);
        expect(updated.ingredients.length, 1);
        expect(updated.ingredients[0].name, 'New Ingredient');
      });
      
      test('should be able to copy all properties at once', () {
        const original = basicRecipe;
        const newIngredients = [Ingredient(name: 'New Ingredient')];
        
        final updated = original.copyWith(
          id: '999',
          name: 'Completely New Recipe',
          instructions: 'New instructions',
          thumbnailUrl: 'https://new-image.jpg',
          ingredients: newIngredients,
          isFavorite: true,
          isBookmarked: true,
        );
        
        expect(updated.id, '999');
        expect(updated.name, 'Completely New Recipe');
        expect(updated.instructions, 'New instructions');
        expect(updated.thumbnailUrl, 'https://new-image.jpg');
        expect(updated.ingredients, newIngredients);
        expect(updated.isFavorite, true);
        expect(updated.isBookmarked, true);
      });
    });
    
    group('Immutability verification', () {
      test('should not allow modifying properties after creation', () {
        const recipe = Recipe(
          id: '1',
          name: 'Test Recipe',
          ingredients: [ingredient1, ingredient2],
        );
        
        final updatedRecipe = recipe.copyWith(name: 'New Name');
        
        expect(recipe.name, 'Test Recipe');
        expect(updatedRecipe.name, 'New Name');
        expect(identical(recipe, updatedRecipe), isFalse);
      });
      
      test('should preserve ingredient list immutability', () {
        const recipe = Recipe(
          id: '1',
          name: 'Test Recipe',
          ingredients: [ingredient1, ingredient2],
        );
        
        expect(() => recipe.ingredients.add(ingredientNoMeasure), throwsUnsupportedError);
        expect(() => recipe.ingredients.removeAt(0), throwsUnsupportedError);
        expect(() => recipe.ingredients.clear(), throwsUnsupportedError);
      });
    });
    
    group('Empty and null collections handling', () {
      test('should handle null ingredients list (converted to empty list)', () {
        const recipe = Recipe(
          id: '1',
          name: 'No Ingredients',
          ingredients: [], 
        );
        
        expect(recipe.ingredients, isNotNull);
        expect(recipe.ingredients, isEmpty);
      });
      
      test('should preserve empty list in copyWith', () {
        const recipe = basicRecipe;
        
        final updatedRecipe = recipe.copyWith(ingredients: const []);
        
        expect(updatedRecipe.ingredients, isNotNull);
        expect(updatedRecipe.ingredients, isEmpty);
      });
    });
    
    group('Optional field behavior', () {
      test('should distinguish between null and empty string', () {
        const recipeWithNull = Recipe(
          id: '1',
          name: 'Test Recipe',
          instructions: null,
          thumbnailUrl: null,
          ingredients: [ingredient1],
        );
        
        const recipeWithEmpty = Recipe(
          id: '1',
          name: 'Test Recipe',
          instructions: '',
          thumbnailUrl: '',
          ingredients: [ingredient1],
        );
        
        expect(recipeWithNull.instructions, isNull);
        expect(recipeWithNull.thumbnailUrl, isNull);
        
        expect(recipeWithEmpty.instructions, isNotNull);
        expect(recipeWithEmpty.instructions, isEmpty);
        expect(recipeWithEmpty.thumbnailUrl, isNotNull);
        expect(recipeWithEmpty.thumbnailUrl, isEmpty);
        
        expect(recipeWithNull, isNot(equals(recipeWithEmpty)));
      });
      
      test('should handle null to empty string conversion in copyWith', () {
        const recipeWithNull = Recipe(
          id: '1',
          name: 'Test Recipe',
          instructions: null,
          ingredients: [ingredient1],
        );
        
        final withEmptyString = recipeWithNull.copyWith(instructions: '');
        final backToNull = withEmptyString.copyWith(instructions: null);
        
        expect(withEmptyString.instructions, isEmpty);
        expect(backToNull.instructions, isNull);
      });
    });
    
    group('Value equality and hash code consistency', () {
      test('should use value equality rather than reference equality', () {
        const recipe1 = Recipe(
          id: '1',
          name: 'Test Recipe',
          instructions: 'Test',
          ingredients: [ingredient1, ingredient2],
        );
        
        final recipe2 = Recipe(
          id: '1',
          name: 'Test Recipe',
          instructions: 'Test',
          ingredients: [ingredient1, ingredient2],
        );
        
        final recipe3 = recipe1; 

        expect(identical(recipe1, recipe2), isFalse); 
        expect(identical(recipe1, recipe3), isTrue); 
        
        expect(recipe1 == recipe2, isTrue); 
        expect(recipe1 == recipe3, isTrue); 
      });
      
      test('should maintain hash code consistency with equality', () {
        const recipe1 = Recipe(
          id: '1',
          name: 'Test Recipe',
          ingredients: [ingredient1, ingredient2],
          isFavorite: true,
        );
        
        const recipe2 = Recipe(
          id: '1',
          name: 'Test Recipe',
          ingredients: [ingredient1, ingredient2],
          isFavorite: true,
        );
        
        const recipe3 = Recipe(
          id: '1',
          name: 'Different Recipe', 
          ingredients: [ingredient1, ingredient2],
          isFavorite: true,
        );
        
        expect(recipe1.hashCode, equals(recipe2.hashCode));
        expect(recipe1.hashCode, isNot(equals(recipe3.hashCode)));
        
        expect(recipe1 == recipe2, isTrue); 
        expect(recipe1.hashCode == recipe2.hashCode, isTrue); 
        
        expect(recipe1 == recipe3, isFalse); 
        expect(recipe1.hashCode == recipe3.hashCode, isFalse); 
      });
      
      test('should work correctly in collections using hash code', () {
        const recipe1 = Recipe(
          id: '1',
          name: 'Test Recipe',
          ingredients: [ingredient1],
        );
        
        const recipe2 = Recipe(
          id: '1',
          name: 'Test Recipe',
          ingredients: [ingredient1],
        );
        
        const recipe3 = Recipe(
          id: '2',  
          name: 'Test Recipe',
          ingredients: [ingredient1],
        );
        
        final recipeSet = <Recipe>{};
        recipeSet.add(recipe1);
        recipeSet.add(recipe2); 
        recipeSet.add(recipe3);
        
        final recipeMap = <Recipe, String>{};
        recipeMap[recipe1] = 'First recipe';
        recipeMap[recipe2] = 'Should overwrite first recipe'; 
        recipeMap[recipe3] = 'Different recipe';
        
        expect(recipeSet.length, 2); 
        expect(recipeMap.length, 2); 
        expect(recipeMap[recipe1], 'Should overwrite first recipe'); 
        expect(recipeMap[recipe2], 'Should overwrite first recipe'); 
      });
    });
  });
  
  group('Ingredient Entity', () {
    test('should create Ingredient with required name', () {
      const ingredient = Ingredient(name: 'Sugar');
      
      expect(ingredient.name, 'Sugar');
      expect(ingredient.measure, isNull);
    });
    
    test('should create Ingredient with name and measure', () {
      const ingredient = Ingredient(name: 'Sugar', measure: '1 cup');
      
      expect(ingredient.name, 'Sugar');
      expect(ingredient.measure, '1 cup');
    });
    
    test('should consider ingredients with same properties as equal', () {
      const ingredient1 = Ingredient(name: 'Sugar', measure: '1 cup');
      const ingredient2 = Ingredient(name: 'Sugar', measure: '1 cup');
      
      expect(ingredient1, equals(ingredient2));
      expect(ingredient1.hashCode, equals(ingredient2.hashCode));
    });
    
    test('should handle empty strings for measure', () {
      const ingredient = Ingredient(name: 'Sugar', measure: '');
      
      expect(ingredient.measure, '');
    });
    
    test('should copy with new values correctly', () {
      const original = Ingredient(name: 'Sugar');
      
      final updated = original.copyWith(measure: '2 cups');
      
      expect(updated.name, original.name);
      expect(updated.measure, '2 cups');
    });
  });
}
