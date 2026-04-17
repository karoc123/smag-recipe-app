/// Recipe model aligned with the Nextcloud Cookbook (schema.org) JSON format.
///
/// Field names mirror the API so round-tripping is lossless. Helper getters
/// expose a friendlier Dart API where useful.
class Recipe {
  /// Local auto-increment id (null until persisted locally).
  final int? localId;

  /// Nextcloud remote id (null for local-only recipes).
  final int? remoteId;

  final String name;
  final String description;
  final String url;
  final String image;
  final String localImagePath;
  final String prepTime;
  final String cookTime;
  final String totalTime;
  final String recipeCategory;
  final String keywords;
  final String recipeYield;
  final List<String> tool;
  final List<String> recipeIngredient;
  final List<String> recipeInstructions;
  final String dateCreated;
  final String dateModified;

  const Recipe({
    this.localId,
    this.remoteId,
    this.name = '',
    this.description = '',
    this.url = '',
    this.image = '',
    this.localImagePath = '',
    this.prepTime = '',
    this.cookTime = '',
    this.totalTime = '',
    this.recipeCategory = '',
    this.keywords = '',
    this.recipeYield = '',
    this.tool = const [],
    this.recipeIngredient = const [],
    this.recipeInstructions = const [],
    this.dateCreated = '',
    this.dateModified = '',
  });

  // ---------------------------------------------------------------------------
  // JSON round-trip
  // ---------------------------------------------------------------------------

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      remoteId: _toInt(json['id']),
      name: _str(json['name']),
      description: _str(json['description']),
      url: _str(json['url']),
      image: _str(json['image']),
      prepTime: _str(json['prepTime']),
      cookTime: _str(json['cookTime']),
      totalTime: _str(json['totalTime']),
      recipeCategory: _str(json['recipeCategory']),
      keywords: _str(json['keywords']),
      recipeYield: _str(json['recipeYield']),
      tool: _strList(json['tool']),
      recipeIngredient: _strList(json['recipeIngredient']),
      recipeInstructions: _instructionsList(json['recipeInstructions']),
      dateCreated: _str(json['dateCreated']),
      dateModified: _str(json['dateModified']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (remoteId != null) 'id': remoteId,
      'name': name,
      'description': description,
      'url': url,
      'image': image,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'totalTime': totalTime,
      'recipeCategory': recipeCategory,
      'keywords': keywords,
      'recipeYield': recipeYield,
      'tool': tool,
      'recipeIngredient': recipeIngredient,
      'recipeInstructions': recipeInstructions,
      'dateCreated': dateCreated,
      'dateModified': dateModified,
    };
  }

  // ---------------------------------------------------------------------------
  // Copy helpers
  // ---------------------------------------------------------------------------

  Recipe copyWith({
    int? localId,
    int? remoteId,
    String? name,
    String? description,
    String? url,
    String? image,
    String? localImagePath,
    String? prepTime,
    String? cookTime,
    String? totalTime,
    String? recipeCategory,
    String? keywords,
    String? recipeYield,
    List<String>? tool,
    List<String>? recipeIngredient,
    List<String>? recipeInstructions,
    String? dateCreated,
    String? dateModified,
  }) {
    return Recipe(
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      image: image ?? this.image,
      localImagePath: localImagePath ?? this.localImagePath,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      totalTime: totalTime ?? this.totalTime,
      recipeCategory: recipeCategory ?? this.recipeCategory,
      keywords: keywords ?? this.keywords,
      recipeYield: recipeYield ?? this.recipeYield,
      tool: tool ?? this.tool,
      recipeIngredient: recipeIngredient ?? this.recipeIngredient,
      recipeInstructions: recipeInstructions ?? this.recipeInstructions,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
    );
  }

  // ---------------------------------------------------------------------------
  // Convenience
  // ---------------------------------------------------------------------------

  /// A display-ready category; falls back to "Uncategorized" if empty.
  String get displayCategory =>
      recipeCategory.isEmpty ? 'Uncategorized' : recipeCategory;

  /// Whether this recipe has ever been pushed / pulled from Nextcloud.
  bool get isRemote => remoteId != null;

  /// Best local or remote image reference for display in the UI.
  String get displayImage => localImagePath.isNotEmpty ? localImagePath : image;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe && localId == other.localId && remoteId == other.remoteId;

  @override
  int get hashCode => Object.hash(localId, remoteId);

  @override
  String toString() => 'Recipe(localId=$localId, remoteId=$remoteId, "$name")';

  // ---------------------------------------------------------------------------
  // Private helpers for lenient JSON parsing
  // ---------------------------------------------------------------------------

  static String _str(dynamic v) {
    if (v == null) return '';
    return v.toString();
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static List<String> _strList(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v
          .map((e) {
            if (e is Map) {
              final text = _str(e['text']);
              if (text.isNotEmpty) return text;
              return _str(e['name']);
            }
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (v is Map) {
      // schema.org can nest list items in itemListElement.
      final nested = v['itemListElement'];
      if (nested != null) return _strList(nested);
      final text = _str(v['text']);
      if (text.isNotEmpty) return [text];
      final name = _str(v['name']);
      if (name.isNotEmpty) return [name];
    }
    if (v is String) return v.isEmpty ? [] : [v];
    return [];
  }

  /// Instructions can arrive as a list of strings *or* a list of objects with
  /// a `text` field (schema.org HowToStep).
  static List<String> _instructionsList(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v
          .expand((e) {
            if (e is Map) {
              final direct = _str(e['text']);
              if (direct.isNotEmpty) return [direct];

              final name = _str(e['name']);
              if (name.isNotEmpty) return [name];

              final nested = e['itemListElement'];
              if (nested != null) return _instructionsList(nested);
              return <String>[];
            }
            final s = e.toString();
            return s.isEmpty ? <String>[] : [s];
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (v is Map) {
      final direct = _str(v['text']);
      if (direct.isNotEmpty) return [direct];
      final nested = v['itemListElement'];
      if (nested != null) return _instructionsList(nested);
    }
    if (v is String) return v.isEmpty ? [] : [v];
    return [];
  }
}

/// Tracks sync state for a locally stored recipe.
enum SyncStatus {
  /// Only exists locally (or no Nextcloud account linked).
  localOnly,

  /// In sync with the server.
  synced,

  /// Modified locally since last sync.
  pendingUpload,

  /// Both local and remote have changes.
  conflict,
}
