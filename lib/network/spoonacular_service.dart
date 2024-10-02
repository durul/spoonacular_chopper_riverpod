import 'dart:async';

import 'package:chopper/chopper.dart';

import '../config.dart';
import '../data/models/recipe.dart';
import 'model_response.dart';
import 'query_result.dart';
import 'service_interface.dart';
import 'spoonacular_converter.dart';

part 'spoonacular_service.chopper.dart';

/// A Chopper service for the Spoonacular API.
/// It is a generic interface to make network calls.
@ChopperApi()
abstract class SpoonacularService extends ChopperService
    implements ServiceInterface {
  @override
  @Get(path: 'recipes/{id}/information?includeNutrition=false')

  /// Query a single recipe by its ID.
  /// This method returns a [RecipeDetailsResponse] object.
  /// The [id] parameter is the ID of the recipe to query.
  /// Recipe_Details page will call it.
  Future<RecipeDetailsResponse> queryRecipe(
    @Path('id') String id,
  );

  @override
  @Get(path: 'recipes/complexSearch')

  /// Query recipes by a search query.
  /// This method returns a [RecipeResponse] object.
  Future<RecipeResponse> queryRecipes(
    @Query('query') String query,
    @Query('offset') int offset,
    @Query('number') int number,
  );

  static SpoonacularService create(String baseUrl) {
    final client = ChopperClient(
      baseUrl: Uri.parse(baseUrl),
      interceptors: [
        ApiKeyInterceptor(),
        HttpLoggingInterceptor(),
      ],
      converter: SpoonacularConverter(),
      errorConverter: const JsonConverter(),
      services: [
        _$SpoonacularService(),
      ],
    );
    return _$SpoonacularService(client);
  }
}

class ApiKeyInterceptor implements Interceptor {
  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
      Chain<BodyType> chain) async {
    final request = chain.request;
    final params = Map<String, dynamic>.from(request.parameters);
    params['apiKey'] = apiKey;
    final updatedRequest = request.copyWith(parameters: params);
    return chain.proceed(updatedRequest);
  }
}
