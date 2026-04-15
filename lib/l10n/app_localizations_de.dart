// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'SMAG';

  @override
  String get gridTitle => 'Deine Woche';

  @override
  String get emptySlot => 'Rezept hinzufügen';

  @override
  String get recipes => 'Rezepte';

  @override
  String get search => 'Suche';

  @override
  String get searchHint => 'Rezepte suchen…';

  @override
  String get noRecipes => 'Noch keine Rezepte. Importiere oder erstelle eines!';

  @override
  String get noResults => 'Keine Ergebnisse gefunden.';

  @override
  String get newRecipe => 'Neues Rezept';

  @override
  String get editRecipe => 'Rezept bearbeiten';

  @override
  String get deleteRecipe => 'Rezept löschen';

  @override
  String deleteConfirm(String title) {
    return 'Möchtest du \"$title\" wirklich löschen?';
  }

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get overwrite => 'Überschreiben';

  @override
  String get overwriteTitle => 'Rezept existiert';

  @override
  String overwriteMessage(String title) {
    return '\"$title\" existiert bereits. Überschreiben?';
  }

  @override
  String get importRecipe => 'Rezept importieren';

  @override
  String get importFromUrl => 'Von URL importieren';

  @override
  String get importFromText => 'Aus Text importieren';

  @override
  String get urlHint => 'Rezept-URL einfügen…';

  @override
  String get textHint => 'Rezepttext einfügen…';

  @override
  String get importing => 'Importiere…';

  @override
  String get importSuccess => 'Rezept erfolgreich importiert!';

  @override
  String get importError => 'Rezept konnte nicht importiert werden.';

  @override
  String get title => 'Titel';

  @override
  String get category => 'Kategorie';

  @override
  String get ingredients => 'Zutaten';

  @override
  String get instructions => 'Zubereitung';

  @override
  String get pickDirectory => 'Rezeptordner wählen';

  @override
  String get pickDirectoryHint =>
      'Wähle den Ordner, in dem deine Rezepte gespeichert sind.';

  @override
  String get removeFromGrid => 'Aus der Woche entfernen';

  @override
  String get assignToGrid => 'Zur Woche hinzufügen';

  @override
  String get cookMode => 'Kochmodus';

  @override
  String get servings => 'Portionen';

  @override
  String get prepTime => 'Vorbereitungszeit';

  @override
  String get cookTime => 'Kochzeit';

  @override
  String get recipePickerTitle => 'Rezept auswählen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get storageDirectory => 'Speicherort';

  @override
  String get notSet => 'Nicht festgelegt';

  @override
  String get dragToRemove => 'Hierher ziehen zum Entfernen';

  @override
  String get categoryUncategorized => 'Unkategorisiert';
}
