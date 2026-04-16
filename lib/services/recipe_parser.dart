import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

import '../domain/recipe.dart';

/// Result of a URL import: the parsed recipe plus image candidate URLs.
class ParsedUrlImport {
  final Recipe recipe;
  final List<String> imageCandidates;

  const ParsedUrlImport({required this.recipe, required this.imageCandidates});
}

/// Standalone, modular service that converts HTML / plain text into [Recipe]
/// instances aligned with the Nextcloud Cookbook JSON schema.
///
/// Deliberately has **no** dependency on file I/O so it can be tested and
/// swapped independently.
class RecipeParser {
  // ──────────────────── HTML → Recipe (URL importer) ─────────────────

  /// Best-effort extraction of structured recipe data from raw HTML.
  Recipe parseHtml(String htmlString, {String? sourceUrl}) {
    return parseHtmlWithCandidates(htmlString, sourceUrl: sourceUrl).recipe;
  }

  ParsedUrlImport parseHtmlWithCandidates(
    String htmlString, {
    String? sourceUrl,
  }) {
    final doc = html_parser.parse(htmlString);

    final title = _extractImportTitle(doc, sourceUrl);

    // Try JSON-LD structured data first – this gives us the full schema.org
    // recipe in one shot.
    Recipe? jsonLdRecipe;
    for (final script
        in doc.querySelectorAll('script[type="application/ld+json"]')) {
      final text = script.text;
      if (text.contains('recipeIngredient') || text.contains('Recipe')) {
        jsonLdRecipe = _parseJsonLdRecipe(text);
        if (jsonLdRecipe != null) break;
      }
    }

    final imageCandidates = _extractImageCandidates(doc, sourceUrl);

    if (jsonLdRecipe != null) {
      return ParsedUrlImport(
        recipe: jsonLdRecipe.copyWith(
          name: jsonLdRecipe.name.isEmpty ? title : null,
          image: jsonLdRecipe.image.isEmpty && imageCandidates.isNotEmpty
              ? imageCandidates.first
              : null,
          url: sourceUrl ?? '',
        ),
        imageCandidates: imageCandidates,
      );
    }

    // Fallback: heuristic scraping
    List<String> ingredients = [];
    List<String> instructions = [];

    // Microdata / CSS class selectors
    final ingredientEls = doc.querySelectorAll(
      'li[itemprop="recipeIngredient"], .recipe-ingredient li, .ingredients li',
    );
    if (ingredientEls.isNotEmpty) {
      ingredients = ingredientEls.map((e) => e.text.trim()).toList();
    }
    if (ingredients.isEmpty) {
      ingredients = _extractSectionItems(doc, const [
        'zutaten',
        'ingredients',
      ]);
    }

    final instructionEls = doc.querySelectorAll(
      '[itemprop="recipeInstructions"] li, .recipe-instructions li, '
      '.instructions li, .directions li',
    );
    if (instructionEls.isNotEmpty) {
      instructions = instructionEls.map((e) => e.text.trim()).toList();
    }
    if (instructions.isEmpty) {
      instructions = _extractSectionItems(doc, const [
        'zubereitung',
        'anleitung',
        'instructions',
        'directions',
      ]);
    }

    final image = imageCandidates.isNotEmpty ? imageCandidates.first : '';

    return ParsedUrlImport(
      recipe: Recipe(
        name: title,
        url: sourceUrl ?? '',
        image: image,
        recipeIngredient: ingredients,
        recipeInstructions: instructions,
      ),
      imageCandidates: imageCandidates,
    );
  }

  // ──────────────────── Plain text / JSON → Recipe ───────────────────

  /// Parse plain text that a user pastes (best-effort).
  /// If text starts with `{`, attempt JSON first.
  Recipe parsePlainText(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('{')) {
      final parsed = _parseJsonRecipe(trimmed);
      if (parsed != null) return parsed;
    }

    // Heuristic: treat first line as title, rest as ingredients/instructions.
    final lines = text.split('\n');
    final title = lines.isNotEmpty
        ? lines.first.replaceAll(RegExp(r'^#+\s*'), '').trim()
        : 'Untitled';

    final bodyLines = lines.length > 1 ? lines.sublist(1) : <String>[];
    final ingredients = <String>[];
    final instructions = <String>[];

    bool inIngredients = false;
    bool inInstructions = false;

    for (final line in bodyLines) {
      final lower = line.trim().toLowerCase();
      if (lower.startsWith('## ingredient') || lower.startsWith('## zutaten')) {
        inIngredients = true;
        inInstructions = false;
        continue;
      }
      if (lower.startsWith('## instruction') ||
          lower.startsWith('## zubereitung') ||
          lower.startsWith('## direction') ||
          lower.startsWith('## anleitung')) {
        inInstructions = true;
        inIngredients = false;
        continue;
      }
      if (line.trim().startsWith('## ')) {
        inIngredients = false;
        inInstructions = false;
        continue;
      }
      final cleaned = line.replaceAll(RegExp(r'^[\s\-*\d.]+'), '').trim();
      if (cleaned.isEmpty) continue;

      if (inIngredients) {
        ingredients.add(cleaned);
      } else if (inInstructions) {
        instructions.add(cleaned);
      }
    }

    return Recipe(
      name: title,
      recipeIngredient: ingredients,
      recipeInstructions: instructions,
    );
  }

  // ──────────────────── Private: JSON-LD parsing ─────────────────────

  Recipe? _parseJsonLdRecipe(String raw) {
    try {
      dynamic decoded = jsonDecode(raw);
      // JSON-LD can be a single object or an array.
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final type = item['@type'];
            if (type == 'Recipe' ||
                (type is List && type.contains('Recipe'))) {
              return Recipe.fromJson(item);
            }
          }
        }
        if (decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
          return Recipe.fromJson(decoded.first as Map<String, dynamic>);
        }
        return null;
      }
      if (decoded is Map<String, dynamic>) {
        // Could be nested inside @graph
        if (decoded.containsKey('@graph')) {
          final graph = decoded['@graph'];
          if (graph is List) {
            for (final item in graph) {
              if (item is Map<String, dynamic>) {
                final type = item['@type'];
                if (type == 'Recipe' ||
                    (type is List && type.contains('Recipe'))) {
                  return Recipe.fromJson(item);
                }
              }
            }
          }
        }
        return Recipe.fromJson(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ──────────────────── Private: JSON paste parsing ──────────────────

  Recipe? _parseJsonRecipe(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      // Support both our own import schema and Nextcloud schema.
      final name = (decoded['title'] ?? decoded['name'] ?? '').toString().trim();
      if (name.isEmpty) return null;

      final category =
          (decoded['category'] ?? decoded['recipeCategory'] ?? '')
              .toString()
              .trim();
      final recipeYield =
          (decoded['servings'] ?? decoded['recipeYield'] ?? '')
              .toString()
              .trim();
      final prepTime =
          (decoded['prep_time'] ?? decoded['prepTime'] ?? '')
              .toString()
              .trim();
      final cookTime =
          (decoded['cook_time'] ?? decoded['cookTime'] ?? '')
              .toString()
              .trim();
      final image = (decoded['image'] ?? '').toString().trim();
      final url =
          (decoded['source_url'] ?? decoded['url'] ?? '').toString().trim();
      final description = (decoded['description'] ?? '').toString().trim();

      List<String> ingredients = _toStringList(
          decoded['ingredients'] ?? decoded['recipeIngredient']);
      List<String> instructions = _toStringList(
          decoded['instructions'] ?? decoded['recipeInstructions']);
      List<String> tools =
          _toStringList(decoded['tools'] ?? decoded['tool']);
      final keywords = (decoded['keywords'] ?? '').toString().trim();

      return Recipe(
        name: name,
        description: description,
        recipeCategory: category,
        recipeYield: recipeYield,
        prepTime: prepTime,
        cookTime: cookTime,
        image: image,
        url: url,
        keywords: keywords,
        tool: tools,
        recipeIngredient: ingredients,
        recipeInstructions: instructions,
      );
    } catch (_) {
      return null;
    }
  }

  // ──────────────────── Private: HTML helpers ────────────────────────

  String _extractImportTitle(Document doc, String? sourceUrl) {
    final candidates = <String>[
      doc.querySelector('meta[property="og:title"]')?.attributes['content'] ??
          '',
      doc.querySelector('meta[name="twitter:title"]')?.attributes['content'] ??
          '',
      doc.querySelector('h1')?.text.trim() ?? '',
      doc.querySelector('article h2')?.text.trim() ?? '',
      doc.querySelector('main h2')?.text.trim() ?? '',
      doc.querySelector('title')?.text.trim() ?? '',
    ];

    for (final raw in candidates) {
      final normalized =
          raw.replaceAll(RegExp(r'\s*[|–—-]\s*[^|–—-]+$'), '').trim();
      if (normalized.isEmpty) continue;
      if (_isGenericSiteTitle(normalized)) continue;
      if (_looksLikeSectionHeading(normalized)) continue;
      return normalized;
    }

    return _titleFromUrl(sourceUrl) ?? 'Imported Recipe';
  }

  bool _isGenericSiteTitle(String title) {
    final t = title.toLowerCase();
    return t == 'home' || t == 'startseite';
  }

  bool _looksLikeSectionHeading(String title) {
    final t = title.toLowerCase();
    return t.startsWith('zutaten') ||
        t.startsWith('zubereitung') ||
        t.startsWith('instructions') ||
        t.startsWith('ingredients') ||
        t.startsWith('directions');
  }

  String? _titleFromUrl(String? sourceUrl) {
    if (sourceUrl == null) return null;
    final uri = Uri.tryParse(sourceUrl);
    final segs =
        uri?.pathSegments.where((s) => s.isNotEmpty).toList() ?? const [];
    if (segs.isEmpty) return null;
    return segs.last.replaceAll('-', ' ').replaceAll('_', ' ').trim();
  }

  /// Extract list items from the first section matching any of [keywords].
  List<String> _extractSectionItems(Document doc, List<String> keywords) {
    final items = <String>[];
    for (final heading in doc.querySelectorAll('h1, h2, h3, h4')) {
      final headingText = heading.text.toLowerCase();
      if (!keywords.any(headingText.contains)) continue;
      Element? node = heading.nextElementSibling;
      while (node != null &&
          !RegExp(r'^h[1-4]$').hasMatch(node.localName ?? '')) {
        if (node.localName == 'ul' || node.localName == 'ol') {
          for (final li in node.querySelectorAll('li')) {
            final text = li.text.trim();
            if (text.isNotEmpty) items.add(text);
          }
        }
        if (node.localName == 'p') {
          final text = node.text.trim();
          if (text.isNotEmpty) items.add(text);
        }
        node = node.nextElementSibling;
      }
      if (items.isNotEmpty) break;
    }
    return items;
  }

  List<String> _extractImageCandidates(Document doc, String? sourceUrl) {
    final candidates = <String>[];

    void addCandidate(String? value) {
      if (value == null || value.trim().isEmpty) return;
      final normalized = _normalizeImageUrl(value.trim(), sourceUrl);
      if (normalized == null) return;
      if (!candidates.contains(normalized)) {
        candidates.add(normalized);
      }
    }

    addCandidate(
      doc.querySelector('meta[property="og:image"]')?.attributes['content'],
    );
    addCandidate(
      doc.querySelector('meta[name="twitter:image"]')?.attributes['content'],
    );
    addCandidate(doc.querySelector('img[itemprop="image"]')?.attributes['src']);

    for (final image in doc.querySelectorAll('article img, main img, img')) {
      addCandidate(image.attributes['src']);
      if (candidates.length >= 12) break;
    }

    return candidates.take(5).toList();
  }

  String? _normalizeImageUrl(String url, String? sourceUrl) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.hasScheme) return uri.toString();
    if (sourceUrl == null) return null;
    final sourceUri = Uri.tryParse(sourceUrl);
    if (sourceUri == null) return null;
    return sourceUri.resolveUri(uri).toString();
  }

  // ──────────────────── Private: utility ─────────────────────────────

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) {
            if (e is Map) return (e['text'] ?? e.values.first ?? '').toString();
            return e.toString();
          })
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }
    if (value is String && value.isNotEmpty) return [value];
    return [];
  }
}
