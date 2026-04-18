import 'package:flutter/foundation.dart';

import '../domain/recipe.dart';
import '../data/recipe_database.dart';

/// State holder for the dynamic weekly planning grid.
class GridProvider extends ChangeNotifier {
  final RecipeDatabase _db;

  Map<int, int?> _slots = {};

  GridProvider(this._db);

  /// Highest filled slot index, or -1 if grid is empty.
  int get _lastFilledIndex {
    var max = -1;
    for (final entry in _slots.entries) {
      if (entry.value != null && entry.key > max) {
        max = entry.key;
      }
    }
    return max;
  }

  /// Number of visible slots: all filled slots plus exactly one trailing empty.
  int get visibleSlotCount {
    final count = _lastFilledIndex + 2;
    return count < 1 ? 1 : count;
  }

  /// Load slot assignments from the database.
  Future<void> load() async {
    _slots = await _db.getGridSlots();
    notifyListeners();
  }

  /// The local recipe id at [index], or null if empty.
  int? recipeIdAt(int index) => _slots[index];

  bool isFilled(int index) => _slots[index] != null;

  /// Assign a recipe to a slot.
  Future<void> assign(int index, Recipe recipe) async {
    if (recipe.localId == null) return;
    await _db.setGridSlot(index, recipe.localId!);
    _slots[index] = recipe.localId;
    notifyListeners();
  }

  /// Clear a slot.
  Future<void> clear(int index) async {
    await _db.clearGridSlot(index);
    _slots[index] = null;
    notifyListeners();
  }

  /// Clear all slots.
  Future<void> clearAll() async {
    await _db.clearAllGridSlots();
    final keys = _slots.keys.toList();
    for (final k in keys) {
      _slots[k] = null;
    }
    notifyListeners();
  }

  /// Swap two slots (for drag-and-drop).
  Future<void> swap(int from, int to) async {
    if (from == to) return;
    await _db.swapGridSlots(from, to);
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
    final recipe = await _db.getByLocalId(id);
    if (recipe != null) {
      return recipe;
    }

    // The slot still points to a deleted recipe. Clear it immediately so the
    // grid updates without waiting for a full reload.
    await _db.clearGridSlot(index);
    _slots[index] = null;
    notifyListeners();
    return null;
  }
}
