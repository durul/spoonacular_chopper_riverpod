import 'dart:async';
import 'dart:core';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/current_recipe_data.dart';
import '../models/models.dart';
import 'repository.dart';

// Notifier: Can manage multiple states or properties within a single class and
// used with NotifierProvider.
class MemoryRepository extends Notifier<CurrentRecipeData>
    implements Repository {
  // These will be captured the first time a stream is requested
  late Stream<List<Recipe>> _recipeStream;
  late Stream<List<Ingredient>> _ingredientStream;

  final StreamController _recipeStreamController =
      StreamController<List<Recipe>>();
  final StreamController _ingredientStreamController =
      StreamController<List<Ingredient>>();

  /// Constructor for the MemoryRepository class.
  MemoryRepository() {
    // Create a broadcast stream for recipes and ingredients
    _recipeStream = _recipeStreamController.stream.asBroadcastStream(
      // Listen for new subscribers
      onListen: (subscription) {
        // This is to send the current recipes to new subscriber
        _recipeStreamController.sink.add(state.currentRecipes);
      },
    ) as Stream<List<Recipe>>;
    _ingredientStream = _ingredientStreamController.stream.asBroadcastStream(
      onListen: (subscription) {
        // This is to send the current ingredients to new subscriber
        _ingredientStreamController.sink.add(state.currentIngredients);
      },
    ) as Stream<List<Ingredient>>;
  }

  // Uses the state property for read-only access,
  // but requires build() method for initialization and custom methods for updates
  @override
  CurrentRecipeData build() {
    const currentRecipieData = CurrentRecipeData();
    return currentRecipieData;
  }

  /// Return a stream of all recipes.
  @override
  Stream<List<Recipe>> watchAllRecipes() {
    return _recipeStream;
  }

  /// Return a stream of all ingredients.
  @override
  Stream<List<Ingredient>> watchAllIngredients() {
    return _ingredientStream;
  }

  @override
  Future<List<Recipe>> findAllRecipes() {
    return Future.value(state.currentRecipes);
  }

  @override
  Future<Recipe> findRecipeById(int id) {
    return Future.value(
        state.currentRecipes.firstWhere((recipe) => recipe.id == id));
  }

  @override
  Future<List<Ingredient>> findAllIngredients() {
    return Future.value(state.currentIngredients);
  }

  @override
  Future<List<Ingredient>> findRecipeIngredients(int recipeId) {
    final recipe =
        state.currentRecipes.firstWhere((recipe) => recipe.id == recipeId);

    final recipeIngredients = state.currentIngredients
        .where((ingredient) => ingredient.recipeId == recipe.id)
        .toList();
    return Future.value(recipeIngredients);
  }

  @override
  Future<int> insertRecipe(Recipe recipe) {
    // Check the recipe is already on the list. If it is, you return 0.
    if (state.currentRecipes.contains(recipe)) {
      return Future.value(0);
    }

    // If not, I assign the current state with a new instance of state
    // of CurrentRecipeData by copying the existing one (copyWith()
    // comes from Freezed)
    state = state.copyWith(currentRecipes: [...state.currentRecipes, recipe]);

    /// Sending Recipes Over the Stream
    _recipeStreamController.sink.add(state.currentRecipes);

    // Update all of the ingredients with the recipe ID and then insert the ingredients.
    final ingredients = <Ingredient>[];
    for (final ingredient in recipe.ingredients) {
      ingredients.add(ingredient.copyWith(recipeId: recipe.id));
    }
    insertIngredients(ingredients);

    return Future.value(0);
  }

  /// Inserts a list of ingredients into the current state.
  @override
  Future<List<int>> insertIngredients(List<Ingredient> ingredients) {
    if (ingredients.isNotEmpty) {
      // This creates a new list using the spread operator: ...
      state = state.copyWith(currentIngredients: [
        ...state.currentIngredients,
        ...ingredients
      ]); // adds two lists together
      _ingredientStreamController.sink.add(state.currentIngredients);
    }
    return Future.value(<int>[]);
  }

  /// Deletes a recipe from the current state.
  /// Also deletes the ingredients associated with the recipe.
  @override
  Future<void> deleteRecipe(Recipe recipe) {
    /// This creates a new list using the spread operator: ...
    final updatedList = [...state.currentRecipes];
    updatedList.remove(recipe);
    state = state.copyWith(currentRecipes: updatedList);
    _recipeStreamController.sink.add(state.currentRecipes);

    deleteRecipeIngredients(recipe.id);
    return Future.value();
  }

  @override
  Future<void> deleteIngredient(Ingredient ingredient) {
    // This creates a new list using the spread operator: ...
    final updatedList = [...state.currentIngredients];
    updatedList.remove(ingredient);
    state = state.copyWith(currentIngredients: updatedList);

    _ingredientStreamController.sink.add(state.currentIngredients);
    return Future.value();
  }

  @override
  Future<void> deleteIngredients(List<Ingredient> ingredients) {
    // This creates a new list using the spread operator: ...
    final updatedList = [...state.currentIngredients];
    updatedList.removeWhere((ingredient) => ingredients.contains(ingredient));
    state = state.copyWith(currentIngredients: updatedList);

    _ingredientStreamController.sink.add(state.currentIngredients);
    return Future.value();
  }

  @override
  Future<void> deleteRecipeIngredients(int recipeId) {
    final updatedList = [...state.currentIngredients];
    updatedList.removeWhere((ingredient) => ingredient.recipeId == recipeId);
    state = state.copyWith(currentIngredients: updatedList);

    _ingredientStreamController.sink.add(state.currentIngredients);
    return Future.value();
  }

  @override
  Future init() {
    return Future.value();
  }

  @override
  void close() {
    _recipeStreamController.close();
    _ingredientStreamController.close();
  }
}
