import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../domain/recipe_entity.dart';

/// SQLite FTS5 full-text search index over all recipes.
class SearchService {
  Database? _db;
  Future<void>? _initFuture;
  bool _usesFts = false;

  static const String _ftsTable = 'recipes_fts';
  static const String _fallbackTable = 'recipes_search';

  Future<void> init() async {
    if (_initFuture != null) {
      await _initFuture;
      return;
    }

    _initFuture = _open();
    await _initFuture;
  }

  Future<void> _open() async {
    final dbPath = p.join(await getDatabasesPath(), 'smag_search.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await _createSchema(db);
      },
      onOpen: (db) async {
        await _detectSchema(db);
      },
    );
  }

  Future<void> _ensureInitialized() async {
    if (_db != null) return;
    await init();
  }

  Future<void> _createSchema(Database db) async {
    // Prefer FTS5 for instant full-text search, but gracefully fallback when
    // unavailable on older Android SQLite builds.
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS $_ftsTable USING fts5(
          title,
          category,
          body,
          relative_path UNINDEXED
        )
      ''');
      _usesFts = true;
      return;
    } catch (_) {
      _usesFts = false;
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_fallbackTable (
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        body TEXT NOT NULL,
        relative_path TEXT PRIMARY KEY
      )
    ''');
  }

  Future<void> _detectSchema(Database db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('$_ftsTable', '$_fallbackTable')",
    );
    final names = rows.map((r) => r['name'] as String).toSet();
    if (names.contains(_ftsTable)) {
      _usesFts = true;
      return;
    }
    if (names.contains(_fallbackTable)) {
      _usesFts = false;
      return;
    }

    await _createSchema(db);
  }

  String get _tableName => _usesFts ? _ftsTable : _fallbackTable;

  /// Rebuild the entire index from a list of recipes.
  Future<void> rebuildIndex(List<RecipeEntity> recipes) async {
    await _ensureInitialized();
    final db = _db!;
    await db.execute('DELETE FROM $_tableName');
    final batch = db.batch();
    for (final r in recipes) {
      batch.insert(_tableName, {
        'title': r.title,
        'category': r.category,
        'body': r.body,
        'relative_path': r.relativePath ?? '',
      });
    }
    await batch.commit(noResult: true);
  }

  /// Upsert a single recipe into the index.
  Future<void> upsertRecipe(RecipeEntity recipe) async {
    await _ensureInitialized();
    final db = _db!;
    await db.execute('DELETE FROM $_tableName WHERE relative_path = ?', [
      recipe.relativePath ?? '',
    ]);
    await db.insert(_tableName, {
      'title': recipe.title,
      'category': recipe.category,
      'body': recipe.body,
      'relative_path': recipe.relativePath ?? '',
    });
  }

  /// Remove a recipe from the index.
  Future<void> removeRecipe(String relativePath) async {
    await _ensureInitialized();
    final db = _db!;
    await db.execute('DELETE FROM $_tableName WHERE relative_path = ?', [
      relativePath,
    ]);
  }

  /// Search with FTS5 query. Returns matching relative paths.
  Future<List<String>> search(String query) async {
    if (query.trim().isEmpty) return [];
    await _ensureInitialized();
    final db = _db!;
    List<Map<String, Object?>> rows;
    if (_usesFts) {
      // Append * for prefix matching with FTS.
      final ftsQuery = query
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .map((w) => '$w*')
          .join(' ');
      rows = await db.rawQuery(
        'SELECT relative_path FROM $_ftsTable WHERE $_ftsTable MATCH ? ORDER BY rowid DESC',
        [ftsQuery],
      );
    } else {
      // Portable fallback query for SQLite without FTS5 support.
      final terms = query
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .map((w) => '%$w%')
          .toList();
      if (terms.isEmpty) return [];

      final where = List.filled(
        terms.length,
        '(title LIKE ? OR category LIKE ? OR body LIKE ?)',
      ).join(' AND ');
      final args = <Object?>[];
      for (final term in terms) {
        args.addAll([term, term, term]);
      }

      rows = await db.rawQuery(
        'SELECT relative_path FROM $_fallbackTable WHERE $where ORDER BY rowid DESC LIMIT 200',
        args,
      );
    }
    return rows.map((r) => r['relative_path'] as String).toList();
  }

  Future<void> close() async {
    await _db?.close();
  }
}
