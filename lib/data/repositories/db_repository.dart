import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/recipe_db.dart';
import '../models/current_recipe_data.dart';
import '../models/models.dart';
import '../repositories/repository.dart';

class DBRepository extends Notifier<CurrentRecipeData> implements Repository {
  // Stores an instance of the Drift RecipeDatabase.
  late RecipeDatabase recipeDatabase;

  // Stores a private RecipeDao to handle recipes.
  late RecipeDao _recipeDao;

  // Stores a private IngredientDao to handle ingredients.
  late IngredientDao _ingredientDao;

  // Store a stream that watches for changes to the list of ingredients.
  Stream<List<Ingredient>>? ingredientStream;

  // Store a stream that watches for changes to the list of recipes.
  Stream<List<Recipe>>? recipeStream;

  /// Create a new RecipeDatabase instance.
  DBRepository({RecipeDatabase? recipeDatabase})
      : recipeDatabase = recipeDatabase ?? RecipeDatabase();

  @override
  Future init() async {
    // Get instances of the RecipeDao and IngredientDao.
    _recipeDao = recipeDatabase.recipeDao;
    _ingredientDao = recipeDatabase.ingredientDao;
  }

  @override
  CurrentRecipeData build() {
    const currentRecipeData = CurrentRecipeData();
    return currentRecipeData;
  }

  /// Converts a DbRecipeData object to a Recipe object.
  /// This method takes a DbRecipeData object and a list of ingredients and
  /// returns a Recipe object.
  @override
  Future<List<Recipe>> findAllRecipes() {
    // Gets a stream of recipes.
    return _recipeDao.findAllRecipes().then<List<Recipe>>(
      (List<DbRecipeData> dbRecipes) async {
        final recipes = <Recipe>[];

        for (final dbRecipe in dbRecipes) {
          // Get the ingredients for the recipe by giving the recipe's id.
          final ingredients = await findRecipeIngredients(dbRecipe.id);
          // Converts the Drift recipe to a model recipe, then adds the recipe to the list.
          final recipe = dbRecipeToModelRecipe(dbRecipe, ingredients);
          recipes.add(recipe);
        }
        return recipes;
      },
    );
  }

  /// Listens for any changes of recipes.
  @override
  Stream<List<Recipe>> watchAllRecipes() {
    // Null-aware assignment operator. It is even more compact way to assign
    // a value to a variable if that variable is currently null.
    recipeStream ??= _recipeDao.watchAllRecipes();
    return recipeStream!;
  }

  /// Listens for any changes of ingredients displayed on the Groceries screen.
  @override
  Stream<List<Ingredient>> watchAllIngredients() {
    if (ingredientStream == null) {
      // Gets a stream of ingredients.
      final stream = _ingredientDao.watchAllIngredients();
      // Maps each ingredient in the stream to a stream of model ingredients.
      ingredientStream = stream.map(
        (dbIngredients) {
          final ingredients = <Ingredient>[];
          for (final dbIngredient in dbIngredients) {
            ingredients.add(dbIngredientToIngredient(dbIngredient));
          }
          return ingredients;
        },
      );
    }
    return ingredientStream!;
  }

  @override
  Future<Recipe> findRecipeById(int id) async {
    // Find all of the ingredients for the given recipe.
    final ingredients = await findRecipeIngredients(id);
    return _recipeDao.findRecipeById(id).then((listOfRecipes) =>
        dbRecipeToModelRecipe(listOfRecipes.first, ingredients));
  }

  /// Converts a DbIngredientData object to an Ingredient object.
  @override
  Future<List<Ingredient>> findAllIngredients() {
    return _ingredientDao.findAllIngredients().then<List<Ingredient>>(
      (List<DbIngredientData> dbIngredients) {
        final ingredients = <Ingredient>[];
        for (final dbIngredient in dbIngredients) {
          // Converts the Drift ingredient to a model ingredient, then adds the ingredient to the list.
          final ingredient = dbIngredientToIngredient(dbIngredient);
          ingredients.add(ingredient);
        }
        return ingredients;
      },
    );
  }

  /// Find all ingredients for a given recipe.
  @override
  Future<List<Ingredient>> findRecipeIngredients(int recipeId) {
    return _ingredientDao.findRecipeIngredients(recipeId).then(
      (listOfIngredients) {
        final ingredients = <Ingredient>[];
        for (final ingredient in listOfIngredients) {
          ingredients.add(dbIngredientToIngredient(ingredient));
        }
        return ingredients;
      },
    );
  }

  /// To insert a recipe, first insert the recipe itself and
  /// then insert all its ingredients.
  @override
  Future<int> insertRecipe(Recipe recipe) {
    // Check if the recipe is already in the list of current recipes.
    if (state.currentRecipes.contains(recipe)) {
      return Future.value(0);
    }
    return Future(
      () async {
        // Update the state with the new recipe.
        state =
            state.copyWith(currentRecipes: [...state.currentRecipes, recipe]);
        // Use the _recipeDao to insert the recipe into the database.
        final id = await _recipeDao.insertRecipe(
          recipeToInsertableDbRecipe(recipe),
        );
        final ingredients = <Ingredient>[];
        for (final ingredient in recipe.ingredients) {
          // Add a copy of the ingredient with the recipe's id.
          ingredients.add(ingredient.copyWith(recipeId: id));
        }
        // Use the _ingredientDao to insert the ingredients into the database.
        insertIngredients(ingredients);
        return id;
      },
    );
  }

  @override
  Future<List<int>> insertIngredients(List<Ingredient> ingredients) {
    return Future(
      () {
        if (ingredients.isEmpty) {
          return <int>[];
        }
        final resultIds = <int>[];
        for (final ingredient in ingredients) {
          // Convert the model ingredient to a Drift ingredient.
          final dbIngredient = ingredientToInsertableDbIngredient(ingredient);
          // Insert the ingredient into the database and add the id to the list.
          _ingredientDao
              .insertIngredient(dbIngredient)
              .then((int id) => resultIds.add(id));
        }
        // Update the state with the new ingredients.
        state = state.copyWith(
            currentIngredients: [...state.currentIngredients, ...ingredients]);

        return resultIds;
      },
    );
  }

  @override
  Future<void> deleteRecipe(Recipe recipe) {
    if (recipe.id != null) {
      // Delete the recipe from our state list.
      final updatedList = [...state.currentRecipes];
      updatedList.remove(recipe);

      state = state.copyWith(currentRecipes: updatedList);
      // Use the RecipeDao to delete the recipe.
      _recipeDao.deleteRecipe(recipe.id!);
      deleteRecipeIngredients(recipe.id!);
    }
    return Future.value();
  }

  @override
  Future<void> deleteIngredient(Ingredient ingredient) {
    if (ingredient.id != null) {
      // Use the IngredientDao to delete the ingredient.
      return _ingredientDao.deleteIngredient(ingredient.id!);
    } else {
      return Future.value();
    }
  }

  @override
  Future<void> deleteIngredients(List<Ingredient> ingredients) {
    for (final ingredient in ingredients) {
      if (ingredient.id != null) {
        _ingredientDao.deleteIngredient(ingredient.id!);
      }
    }
    return Future.value();
  }

  @override
  Future<void> deleteRecipeIngredients(int recipeId) async {
    // Find all ingredients for the given recipe ID.
    final ingredients = await findRecipeIngredients(recipeId);
    // Delete the list of ingredients.
    return deleteIngredients(ingredients);
  }

  @override
  void close() {
    recipeDatabase.close();
  }
}
