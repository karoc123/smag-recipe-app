import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/recipe.dart';
import '../l10n/app_localizations.dart';
import '../state/recipe_provider.dart';
import 'recipe_summary_tile.dart';
import 'recipe_view_screen.dart';

/// Recipe list with category selection first, then filtered recipe view.
///
/// Groups recipes by [Recipe.displayCategory], shows categories as a picker,
/// then displays only recipes in the selected category.
class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  /// null = category picker; empty string = all recipes; non-empty = category.
  String? _selectedCategory;

  bool get _inCategory => _selectedCategory != null;

  /// Sentinel for the "All Recipes" virtual category.
  static const _allRecipesSentinel = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<RecipeProvider>();
    final recipes = provider.recipes;

    // Get all categories
    final allCategories = <String>{};
    for (final r in recipes) {
      allCategories.add(r.displayCategory);
    }
    final categories = allCategories.toList()..sort();

    // If no category selected, show category picker.
    if (_selectedCategory == null) {
      return _CategoryPicker(
        categories: categories,
        allRecipesLabel: l10n.allRecipes,
        onSelect: (cat) {
          setState(() => _selectedCategory = cat);
        },
      );
    }

    // Filter recipes: empty string means show all.
    final showAll = _selectedCategory == _allRecipesSentinel;
    final categoryRecipes = showAll
        ? recipes
        : recipes.where((r) => r.displayCategory == _selectedCategory).toList();

    final headerTitle = showAll ? l10n.allRecipes : _selectedCategory!;

    return PopScope(
      canPop: !_inCategory,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_inCategory) {
          setState(() {
            _selectedCategory = null;
          });
        }
      },
      child: Column(
        children: [
          Material(
            child: ListTile(
              leading: const Icon(Icons.arrow_back),
              title: Text(
                headerTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () => setState(() => _selectedCategory = null),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: categoryRecipes.isEmpty
                ? Center(child: Text(l10n.noRecipes))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: categoryRecipes.length,
                    itemBuilder: (context, i) => _RecipeTile(
                      recipe: categoryRecipes[i],
                      peerRecipes: categoryRecipes,
                      index: i,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Category picker UI with elegant Scandinavian design.
class _CategoryPicker extends StatelessWidget {
  final List<String> categories;
  final String allRecipesLabel;
  final Function(String) onSelect;

  const _CategoryPicker({
    required this.categories,
    required this.allRecipesLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "All Recipes" always first.
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FilledButton.tonal(
              onPressed: () => onSelect(''),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                allRecipesLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton(
                onPressed: () => onSelect(cat),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                child: Text(
                  cat,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recipe list tile with optional thumbnail.
class _RecipeTile extends StatelessWidget {
  final Recipe recipe;
  final List<Recipe> peerRecipes;
  final int index;

  const _RecipeTile({
    required this.recipe,
    required this.peerRecipes,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return RecipeSummaryTile(
      recipe: recipe,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeViewScreen(
              recipe: recipe,
              recipeSequence: peerRecipes,
              initialSequenceIndex: index,
            ),
          ),
        );
      },
    );
  }
}
