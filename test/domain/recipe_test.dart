import 'package:flutter_test/flutter_test.dart';
import 'package:smag/domain/recipe.dart';

void main() {
  group('Recipe.fromJson', () {
    test('parses standard Nextcloud Cookbook JSON', () {
      final json = {
        'id': 42,
        'name': 'Pancakes',
        'description': 'Fluffy pancakes',
        'recipeCategory': 'Breakfast',
        'recipeYield': '4 servings',
        'prepTime': 'PT10M',
        'cookTime': 'PT15M',
        'recipeIngredient': ['2 cups flour', '1 egg'],
        'recipeInstructions': ['Mix', 'Cook'],
      };

      final recipe = Recipe.fromJson(json);
      expect(recipe.remoteId, 42);
      expect(recipe.name, 'Pancakes');
      expect(recipe.description, 'Fluffy pancakes');
      expect(recipe.recipeCategory, 'Breakfast');
      expect(recipe.recipeYield, '4 servings');
      expect(recipe.recipeIngredient, ['2 cups flour', '1 egg']);
      expect(recipe.recipeInstructions, ['Mix', 'Cook']);
    });

    test('handles HowToStep instructions', () {
      final json = {
        'name': 'Test',
        'recipeInstructions': [
          {'@type': 'HowToStep', 'text': 'Step 1'},
          {'@type': 'HowToStep', 'text': 'Step 2'},
        ],
      };

      final recipe = Recipe.fromJson(json);
      expect(recipe.recipeInstructions, ['Step 1', 'Step 2']);
    });

    test('handles nested instruction list via itemListElement', () {
      final json = {
        'name': 'Nested',
        'recipeInstructions': {
          '@type': 'HowToSection',
          'itemListElement': [
            {'@type': 'HowToStep', 'text': 'Prep ingredients'},
            {'@type': 'HowToStep', 'text': 'Cook slowly'},
          ],
        },
      };

      final recipe = Recipe.fromJson(json);
      expect(recipe.recipeInstructions, ['Prep ingredients', 'Cook slowly']);
    });

    test('handles null and missing fields gracefully', () {
      final recipe = Recipe.fromJson({});
      expect(recipe.name, '');
      expect(recipe.recipeIngredient, isEmpty);
      expect(recipe.recipeInstructions, isEmpty);
      expect(recipe.remoteId, isNull);
    });

    test('converts string id to int', () {
      final recipe = Recipe.fromJson({'id': '99', 'name': 'Test'});
      expect(recipe.remoteId, 99);
    });
  });

  group('Recipe.toJson', () {
    test('round-trips through fromJson/toJson', () {
      final original = Recipe(
        remoteId: 5,
        name: 'Soup',
        recipeCategory: 'Dinner',
        recipeIngredient: ['Water', 'Salt'],
        recipeInstructions: ['Boil', 'Season'],
      );

      final json = original.toJson();
      final restored = Recipe.fromJson(json);

      expect(restored.remoteId, original.remoteId);
      expect(restored.name, original.name);
      expect(restored.recipeCategory, original.recipeCategory);
      expect(restored.recipeIngredient, original.recipeIngredient);
      expect(restored.recipeInstructions, original.recipeInstructions);
    });

    test('omits id when remoteId is null', () {
      final recipe = Recipe(name: 'Local');
      final json = recipe.toJson();
      expect(json.containsKey('id'), isFalse);
    });
  });

  group('Recipe.copyWith', () {
    test('copies selected fields', () {
      final original = Recipe(name: 'A', recipeCategory: 'Cat');
      final modified = original.copyWith(name: 'B');

      expect(modified.name, 'B');
      expect(modified.recipeCategory, 'Cat');
    });
  });

  group('Recipe.displayCategory', () {
    test('returns category when set', () {
      expect(Recipe(recipeCategory: 'Main').displayCategory, 'Main');
    });

    test('returns Uncategorized when empty', () {
      expect(const Recipe().displayCategory, 'Uncategorized');
    });
  });
}
