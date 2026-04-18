import 'package:flutter_test/flutter_test.dart';
import 'package:smag/data/recipe_database.dart';
import 'package:smag/domain/recipe.dart';
import 'package:smag/state/grid_provider.dart';

class _FakeRecipeDatabase extends RecipeDatabase {
  Map<int, int?> slots = {0: 1};
  final Map<int, Recipe> recipes = {};
  final List<int> clearedSlots = [];

  @override
  Future<Map<int, int?>> getGridSlots() async => Map<int, int?>.from(slots);

  @override
  Future<void> clearGridSlot(int position) async {
    clearedSlots.add(position);
    slots[position] = null;
  }

  @override
  Future<Recipe?> getByLocalId(int localId) async => recipes[localId];
}

void main() {
  group('GridProvider', () {
    test('clears stale slot when recipe was deleted', () async {
      final db = _FakeRecipeDatabase();
      final provider = GridProvider(db);
      await provider.load();

      var notifications = 0;
      provider.addListener(() {
        notifications++;
      });

      final recipe = await provider.recipeAt(0);

      expect(recipe, isNull);
      expect(db.clearedSlots, [0]);
      expect(provider.isFilled(0), isFalse);
      expect(provider.visibleSlotCount, 1);
      expect(notifications, greaterThanOrEqualTo(1));
    });
  });
}
