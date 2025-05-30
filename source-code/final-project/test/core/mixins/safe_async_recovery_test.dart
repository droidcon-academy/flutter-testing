import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/mixins/safe_async_mixin.dart';

class MockPrimaryService extends Mock {
  Future<String> fetchData();
}

class MockFallbackService extends Mock {
  Future<String> fetchData();
}

class MockCacheService extends Mock {
  Future<String?> getCachedData();
  Future<void> setCachedData(String data);
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error occurred']);
  
  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Authentication error occurred']);
  
  @override
  String toString() => 'AuthException: $message';
}

class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server error occurred']);
  
  @override
  String toString() => 'ServerException: $message';
}

mixin RecoveryAsyncMixin on SafeAsyncMixin {
  Future<T?> safeAsyncWithRecovery<T>({
    required Future<T> Function() primaryOperation,
    required Future<T> Function() fallbackOperation,
    bool Function(Exception)? shouldUseFallback,
    bool acceptDegradedResult = false,
  }) async {
    if (disposed) {
      return null;
    }
    
    try {
      return await safeAsync(primaryOperation);
    } on Exception catch (e) {
      
      if (shouldUseFallback != null && !shouldUseFallback(e)) {
        rethrow; 
      }
      
      try {
        final fallbackResult = await safeAsync(fallbackOperation);
        return fallbackResult;
      } on Exception catch (fallbackError) {
        debugPrint('[RecoveryAsyncMixin] Fallback operation failed: $fallbackError');

        if (acceptDegradedResult) {
          return _getDegradedResult<T>();
        }
        rethrow;
      }
    }
  }
  
  T? _getDegradedResult<T>() {
    if (T == String) return '' as T;
    if (T == List) return <dynamic>[] as T;
    if (T == Map) return <String, dynamic>{} as T;
    if (T == int) return 0 as T;
    if (T == double) return 0.0 as T;
    if (T == bool) return false as T;
    return null;
  }
}

class TestRecoveryObject with SafeAsyncMixin, RecoveryAsyncMixin {
  final MockPrimaryService primaryService;
  final MockFallbackService fallbackService;
  final MockCacheService cacheService;
  
  TestRecoveryObject({
    required this.primaryService,
    required this.fallbackService,
    required this.cacheService,
  });
  
  Future<String?> fetchWithRecovery({
    bool acceptDegradedResult = false,
    bool Function(Exception)? shouldUseFallback,
  }) async {
    return safeAsyncWithRecovery(
      primaryOperation: () => primaryService.fetchData(),
      fallbackOperation: () => fallbackService.fetchData(),
      shouldUseFallback: shouldUseFallback,
      acceptDegradedResult: acceptDegradedResult,
    );
  }
  
  Future<String?> fetchWithCacheRecovery() async {
    return safeAsyncWithRecovery(
      primaryOperation: () => primaryService.fetchData(),
      fallbackOperation: () async {
        final cachedData = await cacheService.getCachedData();
        if (cachedData != null) {
          return cachedData;
        }
        
        final fallbackData = await fallbackService.fetchData();
        await cacheService.setCachedData(fallbackData);
        return fallbackData;
      },
      acceptDegradedResult: true,
    );
  }
}

void main() {
  late MockPrimaryService mockPrimaryService;
  late MockFallbackService mockFallbackService;
  late MockCacheService mockCacheService;
  late TestRecoveryObject testObject;
  
  setUp(() {
    mockPrimaryService = MockPrimaryService();
    mockFallbackService = MockFallbackService();
    mockCacheService = MockCacheService();
    
    testObject = TestRecoveryObject(
      primaryService: mockPrimaryService,
      fallbackService: mockFallbackService,
      cacheService: mockCacheService,
    );
    
    registerFallbackValue('default-data');
  });
  
  tearDown(() {
    testObject.markDisposed();
  });
  
  group('SafeAsyncMixin with recovery - Basic Fallback', () {
    test('should use fallback when primary operation fails', () async {
      when(() => mockPrimaryService.fetchData())
        .thenThrow(NetworkException('Primary service failed'));
      when(() => mockFallbackService.fetchData())
        .thenAnswer((_) => Future.value('Fallback data'));
        
      final result = await testObject.fetchWithRecovery();
      
      expect(result, equals('Fallback data'));
      verify(() => mockPrimaryService.fetchData()).called(1);
      verify(() => mockFallbackService.fetchData()).called(1);
    });
    
    test('should not use fallback for certain error types', () async {
      when(() => mockPrimaryService.fetchData())
        .thenThrow(AuthException('Unauthorized'));
      
      expect(
        () => testObject.fetchWithRecovery(
          shouldUseFallback: (e) => e is! AuthException,
        ),
        throwsA(isA<AuthException>())
      );
      
      verify(() => mockPrimaryService.fetchData()).called(1);
      verifyNever(() => mockFallbackService.fetchData());
    });
    
    test('should use fallback only for specific error types', () async {
      when(() => mockPrimaryService.fetchData())
        .thenThrow(NetworkException('Network unavailable'));
      when(() => mockFallbackService.fetchData())
        .thenAnswer((_) => Future.value('Fallback data'));
        
      final result = await testObject.fetchWithRecovery(
        shouldUseFallback: (e) => e is NetworkException,
      );
      
      expect(result, equals('Fallback data'));
      verify(() => mockPrimaryService.fetchData()).called(1);
      verify(() => mockFallbackService.fetchData()).called(1);
    });
  });
  
  group('SafeAsyncMixin with recovery - Graceful Degradation', () {
    test('should return degraded result when all operations fail and degraded results accepted', () async {
      when(() => mockPrimaryService.fetchData())
        .thenThrow(NetworkException('Primary failed'));
      when(() => mockFallbackService.fetchData())
        .thenThrow(ServerException('Fallback failed'));
        
      final result = await testObject.fetchWithRecovery(
        acceptDegradedResult: true,
      );
      
      expect(result, equals(''));
      verify(() => mockPrimaryService.fetchData()).called(1);
      verify(() => mockFallbackService.fetchData()).called(1);
    });
    
    test('should fail completely when not accepting degraded results', () async {
      when(() => mockPrimaryService.fetchData())
        .thenThrow(NetworkException('Primary failed'));
      when(() => mockFallbackService.fetchData())
        .thenThrow(ServerException('Fallback failed'));
        
      try {
        await testObject.fetchWithRecovery(acceptDegradedResult: false);
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<Exception>());
      }
      
      verify(() => mockPrimaryService.fetchData()).called(1);
      verify(() => mockFallbackService.fetchData()).called(1);
    });
    
    test('should handle error-specific degradation strategies', () async {
      when(() => mockPrimaryService.fetchData())
        .thenThrow(NetworkException('Network unavailable'));
      when(() => mockFallbackService.fetchData())
        .thenThrow(ServerException('Server error'));
        
      final result = await testObject.fetchWithRecovery(
        acceptDegradedResult: true,
        shouldUseFallback: (e) => true,
      );
      
      expect(result, equals(''));
      verify(() => mockPrimaryService.fetchData()).called(1);
      verify(() => mockFallbackService.fetchData()).called(1);
    });
  });
  
  group('SafeAsyncMixin with recovery - Cache-Based Recovery', () {
    test('should recover using cache when primary service fails', () async {
      when(() => mockPrimaryService.fetchData())
        .thenThrow(NetworkException('Primary failed'));
      when(() => mockCacheService.getCachedData())
        .thenAnswer((_) => Future.value('Cached data'));
        
      final result = await testObject.fetchWithCacheRecovery();
      
      expect(result, equals('Cached data'));
      verify(() => mockPrimaryService.fetchData()).called(1);
      verify(() => mockCacheService.getCachedData()).called(1);
      verifyNever(() => mockFallbackService.fetchData());
    });
    
    test('should update cache when using fallback service', () async {
      when(() => mockPrimaryService.fetchData())
        .thenThrow(NetworkException('Primary failed'));
      when(() => mockCacheService.getCachedData())
        .thenAnswer((_) => Future.value(null));
      when(() => mockFallbackService.fetchData())
        .thenAnswer((_) => Future.value('Fallback data'));
      when(() => mockCacheService.setCachedData(any()))
        .thenAnswer((_) => Future.value());
        
      final result = await testObject.fetchWithCacheRecovery();
      
      expect(result, equals('Fallback data'));
      verify(() => mockPrimaryService.fetchData()).called(1);
      verify(() => mockCacheService.getCachedData()).called(1);
      verify(() => mockFallbackService.fetchData()).called(1);
      verify(() => mockCacheService.setCachedData('Fallback data')).called(1);
    });
    
    test('should return degraded result when all operations fail', () async {
      when(() => mockPrimaryService.fetchData())
        .thenThrow(NetworkException('Primary failed'));
      when(() => mockCacheService.getCachedData())
        .thenAnswer((_) => Future.value(null));
      when(() => mockFallbackService.fetchData())
        .thenThrow(ServerException('Fallback failed'));
      when(() => mockCacheService.setCachedData(any()))
        .thenThrow(Exception('Cache write failed'));
        
      final result = await testObject.fetchWithCacheRecovery();
      
      expect(result, equals(''));
      verify(() => mockPrimaryService.fetchData()).called(1);
      verify(() => mockCacheService.getCachedData()).called(1);
      verify(() => mockFallbackService.fetchData()).called(1);
    });
  });
}
