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
  Future<SyncResult> sync({void Function(String entry)? onLog}) async {
    await _remoteGateway.ensureAccountLinked();
    void log(String message) => onLog?.call(message);

    int pulled = 0;
    int pushed = 0;
    int conflicts = 0;
    int deleted = 0;

    log('Sync started.');

    // 0. Execute deferred remote deletions.
    final pendingDeletes = await _db.getPendingDeletions();
    for (final remoteId in pendingDeletes) {
      try {
        await _remoteGateway.deleteRecipe(remoteId);
      } catch (_) {
        // Keep it queued for the next sync attempt.
        log('Delete failed for remote recipe #$remoteId, keeping queue entry.');
        continue;
      }
      await _db.clearPendingDeletion(remoteId);
      deleted++;
      log('Deleted remote recipe #$remoteId.');
    }

    // 1. Remote stubs
    final remoteStubs = await _remoteGateway.getRecipes();
    log('Fetched ${remoteStubs.length} remote recipe stubs.');
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
        log('Pulled new remote recipe "${recipe.name}" (#${stub.id}).');
        continue;
      }

      final localId = local.localId;
      if (localId == null) {
        continue;
      }

      final hasPendingUpload = await _db.hasSyncStatus(
        localId,
        SyncStatus.pendingUpload,
      );
      final hasConflict = await _db.hasSyncStatus(localId, SyncStatus.conflict);
      final remoteChanged = await _db.hasRemoteVersionChanged(
        localId,
        stub.dateModified,
      );

      if (hasConflict) {
        // Preserve unresolved conflicts until the user explicitly resolves them.
        conflicts++;
        log('Conflict still pending for "${local.name}" (#${stub.id}).');
      } else if (hasPendingUpload && remoteChanged) {
        final remoteRecipe = await _remoteGateway.getRecipe(stub.id);

        if (_isImagePathAliasOnlyDifference(local, remoteRecipe)) {
          final localImagePath = await _downloadImage(stub.id);
          await _db.upsertRecipe(
            remoteRecipe.copyWith(
              localId: localId,
              localImagePath: remoteRecipe.image.isEmpty
                  ? ''
                  : (localImagePath ?? local.localImagePath),
            ),
            syncStatus: SyncStatus.synced,
          );
          pulled++;
          log(
            'Suppressed image-path-only conflict for "${local.name}" (#${stub.id}).',
          );
          continue;
        }

        // Both sides changed.
        await _db.setSyncStatus(localId, SyncStatus.conflict);
        conflicts++;
        log('Detected conflict for "${local.name}" (#${stub.id}).');
      } else if (remoteChanged) {
        // Only remote changed → pull.
        final recipe = await _remoteGateway.getRecipe(stub.id);
        final localImagePath = await _downloadImage(stub.id);
        await _db.upsertRecipe(
          recipe.copyWith(
            localId: localId,
            localImagePath: recipe.image.isEmpty ? '' : (localImagePath ?? ''),
          ),
          syncStatus: SyncStatus.synced,
        );
        pulled++;
        log('Pulled updated remote recipe "${recipe.name}" (#${stub.id}).');
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
        log('Deleted local recipe "${local.name}" (missing remotely).');
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
        log('Pushed new local recipe "${recipe.name}" to server.');
      } else {
        // Modified locally → update on server.
        await _remoteGateway.updateRecipe(uploadReady);
        await _refreshSyncedRecipe(recipe, remoteId: recipe.remoteId!);
        log('Updated remote recipe "${recipe.name}" (#${recipe.remoteId}).');
      }
      pushed++;
    }

    log(
      'Sync finished. Pulled=$pulled, Pushed=$pushed, Conflicts=$conflicts, Deleted=$deleted.',
    );

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

  /// Fetch a remote recipe for conflict inspection UI.
  Future<Recipe?> fetchRemoteRecipe(int remoteId) async {
    try {
      return await _remoteGateway.getRecipe(remoteId);
    } catch (_) {
      return null;
    }
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

  bool _isImagePathAliasOnlyDifference(Recipe local, Recipe remote) {
    if (!_matchesIgnoringImage(local, remote)) {
      return false;
    }

    final localImage = local.image.trim();
    final remoteImage = remote.image.trim();
    if (localImage == remoteImage) {
      return false;
    }

    return _isLocalImageFilePath(localImage, local.localImagePath) &&
        _isRemoteManagedImagePath(remoteImage);
  }

  bool _matchesIgnoringImage(Recipe local, Recipe remote) {
    return _same(local.name, remote.name) &&
        _same(local.description, remote.description) &&
        _same(local.url, remote.url) &&
        _same(local.prepTime, remote.prepTime) &&
        _same(local.cookTime, remote.cookTime) &&
        _same(local.totalTime, remote.totalTime) &&
        _same(local.recipeCategory, remote.recipeCategory) &&
        _same(local.keywords, remote.keywords) &&
        _same(local.recipeYield, remote.recipeYield) &&
        _sameList(local.tool, remote.tool) &&
        _sameList(local.recipeIngredient, remote.recipeIngredient) &&
        _sameList(local.recipeInstructions, remote.recipeInstructions);
  }

  bool _same(String a, String b) => a.trim() == b.trim();

  bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_same(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  bool _isLocalImageFilePath(String image, String localImagePath) {
    if (image.isEmpty) return false;
    if (localImagePath.isNotEmpty && image == localImagePath) {
      return true;
    }
    return image.startsWith('/data/') || image.contains('/app_flutter/');
  }

  bool _isRemoteManagedImagePath(String image) {
    return image.startsWith('/.smag-recipe-image-');
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
