import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/file_repository.dart';
import 'services/config_service.dart';
import 'services/recipe_parser.dart';
import 'services/search_service.dart';
import 'services/webdav_sync_service.dart';
import 'state/grid_provider.dart';
import 'state/recipe_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prefer edge-to-edge, light status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Core services
  final parser = RecipeParser();
  final configService = ConfigService();
  final searchService = SearchService();
  final fileRepository = FileRepository(parser);
  final webDavSyncService = WebDavSyncService();

  // Initialize search asynchronously so a DB init issue cannot block first frame.
  unawaited(searchService.init());

  // Use app-private internal storage root for Play Store compliant, permissionless I/O.
  final documentsDir = await getApplicationDocumentsDirectory();
  final rootDir = p.join(documentsDir.path, 'smag_data');
  final root = Directory(rootDir);
  if (!await root.exists()) {
    await root.create(recursive: true);
  }
  await configService.init(rootDir);

  runApp(
    MultiProvider(
      providers: [
        Provider<RecipeParser>.value(value: parser),
        Provider<ConfigService>.value(value: configService),
        Provider<SearchService>.value(value: searchService),
        Provider<WebDavSyncService>.value(value: webDavSyncService),
        Provider<FileRepository>.value(value: fileRepository),
        ChangeNotifierProvider(
          create: (_) {
            final provider = RecipeProvider(
              fileRepository,
              parser,
              configService,
              searchService,
            );
            provider.loadRecipes();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => GridProvider(configService)),
      ],
      child: const SmagApp(),
    ),
  );
}
