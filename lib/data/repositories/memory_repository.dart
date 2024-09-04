import 'dart:core';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/current_recipe_data.dart';
import '../models/models.dart';
import 'repository.dart';

// Notifier: Can manage multiple states or properties within a single class and
// used with NotifierProvider.
class MemoryRepository extends Notifier<CurrentRecipeData>
    implements Repository {
  // Uses the state property for read-only access,
  // but requires build() method for initialization and custom methods for updates
  @override
  CurrentRecipeData build() {
    const currentRecipieData = CurrentRecipeData();
    return currentRecipieData;
  }

  @override
  List<Recipe> findAllRecipes() {
    return state.currentRecipes;
  }

  @override
  Recipe findRecipeById(int id) {
    return state.currentRecipes.firstWhere((recipe) => recipe.id == id);
  }

  @override
  List<Ingredient> findAllIngredients() {
    return state.currentIngredients;
  }

  @override
  List<Ingredient> findRecipeIngredients(int recipeId) {
    final recipe =
        state.currentRecipes.firstWhere((recipe) => recipe.id == recipeId);

    final recipeIngredients = state.currentIngredients
        .where((ingredient) => ingredient.recipeId == recipe.id)
        .toList();
    return recipeIngredients;
  }

  @override
  int insertRecipe(Recipe recipe) {
    // Check the recipe is already on the list. If it is, you return 0.
    if (state.currentRecipes.contains(recipe)) {
      return 0;
    }

    // If not, I assign the current state with a new instance of state
    // of CurrentRecipeData by copying the existing one (copyWith()
    // comes from Freezed)
    state = state.copyWith(currentRecipes: [...state.currentRecipes, recipe]);
    insertIngredients(recipe.ingredients);
    return 0;
  }

  /// Inserts a list of ingredients into the current state.
  @override
  List<int> insertIngredients(List<Ingredient> ingredients) {
    if (ingredients.isNotEmpty) {
      // This creates a new list using the spread operator: ...
      state = state.copyWith(currentIngredients: [
        ...state.currentIngredients,
        ...ingredients
      ]); // adds two lists together
    }
    return <int>[];
  }

  /// Deletes a recipe from the current state.
  /// Also deletes the ingredients associated with the recipe.
  @override
  void deleteRecipe(Recipe recipe) {
    /// This creates a new list using the spread operator: ...
    final updatedList = [...state.currentRecipes];
    updatedList.remove(recipe);
    state = state.copyWith(currentRecipes: updatedList);
    deleteRecipeIngredients(recipe.id);
  }

  @override
  void deleteIngredient(Ingredient ingredient) {
    // This creates a new list using the spread operator: ...
    final updatedList = [...state.currentIngredients];
    updatedList.remove(ingredient);
    state = state.copyWith(currentIngredients: updatedList);
  }

  @override
  void deleteIngredients(List<Ingredient> ingredients) {
    // This creates a new list using the spread operator: ...
    final updatedList = [...state.currentIngredients];
    updatedList.removeWhere((ingredient) => ingredients.contains(ingredient));
    state = state.copyWith(currentIngredients: updatedList);
  }

  @override
  void deleteRecipeIngredients(int recipeId) {
    final updatedList = [...state.currentIngredients];
    updatedList.removeWhere((ingredient) => ingredient.recipeId == recipeId);
    state = state.copyWith(currentIngredients: updatedList);
  }

  @override
  Future init() {
    return Future.value(null);
  }

  @override
  void close() {}
}
