import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smag/data/recipe_database.dart';
import 'package:smag/domain/recipe.dart';
import 'package:smag/l10n/app_localizations.dart';
import 'package:smag/services/managed_recipe_image_store.dart';
import 'package:smag/state/recipe_provider.dart';
import 'package:smag/ui/recipe_list_screen.dart';

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
  testWidgets('category clickflow: select category and back to overview', (
    tester,
  ) async {
    final provider = RecipeProvider(
      _FakeRecipeDatabase([
        const Recipe(localId: 1, name: 'Soup', recipeCategory: 'Dinner'),
        const Recipe(localId: 2, name: 'Pancakes', recipeCategory: 'Breakfast'),
      ]),
      _NoopManagedRecipeImageStore(),
    );
    await provider.loadRecipes();

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
          home: Scaffold(body: RecipeListScreen()),
        ),
      ),
    );

    // "All Recipes" button should be at the top of the category picker.
    expect(find.text('All Recipes'), findsOneWidget);

    // Category overview should be visible.
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);

    // Open a category.
    await tester.tap(find.text('Dinner'));
    await tester.pumpAndSettle();

    expect(find.text('Soup'), findsOneWidget);
    expect(find.text('Pancakes'), findsNothing);

    // Go back to category overview.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
  });

  testWidgets('all recipes button shows every recipe', (tester) async {
    final provider = RecipeProvider(
      _FakeRecipeDatabase([
        const Recipe(localId: 1, name: 'Soup', recipeCategory: 'Dinner'),
        const Recipe(localId: 2, name: 'Pancakes', recipeCategory: 'Breakfast'),
      ]),
      _NoopManagedRecipeImageStore(),
    );
    await provider.loadRecipes();

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
          home: Scaffold(body: RecipeListScreen()),
        ),
      ),
    );

    // Tap "All Recipes" to see every recipe.
    await tester.tap(find.text('All Recipes'));
    await tester.pumpAndSettle();

    expect(find.text('Soup'), findsOneWidget);
    expect(find.text('Pancakes'), findsOneWidget);

    // Go back to category overview.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('All Recipes'), findsOneWidget);
  });
}
