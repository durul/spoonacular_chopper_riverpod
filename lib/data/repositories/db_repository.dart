import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../global.dart';
import '../database/recipe_db.dart';
import '../models/current_recipe_data.dart';
import '../models/models.dart';
import '../repositories/repository.dart';

class DBRepository extends AsyncNotifier<CurrentRecipeData>
    implements Repository {
  late RecipeDatabase _recipeDatabase;
  late RecipeDao _recipeDao;
  late IngredientDao _ingredientDao;

  Stream<List<Ingredient>>? ingredientStream;
  Stream<List<Recipe>>? recipeStream;

  @override
  Future<CurrentRecipeData> build() async {
    return const CurrentRecipeData();
  }

  Future<void> updateState(
      CurrentRecipeData Function(CurrentRecipeData) update) async {
    state = AsyncValue.data(update(state.value!));
  }

  @override
  Future<List<Recipe>> findAllRecipes() async {
    final dbRecipes = await _recipeDao.findAllRecipes();
    final recipes = <Recipe>[];

    for (final dbRecipe in dbRecipes) {
      final ingredients = await findRecipeIngredients(dbRecipe.id);
      final recipe = dbRecipeToModelRecipe(dbRecipe, ingredients);
      recipes.add(recipe);
    }

    await updateState(
        (currentState) => currentState.copyWith(currentRecipes: recipes));
    return recipes;
  }

  @override
  Stream<List<Recipe>> watchAllRecipes() {
    recipeStream ??= _recipeDao.watchAllRecipes();
    return recipeStream!;
  }

  @override
  Stream<List<Ingredient>> watchAllIngredients() {
    if (ingredientStream == null) {
      final stream = _ingredientDao.watchAllIngredients();
      ingredientStream = stream.map(
        (dbIngredients) {
          return dbIngredients.map(dbIngredientToIngredient).toList();
        },
      );
    }
    return ingredientStream!;
  }

  @override
  Future<Recipe> findRecipeById(int id) async {
    final ingredients = await findRecipeIngredients(id);
    final dbRecipes = await _recipeDao.findRecipeById(id);
    return dbRecipeToModelRecipe(dbRecipes.first, ingredients);
  }

  @override
  Future<List<Ingredient>> findAllIngredients() async {
    final dbIngredients = await _ingredientDao.findAllIngredients();
    return dbIngredients.map(dbIngredientToIngredient).toList();
  }

  @override
  Future<List<Ingredient>> findRecipeIngredients(int recipeId) async {
    final dbIngredients = await _ingredientDao.findRecipeIngredients(recipeId);
    return dbIngredients.map(dbIngredientToIngredient).toList();
  }

  @override
  Future<int> insertRecipe(Recipe recipe) async {
    if (state.value!.currentRecipes.contains(recipe)) {
      return 0;
    }

    final id =
        await _recipeDao.insertRecipe(recipeToInsertableDbRecipe(recipe));
    final ingredients =
        recipe.ingredients.map((i) => i.copyWith(recipeId: id)).toList();
    await insertIngredients(ingredients);

    await updateState((currentState) => currentState.copyWith(currentRecipes: [
          ...currentState.currentRecipes,
          recipe.copyWith(id: id)
        ]));

    return id;
  }

  @override
  Future<List<int>> insertIngredients(List<Ingredient> ingredients) async {
    final resultIds = <int>[];
    for (final ingredient in ingredients) {
      final dbIngredient = ingredientToInsertableDbIngredient(ingredient);
      final id = await _ingredientDao.insertIngredient(dbIngredient);
      resultIds.add(id);
    }

    await updateState((currentState) => currentState.copyWith(
            currentIngredients: [
              ...currentState.currentIngredients,
              ...ingredients
            ]));

    return resultIds;
  }

  @override
  Future<void> deleteRecipe(Recipe recipe) async {
    if (recipe.id != null) {
      await _recipeDao.deleteRecipe(recipe.id!);
      await deleteRecipeIngredients(recipe.id!);

      await updateState((currentState) => currentState.copyWith(
          currentRecipes: currentState.currentRecipes
              .where((r) => r.id != recipe.id)
              .toList()));
    }
  }

  @override
  Future<void> deleteIngredient(Ingredient ingredient) async {
    if (ingredient.id != null) {
      await _ingredientDao.deleteIngredient(ingredient.id!);

      await updateState((currentState) => currentState.copyWith(
          currentIngredients: currentState.currentIngredients
              .where((i) => i.id != ingredient.id)
              .toList()));
    }
  }

  @override
  Future<void> deleteIngredients(List<Ingredient> ingredients) async {
    for (final ingredient in ingredients) {
      if (ingredient.id != null) {
        await _ingredientDao.deleteIngredient(ingredient.id!);
      }
    }

    await updateState((currentState) => currentState.copyWith(
        currentIngredients: currentState.currentIngredients
            .where((i) => !ingredients.contains(i))
            .toList()));
  }

  @override
  Future<void> deleteRecipeIngredients(int recipeId) async {
    final ingredients = await findRecipeIngredients(recipeId);
    await deleteIngredients(ingredients);
  }

  @override
  void close() {
    _recipeDatabase.close();
  }

  @override
  Future<void> init() async {
    await Globals.instance
        .initializeGlobals(); // Ensure database is initialized
    _recipeDatabase = Globals.instance.recipeDatabase;
    _recipeDao = _recipeDatabase.recipeDao;
    _ingredientDao = _recipeDatabase.ingredientDao;
  }
}
