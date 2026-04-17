import 'package:flutter_test/flutter_test.dart';
import 'package:smag/data/recipe_database.dart';
import 'package:smag/domain/recipe.dart';
import 'package:smag/services/managed_recipe_image_store.dart';
import 'package:smag/state/recipe_provider.dart';

class _FakeRecipeDatabase extends RecipeDatabase {
  Recipe? savedRecipe;
  final Map<int, Recipe> _recipes = {};
  int _nextId = 1;

  @override
  Future<Recipe?> getByLocalId(int localId) async => _recipes[localId];

  @override
  Future<Recipe> upsertRecipe(Recipe recipe, {SyncStatus? syncStatus}) async {
    final localId = recipe.localId ?? _nextId++;
    savedRecipe = recipe.copyWith(localId: localId);
    _recipes[localId] = savedRecipe!;
    return savedRecipe!;
  }

  @override
  Future<List<Recipe>> getAllRecipes() async => _recipes.values.toList();

  @override
  Future<List<String>> getCategories() async => [];
}

class _FakeManagedRecipeImageStore implements ManagedRecipeImageStore {
  String? persistedSource;
  String? deletedPath;

  @override
  Future<void> delete(String path) async {
    deletedPath = path;
  }

  @override
  bool ownsPath(String path) => path.startsWith('/managed/');

  @override
  Future<String> persist(String sourcePath) async {
    persistedSource = sourcePath;
    return '/managed/pancakes.jpg';
  }
}

void main() {
  group('RecipeProvider', () {
    test(
      'copies external local image paths into managed app storage',
      () async {
        final db = _FakeRecipeDatabase();
        final imageStore = _FakeManagedRecipeImageStore();
        final provider = RecipeProvider(db, imageStore);

        final saved = await provider.saveRecipe(
          const Recipe(
            name: 'Pancakes',
            image: '/gallery/pancakes.jpg',
            localImagePath: '/gallery/pancakes.jpg',
          ),
        );

        expect(imageStore.persistedSource, '/gallery/pancakes.jpg');
        expect(saved.localImagePath, '/managed/pancakes.jpg');
        expect(saved.image, '/managed/pancakes.jpg');
        expect(db.savedRecipe?.localImagePath, '/managed/pancakes.jpg');
      },
    );
  });
}
