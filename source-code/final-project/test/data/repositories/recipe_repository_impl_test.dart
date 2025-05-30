import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/errors/failure.dart';
import 'package:recipevault/data/datasources/local_datasource.dart';
import 'package:recipevault/data/datasources/remote_datasource.dart';
import 'package:recipevault/data/models/recipe_model.dart';
import 'package:recipevault/data/repositories/recipe_repository_impl.dart';
import 'package:recipevault/domain/entities/recipe.dart';
import 'package:recipevault/domain/repositories/recipe_repository.dart';

class MockRemoteDataSource extends Mock implements RemoteDataSource {}
class MockLocalDataSource extends Mock implements LocalDataSource {}
class MockCacheTransaction extends Mock {}

void main() {
  late RecipeRepositoryImpl repository;
  late MockRemoteDataSource mockRemoteDataSource;
  late MockLocalDataSource mockLocalDataSource;
  
  final testRecipeModel = RecipeModel(
    id: '1',
    name: 'Test Recipe',
    ingredients: [
      const IngredientModel(name: 'Ingredient 1', measure: '1 tbsp'),
      const IngredientModel(name: 'Ingredient 2', measure: '2 cups')
    ],
    instructions: 'Test instructions',
    thumbnailUrl: 'https://example.com/image.jpg',
  );
  
  final testRecipeModel2 = RecipeModel(
    id: '2',
    name: 'Another Recipe',
    ingredients: [
      const IngredientModel(name: 'Ingredient A', measure: '1 tsp'),
      const IngredientModel(name: 'Ingredient B', measure: '3 oz')
    ],
    instructions: 'More instructions',
    thumbnailUrl: 'https://example.com/image2.jpg',
  );
  
  final testRecipeModelJson = {
    'idMeal': '1',
    'strMeal': 'Test Recipe',
    'ingredients': [
      {'name': 'Ingredient 1', 'measure': '1 tbsp'},
      {'name': 'Ingredient 2', 'measure': '2 cups'}
    ],
    'strInstructions': 'Test instructions',
    'strMealThumb': 'https://example.com/image.jpg',
  };
  


  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockLocalDataSource = MockLocalDataSource();
    repository = RecipeRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
    
    when(() => mockLocalDataSource.maintainCache())
        .thenAnswer((_) async => Future<void>.value());
    registerFallbackValue('any_letter');
    registerFallbackValue('any_id');
    registerFallbackValue({});
  });

  void setupCacheSuccess() {
    when(() => mockLocalDataSource.isFavorite(any()))
        .thenAnswer((_) async => false);
    when(() => mockLocalDataSource.isBookmarked(any()))
        .thenAnswer((_) async => false);
    when(() => mockLocalDataSource.getCachedRecipe(any()))
        .thenAnswer((_) async => testRecipeModelJson);
    when(() => mockLocalDataSource.cacheRecipe(any()))
        .thenAnswer((_) async {});
  }
  
  void setupRemoteSuccess() {
    when(() => mockRemoteDataSource.getRecipesByLetter(any()))
        .thenAnswer((_) async => [testRecipeModel, testRecipeModel2]);
    when(() => mockRemoteDataSource.getRecipeById(any()))
        .thenAnswer((_) async => testRecipeModel);
  }
  
  void setupNetworkError() {
    when(() => mockRemoteDataSource.getRecipesByLetter(any()))
        .thenThrow(const ConnectionFailure(message: 'No internet connection'));
    when(() => mockRemoteDataSource.getRecipeById(any()))
        .thenThrow(const ConnectionFailure(message: 'No internet connection'));
  }

  group('Network to cache flow', () {
    test('should fetch from remote and store in cache when cache is empty', () async {
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => null);
      when(() => mockLocalDataSource.cacheRecipesByLetter(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockRemoteDataSource.getRecipesByLetter('A'))
          .thenAnswer((_) async => [testRecipeModel, testRecipeModel2]);
      when(() => mockLocalDataSource.isFavorite(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked(any()))
          .thenAnswer((_) async => false);
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should return recipes from remote source'),
        (r) => expect(r.length, 2)
      );
      
      verify(() => mockRemoteDataSource.getRecipesByLetter('A')).called(1);
      verify(() => mockLocalDataSource.cacheRecipesByLetter('A', any())).called(1);
    });
    
    test('should use cache when available and not expired', () async {
      final cachedData = [
        testRecipeModelJson,
      ];
      
      when(() => mockLocalDataSource.isFavorite('1'))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked('1'))
          .thenAnswer((_) async => false);
      
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => cachedData);
      when(() => mockLocalDataSource.isFavorite(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked(any()))
          .thenAnswer((_) async => false);
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isRight(), true);
      
      verify(() => mockLocalDataSource.getCachedRecipesByLetter('A')).called(1);
      verifyNever(() => mockRemoteDataSource.getRecipesByLetter('A'));
    });
  });
  
  group('Error handling and recovery', () {
    test('should return connection failure when network error occurs', () async {
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => null);
      setupNetworkError();
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<ConnectionFailure>()),
        (r) => fail('Should not return success')
      );
    });
    
    test('should recover from network error using cached data', () async {
      final cachedData = [
        testRecipeModelJson,
      ];
      
      when(() => mockLocalDataSource.isFavorite('1'))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked('1'))
          .thenAnswer((_) async => false);
      
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => cachedData);
      when(() => mockLocalDataSource.isFavorite(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked(any()))
          .thenAnswer((_) async => false);
      setupNetworkError();
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should recover using cache'),
        (r) => expect(r.length, 1)
      );
    });
    
    test('should handle server errors appropriately', () async {
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => null);
      when(() => mockRemoteDataSource.getRecipesByLetter('A'))
          .thenThrow(const ServerFailure(message: 'Server error', statusCode: 500));
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<ServerFailure>()),
        (r) => fail('Should not return success')
      );
    });
  });
  
  group('Testing network errors', () {
    test('should convert network exceptions to Failure types', () async {
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => null);
      when(() => mockRemoteDataSource.getRecipesByLetter('A'))
          .thenThrow(Exception('Network error'));
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isLeft(), true);
      expect(
        result.fold((l) => l.runtimeType, (r) => r),
        equals(ServerFailure),
      );
    });
    
    test('should retry failed network requests appropriately', () async {
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => null);
      
      when(() => mockRemoteDataSource.getRecipesByLetter('A'))
          .thenThrow(const ConnectionFailure(message: 'Temporary connection issue'));
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isLeft(), true);
    });
  });
  
  group('Testing cache failures', () {
    test('should handle cache read failures gracefully', () async {
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => null); 
      setupRemoteSuccess();
      when(() => mockLocalDataSource.isFavorite(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.cacheRecipesByLetter(any(), any()))
          .thenAnswer((_) async {});
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isRight(), true);
    });
    
    test('should return appropriate error on cache write failures', () async {
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => null);
      setupRemoteSuccess();
      when(() => mockLocalDataSource.isFavorite(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.cacheRecipesByLetter(any(), any()))
          .thenThrow(Exception('Cache write error'));
      
      final result = await repository.getRecipesByLetter('A');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should have returned a failure')
      );
    });
    
    test('should return cache failure when managing favorites fails', () async {
      when(() => mockLocalDataSource.isFavorite('1'))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.addFavorite('1'))
          .thenThrow(Exception('Cache update error'));
      
      final result = await repository.toggleFavorite('1');
      
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<CacheFailure>()),
        (r) => fail('Should return cache failure')
      );
    });
  });
  
  group('Data transformation verification', () {
    test('should transform RecipeModel to Recipe domain entity correctly', () async {
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => null);
      when(() => mockRemoteDataSource.getRecipesByLetter('A'))
          .thenAnswer((_) async => [testRecipeModel]);
      when(() => mockLocalDataSource.isFavorite(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.cacheRecipesByLetter(any(), any()))
          .thenAnswer((_) async {});
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should return success'),
        (r) {
          final recipe = r.first;
          expect(recipe, isA<Recipe>());
          expect(recipe.id, testRecipeModel.id);
          expect(recipe.name, testRecipeModel.name);
          expect(recipe.ingredients.length, testRecipeModel.ingredients.length);
          expect(recipe.ingredients[0].name, testRecipeModel.ingredients[0].name);
          expect(recipe.ingredients[0].measure, testRecipeModel.ingredients[0].measure);
          expect(recipe.instructions, testRecipeModel.instructions);
          expect(recipe.thumbnailUrl, testRecipeModel.thumbnailUrl);
          expect(recipe.isFavorite, false);
          expect(recipe.isBookmarked, false);
        }
      );
    });
    
    test('should handle malformed API responses gracefully', () async {
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => null);
      
      final malformedModel = RecipeModel(
        id: '3',
        name: '',  
        ingredients: [],  
        instructions: '',
        thumbnailUrl: 'invalid-url',
      );
      
      when(() => mockRemoteDataSource.getRecipesByLetter('A'))
          .thenAnswer((_) async => [malformedModel]);
      when(() => mockLocalDataSource.isFavorite(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.cacheRecipesByLetter(any(), any()))
          .thenAnswer((_) async {});
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should handle malformed data gracefully'),
        (r) {
          final recipe = r.first;
          expect(recipe.name, '');
          expect(recipe.ingredients, isEmpty);
        }
      );
    });
  });
  
  group('Preserving user properties (favorites/bookmarks)', () {
    test('should preserve favorite status when fetching recipes', () async {
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => null);
      when(() => mockRemoteDataSource.getRecipesByLetter('A'))
          .thenAnswer((_) async => [testRecipeModel]);
      
      when(() => mockLocalDataSource.isFavorite('1'))
          .thenAnswer((_) async => true);
      when(() => mockLocalDataSource.isBookmarked('1'))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.cacheRecipesByLetter(any(), any()))
          .thenAnswer((_) async {});
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should return success'),
        (r) {
          final recipe = r.first;
          expect(recipe.isFavorite, true);
          expect(recipe.isBookmarked, false);
        }
      );
    });
    
    test('should toggle favorite status correctly', () async {
      when(() => mockLocalDataSource.isFavorite('1'))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked('1'))
          .thenAnswer((_) async => false);
      
      when(() => mockLocalDataSource.addFavorite('1'))
          .thenAnswer((_) async {});
      
      setupCacheSuccess();
      
      final result = await repository.toggleFavorite('1');
      
      expect(result.isRight(), true);
      verify(() => mockLocalDataSource.addFavorite('1')).called(1);
    });
    
    test('should toggle bookmark status correctly', () async {
      when(() => mockLocalDataSource.getCachedRecipe('1'))
          .thenAnswer((_) async => testRecipeModelJson);
      when(() => mockLocalDataSource.cacheRecipe(any()))
          .thenAnswer((_) async {});
          
      when(() => mockLocalDataSource.isFavorite('1'))
          .thenAnswer((_) async => false);
          
      when(() => mockLocalDataSource.isBookmarked('1'))
          .thenAnswer((_) async => true);
      
      when(() => mockLocalDataSource.removeBookmark('1'))
          .thenAnswer((_) async {});

      when(() => mockRemoteDataSource.getRecipeById('1'))
          .thenAnswer((_) async => testRecipeModel);
      
      final result = await repository.toggleBookmark('1');
      
      expect(result.isRight(), true);
      verify(() => mockLocalDataSource.removeBookmark('1')).called(1);
    });
  });
  
  group('Cache policy implementation (cache-first vs network-first)', () {
    test('should implement cache-first policy correctly', () async {
      final cachedData = [
        testRecipeModelJson,
      ];
      
      when(() => mockLocalDataSource.isFavorite('1'))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked('1'))
          .thenAnswer((_) async => false);
      
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => cachedData);
      when(() => mockLocalDataSource.isFavorite(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked(any()))
          .thenAnswer((_) async => false);
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isRight(), true);
      
      verify(() => mockLocalDataSource.getCachedRecipesByLetter('A')).called(1);
      verifyNever(() => mockRemoteDataSource.getRecipesByLetter('A'));
    });
    
    test('should fall back to network when cache is empty', () async {
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => null);
      setupRemoteSuccess();
      when(() => mockLocalDataSource.isFavorite(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.cacheRecipesByLetter(any(), any()))
          .thenAnswer((_) async {});
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isRight(), true);
      
      verify(() => mockLocalDataSource.getCachedRecipesByLetter('A')).called(1);
      verify(() => mockRemoteDataSource.getRecipesByLetter('A')).called(1);
    });
  });
  
  group('Offline mode behavior', () {
    test('should work in offline mode with cached data', () async {
      final cachedData = [
        testRecipeModelJson,
      ];
      
      when(() => mockLocalDataSource.isFavorite('1'))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked('1'))
          .thenAnswer((_) async => false);
      
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => cachedData);
      when(() => mockLocalDataSource.isFavorite(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked(any()))
          .thenAnswer((_) async => false);
      
      setupNetworkError();
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isRight(), true);
      
      result.fold(
        (l) => fail('Should return cached data in offline mode'),
        (r) => expect(r.length, 1)
      );
    });
    
    test('should handle being offline with empty cache', () async {
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => null);
      
      setupNetworkError();
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<ConnectionFailure>()),
        (r) => fail('Should return connection failure when offline with no cache')
      );
    });
  });
  
  group('Pagination handling', () {
    test('should handle paginated results correctly', () async {
      final largeResultSet = List.generate(
        50,
        (i) => RecipeModel(
          id: '$i',
          name: 'Recipe $i',
          ingredients: [const IngredientModel(name: 'Ingredient', measure: '1 unit')],
          instructions: 'Instructions',
          thumbnailUrl: 'https://example.com/image$i.jpg',
        ),
      );
      
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => null);
      when(() => mockRemoteDataSource.getRecipesByLetter('A'))
          .thenAnswer((_) async => largeResultSet);
      when(() => mockLocalDataSource.isFavorite(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.cacheRecipesByLetter(any(), any()))
          .thenAnswer((_) async {});
      
      final result = await repository.getRecipesByLetter('A');
      
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should return success with large dataset'),
        (r) => expect(r.length, 50)
      );
    });
  });
  
  group('Idempotency (consistent results for identical calls)', () {
    test('should return consistent results for repeated identical calls', () async {
      when(() => mockLocalDataSource.getCachedRecipesByLetter('A'))
          .thenAnswer((_) async => null);
      setupRemoteSuccess();
      when(() => mockLocalDataSource.isFavorite(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.cacheRecipesByLetter(any(), any()))
          .thenAnswer((_) async {});

      final result1 = await repository.getRecipesByLetter('A');
      final result2 = await repository.getRecipesByLetter('A');
      
      expect(result1.isRight(), true);
      expect(result2.isRight(), true);
      
      final recipes1 = result1.fold((_) => [], (r) => r);
      final recipes2 = result2.fold((_) => [], (r) => r);
      
      expect(recipes1.length, recipes2.length);
      
      for (var i = 0; i < recipes1.length; i++) {
        expect(recipes1[i].id, recipes2[i].id);
        expect(recipes1[i].name, recipes2[i].name);
      }
    });
  });
  
  group('Concurrency handling', () {
    test('should handle multiple simultaneous requests correctly', () async {
      when(() => mockLocalDataSource.getCachedRecipesByLetter(any()))
          .thenAnswer((_) async => null);
      setupRemoteSuccess();
      when(() => mockLocalDataSource.isFavorite(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.isBookmarked(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.cacheRecipesByLetter(any(), any()))
          .thenAnswer((_) async {});
      
      final futures = await Future.wait([
        repository.getRecipesByLetter('A'),
        repository.getRecipesByLetter('B'),
        repository.getRecipesByLetter('C'),
      ]);
      
      for (final result in futures) {
        expect(result.isRight(), true);
      }
    });
    
    test('should handle concurrent operations', () async {
      
      when(() => mockLocalDataSource.isFavorite('1'))
          .thenAnswer((_) async => false); 
      when(() => mockLocalDataSource.isBookmarked('1'))
          .thenAnswer((_) async => false); 
      when(() => mockLocalDataSource.addFavorite('1'))
          .thenAnswer((_) async => {}); 
      
      when(() => mockLocalDataSource.getCachedRecipe('1'))
          .thenAnswer((_) async => testRecipeModelJson); 
      when(() => mockLocalDataSource.cacheRecipe(any()))
          .thenAnswer((_) async => {}); 
      
      when(() => mockRemoteDataSource.getRecipeById('1'))
          .thenAnswer((_) async => testRecipeModel);
          
      final result = await repository.toggleFavorite('1');
      
      expect(result.isRight(), true);
      
      verify(() => mockLocalDataSource.isFavorite('1')).called(greaterThanOrEqualTo(1));
      verify(() => mockLocalDataSource.addFavorite('1')).called(1);
      verify(() => mockLocalDataSource.getCachedRecipe('1')).called(greaterThanOrEqualTo(1));
    });
  });
  
  group('Repository Integration Tests', () {
    final testRecipeModels = [
      RecipeModel(
        id: '1', 
        name: 'Recipe 1',
        instructions: 'Instructions 1',
        thumbnailUrl: 'https://example.com/image1.jpg',
      ),
      RecipeModel(
        id: '2', 
        name: 'Recipe 2',
        instructions: 'Instructions 2',
        thumbnailUrl: 'https://example.com/image2.jpg',
      ),
    ];
    
    final List<Map<String, dynamic>> testRecipeJsonList = testRecipeModels
        .map((model) => {
              'idMeal': model.id,
              'strMeal': model.name,
              'strInstructions': model.instructions,
              'strMealThumb': model.thumbnailUrl,
            })
        .toList();
    
    group('End-to-End Data Flow', () {
      test('should fetch from remote data source and return domain entities', () async {
        when(() => mockRemoteDataSource.getRecipesByLetter(any()))
            .thenAnswer((_) async => testRecipeModels);
        when(() => mockLocalDataSource.cacheRecipesByLetter(any(), any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.maintainCache())
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.getCachedRecipesByLetter(any()))
            .thenAnswer((_) async => null); 
        when(() => mockLocalDataSource.isFavorite(any()))
            .thenAnswer((_) async => false);
        when(() => mockLocalDataSource.isBookmarked(any()))
            .thenAnswer((_) async => false);
            
        final result = await repository.getRecipesByLetter('A');
        
        verify(() => mockRemoteDataSource.getRecipesByLetter('A')).called(1);
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected right with recipes, got left with failure'),
          (recipes) {
            expect(recipes.length, testRecipeModels.length);
            expect(recipes[0].id, testRecipeModels[0].id);
            expect(recipes[0].name, testRecipeModels[0].name);
          },
        );
      });
    });
    
    group('Remote-Local Integration', () {
      test('should cache data retrieved from remote source', () async {
        when(() => mockRemoteDataSource.getRecipesByLetter(any()))
            .thenAnswer((_) async => testRecipeModels);
        when(() => mockLocalDataSource.cacheRecipesByLetter(any(), any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.maintainCache())
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.getCachedRecipesByLetter(any()))
            .thenAnswer((_) async => null); 
        when(() => mockLocalDataSource.isFavorite(any()))
            .thenAnswer((_) async => false);
        when(() => mockLocalDataSource.isBookmarked(any()))
            .thenAnswer((_) async => false);
        
        await repository.getRecipesByLetter('A');
        
        verify(() => mockRemoteDataSource.getRecipesByLetter('A')).called(1);
        verify(() => mockLocalDataSource.cacheRecipesByLetter('A', any())).called(1);
      });
      
      test('should handle favorite state during toggle operation', () async {
        when(() => mockLocalDataSource.getCachedRecipe(any()))
            .thenAnswer((_) async => testRecipeJsonList[0]);
        when(() => mockLocalDataSource.isFavorite('1'))
            .thenAnswer((_) async => false);
        when(() => mockLocalDataSource.isBookmarked('1'))
            .thenAnswer((_) async => false);
        when(() => mockLocalDataSource.addFavorite(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.cacheRecipe(any()))
            .thenAnswer((_) async => {});
        
        final result = await repository.toggleFavorite('1');
        
        verify(() => mockLocalDataSource.getCachedRecipe('1')).called(1);
        verify(() => mockLocalDataSource.addFavorite('1')).called(1);
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected right with recipe, got left with failure'),
          (recipe) {
            expect(recipe.id, '1');
          },
        );
      });
    });
    
    group('Cache-Network Synchronization', () {
      test('should fetch and cache bookmark information', () async {
        when(() => mockLocalDataSource.getBookmarkIds())
            .thenAnswer((_) async => ['1', '2']);
        when(() => mockLocalDataSource.getCachedRecipe('1'))
            .thenAnswer((_) async => testRecipeJsonList[0]);
        when(() => mockLocalDataSource.getCachedRecipe('2'))
            .thenAnswer((_) async => testRecipeJsonList[1]);
        when(() => mockLocalDataSource.isFavorite(any()))
            .thenAnswer((_) async => false);
        when(() => mockLocalDataSource.isBookmarked(any()))
            .thenAnswer((_) async => true);
        
        final result = await repository.getBookmarks();
        
        verify(() => mockLocalDataSource.getBookmarkIds()).called(1);
        verify(() => mockLocalDataSource.getCachedRecipe('1')).called(1);
        verify(() => mockLocalDataSource.getCachedRecipe('2')).called(1);
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected right with recipes, got left with failure'),
          (recipes) {
            expect(recipes.length, 2);
            expect(recipes[0].isBookmarked, true);
          },
        );
      });
      
      test('should fetch and cache favorite information', () async {
        when(() => mockLocalDataSource.getFavoriteIds())
            .thenAnswer((_) async => ['1']);
        when(() => mockLocalDataSource.getCachedRecipe('1'))
            .thenAnswer((_) async => testRecipeJsonList[0]);
        when(() => mockLocalDataSource.isFavorite(any()))
            .thenAnswer((_) async => true);
        when(() => mockLocalDataSource.isBookmarked(any()))
            .thenAnswer((_) async => false);
        
        final result = await repository.getFavorites();
        
        verify(() => mockLocalDataSource.getFavoriteIds()).called(1);
        verify(() => mockLocalDataSource.getCachedRecipe('1')).called(1);
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected right with recipes, got left with failure'),
          (recipes) {
            expect(recipes.length, 1);
            expect(recipes[0].isFavorite, true);
          },
        );
      });
    });
    
    group('Data Transformation', () {
      test('should transform cached JSON to Recipe entities', () async {
        when(() => mockLocalDataSource.getFavoriteIds())
            .thenAnswer((_) async => ['1']);
        when(() => mockLocalDataSource.getCachedRecipe('1'))
            .thenAnswer((_) async => testRecipeJsonList[0]);
        when(() => mockLocalDataSource.isFavorite(any()))
            .thenAnswer((_) async => true);
        when(() => mockLocalDataSource.isBookmarked(any()))
            .thenAnswer((_) async => false);
        
        final result = await repository.getFavorites();
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected right with recipes, got left with failure'),
          (recipes) {
            expect(recipes[0], isA<Recipe>());  
            expect(recipes[0].id, '1');
            expect(recipes[0].name, 'Recipe 1');
            expect(recipes[0].isFavorite, true);
          },
        );
      });
    });
    
    group('State Management', () {
      test('should preserve recipe data when toggling bookmark state', () async {
        when(() => mockLocalDataSource.getCachedRecipe(any()))
            .thenAnswer((_) async => testRecipeJsonList[0]);
        when(() => mockLocalDataSource.isFavorite('1'))
            .thenAnswer((_) async => false);
        when(() => mockLocalDataSource.isBookmarked('1'))
            .thenAnswer((_) async => false);
        when(() => mockLocalDataSource.addBookmark(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.cacheRecipe(any()))
            .thenAnswer((_) async => {});
        
        final result = await repository.toggleBookmark('1');
        
        verify(() => mockLocalDataSource.getCachedRecipe('1')).called(1);
        verify(() => mockLocalDataSource.addBookmark('1')).called(1);
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected right with recipe, got left with failure'),
          (recipe) {
            expect(recipe.id, '1');
          },
        );
      });
    });
    
    group('Error Propagation', () {
      test('should convert remote datasource exceptions to domain failures', () async {
        when(() => mockRemoteDataSource.getRecipesByLetter(any()))
            .thenThrow(Exception('Server error'));
        when(() => mockLocalDataSource.getCachedRecipesByLetter(any()))
            .thenAnswer((_) async => null); 
        when(() => mockLocalDataSource.maintainCache())
            .thenAnswer((_) async => {});
        
        final result = await repository.getRecipesByLetter('A');
        
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<Failure>());
            
          },
          (_) => fail('Expected left with failure, got right with recipe'),
        );
      });
      
      test('should handle local cache failures gracefully', () async {
        when(() => mockLocalDataSource.getFavoriteIds())
            .thenThrow(Exception('Cache error'));
        when(() => mockLocalDataSource.maintainCache())
            .thenAnswer((_) async => {});
        
        final result = await repository.getFavorites();
        
        expect(result, isA<Either<Failure, List<Recipe>>>());
      });
    });
    
    group('Multiple Data Source Coordination', () {
      test('should coordinate between remote data and local state', () async {
        when(() => mockRemoteDataSource.getRecipesByLetter(any()))
            .thenAnswer((_) async => testRecipeModels);
        when(() => mockLocalDataSource.getCachedRecipesByLetter(any()))
            .thenAnswer((_) async => null); 
        when(() => mockLocalDataSource.maintainCache())
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.cacheRecipesByLetter(any(), any()))
            .thenAnswer((_) async => {});
        
        when(() => mockLocalDataSource.isFavorite('1'))
            .thenAnswer((_) async => true);
        when(() => mockLocalDataSource.isBookmarked('1'))
            .thenAnswer((_) async => true);
        when(() => mockLocalDataSource.isFavorite(any()))
            .thenAnswer((_) async => false);
        when(() => mockLocalDataSource.isBookmarked(any()))
            .thenAnswer((_) async => false);
        
        final result = await repository.getRecipesByLetter('A');
        
        verify(() => mockRemoteDataSource.getRecipesByLetter('A')).called(1);
        verify(() => mockLocalDataSource.cacheRecipesByLetter('A', any())).called(1);
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected right with recipes, got left with failure'),
          (recipes) {
            expect(recipes.length, testRecipeModels.length);
            expect(recipes[0].id, testRecipeModels[0].id);
          },
        );
      });
    });
    
    group('Contract Compliance', () {
      test('repository should implement RecipeRepository interface methods', () {
        expect(repository, isA<RecipeRepository>());
        
        expect(repository.getRecipesByLetter, isA<Function>());
        expect(repository.toggleFavorite, isA<Function>());
        expect(repository.toggleBookmark, isA<Function>());
        expect(repository.getFavorites, isA<Function>());
        expect(repository.getBookmarks, isA<Function>());
      });
      
      test('repository methods should return types matching the interface contract', () async {
        when(() => mockRemoteDataSource.getRecipesByLetter(any()))
            .thenAnswer((_) async => testRecipeModels);
        when(() => mockLocalDataSource.cacheRecipesByLetter(any(), any()))
            .thenAnswer((_) async => {});
        
        final result = await repository.getRecipesByLetter('A');
        
        expect(result, isA<Either<Failure, List<Recipe>>>());
      });
    });
  });
}