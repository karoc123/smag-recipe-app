/// Hugo-compatible recipe model backed by TOML frontmatter + Markdown body.
class RecipeEntity {
  final String title;
  final DateTime date;
  final String category;
  final String? imagePath; // relative, e.g. "/images/foo.jpg"
  final String? servings;
  final String? prepTime;
  final String? cookTime;
  final String body; // raw Markdown below the frontmatter

  /// Relative path from the storage root, e.g. "Desserts/chocolate-cake.md"
  final String? relativePath;

  RecipeEntity({
    required this.title,
    DateTime? date,
    this.category = '',
    this.imagePath,
    this.servings,
    this.prepTime,
    this.cookTime,
    this.body = '',
    this.relativePath,
  }) : date = date ?? DateTime.now();

  RecipeEntity copyWith({
    String? title,
    DateTime? date,
    String? category,
    String? imagePath,
    String? servings,
    String? prepTime,
    String? cookTime,
    String? body,
    String? relativePath,
  }) {
    return RecipeEntity(
      title: title ?? this.title,
      date: date ?? this.date,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      servings: servings ?? this.servings,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      body: body ?? this.body,
      relativePath: relativePath ?? this.relativePath,
    );
  }

  /// Derives a filename-safe slug from the title.
  String get slug {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9äöüß]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeEntity &&
          runtimeType == other.runtimeType &&
          relativePath == other.relativePath;

  @override
  int get hashCode => relativePath.hashCode;
}
