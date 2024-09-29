import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

import '../utils/logger.dart';
import 'database/recipe_db.dart';

/// Sets up a SQLite database with encryption using Drift and SQLCipher.
RecipeDatabase openRecipeDatabase(String dbKey) {
  _loadSecureStorageLibrary();

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
    open.overrideFor(
        OperatingSystem.android, () => DynamicLibrary.open('libsqlcipher.so'));
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
