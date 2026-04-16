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

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  static const intentChannel = MethodChannel('de.karoc.smag/intent');
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
        // Navigate to import screen with URL pre-filled
        _navigateToImportWithUrl(url);
      }
    } on PlatformException catch (_) {
      // Intent handling not available or failed
    }
  }

  void _navigateToImportWithUrl(String url) {
    _navigateTo(context, ImportScreen(initialUrl: url));
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
    final result = await Navigator.of(
      context,
    ).push<Recipe>(MaterialPageRoute(builder: (_) => const RecipeEditScreen()));
    if (result != null && mounted) {
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
