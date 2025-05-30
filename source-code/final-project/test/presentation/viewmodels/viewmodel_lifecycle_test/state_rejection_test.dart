import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/core/mixins/safe_async_mixin.dart';

class StateChangeTracker {
  int successCount = 0;
  int rejectionCount = 0;
  int errorCount = 0;
  final List<String> log = [];
  
  void logStateChange(String message) {
    log.add('${DateTime.now().millisecondsSinceEpoch}: $message');
    debugPrint(message);
  }
  
  void recordSuccess() => successCount++;
  void recordRejection() => rejectionCount++;
  void recordError() => errorCount++;
  
  bool get hasRejections => rejectionCount > 0;
}

class TestState {
  final int counter;
  final String? message;
  final bool isLoading;
  
  TestState({
    this.counter = 0,
    this.message,
    this.isLoading = false,
  });
  
  TestState copyWith({
    int? counter,
    String? message,
    bool? isLoading,
  }) {
    return TestState(
      counter: counter ?? this.counter,
      message: message ?? this.message,
      isLoading: isLoading ?? this.isLoading,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestState &&
          runtimeType == other.runtimeType &&
          counter == other.counter &&
          message == other.message &&
          isLoading == other.isLoading;

  @override
  int get hashCode => counter.hashCode ^ (message?.hashCode ?? 0) ^ isLoading.hashCode;
  
  @override
  String toString() => 'TestState(counter: $counter, message: $message, isLoading: $isLoading)';
}

class TestViewModel extends StateNotifier<TestState> with SafeAsyncMixin {
  final StateChangeTracker tracker;
  
  TestViewModel(this.tracker) : super(TestState()) {
    tracker.logStateChange('TestViewModel created');
  }
  
  void incrementSync() {
    try {
      if (mounted) {
        state = state.copyWith(counter: state.counter + 1);
        tracker.logStateChange('incrementSync succeeded: ${state.counter}');
        tracker.recordSuccess();
      } else {
        tracker.logStateChange('incrementSync rejected: ViewModel not mounted');
        tracker.recordRejection();
      }
    } catch (e) {
      tracker.logStateChange('incrementSync error: $e');
      tracker.recordError();
    }
  }
  
  Future<void> incrementAsync({int delay = 100}) async {
    tracker.logStateChange('incrementAsync started with delay $delay ms');
    
    try {
      await Future.delayed(Duration(milliseconds: delay));
      if (mounted) {
        state = state.copyWith(counter: state.counter + 1);
        tracker.logStateChange('incrementAsync succeeded: ${state.counter}');
        tracker.recordSuccess();
      } else {
        tracker.logStateChange('incrementAsync rejected: ViewModel not mounted');
        tracker.recordRejection();
      }
    } catch (e) {
      tracker.logStateChange('incrementAsync error: $e');
      tracker.recordError();
    }
  }
  
  Future<void> incrementWithSafeAsync({int delay = 100}) async {
    tracker.logStateChange('incrementWithSafeAsync started');
    
    try {
      final result = await safeAsync(() async {
        await Future.delayed(Duration(milliseconds: delay));
        return 1;
      });
      
      if (mounted) {
        state = state.copyWith(counter: state.counter + (result as int));
        tracker.logStateChange('incrementWithSafeAsync succeeded: ${state.counter}');
        tracker.recordSuccess();
      } else {
        tracker.logStateChange('incrementWithSafeAsync rejected: ViewModel not mounted');
        tracker.recordRejection();
      }
    } catch (e) {
      if (e is StateError && e.message.contains('disposed')) {
        tracker.logStateChange('incrementWithSafeAsync properly rejected: $e');
        tracker.recordRejection();
      } else {
        tracker.logStateChange('incrementWithSafeAsync error: $e');
        tracker.recordError();
      }
    }
  }
  
  void updateComplexState() {
    try {
      if (mounted) {
        state = state.copyWith(
          counter: state.counter + 1,
          message: 'Updated at ${DateTime.now()}',
          isLoading: !state.isLoading,
        );
        tracker.logStateChange('updateComplexState succeeded');
        tracker.recordSuccess();
      } else {
        tracker.logStateChange('updateComplexState rejected: ViewModel not mounted');
        tracker.recordRejection();
      }
    } catch (e) {
      tracker.logStateChange('updateComplexState error: $e');
      tracker.recordError();
    }
  }
  
  void updateStateWithoutCheck() {
    try {
      state = state.copyWith(counter: state.counter + 1);
      tracker.logStateChange('updateStateWithoutCheck succeeded (!)');
      tracker.recordSuccess();
    } catch (e) {
      tracker.logStateChange('updateStateWithoutCheck error: $e');
      tracker.recordError();
    }
  }
  
  void multipleStateUpdates() {
    if (!mounted) {
      tracker.logStateChange('multipleStateUpdates rejected: ViewModel not mounted');
      tracker.recordRejection();
      return;
    }
    
    try {
      state = state.copyWith(isLoading: true);
      state = state.copyWith(counter: state.counter + 1);
      state = state.copyWith(
        counter: state.counter + 1,
        message: 'Multiple updates',
      );
      
      state = state.copyWith(isLoading: false);
      
      tracker.logStateChange('multipleStateUpdates succeeded');
      tracker.recordSuccess();
    } catch (e) {
      tracker.logStateChange('multipleStateUpdates error: $e');
      tracker.recordError();
    }
  }
  
  @override
  void dispose() {
    tracker.logStateChange('TestViewModel disposing');
    super.dispose();
    tracker.logStateChange('TestViewModel disposed');
  }
}

void main() {
  group('State Update Rejection After Disposal', () {
    late StateChangeTracker tracker;
    late TestViewModel viewModel;
    late List<TestState> stateHistory;
    
    setUp(() {
      tracker = StateChangeTracker();
      viewModel = TestViewModel(tracker);
      stateHistory = [];
      
      viewModel.addListener(stateHistory.add);
    });
    
    tearDown(() {
      if (viewModel.mounted) {
        viewModel.dispose();
      }
    });
    
    test('should prevent synchronous state updates after disposal', () async {
      viewModel.incrementSync();
      
      final stateBeforeDisposal = viewModel.state;
      
      viewModel.dispose();
      
      viewModel.incrementSync();
      
      expect(tracker.successCount, equals(1), reason: 'Should have one successful update');
      expect(tracker.rejectionCount, equals(1), reason: 'Should have one rejected update');
      expect(tracker.errorCount, equals(0), reason: 'Should have no errors');
      
      expect(stateBeforeDisposal.counter, equals(1), reason: 'State should remain unchanged after disposal');
    });
    
    test('should prevent async state updates that complete after disposal', () async {
      viewModel.incrementAsync(delay: 50).then((_) {
      });
      
      viewModel.dispose();
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(tracker.rejectionCount, equals(1), reason: 'Should have one rejected update');
      expect(tracker.successCount, equals(0), reason: 'Should have zero successful updates');
    });
    
    test('safeAsync should handle operation completion after disposal', () async {
      final operation = viewModel.incrementWithSafeAsync(delay: 50);
      
      viewModel.dispose();
      
      await operation;
      expect(tracker.rejectionCount, greaterThan(0), reason: 'Should have at least one rejection');
      expect(tracker.successCount, equals(0), reason: 'Should have no successful state updates');
    });
    
    test('should prevent complex state updates after disposal', () async {
      viewModel.updateComplexState();
      
      expect(viewModel.state.counter, equals(1), reason: 'Counter should be updated before disposal');
      expect(tracker.successCount, equals(1), reason: 'Should have one successful update');
      
      viewModel.dispose();
      try {
        viewModel.updateComplexState();
      } catch (e) {
        expect(e is StateError, isTrue, reason: 'Should throw StateError when accessing state after disposal');
      }
      
      expect(tracker.rejectionCount, equals(1), reason: 'Should have one rejected update');
      expect(tracker.successCount, equals(1), reason: 'Should have one successful update (before disposal)');
    });
    
    test('attempting state update without mounted check should error when disposed', () async {
      viewModel.dispose();
      
      viewModel.updateStateWithoutCheck();
      expect(tracker.errorCount, equals(1));
      expect(tracker.successCount, equals(0));
    });
    
    test('should reject all state updates in a sequence when disposed', () async {
      viewModel.dispose();
      
      viewModel.multipleStateUpdates();
      expect(tracker.rejectionCount, equals(1), reason: 'Should have one rejected update sequence');
      expect(tracker.successCount, equals(0), reason: 'Should have no successful updates');
    });
  });
}
