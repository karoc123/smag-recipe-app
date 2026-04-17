import 'package:flutter/material.dart';

import '../domain/recipe.dart';
import '../services/recipe_duration.dart';

class RecipeEditDraft {
  String name;
  String category;
  String yieldText;
  String prepTimeIso;
  String cookTimeIso;
  String description;
  String image;
  String url;
  String keywords;
  String ingredientsText;
  String instructionsText;

  RecipeEditDraft({
    this.name = '',
    this.category = '',
    this.yieldText = '',
    this.prepTimeIso = '',
    this.cookTimeIso = '',
    this.description = '',
    this.image = '',
    this.url = '',
    this.keywords = '',
    this.ingredientsText = '',
    this.instructionsText = '',
  });

  factory RecipeEditDraft.fromRecipe([Recipe? recipe]) {
    final value = recipe ?? const Recipe();
    return RecipeEditDraft(
      name: value.name,
      category: value.recipeCategory,
      yieldText: value.recipeYield,
      prepTimeIso: value.prepTime,
      cookTimeIso: value.cookTime,
      description: value.description,
      image: value.localImagePath.isNotEmpty
          ? value.localImagePath
          : value.image,
      url: value.url,
      keywords: value.keywords,
      ingredientsText: value.recipeIngredient.join('\n'),
      instructionsText: value.recipeInstructions.join('\n'),
    );
  }

  String get prepTimeDisplay => RecipeDuration.toDisplay(prepTimeIso);
  String get cookTimeDisplay => RecipeDuration.toDisplay(cookTimeIso);

  void setPrepTime(TimeOfDay time) {
    prepTimeIso = RecipeDuration.fromTimeOfDay(time);
  }

  void setCookTime(TimeOfDay time) {
    cookTimeIso = RecipeDuration.fromTimeOfDay(time);
  }

  Recipe toRecipe(Recipe base) {
    final trimmedImage = image.trim();
    return base.copyWith(
      name: name.trim(),
      recipeCategory: category.trim(),
      recipeYield: yieldText.trim(),
      prepTime: prepTimeIso,
      cookTime: cookTimeIso,
      image: trimmedImage,
      localImagePath: trimmedImage.startsWith('http') ? '' : trimmedImage,
      url: url.trim(),
      keywords: keywords.trim(),
      description: description.trim(),
      recipeIngredient: _splitLines(ingredientsText),
      recipeInstructions: _splitLines(instructionsText),
    );
  }

  static List<String> _splitLines(String value) {
    return value
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}
