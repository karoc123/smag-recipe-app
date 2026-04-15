import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smag/l10n/app_localizations.dart';

import '../domain/recipe_entity.dart';
import '../state/recipe_provider.dart';
import 'recipe_edit_screen.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _urlCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _urlCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F2ED),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF2D3436),
        title: Text(
          l10n.importRecipe,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFF6B8F71),
          unselectedLabelColor: const Color(0xFF636E72),
          indicatorColor: const Color(0xFF6B8F71),
          tabs: [
            Tab(text: l10n.importFromUrl),
            Tab(text: l10n.importFromText),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [_urlTab(context, l10n), _textTab(context, l10n)],
      ),
    );
  }

  Widget _urlTab(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _urlCtrl,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: l10n.urlHint,
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(
                Icons.link_rounded,
                color: Color(0xFF636E72),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDDD8D0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDDD8D0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6B8F71),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _importUrl,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6B8F71),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.importRecipe),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }

  Widget _textTab(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextField(
              controller: _textCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: GoogleFonts.jetBrainsMono(fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n.textHint,
                hintStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDDD8D0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDDD8D0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6B8F71),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _copyJsonPrompt,
            icon: const Icon(Icons.content_copy_rounded),
            label: const Text('Copy Prompt'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _importText,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6B8F71),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.importRecipe),
          ),
        ],
      ),
    );
  }

  Future<void> _importUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;

    // Basic URL validation
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasScheme ||
        (!uri.isScheme('http') && !uri.isScheme('https'))) {
      setState(() => _error = 'Please enter a valid URL (http or https).');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final provider = context.read<RecipeProvider>();
      final result = await provider.importFromUrlWithCandidates(url);
      var recipe = result.recipe;

      if (mounted && result.imageCandidates.isNotEmpty) {
        final chosen = await _pickImportedImage(result.imageCandidates);
        if (!mounted) return;
        if (chosen != null) {
          recipe = recipe.copyWith(imagePath: chosen);
        }
      }

      if (mounted) _openEditor(recipe);
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context)!.importError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _importText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<RecipeProvider>();
    final recipe = provider.importFromText(text);
    _openEditor(recipe);
  }

  Future<String?> _pickImportedImage(List<String> candidates) async {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        return SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 120),
            padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
            child: SizedBox(
              height: media.size.height * 0.72,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Bild auswählen',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Optional: Wähle ein Bild aus den erkannten Bildern.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF636E72),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: candidates.length,
                      itemBuilder: (ctx, i) {
                        final url = candidates[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () => Navigator.pop(ctx, url),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: 160,
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                              ),
                                            ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF636E72),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text('Überspringen'),
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
  }

  Future<void> _copyJsonPrompt() async {
    const prompt = '''
You are extracting a recipe from a web page or plain text.

Return ONLY valid JSON (no markdown code fences, no commentary) in this exact schema:
{
  "title": "string, required",
  "category": "string, optional",
  "servings": "string, optional",
  "prep_time": "string, optional",
  "cook_time": "string, optional",
  "image": "string URL or /images/local-file.jpg, optional",
  "ingredients": ["string", "..."],
  "instructions": ["string", "..."],
  "notes": "string, optional",
  "source_url": "string URL, optional"
}

Rules:
1) Keep language exactly as in source (German stays German).
2) Keep ingredient quantities and units unchanged.
3) Keep steps concise, one action per list item.
4) If a field is unknown, use empty string or empty list.
5) Do not invent information.
''';

    await Clipboard.setData(const ClipboardData(text: prompt));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prompt copied to clipboard.')),
    );
  }

  void _openEditor(RecipeEntity recipe) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => RecipeEditScreen(recipe: recipe)),
    );
  }
}
