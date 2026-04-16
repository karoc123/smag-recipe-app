import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../domain/recipe.dart';
import '../l10n/app_localizations.dart';
import '../services/sync_service.dart';
import '../state/recipe_provider.dart';
import '../state/settings_provider.dart';
import 'recipe_edit_screen.dart';

/// Unified import screen with two tabs: URL import and text/JSON paste.
///
/// After parsing, the user chooses "Import Locally" or "Send to Nextcloud".
/// When sending to Nextcloud, a sync is triggered immediately after.
class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: true,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.importTitle),
            bottom: TabBar(
              tabs: [
                Tab(text: l10n.importFromUrl),
                Tab(text: l10n.importFromText),
              ],
            ),
          ),
          body: const TabBarView(children: [_UrlImportTab(), _TextImportTab()]),
        ),
      ),
    );
  }
}

// ─────────────────────── URL Import Tab ──────────────────────────

class _UrlImportTab extends StatefulWidget {
  const _UrlImportTab();

  @override
  State<_UrlImportTab> createState() => _UrlImportTabState();
}

class _UrlImportTabState extends State<_UrlImportTab> {
  final _urlCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlCtrl,
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com/recipe',
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _importUrl,
              icon: const Icon(Icons.download),
              label: Text(l10n.importButton),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _showError('URL must start with http:// or https://');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await context.read<RecipeProvider>().importFromUrl(url);

      if (!mounted) return;

      // Show image picker if candidates exist.
      String? selectedImage;
      if (result.imageCandidates.isNotEmpty) {
        selectedImage = await _pickImage(result.imageCandidates);
      }

      final recipe = selectedImage != null
          ? result.recipe.copyWith(image: selectedImage)
          : result.recipe;

      if (!mounted) return;
      _showImportChoice(recipe);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _pickImage(List<String> candidates) async {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectImage,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => Navigator.pop(ctx, candidates[i]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        candidates[i],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: Text(l10n.skip),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportChoice(Recipe recipe) {
    _openImportChoiceDialog(context, recipe);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ─────────────────────── Text Import Tab ─────────────────────────

class _TextImportTab extends StatefulWidget {
  const _TextImportTab();

  @override
  State<_TextImportTab> createState() => _TextImportTabState();
}

class _TextImportTabState extends State<_TextImportTab> {
  final _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _copyPrompt,
              icon: const Icon(Icons.copy),
              label: Text(l10n.copyPrompt),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _textCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: l10n.pasteRecipeHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _importText,
              icon: const Icon(Icons.download),
              label: Text(l10n.importButton),
            ),
          ],
        ),
      ),
    );
  }

  void _copyPrompt() {
    const prompt = '''Convert recipe to this JSON format:
{
  "name": "Recipe Title",
  "description": "Short description",
  "recipeCategory": "Category",
  "recipeYield": "4 servings",
  "prepTime": "PT15M",
  "cookTime": "PT30M",
  "keywords": "keyword1, keyword2",
  "recipeIngredient": ["200g flour", "100g sugar"],
  "recipeInstructions": ["Preheat oven to 180°C.", "Mix ingredients."],
  "url": ""
}''';
    Clipboard.setData(const ClipboardData(text: prompt));
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.promptCopied)));
  }

  void _importText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final recipe = context.read<RecipeProvider>().importFromText(text);
    _openImportChoiceDialog(context, recipe);
  }
}

// ─────────────────── Import choice dialog ────────────────────────

/// Shows a dialog letting the user choose "Import Locally" or "Send to Nextcloud".
Future<void> _openImportChoiceDialog(
  BuildContext context,
  Recipe recipe,
) async {
  final l10n = AppLocalizations.of(context)!;
  final settings = context.read<SettingsProvider>();
  final isLinked = settings.isLinked;

  final choice = await showDialog<_ImportChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.importTitle),
      content: Text(
        recipe.name.isNotEmpty ? '"${recipe.name}"' : l10n.importedRecipe,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, _ImportChoice.local),
          child: Text(l10n.importLocally),
        ),
        if (isLinked)
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _ImportChoice.nextcloud),
            child: Text(l10n.sendToNextcloud),
          ),
      ],
    ),
  );

  if (choice == null || !context.mounted) return;

  if (choice == _ImportChoice.nextcloud) {
    await _sendToNextcloud(context, recipe);
  } else {
    // Open editor for local import.
    final saved = await Navigator.of(context).push<Recipe>(
      MaterialPageRoute(builder: (_) => RecipeEditScreen(recipe: recipe)),
    );
    if (saved != null && context.mounted) {
      context.read<RecipeProvider>().loadRecipes();
      Navigator.of(context).pop(); // Back to main.
    }
  }
}

Future<void> _sendToNextcloud(BuildContext context, Recipe recipe) async {
  final l10n = AppLocalizations.of(context)!;
  final syncService = context.read<SyncService>();
  final settings = context.read<SettingsProvider>();
  final recipeProvider = context.read<RecipeProvider>();

  try {
    settings.setSyncing(true);
    // Push to server.
    await syncService.pushRecipe(recipe);
    // Sync to pull it back locally.
    await syncService.sync();
    await recipeProvider.loadRecipes();

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sentToNextcloud)));
      Navigator.of(context).pop(); // Back to main.
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  } finally {
    settings.setSyncing(false);
  }
}

enum _ImportChoice { local, nextcloud }
