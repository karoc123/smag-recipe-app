import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smag/data/file_repository.dart';
import 'package:smag/domain/recipe_entity.dart';
import 'package:smag/services/config_service.dart';
import 'package:smag/services/recipe_parser.dart';
import 'package:smag/services/search_service.dart';
import 'package:smag/state/recipe_provider.dart';

class ThrowingFileRepository extends FileRepository {
  ThrowingFileRepository(super.parser);

  @override
  Future<List<RecipeEntity>> loadAll(String rootDir) async {
    throw Exception('load failed');
  }
}

class FakeSearchService extends SearchService {
  @override
  Future<void> rebuildIndex(List<RecipeEntity> recipes) async {}

  @override
  Future<void> upsertRecipe(RecipeEntity recipe) async {}

  @override
  Future<void> removeRecipe(String relativePath) async {}

  @override
  Future<List<String>> search(String query) async => const [];
}

void main() {
  group('RecipeProvider', () {
    late Directory tempDir;
    late RecipeParser parser;
    late ConfigService config;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('smag-provider-test-');
      parser = RecipeParser();
      config = ConfigService();
      await config.init(tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loadRecipes resets loading flag after error', () async {
      final provider = RecipeProvider(
        ThrowingFileRepository(parser),
        parser,
        config,
        FakeSearchService(),
      );

      expect(provider.loading, isFalse);

      await expectLater(provider.loadRecipes(), throwsException);
      expect(provider.loading, isFalse);
    });

    test('saveRecipe writes and updates provider state', () async {
      final provider = RecipeProvider(
        FileRepository(parser),
        parser,
        config,
        FakeSearchService(),
      );

      final saved = await provider.saveRecipe(
        RecipeEntity(
          title: 'Marmorkuchen',
          category: 'Kuchen',
          body: '## Ingredients\n- Zucker',
        ),
      );

      expect(saved.relativePath, isNotNull);
      expect(provider.recipes.any((r) => r.title == 'Marmorkuchen'), isTrue);
      expect(provider.categories.contains('Kuchen'), isTrue);

      final file = File('${tempDir.path}/${saved.relativePath!}');
      expect(await file.exists(), isTrue);
    });
  });
}
