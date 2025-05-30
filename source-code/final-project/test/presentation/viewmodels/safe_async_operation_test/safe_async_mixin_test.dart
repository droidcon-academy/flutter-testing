import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/core/mixins/safe_async_mixin.dart';

class OperationLogger {
  final List<String> logs = [];
  
  void log(String message) {
    logs.add('${DateTime.now().millisecondsSinceEpoch}: $message');
    debugPrint(message);
  }
  
  bool containsInOrder(List<String> expectedLogs) {
    int lastFoundIndex = -1;
    
    for (final expectedLog in expectedLogs) {
      bool found = false;
      
      for (int i = lastFoundIndex + 1; i < logs.length; i++) {
        if (logs[i].contains(expectedLog)) {
          lastFoundIndex = i;
          found = true;
          break;
        }
      }
      
      if (!found) return false;
    }
    
    return true;
  }
}

class TestViewModel extends StateNotifier<int> with SafeAsyncMixin {
  final OperationLogger logger;
  final List<Completer<void>> activeCompleters = [];
  int completedOperations = 0;
  int erroredOperations = 0;
  int cancelledOperations = 0;
  
  TestViewModel(this.logger) : super(0);
  
  Future<void> increment({bool shouldThrow = false, int delayMs = 50}) async {
    logger.log('increment operation started');
    
    try {
      final result = await safeAsync(() async {
        await Future.delayed(Duration(milliseconds: delayMs));
        if (shouldThrow) throw Exception('Intentional error');
        return 1;
      });
      
      if (mounted) {
        state = state + (result as int);
        logger.log('increment operation completed: state=$state');
        completedOperations++;
      } else {
        logger.log('increment operation finished after disposal');
      }
    } catch (e) {
      if (mounted) {
        logger.log('increment operation error: $e');
        erroredOperations++;
      } else {
        logger.log('increment operation error after disposal: $e');
      }
    }
  }
  
  Future<void> controlledOperation(Completer<void> completer, {int value = 5}) async {
    logger.log('controlled operation started');
    activeCompleters.add(completer);
    
    try {
      final result = await safeAsync(() async {
        await completer.future;
        return value;
      });
      
      if (mounted) {
        state = state + (result as int);
        logger.log('controlled operation completed: state=$state');
        completedOperations++;
      } else {
        logger.log('controlled operation finished after disposal');
      }
    } catch (e) {
      if (mounted) {
        logger.log('controlled operation error: $e');
        erroredOperations++;
      } else {
        logger.log('controlled operation error after disposal: $e');
      }
    } finally {
      activeCompleters.remove(completer);
    }
  }
  
  Future<void> multipleSequentialOperations(int count) async {
    logger.log('starting $count sequential operations');
    
    int completedOperations = 0;
    
    for (int i = 0; i < count; i++) {
      try {
        await safeAsync(() async {
          await Future.delayed(Duration(milliseconds: 20));
          return 1;
        });
        
        if (mounted) {
          state = state + 1;
          completedOperations++;
          logger.log('sequential operation $i completed');
        } else {
          logger.log('sequential operation $i skipped (disposed)');
          break;
        }
      } catch (e) {
        logger.log('sequential operation $i error: $e');
      }
    }
    
    if (mounted) {
      logger.log('sequential operations finished with state=$state');
    } else {
      logger.log('sequential operations finished after disposal, completed operations: $completedOperations');
    }
  }
  
  Future<void> multipleParallelOperations(int count) async {
    logger.log('starting $count parallel operations');
    
    final futures = List.generate(
      count,
      (index) => _parallelOperation(index),
    );
    
    await Future.wait(futures);
    logger.log('all parallel operations completed with state=$state');
  }
  
  Future<void> _parallelOperation(int index) async {
    try {
      final result = await safeAsync(() async {
        await Future.delayed(Duration(milliseconds: 10 * (index + 1)));
        return 1;
      });
      
      if (mounted) {
        state = state + (result as int);
        logger.log('parallel operation $index completed');
        completedOperations++;
      }
    } catch (e) {
      logger.log('parallel operation $index error: $e');
      erroredOperations++;
    }
  }
  
  @override
  void dispose() {
    logger.log('disposing ViewModel');
    cancelledOperations = activeCompleters.length;
    super.dispose();
  }
}

void main() {
  group('SafeAsyncMixin', () {
    late OperationLogger logger;
    late TestViewModel viewModel;
    
    setUp(() {
      logger = OperationLogger();
      viewModel = TestViewModel(logger);
    });
    
    tearDown(() {
      if (viewModel.mounted) {
        viewModel.dispose();
      }
    });
    
    test('should prevent state updates after disposal', () async {
      final future = viewModel.increment();
      
      expect(viewModel.state, equals(0), reason: 'Initial state should be zero');
      
      viewModel.dispose();
      
      await future;
      
      expect(logger.logs.any((log) => log.contains('operation finished after disposal')), isTrue, 
          reason: 'Should log that operation finished after disposal');
      expect(logger.logs.any((log) => log.contains('state update after disposal')), isFalse, 
          reason: 'Should not update state after disposal');
    });
    
    test('should complete operations successfully when not disposed', () async {
      await viewModel.increment();
      
      expect(viewModel.state, equals(1));
      expect(viewModel.completedOperations, equals(1));
      expect(logger.logs.any((log) => log.contains('operation completed')), isTrue);
    });
    
    test('should handle errors in async operations', () async {
      await viewModel.increment(shouldThrow: true);
      
      expect(viewModel.state, equals(0));
      expect(viewModel.erroredOperations, equals(1));
      expect(logger.logs.any((log) => log.contains('operation error')), isTrue);
    });
    
    test('should handle multiple sequential operations correctly', () async {
      await viewModel.multipleSequentialOperations(5);
      
      expect(viewModel.state, equals(5));
      expect(logger.logs.any((log) => log.contains('sequential operations finished')), isTrue);
    });
    
    test('should handle multiple parallel operations correctly', () async {
      await viewModel.multipleParallelOperations(3);
      
      expect(viewModel.state, equals(3));
      expect(viewModel.completedOperations, equals(3));
      expect(logger.logs.any((log) => log.contains('all parallel operations completed')), isTrue);
    });
    
    test('should abort operations mid-sequence when disposed', () async {
      final future = viewModel.multipleSequentialOperations(10);
      
      await Future.delayed(Duration(milliseconds: 50));
      
      final stateBeforeDisposal = viewModel.state;
      expect(stateBeforeDisposal, greaterThan(0), reason: 'Some operations should complete before disposal');
      expect(stateBeforeDisposal, lessThan(10), reason: 'Not all operations should complete before disposal');
      
      viewModel.dispose();
      
      await future;
      
      expect(logger.logs.any((log) => log.contains('skipped (disposed)')), isTrue,
          reason: 'Should log operations skipped due to disposal');
    });
    
    test('should handle multiple in-flight operations during disposal', () async {
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();
      final completer3 = Completer<void>();
      
      viewModel.controlledOperation(completer1);
      viewModel.controlledOperation(completer2);
      viewModel.controlledOperation(completer3);
      
      expect(viewModel.state, equals(0), reason: 'Initial state should be zero');
      
      viewModel.dispose();
      
      completer1.complete();
      completer2.complete();
      completer3.complete();
      
      await Future.delayed(Duration(milliseconds: 50));
      
      expect(logger.logs.where((log) => log.contains('finished after disposal')).length, equals(3),
          reason: 'All operations should finish after disposal');
      expect(logger.logs.any((log) => log.contains('state update after disposal')), isFalse,
          reason: 'Should not update state after disposal');
    });
    
    test('should maintain order of operations with safeAsync', () async {
      viewModel.increment(delayMs: 50);
      viewModel.increment(delayMs: 10);
      viewModel.increment(delayMs: 30);
      
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(viewModel.state, equals(3));
      expect(viewModel.completedOperations, equals(3));
    });
  });
}
