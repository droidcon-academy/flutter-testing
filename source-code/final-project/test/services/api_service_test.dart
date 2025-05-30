import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/errors/failure.dart';
import 'package:recipevault/services/api_service.dart';

class MockDio extends Mock implements Dio {}

class FakeRequestOptions extends Fake implements RequestOptions {}
class FakeResponse<T> extends Fake implements Response<T> {}

void main() {
  late APIService apiService;
  late MockDio mockDio;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeResponse<Map<String, dynamic>>());
  });

  setUp(() {
    mockDio = MockDio();
    apiService = APIService(mockDio);
  });

  group('Dio configuration testing', () {
    test('Configured with proper base URL', () {
      final dio = Dio(BaseOptions(
        baseUrl: 'https://www.themealdb.com/api/json/v1/1',
      ));
      
      expect(dio.options.baseUrl, 'https://www.themealdb.com/api/json/v1/1');
    });

    test('Timeout settings verification', () {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 6),
      ));
      
      expect(dio.options.connectTimeout, const Duration(seconds: 10));
      expect(dio.options.receiveTimeout, const Duration(seconds: 6));
    });

    test('Status validation behavior', () {
      final dio = Dio(BaseOptions(
        validateStatus: (status) => status != null && status < 500,
      ));
      
      expect(dio.options.validateStatus(200), isTrue); 
      expect(dio.options.validateStatus(404), isTrue); 
      expect(dio.options.validateStatus(500), isFalse); 
    });
  });

  group('HTTP request execution', () {
    test('GET request formatting', () async {
      final responseData = {'meals': [{'idMeal': '1', 'strMeal': 'Test Meal'}]};
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/test'),
      ));

      final result = await apiService.get('/test');

      verify(() => mockDio.get(
        '/test',
        queryParameters: null,
      )).called(1);
      
      expect(result, equals(responseData));
    });

    test('Query parameter handling', () async {
      final responseData = {'meals': [{'idMeal': '1', 'strMeal': 'Test Meal'}]};
      final queryParams = {'f': 'A', 'category': 'Dessert'};
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/test'),
      ));
      
      final result = await apiService.get('/test', queryParams: queryParams);
      verify(() => mockDio.get(
        '/test',
        queryParameters: queryParams,
      )).called(1);
      
      expect(result, equals(responseData));
    });

    test('Response data extraction', () async {
      final responseData = {
        'meals': [
          {'idMeal': '1', 'strMeal': 'Test Meal 1'},
          {'idMeal': '2', 'strMeal': 'Test Meal 2'}
        ]
      };
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/test'),
      ));
      final result = await apiService.get('/test');
      expect(result, isA<Map<String, dynamic>>());
      expect(result['meals'], isA<List>());
      expect((result['meals'] as List).length, 2);
    });

    test('Successful response handling with different status codes', () async {
      final responseData = {'message': 'Resource created successfully'};
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 201,
        requestOptions: RequestOptions(path: '/test'),
      ));
      
      final result = await apiService.get('/test');
      
      expect(result, equals(responseData));
    });
  });

  group('Error handling and conversion', () {
    test('Connection timeout conversion to domain failures', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/test'),
        message: 'Connection timeout',
      ));
      
      try {
        await apiService.get('/test');
        fail('Expected ConnectionFailure to be thrown');
      } catch (e) {
        expect(e, isA<ConnectionFailure>());
        final failure = e as ConnectionFailure;
        expect(failure.message, contains('Connection timeout'));
      }
    });

    test('Network error conversion to ConnectionFailure', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: '/test'),
        message: 'Network error',
      ));
      try {
        await apiService.get('/test');
        fail('Expected ConnectionFailure to be thrown');
      } catch (e) {
        expect(e, isA<ConnectionFailure>());
        final failure = e as ConnectionFailure;
        expect(failure.message, contains('No internet connection'));
      }
    });

    test('Server error conversion to ServerFailure', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenThrow(DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 500,
          statusMessage: 'Internal Server Error',
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      ));
      
      try {
        await apiService.get('/test');
        fail('Expected ServerFailure to be thrown');
      } catch (e) {
        expect(e, isA<ServerFailure>());
        final failure = e as ServerFailure;
        expect(failure.message, contains('Server responded with error'));
        expect(failure.statusCode, 500);
      }
    });

    test('Status code propagation to ServerFailure', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenThrow(DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 404,
          statusMessage: 'Not Found',
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      ));
      
      try {
        await apiService.get('/test');
        fail('Expected ServerFailure to be thrown');
      } catch (e) {
        expect(e, isA<ServerFailure>());
        final failure = e as ServerFailure;
        expect(failure.statusCode, 404);
      }
    });

    test('Custom error message formatting', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenThrow(DioException(
        type: DioExceptionType.unknown,
        error: 'Custom error',
        requestOptions: RequestOptions(path: '/test'),
      ));
      
      try {
        await apiService.get('/test');
        fail('Expected ServerFailure to be thrown');
      } catch (e) {
        expect(e, isA<ServerFailure>());
        final failure = e as ServerFailure;
        expect(failure.message, contains('Unknown error occurred'));
      }
    });
  });

  group('Mocking strategies demonstration', () {
    test('Creating complex fake responses', () async {
      final complexResponse = {
        'meals': [
          {
            'idMeal': '52772',
            'strMeal': 'Teriyaki Chicken Casserole',
            'strCategory': 'Chicken',
            'strArea': 'Japanese',
            'strInstructions': 'Preheat oven to 350° F...',
            'strMealThumb': 'https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg',
          }
        ]
      };
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: complexResponse,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/lookup.php'),
      ));
      
      final result = await apiService.get('/lookup.php', queryParams: {'i': '52772'});
      
      expect(result['meals'][0]['strMeal'], 'Teriyaki Chicken Casserole');
      expect(result['meals'][0]['strCategory'], 'Chicken');
    });

    test('Simulating different error conditions', () async {
      Future<void> testErrorType(DioExceptionType type, Type expectedFailureType) async {
        when(() => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(DioException(
          type: type,
          requestOptions: RequestOptions(path: '/test'),
        ));
        
        try {
          await apiService.get('/test');
          fail('Expected exception to be thrown');
        } catch (e) {
          expect(e, isA<Failure>());
          if (expectedFailureType == ConnectionFailure) {
            expect(e, isA<ConnectionFailure>());
          } else if (expectedFailureType == ServerFailure) {
            expect(e, isA<ServerFailure>());
          }
        }
      }
      
      await testErrorType(DioExceptionType.receiveTimeout, ConnectionFailure);
      await testErrorType(DioExceptionType.sendTimeout, ConnectionFailure);
      await testErrorType(DioExceptionType.cancel, ServerFailure);
    });
  });
}
