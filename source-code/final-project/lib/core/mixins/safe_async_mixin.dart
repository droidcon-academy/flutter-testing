import 'package:flutter/foundation.dart';

mixin SafeAsyncMixin {
  bool _disposed = false;
  bool get disposed => _disposed;
  
  Future<T?> safeAsync<T>(Future<T> Function() action) async {
    if (_disposed) {
      return null;
    }
    
    try {
      final result = await action();
      
      if (_disposed) {
        return null;
      }
      
      return result;
    } catch (e) {
      if (!_disposed) {
        rethrow;
      }
      return null;
    }
  }
  
  bool get canUpdateState => !_disposed;
  
  void safeLog(String message, {LogLevel level = LogLevel.debug}) {
    if (_disposed) return;
    
    switch (level) {
      case LogLevel.debug:
        debugPrint('[SafeAsyncMixin] $message');
        break;
      case LogLevel.info:
        debugPrint('[SafeAsyncMixin] $message');
        break;
      case LogLevel.warning:
        debugPrint('[SafeAsyncMixin] $message');
        break;
      case LogLevel.error:
        debugPrint('[SafeAsyncMixin] $message');
        break;
    }
  }
  
  void markDisposed() {
    _disposed = true;
  }
  
  void checkDisposed() {
    if (_disposed) {
      throw StateError('Operation attempted on disposed object');
    }
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error
}
