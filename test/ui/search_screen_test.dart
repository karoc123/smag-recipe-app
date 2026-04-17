import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smag/data/recipe_database.dart';
import 'package:smag/domain/recipe.dart';
import 'package:smag/l10n/app_localizations.dart';
import 'package:smag/services/managed_recipe_image_store.dart';
import 'package:smag/state/recipe_provider.dart';
import 'package:smag/ui/search_screen.dart';

class _FakeRecipeDatabase extends RecipeDatabase {
  final List<Recipe> _recipes;

  _FakeRecipeDatabase(this._recipes);

  @override
  Future<List<Recipe>> getAllRecipes() async => _recipes;

  @override
  Future<List<String>> getCategories() async => _recipes
      .map((r) => r.recipeCategory)
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList();

  @override
  Future<List<Recipe>> search(String query) async {
    final q = query.toLowerCase();
    return _recipes.where((r) => r.name.toLowerCase().contains(q)).toList();
  }
}

class _NoopManagedRecipeImageStore implements ManagedRecipeImageStore {
  @override
  Future<void> delete(String path) async {}

  @override
  bool ownsPath(String path) => false;

  @override
  Future<String> persist(String sourcePath) async => sourcePath;
}

void main() {
  testWidgets('search screen clears provider state when disposed', (
    tester,
  ) async {
    final provider = RecipeProvider(
      _FakeRecipeDatabase([
        const Recipe(localId: 1, name: 'Soup', recipeCategory: 'Dinner'),
      ]),
      _NoopManagedRecipeImageStore(),
    );
    await provider.loadRecipes();
    await provider.search('Soup');

    await tester.pumpWidget(
      ChangeNotifierProvider<RecipeProvider>.value(
        value: provider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: SearchScreen(),
        ),
      ),
    );

    expect(provider.searchQuery, 'Soup');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(provider.searchQuery, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
