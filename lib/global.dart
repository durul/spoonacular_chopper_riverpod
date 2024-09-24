import 'data/database_provider.dart';
import 'data/secure_storage.dart';

///
/// Global environment configuration
///
class Globals {
  Globals._();

  static final instance = Globals._();

  late final SecureStorage secureStorage;
  late final DatabaseProvider databaseProvider;

  Future<void> initialize() async {
    secureStorage = SecureStorage();
    databaseProvider = await DatabaseProvider.initialize(secureStorage);
  }
}
