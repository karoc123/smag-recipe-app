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
  String get recipes => 'Recipes';

  @override
  String get grid => 'Grid';

  @override
  String get search => 'Search';

  @override
  String get noRecipes => 'No recipes yet. Import or create one!';

  @override
  String get newRecipe => 'New Recipe';

  @override
  String get editRecipe => 'Edit Recipe';

  @override
  String get deleteRecipe => 'Delete Recipe';

  @override
  String get deleteRecipeConfirm =>
      'Are you sure you want to delete this recipe?';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get importTitle => 'Import';

  @override
  String get importFromUrl => 'From URL';

  @override
  String get importFromText => 'From Text';

  @override
  String get importButton => 'Import';

  @override
  String get importLocally => 'Import Locally';

  @override
  String get sendToNextcloud => 'Send to Nextcloud';

  @override
  String get sentToNextcloud => 'Recipe sent to Nextcloud';

  @override
  String get importedRecipe => 'Imported recipe';

  @override
  String get copyPrompt => 'Copy Prompt';

  @override
  String get promptCopied => 'Prompt copied to clipboard';

  @override
  String get pasteRecipeHint => 'Paste JSON or recipe text here…';

  @override
  String get selectImage => 'Select Image';

  @override
  String get skip => 'Skip';

  @override
  String get title => 'Title';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get category => 'Category';

  @override
  String get description => 'Description';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get ingredientsHint => 'One ingredient per line';

  @override
  String get instructions => 'Instructions';

  @override
  String get instructionsHint => 'One step per line';

  @override
  String get servings => 'Servings';

  @override
  String get prepTime => 'Prep Time';

  @override
  String get cookTime => 'Cook Time';

  @override
  String get imageUrl => 'Image URL';

  @override
  String get keywords => 'Keywords';

  @override
  String get settings => 'Settings';

  @override
  String get syncManagement => 'Nextcloud Sync';

  @override
  String get syncNow => 'Sync Now';

  @override
  String syncComplete(String details) {
    return 'Sync complete: $details';
  }

  @override
  String get connectNextcloud => 'Connect Nextcloud';

  @override
  String get connectNextcloudHint =>
      'Link your Nextcloud Cookbook to sync recipes';

  @override
  String get disconnectAccount => 'Disconnect Account';

  @override
  String get disconnectConfirm =>
      'Disconnect from Nextcloud? Local recipes will remain.';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get noAccountLinked => 'No account linked';

  @override
  String get themeSelector => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get oledDarkTheme => 'OLED Dark';

  @override
  String get languageSelector => 'Language';

  @override
  String get about => 'About';

  @override
  String get githubRepo => 'GitHub Repository';

  @override
  String get philosophy => 'Philosophy (FOSS ❤)';

  @override
  String get philosophyTitle => 'Why SMAG?';

  @override
  String get philosophyBody =>
      'SMAG is Free and Open Source Software, built as a counter-movement to noisy, ad-filled cooking apps.\n\nYour recipes are yours. No accounts, no tracking, no cloud dependency. When you choose to sync via Nextcloud, your data stays on infrastructure you control.';

  @override
  String get shoppingList => 'Shopping List';

  @override
  String get clearGrid => 'Clear Grid';

  @override
  String get clearGridConfirm => 'Do you want to clear the entire grid?';

  @override
  String get sourceLabel => 'Source';

  @override
  String get conflictTitle => 'Sync Conflict';

  @override
  String get conflictMessage =>
      'This recipe was changed both locally and on the server. Which version do you want to keep?';

  @override
  String get keepLocal => 'Keep Local';

  @override
  String get keepServer => 'Keep Server';
}
