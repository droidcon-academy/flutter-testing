import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipevault/core/mixins/safe_async_mixin.dart';

class TestState {
  final int value;
  final bool isLoading;
  final String? error;

  TestState({
    this.value = 0,
    this.isLoading = false,
    this.error,
  });

  TestState copyWith({
    int? value,
    bool? isLoading,
    String? error,
  }) {
    return TestState(
      value: value ?? this.value,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestState &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => value.hashCode ^ isLoading.hashCode ^ (error?.hashCode ?? 0);

  @override
  String toString() => 'TestState(value: $value, isLoading: $isLoading, error: $error)';
}

class ApiService {
  Future<int> slowOperation() async => 1;
  Future<int> fastOperation() async => 2;
  Future<int> errorOperation() async => throw Exception('Operation failed');
}

class MockApiService extends Mock implements ApiService {}

class TestViewModel extends StateNotifier<TestState> with SafeAsyncMixin {
  final MockApiService apiService;
  final List<String> operationLog = [];

  TestViewModel(this.apiService) : super(TestState());

  Future<void> runSlowOperation(Completer<void> completer) async {
    operationLog.add('slow_started');
    state = state.copyWith(isLoading: true);
    
    try {
      final result = await safeAsync(() async {
        await completer.future;
        return await apiService.slowOperation();
      });
      
      if (mounted) {
        state = state.copyWith(
          value: result,
          isLoading: false,
        );
        operationLog.add('slow_completed');
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
        operationLog.add('slow_error: ${e.toString()}');
      }
    }
  }

  Future<void> runFastOperation() async {
    operationLog.add('fast_started');
    state = state.copyWith(isLoading: true);
    
    try {
      final result = await safeAsync(() async {
        return await apiService.fastOperation();
      });
      
      if (mounted) {
        state = state.copyWith(
          value: result,
          isLoading: false,
        );
        operationLog.add('fast_completed');
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
        operationLog.add('fast_error: ${e.toString()}');
      }
    }
  }

  Future<void> runErrorOperation() async {
    operationLog.add('error_started');
    state = state.copyWith(isLoading: true);
    
    try {
      await safeAsync(() async {
        return await apiService.errorOperation();
      });
      
      if (mounted) {
        operationLog.add('error_completed_unexpected');
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
        operationLog.add('error_failed');
      }
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    operationLog.add('disposed');
    super.dispose();
  }
}


void main() {
  setUpAll(() {
    registerFallbackValue(TestState());
  });
  
  group('ViewModel race condition handling', () {
    late MockApiService mockApiService;
    late TestViewModel viewModel;
    late List<TestState> stateHistory;

    setUp(() {
      mockApiService = MockApiService();
      
      when(() => mockApiService.slowOperation()).thenAnswer((_) async => 100);
      when(() => mockApiService.fastOperation()).thenAnswer((_) async => 200);
      when(() => mockApiService.errorOperation()).thenAnswer((_) async => throw Exception('Operation failed'));
      
      viewModel = TestViewModel(mockApiService);
      stateHistory = [];
      
      viewModel.addListener((state) {
        stateHistory.add(state);
      });
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('should handle overlapping operations with proper state management', () async {
      final slowCompleter = Completer<void>();
      final fastCompleter = Completer<void>();
      
      reset(mockApiService);
      
      when(() => mockApiService.slowOperation()).thenAnswer((_) async {
        await slowCompleter.future;
        return 1;
      });
      
      when(() => mockApiService.fastOperation()).thenAnswer((_) async {
        await fastCompleter.future;
        return 2;
      });

      final slowFuture = viewModel.runSlowOperation(Completer<void>()..complete());
      
      await Future.delayed(const Duration(milliseconds: 10));
      
      final fastFuture = viewModel.runFastOperation();
      
      slowCompleter.complete();
      await Future.delayed(const Duration(milliseconds: 10));
      fastCompleter.complete();
      
      await Future.wait([slowFuture, fastFuture]);
      await Future.delayed(const Duration(milliseconds: 50)); 
      
      expect(viewModel.state.value, equals(2), reason: 'Final state should reflect the fast operation');
      expect(viewModel.state.isLoading, equals(false));
      expect(viewModel.state.error, isNull);
      
      expect(viewModel.operationLog, contains('slow_started'));
      expect(viewModel.operationLog, contains('fast_started'));
      expect(viewModel.operationLog, contains('slow_completed'));
      expect(viewModel.operationLog, contains('fast_completed'));
      
      expect(stateHistory.last.value, equals(2));
    });

    test('should handle errors during race conditions without affecting later operations', () async {
      final errorApiService = MockApiService();
      final errorViewModel = TestViewModel(errorApiService);
      
      when(() => errorApiService.errorOperation()).thenAnswer((_) async {
        throw Exception('Operation failed intentionally');
      });
      
      await errorViewModel.runErrorOperation().catchError((_) {});
      await Future.delayed(const Duration(milliseconds: 20));
      
      expect(errorViewModel.operationLog, contains('error_failed'));
      expect(errorViewModel.state.error, isNotNull);
      
      errorViewModel.dispose();
      
      final successApiService = MockApiService();
      final successViewModel = TestViewModel(successApiService);
      
      when(() => successApiService.fastOperation()).thenAnswer((_) async {
        return 200;
      });
      
      await successViewModel.runFastOperation();
      await Future.delayed(const Duration(milliseconds: 20));
      
      expect(successViewModel.operationLog, contains('fast_completed'));
      expect(successViewModel.state.value, equals(200));
      expect(successViewModel.state.isLoading, equals(false));
      expect(successViewModel.state.error, isNull);
      
      successViewModel.dispose();
    });

    test('should maintain consistent state when multiple operations update the same property', () async {
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();
      final completer3 = Completer<void>();
      
      when(() => mockApiService.slowOperation()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 1;
      });
      
      when(() => mockApiService.fastOperation()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 2;
      });

      viewModel.runSlowOperation(completer1);
      viewModel.runSlowOperation(completer2);
      viewModel.runSlowOperation(completer3);
      
      completer3.complete();
      await Future.delayed(const Duration(milliseconds: 10));
      completer2.complete();
      await Future.delayed(const Duration(milliseconds: 10));
      completer1.complete();
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(viewModel.state.value, equals(1));
      expect(viewModel.state.isLoading, equals(false));
      
      final loadingStates = stateHistory.map((s) => s.isLoading).toList();
      expect(loadingStates, contains(true));
      expect(loadingStates.last, equals(false));
    });
    
    test('should properly handle operation that completes after ViewModel disposal', () async {
      final testApiService = MockApiService();
      final testViewModel = TestViewModel(testApiService);
      
      final operationCompleter = Completer<void>();
      when(() => testApiService.slowOperation()).thenAnswer((_) async {
        await operationCompleter.future;
        return 999; 
      });
      
      testViewModel.runSlowOperation(Completer<void>()..complete());
      await Future.delayed(const Duration(milliseconds: 10));
      
      final logBeforeDisposal = List<String>.from(testViewModel.operationLog);
      
      testViewModel.dispose();
      operationCompleter.complete();
      
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(logBeforeDisposal, contains('slow_started'));
      expect(testViewModel.operationLog, contains('disposed'));
      
      expect(testViewModel.operationLog, isNot(contains('slow_completed')));
    });
  });
}
