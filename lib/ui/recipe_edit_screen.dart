import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../domain/recipe.dart';
import '../l10n/app_localizations.dart';
import '../services/recipe_duration.dart';
import '../state/recipe_provider.dart';
import 'recipe_edit_draft.dart';

/// Recipe creation / editing form.
///
/// Works with the Nextcloud Cookbook JSON schema fields.
class RecipeEditScreen extends StatefulWidget {
  final Recipe? recipe;

  const RecipeEditScreen({super.key, this.recipe});

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  final _imagePicker = ImagePicker();
  late final RecipeEditDraft _draft;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _yieldCtrl;
  late final TextEditingController _prepTimeCtrl;
  late final TextEditingController _cookTimeCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _keywordsCtrl;
  late final TextEditingController _ingredientsCtrl;
  late final TextEditingController _instructionsCtrl;

  @override
  void initState() {
    super.initState();
    _draft = RecipeEditDraft.fromRecipe(widget.recipe);
    _nameCtrl = TextEditingController(text: _draft.name);
    _categoryCtrl = TextEditingController(text: _draft.category);
    _yieldCtrl = TextEditingController(text: _draft.yieldText);
    _prepTimeCtrl = TextEditingController(text: _draft.prepTimeDisplay);
    _cookTimeCtrl = TextEditingController(text: _draft.cookTimeDisplay);
    _descriptionCtrl = TextEditingController(text: _draft.description);
    _imageCtrl = TextEditingController(text: _draft.image);
    _urlCtrl = TextEditingController(text: _draft.url);
    _keywordsCtrl = TextEditingController(text: _draft.keywords);
    _ingredientsCtrl = TextEditingController(text: _draft.ingredientsText);
    _instructionsCtrl = TextEditingController(text: _draft.instructionsText);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _yieldCtrl.dispose();
    _prepTimeCtrl.dispose();
    _cookTimeCtrl.dispose();
    _descriptionCtrl.dispose();
    _imageCtrl.dispose();
    _urlCtrl.dispose();
    _keywordsCtrl.dispose();
    _ingredientsCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isNew = widget.recipe == null || widget.recipe!.localId == null;
    final categories = context.read<RecipeProvider>().categories;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? l10n.newRecipe : l10n.editRecipe),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + safeBottom),
            children: [
              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: l10n.title),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.titleRequired : null,
              ),
              const SizedBox(height: 12),

              // Category with autocomplete
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) return categories;
                  return categories.where(
                    (c) => c.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
                  );
                },
                initialValue: TextEditingValue(text: _categoryCtrl.text),
                onSelected: (s) => _categoryCtrl.text = s,
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmitted) {
                      // Keep our controller in sync.
                      controller.addListener(
                        () => _categoryCtrl.text = controller.text,
                      );
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(labelText: l10n.category),
                        onChanged: (value) => _categoryCtrl.text = value,
                      );
                    },
              ),
              const SizedBox(height: 12),

              // Yield / Prep / Cook
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yieldCtrl,
                      decoration: InputDecoration(labelText: l10n.servings),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _prepTimeCtrl,
                      readOnly: true,
                      onTap: () => _pickDuration(_prepTimeCtrl),
                      decoration: InputDecoration(
                        labelText: l10n.prepTime,
                        suffixIcon: const Icon(Icons.schedule),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cookTimeCtrl,
                      readOnly: true,
                      onTap: () => _pickDuration(_cookTimeCtrl),
                      decoration: InputDecoration(
                        labelText: l10n.cookTime,
                        suffixIcon: const Icon(Icons.schedule),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Image picker / URL
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: l10n.imageUrl,
                        suffixIcon: const Icon(Icons.image_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    tooltip: l10n.selectImage,
                  ),
                ],
              ),
              if (_imageCtrl.text.isNotEmpty &&
                  !_imageCtrl.text.startsWith('http')) ...[
                const SizedBox(height: 8),
                _buildLocalImagePreview(),
              ],
              const SizedBox(height: 12),

              // Source URL
              TextFormField(
                controller: _urlCtrl,
                decoration: InputDecoration(labelText: l10n.sourceLabel),
              ),
              const SizedBox(height: 12),

              // Keywords
              TextFormField(
                controller: _keywordsCtrl,
                decoration: InputDecoration(labelText: l10n.keywords),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionCtrl,
                decoration: InputDecoration(labelText: l10n.description),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Ingredients (one per line)
              Text(
                l10n.ingredients,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _ingredientsCtrl,
                decoration: InputDecoration(
                  hintText: l10n.ingredientsHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 10,
                style: GoogleFonts.jetBrainsMono(fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Instructions (one per line)
              Text(
                l10n.instructions,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _instructionsCtrl,
                decoration: InputDecoration(
                  hintText: l10n.instructionsHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 10,
                style: GoogleFonts.jetBrainsMono(fontSize: 14),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalImagePreview() {
    final file = File(_imageCtrl.text);
    if (!file.existsSync()) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(file, height: 100, fit: BoxFit.cover),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() {
      _imageCtrl.text = picked.path;
    });
  }

  Future<void> _pickDuration(TextEditingController controller) async {
    final sourceIso = identical(controller, _prepTimeCtrl)
        ? _draft.prepTimeIso
        : _draft.cookTimeIso;
    final initial =
        RecipeDuration.toTimeOfDay(sourceIso) ??
        const TimeOfDay(hour: 0, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (identical(controller, _prepTimeCtrl)) {
        _draft.setPrepTime(picked);
        controller.text = _draft.prepTimeDisplay;
      } else {
        _draft.setCookTime(picked);
        controller.text = _draft.cookTimeDisplay;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    _draft
      ..name = _nameCtrl.text
      ..category = _categoryCtrl.text
      ..yieldText = _yieldCtrl.text
      ..description = _descriptionCtrl.text
      ..image = _imageCtrl.text
      ..url = _urlCtrl.text
      ..keywords = _keywordsCtrl.text
      ..ingredientsText = _ingredientsCtrl.text
      ..instructionsText = _instructionsCtrl.text;

    final recipe = _draft.toRecipe(widget.recipe ?? const Recipe());

    try {
      final saved = await context.read<RecipeProvider>().saveRecipe(recipe);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
