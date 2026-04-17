import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

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

  /// Upload a local image file into the user's Nextcloud files and return the
  /// path that Cookbook accepts in the recipe JSON.
  Future<String> uploadRecipeImage(Recipe recipe, Uint8List bytes) async {
    final account = await _requireAccount();
    final uploadPath = _remoteImagePath(recipe);
    await _sso.binaryUploadRequest(
      'PUT',
      '/remote.php/dav/files/${Uri.encodeComponent(account.userId)}/${_encodePath(uploadPath)}',
      bytes,
      contentType: _contentTypeForPath(uploadPath),
    );
    return uploadPath;
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
    // The API may return a plain integer, a JSON integer, or a JSON object
    // with an "id" field depending on the Nextcloud Cookbook version.
    final trimmed = body.trim();
    final asInt = int.tryParse(trimmed);
    if (asInt != null) return asInt;
    try {
      final json = jsonDecode(trimmed);
      if (json is int) return json;
      if (json is Map<String, dynamic>) {
        final id = json['id'] ?? json['recipe_id'];
        if (id is int) return id;
        if (id is String) return int.parse(id);
      }
    } catch (_) {
      // Not JSON — ignore
    }
    // Fallback: return 0 to indicate success without a parseable id.
    return 0;
  }

  Future<NextcloudAccount> _requireAccount() async {
    final account = await _sso.getCurrentAccount();
    if (account == null) {
      throw StateError('No Nextcloud account linked');
    }
    return account;
  }

  String _remoteImagePath(Recipe recipe) {
    final baseName =
        '.smag-recipe-image-${recipe.localId ?? recipe.remoteId ?? DateTime.now().millisecondsSinceEpoch}';
    final extension = _normalizedExtension(
      recipe.localImagePath.isNotEmpty ? recipe.localImagePath : recipe.image,
    );
    return '/$baseName$extension';
  }

  String _normalizedExtension(String sourcePath) {
    final extension = p.extension(sourcePath).toLowerCase();
    if (extension == '.jpeg' ||
        extension == '.jpg' ||
        extension == '.png' ||
        extension == '.webp') {
      return extension;
    }
    return '.jpg';
  }

  String _contentTypeForPath(String path) {
    final extension = p.extension(path).toLowerCase();
    return switch (extension) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  String _encodePath(String path) {
    return path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
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
