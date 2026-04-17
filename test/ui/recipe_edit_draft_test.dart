import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smag/domain/recipe.dart';
import 'package:smag/ui/recipe_edit_draft.dart';

void main() {
  group('RecipeEditDraft', () {
    test('creates form-friendly values from a recipe', () {
      final draft = RecipeEditDraft.fromRecipe(
        const Recipe(
          name: 'Pancakes',
          recipeCategory: 'Breakfast',
          recipeYield: '4 servings',
          prepTime: 'PT15M',
          cookTime: 'PT10M',
          description: 'Fluffy',
          image: 'https://example.com/pancakes.jpg',
          localImagePath: '/tmp/pancakes.jpg',
          url: 'https://example.com/pancakes',
          keywords: 'sweet, brunch',
          recipeIngredient: ['Flour', 'Milk'],
          recipeInstructions: ['Mix', 'Fry'],
        ),
      );

      expect(draft.name, 'Pancakes');
      expect(draft.category, 'Breakfast');
      expect(draft.yieldText, '4 servings');
      expect(draft.prepTimeDisplay, '15min');
      expect(draft.cookTimeDisplay, '10min');
      expect(draft.ingredientsText, 'Flour\nMilk');
      expect(draft.instructionsText, 'Mix\nFry');
    });

    test('builds a trimmed recipe with split multiline fields', () {
      final draft = RecipeEditDraft.fromRecipe();
      draft.name = '  Pancakes  ';
      draft.category = '  Breakfast  ';
      draft.yieldText = '  4 servings ';
      draft.description = '  Fluffy and quick ';
      draft.image = ' /tmp/pancakes.jpg ';
      draft.url = ' https://example.com/pancakes ';
      draft.keywords = ' sweet, brunch ';
      draft.ingredientsText = ' Flour \n\n Milk \n Eggs ';
      draft.instructionsText = ' Mix \n\n Fry \n Serve ';
      draft.setPrepTime(const TimeOfDay(hour: 0, minute: 15));
      draft.setCookTime(const TimeOfDay(hour: 0, minute: 10));

      final recipe = draft.toRecipe(const Recipe(remoteId: 8));

      expect(recipe.remoteId, 8);
      expect(recipe.name, 'Pancakes');
      expect(recipe.recipeCategory, 'Breakfast');
      expect(recipe.recipeYield, '4 servings');
      expect(recipe.description, 'Fluffy and quick');
      expect(recipe.image, '/tmp/pancakes.jpg');
      expect(recipe.localImagePath, '/tmp/pancakes.jpg');
      expect(recipe.url, 'https://example.com/pancakes');
      expect(recipe.keywords, 'sweet, brunch');
      expect(recipe.prepTime, 'P0DT0H15M');
      expect(recipe.cookTime, 'P0DT0H10M');
      expect(recipe.recipeIngredient, ['Flour', 'Milk', 'Eggs']);
      expect(recipe.recipeInstructions, ['Mix', 'Fry', 'Serve']);
    });
  });
}
