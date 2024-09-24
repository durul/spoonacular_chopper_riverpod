import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';
import 'database/recipe_db.dart';

RecipeDatabase openRecipeDatabase(String dbKey) {
  return RecipeDatabase(LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'recipes.sqlite'));
    return NativeDatabase(
      file,
      logStatements: true,
      setup: (database) {
        final result = database.select('pragma cipher_version');
        logInfo('cipher_version isEmpty ${result.isEmpty}');

        if (result.isEmpty) {
          throw UnsupportedError(
            'This database needs to run with SQLCipher, but that library is '
                'not available!',
          );
        }

        // print versions
        logInfo(
            "cipher_version isEmpty ${database.select('PRAGMA cipher_version;').isEmpty}");
        logInfo(
            "sqlite_version isEmpty ${database.select('SELECT sqlite_version()').isEmpty}");
        // set database key
        try {
          database.execute("PRAGMA key = '$dbKey';");

          // Test that the key is correct by selecting from a table
          database.execute('select count(*) from sqlite_master');
        } on SqliteException catch (e) {
          if (e.resultCode == 26) {
            logInfo('database, the password is probably wrong');
          }
        }
      },
    );
  }));
}