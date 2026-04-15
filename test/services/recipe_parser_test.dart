import 'package:flutter_test/flutter_test.dart';
import 'package:smag/services/recipe_parser.dart';

void main() {
  group('RecipeParser', () {
    late RecipeParser parser;

    setUp(() {
      parser = RecipeParser();
    });

    test('imports JSON recipe text into structured recipe entity', () {
      const json = '''
{
  "title": "Kartoffelsuppe",
  "category": "Suppen",
  "servings": "4",
  "prep_time": "20 min",
  "cook_time": "30 min",
  "ingredients": ["1 kg Kartoffeln", "1 Zwiebel"],
  "instructions": ["Alles schneiden.", "30 Minuten kochen."],
  "source_url": "https://example.org/suppe"
}
''';

      final recipe = parser.parsePlainText(json);

      expect(recipe.title, 'Kartoffelsuppe');
      expect(recipe.category, 'Suppen');
      expect(recipe.servings, '4');
      expect(recipe.prepTime, '20 min');
      expect(recipe.cookTime, '30 min');
      expect(recipe.body, contains('## Ingredients'));
      expect(recipe.body, contains('- 1 kg Kartoffeln'));
      expect(recipe.body, contains('## Instructions'));
      expect(recipe.body, contains('1. Alles schneiden.'));
      expect(recipe.body, contains('*Source: https://example.org/suppe*'));
    });

    test('extracts simple recipe html with title and sections', () {
      const html = '''
<!doctype html>
<html>
  <head>
    <title>Projekt:Essen</title>
  </head>
  <body>
    <article>
      <figure><img src="/images/kuchen.jpg"/></figure>
      <h2>Zutaten</h2>
      <ul><li>2 Eier</li><li>200 g Mehl</li></ul>
      <h2>Zubereitung</h2>
      <p>Alles verruehren.</p>
      <p>Backen.</p>
    </article>
  </body>
</html>
''';

      final parsed = parser.parseHtmlWithCandidates(
        html,
        sourceUrl: 'https://essen.karoc.de/posts/porno-schoko-kuchen/',
      );

      expect(parsed.recipe.title, 'porno schoko kuchen');
      expect(parsed.recipe.body, contains('## Ingredients'));
      expect(parsed.recipe.body, contains('- 2 Eier'));
      expect(parsed.recipe.body, contains('## Instructions'));
      expect(parsed.imageCandidates, isNotEmpty);
      expect(
        parsed.imageCandidates.first,
        startsWith('https://essen.karoc.de/'),
      );
    });

    test('returns up to five unique image candidates', () {
      const html = '''
<!doctype html>
<html>
  <head>
    <meta property="og:image" content="https://img.example/a.jpg"/>
    <meta name="twitter:image" content="https://img.example/b.jpg"/>
  </head>
  <body>
    <img src="https://img.example/c.jpg"/>
    <img src="https://img.example/d.jpg"/>
    <img src="https://img.example/e.jpg"/>
    <img src="https://img.example/f.jpg"/>
    <img src="https://img.example/g.jpg"/>
  </body>
</html>
''';

      final parsed = parser.parseHtmlWithCandidates(
        html,
        sourceUrl: 'https://example.com/recipe',
      );

      expect(parsed.imageCandidates.length, lessThanOrEqualTo(5));
      expect(
        parsed.imageCandidates.toSet().length,
        parsed.imageCandidates.length,
      );
    });
  });
}
