import 'dart:convert';

import 'package:chopper/chopper.dart';

import 'model_response.dart';
import 'query_result.dart';
import 'spoonacular_model.dart';

// To use the returned API data, I need a converter to transform
// requests and responses. To attach a converter to a Chopper client,
// I need an interceptor.
class SpoonacularConverter implements Converter {
  /// Takes a request and adds the necessary headers
  @override
  Request convertRequest(Request request) {
    final req = applyHeader(
      request,
      contentTypeKey,
      jsonHeaders,
      override: false,
    );

    return encodeJson(req);
  }

  /// To make it easy to expand my app in the future,
  /// I’ll separate encoding and decoding logic.
  /// This method takes a request and encodes the body to JSON.
  Request encodeJson(Request request) {
    final contentType = request.headers[contentTypeKey];
    if (contentType != null && contentType.contains(jsonHeaders)) {
      return request.copyWith(body: json.encode(request.body));
    }
    return request;
  }

  /// Parse the JSON data and transform it into the APIRecipeQuery model class.
  Response<BodyType> decodeJson<BodyType, InnerType>(Response response) {
    final contentType = response.headers[contentTypeKey];
    var body = response.body;
    if (contentType != null && contentType.contains(jsonHeaders)) {
      body = utf8.decode(response.bodyBytes);
    }
    try {
      final mapData = json.decode(body) as Map<String, dynamic>;

      // This is the list of recipes
      if (mapData.keys.contains('totalResults')) {
        // fromJson() to convert the map into the model class.
        final spoonacularResults = SpoonacularResults.fromJson(mapData);
        final recipes = spoonacularResultsToRecipe(spoonacularResults);
        final apiQueryResults = QueryResult(
            offset: spoonacularResults.offset,
            number: spoonacularResults.number,
            totalResults: spoonacularResults.totalResults,
            recipes: recipes);
        return response.copyWith<BodyType>(
          body: Success(apiQueryResults) as BodyType,
        );
      } else {
        // This is the recipe details
        final spoonacularRecipe = SpoonacularRecipe.fromJson(mapData);
        final recipe = spoonacularRecipeToRecipe(spoonacularRecipe);
        return response.copyWith<BodyType>(
          body: Success(recipe) as BodyType,
        );
      }
    } catch (e) {
      chopperLogger.warning(e);
      final error = Error<InnerType>(Exception(e.toString()));
      return Response(response.base, null, error: error);
    }
  }

  @override
  Response<BodyType> convertResponse<BodyType, InnerType>(Response response) {
    return decodeJson<BodyType, InnerType>(response);
  }
}
