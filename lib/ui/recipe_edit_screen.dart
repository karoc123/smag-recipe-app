import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smag/l10n/app_localizations.dart';

import '../domain/recipe_entity.dart';
import '../state/recipe_provider.dart';
import 'overwrite_dialog.dart';

class RecipeEditScreen extends StatefulWidget {
  final RecipeEntity? recipe;
  const RecipeEditScreen({super.key, this.recipe});

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _servingsCtrl;
  late TextEditingController _prepTimeCtrl;
  late TextEditingController _cookTimeCtrl;
  late TextEditingController _bodyCtrl;
  String? _imagePath;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _categoryCtrl = TextEditingController(text: r?.category ?? '');
    _servingsCtrl = TextEditingController(text: r?.servings ?? '');
    _prepTimeCtrl = TextEditingController(text: r?.prepTime ?? '');
    _cookTimeCtrl = TextEditingController(text: r?.cookTime ?? '');
    _bodyCtrl = TextEditingController(text: r?.body ?? '');
    _imagePath = r?.imagePath;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _servingsCtrl.dispose();
    _prepTimeCtrl.dispose();
    _cookTimeCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isNew = widget.recipe == null;
    final categories = context.read<RecipeProvider>().categories;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F2ED),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF2D3436),
        title: Text(
          isNew ? l10n.newRecipe : l10n.editRecipe,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6B8F71),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text(
                    l10n.save,
                    style: const TextStyle(
                      color: Color(0xFF6B8F71),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
          children: [
            _field(l10n.title, _titleCtrl, required: true),
            const SizedBox(height: 16),
            // Category with autocomplete
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _categoryCtrl.text),
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return categories;
                return categories.where(
                  (c) => c.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              onSelected: (val) => _categoryCtrl.text = val,
              fieldViewBuilder: (ctx, controller, focusNode, onSubmit) {
                // Sync with our controller
                controller.addListener(
                  () => _categoryCtrl.text = controller.text,
                );
                return _fieldFromController(
                  l10n.category,
                  controller,
                  focusNode: focusNode,
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _field(l10n.servings, _servingsCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _field(l10n.prepTime, _prepTimeCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _field(l10n.cookTime, _cookTimeCtrl)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      _imagePath == null || _imagePath!.isEmpty
                          ? 'Add image'
                          : 'Change image',
                    ),
                  ),
                ),
                if (_imagePath != null && _imagePath!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() => _imagePath = null),
                    tooltip: 'Remove image',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ],
            ),
            if (_imagePath != null && _imagePath!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _imagePath!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF636E72),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              '${l10n.ingredients} & ${l10n.instructions}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF636E72),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyCtrl,
              maxLines: null,
              minLines: 12,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                color: const Color(0xFF2D3436),
              ),
              decoration: InputDecoration(
                hintText: '## Ingredients\n- ...\n\n## Instructions\n1. ...',
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
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: required ? (v) => (v == null || v.isEmpty) ? '' : null : null,
      style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF2D3436)),
      decoration: _inputDecoration(label),
    );
  }

  Widget _fieldFromController(
    String label,
    TextEditingController ctrl, {
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: ctrl,
      focusNode: focusNode,
      style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF2D3436)),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: const Color(0xFF636E72)),
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
        borderSide: const BorderSide(color: Color(0xFF6B8F71), width: 2),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final provider = context.read<RecipeProvider>();
      final recipe = RecipeEntity(
        title: _titleCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        servings: _servingsCtrl.text.trim().isNotEmpty
            ? _servingsCtrl.text.trim()
            : null,
        prepTime: _prepTimeCtrl.text.trim().isNotEmpty
            ? _prepTimeCtrl.text.trim()
            : null,
        cookTime: _cookTimeCtrl.text.trim().isNotEmpty
            ? _cookTimeCtrl.text.trim()
            : null,
        body: _bodyCtrl.text,
        imagePath: _imagePath,
        date: widget.recipe?.date ?? DateTime.now(),
        relativePath: widget.recipe?.relativePath,
      );

      // Check for overwrites on new recipes
      if (widget.recipe == null) {
        final willOverwrite = await provider.wouldOverwrite(recipe);
        if (willOverwrite && mounted) {
          final proceed = await OverwriteDialog.show(context, recipe.title);
          if (proceed != true) {
            return;
          }
        }
      }

      final saved = await provider.saveRecipe(
        recipe,
        oldRelativePath: widget.recipe?.relativePath,
      );

      if (mounted) Navigator.pop(context, saved);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save recipe. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: false,
    );
    final pickedPath = result?.files.single.path;
    if (pickedPath == null || !mounted) return;

    final source = File(pickedPath);
    if (!await source.exists()) return;
    if (!mounted) return;

    try {
      final provider = context.read<RecipeProvider>();
      final savedPath = await provider.saveImage(source);
      if (!mounted) return;
      setState(() => _imagePath = savedPath);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not add image.')));
    }
  }
}
