import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smag/l10n/app_localizations.dart';

import '../domain/recipe_entity.dart';
import '../state/recipe_provider.dart';
import 'recipe_view_screen.dart';
import 'recipe_edit_screen.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F2ED),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF2D3436),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.inter(color: Colors.grey),
                ),
                style: GoogleFonts.inter(),
                onChanged: (q) => provider.search(q),
              )
            : Text(
                l10n.recipes,
                style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) {
                _searchController.clear();
                provider.clearSearch();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B8F71),
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecipeEditScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: provider.loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B8F71)),
            )
          : recipes.isEmpty
          ? Center(
              child: Text(
                provider.searchQuery.isNotEmpty
                    ? l10n.noResults
                    : l10n.noRecipes,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF636E72),
                ),
              ),
            )
          : _buildList(context, recipes),
    );
  }

  Widget _buildList(BuildContext context, List<RecipeEntity> recipes) {
    // Group by category
    final grouped = <String, List<RecipeEntity>>{};
    for (final r in recipes) {
      final cat = r.category.isNotEmpty ? r.category : 'Uncategorized';
      grouped.putIfAbsent(cat, () => []).add(r);
    }
    final sortedKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: sortedKeys.length,
      itemBuilder: (ctx, catIndex) {
        final category = sortedKeys[catIndex];
        final items = grouped[category]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (catIndex > 0) const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                category,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF636E72),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...items.map((recipe) => _RecipeTile(recipe: recipe)),
          ],
        );
      },
    );
  }
}

class _RecipeTile extends StatelessWidget {
  final RecipeEntity recipe;
  const _RecipeTile({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          recipe.title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3436),
          ),
        ),
        subtitle: recipe.servings != null || recipe.prepTime != null
            ? Text(
                [
                  if (recipe.servings != null) recipe.servings!,
                  if (recipe.prepTime != null) recipe.prepTime!,
                ].join(' · '),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF636E72),
                ),
              )
            : null,
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFB2BEC3),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeViewScreen(recipe: recipe)),
        ),
      ),
    );
  }
}
