import 'data/database/recipe_db.dart';
import 'data/database_provider.dart';
import 'data/secure_storage.dart';

class Globals {
  factory Globals() => _instance;

  Globals._internal() {
    _instance = this;
    _instance.secureStorage = SecureStorage();
    _instance.databaseProvider = DatabaseProvider(_instance.secureStorage);
  }

  static Globals _instance = Globals._internal();

  late final SecureStorage secureStorage;
  late final DatabaseProvider databaseProvider;

  static Globals get instance => _instance;

  Future<void> initializeGlobals() async {
    await databaseProvider.create();
  }

  // Update this line
  RecipeDatabase get recipeDatabase => databaseProvider.database;
}