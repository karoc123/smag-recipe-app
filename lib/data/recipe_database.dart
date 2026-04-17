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
  static const int gridSlotCount = 1;

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
      version: 2,
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
        for (var i = 0; i < gridSlotCount; i++) {
          await db.insert('grid_slots', {'position': i, 'recipe_id': null});
        }

        await db.execute('''
          CREATE TABLE pending_deletions (
            remote_id INTEGER PRIMARY KEY
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS pending_deletions (
              remote_id INTEGER PRIMARY KEY
            )
          ''');
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
      final values = <String, Object?>{
        'remote_id': recipe.remoteId,
        'name': recipe.name,
        'category': recipe.recipeCategory,
        'json_data': json,
        'image_path': recipe.localImagePath,
        'sync_status': status.name,
        'date_modified': recipe.dateModified.isEmpty
            ? now
            : recipe.dateModified,
      };
      if (status == SyncStatus.synced) {
        values['remote_date_modified'] = recipe.dateModified;
      }

      await db.update(
        'recipes',
        values,
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
      'image_path': recipe.localImagePath,
      'sync_status': status.name,
      'date_modified': recipe.dateModified.isEmpty ? now : recipe.dateModified,
      'remote_date_modified': status == SyncStatus.synced
          ? recipe.dateModified
          : '',
    });
    return recipe.copyWith(localId: id);
  }

  Future<void> deleteRecipe(int localId) async {
    final db = await database;
    await db.delete('recipes', where: 'local_id = ?', whereArgs: [localId]);
  }

  /// Queue a remote recipe id for deletion during the next sync run.
  Future<void> queuePendingDeletion(int remoteId) async {
    final db = await database;
    await db.insert('pending_deletions', {
      'remote_id': remoteId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Returns all remote ids waiting for deletion on the server.
  Future<List<int>> getPendingDeletions() async {
    final db = await database;
    final rows = await db.query('pending_deletions', columns: ['remote_id']);
    return rows.map((r) => r['remote_id'] as int).toList();
  }

  /// Remove a remote id from pending deletions after successful sync delete.
  Future<void> clearPendingDeletion(int remoteId) async {
    final db = await database;
    await db.delete(
      'pending_deletions',
      where: 'remote_id = ?',
      whereArgs: [remoteId],
    );
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
      where: 'sync_status IN (?, ?)',
      whereArgs: ['pendingUpload', 'localOnly'],
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
    await _normalizeGridSlots(db);
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

  Future<void> clearAllGridSlots() async {
    final db = await database;
    await db.update('grid_slots', {'recipe_id': null});
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

  Future<bool> hasSyncStatus(int localId, SyncStatus status) async {
    final db = await database;
    final rows = await db.query(
      'recipes',
      columns: ['sync_status'],
      where: 'local_id = ?',
      whereArgs: [localId],
    );
    if (rows.isEmpty) return false;
    return rows.first['sync_status'] == status.name;
  }

  /// True when the server's `dateModified` has changed since last synced pull.
  Future<bool> hasRemoteVersionChanged(
    int localId,
    String remoteDateModified,
  ) async {
    final db = await database;
    final rows = await db.query(
      'recipes',
      columns: ['remote_date_modified'],
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );

    if (rows.isEmpty) return true;
    final previous = (rows.first['remote_date_modified'] as String?) ?? '';
    if (previous.isEmpty) return true;
    return previous != remoteDateModified;
  }

  Recipe _rowToRecipe(Map<String, dynamic> row) {
    final json = jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
    return Recipe.fromJson(json).copyWith(
      localId: row['local_id'] as int,
      localImagePath: (row['image_path'] as String?) ?? '',
      remoteId: row['remote_id'] as int?,
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> _normalizeGridSlots(Database db) async {
    final rows = await db.query('grid_slots', orderBy: 'position');
    if (rows.isEmpty) {
      await db.insert('grid_slots', {
        'position': 0,
        'recipe_id': null,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    var maxFilled = -1;
    final existingPositions = <int>{};
    for (final row in rows) {
      final position = row['position'] as int;
      existingPositions.add(position);
      if (row['recipe_id'] != null && position > maxFilled) {
        maxFilled = position;
      }
    }

    final maxRequiredPosition = maxFilled < 0 ? 0 : maxFilled + 1;

    for (var i = 0; i <= maxRequiredPosition; i++) {
      if (!existingPositions.contains(i)) {
        await db.insert('grid_slots', {
          'position': i,
          'recipe_id': null,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    await db.delete(
      'grid_slots',
      where: 'position > ? AND recipe_id IS NULL',
      whereArgs: [maxRequiredPosition],
    );
  }
}
