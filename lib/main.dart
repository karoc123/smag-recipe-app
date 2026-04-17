import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/nextcloud_api.dart';
import 'data/nextcloud_sso.dart';
import 'data/recipe_database.dart';
import 'services/managed_recipe_image_store.dart';
import 'services/recipe_image_cache.dart';
import 'services/recipe_import_service.dart';
import 'services/recipe_parser.dart';
import 'services/recipe_remote_gateway.dart';
import 'services/sync_service.dart';
import 'state/grid_provider.dart';
import 'state/recipe_provider.dart';
import 'state/settings_provider.dart';

Future<void> main() async {
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
  final httpClient = http.Client();
  final sso = NextcloudSso();
  final api = NextcloudApi(sso);
  final importService = RecipeImportService(httpClient, parser);
  final remoteGateway = NextcloudRecipeRemoteGateway(api, sso);
  final imageCache = FileRecipeImageCache();
  final imageStore = FileManagedRecipeImageStore();
  final syncService = SyncService(db, remoteGateway, imageCache);

  // State providers
  final settingsProvider = SettingsProvider(sso);
  await settingsProvider.init();

  final recipeProvider = RecipeProvider(db, imageStore);
  await recipeProvider.loadRecipes();

  final gridProvider = GridProvider(db);
  await gridProvider.load();

  runApp(
    MultiProvider(
      providers: [
        Provider<RecipeDatabase>.value(value: db),
        Provider<NextcloudSso>.value(value: sso),
        Provider<NextcloudApi>.value(value: api),
        Provider<RecipeImportService>.value(value: importService),
        Provider<RecipeRemoteGateway>.value(value: remoteGateway),
        Provider<ManagedRecipeImageStore>.value(value: imageStore),
        Provider<RecipeImageCache>.value(value: imageCache),
        Provider<SyncService>.value(value: syncService),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
        ChangeNotifierProvider<GridProvider>.value(value: gridProvider),
      ],
      child: const SmagApp(),
    ),
  );
}
