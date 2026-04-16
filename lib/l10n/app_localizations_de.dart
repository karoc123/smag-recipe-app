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
  String get recipes => 'Rezepte';

  @override
  String get grid => 'Wochenplan';

  @override
  String get search => 'Suche';

  @override
  String get noRecipes => 'Noch keine Rezepte. Importiere oder erstelle eines!';

  @override
  String get newRecipe => 'Neues Rezept';

  @override
  String get editRecipe => 'Rezept bearbeiten';

  @override
  String get deleteRecipe => 'Rezept löschen';

  @override
  String get deleteRecipeConfirm =>
      'Möchtest du dieses Rezept wirklich löschen?';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get close => 'Schließen';

  @override
  String get importTitle => 'Import';

  @override
  String get importFromUrl => 'Von URL';

  @override
  String get importFromText => 'Aus Text';

  @override
  String get importButton => 'Importieren';

  @override
  String get importLocally => 'Lokal importieren';

  @override
  String get sendToNextcloud => 'An Nextcloud senden';

  @override
  String get sentToNextcloud => 'Rezept an Nextcloud gesendet';

  @override
  String get importedRecipe => 'Importiertes Rezept';

  @override
  String get copyPrompt => 'Prompt kopieren';

  @override
  String get promptCopied => 'Prompt in Zwischenablage kopiert';

  @override
  String get pasteRecipeHint => 'JSON oder Rezepttext hier einfügen…';

  @override
  String get selectImage => 'Bild auswählen';

  @override
  String get skip => 'Überspringen';

  @override
  String get title => 'Titel';

  @override
  String get titleRequired => 'Titel ist erforderlich';

  @override
  String get category => 'Kategorie';

  @override
  String get description => 'Beschreibung';

  @override
  String get ingredients => 'Zutaten';

  @override
  String get ingredientsHint => 'Eine Zutat pro Zeile';

  @override
  String get instructions => 'Zubereitung';

  @override
  String get instructionsHint => 'Ein Schritt pro Zeile';

  @override
  String get servings => 'Portionen';

  @override
  String get prepTime => 'Vorbereitungszeit';

  @override
  String get cookTime => 'Kochzeit';

  @override
  String get imageUrl => 'Bild-URL';

  @override
  String get keywords => 'Schlagwörter';

  @override
  String get settings => 'Einstellungen';

  @override
  String get syncManagement => 'Nextcloud-Synchronisierung';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String syncComplete(String details) {
    return 'Synchronisierung abgeschlossen: $details';
  }

  @override
  String get connectNextcloud => 'Nextcloud verbinden';

  @override
  String get connectNextcloudHint =>
      'Verknüpfe dein Nextcloud Cookbook, um Rezepte zu synchronisieren';

  @override
  String get disconnectAccount => 'Konto trennen';

  @override
  String get disconnectConfirm =>
      'Von Nextcloud trennen? Lokale Rezepte bleiben erhalten.';

  @override
  String get disconnect => 'Trennen';

  @override
  String get noAccountLinked => 'Kein Konto verknüpft';

  @override
  String get themeSelector => 'Design';

  @override
  String get lightTheme => 'Hell';

  @override
  String get oledDarkTheme => 'OLED Dunkel';

  @override
  String get languageSelector => 'Sprache';

  @override
  String get about => 'Über';

  @override
  String get githubRepo => 'GitHub-Repository';

  @override
  String get philosophy => 'Philosophie (FOSS ❤)';

  @override
  String get philosophyTitle => 'Warum SMAG?';

  @override
  String get philosophyBody =>
      'SMAG ist freie und quelloffene Software – entwickelt als Gegenbewegung zu lauten, werbeüberladenen Koch-Apps.\n\nDeine Rezepte gehören dir. Keine Konten, kein Tracking, keine Cloud-Abhängigkeit. Wenn du über Nextcloud synchronisierst, bleiben deine Daten auf Infrastruktur, die du kontrollierst.';

  @override
  String get shoppingList => 'Einkaufsliste';

  @override
  String get conflictTitle => 'Synchronisierungskonflikt';

  @override
  String get conflictMessage =>
      'Dieses Rezept wurde lokal und auf dem Server geändert. Welche Version möchtest du behalten?';

  @override
  String get keepLocal => 'Lokale Version';

  @override
  String get keepServer => 'Server-Version';
}
