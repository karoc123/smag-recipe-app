import 'dart:typed_data';

import '../data/nextcloud_api.dart';
import '../data/nextcloud_sso.dart';
import '../domain/recipe.dart';

abstract interface class RecipeRemoteGateway {
  Future<void> ensureAccountLinked();
  Future<List<RecipeStub>> getRecipes();
  Future<Recipe> getRecipe(int id);
  Future<int> createRecipe(Recipe recipe);
  Future<void> updateRecipe(Recipe recipe);
  Future<String> uploadRecipeImage(Recipe recipe, Uint8List bytes);
  Future<void> deleteRecipe(int remoteId);
  Future<int> importFromUrl(String url);
  Future<Uint8List?> getImage(int remoteId, {String size});
}

class NextcloudRecipeRemoteGateway implements RecipeRemoteGateway {
  final NextcloudApi _api;
  final NextcloudSso _sso;

  NextcloudRecipeRemoteGateway(this._api, this._sso);

  @override
  Future<void> ensureAccountLinked() async {
    final account = await _sso.getCurrentAccount();
    if (account == null) {
      throw StateError('No Nextcloud account linked');
    }
  }

  @override
  Future<int> createRecipe(Recipe recipe) => _api.createRecipe(recipe);

  @override
  Future<void> deleteRecipe(int remoteId) => _api.deleteRecipe(remoteId);

  @override
  Future<Uint8List?> getImage(int remoteId, {String size = 'full'}) {
    return _api.getImage(remoteId, size: size);
  }

  @override
  Future<String> uploadRecipeImage(Recipe recipe, Uint8List bytes) {
    return _api.uploadRecipeImage(recipe, bytes);
  }

  @override
  Future<Recipe> getRecipe(int id) => _api.getRecipe(id);

  @override
  Future<List<RecipeStub>> getRecipes() => _api.getRecipes();

  @override
  Future<int> importFromUrl(String url) => _api.importFromUrl(url);

  @override
  Future<void> updateRecipe(Recipe recipe) => _api.updateRecipe(recipe);
}
