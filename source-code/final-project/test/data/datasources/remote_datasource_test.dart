import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/errors/failure.dart';
import 'package:recipevault/data/datasources/remote_datasource.dart';
import 'package:recipevault/data/models/recipe_model.dart';
import 'package:recipevault/services/api_service.dart';

class MockAPIService extends Mock implements APIService {}

void main() {
  late RemoteDataSource remoteDataSource;
  late MockAPIService mockApiService;

  setUp(() {
    mockApiService = MockAPIService();
    remoteDataSource = RemoteDataSource(mockApiService);
    registerFallbackValue({'fallback': 'value'});
  });

  final sampleRecipeJson = {
    'idMeal': '12345',
    'strMeal': 'Test Recipe',
    'strCategory': 'Test Category',
    'strArea': 'Test Area',
    'strInstructions': 'Test Instructions',
    'strMealThumb': 'https://example.com/image.jpg',
    'strIngredient1': 'Ingredient 1',
    'strMeasure1': 'Measure 1',
  };

  final sampleRecipeJson2 = {
    'idMeal': '67890',
    'strMeal': 'Another Recipe',
    'strCategory': 'Another Category',
    'strArea': 'Another Area',
    'strInstructions': 'More Instructions',
    'strMealThumb': 'https://example.com/another-image.jpg',
    'strIngredient1': 'Another Ingredient',
    'strMeasure1': 'Another Measure',
  };

  final sampleSearchResponse = {
    'meals': [sampleRecipeJson, sampleRecipeJson2]
  };

  final sampleLookupResponse = {
    'meals': [sampleRecipeJson]
  };

  final emptyResponse = {
    'meals': null
  };

  final malformedResponse = {
    'meals': [
      {'invalidField': 'value'} 
    ]
  };

  group('API Endpoint Interactions', () {
    test('getRecipesByLetter calls correct endpoint with parameters', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => sampleSearchResponse);

      await remoteDataSource.getRecipesByLetter('A');

      verify(() => mockApiService.get(
            '/search.php',
            queryParams: {'f': 'A'},
          )).called(1);
    });

    test('getRecipeById calls correct endpoint with parameters', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => sampleLookupResponse);
      await remoteDataSource.getRecipeById('12345');

      verify(() => mockApiService.get(
            '/lookup.php',
            queryParams: {'i': '12345'},
          )).called(1);
    });
  });

  group('Response Parsing', () {
    test('getRecipesByLetter correctly parses response into RecipeModel list',
        () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => sampleSearchResponse);
      final result = await remoteDataSource.getRecipesByLetter('A');

      expect(result, isA<List<RecipeModel>>());
      expect(result.length, 2);
      expect(result[0].id, '12345');
      expect(result[0].name, 'Test Recipe');
      expect(result[1].id, '67890');
      expect(result[1].name, 'Another Recipe');
    });

    test('getRecipeById correctly parses response into RecipeModel', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => sampleLookupResponse);

      final result = await remoteDataSource.getRecipeById('12345');
      expect(result, isA<RecipeModel>());
      expect(result?.id, '12345');
      expect(result?.name, 'Test Recipe');
      expect(result?.instructions, 'Test Instructions');
      expect(result?.thumbnailUrl, 'https://example.com/image.jpg');
    });

    test('getRecipesByLetter returns empty list when meals is null', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => emptyResponse);

      final result = await remoteDataSource.getRecipesByLetter('A');

      expect(result, isA<List<RecipeModel>>());
      expect(result, isEmpty);
    });

    test('getRecipeById returns null when meals is null', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => emptyResponse);

      final result = await remoteDataSource.getRecipeById('12345');

      expect(result, isNull);
    });

    test('getRecipeById returns null when meals is empty list', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {'meals': []});

      final result = await remoteDataSource.getRecipeById('12345');

      expect(result, isNull);
    });
  });

  group('Request Parameters Verification', () {
    test('getRecipesByLetter sends correct letter parameter', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => sampleSearchResponse);

      await remoteDataSource.getRecipesByLetter('B');

      verify(() => mockApiService.get(
            any(),
            queryParams: {'f': 'B'},
          )).called(1);
    });

    test('getRecipeById handles string ID correctly', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => sampleLookupResponse);
      await remoteDataSource.getRecipeById('string-id');

      verify(() => mockApiService.get(
            any(),
            queryParams: {'i': 'string-id'},
          )).called(1);
    });

    test('getRecipeById handles int ID correctly', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => sampleLookupResponse);
      await remoteDataSource.getRecipeById(12345);

      verify(() => mockApiService.get(
            any(),
            queryParams: {'i': '12345'},
          )).called(1);
    });

    test('getRecipeById rejects null ID', () async {
      expect(
        () => remoteDataSource.getRecipeById(null),
        throwsA(
          isA<ServerFailure>().having(
            (e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );

      verifyNever(() => mockApiService.get(any(), queryParams: any(named: 'queryParams')));
    });

    test('getRecipeById rejects empty ID', () async {
      expect(
        () => remoteDataSource.getRecipeById(''),
        throwsA(
          isA<ServerFailure>().having(
            (e) => e.statusCode,
            'statusCode',
            400,
          ),
        ),
      );

      verifyNever(() => mockApiService.get(any(), queryParams: any(named: 'queryParams')));
    });
  });

  group('Response Scenarios', () {
    test('handles successful response with data', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => sampleLookupResponse);
      final result = await remoteDataSource.getRecipeById('12345');

      expect(result, isNotNull);
      expect(result?.id, '12345');
    });

    test('handles empty response', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => emptyResponse);
      final result = await remoteDataSource.getRecipeById('12345');

      expect(result, isNull);
    });

    test('handles malformed response data', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => malformedResponse);

      expect(
        () => remoteDataSource.getRecipeById('12345'),
        throwsA(isA<ServerFailure>().having(
          (e) => e.statusCode,
          'statusCode',
          422, 
        )),
      );
    });
  });

  group('Error Handling', () {
    test('propagates ServerFailure from API service', () async {
      
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ServerFailure(
            message: 'Internal server error',
            statusCode: 500,
          ));

      expect(
        () => remoteDataSource.getRecipesByLetter('A'),
        throwsA(isA<ServerFailure>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );
    });

    test('propagates ConnectionFailure from API service', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ConnectionFailure(
            message: 'No internet connection',
          ));

      expect(
        () => remoteDataSource.getRecipesByLetter('A'),
        throwsA(isA<ConnectionFailure>()),
      );
    });

    test('handles JSON parsing errors in getRecipeById', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
                'meals': [null]
              });

      expect(
        () => remoteDataSource.getRecipeById('12345'),
        throwsA(isA<ServerFailure>().having(
          (e) => e.statusCode,
          'statusCode',
          422,
        )),
      );
    });

    test('handles unexpected exceptions', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Unexpected error'));

      expect(
        () => remoteDataSource.getRecipesByLetter('A'),
        throwsA(isA<ServerFailure>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );
    });

    test('handles timeout errors', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(TimeoutException('Connection timed out'));

      expect(
        () => remoteDataSource.getRecipesByLetter('A'),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('URL Parameter Encoding', () {
    test('encodes special characters in recipe ID', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => sampleLookupResponse);
      await remoteDataSource.getRecipeById('special/id?with&chars');

      verify(() => mockApiService.get(
            '/lookup.php',
            queryParams: {'i': 'special/id?with&chars'},
          )).called(1);
    });

    test('encodes special characters in letter parameter', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => sampleSearchResponse);
      await remoteDataSource.getRecipesByLetter('+');

      verify(() => mockApiService.get(
            '/search.php',
            queryParams: {'f': '+'},
          )).called(1);
    });
  });

  group('Network Connectivity', () {
    test('handles connection failure', () async {
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ConnectionFailure(
            message: 'No internet connection',
          ));

      expect(
        () => remoteDataSource.getRecipeById('12345'),
        throwsA(
          isA<ConnectionFailure>().having(
            (e) => e.message,
            'message',
            'No internet connection',
          ),
        ),
      );
    });

    test('provides meaningful error messages for connection issues', () async {
      const errorMessage = 'Weak network signal';
      when(() => mockApiService.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenThrow(const ConnectionFailure(
            message: errorMessage,
          ));

      expect(
        () => remoteDataSource.getRecipeById('12345'),
        throwsA(
          isA<ConnectionFailure>().having(
            (e) => e.message,
            'message',
            errorMessage,
          ),
        ),
      );
    });
  });
}
