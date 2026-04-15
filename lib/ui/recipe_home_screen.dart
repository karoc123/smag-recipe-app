import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smag/l10n/app_localizations.dart';

import '../domain/recipe_entity.dart';
import '../state/recipe_provider.dart';
import 'grid_screen.dart';
import 'import_screen.dart';
import 'recipe_edit_screen.dart';
import 'recipe_view_screen.dart';

class RecipeHomeScreen extends StatelessWidget {
  const RecipeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<RecipeProvider>();

    final grouped = _groupByCategory(
      provider.recipes,
      l10n.categoryUncategorized,
    );
    final categories = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2ED),
      appBar: AppBar(
        title: Text(
          l10n.recipes,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: l10n.gridTitle,
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GridScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: l10n.importRecipe,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImportScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B8F71),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecipeEditScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: provider.loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B8F71)),
            )
          : categories.isEmpty
          ? Center(
              child: Text(
                l10n.noRecipes,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF636E72),
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                final items = grouped[category]!;
                return _CategoryCard(
                  category: category,
                  count: items.length,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryRecipesScreen(
                        category: category,
                        recipes: items,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Map<String, List<RecipeEntity>> _groupByCategory(
    List<RecipeEntity> recipes,
    String fallback,
  ) {
    final grouped = <String, List<RecipeEntity>>{};
    for (final recipe in recipes) {
      final category = recipe.category.isNotEmpty ? recipe.category : fallback;
      grouped.putIfAbsent(category, () => []).add(recipe);
    }
    return grouped;
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final int count;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDD8D0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: const Color(0xFF6B8F71),
                size: 26,
              ),
              Text(
                category,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D3436),
                ),
              ),
              Text(
                '$count recipes',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF636E72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryRecipesScreen extends StatelessWidget {
  final String category;
  final List<RecipeEntity> recipes;

  const CategoryRecipesScreen({
    super.key,
    required this.category,
    required this.recipes,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...recipes]..sort((a, b) => a.title.compareTo(b.title));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2ED),
      appBar: AppBar(
        title: Text(
          category,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final recipe = sorted[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                recipe.title,
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3436),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeViewScreen(
                    recipe: recipe,
                    recipeSequence: sorted,
                    initialSequenceIndex: index,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
