import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../domain/recipe.dart';
import '../l10n/app_localizations.dart';
import '../services/recipe_import_service.dart';
import '../services/sync_service.dart';
import '../state/recipe_provider.dart';
import '../state/settings_provider.dart';
import 'error_dialog.dart';
import 'recipe_edit_screen.dart';

/// Unified import screen with two tabs: URL import and text/JSON paste.
///
/// After parsing, the user chooses "Import Locally" or "Send to Nextcloud".
/// When sending to Nextcloud, a sync is triggered immediately after.
class ImportScreen extends StatelessWidget {
  final String? initialUrl;

  const ImportScreen({super.key, this.initialUrl});

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
          body: TabBarView(
            children: [
              _UrlImportTab(initialUrl: initialUrl),
              const _TextImportTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── URL Import Tab ──────────────────────────

class _UrlImportTab extends StatefulWidget {
  final String? initialUrl;

  const _UrlImportTab({this.initialUrl});

  @override
  State<_UrlImportTab> createState() => _UrlImportTabState();
}

class _UrlImportTabState extends State<_UrlImportTab> {
  final _urlCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _urlCtrl.text = widget.initialUrl!;
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insets = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + insets + safeBottom),
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

    final choice = await _chooseUrlImportTarget(url);
    if (choice == null || !mounted) return;

    if (choice == _ImportChoice.nextcloud) {
      await _sendToNextcloud(context, const Recipe(), sourceUrl: url);
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await context.read<RecipeImportService>().importFromUrl(
        url,
      );

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
      await _openLocalImportEditor(context, recipe);
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          title: AppLocalizations.of(context)!.errorTitle,
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<_ImportChoice?> _chooseUrlImportTarget(String url) async {
    final l10n = AppLocalizations.of(context)!;
    final isLinked = context.read<SettingsProvider>().isLinked;

    return showDialog<_ImportChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importTitle),
        content: Text(url),
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
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => Navigator.pop(ctx, candidates[i]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        candidates[i],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
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
    final insets = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + insets + safeBottom),
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

    final recipe = context.read<RecipeImportService>().importFromText(text);
    _openImportChoiceDialog(context, recipe);
  }
}

// ─────────────────── Import choice dialog ────────────────────────

/// Shows a dialog letting the user choose "Import Locally" or "Send to Nextcloud".
Future<void> _openImportChoiceDialog(
  BuildContext context,
  Recipe recipe, {
  String? sourceUrl,
}) async {
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
    await _sendToNextcloud(context, recipe, sourceUrl: sourceUrl);
  } else {
    await _openLocalImportEditor(context, recipe);
  }
}

Future<void> _openLocalImportEditor(BuildContext context, Recipe recipe) async {
  final saved = await Navigator.of(context).push<Recipe>(
    MaterialPageRoute(builder: (_) => RecipeEditScreen(recipe: recipe)),
  );
  if (saved != null && context.mounted) {
    await context.read<RecipeProvider>().loadRecipes();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

Future<void> _sendToNextcloud(
  BuildContext context,
  Recipe recipe, {
  String? sourceUrl,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final syncService = context.read<SyncService>();
  final settings = context.read<SettingsProvider>();
  final recipeProvider = context.read<RecipeProvider>();

  // Show a loading dialog that blocks interaction until the import finishes.
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Expanded(child: Text(l10n.sendToNextcloud)),
          ],
        ),
      ),
    ),
  );

  try {
    settings.setSyncing(true);
    if (sourceUrl != null && sourceUrl.isNotEmpty) {
      await syncService.importFromUrl(sourceUrl);
    } else {
      await syncService.pushRecipe(recipe);
    }
    await syncService.sync();
    await recipeProvider.loadRecipes();

    if (context.mounted) {
      // Dismiss the loading dialog.
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sentToNextcloud)));
      Navigator.of(context).pop(); // Back to main.
    }
  } catch (e) {
    if (context.mounted) {
      // Dismiss the loading dialog.
      Navigator.of(context).pop();
      showErrorDialog(context, title: l10n.syncErrorTitle, error: e);
    }
  } finally {
    settings.setSyncing(false);
  }
}

enum _ImportChoice { local, nextcloud }
