import 'package:drift/drift.dart';

import 'database/recipe_db.dart';

Never _unsupported() {
  throw UnsupportedError(
      'No suitable database implementation was found on this platform.');
}

// Depending on the platform the app is compiled to, the following stubs will
// be replaced with the methods in native_db.dart or web_db.dart
RecipeDatabase openRecipeDatabase(String dbKey) {
  throw UnsupportedError('No database implementation found.');
}

Future<void> validateDatabaseSchema(GeneratedDatabase database) async {
  _unsupported();
}
