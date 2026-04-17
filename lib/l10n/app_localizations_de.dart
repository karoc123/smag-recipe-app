// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Simple Meal Archive Gallery';

  @override
  String get recipes => 'Rezepte';

  @override
  String get grid => 'Wochenplan';

  @override
  String get search => 'Suche';

  @override
  String get allRecipes => 'Alle Gerichte';

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
  String get syncLogTitle => 'Synchronisierungsprotokoll';

  @override
  String get syncLogEmpty => 'Noch keine Synchronisierungsereignisse.';

  @override
  String get syncCanceled =>
      'Die Synchronisierung wurde vor der vollständigen Konfliktauflösung abgebrochen.';

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
  String get clearGrid => 'Grid leeren';

  @override
  String get clearGridConfirm => 'Möchtest du das gesamte Grid leeren?';

  @override
  String get sourceLabel => 'Quelle';

  @override
  String get conflictTitle => 'Synchronisierungskonflikt';

  @override
  String get conflictMessage =>
      'Dieses Rezept wurde lokal und auf dem Server geändert. Welche Version möchtest du behalten?';

  @override
  String get conflictFieldDifferences => 'Unterschiedliche Felder';

  @override
  String get conflictLocalLabel => 'Lokal';

  @override
  String get conflictServerLabel => 'Server';

  @override
  String get conflictNoServerData =>
      'Die Server-Version konnte nicht geladen werden. Du kannst trotzdem eine Seite wählen.';

  @override
  String get conflictNoFieldDifferences =>
      'Keine Unterschiede auf Feldebene erkannt.';

  @override
  String get keepLocal => 'Lokale Version';

  @override
  String get keepServer => 'Server-Version';

  @override
  String get cancelSync => 'Sync abbrechen';

  @override
  String get skipConflict => 'Überspringen';

  @override
  String get importing => 'Importiere…';

  @override
  String get errorTitle => 'Fehler';

  @override
  String get syncErrorTitle => 'Synchronisierungsfehler';

  @override
  String get copyError => 'Fehler kopieren';

  @override
  String get errorCopied => 'Fehlerdetails in Zwischenablage kopiert';

  @override
  String get error409RecipeExists =>
      'Ein Rezept mit diesem Namen existiert bereits auf dem Server. Bitte benenne das Rezept um und versuche es erneut.';

  @override
  String get error401Unauthorized =>
      'Authentifizierung fehlgeschlagen. Bitte verbinde dein Nextcloud-Konto erneut.';

  @override
  String get error404NotFound =>
      'Die angeforderte Ressource wurde nicht auf dem Server gefunden.';

  @override
  String get error500Server =>
      'Der Nextcloud-Server hat einen internen Fehler. Bitte versuche es später erneut.';

  @override
  String get errorNetwork =>
      'Der Server ist nicht erreichbar. Bitte prüfe deine Internetverbindung.';

  @override
  String get errorUnknown => 'Ein unerwarteter Fehler ist aufgetreten.';
}
