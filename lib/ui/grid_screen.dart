import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smag/l10n/app_localizations.dart';

import '../domain/recipe_entity.dart';
import '../state/grid_provider.dart';
import '../state/recipe_provider.dart';
import '../services/config_service.dart';
import '../services/webdav_sync_service.dart';
import 'recipe_home_screen.dart';
import 'recipe_picker_dialog.dart';
import 'recipe_view_screen.dart';
import 'import_screen.dart';
import 'recipe_edit_screen.dart';

class GridScreen extends StatefulWidget {
  const GridScreen({super.key});

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  bool _showRemoveZone = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final grid = context.watch<GridProvider>();
    final recipes = context.watch<RecipeProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2ED),
      appBar: AppBar(
        title: Text(
          l10n.gridTitle,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFF5F2ED),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF2D3436),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_rounded),
            tooltip: l10n.recipes,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecipeHomeScreen()),
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
          IconButton(
            icon: const Icon(Icons.cloud_sync_outlined),
            tooltip: 'WebDAV Sync',
            onPressed: _openWebDavSettings,
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
      body: _buildGrid(context, l10n, grid, recipes),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    AppLocalizations l10n,
    GridProvider grid,
    RecipeProvider recipes,
  ) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: GridView.builder(
              itemCount: grid.slotCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (ctx, index) {
                final path = grid.pathAt(index);
                final recipe = path != null ? recipes.getByPath(path) : null;
                return _buildSlot(context, l10n, index, recipe, grid);
              },
            ),
          ),
        ),
        // Drag-to-remove zone — slides up when dragging
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _showRemoveZone ? 72 : 0,
          child: _showRemoveZone
              ? DragTarget<int>(
                  onWillAcceptWithDetails: (_) => true,
                  onAcceptWithDetails: (details) {
                    context.read<GridProvider>().clear(details.data);
                    setState(() => _showRemoveZone = false);
                  },
                  builder: (ctx, candidateData, _) {
                    final hovering = candidateData.isNotEmpty;
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: hovering
                            ? Colors.red.shade100
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hovering ? Colors.red : Colors.red.shade200,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: hovering
                                  ? Colors.red
                                  : Colors.red.shade300,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.dragToRemove,
                              style: TextStyle(
                                color: hovering
                                    ? Colors.red
                                    : Colors.red.shade300,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSlot(
    BuildContext context,
    AppLocalizations l10n,
    int index,
    RecipeEntity? recipe,
    GridProvider grid,
  ) {
    if (recipe == null) {
      return _buildEmptySlot(context, l10n, index, grid);
    }
    return _buildFilledSlot(context, index, recipe, grid);
  }

  Widget _buildEmptySlot(
    BuildContext context,
    AppLocalizations l10n,
    int index,
    GridProvider grid,
  ) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) {
        grid.swap(details.data, index);
        setState(() => _showRemoveZone = false);
      },
      builder: (ctx, candidateData, _) {
        final hovering = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: () => _pickRecipeForSlot(context, index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: hovering ? const Color(0xFFD5E8D4) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hovering
                    ? const Color(0xFF6B8F71)
                    : const Color(0xFFDDD8D0),
                width: hovering ? 2 : 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 36,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.emptySlot,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilledSlot(
    BuildContext context,
    int index,
    RecipeEntity recipe,
    GridProvider grid,
  ) {
    final rootDir = context.read<ConfigService>().rootDir!;

    Widget card = DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) {
        grid.swap(details.data, index);
        setState(() => _showRemoveZone = false);
      },
      builder: (ctx, candidateData, _) {
        final hovering = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RecipeViewScreen(recipe: recipe)),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: hovering
                  ? Border.all(color: const Color(0xFF6B8F71), width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _slotImage(rootDir, recipe),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return LongPressDraggable<int>(
      data: index,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 140,
          height: 140,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _slotImage(rootDir, recipe),
                Container(color: Colors.black.withValues(alpha: 0.3)),
                Center(
                  child: Text(
                    recipe.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8E4DE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDD8D0), width: 1.5),
        ),
      ),
      onDragStarted: () => setState(() => _showRemoveZone = true),
      onDragEnd: (_) => setState(() => _showRemoveZone = false),
      child: card,
    );
  }

  Widget _slotImage(String rootDir, RecipeEntity recipe) {
    if (recipe.imagePath != null && recipe.imagePath!.isNotEmpty) {
      final cleaned = recipe.imagePath!.startsWith('/')
          ? recipe.imagePath!.substring(1)
          : recipe.imagePath!;
      final file = File('$rootDir/$cleaned');
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return Container(
      color: const Color(0xFFD5CFC7),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 40,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Future<void> _pickRecipeForSlot(BuildContext context, int index) async {
    final gridProvider = context.read<GridProvider>();
    final recipe = await showModalBottomSheet<RecipeEntity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RecipePickerDialog(),
    );
    if (recipe != null && mounted) {
      gridProvider.assign(index, recipe);
    }
  }

  Future<void> _openWebDavSettings() async {
    final syncService = context.read<WebDavSyncService>();
    final config = await syncService.loadConfig();

    if (!mounted) return;

    final enabled = ValueNotifier<bool>(config.enabled);
    final urlCtrl = TextEditingController(text: config.baseUrl);
    final userCtrl = TextEditingController(text: config.username);
    final pwdCtrl = TextEditingController(text: config.password);
    final pathCtrl = TextEditingController(text: config.remotePath);

    final shouldSync = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('WebDAV Sync'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: enabled,
                builder: (ctx, isEnabled, _) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable sync'),
                  value: isEnabled,
                  onChanged: (v) => enabled.value = v,
                ),
              ),
              TextField(
                controller: urlCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Server URL'),
              ),
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: pwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password / App token',
                ),
              ),
              TextField(
                controller: pathCtrl,
                decoration: const InputDecoration(
                  labelText: 'Remote path (e.g. /smag)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              final newConfig = WebDavConfig(
                enabled: enabled.value,
                baseUrl: urlCtrl.text.trim(),
                username: userCtrl.text.trim(),
                password: pwdCtrl.text,
                remotePath: pathCtrl.text.trim(),
              );
              await syncService.saveConfig(newConfig);
              if (!ctx.mounted) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Save & Sync'),
          ),
        ],
      ),
    );

    enabled.dispose();
    urlCtrl.dispose();
    userCtrl.dispose();
    pwdCtrl.dispose();
    pathCtrl.dispose();

    if (shouldSync != true || !mounted) return;

    final rootDir = context.read<ConfigService>().rootDir;
    if (rootDir == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Sync started...')));
    try {
      final result = await syncService.syncLocalToRemote(rootDir);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Sync finished: ${result.uploadedFiles} files uploaded.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sync failed. Check your WebDAV settings.'),
        ),
      );
    }
  }
}
