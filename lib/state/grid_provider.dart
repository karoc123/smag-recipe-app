import 'package:flutter/foundation.dart';

import '../services/config_service.dart';
import '../domain/recipe.dart';
import '../data/recipe_database.dart';

/// State holder for the 7-slot weekly planning grid.
class GridProvider extends ChangeNotifier {
  final ConfigService _config;
  final RecipeDatabase _db;

  Map<int, int?> _slots = {};

  GridProvider(this._config, this._db);

  int get slotCount => ConfigService.slotCount;

  /// Load slot assignments from the database.
  Future<void> load() async {
    _slots = await _config.getSlots();
    notifyListeners();
  }

  /// The local recipe id at [index], or null if empty.
  int? recipeIdAt(int index) => _slots[index];

  bool isFilled(int index) => _slots[index] != null;

  /// Assign a recipe to a slot.
  Future<void> assign(int index, Recipe recipe) async {
    if (recipe.localId == null) return;
    await _config.setSlot(index, recipe.localId!);
    _slots[index] = recipe.localId;
    notifyListeners();
  }

  /// Clear a slot.
  Future<void> clear(int index) async {
    await _config.clearSlot(index);
    _slots[index] = null;
    notifyListeners();
  }

  /// Clear all slots.
  Future<void> clearAll() async {
    for (int i = 0; i < slotCount; i++) {
      await _config.clearSlot(i);
      _slots[i] = null;
    }
    notifyListeners();
  }

  /// Swap two slots (for drag-and-drop).
  Future<void> swap(int from, int to) async {
    await _config.swapSlots(from, to);
    final tmp = _slots[from];
    _slots[from] = _slots[to];
    _slots[to] = tmp;
    notifyListeners();
  }

  /// Resolve the full recipe for a slot. Returns null if the slot is empty or
  /// the recipe was deleted.
  Future<Recipe?> recipeAt(int index) async {
    final id = _slots[index];
    if (id == null) return null;
    return _db.getByLocalId(id);
  }
}
