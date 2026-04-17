import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/recipe.dart';
import '../l10n/app_localizations.dart';
import '../state/recipe_provider.dart';
import 'recipe_summary_tile.dart';
import 'recipe_view_screen.dart';

/// Full-screen search overlay that queries all recipes regardless of category.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  late final RecipeProvider _recipeProvider;
  var _providerBound = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_providerBound) return;
    _recipeProvider = context.read<RecipeProvider>();
    _providerBound = true;
  }

  @override
  void dispose() {
    // Reset stale search state without notifying during framework teardown.
    _recipeProvider.clearSearch(notify: false);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<RecipeProvider>();
    final results = provider.searchResults;
    final hasQuery = provider.searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.search,
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (q) => provider.search(q),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                provider.clearSearch();
              },
            ),
        ],
      ),
      body: !hasQuery
          ? Center(
              child: Text(
                l10n.search,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : results.isEmpty
          ? Center(child: Text(l10n.noRecipes))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: results.length,
              itemBuilder: (context, i) => _SearchResultTile(
                recipe: results[i],
                allResults: results,
                index: i,
              ),
            ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Recipe recipe;
  final List<Recipe> allResults;
  final int index;

  const _SearchResultTile({
    required this.recipe,
    required this.allResults,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return RecipeSummaryTile(
      recipe: recipe,
      subtitle: recipe.displayCategory,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeViewScreen(
              recipe: recipe,
              recipeSequence: allResults,
              initialSequenceIndex: index,
            ),
          ),
        );
      },
    );
  }
}
