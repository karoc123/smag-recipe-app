import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:smag/l10n/app_localizations.dart';

import '../domain/recipe_entity.dart';
import '../services/config_service.dart';
import '../state/recipe_provider.dart';
import 'recipe_edit_screen.dart';

class RecipeViewScreen extends StatefulWidget {
  final RecipeEntity recipe;
  final List<RecipeEntity>? recipeSequence;
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
  late List<RecipeEntity> _sequence;
  late int _index;
  RecipeEntity get _recipe => _sequence[_index];

  @override
  void initState() {
    super.initState();
    _sequence =
        widget.recipeSequence != null && widget.recipeSequence!.isNotEmpty
        ? List<RecipeEntity>.from(widget.recipeSequence!)
        : [widget.recipe];
    _index = widget.recipeSequence != null
        ? widget.initialSequenceIndex.clamp(0, _sequence.length - 1)
        : 0;
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rootDir = context.read<ConfigService>().rootDir;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: CustomScrollView(
        slivers: [
          // Hero image or plain app bar
          _buildAppBar(context, l10n, rootDir),
          // Content
          SliverToBoxAdapter(child: _buildContent(context, l10n, rootDir)),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    String? rootDir,
  ) {
    final hasImage = _recipe.imagePath != null && _recipe.imagePath!.isNotEmpty;
    Widget? background;
    if (hasImage && rootDir != null) {
      final cleaned = _recipe.imagePath!.startsWith('/')
          ? _recipe.imagePath!.substring(1)
          : _recipe.imagePath!;
      final file = File('$rootDir/$cleaned');
      if (file.existsSync()) {
        background = Image.file(file, fit: BoxFit.cover);
      }
    }

    return SliverAppBar(
      expandedHeight: hasImage && background != null ? 280 : 0,
      pinned: true,
      backgroundColor: const Color(0xFFFAF8F5),
      foregroundColor: const Color(0xFF2D3436),
      flexibleSpace: background != null
          ? FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  background,
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          tooltip: l10n.editRecipe,
          onPressed: () async {
            final updated = await Navigator.push<RecipeEntity>(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeEditScreen(recipe: _recipe),
              ),
            );
            if (updated != null) {
              setState(() {
                _sequence[_index] = updated;
              });
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: l10n.deleteRecipe,
          onPressed: () => _confirmDelete(context, l10n),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    String? rootDir,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -200) {
            _goToNextRecipe();
          } else if (velocity > 200) {
            _goToPreviousRecipe();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_sequence.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous recipe',
                      onPressed: _index > 0 ? _goToPreviousRecipe : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        '${_index + 1} / ${_sequence.length}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF636E72),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next recipe',
                      onPressed: _index < _sequence.length - 1
                          ? _goToNextRecipe
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
            // Title
            Text(
              _recipe.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2D3436),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            // Metadata row
            if (_recipe.category.isNotEmpty ||
                _recipe.servings != null ||
                _recipe.prepTime != null ||
                _recipe.cookTime != null)
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (_recipe.category.isNotEmpty)
                    _chip(Icons.folder_outlined, _recipe.category),
                  if (_recipe.servings != null)
                    _chip(Icons.people_outline_rounded, _recipe.servings!),
                  if (_recipe.prepTime != null)
                    _chip(Icons.timer_outlined, _recipe.prepTime!),
                  if (_recipe.cookTime != null)
                    _chip(
                      Icons.local_fire_department_outlined,
                      _recipe.cookTime!,
                    ),
                ],
              ),
            const SizedBox(height: 24),
            // Markdown body — strip Hugo shortcodes before rendering
            MarkdownBody(
              data: _stripShortcodes(_recipe.body),
              styleSheet: MarkdownStyleSheet(
                h2: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D3436),
                ),
                h3: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3436),
                ),
                p: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.6,
                  color: const Color(0xFF2D3436),
                ),
                listBullet: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF2D3436),
                ),
              ),
              // ignore: deprecated_member_use
              imageBuilder: (uri, title, alt) {
                if (rootDir != null) {
                  final cleaned = uri.path.startsWith('/')
                      ? uri.path.substring(1)
                      : uri.path;
                  final file = File('$rootDir/$cleaned');
                  if (file.existsSync()) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(file, fit: BoxFit.cover),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _goToNextRecipe() {
    if (_index >= _sequence.length - 1) return;
    setState(() => _index++);
  }

  void _goToPreviousRecipe() {
    if (_index <= 0) return;
    setState(() => _index--);
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B8F71)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF636E72),
          ),
        ),
      ],
    );
  }

  String _stripShortcodes(String md) {
    // Remove Hugo shortcodes like {{< figure src="..." >}}
    return md.replaceAll(RegExp(r'\{\{<[^>]*>\}\}'), '');
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final provider = context.read<RecipeProvider>();
    final nav = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteRecipe),
        content: Text(l10n.deleteConfirm(_recipe.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await provider.deleteRecipe(_recipe);
      if (mounted) nav.pop();
    }
  }
}
