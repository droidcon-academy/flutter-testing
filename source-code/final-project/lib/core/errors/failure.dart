import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  final int statusCode;

  const ServerFailure({
    required super.message,
    required this.statusCode,
  }) : super(
          code: statusCode,
        );

  @override
  List<Object?> get props => [...super.props, statusCode];
}

class ConnectionFailure extends Failure {
  const ConnectionFailure({
    super.message = 'No internet connection',
  }) : super(code: -1);
}

class CacheFailure extends Failure {
  final String operation;

  const CacheFailure({
    required super.message,
    required this.operation,
  }) : super(code: -2);

  @override
  List<Object?> get props => [...super.props, operation];
}

class InputValidationFailure extends Failure {
  const InputValidationFailure({
    required super.message,
  }) : super(code: -3);
}