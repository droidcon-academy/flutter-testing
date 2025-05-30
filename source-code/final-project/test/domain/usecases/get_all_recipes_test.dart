import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/errors/failure.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/repositories/recipe_repository.dart';
import 'package:recipevault/domain/usecases/get_all_recipes.dart';

class MockRecipeRepository extends Mock implements RecipeRepository {}

void main() {
  late GetAllRecipes usecase;
  late MockRecipeRepository mockRepository;

  final testLetter = 'A';
  final testParams = GetAllRecipesParams(letter: testLetter);
  final testRecipes = [
    Recipe(
      id: '1',
      name: 'Apple Pie',
      ingredients: [
        const Ingredient(name: 'Apples', measure: '4 cups'),
        const Ingredient(name: 'Sugar', measure: '1 cup'),
      ],
    ),
    Recipe(
      id: '2',
      name: 'Avocado Toast',
      ingredients: [
        const Ingredient(name: 'Avocado', measure: '1'),
        const Ingredient(name: 'Bread', measure: '2 slices'),
      ],
    ),
  ];

  setUp(() {
    mockRepository = MockRecipeRepository();
    usecase = GetAllRecipes(mockRepository);
  });

  group('GetAllRecipes', () {
    test('should get recipes by letter from the repository', () async {
      when(() => mockRepository.getRecipesByLetter(testLetter))
          .thenAnswer((_) async => Right(testRecipes));

      final result = await usecase(testParams);

      expect(result, Right(testRecipes));
      verify(() => mockRepository.getRecipesByLetter(testLetter)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return a ServerFailure when there is a server error', () async {
      final failure = ServerFailure(message: 'Server error', statusCode: 500);
      when(() => mockRepository.getRecipesByLetter(testLetter))
          .thenAnswer((_) async => Left(failure));

      final result = await usecase(testParams);

      expect(result, Left(failure));
      verify(() => mockRepository.getRecipesByLetter(testLetter)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle empty result gracefully', () async {
      when(() => mockRepository.getRecipesByLetter(testLetter))
          .thenAnswer((_) async => const Right(<Recipe>[]));

      final result = await usecase(testParams);

      expect(
        result.getOrElse((failure) => []).isEmpty,
        true,
        reason: "Expected empty list when no recipes are found",
      );
      verify(() => mockRepository.getRecipesByLetter(testLetter)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle invalid letter parameter gracefully', () async {
      final invalidParams = GetAllRecipesParams(letter: '');
      final failure = InputValidationFailure(message: 'Invalid letter parameter');
      
      when(() => mockRepository.getRecipesByLetter(''))
          .thenAnswer((_) async => Left(failure));

      final result = await usecase(invalidParams);

      expect(result.isLeft(), true);
      expect(result, Left(failure));
      verify(() => mockRepository.getRecipesByLetter('')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle non-alphabet character parameter gracefully', () async {
      final specialCharParams = GetAllRecipesParams(letter: '#');
      final failure = InputValidationFailure(message: 'Invalid character: only alphabets are allowed');
      
      when(() => mockRepository.getRecipesByLetter('#'))
          .thenAnswer((_) async => Left(failure));

      final result = await usecase(specialCharParams);

      expect(result.isLeft(), true);
      expect(result, Left(failure));
      verify(() => mockRepository.getRecipesByLetter('#')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should filter recipes by different letters correctly', () async {
      final bLetter = 'B';
      final bParams = GetAllRecipesParams(letter: bLetter);
      final bRecipes = [
        Recipe(
          id: '3',
          name: 'Banana Bread',
          ingredients: [
            const Ingredient(name: 'Bananas', measure: '3'),
            const Ingredient(name: 'Flour', measure: '2 cups'),
          ],
        ),
      ];
      
      when(() => mockRepository.getRecipesByLetter(bLetter))
          .thenAnswer((_) async => Right(bRecipes));

      final result = await usecase(bParams);

      expect(result, Right(bRecipes));
      verify(() => mockRepository.getRecipesByLetter(bLetter)).called(1);
    });
    
    test('should handle cache failure gracefully', () async {
      final failure = CacheFailure(
        message: 'Error accessing local storage',
        operation: 'getRecipesByLetter'
      );
      
      when(() => mockRepository.getRecipesByLetter(testLetter))
          .thenAnswer((_) async => Left(failure));

      final result = await usecase(testParams);

      expect(result.isLeft(), true);
      expect(result, Left(failure));
      verify(() => mockRepository.getRecipesByLetter(testLetter)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should handle multi-letter input parameter gracefully', () async {
      final multiLetterParams = GetAllRecipesParams(letter: 'ABC');
      final failure = InputValidationFailure(
        message: 'Invalid input: only single letters are allowed'
      );
      
      when(() => mockRepository.getRecipesByLetter('ABC'))
          .thenAnswer((_) async => Left(failure));

      final result = await usecase(multiLetterParams);

      expect(result.isLeft(), true);
      expect(result, Left(failure));
      verify(() => mockRepository.getRecipesByLetter('ABC')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should handle network connectivity issues', () async {
      final failure = ConnectionFailure(
        message: 'No internet connection'
      );
      
      when(() => mockRepository.getRecipesByLetter(testLetter))
          .thenAnswer((_) async => Left(failure));

      final result = await usecase(testParams);

      expect(result.isLeft(), true);
      expect(result, Left(failure));
      verify(() => mockRepository.getRecipesByLetter(testLetter)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
