import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../domain/recipe.dart';
import '../l10n/app_localizations.dart';
import '../services/sync_service.dart';
import '../state/recipe_provider.dart';
import 'recipe_edit_screen.dart';

/// Full-screen recipe reading view with wakelock, swipe navigation within a
/// category sequence, and Markdown rendering of the instructions body.
class RecipeViewScreen extends StatefulWidget {
  final Recipe recipe;

  /// Optional ordered list for swipe navigation.
  final List<Recipe>? recipeSequence;
  final int initialSequenceIndex;

  const RecipeViewScreen({
    super.key,
    required this.recipe,
    this.recipeSequence,
    this.initialSequenceIndex = 0,
  });

  @override
  State<RecipeViewScreen> createState() => _RecipeViewScreenState();
}

class _RecipeViewScreenState extends State<RecipeViewScreen> {
  late Recipe _current;
  late int _seqIndex;

  @override
  void initState() {
    super.initState();
    _current = widget.recipe;
    _seqIndex = widget.initialSequenceIndex;
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  bool get _hasSequence =>
      widget.recipeSequence != null && widget.recipeSequence!.length > 1;

  void _goToNext() {
    if (!_hasSequence) return;
    final seq = widget.recipeSequence!;
    if (_seqIndex < seq.length - 1) {
      setState(() {
        _seqIndex++;
        _current = seq[_seqIndex];
      });
    }
  }

  void _goToPrev() {
    if (!_hasSequence) return;
    if (_seqIndex > 0) {
      setState(() {
        _seqIndex--;
        _current = widget.recipeSequence![_seqIndex];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_current.name),
        actions: [
          if (_hasSequence)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${_seqIndex + 1} / ${widget.recipeSequence!.length}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          IconButton(icon: const Icon(Icons.edit), onPressed: _editRecipe),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteRecipe,
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: _hasSequence
            ? (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -200) {
                  _goToNext();
                } else if (velocity > 200) {
                  _goToPrev();
                }
              }
            : null,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Image
            if (_current.image.isNotEmpty) _buildImage(context),

            // Metadata chips
            _buildMetadata(context),

            const SizedBox(height: 16),

            // Ingredients
            if (_current.recipeIngredient.isNotEmpty) ...[
              Text(l10n.ingredients, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._current.recipeIngredient.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Instructions
            if (_current.recipeInstructions.isNotEmpty) ...[
              Text(l10n.instructions, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._current.recipeInstructions.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${e.key + 1}.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(child: Text(e.value)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Description (as Markdown fallback)
            if (_current.description.isNotEmpty) ...[
              MarkdownBody(data: _current.description),
              const SizedBox(height: 16),
            ],

            // Source URL
            if (_current.url.isNotEmpty) ...[
              const Divider(),
              InkWell(
                onTap: () => _launchUrl(_current.url),
                child: Text(
                  '${l10n.sourceLabel}: ${_current.url}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final image = _current.image;

    // Local cached image for remote recipes.
    if (_current.remoteId != null) {
      return FutureBuilder<String?>(
        future: SyncService.imagePath(_current.remoteId!),
        builder: (context, snapshot) {
          if (snapshot.data != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(snapshot.data!),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            );
          }
          // Fall back to network image.
          if (image.startsWith('http')) {
            return _networkImage(image);
          }
          return const SizedBox.shrink();
        },
      );
    }

    if (image.startsWith('http')) {
      return _networkImage(image);
    }

    // Local file path.
    final file = File(image);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          file,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _networkImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    final chips = <Widget>[];

    if (_current.recipeCategory.isNotEmpty) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.folder_outlined, size: 16),
          label: Text(_current.recipeCategory),
        ),
      );
    }
    if (_current.recipeYield.isNotEmpty) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.people_outline, size: 16),
          label: Text(_current.recipeYield),
        ),
      );
    }
    if (_current.prepTime.isNotEmpty) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.timer_outlined, size: 16),
          label: Text(_formatDuration(_current.prepTime)),
        ),
      );
    }
    if (_current.cookTime.isNotEmpty) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.local_fire_department_outlined, size: 16),
          label: Text(_formatDuration(_current.cookTime)),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }

  void _editRecipe() async {
    final result = await Navigator.of(context).push<Recipe>(
      MaterialPageRoute(builder: (_) => RecipeEditScreen(recipe: _current)),
    );
    if (result != null && mounted) {
      setState(() => _current = result);
      context.read<RecipeProvider>().loadRecipes();
    }
  }

  void _deleteRecipe() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteRecipe),
        content: Text(l10n.deleteRecipeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final id = _current.localId;
      if (id != null) {
        await context.read<RecipeProvider>().deleteRecipe(id);
      }
      if (mounted) Navigator.of(context).pop();
    }
  }

  /// Parse ISO-like duration strings (PT20M30S, P0DT0H25M) to readable text.
  String _formatDuration(String iso8601) {
    if (iso8601.isEmpty) return '';

    // Match ISO 8601 duration pattern: P[nD]T[nH][nM][nS]
    final regex = RegExp(
      r'^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$',
    );
    final match = regex.firstMatch(iso8601);

    if (match == null) return iso8601;

    final days = int.tryParse(match.group(1) ?? '') ?? 0;
    final hours = int.tryParse(match.group(2) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(3) ?? '') ?? 0;
    final seconds = int.tryParse(match.group(4) ?? '') ?? 0;

    final parts = <String>[];
    if (days > 0) parts.add('$days d');
    if (hours > 0) parts.add('$hours h');
    if (minutes > 0) parts.add('$minutes min');
    if (seconds > 0) parts.add('$seconds s');

    return parts.isNotEmpty ? parts.join(' ') : iso8601;
  }

  /// Launch URL if valid.
  void _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // URL launch failed, ignore silently
    }
  }
}
