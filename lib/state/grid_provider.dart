import 'package:flutter/foundation.dart';

import '../domain/recipe_entity.dart';
import '../services/config_service.dart';

/// State holder for the 7-slot weekly grid.
class GridProvider extends ChangeNotifier {
  final ConfigService _config;

  GridProvider(this._config);

  List<String> get slots => _config.slots;
  int get slotCount => _config.slots.length;

  /// Assign a recipe to an empty slot.
  Future<void> assign(int index, RecipeEntity recipe) async {
    if (recipe.relativePath == null) return;
    await _config.setSlot(index, recipe.relativePath!);
    notifyListeners();
  }

  /// Remove a recipe from a slot (the intuitive "drag-to-remove" or long-press).
  Future<void> clear(int index) async {
    await _config.clearSlot(index);
    notifyListeners();
  }

  /// Swap two slots during drag-and-drop reorder.
  Future<void> swap(int from, int to) async {
    await _config.swapSlots(from, to);
    notifyListeners();
  }

  /// Check if a specific slot is filled.
  bool isFilled(int index) => slots[index].isNotEmpty;

  /// Get the relative path for a slot, or null if empty.
  String? pathAt(int index) {
    final val = slots[index];
    return val.isEmpty ? null : val;
  }
}
