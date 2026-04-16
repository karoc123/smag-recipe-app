import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/nextcloud_api.dart';
import '../data/nextcloud_sso.dart';
import '../data/recipe_database.dart';
import '../domain/recipe.dart';

/// Bidirectional sync engine between local SQLite and Nextcloud Cookbook.
///
/// Strategy:
///   1. Fetch the remote recipe list (stubs with dateModified).
///   2. For each remote recipe, compare with local copy.
///   3. Push locally-created or modified recipes that have no remote conflict.
///   4. Flag conflicts for manual resolution.
class SyncService {
  final RecipeDatabase _db;
  final NextcloudApi _api;
  final NextcloudSso _sso;

  SyncService(this._db, this._api, this._sso);

  /// Run a full sync cycle. Returns a human-readable summary.
  ///
  /// Throws if no account is linked.
  Future<SyncResult> sync() async {
    final account = await _sso.getCurrentAccount();
    if (account == null) {
      throw StateError('No Nextcloud account linked');
    }

    int pulled = 0;
    int pushed = 0;
    int conflicts = 0;
    int deleted = 0;

    // 1. Remote stubs
    final remoteStubs = await _api.getRecipes();
    final remoteIds = <int>{};

    // 2. Pull / detect conflicts
    for (final stub in remoteStubs) {
      remoteIds.add(stub.id);
      final local = await _db.getByRemoteId(stub.id);

      if (local == null) {
        // New remote recipe → pull full data.
        final recipe = await _api.getRecipe(stub.id);
        await _db.upsertRecipe(recipe, syncStatus: SyncStatus.synced);
        await _downloadImage(stub.id);
        pulled++;
        continue;
      }

      // Exists locally — check for conflicts.
      final localModified =
          local.dateModified != stub.dateModified &&
          await _isSyncStatus(local.localId!, SyncStatus.pendingUpload);

      if (localModified) {
        // Both sides changed.
        await _db.setSyncStatus(local.localId!, SyncStatus.conflict);
        conflicts++;
      } else if (local.dateModified != stub.dateModified) {
        // Only remote changed → pull.
        final recipe = await _api.getRecipe(stub.id);
        await _db.upsertRecipe(
          recipe.copyWith(localId: local.localId),
          syncStatus: SyncStatus.synced,
        );
        await _downloadImage(stub.id);
        pulled++;
      }
      // else: in sync, nothing to do.
    }

    // 3. Detect locally deleted recipes that are still on the server.
    final allLocal = await _db.getAllRecipes();
    for (final local in allLocal) {
      if (local.remoteId != null && !remoteIds.contains(local.remoteId)) {
        // Recipe was deleted on the server → remove locally.
        await _db.deleteRecipe(local.localId!);
        deleted++;
      }
    }

    // 4. Push local-only and pending-upload recipes.
    final pending = await _db.getPendingUploads();
    for (final recipe in pending) {
      if (recipe.remoteId == null) {
        // New local recipe → create on server.
        final remoteId = await _api.createRecipe(recipe);
        await _db.upsertRecipe(
          recipe.copyWith(remoteId: remoteId),
          syncStatus: SyncStatus.synced,
        );
      } else {
        // Modified locally → update on server.
        await _api.updateRecipe(recipe);
        await _db.setSyncStatus(recipe.localId!, SyncStatus.synced);
      }
      pushed++;
    }

    return SyncResult(
      pulled: pulled,
      pushed: pushed,
      conflicts: conflicts,
      deleted: deleted,
    );
  }

  /// Resolve a conflict by keeping either the local or remote version.
  Future<void> resolveConflict(int localId, {required bool keepLocal}) async {
    final recipe = await _db.getByLocalId(localId);
    if (recipe == null || recipe.remoteId == null) return;

    if (keepLocal) {
      // Push local version to server.
      await _api.updateRecipe(recipe);
      await _db.setSyncStatus(localId, SyncStatus.synced);
    } else {
      // Pull remote version.
      final remote = await _api.getRecipe(recipe.remoteId!);
      await _db.upsertRecipe(
        remote.copyWith(localId: localId),
        syncStatus: SyncStatus.synced,
      );
      await _downloadImage(recipe.remoteId!);
    }
  }

  /// Push a single recipe to Nextcloud (for "Send to Nextcloud" import flow).
  /// Returns the new remote id.
  Future<int> pushRecipe(Recipe recipe) async {
    return _api.createRecipe(recipe);
  }

  // ---------------------------------------------------------------------------
  // Image helpers
  // ---------------------------------------------------------------------------

  Future<void> _downloadImage(int remoteId) async {
    try {
      final bytes = await _api.getImage(remoteId);
      if (bytes != null) {
        await _saveImageToCache(remoteId, bytes);
      }
    } catch (_) {
      // Non-fatal: recipe works without image.
    }
  }

  Future<void> _saveImageToCache(int remoteId, Uint8List bytes) async {
    final dir = await _imageCacheDir();
    final file = File(p.join(dir.path, '$remoteId.jpg'));
    await file.writeAsBytes(bytes);
  }

  /// Returns the local cache path for a remote recipe image, or null.
  static Future<String?> imagePath(int remoteId) async {
    final dir = await _imageCacheDir();
    final file = File(p.join(dir.path, '$remoteId.jpg'));
    if (await file.exists()) return file.path;
    return null;
  }

  static Future<Directory> _imageCacheDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'smag_images'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<bool> _isSyncStatus(int localId, SyncStatus status) async {
    final db = await _db.database;
    final rows = await db.query(
      'recipes',
      columns: ['sync_status'],
      where: 'local_id = ?',
      whereArgs: [localId],
    );
    if (rows.isEmpty) return false;
    return rows.first['sync_status'] == status.name;
  }
}

/// Summary of a sync operation.
class SyncResult {
  final int pulled;
  final int pushed;
  final int conflicts;
  final int deleted;

  const SyncResult({
    this.pulled = 0,
    this.pushed = 0,
    this.conflicts = 0,
    this.deleted = 0,
  });

  @override
  String toString() =>
      'Pulled: $pulled, Pushed: $pushed, Conflicts: $conflicts, Deleted: $deleted';
}
