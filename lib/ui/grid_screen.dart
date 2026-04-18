import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../domain/recipe.dart';
import '../l10n/app_localizations.dart';
import '../state/grid_provider.dart';
import 'recipe_picker_dialog.dart';
import 'recipe_view_screen.dart';

/// Dynamic meal planning grid with drag-and-drop and images.
class GridScreen extends StatefulWidget {
  const GridScreen({super.key});

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.grid),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => _showShoppingList(context),
            tooltip: l10n.shoppingList,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _clearAllSlots(context),
            tooltip: l10n.clearGrid,
          ),
        ],
      ),
      body: _GridBody(
        isDragging: _isDragging,
        onDragStart: () => setState(() => _isDragging = true),
        onDragEnd: () => setState(() => _isDragging = false),
      ),
    );
  }

  void _showShoppingList(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final grid = context.read<GridProvider>();

    // Aggregate all ingredients from filled slots
    final allIngredients = <String>[];
    for (int i = 0; i < grid.visibleSlotCount; i++) {
      if (grid.isFilled(i)) {
        final recipe = await grid.recipeAt(i);
        if (recipe != null) {
          allIngredients.addAll(recipe.recipeIngredient);
        }
      }
    }

    allIngredients.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.shoppingList),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: allIngredients.isEmpty
                ? [Text(l10n.noRecipes)]
                : allIngredients
                      .map(
                        (ing) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(ing)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          FilledButton(
            onPressed: () {
              _copyIngredientsToClipboard(allIngredients);
              Navigator.pop(context);
            },
            child: Text(l10n.copyPrompt),
          ),
        ],
      ),
    );
  }

  void _copyIngredientsToClipboard(List<String> ingredients) {
    final text = ingredients.join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.promptCopied)),
    );
  }

  void _clearAllSlots(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearGrid),
        content: Text(l10n.clearGridConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              context.read<GridProvider>().clearAll();
              Navigator.pop(ctx);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _GridBody extends StatelessWidget {
  final bool isDragging;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  const _GridBody({
    required this.isDragging,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final grid = context.watch<GridProvider>();
    final visibleSlotCount = grid.visibleSlotCount;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: visibleSlotCount,
        itemBuilder: (context, index) {
          // While dragging, replace the trailing "+" tile with a delete tile.
          if (isDragging && index == visibleSlotCount - 1) {
            return _DeleteSlot(onDragEnd: onDragEnd);
          }
          return _GridSlot(
            index: index,
            onDragStart: onDragStart,
            onDragEnd: onDragEnd,
          );
        },
      ),
    );
  }
}

class _GridSlot extends StatelessWidget {
  final int index;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  const _GridSlot({
    required this.index,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final grid = context.watch<GridProvider>();
    final filled = grid.isFilled(index);

    if (!filled) {
      return _EmptySlot(index: index);
    }

    return FutureBuilder<Recipe?>(
      future: grid.recipeAt(index),
      builder: (context, snapshot) {
        final recipe = snapshot.data;
        if (recipe == null) {
          return _EmptySlot(index: index);
        }
        return _FilledSlot(
          index: index,
          recipe: recipe,
          onDragStart: onDragStart,
          onDragEnd: onDragEnd,
        );
      },
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final int index;

  const _EmptySlot({required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        final grid = context.read<GridProvider>();
        grid.swap(details.data, index);
      },
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        return Card(
          color: hovering
              ? theme.colorScheme.primaryContainer
              : theme.cardTheme.color,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pickRecipe(context, index),
            child: Center(
              child: Icon(
                Icons.add,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickRecipe(BuildContext context, int index) async {
    final recipe = await showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const RecipePickerDialog(),
    );
    if (recipe != null && context.mounted) {
      context.read<GridProvider>().assign(index, recipe);
    }
  }
}

/// Delete target tile that appears during drag.
class _DeleteSlot extends StatelessWidget {
  final VoidCallback onDragEnd;

  const _DeleteSlot({required this.onDragEnd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        context.read<GridProvider>().clear(details.data);
        onDragEnd();
      },
      onLeave: (_) {
        onDragEnd();
      },
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        return Card(
          color: hovering
              ? theme.colorScheme.errorContainer
              : theme.cardTheme.color,
          child: Center(
            child: Icon(
              Icons.delete_outline,
              size: 32,
              color: hovering
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }
}

class _FilledSlot extends StatelessWidget {
  final int index;
  final Recipe recipe;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  const _FilledSlot({
    required this.index,
    required this.recipe,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LongPressDraggable<int>(
      data: index,
      onDragStarted: onDragStart,
      onDragEnd: (_) => onDragEnd(),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 140,
          height: 140,
          child: _RecipeTileContent(recipe: recipe),
        ),
      ),
      childWhenDragging: Card(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const SizedBox.expand(),
      ),
      child: DragTarget<int>(
        onAcceptWithDetails: (details) {
          context.read<GridProvider>().swap(details.data, index);
          onDragEnd();
        },
        builder: (context, candidateData, _) {
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _viewRecipe(context),
              child: _RecipeTileContent(recipe: recipe),
            ),
          );
        },
      ),
    );
  }

  Future<void> _viewRecipe(BuildContext context) async {
    final grid = context.read<GridProvider>();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => RecipeViewScreen(recipe: recipe)));
    if (!context.mounted) return;
    await grid.load();
  }
}

/// Displays recipe as image with text overlay, or just text.
class _RecipeTileContent extends StatelessWidget {
  final Recipe recipe;

  const _RecipeTileContent({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = recipe.displayImage;

    if (image.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            recipe.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImage(image),
        Container(color: Colors.black.withValues(alpha: 0.4)),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Text(
              recipe.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String image) {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[300]),
        errorWidget: (context, url, error) =>
            Container(color: Colors.grey[300]),
      );
    }

    final file = File(image);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }

    return Container(color: Colors.grey[300]);
  }
}
