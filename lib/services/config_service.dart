import 'dart:io';

/// Manages the app-level `config.toml` that lives at the root of the
/// user-selected storage directory.
///
/// The file stores the 7-slot grid mapping and the storage path itself
/// (persisted via shared_preferences so we know where to find it on next launch).
///
/// Format:
/// ```toml
/// [grid]
/// slots = ["Desserts/cake.md", "", "", "", "", "", ""]
/// ```
class ConfigService {
  static const int minVisibleSlots = 1;

  String? _rootDir;

  /// Current storage root.  `null` until the user picks a directory.
  String? get rootDir => _rootDir;

  /// The in-memory slot array with exactly one trailing empty slot.
  List<String> _slots = [''];

  List<String> get slots => List.unmodifiable(_slots);

  /// Initialise with a known root directory (e.g. from shared preferences).
  Future<void> init(String rootDir) async {
    _rootDir = rootDir;
    await _load();
  }

  // ─────────────────────────── Slot mutations ───────────────────────────

  /// Assign [relativePath] to the given 0-based [index].
  Future<void> setSlot(int index, String relativePath) async {
    if (relativePath.isEmpty) return;
    _ensureIndex(index);

    // Keep each recipe only once in the grid.
    _slots.removeWhere((s) => s == relativePath);

    _ensureIndex(index);
    _slots[index] = relativePath;
    _normalizeSlots();
    await _save();
  }

  /// Clear a specific slot.
  Future<void> clearSlot(int index) async {
    if (index < 0 || index >= _slots.length) return;
    _slots[index] = '';
    _normalizeSlots();
    await _save();
  }

  /// Swap two slots (for drag-and-drop reorder).
  Future<void> swapSlots(int from, int to) async {
    if (from == to) return;
    _ensureIndex(from);
    _ensureIndex(to);

    final temp = _slots[from];
    _slots[from] = _slots[to];
    _slots[to] = temp;
    _normalizeSlots();
    await _save();
  }

  /// Move slot content from [from] to [to], shifting others.
  Future<void> moveSlot(int from, int to) async {
    if (from < 0 || from >= _slots.length || to < 0) return;
    if (to >= _slots.length) {
      _ensureIndex(to);
    }
    final item = _slots.removeAt(from);
    _slots.insert(to, item);
    _normalizeSlots();
    await _save();
  }

  /// Remove a recipe from whichever slot it's in (if any).
  Future<void> removeRecipeFromSlots(String relativePath) async {
    _slots = _slots.where((s) => s != relativePath).toList();
    _normalizeSlots();
    await _save();
  }

  /// Returns the slot index for [relativePath], or -1 if not in the grid.
  int slotFor(String relativePath) => _slots.indexOf(relativePath);

  // ──────────────────────────── Persistence ─────────────────────────────

  File get _configFile => File('$_rootDir/config.toml');

  Future<void> _load() async {
    final file = _configFile;
    if (!await file.exists()) {
      _slots = [''];
      return;
    }
    final content = await file.readAsString();
    _slots = _parseSlots(content);
    _normalizeSlots();
  }

  Future<void> _save() async {
    if (_rootDir == null) return;
    final buf = StringBuffer();
    buf.writeln('[grid]');
    buf.write('slots = [');
    buf.write(_slots.map((s) => '"$s"').join(', '));
    buf.writeln(']');
    await _configFile.writeAsString(buf.toString());
  }

  List<String> _parseSlots(String content) {
    // Simple parser for: slots = ["a", "b", ...]
    final match = RegExp(r'slots\s*=\s*\[([^\]]*)\]').firstMatch(content);
    if (match == null) return [''];

    final inner = match.group(1)!;
    final items = RegExp(
      r'"([^"]*)"',
    ).allMatches(inner).map((m) => m.group(1)!).toList();

    return items;
  }

  void _ensureIndex(int index) {
    while (_slots.length <= index) {
      _slots.add('');
    }
  }

  void _normalizeSlots() {
    final compact = _slots.where((s) => s.isNotEmpty).toList();
    compact.add('');
    _slots = compact;
    if (_slots.length < minVisibleSlots) {
      _slots = [''];
    }
  }
}
