import 'dart:typed_data';

import '../data/nextcloud_api.dart';
import '../data/nextcloud_sso.dart';
import '../domain/recipe.dart';

abstract interface class RecipeRemoteGateway {
  Future<void> ensureAccountLinked();
  Future<String> getCookbookFolderPath();
  Future<List<RecipeStub>> getRecipes();
  Future<Recipe> getRecipe(int id);
  Future<int> createRecipe(Recipe recipe);
  Future<void> updateRecipe(Recipe recipe);
  Future<StagedRecipeImage> uploadRecipeImage(
    Recipe recipe,
    Uint8List bytes, {
    required String cookbookFolderPath,
  });
  Future<void> deleteUserFile(
    String path, {
    required String cookbookFolderPath,
  });
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
  Future<void> deleteUserFile(
    String path, {
    required String cookbookFolderPath,
  }) {
    return _api.deleteUserFile(path, cookbookFolderPath: cookbookFolderPath);
  }

  @override
  Future<void> deleteRecipe(int remoteId) => _api.deleteRecipe(remoteId);

  @override
  Future<Uint8List?> getImage(int remoteId, {String size = 'full'}) {
    return _api.getImage(remoteId, size: size);
  }

  @override
  Future<String> getCookbookFolderPath() async {
    final config = await _api.getConfig();
    return config.folderPath;
  }

  @override
  Future<StagedRecipeImage> uploadRecipeImage(
    Recipe recipe,
    Uint8List bytes, {
    required String cookbookFolderPath,
  }) {
    return _api.uploadRecipeImage(
      recipe,
      bytes,
      cookbookFolderPath: cookbookFolderPath,
    );
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
