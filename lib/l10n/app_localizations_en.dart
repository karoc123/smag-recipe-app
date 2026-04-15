// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SMAG';

  @override
  String get gridTitle => 'Your Week';

  @override
  String get emptySlot => 'Add Recipe';

  @override
  String get recipes => 'Recipes';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search recipes…';

  @override
  String get noRecipes => 'No recipes yet. Import or create one!';

  @override
  String get noResults => 'No results found.';

  @override
  String get newRecipe => 'New Recipe';

  @override
  String get editRecipe => 'Edit Recipe';

  @override
  String get deleteRecipe => 'Delete Recipe';

  @override
  String deleteConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get overwrite => 'Overwrite';

  @override
  String get overwriteTitle => 'Recipe Exists';

  @override
  String overwriteMessage(String title) {
    return '\"$title\" already exists. Overwrite?';
  }

  @override
  String get importRecipe => 'Import Recipe';

  @override
  String get importFromUrl => 'Import from URL';

  @override
  String get importFromText => 'Import from Text';

  @override
  String get urlHint => 'Paste recipe URL…';

  @override
  String get textHint => 'Paste recipe text…';

  @override
  String get importing => 'Importing…';

  @override
  String get importSuccess => 'Recipe imported successfully!';

  @override
  String get importError => 'Could not import recipe.';

  @override
  String get title => 'Title';

  @override
  String get category => 'Category';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get instructions => 'Instructions';

  @override
  String get pickDirectory => 'Select Recipe Folder';

  @override
  String get pickDirectoryHint =>
      'Choose the directory where your recipes are stored.';

  @override
  String get removeFromGrid => 'Remove from grid';

  @override
  String get assignToGrid => 'Add to grid';

  @override
  String get cookMode => 'Cook Mode';

  @override
  String get servings => 'Servings';

  @override
  String get prepTime => 'Prep Time';

  @override
  String get cookTime => 'Cook Time';

  @override
  String get recipePickerTitle => 'Choose a Recipe';

  @override
  String get settings => 'Settings';

  @override
  String get storageDirectory => 'Storage Directory';

  @override
  String get notSet => 'Not set';

  @override
  String get dragToRemove => 'Drag here to remove';

  @override
  String get categoryUncategorized => 'Uncategorized';
}
