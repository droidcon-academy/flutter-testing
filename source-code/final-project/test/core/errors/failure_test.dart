import 'package:flutter_test/flutter_test.dart';
import 'package:recipevault/core/errors/failure.dart';

void main() {
  group('Failure base class', () {
    test('props should contain message and code', () {
      const failure = ServerFailure(
        message: 'Server error',
        statusCode: 500,
      );
      expect(failure.props, contains('Server error'));
      expect(failure.props, contains(500));
    });
  });

  group('ServerFailure', () {
    test('should set message and statusCode from constructor', () {
      const failure = ServerFailure(
        message: 'Internal server error',
        statusCode: 500,
      );
      expect(failure.message, 'Internal server error');
      expect(failure.statusCode, 500);
      expect(failure.code, 500);
    });

    test('should override props to include statusCode', () {
      const failure = ServerFailure(
        message: 'Not found',
        statusCode: 404,
      );
      expect(failure.props, contains('Not found'));
      expect(failure.props, contains(404));
    });

    test('equality should work correctly', () {
      const failure1 = ServerFailure(
        message: 'Bad request',
        statusCode: 400,
      );
      const failure2 = ServerFailure(
        message: 'Bad request',
        statusCode: 400,
      );
      const differentFailure = ServerFailure(
        message: 'Unauthorized',
        statusCode: 401,
      );
      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(differentFailure)));
    });
  });

  group('ConnectionFailure', () {
    test('should set default message and code', () {
      const failure = ConnectionFailure();
      expect(failure.message, 'No internet connection');
      expect(failure.code, -1);
    });

    test('should allow custom message', () {
      const failure = ConnectionFailure(
        message: 'Network timeout after 30s',
      );
      expect(failure.message, 'Network timeout after 30s');
      expect(failure.code, -1);
    });

    test('equality should work correctly', () {
      const failure1 = ConnectionFailure();
      const failure2 = ConnectionFailure();
      const customFailure = ConnectionFailure(
        message: 'Custom message',
      );
      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(customFailure)));
    });
  });

  group('CacheFailure', () {
    test('should set message, operation and code', () {
      const failure = CacheFailure(
        message: 'Failed to read data',
        operation: 'READ',
      );
      expect(failure.message, 'Failed to read data');
      expect(failure.operation, 'READ');
      expect(failure.code, -2);
    });

    test('should override props to include operation', () {
      const failure = CacheFailure(
        message: 'Failed to write data',
        operation: 'WRITE',
      );
      expect(failure.props, contains('Failed to write data'));
      expect(failure.props, contains(-2));
      expect(failure.props, contains('WRITE'));
    });

    test('equality should work correctly', () {
      const failure1 = CacheFailure(
        message: 'Failed to delete data',
        operation: 'DELETE',
      );
      const failure2 = CacheFailure(
        message: 'Failed to delete data',
        operation: 'DELETE',
      );
      const differentFailure = CacheFailure(
        message: 'Failed to delete data',
        operation: 'CLEAR',
      );
      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(differentFailure)));
    });
  });

  group('InputValidationFailure', () {
    test('should set message and code', () {
      const failure = InputValidationFailure(
        message: 'Email is invalid',
      );
      expect(failure.message, 'Email is invalid');
      expect(failure.code, -3);
    });

    test('equality should work correctly', () {
      const failure1 = InputValidationFailure(
        message: 'Password too short',
      );
      const failure2 = InputValidationFailure(
        message: 'Password too short',
      );
      const differentFailure = InputValidationFailure(
        message: 'Username is required',
      );
      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(differentFailure)));
    });
  });

  group('Different failure types', () {
    test('should not be equal even with same message and code', () {
      const serverFailure = ServerFailure(
        message: 'Error occurred',
        statusCode: 500,
      );
      const validationFailure = InputValidationFailure(
        message: 'Error occurred',
      );
      expect(serverFailure, isNot(equals(validationFailure)));
    });
  });
}
