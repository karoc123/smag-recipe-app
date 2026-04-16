import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/recipe_provider.dart';
import 'grid_screen.dart';
import 'import_screen.dart';
import 'recipe_list_screen.dart';
import 'settings_screen.dart';

/// Root navigation shell with three primary actions:
///   1. View Toggle (List ↔ Grid)
///   2. Import
///   3. Settings
///
/// Back-button from Grid, Settings, or Import always returns here.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const intentChannel = MethodChannel('de.karoc.smag/intent');
  bool _showGrid = false;

  @override
  void initState() {
    super.initState();
    _checkIntentUrl();
  }

  /// Check if the app was launched with a URL intent (e.g., "Share with" URL).
  Future<void> _checkIntentUrl() async {
    try {
      final url = await intentChannel.invokeMethod<String?>('getInitialUrl');
      if (url != null && url.isNotEmpty && mounted) {
        // Navigate to import screen with URL pre-filled
        _navigateToImportWithUrl(url);
      }
    } on PlatformException catch (_) {
      // Intent handling not available or failed
    }
  }

  void _navigateToImportWithUrl(String url) {
    // For now, just navigate to import screen
    // TODO: In a future version, pre-fill the URL in the import screen
    _navigateTo(context, const ImportScreen());
  }

  @override
  Widget build(BuildContext context) {
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
        body: _showGrid ? const GridScreen() : const RecipeListScreen(),
        bottomNavigationBar: _BottomBar(
          showGrid: _showGrid,
          onToggleView: () => setState(() => _showGrid = !_showGrid),
          onImport: () => _navigateTo(context, const ImportScreen()),
          onSettings: () => _navigateTo(context, const SettingsScreen()),
        ),
        floatingActionButton: _showGrid
            ? null
            : FloatingActionButton(
                onPressed: () => _createRecipe(context),
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _createRecipe(BuildContext context) async {
    // Push to recipe edit screen for new recipe.
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _NewRecipeRedirect()));
    if (result == true && mounted) {
      context.read<RecipeProvider>().loadRecipes();
    }
  }
}

/// Bottom bar with the three primary navigation buttons.
class _BottomBar extends StatelessWidget {
  final bool showGrid;
  final VoidCallback onToggleView;
  final VoidCallback onImport;
  final VoidCallback onSettings;

  const _BottomBar({
    required this.showGrid,
    required this.onToggleView,
    required this.onImport,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (i) {
        switch (i) {
          case 0:
            onToggleView();
          case 1:
            onImport();
          case 2:
            onSettings();
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(showGrid ? Icons.list : Icons.grid_view),
          label: showGrid ? l10n.recipes : l10n.grid,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.download),
          label: l10n.importTitle,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings),
          label: l10n.settings,
        ),
      ],
    );
  }
}

/// Tiny redirect widget that pushes to the recipe edit screen.
class _NewRecipeRedirect extends StatelessWidget {
  const _NewRecipeRedirect();

  @override
  Widget build(BuildContext context) {
    // Redirect immediately — import the edit screen lazily.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) {
            // Lazy import to avoid circular dependency.
            return const _NewRecipePlaceholder();
          },
        ),
      );
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Placeholder that will be replaced by RecipeEditScreen in the actual import.
class _NewRecipePlaceholder extends StatelessWidget {
  const _NewRecipePlaceholder();

  @override
  Widget build(BuildContext context) {
    // Immediately redirect to the real edit screen.
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
