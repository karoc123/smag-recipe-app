import 'dart:convert';
import 'dart:typed_data';

import '../domain/recipe.dart';
import 'nextcloud_sso.dart';

/// Dart client for the Nextcloud Cookbook REST API v1.
///
/// All network calls are delegated to [NextcloudSso] which routes them through
/// the native Android-SingleSignOn library for transparent authentication.
class NextcloudApi {
  final NextcloudSso _sso;

  static const _base = '/index.php/apps/cookbook/api/v1';

  NextcloudApi(this._sso);

  // ---------------------------------------------------------------------------
  // Recipes
  // ---------------------------------------------------------------------------

  /// Fetch the overview list of all recipes (id, name, category, dateModified).
  Future<List<RecipeStub>> getRecipes() async {
    final body = await _sso.request('GET', '$_base/recipes');
    final list = jsonDecode(body) as List;
    return list
        .map((e) => RecipeStub.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single recipe with full details.
  Future<Recipe> getRecipe(int id) async {
    final body = await _sso.request('GET', '$_base/recipes/$id');
    final json = jsonDecode(body) as Map<String, dynamic>;
    return Recipe.fromJson(json);
  }

  /// Create a new recipe on the server. Returns the new remote id.
  Future<int> createRecipe(Recipe recipe) async {
    final body = await _sso.request(
      'POST',
      '$_base/recipes',
      body: jsonEncode(recipe.toJson()),
    );
    // The API returns the new id as a plain integer string.
    return int.parse(body.trim());
  }

  /// Update an existing recipe on the server.
  Future<void> updateRecipe(Recipe recipe) async {
    if (recipe.remoteId == null) {
      throw ArgumentError('Cannot update a recipe without a remoteId');
    }
    await _sso.request(
      'PUT',
      '$_base/recipes/${recipe.remoteId}',
      body: jsonEncode(recipe.toJson()),
    );
  }

  /// Delete a recipe from the server.
  Future<void> deleteRecipe(int remoteId) async {
    await _sso.request('DELETE', '$_base/recipes/$remoteId');
  }

  // ---------------------------------------------------------------------------
  // Images
  // ---------------------------------------------------------------------------

  /// Download a recipe image. Returns raw bytes or null.
  Future<Uint8List?> getImage(int remoteId, {String size = 'full'}) async {
    return _sso.binaryRequest('$_base/recipes/$remoteId/image?size=$size');
  }

  // ---------------------------------------------------------------------------
  // Import (server-side)
  // ---------------------------------------------------------------------------

  /// Ask Nextcloud to import a recipe from a URL. Returns the new remote id.
  Future<int> importFromUrl(String url) async {
    final body = await _sso.request(
      'POST',
      '$_base/import',
      body: jsonEncode({'url': url}),
    );
    return int.parse(body.trim());
  }
}

/// Lightweight recipe preview returned by the list endpoint.
class RecipeStub {
  final int id;
  final String name;
  final String category;
  final String dateModified;

  const RecipeStub({
    required this.id,
    this.name = '',
    this.category = '',
    this.dateModified = '',
  });

  factory RecipeStub.fromJson(Map<String, dynamic> json) {
    return RecipeStub(
      id: json['recipe_id'] as int? ?? json['id'] as int? ?? 0,
      name: (json['name'] ?? '') as String,
      category: (json['recipeCategory'] ?? json['category'] ?? '') as String,
      dateModified: (json['dateModified'] ?? '') as String,
    );
  }
}
