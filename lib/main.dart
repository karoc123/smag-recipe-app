import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/nextcloud_api.dart';
import 'data/nextcloud_sso.dart';
import 'data/recipe_database.dart';
import 'services/config_service.dart';
import 'services/recipe_parser.dart';
import 'services/sync_service.dart';
import 'state/grid_provider.dart';
import 'state/recipe_provider.dart';
import 'state/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Transparent status bar with dark icons.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Core services
  final db = RecipeDatabase();
  final parser = RecipeParser();
  final sso = NextcloudSso();
  final api = NextcloudApi(sso);
  final configService = ConfigService(db);
  final syncService = SyncService(db, api, sso);

  // State providers
  final settingsProvider = SettingsProvider(sso);
  await settingsProvider.init();

  final recipeProvider = RecipeProvider(db, parser);
  await recipeProvider.loadRecipes();

  final gridProvider = GridProvider(configService, db);
  await gridProvider.load();

  runApp(
    MultiProvider(
      providers: [
        Provider<RecipeDatabase>.value(value: db),
        Provider<RecipeParser>.value(value: parser),
        Provider<NextcloudSso>.value(value: sso),
        Provider<NextcloudApi>.value(value: api),
        Provider<ConfigService>.value(value: configService),
        Provider<SyncService>.value(value: syncService),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
        ChangeNotifierProvider<GridProvider>.value(value: gridProvider),
      ],
      child: const SmagApp(),
    ),
  );
}
