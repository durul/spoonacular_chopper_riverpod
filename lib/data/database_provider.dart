import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:sqlite3/open.dart';

import '../../utils/logger.dart';
import 'database/recipe_db.dart';
import 'secure_storage.dart';

class DatabaseProvider {
  DatabaseProvider._(this._secureStorage);

  static Future<DatabaseProvider> initialize(
      SecureStorage secureStorage) async {
    final provider = DatabaseProvider._(secureStorage);
    await provider._initDatabase();
    return provider;
  }

  Future<void> _initDatabase() async {
    final dbKey = await _getOrCreateDbKey();
    _recipeDatabase = RecipeDatabase(openConnection(dbKey));
  }

  late RecipeDao _recipeDao;
  late IngredientDao _ingredientDao;
  late final RecipeDatabase _recipeDatabase;

  final SecureStorage _secureStorage;

  static const kDbKey = 'db_key';

  RecipeDao get recipeDao => _recipeDao;

  IngredientDao get ingredientDao => _ingredientDao;

  RecipeDatabase get recipeDatabase => _recipeDatabase;

  // Future<void> create() async {
  //   await _loadSecureStorageLibrary();
  //
  //   _recipeDatabase = RecipeDatabase(openConnection(await _getOrCreateDbKey()));
  //   _recipeDao = RecipeDao(_recipeDatabase);
  //   _ingredientDao = IngredientDao(_recipeDatabase);
  //   // Set this option to suppress the warning
  //   driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  // }

  Future<void> _loadSecureStorageLibrary() async {
    if (Platform.isIOS) {
      return _openOnIOS();
    } else if (Platform.isAndroid) {
      return _openOnAndroid();
    }
  }

  Future<void> _openOnIOS() async {
    try {
      open.overrideFor(OperatingSystem.iOS, DynamicLibrary.process);
    } catch (error) {
      logErrorText(error.toString());
    }
  }

  Future<void> _openOnAndroid() async {
    try {
      open.overrideFor(OperatingSystem.android,
          () => DynamicLibrary.open('libsqlcipher.so'));
    } catch (error) {
      logErrorText(error.toString());
    }
  }

  Future<String> _getOrCreateDbKey() async {
    const kDbKey = 'db_key';
    var dbKey = await _secureStorage.read(kDbKey);
    if (dbKey == null) {
      dbKey = generateStrongEncryptionKey();
      await _secureStorage.write(kDbKey, dbKey);
    }
    return dbKey;
  }
}
