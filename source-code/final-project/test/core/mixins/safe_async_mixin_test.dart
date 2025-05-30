import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/core/mixins/safe_async_mixin.dart';

class TestObject with SafeAsyncMixin {}

void main() {
  group('SafeAsyncMixin', () {
    late TestObject testObject;

    setUp(() {
      testObject = TestObject();
    });

    tearDown(() {
      testObject.markDisposed();
    });

    group('safeAsync', () {
      test('should execute async action and return result when not disposed', () async {
        final result = await testObject.safeAsync<String>(() async {
          return 'Success';
        });

        expect(result, equals('Success'));
      });

      test('should return null when already disposed', () async {
        testObject.markDisposed();

        final result = await testObject.safeAsync<String>(() async {
          return 'Success';
        });
        expect(result, isNull);
      });

      test('should return null if disposed during async operation', () async {
        final resultFuture = testObject.safeAsync<String>(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 'Success';
        });
        testObject.markDisposed();
        final result = await resultFuture;
        expect(result, isNull);
      });

      test('should rethrow errors if not disposed', () async {
        final future = testObject.safeAsync<String>(() async {
          throw Exception('Test error');
        });
        expect(future, throwsException);
      });

      test('should suppress errors if disposed', () async {
        testObject.markDisposed();

        final result = await testObject.safeAsync<String>(() async {
          throw Exception('Test error');
        });
        expect(result, isNull);
      });

      test('should suppress errors that occur after disposal', () async {
        final resultFuture = testObject.safeAsync<String>(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          throw Exception('Test error');
        });
        testObject.markDisposed();
        final result = await resultFuture;
        expect(result, isNull);
      });
    });

    group('canUpdateState', () {
      test('should return true when not disposed', () {
        expect(testObject.canUpdateState, isTrue);
      });

      test('should return false when disposed', () {
        testObject.markDisposed();
        expect(testObject.canUpdateState, isFalse);
      });
    });

    group('markDisposed', () {
      test('should set disposed flag to true', () {
        testObject.markDisposed();
        expect(testObject.disposed, isTrue);
      });

      test('should prevent future safeAsync calls from executing', () async {
        testObject.markDisposed();
        bool actionExecuted = false;
        await testObject.safeAsync(() async {
          actionExecuted = true;
          return null;
        });
        expect(actionExecuted, isFalse);
      });
    });

    group('checkDisposed', () {
      test('should not throw when not disposed', () {
        expect(() => testObject.checkDisposed(), isNot(throwsA(isA<StateError>())));
      });

      test('should throw StateError when disposed', () {
        testObject.markDisposed();
        expect(
          () => testObject.checkDisposed(),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            'Operation attempted on disposed object',
          )),
        );
      });
    });

    group('safeLog', () {
      testWidgets('should not log when disposed', (WidgetTester tester) async {
        testObject.markDisposed();
        bool logPrinted = false;
        final originalDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          logPrinted = true;
        };
        testObject.safeLog('Test message');
        expect(logPrinted, isFalse);
        debugPrint = originalDebugPrint;
      });

      testWidgets('should log with correct level when not disposed', 
          (WidgetTester tester) async {
        final List<String> logMessages = [];
        final originalDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) logMessages.add(message);
        };
        testObject.safeLog('Test debug', level: LogLevel.debug);
        testObject.safeLog('Test info', level: LogLevel.info);
        testObject.safeLog('Test warning', level: LogLevel.warning);
        testObject.safeLog('Test error', level: LogLevel.error);
        
        expect(logMessages.length, equals(4));
        expect(logMessages[0], contains('Test debug'));
        expect(logMessages[1], contains('Test info'));
        expect(logMessages[2], contains('Test warning'));
        expect(logMessages[3], contains('Test error'));
        
        debugPrint = originalDebugPrint;
      });
    });

    group('Memory leak prevention', () {
      test('ensures operations results are discarded after disposal', () async {
        final future = testObject.safeAsync(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 'Operation completed';
        });
        
        testObject.markDisposed();
        final result = await future;
        expect(result, isNull);
      });
      
      test('prevents callbacks from updating state after disposal', () async {
        bool stateUpdated = false;
        testObject.safeAsync(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          if (testObject.canUpdateState) {
            stateUpdated = true;
          }
          return null;
        });
        testObject.markDisposed();
        await Future.delayed(const Duration(milliseconds: 100));
        expect(stateUpdated, isFalse);
      });
    });
  });
}
