import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smag/services/recipe_import_service.dart';
import 'package:smag/services/recipe_parser.dart';

void main() {
  group('RecipeImportService', () {
    test('imports a recipe from url using the injected http client', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'https://example.com/soup');
        return http.Response('''
          <html>
            <head><title>Tomato Soup</title></head>
            <body>
              <ul>
                <li itemprop="recipeIngredient">Tomatoes</li>
                <li itemprop="recipeIngredient">Salt</li>
              </ul>
            </body>
          </html>
        ''', 200);
      });
      final service = RecipeImportService(client, RecipeParser());

      final result = await service.importFromUrl('https://example.com/soup');

      expect(result.recipe.name, 'Tomato Soup');
      expect(result.recipe.url, 'https://example.com/soup');
      expect(result.recipe.recipeIngredient, ['Tomatoes', 'Salt']);
    });

    test('throws when the remote page returns a non-success status', () async {
      final client = MockClient((_) async => http.Response('not found', 404));
      final service = RecipeImportService(client, RecipeParser());

      expect(
        () => service.importFromUrl('https://example.com/missing'),
        throwsA(isA<Exception>()),
      );
    });

    test('imports a recipe from plain text through the parser', () {
      final client = MockClient((_) async => http.Response('', 200));
      final service = RecipeImportService(client, RecipeParser());

      final recipe = service.importFromText('''
# Pancakes

## Ingredients
- Flour
- Milk

## Instructions
1. Mix
2. Fry
''');

      expect(recipe.name, 'Pancakes');
      expect(recipe.recipeIngredient, ['Flour', 'Milk']);
      expect(recipe.recipeInstructions, ['Mix', 'Fry']);
    });
  });
}
