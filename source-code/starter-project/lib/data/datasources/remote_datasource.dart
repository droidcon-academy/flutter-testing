import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failure.dart';
import '../../services/api_service.dart';
import '../models/recipe_model.dart';

final remoteDataSourceProvider = Provider<RemoteDataSource>((ref) {
  final apiService = ref.watch(dioProvider);
  return RemoteDataSource(APIService(apiService));
});

class RemoteDataSource {
  final APIService _apiService;
  
  RemoteDataSource(this._apiService);

  Future<List<RecipeModel>> getRecipesByLetter(String letter) async {
    try {
      final response = await _apiService.get(
        '/search.php',
        queryParams: {'f': letter},
      );

      final meals = response['meals'] as List<dynamic>?;
      if (meals == null) {
        return [];
      }

      return meals
          .cast<Map<String, dynamic>>()
          .map((json) => RecipeModel.fromJson(json))
          .toList();
    } on ServerFailure catch (e) {
      throw e;
    } on ConnectionFailure catch (e) {
      throw e;
    } catch (e) {
      throw const ServerFailure(
        message: 'Failed to parse recipe data',
        statusCode: 500,
      );
    }
  }

  Future<RecipeModel?> getRecipeById(dynamic id) async {
    try {
      final String stringId = id?.toString() ?? 'invalid_id';
      if (stringId == 'invalid_id' || stringId.isEmpty) {
        throw ServerFailure(
          message: 'Invalid recipe ID format provided: $id',
          statusCode: 400,
        );
      }
      
      final response = await _apiService.get(
        '/lookup.php',
        queryParams: {'i': stringId},
      );

      final meals = response['meals'] as List<dynamic>?;
      if (meals == null || meals.isEmpty) {
        return null;
      }

      try {
        final mealJson = meals.first as Map<String, dynamic>;
        return RecipeModel.fromJson(mealJson);
      } catch (parseError) {
        throw ServerFailure(
          message: 'Failed to parse recipe data for ID $stringId: $parseError',
          statusCode: 422, 
        );
      }
    } on ServerFailure catch (e) {
      throw e;
    } on ConnectionFailure catch (e) {
      throw e;
    } catch (e) {
      throw ServerFailure(
        message: 'Failed to process recipe data for ID $id: $e',
        statusCode: 500,
      );
    }
  }
}