import 'package:http/http.dart' as http;

import 'recipe_parser.dart';
import '../domain/recipe.dart';

class RecipeImportService {
  final http.Client _httpClient;
  final RecipeParser _parser;

  RecipeImportService(this._httpClient, this._parser);

  Future<ParsedUrlImport> importFromUrl(String url) async {
    final response = await _httpClient.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    return _parser.parseHtmlWithCandidates(response.body, sourceUrl: url);
  }

  Recipe importFromText(String text) {
    return _parser.parsePlainText(text);
  }
}
