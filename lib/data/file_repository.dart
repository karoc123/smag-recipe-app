import 'dart:io';
import 'package:path/path.dart' as p;

import '../domain/recipe_entity.dart';
import '../services/recipe_parser.dart';

/// Handles all file-system operations: directory scanning, recipe CRUD,
/// and folder-based category management.
class FileRepository {
  final RecipeParser _parser;

  FileRepository(this._parser);

  // ──────────────────────────── Scanning ─────────────────────────────

  /// Recursively scans [rootDir] for `.md` files (skipping config.toml and
  /// the images/ folder) and returns parsed [RecipeEntity] instances.
  Future<List<RecipeEntity>> loadAll(String rootDir) async {
    final root = Directory(rootDir);
    if (!await root.exists()) return [];

    final recipes = <RecipeEntity>[];
    await for (final entity in root.list(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.md')) continue;
      // Skip files inside the images folder
      final rel = p.relative(entity.path, from: rootDir);
      if (rel.startsWith('images${p.separator}')) continue;

      final content = await entity.readAsString();
      recipes.add(_parser.parseMarkdown(content, relativePath: rel));
    }
    return recipes;
  }

  /// Returns all category folder names in [rootDir].
  Future<List<String>> listCategories(String rootDir) async {
    final root = Directory(rootDir);
    if (!await root.exists()) return [];

    final categories = <String>[];
    await for (final entity in root.list()) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (name == 'images' || name.startsWith('.')) continue;
      categories.add(name);
    }
    categories.sort();
    return categories;
  }

  // ──────────────────────────── CRUD ────────────────────────────────

  /// Writes (creates or overwrites) a recipe to the file system.
  /// Returns the relative path of the written file.
  Future<String> saveRecipe(String rootDir, RecipeEntity recipe) async {
    final category = recipe.category.isNotEmpty
        ? recipe.category
        : 'Uncategorized';
    final dir = Directory(p.join(rootDir, category));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final filename = '${recipe.slug}.md';
    final relPath = p.join(category, filename);
    final file = File(p.join(rootDir, relPath));

    final content = _parser.toMarkdown(recipe);
    await file.writeAsString(content);

    return relPath;
  }

  /// Deletes a recipe file from disk.
  Future<void> deleteRecipe(String rootDir, String relativePath) async {
    final file = File(p.join(rootDir, relativePath));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Checks whether a file with this recipe's slug already exists.
  Future<bool> exists(String rootDir, RecipeEntity recipe) async {
    final category = recipe.category.isNotEmpty
        ? recipe.category
        : 'Uncategorized';
    final filename = '${recipe.slug}.md';
    final file = File(p.join(rootDir, category, filename));
    return file.exists();
  }

  /// Reads a single recipe file from a relative path.
  Future<RecipeEntity?> readRecipe(String rootDir, String relativePath) async {
    final file = File(p.join(rootDir, relativePath));
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    return _parser.parseMarkdown(content, relativePath: relativePath);
  }

  /// Moves a recipe to a new category folder when the category is changed.
  /// Returns the new relative path.
  Future<String> moveRecipe(
    String rootDir,
    String oldRelativePath,
    RecipeEntity updatedRecipe,
  ) async {
    // Delete old file
    await deleteRecipe(rootDir, oldRelativePath);
    // Write to new location
    return saveRecipe(rootDir, updatedRecipe);
  }

  /// Resolves an absolute image path from a relative one.
  String resolveImagePath(String rootDir, String relativeImage) {
    // Image paths in recipes start with /images/
    final cleaned = relativeImage.startsWith('/')
        ? relativeImage.substring(1)
        : relativeImage;
    return p.join(rootDir, cleaned);
  }

  /// Save an image file to the images/ directory. Returns the relative path.
  Future<String> saveImage(String rootDir, File sourceFile) async {
    final imagesDir = Directory(p.join(rootDir, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final filename = p.basename(sourceFile.path);
    final dest = File(p.join(imagesDir.path, filename));
    await sourceFile.copy(dest.path);
    return '/images/$filename';
  }
}
