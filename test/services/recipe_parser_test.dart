import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smag/services/recipe_parser.dart';

void main() {
  late RecipeParser parser;

  setUp(() {
    parser = RecipeParser();
  });

  group('parseHtml – JSON-LD', () {
    test('extracts recipe from JSON-LD script tag', () {
      final jsonLd = jsonEncode({
        '@type': 'Recipe',
        'name': 'Cake',
        'recipeIngredient': ['Flour', 'Sugar'],
        'recipeInstructions': [
          {'@type': 'HowToStep', 'text': 'Mix'},
          {'@type': 'HowToStep', 'text': 'Bake'},
        ],
      });

      final html =
          '''
<!DOCTYPE html>
<html><head><title>My Cake</title>
<script type="application/ld+json">$jsonLd</script>
</head><body></body></html>
''';

      final result = parser.parseHtmlWithCandidates(
        html,
        sourceUrl: 'https://example.com/cake',
      );
      expect(result.recipe.name, 'Cake');
      expect(result.recipe.recipeIngredient, ['Flour', 'Sugar']);
      expect(result.recipe.recipeInstructions, ['Mix', 'Bake']);
      expect(result.recipe.url, 'https://example.com/cake');
    });

    test('handles @graph wrapper', () {
      final jsonLd = jsonEncode({
        '@context': 'https://schema.org',
        '@graph': [
          {'@type': 'WebPage', 'name': 'Page'},
          {
            '@type': 'Recipe',
            'name': 'Salad',
            'recipeIngredient': ['Lettuce'],
          },
        ],
      });

      final html =
          '''
<html><head>
<script type="application/ld+json">$jsonLd</script>
</head><body></body></html>
''';

      final recipe = parser.parseHtml(html);
      expect(recipe.name, 'Salad');
      expect(recipe.recipeIngredient, ['Lettuce']);
    });
  });

  group('parseHtml – heuristic fallback', () {
    test('extracts ingredients from microdata', () {
      final html = '''
<html><head><title>Soup</title></head><body>
<ul>
  <li itemprop="recipeIngredient">Water</li>
  <li itemprop="recipeIngredient">Salt</li>
</ul>
</body></html>
''';

      final recipe = parser.parseHtml(html);
      expect(recipe.name, 'Soup');
      expect(recipe.recipeIngredient, ['Water', 'Salt']);
    });
  });

  group('parsePlainText', () {
    test('parses JSON input', () {
      final json = jsonEncode({
        'name': 'Toast',
        'recipeIngredient': ['Bread', 'Butter'],
        'recipeInstructions': ['Toast bread', 'Apply butter'],
      });

      final recipe = parser.parsePlainText(json);
      expect(recipe.name, 'Toast');
      expect(recipe.recipeIngredient, ['Bread', 'Butter']);
    });

    test('parses JSON with alternate keys (title, category)', () {
      final json = jsonEncode({
        'title': 'Omelette',
        'category': 'Breakfast',
        'ingredients': ['Eggs', 'Cheese'],
        'instructions': ['Beat eggs', 'Cook'],
      });

      final recipe = parser.parsePlainText(json);
      expect(recipe.name, 'Omelette');
      expect(recipe.recipeCategory, 'Breakfast');
    });

    test('parses markdown-style text', () {
      const text = '''
# My Recipe

## Ingredients
- Flour
- Water

## Instructions
1. Mix together
2. Bake
''';

      final recipe = parser.parsePlainText(text);
      expect(recipe.name, 'My Recipe');
      expect(recipe.recipeIngredient, ['Flour', 'Water']);
      expect(recipe.recipeInstructions, ['Mix together', 'Bake']);
    });

    test('handles German section headers', () {
      const text = '''
Kartoffelsuppe

## Zutaten
- Kartoffeln
- Salz

## Zubereitung
- Kochen
- Würzen
''';

      final recipe = parser.parsePlainText(text);
      expect(recipe.name, 'Kartoffelsuppe');
      expect(recipe.recipeIngredient, ['Kartoffeln', 'Salz']);
      expect(recipe.recipeInstructions, ['Kochen', 'Würzen']);
    });
  });
}
