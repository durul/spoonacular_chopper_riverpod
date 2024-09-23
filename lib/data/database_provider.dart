import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:sqlite3/open.dart';

import '../../utils/logger.dart';
import 'database/recipe_db.dart';
import 'secure_storage.dart';

class DatabaseProvider {
  DatabaseProvider([SecureStorage? secureStorage]) {
    if (secureStorage != null) {
      _secureStorage = secureStorage;
      _hasSecureStorage = true;
    }
  }

  late final SecureStorage _secureStorage;
  bool _hasSecureStorage = false;
  static RecipeDatabase? _database;

  static const kDbKey = 'db_key';

  IngredientDao get ingredientDao => database.ingredientDao;
  RecipeDao get recipeDao => database.recipeDao;

  RecipeDatabase get database {
    if (_database == null) {
      throw StateError('Database has not been initialized. Call create() first.');
    }
    return _database!;
  }

  Future<void> create() async {
    if (_database != null) return;
    if (!_hasSecureStorage) {
      throw StateError('SecureStorage not initialized');
    }
    await _loadSecureStorageLibrary();
    final databaseKey = await _getKey();
    _database = RecipeDatabase(openConnection(databaseKey));

    // Set this option to suppress the warning
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

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

  Future<String> _getKey() async {
    if (!_hasSecureStorage) {
      throw StateError('SecureStorage not initialized');
    }
    var data = await _secureStorage.read(kDbKey);
    if (data == null) {
      final newKey = generateStrongEncryptionKey();
      await _secureStorage.write(kDbKey, newKey);
      return newKey;
    }
    return data;
  }
}