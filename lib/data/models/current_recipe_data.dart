import 'package:freezed_annotation/freezed_annotation.dart';

import 'models.dart';

part 'current_recipe_data.freezed.dart';

@freezed
class CurrentRecipeData with _$CurrentRecipeData {
  // This is a data model for the current recipe data.
  // It contains a list of recipes and a list of ingredients.
  const factory CurrentRecipeData({
    @Default(<Recipe>[]) List<Recipe> currentRecipes,
    @Default(<Ingredient>[]) List<Ingredient> currentIngredients,
  }) = _CurrentRecipeData;
}
