import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

import 'database/recipe_db.dart';

RecipeDatabase openRecipeDatabase(String dbKey) {
  return RecipeDatabase(LazyDatabase(() async {
    final db = await WasmDatabase.open(
      databaseName: 'db',
      sqlite3Uri: Uri.parse('/sqlite3.wasm'),
      driftWorkerUri: Uri.parse('/drift_worker.js'),
    );

    if (db.missingFeatures.isNotEmpty) {
      debugPrint('Using ${db.chosenImplementation} due to unsupported '
          'browser features: ${db.missingFeatures}');
    }
    final executor = db.resolvedExecutor;

    return executor;
  }));
}
