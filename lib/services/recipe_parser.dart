import 'dart:convert';

import 'package:toml/toml.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../domain/recipe_entity.dart';

class ParsedUrlImport {
  final RecipeEntity recipe;
  final List<String> imageCandidates;

  const ParsedUrlImport({required this.recipe, required this.imageCandidates});
}

/// Standalone, modular service that converts between SMAG Markdown files and
/// [RecipeEntity] instances.  Deliberately has **no** dependency on file I/O so
/// it can be tested and swapped independently.
class RecipeParser {
  // ──────────────────────── Markdown → Entity ────────────────────────

  /// Parses a Hugo-compatible Markdown string (with `+++` TOML frontmatter)
  /// into a [RecipeEntity].
  RecipeEntity parseMarkdown(String raw, {String? relativePath}) {
    final parts = _splitFrontmatter(raw);
    final tomlString = parts.$1;
    final body = parts.$2;

    Map<String, dynamic> meta = {};
    if (tomlString.isNotEmpty) {
      try {
        meta = TomlDocument.parse(tomlString).toMap();
      } catch (_) {
        // Gracefully degrade – treat file as body-only.
      }
    }

    final extra = meta['extra'] as Map<String, dynamic>? ?? {};

    return RecipeEntity(
      title: _str(meta['title']) ?? _titleFromPath(relativePath) ?? 'Untitled',
      date: _parseDate(meta['date']),
      category: _str(meta['category']) ?? _categoryFromPath(relativePath) ?? '',
      imagePath: _extractImage(body),
      servings: _str(extra['servings']),
      prepTime: _str(extra['prep_time']),
      cookTime: _str(extra['cook_time']),
      body: body,
      relativePath: relativePath,
    );
  }

  // ──────────────────────── Entity → Markdown ────────────────────────

  /// Serialises a [RecipeEntity] back into a Hugo-compatible Markdown string.
  String toMarkdown(RecipeEntity recipe) {
    final buf = StringBuffer();
    buf.writeln('+++');
    buf.writeln('title = ${_tomlQuote(recipe.title)}');
    buf.writeln('date = ${recipe.date.toUtc().toIso8601String()}');
    if (recipe.category.isNotEmpty) {
      buf.writeln('category = ${_tomlQuote(recipe.category)}');
    }

    // [extra] block
    final hasExtra =
        recipe.servings != null ||
        recipe.prepTime != null ||
        recipe.cookTime != null;
    if (hasExtra) {
      buf.writeln('[extra]');
      if (recipe.servings != null) {
        buf.writeln('servings = ${_tomlQuote(recipe.servings!)}');
      }
      if (recipe.prepTime != null) {
        buf.writeln('prep_time = ${_tomlQuote(recipe.prepTime!)}');
      }
      if (recipe.cookTime != null) {
        buf.writeln('cook_time = ${_tomlQuote(recipe.cookTime!)}');
      }
    }
    buf.writeln('+++');
    buf.writeln();

    if (recipe.imagePath != null && recipe.imagePath!.isNotEmpty) {
      buf.writeln('{{< figure src="${recipe.imagePath}" >}}');
      buf.writeln();
    }

    buf.write(recipe.body);
    return buf.toString();
  }

  // ──────────────────── HTML → Entity (importer) ─────────────────────

  /// Best-effort extraction of structured recipe data from raw HTML.
  RecipeEntity parseHtml(String htmlString, {String? sourceUrl}) {
    return parseHtmlWithCandidates(htmlString, sourceUrl: sourceUrl).recipe;
  }

  ParsedUrlImport parseHtmlWithCandidates(
    String htmlString, {
    String? sourceUrl,
  }) {
    final doc = html_parser.parse(htmlString);

    final title = _extractImportTitle(doc, sourceUrl);

    // Try JSON-LD structured data first
    String ingredients = '';
    String instructions = '';
    for (final script in doc.querySelectorAll(
      'script[type="application/ld+json"]',
    )) {
      final text = script.text;
      if (text.contains('recipeIngredient')) {
        ingredients = _extractJsonLdList(text, 'recipeIngredient');
        instructions = _extractJsonLdInstructions(text);
        break;
      }
    }

    // Fallback: heuristic scraping
    if (ingredients.isEmpty) {
      final ingredientEls = doc.querySelectorAll(
        'li[itemprop="recipeIngredient"], .recipe-ingredient li, .ingredients li',
      );
      if (ingredientEls.isNotEmpty) {
        ingredients = ingredientEls.map((e) => '- ${e.text.trim()}').join('\n');
      }

      if (ingredients.isEmpty) {
        ingredients = _extractSectionList(doc, const [
          'zutaten',
          'ingredients',
        ]);
      }
    }
    if (instructions.isEmpty) {
      final instructionEls = doc.querySelectorAll(
        '[itemprop="recipeInstructions"] li, .recipe-instructions li, .instructions li, .directions li',
      );
      if (instructionEls.isNotEmpty) {
        int step = 1;
        instructions = instructionEls
            .map((e) => '${step++}. ${e.text.trim()}')
            .join('\n');
      }

      if (instructions.isEmpty) {
        instructions = _extractSectionSteps(doc, const [
          'zubereitung',
          'anleitung',
          'instructions',
          'directions',
        ]);
      }
    }

    final imageCandidates = _extractImageCandidates(doc, sourceUrl);
    final image = imageCandidates.isNotEmpty ? imageCandidates.first : null;

    final body = StringBuffer();
    if (ingredients.isNotEmpty) {
      body.writeln('## Ingredients');
      body.writeln(ingredients);
      body.writeln();
    }
    if (instructions.isNotEmpty) {
      body.writeln('## Instructions');
      body.writeln(instructions);
      body.writeln();
    }

    if (ingredients.isEmpty && instructions.isEmpty) {
      final fallbackText = _extractFallbackBody(doc);
      if (fallbackText.isNotEmpty) {
        body.writeln(fallbackText);
        body.writeln();
      }
    }

    if (sourceUrl != null) {
      body.writeln('---');
      body.writeln('*Source: $sourceUrl*');
    }

    return ParsedUrlImport(
      recipe: RecipeEntity(
        title: title,
        imagePath: image,
        body: body.toString(),
      ),
      imageCandidates: imageCandidates,
    );
  }

  /// Parse plain text that a user pastes (best-effort).
  RecipeEntity parsePlainText(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('{')) {
      final parsed = _parseJsonRecipe(trimmed);
      if (parsed != null) return parsed;
    }

    final lines = text.split('\n');
    final title = lines.isNotEmpty
        ? lines.first.replaceAll(RegExp(r'^#+\s*'), '').trim()
        : 'Untitled';
    final body = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';
    return RecipeEntity(title: title, body: body);
  }

  // ──────────────────────── Private helpers ──────────────────────────

  (String, String) _splitFrontmatter(String raw) {
    final trimmed = raw.trimLeft();
    if (!trimmed.startsWith('+++')) return ('', raw);
    final end = trimmed.indexOf('+++', 3);
    if (end == -1) return ('', raw);
    final toml = trimmed.substring(3, end).trim();
    final body = trimmed.substring(end + 3).trim();
    return (toml, body);
  }

  String? _str(dynamic v) => v?.toString();

  DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  String? _titleFromPath(String? p) {
    if (p == null) return null;
    final name = p.split('/').last.replaceAll('.md', '');
    return name.replaceAll('-', ' ').replaceAll('_', ' ');
  }

  String? _categoryFromPath(String? p) {
    if (p == null) return null;
    final segments = p.split('/');
    return segments.length > 1 ? segments.first : null;
  }

  String? _extractImage(String body) {
    // Match Hugo shortcode: {{< figure src="/images/foo.jpg" >}}
    final shortcode = RegExp(r'\{\{<\s*figure\s+src="([^"]+)"');
    final m = shortcode.firstMatch(body);
    if (m != null) return m.group(1);
    // Match standard Markdown image: ![alt](url)
    final mdImage = RegExp(r'!\[[^\]]*\]\(([^)]+)\)');
    final m2 = mdImage.firstMatch(body);
    return m2?.group(1);
  }

  String _tomlQuote(String v) => '"${v.replaceAll('"', '\\"')}"';

  String _extractJsonLdList(String json, String key) {
    // Lightweight extraction without a JSON dependency – matches array of strings.
    final pattern = RegExp('"$key"\\s*:\\s*\\[([^\\]]+)]');
    final m = pattern.firstMatch(json);
    if (m == null) return '';
    final items = RegExp(r'"([^"]+)"').allMatches(m.group(1)!);
    return items.map((i) => '- ${i.group(1)}').join('\n');
  }

  String _extractJsonLdInstructions(String json) {
    // Extract recipeInstructions text fields
    final pattern = RegExp(r'"text"\s*:\s*"([^"]+)"');
    final matches = pattern.allMatches(json);
    int step = 1;
    return matches.map((m) => '${step++}. ${m.group(1)}').join('\n');
  }

  String _extractImportTitle(Document doc, String? sourceUrl) {
    final candidates = <String>[
      doc.querySelector('meta[property="og:title"]')?.attributes['content'] ??
          '',
      doc.querySelector('meta[name="twitter:title"]')?.attributes['content'] ??
          '',
      doc.querySelector('h1')?.text.trim() ?? '',
      doc.querySelector('article h2')?.text.trim() ?? '',
      doc.querySelector('main h2')?.text.trim() ?? '',
      doc.querySelector('figcaption h4')?.text.trim() ?? '',
      doc.querySelector('title')?.text.trim() ?? '',
    ];

    for (final raw in candidates) {
      final normalized = raw
          .replaceAll(RegExp(r'\s*[|–—-]\s*[^|–—-]+$'), '')
          .trim();
      if (normalized.isEmpty) continue;
      if (_isGenericSiteTitle(normalized)) continue;
      if (_looksLikeSectionHeading(normalized)) continue;
      return normalized;
    }

    return _titleFromUrl(sourceUrl) ?? 'Imported Recipe';
  }

  bool _isGenericSiteTitle(String title) {
    final t = title.toLowerCase();
    return t == 'home' ||
        t == 'startseite' ||
        t == 'projekt:essen' ||
        t == 'projekt essen';
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
        uri?.pathSegments.where((s) => s.isNotEmpty).toList() ??
        const <String>[];
    if (segs.isEmpty) return null;
    final slug = segs.last;
    return slug.replaceAll('-', ' ').replaceAll('_', ' ').trim();
  }

  String _extractSectionList(Document doc, List<String> keywords) {
    final listItems = <String>[];
    for (final heading in doc.querySelectorAll('h1, h2, h3, h4')) {
      final headingText = heading.text.toLowerCase();
      if (!keywords.any(headingText.contains)) continue;
      Element? node = heading.nextElementSibling;
      while (node != null &&
          !RegExp(r'^h[1-4]$').hasMatch(node.localName ?? '')) {
        if (node.localName == 'ul' || node.localName == 'ol') {
          for (final li in node.querySelectorAll('li')) {
            final text = li.text.trim();
            if (text.isNotEmpty) listItems.add('- $text');
          }
        }
        node = node.nextElementSibling;
      }
    }
    return listItems.join('\n');
  }

  String _extractSectionSteps(Document doc, List<String> keywords) {
    final steps = <String>[];
    for (final heading in doc.querySelectorAll('h1, h2, h3, h4')) {
      final headingText = heading.text.toLowerCase();
      if (!keywords.any(headingText.contains)) continue;
      Element? node = heading.nextElementSibling;
      while (node != null &&
          !RegExp(r'^h[1-4]$').hasMatch(node.localName ?? '')) {
        if (node.localName == 'ol') {
          for (final li in node.querySelectorAll('li')) {
            final text = li.text.trim();
            if (text.isNotEmpty) steps.add(text);
          }
        }
        if (node.localName == 'ul') {
          for (final li in node.querySelectorAll('li')) {
            final text = li.text.trim();
            if (text.isNotEmpty) steps.add(text);
          }
        }
        if (node.localName == 'p') {
          final text = node.text.trim();
          if (text.isNotEmpty) steps.add(text);
        }
        node = node.nextElementSibling;
      }
    }
    int idx = 1;
    return steps.map((s) => '${idx++}. $s').join('\n');
  }

  String _extractFallbackBody(Document doc) {
    final article =
        doc.querySelector('article') ?? doc.querySelector('main') ?? doc.body;
    if (article == null) return '';

    final paragraphs = <String>[];
    for (final p in article.querySelectorAll('p')) {
      final text = p.text.trim();
      if (text.isEmpty) continue;
      if (text.length < 20) continue;
      paragraphs.add(text);
      if (paragraphs.length >= 6) break;
    }
    return paragraphs.join('\n\n');
  }

  RecipeEntity? _parseJsonRecipe(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final title = (decoded['title'] ?? '').toString().trim();
      if (title.isEmpty) return null;

      final category = (decoded['category'] ?? '').toString().trim();
      final servings = _jsonString(decoded['servings']);
      final prepTime =
          _jsonString(decoded['prep_time']) ?? _jsonString(decoded['prepTime']);
      final cookTime =
          _jsonString(decoded['cook_time']) ?? _jsonString(decoded['cookTime']);
      final image = _jsonString(decoded['image']);

      final ingredients = _jsonList(decoded['ingredients']);
      final instructions = _jsonList(decoded['instructions']);

      String body = _jsonString(decoded['body'])?.trim() ?? '';
      if (body.isEmpty) {
        final buf = StringBuffer();
        if (ingredients.isNotEmpty) {
          buf.writeln('## Ingredients');
          for (final item in ingredients) {
            buf.writeln('- $item');
          }
          buf.writeln();
        }
        if (instructions.isNotEmpty) {
          buf.writeln('## Instructions');
          for (int i = 0; i < instructions.length; i++) {
            buf.writeln('${i + 1}. ${instructions[i]}');
          }
          buf.writeln();
        }
        final notes = _jsonString(decoded['notes']);
        if (notes != null && notes.trim().isNotEmpty) {
          buf.writeln('## Notes');
          buf.writeln(notes.trim());
          buf.writeln();
        }
        final source = _jsonString(decoded['source_url']);
        if (source != null && source.trim().isNotEmpty) {
          buf.writeln('---');
          buf.writeln('*Source: ${source.trim()}*');
        }
        body = buf.toString().trim();
      }

      return RecipeEntity(
        title: title,
        category: category,
        servings: servings,
        prepTime: prepTime,
        cookTime: cookTime,
        imagePath: image,
        body: body,
      );
    } catch (_) {
      return null;
    }
  }

  String? _jsonString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  List<String> _jsonList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
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
}
