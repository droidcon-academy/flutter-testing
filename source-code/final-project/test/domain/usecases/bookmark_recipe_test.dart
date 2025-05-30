import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/errors/failure.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/repositories/recipe_repository.dart';
import 'package:recipevault/domain/usecases/bookmark_recipe.dart';

class MockRecipeRepository extends Mock implements RecipeRepository {}

void main() {
  late BookmarkRecipe usecase;
  late MockRecipeRepository mockRepository;

  const testRecipeId = '123';
  const testParams = BookmarkRecipeParams(recipeId: testRecipeId);
  const testRecipe = Recipe(
    id: testRecipeId,
    name: 'Test Recipe',
    isBookmarked: true,
    ingredients: [
      Ingredient(name: 'Ingredient 1', measure: '1 cup'),
    ],
  );
  final testBookmarkedRecipes = [
    const Recipe(
      id: '123',
      name: 'Test Recipe 1',
      isBookmarked: true,
      ingredients: [
        Ingredient(name: 'Ingredient 1', measure: '1 cup'),
      ],
    ),
    const Recipe(
      id: '456',
      name: 'Test Recipe 2',
      isBookmarked: true,
      ingredients: [
        Ingredient(name: 'Ingredient 2', measure: '2 cups'),
      ],
    ),
  ];

  setUp(() {
    mockRepository = MockRecipeRepository();
    usecase = BookmarkRecipe(mockRepository);
  });

  group('BookmarkRecipe call', () {
    test('should toggle bookmark status through the repository', () async {
      when(() => mockRepository.toggleBookmark(testRecipeId))
          .thenAnswer((_) async => const Right(testRecipe));

      final result = await usecase(testParams);

      expect(result, const Right(testRecipe));
      verify(() => mockRepository.toggleBookmark(testRecipeId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return a ServerFailure when the repository fails', () async {
      const failure = ServerFailure(message: 'Server error', statusCode: 500);
      when(() => mockRepository.toggleBookmark(testRecipeId))
          .thenAnswer((_) async => const Left(failure));
      final result = await usecase(testParams);

      expect(result, const Left(failure));
      verify(() => mockRepository.toggleBookmark(testRecipeId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle non-existent recipe ID gracefully', () async {
      const nonExistentParams = BookmarkRecipeParams(recipeId: 'non-existent');
      const failure = InputValidationFailure(message: 'Recipe not found');
      
      when(() => mockRepository.toggleBookmark('non-existent'))
          .thenAnswer((_) async => const Left(failure));

      final result = await usecase(nonExistentParams);

      expect(result.isLeft(), true);
      expect(result, const Left(failure));
      verify(() => mockRepository.toggleBookmark('non-existent')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should handle empty recipe ID gracefully', () async {
      const emptyIdParams = BookmarkRecipeParams(recipeId: '');
      const failure = InputValidationFailure(message: 'Recipe ID cannot be empty');
      
      when(() => mockRepository.toggleBookmark(''))
          .thenAnswer((_) async => const Left(failure));

      final result = await usecase(emptyIdParams);

      expect(result, const Left(failure));
      verify(() => mockRepository.toggleBookmark('')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('getBookmarks', () {
    test('should get all bookmarked recipes from the repository', () async {
      when(() => mockRepository.getBookmarks())
          .thenAnswer((_) async => Right(testBookmarkedRecipes));

      final result = await usecase.getBookmarks();

      expect(result, Right(testBookmarkedRecipes));
      verify(() => mockRepository.getBookmarks()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return a failure when the repository fails', () async {
      const failure = ServerFailure(message: 'Server error', statusCode: 500);
      when(() => mockRepository.getBookmarks())
          .thenAnswer((_) async => const Left(failure));
      final result = await usecase.getBookmarks();

      expect(result, const Left(failure));
      verify(() => mockRepository.getBookmarks()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should handle empty bookmarks list gracefully', () async {
      when(() => mockRepository.getBookmarks())
          .thenAnswer((_) async => const Right(<Recipe>[]));

      final result = await usecase.getBookmarks();
      expect(
        result.getOrElse((failure) => []).isEmpty,
        true,
        reason: "Expected empty list when no bookmarks are found",
      );
      verify(() => mockRepository.getBookmarks()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should handle cache failures gracefully', () async {
      const failure = CacheFailure(
        message: 'Failed to retrieve bookmarks', 
        operation: 'getBookmarks'
      );
      
      when(() => mockRepository.getBookmarks())
          .thenAnswer((_) async => const Left(failure));

      final result = await usecase.getBookmarks();

      expect(result.isLeft(), true);
      expect(result, const Left(failure));
      verify(() => mockRepository.getBookmarks()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should handle concurrent bookmark operations correctly', () async {
      when(() => mockRepository.getBookmarks())
          .thenAnswer((_) async => Right(testBookmarkedRecipes));
          
      when(() => mockRepository.toggleBookmark(testRecipeId))
          .thenAnswer((_) async => const Right(testRecipe));

      final toggleResult = await usecase(testParams);
      final getBookmarksResult = await usecase.getBookmarks();

      expect(toggleResult, const Right(testRecipe));
      expect(getBookmarksResult, Right(testBookmarkedRecipes));
      
      verify(() => mockRepository.toggleBookmark(testRecipeId)).called(1);
      verify(() => mockRepository.getBookmarks()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should handle connection failures when fetching bookmarks', () async {
      const failure = ConnectionFailure(message: 'No internet connection');
      when(() => mockRepository.getBookmarks())
          .thenAnswer((_) async => const Left(failure));
      final result = await usecase.getBookmarks();

      expect(result.isLeft(), true);
      expect(result, const Left(failure));
      verify(() => mockRepository.getBookmarks()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
  
  group('Additional validation tests', () {
    test('should handle invalid characters in recipe ID', () async {
      const invalidIdParams = BookmarkRecipeParams(recipeId: 'id@with#invalid!chars');
      const failure = InputValidationFailure(message: 'Recipe ID contains invalid characters');
      
      when(() => mockRepository.toggleBookmark('id@with#invalid!chars'))
          .thenAnswer((_) async => const Left(failure));

      final result = await usecase(invalidIdParams);

      expect(result.isLeft(), true);
      expect(result, const Left(failure));
      verify(() => mockRepository.toggleBookmark('id@with#invalid!chars')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should handle extremely long recipe ID', () async {
      final longId = 'a' * 1000; 
      final longIdParams = BookmarkRecipeParams(recipeId: longId);
      const failure = InputValidationFailure(message: 'Recipe ID exceeds maximum length');
      
      when(() => mockRepository.toggleBookmark(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await usecase(longIdParams);

      expect(result.isLeft(), true);
      expect(result, const Left(failure));
      verify(() => mockRepository.toggleBookmark(longId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
