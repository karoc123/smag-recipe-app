import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/recipe_database.dart';
import '../domain/recipe.dart';
import '../services/managed_recipe_image_store.dart';

/// Central recipe state holder backed by SQLite.
class RecipeProvider extends ChangeNotifier {
  final RecipeDatabase _db;
  final ManagedRecipeImageStore _imageStore;

  List<Recipe> _recipes = [];
  List<Recipe> _searchResults = [];
  List<String> _categories = [];
  String _searchQuery = '';
  bool _loading = false;

  RecipeProvider(this._db, this._imageStore);

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
    final existing = recipe.localId == null
        ? null
        : await _db.getByLocalId(recipe.localId!);
    final prepared = await _prepareImage(recipe, existing);
    final now = DateTime.now().toUtc().toIso8601String();
    final updated = prepared.copyWith(dateModified: now);

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
    await _deleteManagedImage(recipe?.localImagePath ?? '');
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

  void clearSearch({bool notify = true}) {
    _searchQuery = '';
    _searchResults = [];
    if (notify) {
      notifyListeners();
    }
  }
  // ---- Private ----

  Future<void> _refreshState() async {
    _recipes = await _db.getAllRecipes();
    _categories = await _db.getCategories();
    notifyListeners();
  }

  Future<Recipe> _prepareImage(Recipe recipe, Recipe? existing) async {
    final image = recipe.image.trim();
    final localImagePath = recipe.localImagePath.trim();

    if (image.isEmpty) {
      await _deleteManagedImage(existing?.localImagePath ?? '');
      return recipe.copyWith(image: '', localImagePath: '');
    }

    if (image.startsWith('http')) {
      await _deleteManagedImage(existing?.localImagePath ?? '');
      return recipe.copyWith(localImagePath: '');
    }

    if (localImagePath.isEmpty && !File(image).existsSync()) {
      return recipe.copyWith(localImagePath: '');
    }

    final managedPath = _imageStore.ownsPath(localImagePath)
        ? localImagePath
        : await _imageStore.persist(
            localImagePath.isNotEmpty ? localImagePath : image,
          );

    if (existing != null &&
        existing.localImagePath.isNotEmpty &&
        existing.localImagePath != managedPath) {
      await _deleteManagedImage(existing.localImagePath);
    }

    return recipe.copyWith(image: managedPath, localImagePath: managedPath);
  }

  Future<void> _deleteManagedImage(String path) async {
    if (_imageStore.ownsPath(path)) {
      await _imageStore.delete(path);
    }
  }
}
