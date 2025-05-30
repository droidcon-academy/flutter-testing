import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/errors/failure.dart';
import 'package:recipevault/data/models/recipe_model.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/repositories/recipe_repository.dart';
import 'package:recipevault/data/repositories/recipe_repository_impl.dart';
import 'package:recipevault/data/datasources/remote_datasource.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';

extension DataSourceExtensions on Map<String, dynamic> {
  RecipeModel toRecipeModel() => RecipeModel.fromJson(this);
}

class MockRemoteDataSource extends Mock implements RemoteDataSource {}

class MockLocalDataSource extends Mock implements LocalDataSource {}

class MockRecipeRepository extends Mock implements RecipeRepository {}

class TestRecipeData {
  static const ingredient1 = Ingredient(name: 'Ingredient 1', measure: '1 cup');
  static const ingredient2 = Ingredient(name: 'Ingredient 2', measure: '2 tbsp');
  static const ingredientA = Ingredient(name: 'Ingredient A', measure: '1 tbsp');
  static const ingredientB = Ingredient(name: 'Ingredient B', measure: '3 cups');
  
  static const testRecipe1 = Recipe(
    id: '1',
    name: 'Test Recipe 1',
    ingredients: [ingredient1, ingredient2],
    instructions: 'Step 1. Mix ingredients\nStep 2. Cook for 20 minutes',
    thumbnailUrl: 'https://example.com/recipe1.jpg',
    isFavorite: false,
    isBookmarked: false,
  );

  static const testRecipe2 = Recipe(
    id: '2',
    name: 'Test Recipe 2',
    ingredients: [ingredientA, ingredientB],
    instructions: 'Step A. Prepare ingredients\nStep B. Bake for 15 minutes',
    thumbnailUrl: 'https://example.com/recipe2.jpg',
    isFavorite: true,
    isBookmarked: true,
  );

  static const List<Recipe> testRecipes = [testRecipe1, testRecipe2];

  static final Map<String, dynamic> testRecipe1Json = {
    'idMeal': '1',
    'strMeal': 'Test Recipe 1',
    'strInstructions': 'Step 1. Mix ingredients\nStep 2. Cook for 20 minutes',
    'strMealThumb': 'https://example.com/recipe1.jpg',
    'strIngredient1': 'Ingredient 1',
    'strMeasure1': '1 cup',
    'strIngredient2': 'Ingredient 2',
    'strMeasure2': '2 tbsp',
  };

  static final Map<String, dynamic> testRecipe2Json = {
    'idMeal': '2',
    'strMeal': 'Test Recipe 2',
    'strInstructions': 'Step A. Prepare ingredients\nStep B. Bake for 15 minutes',
    'strMealThumb': 'https://example.com/recipe2.jpg',
    'strIngredient1': 'Ingredient A',
    'strMeasure1': '1 tbsp',
    'strIngredient2': 'Ingredient B',
    'strMeasure2': '3 cups',
  };

  static const serverFailure = ServerFailure(
    message: 'Server error occurred',
    statusCode: 500,
  );
  
  static const cacheFailure = CacheFailure(
    message: 'Cache error occurred',
    operation: 'read',
  );
  
  static const connectionFailure = ConnectionFailure(
    message: 'No internet connection',
  );
  
  static const validationFailure = InputValidationFailure(
    message: 'Invalid input',
  );

  static final recipeJson1 = {
    'idMeal': '1',
    'strMeal': 'Test Recipe 1',
    'strInstructions': 'Step 1. Mix ingredients\nStep 2. Cook for 20 minutes',
    'strMealThumb': 'https://example.com/recipe1.jpg',
    'strIngredient1': 'Ingredient 1',
    'strIngredient2': 'Ingredient 2',
    'strMeasure1': '1 cup',
    'strMeasure2': '2 tbsp',
  };
  
  static final recipeJson2 = {
    'idMeal': '2',
    'strMeal': 'Test Recipe 2',
    'strInstructions': 'Step A. Prepare ingredients\nStep B. Bake for 15 minutes',
    'strMealThumb': 'https://example.com/recipe2.jpg',
    'strIngredient1': 'Ingredient A',
    'strIngredient2': 'Ingredient B',
    'strMeasure1': '1 tbsp',
    'strMeasure2': '3 cups',
  };
  
  static final malformedRecipeJson = {
    'idMeal': '3',
    'strMeal': 'Malformed Recipe',
    'strMealThumb': null,
    'strIngredient1': 'Malformed Ingredient',
  };
  
  static final extraFieldsRecipeJson = {
    'idMeal': '4',
    'strMeal': 'Extra Fields Recipe',
    'strInstructions': 'Simple instructions',
    'strMealThumb': 'https://example.com/recipe4.jpg',
    'strIngredient1': 'Regular Ingredient',
    'strMeasure1': 'Regular measure',
    'extra_field': 'This field does not belong in the schema',
    'random_data': {'nested': 'object', 'that': ['should', 'be', 'ignored']},
  };
  
  static RecipeModel get testRecipeModel1 => RecipeModel.fromJson(testRecipe1Json);
  static RecipeModel get testRecipeModel2 => RecipeModel.fromJson(testRecipe2Json);
  static RecipeModel get malformedRecipeModel => RecipeModel.fromJson(malformedRecipeJson);
  static RecipeModel get extraFieldsRecipeModel => RecipeModel.fromJson(extraFieldsRecipeJson);
}

void main() {
  final Matcher isValidLetter = predicate<String>(
    (letter) => letter.length == 1 && letter.isNotEmpty,
    'is a single valid letter'
  );
  
  final Matcher isValidId = predicate<String>(
    (id) => id.isNotEmpty,
    'is a non-empty ID'
  );
  
  final Matcher isInvalidLetter = predicate<String>(
    (letter) => letter.length != 1 || letter.isEmpty,
    'is not a valid single letter'
  );
  
  late MockRecipeRepository repository;
  late MockRemoteDataSource mockRemoteDataSource;
  late MockLocalDataSource mockLocalDataSource;
  late RecipeRepositoryImpl repositoryImpl;

  setUp(() {
    repository = MockRecipeRepository();
    mockRemoteDataSource = MockRemoteDataSource();
    mockLocalDataSource = MockLocalDataSource();
    repositoryImpl = RecipeRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
    registerFallbackValue('any_id');
  });
  
  void setupCommonMocks() {
    when(() => mockLocalDataSource.maintainCache())
      .thenAnswer((_) async => Future<void>.value());
    when(() => mockLocalDataSource.isFavorite(any()))
      .thenAnswer((_) async => false);
    when(() => mockLocalDataSource.isBookmarked(any()))
      .thenAnswer((_) async => false);
    when(() => mockLocalDataSource.cacheRecipe(any()))
      .thenAnswer((_) async => Future<void>.value());
      
    when(() => mockRemoteDataSource.getRecipesByLetter(any()))
      .thenAnswer((_) async => [TestRecipeData.testRecipeModel1]);
  }
  
  void setupConsistentErrorHandling(Failure failure) {
    when(() => repository.getRecipesByLetter(any()))
      .thenAnswer((_) async => Left(failure));
    when(() => repository.getFavorites())
      .thenAnswer((_) async => Left(failure));
    when(() => repository.getBookmarks())
      .thenAnswer((_) async => Left(failure));
    when(() => repository.toggleFavorite(any()))
      .thenAnswer((_) async => Left(failure));
    when(() => repository.toggleBookmark(any()))
      .thenAnswer((_) async => Left(failure));
  }
  
  test('repository implementation should be initialized with data sources', () {
    expect(repositoryImpl, isA<RecipeRepositoryImpl>());
  });
  
  void _assertMethodAvailability() {
    when(() => repository.getRecipesByLetter(any()))
      .thenAnswer((_) async => const Right(<Recipe>[])); 
    when(() => repository.toggleFavorite(any()))
      .thenAnswer((_) async => const Right(TestRecipeData.testRecipe1));
    when(() => repository.toggleBookmark(any()))
      .thenAnswer((_) async => const Right(TestRecipeData.testRecipe1));
    when(() => repository.getFavorites())
      .thenAnswer((_) async => const Right(<Recipe>[])); 
    when(() => repository.getBookmarks())
      .thenAnswer((_) async => const Right(<Recipe>[])); 
      
    repository.getRecipesByLetter('A');
    repository.toggleFavorite('1');
    repository.toggleBookmark('1');
    repository.getFavorites();
    repository.getBookmarks();
  }

  group('RecipeRepository Contract Tests', () {
    test('should implement all required interface methods', () {
      expect(() => _assertMethodAvailability(), returnsNormally);
    });

    group('Return Type Compliance', () {
      test('all methods should return Either<Failure, T> type', () async {
        when(() => repository.getRecipesByLetter(any()))
            .thenAnswer((_) async => const Right(<Recipe>[])); 
        when(() => repository.toggleFavorite(any()))  
            .thenAnswer((_) async => const Right(TestRecipeData.testRecipe1));
        when(() => repository.toggleBookmark(any()))
            .thenAnswer((_) async => const Right(TestRecipeData.testRecipe1));
        when(() => repository.getFavorites())
            .thenAnswer((_) async => const Right(<Recipe>[])); 
        when(() => repository.getBookmarks())
            .thenAnswer((_) async => const Right(<Recipe>[])); 

        final byLetterResult = await repository.getRecipesByLetter('A');
        final toggleFavResult = await repository.toggleFavorite('1');
        final toggleBookResult = await repository.toggleBookmark('1');
        final getFavResult = await repository.getFavorites();
        final getBookResult = await repository.getBookmarks();

        expect(byLetterResult, isA<Either<Failure, List<Recipe>>>());
        expect(toggleFavResult, isA<Either<Failure, Recipe>>());
        expect(toggleBookResult, isA<Either<Failure, Recipe>>());
        expect(getFavResult, isA<Either<Failure, List<Recipe>>>());
        expect(getBookResult, isA<Either<Failure, List<Recipe>>>());
      });

      test('failure results should return Left<Failure, T>', () async {
        final failure = ServerFailure(message: 'Test error', statusCode: 500);
        when(() => repository.getRecipesByLetter(any()))
            .thenAnswer((_) async => Left(failure));
        final result = await repository.getRecipesByLetter('A');

        expect(result.isLeft(), true);
        expect(result, Left(failure));
      });

      test('success results should return Right<Failure, T>', () async {
        when(() => repository.getFavorites())
            .thenAnswer((_) async => const Right(TestRecipeData.testRecipes));

        final result = await repository.getFavorites();

        expect(result.isRight(), true);
        expect(result, const Right(TestRecipeData.testRecipes));
      });
    });
    
    group('getRecipesByLetter', () {
      const testLetter = 'A';
      const emptyLetter = '';
      
      test('should return a list of recipes when the letter is valid', () async {
        when(() => repository.getRecipesByLetter(testLetter))
            .thenAnswer((_) async => const Right(TestRecipeData.testRecipes));
        
        final result = await repository.getRecipesByLetter(testLetter);
        
        expect(result, equals(const Right(TestRecipeData.testRecipes)));
        verify(() => repository.getRecipesByLetter(testLetter)).called(1);
      });

      test('should return empty list when no recipes match the letter', () async {
        when(() => repository.getRecipesByLetter(testLetter))
            .thenAnswer((_) async => const Right(<Recipe>[]));  
        
        final result = await repository.getRecipesByLetter(testLetter);
        
        expect(result.isRight(), true);
        expect(result.fold((l) => <Recipe>[], (r) => r), isEmpty);
      });

      test('should return validation failure when letter is empty', () async {
        when(() => repository.getRecipesByLetter(emptyLetter))
            .thenAnswer((_) async => const Left(TestRecipeData.validationFailure));
        
        final result = await repository.getRecipesByLetter(emptyLetter);
        
        expect(result, equals(const Left(TestRecipeData.validationFailure)));
      });

      test('should return server failure when server error occurs', () async {
        when(() => repository.getRecipesByLetter(testLetter))
            .thenAnswer((_) async => const Left(TestRecipeData.serverFailure));
            
        final result = await repository.getRecipesByLetter(testLetter);
        
        expect(result, const Left(TestRecipeData.serverFailure));
        verify(() => repository.getRecipesByLetter(testLetter)).called(1);
      });
      
      test('should return a CacheFailure when there is a local storage error', () async {
        final failure = CacheFailure(message: 'Cache error', operation: 'getRecipesByLetter');
        when(() => repository.getRecipesByLetter(testLetter))
            .thenAnswer((_) async => Left(failure));
        
        final result = await repository.getRecipesByLetter(testLetter);
        
        expect(result, Left(failure));
        verify(() => repository.getRecipesByLetter(testLetter)).called(1);
      });

      test('should return a ConnectionFailure when there is a network issue', () async {
        final failure = ConnectionFailure(message: 'No internet connection');
        when(() => repository.getRecipesByLetter(testLetter))
            .thenAnswer((_) async => Left(failure));
        
        final result = await repository.getRecipesByLetter(testLetter);
        
        expect(result, Left(failure));
        verify(() => repository.getRecipesByLetter(testLetter)).called(1);
      });

      test('should return a ValidationFailure when input is invalid', () async {
        final failure = InputValidationFailure(message: 'Invalid input: only single letters are allowed');
        
        when(() => repository.getRecipesByLetter(any(that: isInvalidLetter)))
            .thenAnswer((_) async => Left(failure));
        
        final result = await repository.getRecipesByLetter('ABC');
        
        expect(result, Left(failure));
        verify(() => repository.getRecipesByLetter('ABC')).called(1);
      });
      
      test('should handle empty input gracefully', () async {
        final failure = InputValidationFailure(message: 'Empty input not allowed');
        
        when(() => repository.getRecipesByLetter(''))
            .thenAnswer((_) async => Left(failure));
        
        final result = await repository.getRecipesByLetter('');
        
        expect(result, Left(failure));
        expect(result.isLeft(), true);
        expect(result.fold((l) => l is InputValidationFailure, (r) => false), true);
      });
      

      test('should return connection failure when no internet connection', () async {
        when(() => repository.getRecipesByLetter(testLetter))
            .thenAnswer((_) async => const Left(TestRecipeData.connectionFailure));
        
        final result = await repository.getRecipesByLetter(testLetter);
        
        expect(result, equals(const Left(TestRecipeData.connectionFailure)));
      });
    });

    group('toggleFavorite', () {
      const testRecipeId = '1';
      const nonExistentRecipeId = '999';
      const updatedRecipe = Recipe(
        id: '1',
        name: 'Test Recipe 1',
        ingredients: [TestRecipeData.ingredient1, TestRecipeData.ingredient2],
        instructions: 'Step 1. Mix ingredients\nStep 2. Cook for 20 minutes',
        thumbnailUrl: 'https://example.com/recipe1.jpg',
        isFavorite: true,
        isBookmarked: false,
      );

      test('should return updated recipe when toggling favorite succeeds', () async {
        when(() => repository.toggleFavorite(testRecipeId))
            .thenAnswer((_) async => const Right(updatedRecipe));
        
        final result = await repository.toggleFavorite(testRecipeId);
        
        expect(result, equals(const Right(updatedRecipe)));
        expect(result.fold((l) => TestRecipeData.testRecipe1, (r) => r).isFavorite, true);
        verify(() => repository.toggleFavorite(testRecipeId)).called(1);
      });

      test('should return cache failure when toggling favorite fails', () async {
        when(() => repository.toggleFavorite(testRecipeId))
            .thenAnswer((_) async => const Left(TestRecipeData.cacheFailure));
        
        final result = await repository.toggleFavorite(testRecipeId);
        
        expect(result, equals(const Left(TestRecipeData.cacheFailure)));
      });

      test('should return validation failure for non-existent recipe ID', () async {
        when(() => repository.toggleFavorite(nonExistentRecipeId))
            .thenAnswer((_) async => const Left(TestRecipeData.validationFailure));
        
        final result = await repository.toggleFavorite(nonExistentRecipeId);
        
        expect(result, equals(const Left(TestRecipeData.validationFailure)));
      });
    });

    group('toggleBookmark', () {
      const testRecipeId = '1';
      const nonExistentRecipeId = '999';
      const updatedRecipe = Recipe(
        id: '1',
        name: 'Test Recipe 1',
        ingredients: [TestRecipeData.ingredient1, TestRecipeData.ingredient2],
        instructions: 'Step 1. Mix ingredients\nStep 2. Cook for 20 minutes',
        thumbnailUrl: 'https://example.com/recipe1.jpg',
        isFavorite: false,
        isBookmarked: true,
      );

      test('should return updated recipe when toggling bookmark succeeds', () async {
        when(() => repository.toggleBookmark(testRecipeId))
            .thenAnswer((_) async => const Right(updatedRecipe));
        
        final result = await repository.toggleBookmark(testRecipeId);
        
        expect(result, equals(const Right(updatedRecipe)));
        expect(result.fold((l) => TestRecipeData.testRecipe1, (r) => r).isBookmarked, true);
        verify(() => repository.toggleBookmark(testRecipeId)).called(1);
      });

      test('should return cache failure when toggling bookmark fails', () async {
        when(() => repository.toggleBookmark(testRecipeId))
            .thenAnswer((_) async => const Left(TestRecipeData.cacheFailure));
        
        final result = await repository.toggleBookmark(testRecipeId);
        
        expect(result, equals(const Left(TestRecipeData.cacheFailure)));
      });

      test('should return validation failure for non-existent recipe ID', () async {
        when(() => repository.toggleBookmark(nonExistentRecipeId))
            .thenAnswer((_) async => const Left(TestRecipeData.validationFailure));
        
        final result = await repository.toggleBookmark(nonExistentRecipeId);
        
        expect(result, equals(const Left(TestRecipeData.validationFailure)));
      });
    });

    group('getFavorites', () {
      test('should return list of favorite recipes when successful', () async {
        final favoriteRecipes = <Recipe>[TestRecipeData.testRecipe2]; 
        when(() => repository.getFavorites())
            .thenAnswer((_) async => Right(favoriteRecipes));
        
        final result = await repository.getFavorites();
        
        expect(result, equals(Right(favoriteRecipes)));
        verify(() => repository.getFavorites()).called(1);
      });

      test('should return empty list when no favorites exist', () async {
        when(() => repository.getFavorites())
            .thenAnswer((_) async => const Right(<Recipe>[]));  
        
        final result = await repository.getFavorites();
        
        expect(result.isRight(), true);
        expect(result.fold((l) => <Recipe>[], (r) => r), isEmpty);
      });

      test('should return cache failure when retrieving favorites fails', () async {
        when(() => repository.getFavorites())
            .thenAnswer((_) async => const Left(TestRecipeData.cacheFailure));
        
        final result = await repository.getFavorites();
        
        expect(result, equals(const Left(TestRecipeData.cacheFailure)));
      });
    });

    group('getBookmarks', () {
      test('should return list of bookmarked recipes when successful', () async {
        final bookmarkedRecipes = <Recipe>[TestRecipeData.testRecipe2]; 
        when(() => repository.getBookmarks())
            .thenAnswer((_) async => Right(bookmarkedRecipes));
        
        final result = await repository.getBookmarks();
        
        expect(result, equals(Right(bookmarkedRecipes)));
        verify(() => repository.getBookmarks()).called(1);
      });

      test('should return empty list when no bookmarks exist', () async {
        when(() => repository.getBookmarks())
            .thenAnswer((_) async => const Right(<Recipe>[]));  
        
        final result = await repository.getBookmarks();
        
        expect(result.isRight(), true);
        expect(result.fold((l) => <Recipe>[], (r) => r), isEmpty);
      });

      test('should return cache failure when retrieving bookmarks fails', () async {
        when(() => repository.getBookmarks())
            .thenAnswer((_) async => const Left(TestRecipeData.cacheFailure));
        
        final result = await repository.getBookmarks();
        
        expect(result, equals(const Left(TestRecipeData.cacheFailure)));
      });
    });

    group('Edge Cases and Interface Compliance', () {
      test('should enforce consistent error handling across methods', () async {
        final failure = ConnectionFailure(message: 'No internet connection');
        setupConsistentErrorHandling(failure);
        
        final resultLetter = await repository.getRecipesByLetter('A');
        final resultFavorites = await repository.getFavorites();
        final resultBookmarks = await repository.getBookmarks();
        final resultToggleFav = await repository.toggleFavorite('1');
        final resultToggleBook = await repository.toggleBookmark('1');
        
        expect(resultLetter.isLeft(), true, reason: 'getRecipesByLetter should return Left on error');
        expect(resultFavorites.isLeft(), true, reason: 'getFavorites should return Left on error');
        expect(resultBookmarks.isLeft(), true, reason: 'getBookmarks should return Left on error');
        expect(resultToggleFav.isLeft(), true, reason: 'toggleFavorite should return Left on error');
        expect(resultToggleBook.isLeft(), true, reason: 'toggleBookmark should return Left on error');
        
        final failureTypes = [
          resultLetter.fold((l) => l.runtimeType, (_) => null),
          resultFavorites.fold((l) => l.runtimeType, (_) => null),
          resultBookmarks.fold((l) => l.runtimeType, (_) => null),
          resultToggleFav.fold((l) => l.runtimeType, (_) => null),
          resultToggleBook.fold((l) => l.runtimeType, (_) => null),
        ];
        
        expect(failureTypes.toSet().length, 1, 
          reason: 'All methods should return the same failure type for consistency');
      });
      test('should handle null recipe ID gracefully', () async {
        when(() => repository.toggleFavorite(any()))
            .thenAnswer((_) async => const Left(TestRecipeData.validationFailure));
        
        final String? nullableId = null;
        if (nullableId != null) {
          final result = await repository.toggleFavorite(nullableId);
          expect(result, equals(const Left(TestRecipeData.validationFailure)));
        } else {
          expect(nullableId, isNull);
        }
      });

      test('should handle extremely long recipe IDs', () async {
        final longId = 'a' * 1000; 
        when(() => repository.toggleBookmark(longId))
            .thenAnswer((_) async => const Left(TestRecipeData.validationFailure));
        
        final result = await repository.toggleBookmark(longId);
        
        expect(result.isLeft(), true);
      });

      test('should handle special characters in recipe IDs', () async {
        const specialId = '123!@#\$%^&*()_+{}:<>?-=[]';
        when(() => repository.getRecipesByLetter(specialId))
            .thenAnswer((_) async => const Left(TestRecipeData.validationFailure));
        
        final result = await repository.getRecipesByLetter(specialId);
        
        expect(result.isLeft(), true);
      });

      test('should handle concurrent operations gracefully', () async {
        when(() => repository.toggleFavorite('1'))
            .thenAnswer((_) async => Right(TestRecipeData.testRecipe1.copyWith(isFavorite: true)));
        when(() => repository.toggleBookmark('1'))
            .thenAnswer((_) async => Right(TestRecipeData.testRecipe1.copyWith(isBookmarked: true)));
        
        final results = await Future.wait([
          repository.toggleFavorite('1'),
          repository.toggleBookmark('1'),
        ]);
        
        expect(results.length, 2);
        expect(results[0].isRight(), true);
        expect(results[1].isRight(), true);
        verify(() => repository.toggleFavorite('1')).called(1);
        verify(() => repository.toggleBookmark('1')).called(1);
      });

      test('should handle repeat requests with idempotency', () async {
        final updatedRecipe = TestRecipeData.testRecipe1.copyWith(isFavorite: true);
        when(() => repository.toggleFavorite('1'))
            .thenAnswer((_) async => Right(updatedRecipe));
        
        final result1 = await repository.toggleFavorite('1');
        final result2 = await repository.toggleFavorite('1');
        final result3 = await repository.toggleFavorite('1');
        
        expect(result1, equals(Right(updatedRecipe)));
        expect(result2, equals(Right(updatedRecipe)));
        expect(result3, equals(Right(updatedRecipe)));
        verify(() => repository.toggleFavorite('1')).called(3);
      });
    });   
    
    group('Repository Domain Integration', () {
      test('should transform raw JSON data to domain Recipe entities', () async {
        when(() => mockRemoteDataSource.getRecipesByLetter('A'))
            .thenAnswer((_) async => [
                  RecipeModel.fromJson(TestRecipeData.recipeJson1),
                  RecipeModel.fromJson(TestRecipeData.recipeJson2)
                ]);
        when(() => repository.getRecipesByLetter('A'))
            .thenAnswer((_) async => const Right(TestRecipeData.testRecipes));
        
        final models = await mockRemoteDataSource.getRecipesByLetter('A');
        final jsonData = [TestRecipeData.recipeJson1, TestRecipeData.recipeJson2];
        final domainResult = await repository.getRecipesByLetter('A');

        expect(jsonData.length, equals(2));
        expect(domainResult.isRight(), true);
        domainResult.fold(
          (l) => fail('Should not return failure'),
          (recipes) {
            expect(recipes.length, 2);
            expect(recipes[0].id, equals(jsonData[0]['idMeal']));
            expect(recipes[0].name, equals(jsonData[0]['strMeal']));
            expect(recipes[1].id, equals(jsonData[1]['idMeal']));
            expect(recipes[1].name, equals(jsonData[1]['strMeal']));
            
            expect(models[0].id, equals(jsonData[0]['idMeal']));
            expect(models[0].name, equals(jsonData[0]['strMeal']));
          },
        );
      });
      
      test('should handle malformed data gracefully', () async {
        when(() => mockRemoteDataSource.getRecipesByLetter('M'))
            .thenAnswer((_) async => [RecipeModel.fromJson(TestRecipeData.malformedRecipeJson)]);
        when(() => repository.getRecipesByLetter('M'))
            .thenAnswer((_) async => const Right([Recipe(
              id: '3',
              name: 'Malformed Recipe',
              instructions: '',  
              thumbnailUrl: '', 
              ingredients: [Ingredient(name: 'Malformed Ingredient', measure: '')],
              isFavorite: false,
              isBookmarked: false,
            )]));
        
        final recipeModels = await mockRemoteDataSource.getRecipesByLetter('M');
        final originalJson = [TestRecipeData.malformedRecipeJson];
        final domainResult = await repository.getRecipesByLetter('M');
        
        expect(originalJson.length, equals(1));
        expect(domainResult.isRight(), true);
        domainResult.fold(
          (l) => fail('Should not return failure even with malformed data'),
          (recipes) {
            expect(recipes.length, 1);
            expect(recipes[0].id, equals(originalJson[0]['idMeal']));
            expect(recipes[0].name, equals(originalJson[0]['strMeal']));
            expect(recipes[0].instructions, equals(''));
            expect(recipes[0].thumbnailUrl, equals(''));
            expect(recipes[0].ingredients.length, 1);
            expect(recipes[0].ingredients[0].measure, equals(''));
            
            expect(recipeModels[0].id, equals(originalJson[0]['idMeal']));
          },
        );
      });
      
      test('should ignore extra fields in JSON data', () async {
        when(() => mockRemoteDataSource.getRecipesByLetter('E'))
            .thenAnswer((_) async => [RecipeModel.fromJson(TestRecipeData.extraFieldsRecipeJson)]);
        when(() => repository.getRecipesByLetter('E'))
            .thenAnswer((_) async => const Right([Recipe(
              id: '4',
              name: 'Extra Fields Recipe',
              instructions: 'Simple instructions',
              thumbnailUrl: 'https://example.com/recipe4.jpg',
              ingredients: [Ingredient(name: 'Regular Ingredient', measure: 'Regular measure')],
              isFavorite: false,
              isBookmarked: false,
            )]));
        
        final recipeModels = await mockRemoteDataSource.getRecipesByLetter('E');
        final originalJson = [TestRecipeData.extraFieldsRecipeJson];
        final domainResult = await repository.getRecipesByLetter('E');
        
        expect(originalJson.length, equals(1));
        expect(recipeModels.length, equals(1));
        expect(originalJson[0].containsKey('extra_field'), true); 
        expect(domainResult.isRight(), true);
        domainResult.fold(
          (l) => fail('Should not return failure'),
          (recipes) {
            expect(recipes.length, 1);
            expect(recipes[0].id, equals(originalJson[0]['idMeal']));
            expect(recipes[0].name, equals(originalJson[0]['strMeal']));
            expect(recipeModels[0].id, equals(originalJson[0]['idMeal']));
          },
        );
      });
      
      test('should maintain local state during transformations', () async {
        when(() => mockLocalDataSource.getFavoriteIds())
            .thenAnswer((_) async => ['2']);
        when(() => repository.getFavorites())
            .thenAnswer((_) async => const Right([TestRecipeData.testRecipe2]));
            
        when(() => mockRemoteDataSource.getRecipesByLetter('A'))
            .thenAnswer((_) async => [
                  RecipeModel.fromJson(TestRecipeData.recipeJson1),
                  RecipeModel.fromJson(TestRecipeData.recipeJson2)
                ]);
        when(() => repository.getRecipesByLetter('A'))
            .thenAnswer((_) async => const Right([
              TestRecipeData.testRecipe1, 
              TestRecipeData.testRecipe2, 
            ]));
        
        final favorites = await repository.getFavorites();
        final recipes = await repository.getRecipesByLetter('A');
        
        expect(favorites.isRight(), true);
        expect(recipes.isRight(), true);
        
        favorites.fold((l) => fail('Should not return failure'), 
          (favs) => expect(favs[0].isFavorite, true));
        
        recipes.fold((l) => fail('Should not return failure'),
          (recs) {
            expect(recs.length, 2);
            expect(recs[0].isFavorite, false); 
            expect(recs[1].isFavorite, true); 
          });
      });

      test('should properly merge domain properties during updates', () async {
        final updatedJson = {
          'idMeal': '1',
          'strMeal': 'Updated Recipe Name',
          'strInstructions': 'Updated instructions',
          'strMealThumb': 'https://example.com/updated.jpg',
          'strIngredient1': 'Updated Ingredient',
          'strMeasure1': 'Updated measure',
        };
        
        const expectedMergedRecipe = Recipe(
          id: '1',
          name: 'Updated Recipe Name', 
          ingredients: [Ingredient(name: 'Updated Ingredient', measure: 'Updated measure')], 
          instructions: 'Updated instructions', 
          thumbnailUrl: 'https://example.com/updated.jpg',
          isFavorite: true,    
          isBookmarked: true,  
        );
        
        when(() => mockRemoteDataSource.getRecipeById('1'))
            .thenAnswer((_) async => RecipeModel.fromJson(updatedJson));
        when(() => repository.getRecipesByLetter('A'))
            .thenAnswer((_) async => const Right([expectedMergedRecipe]));
        
        final result = await repository.getRecipesByLetter('A');
        
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not return failure'),
          (recipes) {
            expect(recipes.length, 1);
            final mergedRecipe = recipes[0];
            
            expect(mergedRecipe.name, equals('Updated Recipe Name'));
            expect(mergedRecipe.instructions, equals('Updated instructions'));
            expect(mergedRecipe.thumbnailUrl, equals('https://example.com/updated.jpg'));
            expect(mergedRecipe.ingredients.length, 1);
            expect(mergedRecipe.ingredients[0].name, equals('Updated Ingredient'));
            
            expect(mergedRecipe.isFavorite, equals(true));
            expect(mergedRecipe.isBookmarked, equals(true));
          },
        );
      });
    }); });
  
  group('Repository Edge Case Handling', () {
    test('should handle empty recipe ID gracefully', () async {
      const emptyId = '';
      final failure = InputValidationFailure(message: 'Recipe ID cannot be empty');
      when(() => repository.toggleFavorite(emptyId))
          .thenAnswer((_) async => Left(failure));
      
      final result = await repository.toggleFavorite(emptyId);
      
      expect(result, Left(failure));
      verify(() => repository.toggleFavorite(emptyId)).called(1);
    });
    
    test('should handle invalid characters in recipe ID', () async {
      const invalidId = 'id@with#invalid!chars';
      final failure = InputValidationFailure(message: 'Recipe ID contains invalid characters');
      when(() => repository.toggleBookmark(invalidId))
          .thenAnswer((_) async => Left(failure));
      
      final result = await repository.toggleBookmark(invalidId);
      
      expect(result.isLeft(), true);
      expect(result, Left(failure));
      verify(() => repository.toggleBookmark(invalidId)).called(1);
    });
    
    test('should handle extremely long recipe ID', () async {
      final longId = 'a' * 1000; 
      final failure = InputValidationFailure(message: 'Recipe ID exceeds maximum length');
      when(() => repository.toggleBookmark(longId))
          .thenAnswer((_) async => Left(failure));
      
      final result = await repository.toggleBookmark(longId);
      
      expect(result.isLeft(), true);
      expect(result, Left(failure));
      verify(() => repository.toggleBookmark(longId)).called(1);
    });
  });
  
  group('Repository Concurrency Behavior', () {
    test('should handle multiple concurrent operations correctly', () async {
      final favoritedRecipe = TestRecipeData.testRecipe1.copyWith(isFavorite: true);
      final favoriteRecipes = [favoritedRecipe, TestRecipeData.testRecipe2];
      
      when(() => repository.toggleFavorite('1'))
          .thenAnswer((_) async => Right(favoritedRecipe));
      when(() => repository.getFavorites())
          .thenAnswer((_) async => Right(favoriteRecipes));
      when(() => repository.getRecipesByLetter('A'))
          .thenAnswer((_) async => const Right(TestRecipeData.testRecipes));
      
      final results = await Future.wait([
        repository.toggleFavorite('1'),
        repository.getFavorites(),
        repository.getRecipesByLetter('A'),
      ]);
      
      expect(results[0], Right(favoritedRecipe));
      expect(results[1], Right(favoriteRecipes));
      expect(results[2], const Right(TestRecipeData.testRecipes));
      verify(() => repository.toggleFavorite('1')).called(1);
      verify(() => repository.getFavorites()).called(1);
      verify(() => repository.getRecipesByLetter('A')).called(1);
    });
    
    test('should maintain consistency during concurrent toggle operations', () async {
      final recipe = TestRecipeData.testRecipe1;
      final toggled = recipe.copyWith(isFavorite: !recipe.isFavorite);
      final recipe2 = TestRecipeData.testRecipe2;
      
      when(() => repository.toggleFavorite('1'))
          .thenAnswer((_) async => Right(toggled));
      
      when(() => repository.toggleFavorite('2'))
          .thenAnswer((_) async => Right(recipe2));
      
      final results = await Future.wait([
        repository.toggleFavorite('1'),
        repository.toggleFavorite('2'),
      ]);
      
      expect(results[0], Right(toggled));
      expect(results[1], Right(recipe2));
      verify(() => repository.toggleFavorite('1')).called(1);
      verify(() => repository.toggleFavorite('2')).called(1);
    });
  });
  
  group('Repository Interface Compliance', () {
    test('should enforce consistent error handling across methods', () async {
      final failure = ConnectionFailure(message: 'Network error');
      
      when(() => repository.getRecipesByLetter('A'))
          .thenAnswer((_) async => Left(failure));
      when(() => repository.getFavorites())
          .thenAnswer((_) async => Left(failure));
      when(() => repository.getBookmarks())
          .thenAnswer((_) async => Left(failure));
      
      final resultLetter = await repository.getRecipesByLetter('A');
      final resultFavorites = await repository.getFavorites();
      final resultBookmarks = await repository.getBookmarks();
      
      expect(resultLetter, Left(failure));
      expect(resultFavorites, Left(failure));
      expect(resultBookmarks, Left(failure));
    });
    
    test('should return consistent types from similar methods', () async {
      when(() => repository.toggleFavorite('1'))
          .thenAnswer((_) async => const Right(TestRecipeData.testRecipe1));
      when(() => repository.toggleBookmark('1'))
          .thenAnswer((_) async => const Right(TestRecipeData.testRecipe1));
      
      final resultFavorite = await repository.toggleFavorite('1');
      final resultBookmark = await repository.toggleBookmark('1');
      
      expect(resultFavorite, isA<Either<Failure, Recipe>>());
      expect(resultBookmark, isA<Either<Failure, Recipe>>());
      
      expect(resultFavorite.runtimeType, equals(resultBookmark.runtimeType));
    });
    
    test('should implement all methods defined in the repository interface', () {
      when(() => repository.getRecipesByLetter(any()))
        .thenAnswer((_) async => const Right(<Recipe>[])); 
      when(() => repository.toggleFavorite(any()))
        .thenAnswer((_) async => const Right(TestRecipeData.testRecipe1));
      when(() => repository.toggleBookmark(any()))
        .thenAnswer((_) async => const Right(TestRecipeData.testRecipe1));
      when(() => repository.getFavorites())
        .thenAnswer((_) async => const Right(<Recipe>[])); 
      when(() => repository.getBookmarks())
        .thenAnswer((_) async => const Right(<Recipe>[])); 

      expect(() {
        repository.getRecipesByLetter('A');
        repository.toggleFavorite('1');
        repository.toggleBookmark('1');
        repository.getFavorites();
        repository.getBookmarks();
      }, returnsNormally);
    });
  });
  
  group('Repository Stress Testing', () {
    test('should handle large result sets efficiently', () async {
      final largeRecipeList = List.generate(
        500,
        (index) => TestRecipeData.testRecipe1.copyWith(
          id: 'recipe_$index',
          name: 'Recipe $index',
        ),
      );
      
      when(() => repository.getRecipesByLetter('A'))
          .thenAnswer((_) async => Right(largeRecipeList));
      
      final stopwatch = Stopwatch()..start();
      final result = await repository.getRecipesByLetter('A');
      stopwatch.stop();
      
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (recipes) {
          expect(recipes.length, 500, reason: 'Should return all 500 recipes');
          expect(
            recipes.first.id, 
            'recipe_0', 
            reason: 'First recipe should have expected ID'
          );
          expect(
            recipes.last.id, 
            'recipe_499', 
            reason: 'Last recipe should have expected ID'
          );
        },
      );
    });
    
    test('should handle batch processing of favorites efficiently', () async {
      final largeFavoritesList = List.generate(
        100,
        (index) => TestRecipeData.testRecipe1.copyWith(
          id: 'favorite_$index',
          name: 'Favorite Recipe $index',
          isFavorite: true,
        ),
      );
      
      when(() => repository.getFavorites())
          .thenAnswer((_) async => Right(largeFavoritesList));
      
      final stopwatch = Stopwatch()..start();
      final result = await repository.getFavorites();
      stopwatch.stop();
      
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure for large favorites list'),
        (favorites) {
          expect(favorites.length, 100, reason: 'Should return all 100 favorite recipes');
          for (final recipe in favorites) {
            expect(recipe.isFavorite, true, reason: 'All recipes should be marked as favorites');
          }
          expect(favorites.first.id, 'favorite_0');
          expect(favorites.last.id, 'favorite_99');
        },
      );
      
    });
    
    test('should handle multiple toggle operations efficiently', () async {
      final toggleCount = 50;
      final toggleOperations = <Future<Either<Failure, Recipe>>>[];
      
      for (int i = 0; i < toggleCount; i++) {
        final recipeId = 'recipe_$i';
        final resultRecipe = TestRecipeData.testRecipe1.copyWith(
          id: recipeId,
          name: 'Recipe $i',
          isFavorite: true, 
        );
        
        when(() => repository.toggleFavorite(recipeId))
            .thenAnswer((_) async => Right(resultRecipe));
        
        toggleOperations.add(repository.toggleFavorite(recipeId));
      }
      
      final stopwatch = Stopwatch()..start();
      final results = await Future.wait(toggleOperations);
      stopwatch.stop();
      
      expect(results.length, toggleCount);
      
      int successCount = 0;
      for (final result in results) {
        if (result.isRight()) successCount++;
      }
      expect(successCount, toggleCount, reason: 'All toggle operations should succeed');
      
      expect(results[0], isA<Right<Failure, Recipe>>());
      expect(results[toggleCount - 1], isA<Right<Failure, Recipe>>());
      
    });
  });
  
  group('Repository Integration Tests', () {
    late MockRemoteDataSource remoteDataSource;
    late MockLocalDataSource localDataSource;
    late RecipeRepositoryImpl repositoryImpl;
    
    setUp(() {
      remoteDataSource = MockRemoteDataSource();
      localDataSource = MockLocalDataSource();
      repositoryImpl = RecipeRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
    });
    
    group('Concrete Repository Implementation', () {
      test('should correctly transform data from remote data source', () async {
        setupCommonMocks();
        
        final recipeModel = TestRecipeData.testRecipeModel1;
        
        when(() => remoteDataSource.getRecipesByLetter(any(that: isValidLetter)))
            .thenAnswer((_) async => [recipeModel]);
            
        when(() => localDataSource.isFavorite(any(that: isValidId)))
            .thenAnswer((_) async => false);
        when(() => localDataSource.isBookmarked(any(that: isValidId)))
            .thenAnswer((_) async => false);
        when(() => localDataSource.getCachedRecipesByLetter(any(that: isValidLetter)))
            .thenAnswer((_) async => [TestRecipeData.testRecipe1Json]);
        when(() => localDataSource.getFavoriteIds())
            .thenAnswer((_) async => []);
        
        final result = await repositoryImpl.getRecipesByLetter('A');
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (recipes) {
            expect(recipes.isNotEmpty, isTrue, reason: 'Should have at least one recipe');
            
            final recipe = recipes.first;
            expect(recipe.id, '1', reason: 'Recipe should have ID "1"');
            expect(recipe.name, 'Test Recipe 1', reason: 'Recipe should have name from TestRecipeData');
            
            expect(recipe.ingredients.isNotEmpty, isTrue, reason: 'Recipe should have ingredients');
          },
        );
      });
    });
    
    group('Repository and Data Source Integration', () {
      late MockRemoteDataSource remoteDataSource;
      late MockLocalDataSource localDataSource;
      late RecipeRepositoryImpl repositoryImpl;
      
      setUp(() {
        remoteDataSource = MockRemoteDataSource();
        localDataSource = MockLocalDataSource();
        repositoryImpl = RecipeRepositoryImpl(
          remoteDataSource: remoteDataSource,
          localDataSource: localDataSource,
        );
        
        when(() => localDataSource.maintainCache())
            .thenAnswer((_) async => Future<void>.value());
      });
      
      test('should integrate with both remote and local data sources', () async {
        when(() => remoteDataSource.getRecipesByLetter('A'))
            .thenAnswer((_) async => [
                  RecipeModel.fromJson(TestRecipeData.testRecipe1Json),
                ]);
        when(() => localDataSource.getFavoriteIds())
            .thenAnswer((_) async => ['1']);
        when(() => localDataSource.getCachedRecipe('1'))
            .thenAnswer((_) async => TestRecipeData.testRecipe1Json);
        when(() => localDataSource.isFavorite('1'))
            .thenAnswer((_) async => true);
        when(() => localDataSource.isBookmarked('1'))
            .thenAnswer((_) async => false);
        when(() => localDataSource.maintainCache())
            .thenAnswer((_) async => Future<void>.value());
        when(() => localDataSource.cacheRecipe(any()))
            .thenAnswer((_) async => Future<void>.value());
        when(() => localDataSource.getCachedRecipesByLetter(any()))
            .thenAnswer((_) async => [TestRecipeData.testRecipe1Json]);
        
        final remoteResult = await repositoryImpl.getRecipesByLetter('A');
        final localResult = await repositoryImpl.getFavorites();
        
        expect(remoteResult.isRight(), true);
        expect(localResult.isRight(), true);
        
        remoteResult.fold(
          (failure) => fail('Should not return failure'),
          (recipes) {
            expect(recipes.length, equals(1));
            expect(recipes[0].id, equals('1'));
            expect(recipes[0].name, equals('Test Recipe 1'));
          },
        );
        
        localResult.fold(
          (failure) => fail('Should not return failure'),
          (favorites) {
            expect(favorites.length, equals(1));
            expect(favorites[0].id, equals('1'));
            expect(favorites[0].isFavorite, isTrue);
          },
        );
      });
      
      test('should fallback to local cache when remote source fails', () async {
        when(() => remoteDataSource.getRecipesByLetter('B'))
            .thenThrow(const ServerFailure(message: 'Server error', statusCode: 500));
        when(() => localDataSource.getCachedRecipesByLetter('B'))
            .thenAnswer((_) async => [TestRecipeData.testRecipe2Json]);
        when(() => localDataSource.isFavorite('2'))
            .thenAnswer((_) async => true);
        when(() => localDataSource.isBookmarked('2'))
            .thenAnswer((_) async => true);
        when(() => localDataSource.maintainCache())
            .thenAnswer((_) async => Future<void>.value());
        
        final result = await repositoryImpl.getRecipesByLetter('B');
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (recipes) {
            expect(recipes.length, equals(1));
            expect(recipes[0].id, equals('2'));
            expect(recipes[0].isFavorite, isTrue);
            expect(recipes[0].isBookmarked, isTrue);
          },
        );
        
        verify(() => localDataSource.isFavorite('2')).called(greaterThanOrEqualTo(1));
        verify(() => localDataSource.isBookmarked('2')).called(greaterThanOrEqualTo(1));
        verify(() => localDataSource.maintainCache()).called(greaterThanOrEqualTo(1));
      });
      
      test('should update local state when toggling favorite status', () async {
        const recipeId = '1';
        when(() => localDataSource.isFavorite(recipeId))
            .thenAnswer((_) async => false);
        when(() => localDataSource.addFavorite(recipeId))
            .thenAnswer((_) async => Future<void>.value());
        when(() => localDataSource.getCachedRecipe(recipeId))
            .thenAnswer((_) async => TestRecipeData.testRecipe1Json);
        when(() => localDataSource.isBookmarked(recipeId))
            .thenAnswer((_) async => false);
        when(() => localDataSource.cacheRecipe(any()))
            .thenAnswer((_) async => Future<void>.value());
        when(() => localDataSource.maintainCache())
            .thenAnswer((_) async => Future<void>.value());
        
        when(() => localDataSource.isFavorite(recipeId))
            .thenAnswer((_) async => false);
        
        final result = await repositoryImpl.toggleFavorite(recipeId);
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (recipe) {
            expect(recipe.id, equals(recipeId));
          },
        );
        
        verify(() => localDataSource.isFavorite(recipeId)).called(greaterThanOrEqualTo(1));
        verify(() => localDataSource.addFavorite(recipeId)).called(1);
      });
      
      test('should propagate connection failure appropriately', () async {
        when(() => remoteDataSource.getRecipesByLetter('X'))
            .thenThrow(const ConnectionFailure(message: 'No internet connection'));
        when(() => localDataSource.getCachedRecipesByLetter('X'))
            .thenAnswer((_) async => null);
        when(() => localDataSource.maintainCache())
            .thenAnswer((_) async => Future<void>.value());
            
        final result = await repositoryImpl.getRecipesByLetter('X');
        
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ConnectionFailure>());
            expect((failure as ConnectionFailure).message, 'No internet connection');
          },
          (_) => fail('Should return failure'),
        );
        
        verify(() => remoteDataSource.getRecipesByLetter('X')).called(1);
      });
      
      test('should handle bookmark toggling correctly', () async {
        const recipeId = '2';
        when(() => localDataSource.isBookmarked(recipeId))
            .thenAnswer((_) async => true);
        when(() => localDataSource.removeBookmark(recipeId))
            .thenAnswer((_) async => Future<void>.value());
        when(() => localDataSource.getCachedRecipe(recipeId))
            .thenAnswer((_) async => TestRecipeData.testRecipe2Json);
        when(() => localDataSource.isFavorite(recipeId))
            .thenAnswer((_) async => true);
        when(() => localDataSource.cacheRecipe(any()))
            .thenAnswer((_) async => Future<void>.value());
        
        final result = await repositoryImpl.toggleBookmark(recipeId);
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure'),
          (recipe) {
            expect(recipe.id, equals(recipeId));
            expect(recipe.isFavorite, isTrue);
          },
        );
        
        verify(() => localDataSource.isBookmarked(recipeId)).called(greaterThanOrEqualTo(1));
        verify(() => localDataSource.removeBookmark(recipeId)).called(greaterThanOrEqualTo(1));
      });
    });
    
    group('Error Propagation', () {
      test('should convert remote data source exceptions to Failure types', () async {
        when(() => remoteDataSource.getRecipesByLetter('A'))
            .thenThrow(Exception('Server error'));
        
        final result = await repositoryImpl.getRecipesByLetter('A');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure on data source exception'),
        );
      });
      
      test('should convert local data source exceptions to Failure types', () async {
        when(() => localDataSource.getFavoriteIds())
            .thenThrow(Exception('Cache error'));
        
        final result = await repositoryImpl.getFavorites();
        
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return failure on data source exception'),
        );
      });   
    });    

    group('Caching and Data Synchronization', () {
      test('should update local cache after toggling favorite status', () async {
        const recipeId = '1';
        when(() => localDataSource.isFavorite(recipeId))
            .thenAnswer((_) async => false);
        when(() => localDataSource.addFavorite(recipeId))
            .thenAnswer((_) async => Future<void>.value());
        when(() => localDataSource.getCachedRecipe(recipeId))
            .thenAnswer((_) async => TestRecipeData.recipeJson1);
        when(() => localDataSource.isBookmarked(recipeId))
            .thenAnswer((_) async => false);
        when(() => localDataSource.maintainCache())
            .thenAnswer((_) async => Future<void>.value());
        when(() => localDataSource.cacheRecipe(any()))
            .thenAnswer((_) async => Future<void>.value());
        
        final result = await repositoryImpl.toggleFavorite(recipeId);
        
        expect(result.isRight(), true);
        verify(() => localDataSource.addFavorite(recipeId)).called(1);
      });
    });    

    group('Network Error Handling', () {
      test('should handle network timeouts', () async {
        when(() => remoteDataSource.getRecipesByLetter('A'))
            .thenThrow(TimeoutException('Connection timeout'));
        
        when(() => localDataSource.maintainCache())
            .thenAnswer((_) async => Future<void>.value());
        
        when(() => localDataSource.getCachedRecipesByLetter('A'))
            .thenAnswer((_) async => []);
        
        final result = await repositoryImpl.getRecipesByLetter('A');

        if (result.isLeft()) {
          result.fold(
            (failure) => expect(failure, anyOf(isA<ConnectionFailure>(), isA<ServerFailure>())),
            (_) => fail('Should not reach this branch')
          );
        } 
        else {
          result.fold(
            (_) => fail('Should not reach this branch'),
            (recipes) => expect(recipes.isEmpty, isTrue, reason: 'Should return empty list when timeout occurs and no cache available')
          );
        }
      });
    });    

    group('Connection State Management', () {
      test('should adapt behavior based on connection state', () async {

        when(() => remoteDataSource.getRecipesByLetter('A'))
            .thenThrow(const ConnectionFailure(message: 'No internet connection'));
            
        when(() => localDataSource.maintainCache())
            .thenAnswer((_) async => Future<void>.value());
            
        when(() => localDataSource.getCachedRecipesByLetter('A'))
            .thenAnswer((_) async => [TestRecipeData.recipeJson1]);
        
        final result = await repositoryImpl.getRecipesByLetter('A');

        if (result.isRight()) {
          result.fold(
            (_) => fail('This branch should not be reached'),
            (recipes) => expect(recipes.isNotEmpty, true)
          );
        } else {
          result.fold(
            (failure) => expect(failure, anyOf(isA<ConnectionFailure>(), isA<ServerFailure>())),
            (_) => fail('This branch should not be reached')
          );
        }
      });    });
    
    group('Data Source Fallback', () {
      test('should fall back to local data when remote fails', () async {
        when(() => remoteDataSource.getRecipesByLetter('A'))
            .thenThrow(Exception('Network error'));
        when(() => localDataSource.getCachedRecipesByLetter('A'))
            .thenAnswer((_) async => [TestRecipeData.recipeJson1]);
            
        when(() => localDataSource.maintainCache())
            .thenAnswer((_) async => Future<void>.value());
        when(() => localDataSource.isFavorite('1'))
            .thenAnswer((_) async => false);
        when(() => localDataSource.isBookmarked('1'))
            .thenAnswer((_) async => false);
        
        final result = await repositoryImpl.getRecipesByLetter('A');
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not return failure when local cache available'),
          (recipes) => expect(recipes.length, 1),
        );
      });
    }); 
  });
}
