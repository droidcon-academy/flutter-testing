import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

mixin SafeAsyncMixin<T> on StateNotifier<T> {
  bool get mounted => !_disposed;
  bool _disposed = false;
  
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
  
  Future<R> safeAsync<R>(Future<R> Function() operation) async {
    if (_disposed) {
      throw StateError('Cannot call safeAsync after disposal');
    }
    
    try {
      return await operation();
    } catch (e) {
      if (_disposed) {
        rethrow;
      }
      rethrow;
    }
  }
}

class CancelledException implements Exception {
  final String message;

  CancelledException([this.message = 'Operation was cancelled']);

  @override
  String toString() => 'CancelledException: $message';
}

class CancelToken {
  bool _isCancelled = false;
  
  bool get isCancelled => _isCancelled;
  
  void cancel() {
    _isCancelled = true;
  }
}

enum OperationStatus { pending, completed, cancelled, error }

class TestState {
  final int value;
  final bool isLoading;
  final String? error;
  final List<String> pendingOperations;

  TestState({
    this.value = 0,
    this.isLoading = false,
    this.error,
    this.pendingOperations = const [],
  });

  TestState copyWith({
    int? value,
    bool? isLoading,
    String? error,
    List<String>? pendingOperations,
  }) {
    return TestState(
      value: value ?? this.value,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pendingOperations: pendingOperations ?? this.pendingOperations,
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
}

class TestApiService {
  final Map<String, OperationStatus> operationStatuses = {};
  final List<String> callLog = [];
  int resourcesCreated = 0;
  int resourcesClosed = 0;
  int errorOccurrenceCount = 0;
  bool shouldThrowOnOperation = false;
  Duration operationDuration = const Duration(milliseconds: 100);
  
  Future<int> longRunningOperation(String operationId, CancelToken token) async {
    callLog.add('longRunningOperation:$operationId');
    operationStatuses[operationId] = OperationStatus.pending;
    
    final completer = Completer<int>();
    
    Future.delayed(operationDuration, () {
      if (token.isCancelled) {
        callLog.add('cancelled:$operationId');
        operationStatuses[operationId] = OperationStatus.cancelled;
        completer.completeError(CancelledException('Operation $operationId was cancelled'));
      } else if (shouldThrowOnOperation) {
        callLog.add('error:$operationId');
        operationStatuses[operationId] = OperationStatus.error;
        errorOccurrenceCount++;
        completer.completeError(Exception('Operation $operationId failed'));
      } else {
        callLog.add('completed:$operationId');
        operationStatuses[operationId] = OperationStatus.completed;
        completer.complete(42); 
      }
    });
    
    return completer.future;
  }
  
  dynamic createResource(String resourceId) {
    callLog.add('createResource:$resourceId');
    resourcesCreated++;
    return resourceId; 
  }
  
  void closeResource(dynamic resource) {
    callLog.add('closeResource:$resource');
    resourcesClosed++;
  }
}

class TestViewModel extends StateNotifier<TestState> with SafeAsyncMixin<TestState> {
  final TestApiService apiService;
  final Map<String, CancelToken> _cancelTokens = {};
  int stateUpdateRejections = 0;
  
  TestViewModel(this.apiService) : super(TestState());
  
  Future<void> startOperation(String operationId) async {
    if (!mounted) {
      stateUpdateRejections++;
      return;
    }
    
    final token = CancelToken();
    _cancelTokens[operationId] = token;
    
    try {
      state = state.copyWith(
        isLoading: true,
        pendingOperations: [...state.pendingOperations, operationId],
      );
      
      final result = await safeAsync(() async {
        if (token.isCancelled) {
          throw CancelledException('Operation was cancelled before execution');
        }
        return await apiService.longRunningOperation(operationId, token);
      });
      
      state = state.copyWith(
        isLoading: false,
        pendingOperations: state.pendingOperations
            .where((id) => id != operationId)
            .toList(),
        value: result,
      );
    } catch (e) {
      if (e is CancelledException) {
      } else if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
          pendingOperations: state.pendingOperations
              .where((id) => id != operationId)
              .toList(),
        );
      } else {
        stateUpdateRejections++;
      }
    } finally {
      _cancelTokens.remove(operationId);
    }
  }
  
  void cancelOperation(String operationId) {
    final token = _cancelTokens[operationId];
    if (token != null) {
      token.cancel();
      
      apiService.operationStatuses[operationId] = OperationStatus.cancelled;
      apiService.callLog.add('cancelled:$operationId');
      
      if (mounted) {
        state = state.copyWith(
          pendingOperations: state.pendingOperations
              .where((id) => id != operationId)
              .toList(),
        );
      }
    }
  }
  
  void cancelAllOperations() {
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
  }
  
  Future<void> operationWithResource(String operationId) async {
    if (!mounted) {
      stateUpdateRejections++;
      return;
    }
    
    final resource = apiService.createResource(operationId);
    
    try {
      final token = CancelToken();
      _cancelTokens[operationId] = token;
      
      state = state.copyWith(
        isLoading: true,
        pendingOperations: [...state.pendingOperations, operationId],
      );
      
      final result = await safeAsync(() async {
        if (token.isCancelled) {
          throw CancelledException('Operation was cancelled before execution');
        }
        return await apiService.longRunningOperation(operationId, token);
      });
      
      state = state.copyWith(
        value: result,
        isLoading: false,
        pendingOperations: state.pendingOperations
            .where((id) => id != operationId)
            .toList(),
      );
    } catch (e) {
      if (e is CancelledException) {
      } else if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
          pendingOperations: state.pendingOperations
              .where((id) => id != operationId)
              .toList(),
        );
      } else {
        stateUpdateRejections++;
      }
    } finally {
      apiService.closeResource(resource);
      
      _cancelTokens.remove(operationId);
    }
  }
  
  @override
  void dispose() {
    cancelAllOperations();
    
    super.dispose();
  }
}

void main() {
  group('CancellationTests', () {
    late TestApiService apiService;
    late TestViewModel viewModel;
    
    setUp(() {
      apiService = TestApiService();
      viewModel = TestViewModel(apiService);
    });
  
  test('operations are cancelled on disposal', () async {
    final operationFuture = viewModel.startOperation('op1');
    
    await Future.delayed(const Duration(milliseconds: 10));
    expect(apiService.operationStatuses['op1'], equals(OperationStatus.pending));
    expect(viewModel.state.pendingOperations, contains('op1'));
    
    final pendingOperations = List<String>.from(viewModel.state.pendingOperations);
    
    viewModel.dispose();
    await Future.delayed(const Duration(milliseconds: 200));
    
    expect(apiService.callLog, contains('cancelled:op1'));
    expect(apiService.operationStatuses['op1'], equals(OperationStatus.cancelled));
  });
    
    test('individual operations can be cancelled', () async {
    apiService.operationDuration = const Duration(milliseconds: 1000);
    
    viewModel.startOperation('op1');
    viewModel.startOperation('op2');
    
    await Future.delayed(const Duration(milliseconds: 50));
    
    expect(apiService.operationStatuses['op1'], equals(OperationStatus.pending));
    expect(apiService.operationStatuses['op2'], equals(OperationStatus.pending));
    
    viewModel.cancelOperation('op1');
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    expect(apiService.operationStatuses['op1'], equals(OperationStatus.cancelled));
    expect(apiService.operationStatuses['op2'], equals(OperationStatus.pending));
    
    expect(viewModel.state.pendingOperations.contains('op1'), isFalse);
    expect(viewModel.state.pendingOperations.contains('op2'), isTrue);
    
    viewModel.cancelOperation('op2');
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    expect(apiService.operationStatuses['op2'], equals(OperationStatus.cancelled));
    
    viewModel.dispose();
  });
    
    test('resources are handled properly', () async {
    viewModel.operationWithResource('op1');
    
    await Future.delayed(const Duration(milliseconds: 10));
    
    expect(apiService.resourcesCreated, equals(1));
    expect(apiService.resourcesClosed, equals(0));
    
    viewModel.dispose();
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    expect(apiService.resourcesClosed, equals(1));
  });
    
    test('all operations can be cancelled', () async {
    viewModel.startOperation('op1');
    viewModel.startOperation('op2');
    viewModel.startOperation('op3');
    
    await Future.delayed(const Duration(milliseconds: 10));
    
    expect(apiService.operationStatuses['op1'], equals(OperationStatus.pending));
    expect(apiService.operationStatuses['op2'], equals(OperationStatus.pending));
    expect(apiService.operationStatuses['op3'], equals(OperationStatus.pending));
    
    viewModel.cancelAllOperations();
    
    await Future.delayed(const Duration(milliseconds: 150));
    
    expect(apiService.operationStatuses['op1'], equals(OperationStatus.cancelled));
    expect(apiService.operationStatuses['op2'], equals(OperationStatus.cancelled));
    expect(apiService.operationStatuses['op3'], equals(OperationStatus.cancelled));
    
    viewModel.dispose();
  });
    
    test('operations handle failure and cancellation properly', () async {
      apiService.shouldThrowOnOperation = true;
      final operationFuture = viewModel.startOperation('op1');
      viewModel.cancelOperation('op1');
      await operationFuture;
      
      expect(apiService.operationStatuses['op1'], equals(OperationStatus.cancelled));
      expect(viewModel.state.error, isNull);
    });
    
    test('state update rejections are counted after disposal', () async {
    expect(viewModel.stateUpdateRejections, equals(0));
    
    viewModel.dispose();
  
    await viewModel.startOperation('op1');
    await viewModel.startOperation('op2');
    
    expect(viewModel.stateUpdateRejections, equals(2));
  });
  });
}
