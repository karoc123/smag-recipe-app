import 'dart:io';

import '../data/recipe_database.dart';
import '../domain/recipe.dart';
import 'recipe_image_cache.dart';
import 'recipe_remote_gateway.dart';

/// Bidirectional sync engine between local SQLite and Nextcloud Cookbook.
///
/// Strategy:
///   1. Fetch the remote recipe list (stubs with dateModified).
///   2. For each remote recipe, compare with local copy.
///   3. Push locally-created or modified recipes that have no remote conflict.
///   4. Flag conflicts for manual resolution.
class SyncService {
  final RecipeDatabase _db;
  final RecipeRemoteGateway _remoteGateway;
  final RecipeImageCache _imageCache;

  SyncService(this._db, this._remoteGateway, this._imageCache);

  /// Run a full sync cycle. Returns a human-readable summary.
  ///
  /// Throws if no account is linked.
  Future<SyncResult> sync() async {
    await _remoteGateway.ensureAccountLinked();

    int pulled = 0;
    int pushed = 0;
    int conflicts = 0;
    int deleted = 0;

    // 0. Execute deferred remote deletions.
    final pendingDeletes = await _db.getPendingDeletions();
    for (final remoteId in pendingDeletes) {
      try {
        await _remoteGateway.deleteRecipe(remoteId);
      } catch (_) {
        // Keep it queued for the next sync attempt.
        continue;
      }
      await _db.clearPendingDeletion(remoteId);
      deleted++;
    }

    // 1. Remote stubs
    final remoteStubs = await _remoteGateway.getRecipes();
    final remoteIds = <int>{};

    // 2. Pull / detect conflicts
    for (final stub in remoteStubs) {
      remoteIds.add(stub.id);
      final local = await _db.getByRemoteId(stub.id);

      if (local == null) {
        // New remote recipe → pull full data.
        final recipe = await _remoteGateway.getRecipe(stub.id);
        final localImagePath = await _downloadImage(stub.id);
        await _db.upsertRecipe(
          recipe.copyWith(
            localImagePath: recipe.image.isEmpty ? '' : (localImagePath ?? ''),
          ),
          syncStatus: SyncStatus.synced,
        );
        pulled++;
        continue;
      }

      // Exists locally — check for conflicts.
      final localModified =
          local.dateModified != stub.dateModified &&
          await _db.hasSyncStatus(local.localId!, SyncStatus.pendingUpload);

      if (localModified) {
        // Both sides changed.
        await _db.setSyncStatus(local.localId!, SyncStatus.conflict);
        conflicts++;
      } else if (local.dateModified != stub.dateModified) {
        // Only remote changed → pull.
        final recipe = await _remoteGateway.getRecipe(stub.id);
        final localImagePath = await _downloadImage(stub.id);
        await _db.upsertRecipe(
          recipe.copyWith(
            localId: local.localId,
            localImagePath: recipe.image.isEmpty ? '' : (localImagePath ?? ''),
          ),
          syncStatus: SyncStatus.synced,
        );
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
      final uploadReady = await _prepareRecipeForUpload(recipe);
      if (recipe.remoteId == null) {
        // New local recipe → create on server.
        final remoteId = await _remoteGateway.createRecipe(uploadReady);
        await _refreshSyncedRecipe(
          recipe.copyWith(remoteId: remoteId),
          remoteId: remoteId,
        );
      } else {
        // Modified locally → update on server.
        await _remoteGateway.updateRecipe(uploadReady);
        await _refreshSyncedRecipe(recipe, remoteId: recipe.remoteId!);
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
      final uploadReady = await _prepareRecipeForUpload(recipe);
      await _remoteGateway.updateRecipe(uploadReady);
      await _refreshSyncedRecipe(recipe, remoteId: recipe.remoteId!);
    } else {
      // Pull remote version.
      final remote = await _remoteGateway.getRecipe(recipe.remoteId!);
      final localImagePath = await _downloadImage(recipe.remoteId!);
      await _db.upsertRecipe(
        remote.copyWith(
          localId: localId,
          localImagePath: remote.image.isEmpty ? '' : (localImagePath ?? ''),
        ),
        syncStatus: SyncStatus.synced,
      );
    }
  }

  /// Push a single recipe to Nextcloud (for "Send to Nextcloud" import flow).
  /// Returns the new remote id.
  Future<int> pushRecipe(Recipe recipe) async {
    final uploadReady = await _prepareRecipeForUpload(recipe);
    return _remoteGateway.createRecipe(uploadReady);
  }

  /// Let Nextcloud import a recipe URL server-side via Cookbook import endpoint.
  Future<int> importFromUrl(String url) async {
    return _remoteGateway.importFromUrl(url);
  }

  // ---------------------------------------------------------------------------
  // Image helpers
  // ---------------------------------------------------------------------------

  Future<String?> _downloadImage(int remoteId) async {
    try {
      final bytes = await _remoteGateway.getImage(remoteId);
      if (bytes != null) {
        return await _imageCache.save(remoteId, bytes);
      }
    } catch (_) {
      // Non-fatal: recipe works without image.
    }
    return null;
  }

  Future<Recipe> _prepareRecipeForUpload(Recipe recipe) async {
    final localImagePath = _localImagePath(recipe);
    if (localImagePath == null) {
      return recipe;
    }

    final bytes = await File(localImagePath).readAsBytes();
    final remotePath = await _remoteGateway.uploadRecipeImage(recipe, bytes);
    return recipe.copyWith(image: remotePath);
  }

  Future<void> _refreshSyncedRecipe(
    Recipe recipe, {
    required int remoteId,
  }) async {
    final remoteRecipe = await _remoteGateway.getRecipe(remoteId);
    final cachedImagePath = await _downloadImage(remoteId);
    await _db.upsertRecipe(
      remoteRecipe.copyWith(
        localId: recipe.localId,
        localImagePath: remoteRecipe.image.isEmpty
            ? ''
            : (cachedImagePath ?? recipe.localImagePath),
      ),
      syncStatus: SyncStatus.synced,
    );
  }

  String? _localImagePath(Recipe recipe) {
    if (recipe.localImagePath.isNotEmpty) {
      return recipe.localImagePath;
    }
    if (recipe.image.isNotEmpty && !recipe.image.startsWith('http')) {
      return recipe.image;
    }
    return null;
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
