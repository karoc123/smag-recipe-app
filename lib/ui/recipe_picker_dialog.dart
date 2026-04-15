import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smag/l10n/app_localizations.dart';

import '../state/recipe_provider.dart';

/// Bottom sheet that lets the user pick a recipe to assign to a grid slot.
class RecipePickerDialog extends StatefulWidget {
  const RecipePickerDialog({super.key});

  @override
  State<RecipePickerDialog> createState() => _RecipePickerDialogState();
}

class _RecipePickerDialogState extends State<RecipePickerDialog> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<RecipeProvider>();
    final recipes = _filter.isEmpty
        ? provider.recipes
        : provider.recipes
              .where(
                (r) => r.title.toLowerCase().contains(_filter.toLowerCase()),
              )
              .toList();

    final mediaQuery = MediaQuery.of(context);

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F2ED),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  l10n.recipePickerTitle,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D3436),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    hintStyle: GoogleFonts.inter(color: Colors.grey),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF636E72),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: GoogleFonts.inter(),
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: recipes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            l10n.noRecipes,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF636E72),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.fromLTRB(
                          8,
                          0,
                          8,
                          mediaQuery.padding.bottom + 16,
                        ),
                        itemCount: recipes.length,
                        itemBuilder: (ctx, i) {
                          final r = recipes[i];
                          return ListTile(
                            title: Text(
                              r.title,
                              style: GoogleFonts.playfairDisplay(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D3436),
                              ),
                            ),
                            subtitle: r.category.isNotEmpty
                                ? Text(
                                    r.category,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF636E72),
                                    ),
                                  )
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: () => Navigator.pop(context, r),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
