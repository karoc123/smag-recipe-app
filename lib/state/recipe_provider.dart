import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/recipe_database.dart';
import '../domain/recipe.dart';
import '../services/recipe_parser.dart';

/// Result of a URL import: the parsed recipe plus image candidate URLs.
class UrlImportResult {
  final Recipe recipe;
  final List<String> imageCandidates;
  const UrlImportResult({required this.recipe, required this.imageCandidates});
}

/// Central recipe state holder backed by SQLite.
class RecipeProvider extends ChangeNotifier {
  final RecipeDatabase _db;
  final RecipeParser _parser;

  List<Recipe> _recipes = [];
  List<Recipe> _searchResults = [];
  List<String> _categories = [];
  String _searchQuery = '';
  bool _loading = false;

  RecipeProvider(this._db, this._parser);

  // ---- Getters ----

  List<Recipe> get recipes => _recipes;
  List<Recipe> get searchResults => _searchResults;
  List<String> get categories => _categories;
  String get searchQuery => _searchQuery;
  bool get loading => _loading;

  // ---- Load ----

  Future<void> loadRecipes() async {
    _loading = true;
    notifyListeners();
    try {
      _recipes = await _db.getAllRecipes();
      _categories = await _db.getCategories();
    } catch (e) {
      debugPrint('Failed to load recipes: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ---- CRUD ----

  Recipe? getByLocalId(int localId) {
    try {
      return _recipes.firstWhere((r) => r.localId == localId);
    } catch (_) {
      return null;
    }
  }

  Future<Recipe> saveRecipe(Recipe recipe) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final updated = recipe.copyWith(dateModified: now);

    // Determine sync status: if it has a remoteId, mark as pending upload.
    final status = updated.remoteId != null
        ? SyncStatus.pendingUpload
        : SyncStatus.localOnly;

    final saved = await _db.upsertRecipe(updated, syncStatus: status);
    await _refreshState();
    return saved;
  }

  Future<void> deleteRecipe(int localId) async {
    final recipe = await _db.getByLocalId(localId);
    if (recipe?.remoteId != null) {
      await _db.queuePendingDeletion(recipe!.remoteId!);
    }
    await _db.removeRecipeFromGrid(localId);
    await _db.deleteRecipe(localId);
    await _refreshState();
  }

  // ---- Search ----

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = await _db.search(query);
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  // ---- Import ----

  Future<UrlImportResult> importFromUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final result = _parser.parseHtmlWithCandidates(
      response.body,
      sourceUrl: url,
    );
    return UrlImportResult(
      recipe: result.recipe,
      imageCandidates: result.imageCandidates,
    );
  }

  Recipe importFromText(String text) {
    return _parser.parsePlainText(text);
  }

  // ---- Private ----

  Future<void> _refreshState() async {
    _recipes = await _db.getAllRecipes();
    _categories = await _db.getCategories();
    notifyListeners();
  }
}
