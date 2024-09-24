import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

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

  Future<void> testDatabaseConnection() async {
    try {
      await _recipeDatabase.customSelect('SELECT 1').getSingle();
      logInfo('Database connection successful');
    } catch (e) {
      logInfo('Database connection failed');
      if (e is SqliteException && e.extendedResultCode == 26) {
        logInfo('Encryption key might be incorrect');
      }
    }
  }

  Future<void> _initDatabase() async {
    await _loadSecureStorageLibrary();

    final dbKey = await _getOrCreateDbKey();
    _recipeDatabase = await RecipeDatabase.connect(dbKey);

    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    _recipeDao = RecipeDao(_recipeDatabase);
    _ingredientDao = IngredientDao(_recipeDatabase);
  }

  late RecipeDao _recipeDao;
  late IngredientDao _ingredientDao;
  late final RecipeDatabase _recipeDatabase;

  final SecureStorage _secureStorage;

  static const kDbKey = 'db_key';

  RecipeDao get recipeDao => _recipeDao;

  IngredientDao get ingredientDao => _ingredientDao;

  RecipeDatabase get recipeDatabase => _recipeDatabase;

  Future<void> _loadSecureStorageLibrary() async {
    if (Platform.isIOS || Platform.isAndroid) {
      await loadSqlite3Flutter();
    } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqlite3.openInMemory();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  Future<void> loadSqlite3Flutter() async {
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

  String generateStrongEncryptionKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
}
