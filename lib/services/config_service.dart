import '../data/recipe_database.dart';

/// Manages grid slot persistence using SQLite.
///
/// This replaces the old TOML-based config file with a cleaner database-backed
/// approach. The grid always has exactly 7 slots.
class ConfigService {
  final RecipeDatabase _db;

  static const int slotCount = 7;

  ConfigService(this._db);

  Future<Map<int, int?>> getSlots() => _db.getGridSlots();

  Future<void> setSlot(int position, int recipeId) =>
      _db.setGridSlot(position, recipeId);

  Future<void> clearSlot(int position) => _db.clearGridSlot(position);

  Future<void> swapSlots(int a, int b) => _db.swapGridSlots(a, b);

  Future<void> removeRecipeFromSlots(int recipeId) =>
      _db.removeRecipeFromGrid(recipeId);
}
