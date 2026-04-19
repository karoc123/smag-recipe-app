import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../domain/recipe.dart';
import '../l10n/app_localizations.dart';
import '../state/recipe_provider.dart';
import 'grid_screen.dart';
import 'import_screen.dart';
import 'recipe_edit_screen.dart';
import 'recipe_list_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// Root navigation shell with top-bar search/settings and floating actions.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  static const intentChannel = MethodChannel('de.karoc.smagrecipe/intent');
  bool _showGrid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkIntentUrl();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkIntentUrl();
    }
  }

  /// Check if the app was launched with a URL intent (e.g., "Share with" URL).
  Future<void> _checkIntentUrl() async {
    try {
      final url = await intentChannel.invokeMethod<String?>('getInitialUrl');
      if (url != null && url.isNotEmpty && mounted) {
        await _openImport(initialUrl: url);
      }
    } on PlatformException catch (_) {
      // Intent handling not available or failed
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      // Prevent accidental app exit; let the child handle it.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_showGrid) {
          setState(() => _showGrid = false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: l10n.search,
              onPressed: () => _navigateTo(context, const SearchScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: l10n.settings,
              onPressed: _openSettings,
            ),
          ],
        ),
        body: _showGrid ? const GridScreen() : const RecipeListScreen(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_showGrid) ...[
              FloatingActionButton(
                heroTag: 'fab_add_recipe',
                tooltip: l10n.newRecipe,
                onPressed: _openCreateOrImportChoice,
                child: const Icon(Icons.add),
              ),
              const SizedBox(width: 12),
            ],
            FloatingActionButton(
              heroTag: 'fab_toggle_grid',
              tooltip: _showGrid ? l10n.recipes : l10n.grid,
              onPressed: () => setState(() => _showGrid = !_showGrid),
              child: Icon(_showGrid ? Icons.list : Icons.grid_view),
            ),
          ],
        ),
      ),
    );
  }

  Future<T?> _navigateTo<T>(BuildContext context, Widget screen) {
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openCreateOrImportChoice() async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<_AddAction>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: Text(l10n.newRecipe),
              onTap: () => Navigator.pop(ctx, _AddAction.newRecipe),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: Text(l10n.importTitle),
              onTap: () => Navigator.pop(ctx, _AddAction.importRecipe),
            ),
          ],
        ),
      ),
    );

    if (!mounted || choice == null) return;
    switch (choice) {
      case _AddAction.newRecipe:
        await _createRecipe();
        break;
      case _AddAction.importRecipe:
        await _openImport();
        break;
    }
  }

  Future<void> _openImport({String? initialUrl}) async {
    _ensureRecipeView();
    await _navigateTo(context, ImportScreen(initialUrl: initialUrl));
  }

  Future<void> _openSettings() async {
    _ensureRecipeView();
    await _navigateTo(context, const SettingsScreen());
  }

  void _ensureRecipeView() {
    if (_showGrid) {
      setState(() => _showGrid = false);
    }
  }

  Future<void> _createRecipe() async {
    _ensureRecipeView();
    final result = await Navigator.of(
      context,
    ).push<Recipe>(MaterialPageRoute(builder: (_) => const RecipeEditScreen()));
    if (result != null && mounted) {
      await context.read<RecipeProvider>().loadRecipes();
    }
  }
}

enum _AddAction { newRecipe, importRecipe }
