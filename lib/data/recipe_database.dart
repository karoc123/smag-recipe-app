import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/recipe.dart';

/// Local SQLite storage for recipes and grid slot assignments.
///
/// Stores the full Nextcloud Cookbook JSON per recipe so round-tripping to the
/// API is lossless. Indexed columns enable fast list / search queries.
class RecipeDatabase {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'smag_recipes.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recipes (
            local_id     INTEGER PRIMARY KEY AUTOINCREMENT,
            remote_id    INTEGER,
            name         TEXT NOT NULL DEFAULT '',
            category     TEXT NOT NULL DEFAULT '',
            json_data    TEXT NOT NULL,
            image_path   TEXT NOT NULL DEFAULT '',
            sync_status  TEXT NOT NULL DEFAULT 'localOnly',
            date_modified TEXT NOT NULL DEFAULT '',
            remote_date_modified TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_recipes_remote ON recipes(remote_id)',
        );
        await db.execute(
          'CREATE INDEX idx_recipes_category ON recipes(category)',
        );

        await db.execute('''
          CREATE TABLE grid_slots (
            position  INTEGER PRIMARY KEY,
            recipe_id INTEGER,
            FOREIGN KEY (recipe_id) REFERENCES recipes(local_id) ON DELETE SET NULL
          )
        ''');

        // Initialize 7 grid slots.
        for (var i = 0; i < 7; i++) {
          await db.insert('grid_slots', {'position': i, 'recipe_id': null});
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Recipes CRUD
  // ---------------------------------------------------------------------------

  Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    final rows = await db.query('recipes', orderBy: 'name COLLATE NOCASE');
    return rows.map(_rowToRecipe).toList();
  }

  Future<Recipe?> getByLocalId(int localId) async {
    final db = await database;
    final rows = await db.query(
      'recipes',
      where: 'local_id = ?',
      whereArgs: [localId],
    );
    if (rows.isEmpty) return null;
    return _rowToRecipe(rows.first);
  }

  Future<Recipe?> getByRemoteId(int remoteId) async {
    final db = await database;
    final rows = await db.query(
      'recipes',
      where: 'remote_id = ?',
      whereArgs: [remoteId],
    );
    if (rows.isEmpty) return null;
    return _rowToRecipe(rows.first);
  }

  /// Insert or update a recipe. Returns the recipe with its [localId] set.
  Future<Recipe> upsertRecipe(Recipe recipe, {SyncStatus? syncStatus}) async {
    final db = await database;
    final status = syncStatus ?? SyncStatus.localOnly;
    final json = jsonEncode(recipe.toJson());
    final now = DateTime.now().toUtc().toIso8601String();

    if (recipe.localId != null) {
      // Update existing.
      await db.update(
        'recipes',
        {
          'remote_id': recipe.remoteId,
          'name': recipe.name,
          'category': recipe.recipeCategory,
          'json_data': json,
          'image_path': recipe.image,
          'sync_status': status.name,
          'date_modified': recipe.dateModified.isEmpty
              ? now
              : recipe.dateModified,
        },
        where: 'local_id = ?',
        whereArgs: [recipe.localId],
      );
      return recipe;
    }

    // Insert new.
    final id = await db.insert('recipes', {
      'remote_id': recipe.remoteId,
      'name': recipe.name,
      'category': recipe.recipeCategory,
      'json_data': json,
      'image_path': recipe.image,
      'sync_status': status.name,
      'date_modified': recipe.dateModified.isEmpty ? now : recipe.dateModified,
      'remote_date_modified': recipe.dateModified,
    });
    return recipe.copyWith(localId: id);
  }

  Future<void> deleteRecipe(int localId) async {
    final db = await database;
    await db.delete('recipes', where: 'local_id = ?', whereArgs: [localId]);
  }

  Future<List<Recipe>> search(String query) async {
    final db = await database;
    final pattern = '%$query%';
    final rows = await db.query(
      'recipes',
      where: 'name LIKE ? OR category LIKE ? OR json_data LIKE ?',
      whereArgs: [pattern, pattern, pattern],
      orderBy: 'name COLLATE NOCASE',
      limit: 200,
    );
    return rows.map(_rowToRecipe).toList();
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT category FROM recipes WHERE category != '' ORDER BY category COLLATE NOCASE",
    );
    return rows.map((r) => r['category'] as String).toList();
  }

  /// Update sync status for a recipe.
  Future<void> setSyncStatus(
    int localId,
    SyncStatus status, {
    String? remoteDateModified,
  }) async {
    final db = await database;
    final values = <String, dynamic>{'sync_status': status.name};
    if (remoteDateModified != null) {
      values['remote_date_modified'] = remoteDateModified;
    }
    await db.update(
      'recipes',
      values,
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  /// Get all recipes that need to be pushed to the server.
  Future<List<Recipe>> getPendingUploads() async {
    final db = await database;
    final rows = await db.query(
      'recipes',
      where: 'sync_status = ?',
      whereArgs: ['pendingUpload'],
    );
    return rows.map(_rowToRecipe).toList();
  }

  /// Get all recipes in conflict state.
  Future<List<Recipe>> getConflicts() async {
    final db = await database;
    final rows = await db.query(
      'recipes',
      where: 'sync_status = ?',
      whereArgs: ['conflict'],
    );
    return rows.map(_rowToRecipe).toList();
  }

  // ---------------------------------------------------------------------------
  // Grid slots
  // ---------------------------------------------------------------------------

  /// Returns a map of position → localId (null if slot is empty).
  Future<Map<int, int?>> getGridSlots() async {
    final db = await database;
    final rows = await db.query('grid_slots', orderBy: 'position');
    return {for (final r in rows) r['position'] as int: r['recipe_id'] as int?};
  }

  Future<void> setGridSlot(int position, int? recipeId) async {
    final db = await database;
    await db.insert('grid_slots', {
      'position': position,
      'recipe_id': recipeId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearGridSlot(int position) async {
    await setGridSlot(position, null);
  }

  Future<void> swapGridSlots(int a, int b) async {
    final db = await database;
    await db.transaction((txn) async {
      final rowA = await txn.query(
        'grid_slots',
        where: 'position = ?',
        whereArgs: [a],
      );
      final rowB = await txn.query(
        'grid_slots',
        where: 'position = ?',
        whereArgs: [b],
      );
      final idA = rowA.isEmpty ? null : rowA.first['recipe_id'] as int?;
      final idB = rowB.isEmpty ? null : rowB.first['recipe_id'] as int?;
      await txn.insert('grid_slots', {
        'position': a,
        'recipe_id': idB,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('grid_slots', {
        'position': b,
        'recipe_id': idA,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  /// Remove a recipe from all grid slots (e.g. on recipe deletion).
  Future<void> removeRecipeFromGrid(int recipeId) async {
    final db = await database;
    await db.update(
      'grid_slots',
      {'recipe_id': null},
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Recipe _rowToRecipe(Map<String, dynamic> row) {
    final json = jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
    return Recipe.fromJson(json).copyWith(
      localId: row['local_id'] as int,
      remoteId: row['remote_id'] as int?,
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
