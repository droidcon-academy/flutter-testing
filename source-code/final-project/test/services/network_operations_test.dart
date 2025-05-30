
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/errors/failure.dart';
import 'package:recipevault/services/api_service.dart';

class MockDio extends Mock implements Dio {}

class FakeRequestOptions extends Fake implements RequestOptions {}
class FakeResponse<T> extends Fake implements Response<T> {}
class FakeDioException extends Fake implements DioException {}

void main() {
  late APIService apiService;
  late MockDio mockDio;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeResponse<Map<String, dynamic>>());
    registerFallbackValue(FakeDioException());
  });

  setUp(() {
    mockDio = MockDio();
    apiService = APIService(mockDio);
  });

  group('Response parsing and validation', () {
    test('Standard response parsing with all fields', () async {

      final responseData = {
        'meals': [
          {
            'idMeal': '52772',
            'strMeal': 'Teriyaki Chicken Casserole',
            'strCategory': 'Chicken',
            'strArea': 'Japanese',
            'strInstructions': 'Preheat oven to 350° F...',
            'strTags': 'Meat,Casserole',
            'strYoutube': 'https://www.youtube.com/watch?v=4aZr5hZXP_s',
          }
        ]
      };
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/lookup.php'),
      ));
      

      final result = await apiService.get('/lookup.php', queryParams: {'i': '52772'});
      

      expect(result, equals(responseData));
      expect(result['meals'], isA<List>());
      expect(result['meals'][0]['idMeal'], '52772');
      expect(result['meals'][0]['strMeal'], 'Teriyaki Chicken Casserole');
      expect(result['meals'][0]['strCategory'], 'Chicken');
    });

    test('JSON response validation with different data types', () async {

      final responseData = {
        'meals': [
          {
            'idMeal': '52772',  
            'popularity': 4.5,   
            'ingredients': [     
              'chicken',
              'broccoli',
              'rice'
            ],
            'isVegetarian': false, 
          }
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
      
      // Act
      final result = await apiService.get('/test');
      
      // Assert
      expect(result['meals'][0]['idMeal'], isA<String>());
      expect(result['meals'][0]['popularity'], isA<double>());
      expect(result['meals'][0]['ingredients'], isA<List>());
      expect(result['meals'][0]['isVegetarian'], isA<bool>());
    });

    test('Empty response handling (empty object)', () async {
      
      final responseData = <String, dynamic>{};
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/test'),
      ));
      
      
      final result = await apiService.get('/test');
      
      
      expect(result, isEmpty);
    });
    
    test('Empty response handling (null response)', () async {
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: null,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/test'),
      ));
      
      expect(
        () async => await apiService.get('/test'),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('Empty response handling (empty array)', () async {
      final responseData = {'meals': []};
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async => Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/test'),
      ));
      
      final result = await apiService.get('/test');
      
      expect(result['meals'], isEmpty);
    });

    test('Malformed response handling (invalid JSON structure)', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenThrow(DioException(
        type: DioExceptionType.badResponse,
        error: 'Invalid JSON',
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          statusCode: 200,
          data: 'Not a JSON response',
          requestOptions: RequestOptions(path: '/test'),
        ),
      ));
      
      expect(
        () async => await apiService.get('/test'),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('Malformed response handling (unexpected structure)', () async {
      final responseData = {
        'unexpected_key': 'unexpected_value'
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
      
      expect(result.containsKey('meals'), isFalse);
      expect(result.containsKey('unexpected_key'), isTrue);
    });
  });

  group('Network condition simulation', () {
    test('Slow network handling with timeout configuration', () async {
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
        expect((e as ConnectionFailure).message, contains('Connection timeout'));
      }
    });

    test('Intermittent connection handling', () async {
      int callCount = 0;
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) {
        if (callCount == 0) {
          callCount++;
          throw DioException(
            type: DioExceptionType.connectionError,
            requestOptions: RequestOptions(path: '/test'),
            message: 'Network error',
          );
        } else {
          return Future.value(Response(
            data: {'success': true},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/test'),
          ));
        }
      });
      
      try {
        await apiService.get('/test');
        fail('Expected ConnectionFailure to be thrown');
      } catch (e) {
        expect(e, isA<ConnectionFailure>());
      }

      final result = await apiService.get('/test');
      expect(result['success'], isTrue);
    });

    test('Request cancellation handling', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenThrow(DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(path: '/test'),
        message: 'Request cancelled',
      ));
      
      try {
        await apiService.get('/test');
        fail('Expected ServerFailure to be thrown');
      } catch (e) {
        expect(e, isA<ServerFailure>());
        expect((e as ServerFailure).message, contains('Unknown error'));
      }
    });

    test('Long running request with delayed response', () async {
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 2));
        return Response(
          data: {'success': true, 'message': 'Delayed response'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );
      });
      
      final result = await apiService.get('/test');
      
      expect(result['success'], isTrue);
      expect(result['message'], 'Delayed response');
    });
  });

  
  group('Retry mechanisms (demonstration)', () {
    test('Auto-retry simulation for transient errors', () async {
      
      int callCount = 0;
      final responseData = {'success': true};
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) {
        callCount++;
        if (callCount < 3) {
          throw DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/test'),
          );
        } else {
          return Future.value(Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/test'),
          ));
        }
      });
      
      Future<JsonMap> getWithRetry(String endpoint, {int maxRetries = 3}) async {
        int attempts = 0;
        while (attempts < maxRetries) {
          try {
            attempts++;
            return await apiService.get(endpoint);
          } on ConnectionFailure {
            if (attempts >= maxRetries) rethrow;
            await Future.delayed(Duration(milliseconds: 100 * attempts));
          } on ServerFailure {
            rethrow;
          }
        }
        throw const ConnectionFailure(message: 'Max retries exceeded');
      }
      
      final result = await getWithRetry('/test');
      
      expect(result, equals(responseData));
      expect(callCount, 3); 
    });

    test('Backoff strategy simulation', () async {
      final requestTimes = <DateTime>[];
      int callCount = 0;
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) {
        requestTimes.add(DateTime.now());
        callCount++;
        if (callCount < 3) {
          throw DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/test'),
          );
        } else {
          return Future.value(Response(
            data: {'success': true},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/test'),
          ));
        }
      });
      
      Future<JsonMap> getWithExponentialBackoff(String endpoint, {int maxRetries = 3}) async {
        int attempts = 0;
        while (attempts < maxRetries) {
          try {
            attempts++;
            return await apiService.get(endpoint);
          } on ConnectionFailure {
            if (attempts >= maxRetries) rethrow;
            final backoffMs = 200 * (1 << (attempts - 1)); 
            await Future.delayed(Duration(milliseconds: backoffMs));
          } on ServerFailure {
            rethrow;
          }
        }
        throw const ConnectionFailure(message: 'Max retries exceeded');
      }
      
      final result = await getWithExponentialBackoff('/test');
      
      expect(result['success'], isTrue);
      expect(callCount, 3);
      expect(requestTimes.length, 3);
      
      if (requestTimes.length >= 3) {
        final firstInterval = requestTimes[1].difference(requestTimes[0]).inMilliseconds;
        final secondInterval = requestTimes[2].difference(requestTimes[1]).inMilliseconds;
        
        expect(secondInterval > firstInterval, isTrue);
      }
    });

    test('Safe retry behavior with idempotent operations', () async {
      int callCount = 0;
      
      when(() => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
      )).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          throw DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/lookup.php'),
          );
        } else {
          return Future.value(Response(
            data: {'meals': [{'idMeal': '52772', 'strMeal': 'Teriyaki Chicken Casserole'}]},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/lookup.php'),
          ));
        }
      });
      
      Future<JsonMap> getWithRetry(String endpoint, Map<String, dynamic>? params, {int maxRetries = 2}) async {
        for (int i = 0; i < maxRetries; i++) {
          try {
            return await apiService.get(endpoint, queryParams: params);
          } on ConnectionFailure {
            if (i == maxRetries - 1) rethrow;
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
        throw const ConnectionFailure(message: 'Max retries exceeded');
      }
      
      final result = await getWithRetry('/lookup.php', {'i': '52772'});
      
      expect(result['meals'][0]['idMeal'], '52772');
      expect(callCount, 2);
    });
  });
}
