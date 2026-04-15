import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smag/data/file_repository.dart';
import 'package:smag/domain/recipe_entity.dart';
import 'package:smag/l10n/app_localizations.dart';
import 'package:smag/services/config_service.dart';
import 'package:smag/services/recipe_parser.dart';
import 'package:smag/services/search_service.dart';
import 'package:smag/state/recipe_provider.dart';
import 'package:smag/ui/recipe_picker_dialog.dart';

class DummyFileRepository extends FileRepository {
  DummyFileRepository(super.parser);
}

class DummySearchService extends SearchService {
  @override
  Future<void> rebuildIndex(List<RecipeEntity> recipes) async {}

  @override
  Future<void> upsertRecipe(RecipeEntity recipe) async {}

  @override
  Future<void> removeRecipe(String relativePath) async {}

  @override
  Future<List<String>> search(String query) async => const [];
}

class InMemoryRecipeProvider extends RecipeProvider {
  final List<RecipeEntity> _items;

  InMemoryRecipeProvider(this._items)
    : super(
        DummyFileRepository(RecipeParser()),
        RecipeParser(),
        ConfigService(),
        DummySearchService(),
      );

  @override
  List<RecipeEntity> get recipes => List.unmodifiable(_items);
}

void main() {
  testWidgets('recipe picker remains renderable with keyboard inset', (
    tester,
  ) async {
    final provider = InMemoryRecipeProvider([
      RecipeEntity(title: 'Apfelkuchen', category: 'Kuchen', body: 'Test'),
    ]);

    await tester.pumpWidget(
      ChangeNotifierProvider<RecipeProvider>.value(
        value: provider,
        child: MediaQuery(
          data: const MediaQueryData(
            viewInsets: EdgeInsets.only(bottom: 320),
            padding: EdgeInsets.only(bottom: 24),
          ),
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: RecipePickerDialog()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(RecipePickerDialog), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
