import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/errors/failure.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/repositories/recipe_repository.dart';
import 'package:recipevault/domain/usecases/favorite_recipe.dart';

class MockRecipeRepository extends Mock implements RecipeRepository {}

void main() {
  late FavoriteRecipe usecase;
  late MockRecipeRepository mockRepository;

  final testRecipeId = '123';
  final testParams = FavoriteRecipeParams(recipeId: testRecipeId);
  final testRecipe = Recipe(
    id: testRecipeId,
    name: 'Test Recipe',
    isFavorite: true,
    ingredients: [
      const Ingredient(name: 'Ingredient 1', measure: '1 cup'),
    ],
  );
  final testFavoriteRecipes = [
    Recipe(
      id: '123',
      name: 'Test Recipe 1',
      isFavorite: true,
      ingredients: [
        const Ingredient(name: 'Ingredient 1', measure: '1 cup'),
      ],
    ),
    Recipe(
      id: '456',
      name: 'Test Recipe 2',
      isFavorite: true,
      ingredients: [
        const Ingredient(name: 'Ingredient 2', measure: '2 cups'),
      ],
    ),
  ];

  setUp(() {
    mockRepository = MockRecipeRepository();
    usecase = FavoriteRecipe(mockRepository);
  });

  group('FavoriteRecipe call', () {
    test('should toggle favorite status through the repository', () async {
      when(() => mockRepository.toggleFavorite(testRecipeId))
          .thenAnswer((_) async => Right(testRecipe));

      final result = await usecase(testParams);

      expect(result, Right(testRecipe));
      verify(() => mockRepository.toggleFavorite(testRecipeId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return a ServerFailure when the repository fails', () async {
      final failure = ServerFailure(message: 'Server error', statusCode: 500);
      when(() => mockRepository.toggleFavorite(testRecipeId))
          .thenAnswer((_) async => Left(failure));
      final result = await usecase(testParams);

      expect(result, Left(failure));
      verify(() => mockRepository.toggleFavorite(testRecipeId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle non-existent recipe ID gracefully', () async {
      final nonExistentParams = FavoriteRecipeParams(recipeId: 'non-existent');
      final failure = InputValidationFailure(message: 'Recipe not found');
      
      when(() => mockRepository.toggleFavorite('non-existent'))
          .thenAnswer((_) async => Left(failure));

      final result = await usecase(nonExistentParams);

      expect(result.isLeft(), true);
      expect(result, Left(failure));
      verify(() => mockRepository.toggleFavorite('non-existent')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should handle empty recipe ID gracefully', () async {
      final emptyIdParams = FavoriteRecipeParams(recipeId: '');
      final failure = InputValidationFailure(message: 'Recipe ID cannot be empty');
      
      when(() => mockRepository.toggleFavorite(''))
          .thenAnswer((_) async => Left(failure));

      final result = await usecase(emptyIdParams);

      expect(result, Left(failure));
      verify(() => mockRepository.toggleFavorite('')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('getFavorites', () {
    test('should get all favorite recipes from the repository', () async {
      when(() => mockRepository.getFavorites())
          .thenAnswer((_) async => Right(testFavoriteRecipes));

      final result = await usecase.getFavorites();
      expect(result, Right(testFavoriteRecipes));
      verify(() => mockRepository.getFavorites()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return a failure when the repository fails', () async {
      final failure = ServerFailure(message: 'Server error', statusCode: 500);
      when(() => mockRepository.getFavorites())
          .thenAnswer((_) async => Left(failure));
      final result = await usecase.getFavorites();

      expect(result, Left(failure));
      verify(() => mockRepository.getFavorites()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should handle empty favorites list gracefully', () async {
      when(() => mockRepository.getFavorites())
          .thenAnswer((_) async => const Right(<Recipe>[]));

      final result = await usecase.getFavorites();
      expect(
        result.getOrElse((failure) => []).isEmpty,
        true,
        reason: "Expected empty list when no favorites are found",
      );
      verify(() => mockRepository.getFavorites()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should handle concurrent favorite operations correctly', () async {
      when(() => mockRepository.getFavorites())
          .thenAnswer((_) async => Right(testFavoriteRecipes));
          
      when(() => mockRepository.toggleFavorite(testRecipeId))
          .thenAnswer((_) async => Right(testRecipe));

      final toggleResult = await usecase(testParams);
      final getFavoritesResult = await usecase.getFavorites();

      expect(toggleResult, Right(testRecipe));
      expect(getFavoritesResult, Right(testFavoriteRecipes));
      
      verify(() => mockRepository.toggleFavorite(testRecipeId)).called(1);
      verify(() => mockRepository.getFavorites()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should handle connection failures when fetching favorites', () async {
      final failure = ConnectionFailure(message: 'No internet connection');
      when(() => mockRepository.getFavorites())
          .thenAnswer((_) async => Left(failure));

      final result = await usecase.getFavorites();

      expect(result.isLeft(), true);
      expect(result, Left(failure));
      verify(() => mockRepository.getFavorites()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
  
  group('Additional validation tests', () {
    test('should handle invalid characters in recipe ID', () async {
      final invalidIdParams = FavoriteRecipeParams(recipeId: 'id@with#invalid!chars');
      final failure = InputValidationFailure(message: 'Recipe ID contains invalid characters');
      
      when(() => mockRepository.toggleFavorite('id@with#invalid!chars'))
          .thenAnswer((_) async => Left(failure));

      final result = await usecase(invalidIdParams);

      expect(result.isLeft(), true);
      expect(result, Left(failure));
      verify(() => mockRepository.toggleFavorite('id@with#invalid!chars')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should handle extremely long recipe ID', () async {
      final longId = 'a' * 1000;
      final longIdParams = FavoriteRecipeParams(recipeId: longId);
      final failure = InputValidationFailure(message: 'Recipe ID exceeds maximum length');
      
      when(() => mockRepository.toggleFavorite(longId))
          .thenAnswer((_) async => Left(failure));

      final result = await usecase(longIdParams);

      expect(result.isLeft(), true);
      expect(result, Left(failure));
      verify(() => mockRepository.toggleFavorite(longId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
