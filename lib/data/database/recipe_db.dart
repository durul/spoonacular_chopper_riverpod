import 'package:drift/drift.dart';

import '../models/ingredient.dart';
import '../models/recipe.dart';
import 'connection.dart' as impl;

/// The part statement is a way to combine one file into another to form
/// a whole file.
part 'recipe_db.g.dart';

///  This file defines the database for recipes and ingredients.
///  It also defines the Data Access Objects (DAOs) for the database.
///  The database will be used to store and retrieve recipes and ingredients.

/// DbRecipe table definition here
class DbRecipe extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get label => text()();

  TextColumn get image => text()();

  TextColumn get description => text()();

  BoolColumn get bookmarked => boolean()();
}

/// DbIngredient table definition here
class DbIngredient extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get recipeId => integer()();

  TextColumn get name => text()();

  RealColumn get amount => real()();
}

/// Drift uses annotations. @DriftDatabase() and RecipeDatabase() specifies
/// the tables and Data Access Objects (DAO) to use.

@DriftDatabase(
  tables: [DbRecipe, DbIngredient],
  daos: [RecipeDao, IngredientDao],
)
// RecipeDatabase definition here
class RecipeDatabase extends _$RecipeDatabase {
  // connection.dart will import either
  // the native or web files so you get the proper database initialization.
  RecipeDatabase() : super(impl.connect());

  @override
  int get schemaVersion => 1;
}

/// RecipeDao Data Access Object (DAO) definition here
@DriftAccessor(tables: [DbRecipe])
class RecipeDao extends DatabaseAccessor<RecipeDatabase> with _$RecipeDaoMixin {
  // Create a field to hold an instance of your database.
  final RecipeDatabase db;

  RecipeDao(this.db) : super(db);

  // Find all recipes
  Future<List<DbRecipeData>> findAllRecipes() => select(dbRecipe).get();

  /// Watch all recipes for changes
  // This method returns a stream of all recipes in the database.
  // This method implemented after Conversion Methods implementation.

  // A Stream is used because it allows real-time updates when the data changes.
  Stream<List<Recipe>> watchAllRecipes() {
    return select(dbRecipe) // Start query with the dbRecipe table
        .watch() // Watch the database for changes and emit new results
        .map(
      (rows) {
        // Convert the rows to a list of recipes
        final recipes = <Recipe>[];
        for (final row in rows) {
          final recipe = dbRecipeToModelRecipe(row, <Ingredient>[]);
          // Checking for duplicates
          if (!recipes.contains(recipe)) {
            recipes.add(recipe);
          }
        }
        return recipes;
      },
    );
  }

  // Find a recipe by id
  Future<List<DbRecipeData>> findRecipeById(int id) =>
      (select(dbRecipe)..where((tbl) => tbl.id.equals(id))).get();

  // Insert a recipe
  Future<int> insertRecipe(Insertable<DbRecipeData> recipe) =>
      into(dbRecipe).insert(recipe);

  // Delete a recipe
  Future deleteRecipe(int id) =>
      Future.value((delete(dbRecipe)..where((tbl) => tbl.id.equals(id))).go());
}

/// IngredientDao Data Access Object (DAO) definition here
@DriftAccessor(tables: [DbIngredient])
class IngredientDao extends DatabaseAccessor<RecipeDatabase>
    with _$IngredientDaoMixin {
  final RecipeDatabase db;

  IngredientDao(this.db) : super(db);

  // Find all ingredients
  Future<List<DbIngredientData>> findAllIngredients() =>
      select(dbIngredient).get();

  // Watch all ingredients for changes
  Stream<List<DbIngredientData>> watchAllIngredients() =>
      select(dbIngredient).watch();

  // Find ingredients for a recipe
  Future<List<DbIngredientData>> findRecipeIngredients(int id) =>
      (select(dbIngredient)..where((tbl) => tbl.recipeId.equals(id))).get();

  // Find an ingredient by id
  Future<int> insertIngredient(Insertable<DbIngredientData> ingredient) =>
      into(dbIngredient).insert(ingredient);

  // Delete an ingredient by id
  Future deleteIngredient(int id) => Future.value(
      (delete(dbIngredient)..where((tbl) => tbl.id.equals(id))).go());
}

/// Conversion Methods
// This converts between my database representation of a recipe and
// my application's model representation.

/// dbRecipeToModelRecipe
Recipe dbRecipeToModelRecipe(
    DbRecipeData dbRecipe, List<Ingredient> ingredients) {
  return Recipe(
    id: dbRecipe.id,
    label: dbRecipe.label,
    image: dbRecipe.image,
    description: dbRecipe.description,
    bookmarked: dbRecipe.bookmarked,
    ingredients: ingredients,
  );
}

/// recipeToInsertableDbRecipe
Insertable<DbRecipeData> recipeToInsertableDbRecipe(Recipe recipe) {
  return DbRecipeCompanion.insert(
    id: Value.absentIfNull(recipe.id),
    label: recipe.label ?? '',
    image: recipe.image ?? '',
    description: recipe.description ?? '',
    bookmarked: recipe.bookmarked,
  );
}

/// These methods convert a Drift ingredient into an instance of Ingredient and vice versa.
/// This is necessary because the Drift library uses its own data types to represent
/// database records, and I need to convert them to our own data types to use them in our app.

/// dbIngredientToIngredient
Ingredient dbIngredientToIngredient(DbIngredientData ingredient) {
  return Ingredient(
    id: ingredient.id,
    recipeId: ingredient.recipeId,
    name: ingredient.name,
    amount: ingredient.amount,
  );
}

/// ingredientToInsertableDbIngredient
DbIngredientCompanion ingredientToInsertableDbIngredient(
    Ingredient ingredient) {
  return DbIngredientCompanion.insert(
    recipeId: ingredient.recipeId ?? 0,
    name: ingredient.name ?? '',
    amount: ingredient.amount ?? 0,
  );
}
