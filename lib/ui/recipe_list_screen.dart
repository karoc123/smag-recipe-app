import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../domain/recipe.dart';
import '../l10n/app_localizations.dart';
import '../state/recipe_provider.dart';
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
  String? _selectedCategory;
  bool _searching = false;
  final _searchController = TextEditingController();

  bool get _inCategory => _selectedCategory != null;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<RecipeProvider>();
    final recipes = provider.searchQuery.isNotEmpty
        ? provider.searchResults
        : provider.recipes;

    // Get all categories
    final allCategories = <String>{};
    for (final r in recipes) {
      allCategories.add(r.displayCategory);
    }
    final categories = allCategories.toList()..sort();

    // If no category selected, show category picker.
    if (_selectedCategory == null) {
      return PopScope(
        canPop: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.recipes),
            automaticallyImplyLeading: false,
          ),
          body: _CategoryPicker(
            categories: categories,
            onSelect: (cat) {
              setState(() => _selectedCategory = cat);
            },
          ),
        ),
      );
    }

    // Filter recipes to selected category
    final categoryRecipes = recipes
        .where((r) => r.displayCategory == _selectedCategory)
        .toList();

    return PopScope(
      canPop: !_inCategory,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_inCategory) {
          setState(() {
            _selectedCategory = null;
            _searching = false;
            _searchController.clear();
            provider.clearSearch();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _searching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.search,
                    border: InputBorder.none,
                    filled: false,
                  ),
                  onChanged: (q) => provider.search(q),
                )
              : Text(_selectedCategory!),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _searching = false;
                _searchController.clear();
                provider.clearSearch();
              });
            },
          ),
          actions: [
            IconButton(
              icon: Icon(_searching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _searching = !_searching;
                  if (!_searching) {
                    _searchController.clear();
                    provider.clearSearch();
                  }
                });
              },
            ),
          ],
        ),
        body: categoryRecipes.isEmpty
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
    );
  }
}

/// Category picker UI with elegant Scandinavian design.
class _CategoryPicker extends StatelessWidget {
  final List<String> categories;
  final Function(String) onSelect;

  const _CategoryPicker({required this.categories, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
    return ListTile(
      minVerticalPadding: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: recipe.image.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 48,
                height: 48,
                child: CachedNetworkImage(
                  imageUrl: recipe.image,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 24),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 24),
                  ),
                ),
              ),
            )
          : null,
      title: Align(alignment: Alignment.centerLeft, child: Text(recipe.name)),
      trailing: const Icon(Icons.chevron_right),
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
