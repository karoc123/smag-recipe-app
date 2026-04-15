import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../data/file_repository.dart';
import '../domain/recipe_entity.dart';
import '../services/config_service.dart';
import '../services/recipe_parser.dart';
import '../services/search_service.dart';

class UrlImportResult {
  final RecipeEntity recipe;
  final List<String> imageCandidates;

  const UrlImportResult({required this.recipe, required this.imageCandidates});
}

/// Central state holder for recipes.  Manages loading, CRUD, search and import.
class RecipeProvider extends ChangeNotifier {
  final FileRepository _repo;
  final RecipeParser _parser;
  final ConfigService _config;
  final SearchService _search;

  RecipeProvider(this._repo, this._parser, this._config, this._search);

  List<RecipeEntity> _recipes = [];
  List<RecipeEntity> get recipes => List.unmodifiable(_recipes);

  List<RecipeEntity> _searchResults = [];
  List<RecipeEntity> get searchResults => List.unmodifiable(_searchResults);

  bool _loading = false;
  bool get loading => _loading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<String> _categories = [];
  List<String> get categories => List.unmodifiable(_categories);

  // ──────────────────────────── Loading ──────────────────────────────

  Future<void> loadRecipes() async {
    final root = _config.rootDir;
    if (root == null) return;
    _loading = true;
    notifyListeners();

    try {
      _recipes = await _repo.loadAll(root);
      _recipes.sort((a, b) => a.title.compareTo(b.title));
      _categories = await _repo.listCategories(root);
      await _search.rebuildIndex(_recipes);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  RecipeEntity? getByPath(String relativePath) {
    try {
      return _recipes.firstWhere((r) => r.relativePath == relativePath);
    } catch (_) {
      return null;
    }
  }

  // ────────────────────────────── CRUD ───────────────────────────────

  Future<RecipeEntity> saveRecipe(
    RecipeEntity recipe, {
    String? oldRelativePath,
  }) async {
    final root = _config.rootDir!;
    String newPath;
    if (oldRelativePath != null && oldRelativePath != _expectedPath(recipe)) {
      newPath = await _repo.moveRecipe(root, oldRelativePath, recipe);
      await _search.removeRecipe(oldRelativePath);
    } else {
      newPath = await _repo.saveRecipe(root, recipe);
    }
    final saved = recipe.copyWith(relativePath: newPath);
    _recipes.removeWhere(
      (r) => r.relativePath == oldRelativePath || r.relativePath == newPath,
    );
    _recipes.add(saved);
    _recipes.sort((a, b) => a.title.compareTo(b.title));
    _categories = await _repo.listCategories(root);
    await _search.upsertRecipe(saved);
    notifyListeners();
    return saved;
  }

  Future<void> deleteRecipe(RecipeEntity recipe) async {
    final root = _config.rootDir!;
    if (recipe.relativePath != null) {
      await _repo.deleteRecipe(root, recipe.relativePath!);
      await _search.removeRecipe(recipe.relativePath!);
      await _config.removeRecipeFromSlots(recipe.relativePath!);
    }
    _recipes.remove(recipe);
    notifyListeners();
  }

  Future<bool> wouldOverwrite(RecipeEntity recipe) async {
    final root = _config.rootDir;
    if (root == null) return false;
    return _repo.exists(root, recipe);
  }

  // ─────────────────────────── Searching ─────────────────────────────

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    final paths = await _search.search(query);
    _searchResults = paths
        .map((p) {
          try {
            return _recipes.firstWhere((r) => r.relativePath == p);
          } catch (_) {
            return null;
          }
        })
        .whereType<RecipeEntity>()
        .toList();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  // ─────────────────────────── Importing ─────────────────────────────

  Future<RecipeEntity> importFromUrl(String url) async {
    final result = await importFromUrlWithCandidates(url);
    return result.recipe;
  }

  Future<UrlImportResult> importFromUrlWithCandidates(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch URL: ${response.statusCode}');
    }
    final parsed = _parser.parseHtmlWithCandidates(
      response.body,
      sourceUrl: url,
    );
    return UrlImportResult(
      recipe: parsed.recipe,
      imageCandidates: parsed.imageCandidates,
    );
  }

  RecipeEntity importFromText(String text) {
    return _parser.parsePlainText(text);
  }

  Future<String> saveImage(File sourceFile) async {
    final root = _config.rootDir;
    if (root == null) {
      throw StateError('Storage root is not initialized.');
    }
    return _repo.saveImage(root, sourceFile);
  }

  // ──────────────────────────── Helpers ──────────────────────────────

  String _expectedPath(RecipeEntity recipe) {
    final cat = recipe.category.isNotEmpty ? recipe.category : 'Uncategorized';
    return '$cat/${recipe.slug}.md';
  }
}
