import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/mixins/safe_async_mixin.dart';

class MockApiService extends Mock {
  Future<String> fetchData();
}

class TransientException implements Exception {
  final String message;
  TransientException([this.message = 'Transient error occurred']);
  
  @override
  String toString() => 'TransientException: $message';
}

class PermanentException implements Exception {
  final String message;
  PermanentException([this.message = 'Permanent error occurred']);
  
  @override
  String toString() => 'PermanentException: $message';
}

class RetryTracker {
  final List<DateTime> attemptTimes = [];
  int successCount = 0;
  int failureCount = 0;
  List<Duration> delaysBetweenAttempts = [];
  
  void recordAttempt() {
    attemptTimes.add(DateTime.now());
    
    if (attemptTimes.length > 1) {
      delaysBetweenAttempts.add(
        attemptTimes.last.difference(attemptTimes[attemptTimes.length - 2])
      );
    }
  }
  
  void recordSuccess() => successCount++;
  void recordFailure() => failureCount++;
  
  void reset() {
    attemptTimes.clear();
    delaysBetweenAttempts.clear();
    successCount = 0;
    failureCount = 0;
  }
}

mixin RetryAsyncMixin on SafeAsyncMixin {
  Future<T?> safeAsyncWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 100),
    double backoffFactor = 2.0,
    bool Function(Exception)? shouldRetry,
    RetryTracker? tracker,
  }) async {
    if (disposed) {
      return null;
    }
    
    bool defaultShouldRetry(Exception e) => true;
    
    final retryFunction = shouldRetry ?? defaultShouldRetry;
    int attempts = 0;
    Duration delay = initialDelay;
    
    while (true) {
      attempts++;
      tracker?.recordAttempt();
      try {
        final result = await safeAsync(operation);
        tracker?.recordSuccess();
        return result;
      } on Exception catch (e) {
        if (disposed) {
          tracker?.recordFailure();
          return null;
        }
        
        if (attempts > maxRetries || !retryFunction(e)) {
          tracker?.recordFailure();
          rethrow;
        }
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * backoffFactor).floor());
      }
    }
  }
}

class TestRetryObject with SafeAsyncMixin, RetryAsyncMixin {
  final MockApiService apiService;
  
  TestRetryObject(this.apiService);
  
  Future<String?> fetchWithRetry({
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 100),
    double backoffFactor = 2.0,
    bool Function(Exception)? shouldRetry,
    RetryTracker? tracker,
  }) async {
    return safeAsyncWithRetry(
      operation: () => apiService.fetchData(),
      maxRetries: maxRetries,
      initialDelay: initialDelay,
      backoffFactor: backoffFactor,
      shouldRetry: shouldRetry,
      tracker: tracker,
    );
  }
}

void main() {
  late MockApiService mockApiService;
  late TestRetryObject testObject;
  late RetryTracker tracker;
  
  setUp(() {
    mockApiService = MockApiService();
    testObject = TestRetryObject(mockApiService);
    tracker = RetryTracker();
  });
  
  tearDown(() {
    testObject.markDisposed();
    tracker.reset();
  });
  
  group('SafeAsyncMixin with retry - Basic Functionality', () {
    test('should successfully retry after transient failures', () async {
      int callCount = 0;
      
      when(() => mockApiService.fetchData()).thenAnswer((_) {
        callCount++;
        if (callCount < 3) {
          throw TransientException('Temporary network issue');
        } else {
          return Future.value('Success data');
        }
      });
      
      final result = await testObject.fetchWithRetry(
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 50),
        tracker: tracker,
      );
      
      expect(result, equals('Success data'));
      expect(callCount, 3); 
      expect(tracker.attemptTimes.length, 3);
      expect(tracker.successCount, 1);
      expect(tracker.failureCount, 0);
    });
    
    test('should respect maximum retry count and fail after all attempts', () async {
      int callCount = 0;
      
      when(() => mockApiService.fetchData()).thenAnswer((_) {
        callCount++;
        throw TransientException('Temporary network issue');
      });
      
      expect(
        () => testObject.fetchWithRetry(
          maxRetries: 3,
          initialDelay: const Duration(milliseconds: 50),
          tracker: tracker,
        ),
        throwsA(isA<TransientException>())
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      expect(callCount, 4); 
      expect(tracker.attemptTimes.length, 4);
      expect(tracker.successCount, 0);
      expect(tracker.failureCount, 1);
    });
    
    test('should not retry permanent errors', () async {
      int callCount = 0;
      final permError = PermanentException('Authorization error');
      
      when(() => mockApiService.fetchData()).thenAnswer((_) {
        callCount++;
        throw permError;
      });
      
      late Object caughtError;
      try {
        await testObject.fetchWithRetry(
          maxRetries: 3,
          initialDelay: const Duration(milliseconds: 50),
          tracker: tracker,
          shouldRetry: (e) => e is TransientException,
        );
      } catch (e) {
        caughtError = e;
      }
      
      expect(caughtError, isA<PermanentException>());
      expect(callCount, 1, reason: 'Should make exactly one API call for permanent errors');
      expect(tracker.attemptTimes.length, 1, reason: 'Should record one attempt');
      expect(tracker.successCount, 0, reason: 'Should not record success');
      expect(tracker.failureCount, 1, reason: 'Should record one failure');
    });
  });
  
  group('SafeAsyncMixin with retry - Exponential Backoff', () {
    test('should use exponential backoff for retry delays', () async {
      int callCount = 0;
      
      when(() => mockApiService.fetchData()).thenAnswer((_) {
        callCount++;
        if (callCount < 4) {
          throw TransientException('Temporary network issue');
        } else {
          return Future.value('Success data');
        }
      });
      const initialDelay = Duration(milliseconds: 50);
      const backoffFactor = 2.0;
      
      await testObject.fetchWithRetry(
        maxRetries: 5, 
        initialDelay: initialDelay,
        backoffFactor: backoffFactor,
        tracker: tracker,
      );
      
      expect(callCount, 4);
      expect(tracker.attemptTimes.length, 4);
      expect(tracker.delaysBetweenAttempts.length, 3);
      
      expect(
        tracker.delaysBetweenAttempts[0].inMilliseconds,
        greaterThanOrEqualTo(40), 
      );
      expect(
        tracker.delaysBetweenAttempts[0].inMilliseconds,
        lessThanOrEqualTo(100), 
      );
      
      expect(
        tracker.delaysBetweenAttempts[1].inMilliseconds,
        greaterThanOrEqualTo(90), 
      );
      expect(
        tracker.delaysBetweenAttempts[1].inMilliseconds,
        lessThanOrEqualTo(150), 
      );
      
      expect(
        tracker.delaysBetweenAttempts[2].inMilliseconds,
        greaterThanOrEqualTo(180), 
      );
      expect(
        tracker.delaysBetweenAttempts[2].inMilliseconds,
        lessThanOrEqualTo(300), 
      );
    });
    
    test('should respect custom backoff factor', () async {
      int callCount = 0;
      
      when(() => mockApiService.fetchData()).thenAnswer((_) {
        callCount++;
        if (callCount < 4) {
          throw TransientException('Temporary network issue');
        } else {
          return Future.value('Success data');
        }
      });
      
      const initialDelay = Duration(milliseconds: 50);
      const backoffFactor = 3.0; 
      
      await testObject.fetchWithRetry(
        maxRetries: 5,
        initialDelay: initialDelay,
        backoffFactor: backoffFactor,
        tracker: tracker,
      );
      
      expect(callCount, 4); 
      expect(tracker.attemptTimes.length, 4);
      expect(tracker.delaysBetweenAttempts.length, 3);
      
      expect(
        tracker.delaysBetweenAttempts[1].inMilliseconds,
        greaterThanOrEqualTo(120), 
      );
      expect(
        tracker.delaysBetweenAttempts[1].inMilliseconds,
        lessThanOrEqualTo(200), 
      );
      
      expect(
        tracker.delaysBetweenAttempts[2].inMilliseconds,
        greaterThanOrEqualTo(400),
      );
      expect(
        tracker.delaysBetweenAttempts[2].inMilliseconds,
        lessThanOrEqualTo(550), 
      );
    });
  });
  
  group('SafeAsyncMixin with retry - Cancellation During Retry', () {
    test('should cancel operation when disposed during retry delay', () async {
      int callCount = 0;
      
      when(() => mockApiService.fetchData()).thenAnswer((_) async {
        callCount++;
        throw TransientException('Temporary error');
      });
      
      final future = testObject.fetchWithRetry(
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 100),
        tracker: tracker,
      );
      
      await Future.delayed(const Duration(milliseconds: 50));

      testObject.markDisposed();
      
      final result = await future;
      expect(result, isNull, reason: 'Operation should be cancelled');
      
      expect(callCount, 1);
      
      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 1, reason: 'No additional calls should happen after disposal');
    });
    
    test('should cancel operation after multiple retry attempts', () async {
      int callCount = 0;
      
      when(() => mockApiService.fetchData()).thenAnswer((_) async {
        callCount++;
        throw TransientException('Temporary error');
      });
      
      final future = testObject.fetchWithRetry(
        maxRetries: 5,
        initialDelay: const Duration(milliseconds: 50),
        tracker: tracker,
      );
      
      await Future.delayed(const Duration(milliseconds: 120));
      testObject.markDisposed();
      await Future.delayed(const Duration(milliseconds: 100));
      
      final result = await future;
      expect(result, isNull, reason: 'Operation should be cancelled');
      
      final finalCallCount = callCount;
      
      await Future.delayed(const Duration(milliseconds: 200));
      expect(callCount, finalCallCount, reason: 'No additional calls should happen after disposal');
    });
  });
}
