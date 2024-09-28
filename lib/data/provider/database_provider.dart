import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart';
import 'package:sqlbrite/sqlbrite.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../utils/logger.dart';
import '../../utils/uid_gen.dart';
import '../database/recipe_db.dart';
import '../native.dart';
import '../secure_storage.dart';

/// DatabaseProvider is a singleton class that manages he `RecipeDatabase`
/// connections and provides access to DAOs.
class DatabaseProvider {
  DatabaseProvider._(this._secureStorage);

  late RecipeDao _recipeDao;
  late IngredientDao _ingredientDao;
  late final RecipeDatabase _recipeDatabase;

  // SecureStorage for storing the database encryption key.
  // Implements SQLCipher for database encryption on supported platforms.
  final SecureStorage _secureStorage;

  static const kDbKey = 'db_key';

  RecipeDao get recipeDao => _recipeDao;

  IngredientDao get ingredientDao => _ingredientDao;

  RecipeDatabase get recipeDatabase => _recipeDatabase;

  /// Creates an instance and initializes the database.
  static Future<DatabaseProvider> initialize(
      SecureStorage secureStorage) async {
    final provider = DatabaseProvider._(secureStorage);
    await provider._initDatabase();
    return provider;
  }

  /// Checks if the database connection is successful.
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

  /// Checks if the database is encrypted.
  Future<void> testDatabaseEncryption() async {
    final dbFile = File(join(await getDatabasesPath(), 'db.sqlite'));
    if (await dbFile.exists()) {
      final bytes = await dbFile.readAsBytes();
      final header = bytes.sublist(0, 16);
      final isEncrypted =
          !header.any((byte) => byte == 0x53 && byte == 0x51 && byte == 0x4C);
      logInfo('Database is ${isEncrypted ? 'encrypted' : 'not encrypted'}');
    } else {
      logInfo('Database file does not exist');
    }
  }

  Future<void> _initDatabase() async {
    await _loadSecureStorageLibrary();

    // This method either retrieves an existing encryption key from
    // secure storage or generates a new one if it doesn't exist.
    final dbKey = await _getOrCreateDbKey();

    try {
      /// Open the database
      _recipeDatabase = openRecipeDatabase(dbKey);
    } catch (e) {
      logInfo('Error connecting to database: $e');
      if (e.toString().contains('file is encrypted or is not a database')) {
        logInfo('This might be an encryption key mismatch');
      }
    }

    // This line configures Drift to not warn about multiple database
    // instances, which can be useful in certain scenarios.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

    _recipeDao = _recipeDatabase.recipeDao;
    _ingredientDao = _recipeDatabase.ingredientDao;
  }

  /// Loads the appropriate SQLite library based on the platform.
  Future<void> _loadSecureStorageLibrary() async {
    if (Platform.isIOS || Platform.isAndroid) {
      await loadSqlite3Flutter();
    } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqlite3.openInMemory();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Loads the SQLite library for the platform.
  Future<void> loadSqlite3Flutter() async {
    if (Platform.isIOS) {
      return _openOnIOS();
    } else if (Platform.isAndroid) {
      return _openOnAndroid();
    } else if (Platform.isLinux) {
      return _openOnLinux();
    }
  }

  /// Opens the SQLite library on iOS.
  Future<void> _openOnIOS() async {
    try {
      open.overrideFor(OperatingSystem.iOS, () => DynamicLibrary.executable());
    } catch (error) {
      logErrorText(error.toString());
    }
  }

  /// Opens the SQLite library on Android.
  Future<void> _openOnAndroid() async {
    try {
      open.overrideFor(OperatingSystem.android,
          () => DynamicLibrary.open('libsqlcipher.so'));
    } catch (error) {
      logErrorText(error.toString());
    }
  }

  /// Opens the SQLite library on Linux.
  void _openOnLinux() {
    try {
      open.overrideFor(
          OperatingSystem.linux, () => DynamicLibrary.open('libsqlcipher.so'));
      return;
    } catch (_) {
      logErrorText(_.toString());
      try {
        // fallback to sqlite if unavailable
        final scriptDir = File(Platform.script.toFilePath()).parent;
        final libraryNextToScript = File('${scriptDir.path}/sqlite3.so');
        final lib = DynamicLibrary.open(libraryNextToScript.path);

        open.overrideFor(OperatingSystem.linux, () => lib);
      } catch (error) {
        logErrorText(error.toString());
        rethrow;
      }
    }
  }

  /// Generates a new encryption key if one does not exist.
  Future<String> _getOrCreateDbKey() async {
    const kDbKey = 'db_key';
    var dbKey = await _secureStorage.read(kDbKey);
    if (dbKey == null) {
      dbKey = UidGen.generateStrongEncryptionKey();
      await _secureStorage.write(kDbKey, dbKey);
    }
    return dbKey;
  }
}
