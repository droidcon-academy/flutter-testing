import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipevault/core/errors/failure.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://www.themealdb.com/api/json/v1/1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 6), 
    validateStatus: (status) => status != null && status < 500, 
  ));
  
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
    logPrint: (obj) => print('DIO: $obj'),
  ));
  
  return dio;
});

typedef JsonMap = Map<String, dynamic>;
typedef JsonList = List<JsonMap>;

class APIService {
  final Dio _dio;

  APIService(this._dio);

  Future<JsonMap> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParams);
      return response.data as JsonMap;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw const ServerFailure(
        message: 'Unexpected error processing the request',
        statusCode: 500,
      );
    }
  }

  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ConnectionFailure(message: 'Connection timeout. Please check your internet connection and try again.');
      case DioExceptionType.connectionError:
        return const ConnectionFailure(message: 'No internet connection. Please check your network settings and try again.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.statusMessage ?? 'Server error';
        return ServerFailure(
          message: 'Server responded with error: $message',
          statusCode: statusCode ?? 500,
        );
      default:
        if (error.response?.statusCode != null) {
          return ServerFailure(
            message: error.message ?? 'Server error',
            statusCode: error.response!.statusCode!,
          );
        }
        return const ServerFailure(
          message: 'Unknown error occurred. Please try again later.',
          statusCode: 500,
        );
    }
  }
}