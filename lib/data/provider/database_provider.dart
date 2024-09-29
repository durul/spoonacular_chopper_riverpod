
import 'package:drift/drift.dart';
import '../../../utils/logger.dart';
import '../../utils/uid_gen.dart';
import '../connection.dart' as connection;
import '../database/recipe_db.dart';
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

  // /// Checks if the database connection is successful.
  // Future<void> testDatabaseConnection() async {
  //   try {
  //     await _recipeDatabase.customSelect('SELECT 1').getSingle();
  //     logInfo('Database connection successful');
  //   } catch (e) {
  //     logInfo('Database connection failed');
  //     if (e is SqliteException && e.extendedResultCode == 26) {
  //       logInfo('Encryption key might be incorrect');
  //     }
  //   }
  // }
  //
  // /// Checks if the database is encrypted.
  // Future<void> testDatabaseEncryption() async {
  //   final dbFile = File(join(await getDatabasesPath(), 'db.sqlite'));
  //   if (await dbFile.exists()) {
  //     final bytes = await dbFile.readAsBytes();
  //     final header = bytes.sublist(0, 16);
  //     final isEncrypted =
  //         !header.any((byte) => byte == 0x53 && byte == 0x51 && byte == 0x4C);
  //     logInfo('Database is ${isEncrypted ? 'encrypted' : 'not encrypted'}');
  //   } else {
  //     logInfo('Database file does not exist');
  //   }
  // }

  Future<void> _initDatabase() async {
    // This method either retrieves an existing encryption key from
    // secure storage or generates a new one if it doesn't exist.
    final dbKey = await _getOrCreateDbKey();

    try {
      /// Open the database
      _recipeDatabase = connection.openRecipeDatabase(dbKey);
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
