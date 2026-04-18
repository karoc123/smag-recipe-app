import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Simple Meal Archive Gallery'**
  String get appTitle;

  /// No description provided for @recipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipes;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @allRecipes.
  ///
  /// In en, this message translates to:
  /// **'All Recipes'**
  String get allRecipes;

  /// No description provided for @noRecipes.
  ///
  /// In en, this message translates to:
  /// **'No recipes yet. Import or create one!'**
  String get noRecipes;

  /// No description provided for @newRecipe.
  ///
  /// In en, this message translates to:
  /// **'New Recipe'**
  String get newRecipe;

  /// No description provided for @editRecipe.
  ///
  /// In en, this message translates to:
  /// **'Edit Recipe'**
  String get editRecipe;

  /// No description provided for @deleteRecipe.
  ///
  /// In en, this message translates to:
  /// **'Delete Recipe'**
  String get deleteRecipe;

  /// No description provided for @deleteRecipeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this recipe?'**
  String get deleteRecipeConfirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importTitle;

  /// No description provided for @importFromUrl.
  ///
  /// In en, this message translates to:
  /// **'From URL'**
  String get importFromUrl;

  /// No description provided for @importFromText.
  ///
  /// In en, this message translates to:
  /// **'From Text'**
  String get importFromText;

  /// No description provided for @importButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importButton;

  /// No description provided for @importLocally.
  ///
  /// In en, this message translates to:
  /// **'Import Locally'**
  String get importLocally;

  /// No description provided for @sendToNextcloud.
  ///
  /// In en, this message translates to:
  /// **'Send to Nextcloud'**
  String get sendToNextcloud;

  /// No description provided for @sentToNextcloud.
  ///
  /// In en, this message translates to:
  /// **'Recipe sent to Nextcloud'**
  String get sentToNextcloud;

  /// No description provided for @importedRecipe.
  ///
  /// In en, this message translates to:
  /// **'Imported recipe'**
  String get importedRecipe;

  /// No description provided for @copyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Copy Prompt'**
  String get copyPrompt;

  /// No description provided for @promptCopied.
  ///
  /// In en, this message translates to:
  /// **'Prompt copied to clipboard'**
  String get promptCopied;

  /// No description provided for @pasteRecipeHint.
  ///
  /// In en, this message translates to:
  /// **'Paste JSON or recipe text here…'**
  String get pasteRecipeHint;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @ingredientsHint.
  ///
  /// In en, this message translates to:
  /// **'One ingredient per line'**
  String get ingredientsHint;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @instructionsHint.
  ///
  /// In en, this message translates to:
  /// **'One step per line'**
  String get instructionsHint;

  /// No description provided for @servings.
  ///
  /// In en, this message translates to:
  /// **'Servings'**
  String get servings;

  /// No description provided for @prepTime.
  ///
  /// In en, this message translates to:
  /// **'Prep Time'**
  String get prepTime;

  /// No description provided for @cookTime.
  ///
  /// In en, this message translates to:
  /// **'Cook Time'**
  String get cookTime;

  /// No description provided for @imageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrl;

  /// No description provided for @keywords.
  ///
  /// In en, this message translates to:
  /// **'Keywords'**
  String get keywords;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @syncManagement.
  ///
  /// In en, this message translates to:
  /// **'Nextcloud Sync'**
  String get syncManagement;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @syncLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Log'**
  String get syncLogTitle;

  /// No description provided for @syncLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sync log entries yet.'**
  String get syncLogEmpty;

  /// No description provided for @syncCanceled.
  ///
  /// In en, this message translates to:
  /// **'Sync was canceled before all conflicts were resolved.'**
  String get syncCanceled;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync complete: {details}'**
  String syncComplete(String details);

  /// No description provided for @cookbookFolderOverrideTitle.
  ///
  /// In en, this message translates to:
  /// **'Cookbook Folder Override'**
  String get cookbookFolderOverrideTitle;

  /// No description provided for @cookbookFolderOverrideField.
  ///
  /// In en, this message translates to:
  /// **'Folder Path'**
  String get cookbookFolderOverrideField;

  /// No description provided for @cookbookFolderOverrideHint.
  ///
  /// In en, this message translates to:
  /// **'Optional path (for example /Recipes). Leave empty to use the folder from Nextcloud config.'**
  String get cookbookFolderOverrideHint;

  /// No description provided for @cookbookFolderUsesServerConfig.
  ///
  /// In en, this message translates to:
  /// **'Using folder from Nextcloud config'**
  String get cookbookFolderUsesServerConfig;

  /// No description provided for @cookbookFolderOverrideActive.
  ///
  /// In en, this message translates to:
  /// **'Manual override active: {path}'**
  String cookbookFolderOverrideActive(String path);

  /// No description provided for @cookbookFolderOverrideWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual folder override enabled'**
  String get cookbookFolderOverrideWarningTitle;

  /// No description provided for @cookbookFolderOverrideWarningBody.
  ///
  /// In en, this message translates to:
  /// **'This value normally comes from Nextcloud Cookbook. Use an override only for troubleshooting.'**
  String get cookbookFolderOverrideWarningBody;

  /// No description provided for @useServerFolder.
  ///
  /// In en, this message translates to:
  /// **'Use Server Folder'**
  String get useServerFolder;

  /// No description provided for @cookbookFolderOverrideInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid folder path.'**
  String get cookbookFolderOverrideInvalid;

  /// No description provided for @connectNextcloud.
  ///
  /// In en, this message translates to:
  /// **'Connect Nextcloud'**
  String get connectNextcloud;

  /// No description provided for @connectNextcloudHint.
  ///
  /// In en, this message translates to:
  /// **'Link your Nextcloud Cookbook to sync recipes'**
  String get connectNextcloudHint;

  /// No description provided for @disconnectAccount.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Account'**
  String get disconnectAccount;

  /// No description provided for @disconnectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from Nextcloud? Local recipes will remain.'**
  String get disconnectConfirm;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @noAccountLinked.
  ///
  /// In en, this message translates to:
  /// **'No account linked'**
  String get noAccountLinked;

  /// No description provided for @themeSelector.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSelector;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @oledDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'OLED Dark'**
  String get oledDarkTheme;

  /// No description provided for @languageSelector.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSelector;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @githubRepo.
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get githubRepo;

  /// No description provided for @philosophy.
  ///
  /// In en, this message translates to:
  /// **'Philosophy (FOSS ❤)'**
  String get philosophy;

  /// No description provided for @philosophyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why SMAG?'**
  String get philosophyTitle;

  /// No description provided for @philosophyBody.
  ///
  /// In en, this message translates to:
  /// **'SMAG is Free and Open Source Software, built as a counter-movement to noisy, ad-filled cooking apps.\n\nYour recipes are yours. No accounts, no tracking, no cloud dependency. When you choose to sync via Nextcloud, your data stays on infrastructure you control.'**
  String get philosophyBody;

  /// No description provided for @shoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get shoppingList;

  /// No description provided for @clearGrid.
  ///
  /// In en, this message translates to:
  /// **'Clear Grid'**
  String get clearGrid;

  /// No description provided for @clearGridConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to clear the entire grid?'**
  String get clearGridConfirm;

  /// No description provided for @sourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceLabel;

  /// No description provided for @conflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Conflict'**
  String get conflictTitle;

  /// No description provided for @conflictMessage.
  ///
  /// In en, this message translates to:
  /// **'This recipe was changed both locally and on the server. Which version do you want to keep?'**
  String get conflictMessage;

  /// No description provided for @conflictFieldDifferences.
  ///
  /// In en, this message translates to:
  /// **'Field differences'**
  String get conflictFieldDifferences;

  /// No description provided for @conflictLocalLabel.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get conflictLocalLabel;

  /// No description provided for @conflictServerLabel.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get conflictServerLabel;

  /// No description provided for @conflictNoServerData.
  ///
  /// In en, this message translates to:
  /// **'Server version could not be loaded. You can still choose a side.'**
  String get conflictNoServerData;

  /// No description provided for @conflictNoFieldDifferences.
  ///
  /// In en, this message translates to:
  /// **'No field-level differences detected.'**
  String get conflictNoFieldDifferences;

  /// No description provided for @keepLocal.
  ///
  /// In en, this message translates to:
  /// **'Keep Local'**
  String get keepLocal;

  /// No description provided for @keepServer.
  ///
  /// In en, this message translates to:
  /// **'Keep Server'**
  String get keepServer;

  /// No description provided for @cancelSync.
  ///
  /// In en, this message translates to:
  /// **'Cancel Sync'**
  String get cancelSync;

  /// No description provided for @skipConflict.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipConflict;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get importing;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @syncErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Error'**
  String get syncErrorTitle;

  /// No description provided for @copyError.
  ///
  /// In en, this message translates to:
  /// **'Copy Error'**
  String get copyError;

  /// No description provided for @errorCopied.
  ///
  /// In en, this message translates to:
  /// **'Error details copied to clipboard'**
  String get errorCopied;

  /// No description provided for @error409RecipeExists.
  ///
  /// In en, this message translates to:
  /// **'A recipe with this name already exists on the server. Please rename the recipe and try again.'**
  String get error409RecipeExists;

  /// No description provided for @error401Unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please reconnect your Nextcloud account.'**
  String get error401Unauthorized;

  /// No description provided for @error404NotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested resource was not found on the server.'**
  String get error404NotFound;

  /// No description provided for @error500Server.
  ///
  /// In en, this message translates to:
  /// **'The Nextcloud server encountered an internal error. Please try again later.'**
  String get error500Server;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Please check your internet connection.'**
  String get errorNetwork;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get errorUnknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
