import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smag/data/recipe_database.dart';
import 'package:smag/data/nextcloud_api.dart';
import 'package:smag/domain/recipe.dart';
import 'package:smag/services/recipe_image_cache.dart';
import 'package:smag/services/recipe_remote_gateway.dart';
import 'package:smag/services/sync_service.dart';

class _FakeRecipeDatabase extends RecipeDatabase {
  final Map<int, Recipe> _byLocalId = {};
  final Map<int, SyncStatus> _statuses = {};
  final Map<int, String> _remoteDateModified = {};
  int _nextId = 1;

  SyncStatus? statusFor(int localId) => _statuses[localId];

  void seed(
    Recipe recipe,
    SyncStatus status, {
    String remoteDateModified = '',
  }) {
    final localId = recipe.localId ?? _nextId++;
    _byLocalId[localId] = recipe.copyWith(localId: localId);
    _statuses[localId] = status;
    _remoteDateModified[localId] = remoteDateModified;
  }

  @override
  Future<List<int>> getPendingDeletions() async => [];

  @override
  Future<void> clearPendingDeletion(int remoteId) async {}

  @override
  Future<Recipe?> getByRemoteId(int remoteId) async {
    try {
      return _byLocalId.values.firstWhere((r) => r.remoteId == remoteId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Recipe?> getByLocalId(int localId) async => _byLocalId[localId];

  @override
  Future<Recipe> upsertRecipe(Recipe recipe, {SyncStatus? syncStatus}) async {
    final localId = recipe.localId ?? _nextId++;
    final saved = recipe.copyWith(localId: localId);
    _byLocalId[localId] = saved;
    final status = syncStatus ?? SyncStatus.localOnly;
    _statuses[localId] = status;
    if (status == SyncStatus.synced) {
      _remoteDateModified[localId] = saved.dateModified;
    } else {
      _remoteDateModified.putIfAbsent(localId, () => '');
    }
    return saved;
  }

  @override
  Future<List<Recipe>> getAllRecipes() async => _byLocalId.values.toList();

  @override
  Future<void> deleteRecipe(int localId) async {
    _byLocalId.remove(localId);
    _statuses.remove(localId);
    _remoteDateModified.remove(localId);
  }

  @override
  Future<List<Recipe>> getPendingUploads() async {
    return _byLocalId.values.where((recipe) {
      final status = _statuses[recipe.localId];
      return status == SyncStatus.pendingUpload ||
          status == SyncStatus.localOnly;
    }).toList();
  }

  @override
  Future<void> setSyncStatus(
    int localId,
    SyncStatus status, {
    String? remoteDateModified,
  }) async {
    _statuses[localId] = status;
    if (remoteDateModified != null) {
      _remoteDateModified[localId] = remoteDateModified;
    }
  }

  @override
  Future<bool> hasSyncStatus(int localId, SyncStatus status) async {
    return _statuses[localId] == status;
  }

  @override
  Future<bool> hasRemoteVersionChanged(
    int localId,
    String remoteDateModified,
  ) async {
    final previous = _remoteDateModified[localId] ?? '';
    if (previous.isEmpty) return true;
    return previous != remoteDateModified;
  }
}

class _FakeRemoteGateway implements RecipeRemoteGateway {
  List<RecipeStub> stubs = [];
  final Map<int, Recipe> recipes = {};
  final Map<int, Uint8List> images = {};
  String cookbookFolderPath = '/Rezepte';
  int cookbookFolderRequests = 0;
  bool throwOnCookbookFolder = false;
  Recipe? createdRecipe;
  Recipe? updatedRecipe;
  Recipe? uploadedRecipe;
  Uint8List? uploadedBytes;
  String? uploadedCookbookFolderPath;
  final List<String> deletedUserFiles = [];

  @override
  Future<void> ensureAccountLinked() async {}

  @override
  Future<int> createRecipe(Recipe recipe) async {
    createdRecipe = recipe;
    return 999;
  }

  @override
  Future<void> deleteUserFile(
    String path, {
    required String cookbookFolderPath,
  }) async {
    if (!path.startsWith('$cookbookFolderPath/')) {
      throw StateError('Path outside cookbook folder: $path');
    }
    deletedUserFiles.add(path);
  }

  @override
  Future<void> deleteRecipe(int remoteId) async {}

  @override
  Future<Uint8List?> getImage(int remoteId, {String size = 'full'}) async {
    return images[remoteId];
  }

  @override
  Future<String> getCookbookFolderPath() async {
    cookbookFolderRequests++;
    if (throwOnCookbookFolder) {
      throw StateError('config unavailable');
    }
    return cookbookFolderPath;
  }

  @override
  Future<Recipe> getRecipe(int id) async => recipes[id]!;

  @override
  Future<List<RecipeStub>> getRecipes() async => stubs;

  @override
  Future<int> importFromUrl(String url) async => 123;

  @override
  Future<void> updateRecipe(Recipe recipe) async {
    updatedRecipe = recipe;
  }

  @override
  Future<StagedRecipeImage> uploadRecipeImage(
    Recipe recipe,
    Uint8List bytes, {
    required String cookbookFolderPath,
  }) async {
    uploadedRecipe = recipe;
    uploadedBytes = bytes;
    uploadedCookbookFolderPath = cookbookFolderPath;
    final stagedPath = '$cookbookFolderPath/.smag-upload-${recipe.localId}.jpg';
    return StagedRecipeImage(
      recipeImagePath: stagedPath,
      stagedFilePath: stagedPath,
    );
  }
}

class _FakeRecipeImageCache implements RecipeImageCache {
  final Map<int, Uint8List> savedImages = {};
  final Map<int, String> savedPaths = {};

  @override
  Future<String?> imagePath(int remoteId) async => savedPaths[remoteId];

  @override
  Future<String> save(int remoteId, Uint8List bytes) async {
    savedImages[remoteId] = bytes;
    final path = '/cache/$remoteId.jpg';
    savedPaths[remoteId] = path;
    return path;
  }
}

void main() {
  group('SyncService', () {
    test('pulls missing remote recipes and caches their images', () async {
      final db = _FakeRecipeDatabase();
      final gateway = _FakeRemoteGateway()
        ..stubs = const [
          RecipeStub(
            id: 7,
            name: 'Soup',
            category: 'Dinner',
            dateModified: 'v1',
          ),
        ]
        ..recipes[7] = const Recipe(
          remoteId: 7,
          name: 'Soup',
          image: 'https://cloud.example/recipes/7/image',
          recipeCategory: 'Dinner',
          dateModified: 'v1',
        )
        ..images[7] = Uint8List.fromList([1, 2, 3]);
      final imageCache = _FakeRecipeImageCache();
      final syncService = SyncService(db, gateway, imageCache);

      final result = await syncService.sync();

      final saved = await db.getByRemoteId(7);
      expect(saved?.name, 'Soup');
      expect(db.statusFor(saved!.localId!), SyncStatus.synced);
      expect(saved.localImagePath, '/cache/7.jpg');
      expect(imageCache.savedImages[7], Uint8List.fromList([1, 2, 3]));
      expect(result.pulled, 1);
      expect(result.conflicts, 0);
    });

    test(
      'marks pending local changes as conflicts when remote changed too',
      () async {
        final db = _FakeRecipeDatabase();
        db.seed(
          const Recipe(
            localId: 1,
            remoteId: 8,
            name: 'Salad',
            dateModified: 'local-change',
          ),
          SyncStatus.pendingUpload,
          remoteDateModified: 'remote-base',
        );
        final gateway = _FakeRemoteGateway()
          ..stubs = const [
            RecipeStub(
              id: 8,
              name: 'Salad',
              category: 'Lunch',
              dateModified: 'remote-change',
            ),
          ]
          ..recipes[8] = const Recipe(
            remoteId: 8,
            name: 'Salad',
            dateModified: 'remote-change',
          );
        final imageCache = _FakeRecipeImageCache();
        final syncService = SyncService(db, gateway, imageCache);

        final result = await syncService.sync();

        expect(db.statusFor(1), SyncStatus.conflict);
        expect(result.conflicts, 1);
      },
    );

    test(
      'does not mark conflict when remote is unchanged and local recipe is pending upload',
      () async {
        final db = _FakeRecipeDatabase();
        db.seed(
          const Recipe(
            localId: 1,
            remoteId: 11,
            name: 'Pasta',
            dateModified: 'local-change',
          ),
          SyncStatus.pendingUpload,
          remoteDateModified: 'remote-base',
        );

        final gateway = _FakeRemoteGateway()
          ..stubs = const [
            RecipeStub(
              id: 11,
              name: 'Pasta',
              category: 'Dinner',
              dateModified: 'remote-base',
            ),
          ]
          ..recipes[11] = const Recipe(
            remoteId: 11,
            name: 'Pasta',
            dateModified: 'remote-base',
          );

        final imageCache = _FakeRecipeImageCache();
        final syncService = SyncService(db, gateway, imageCache);

        final result = await syncService.sync();

        expect(result.conflicts, 0);
        expect(result.pushed, 1);
        expect(gateway.updatedRecipe?.remoteId, 11);
        expect(db.statusFor(1), SyncStatus.synced);
      },
    );

    test('keeps existing conflicts unresolved across sync runs', () async {
      final db = _FakeRecipeDatabase();
      db.seed(
        const Recipe(
          localId: 1,
          remoteId: 12,
          name: 'Soup',
          dateModified: 'local-conflict-version',
        ),
        SyncStatus.conflict,
        remoteDateModified: 'remote-v1',
      );

      final gateway = _FakeRemoteGateway()
        ..stubs = const [
          RecipeStub(
            id: 12,
            name: 'Soup',
            category: 'Dinner',
            dateModified: 'remote-v1',
          ),
        ]
        ..recipes[12] = const Recipe(
          remoteId: 12,
          name: 'Soup server',
          dateModified: 'remote-v1',
        );

      final imageCache = _FakeRecipeImageCache();
      final syncService = SyncService(db, gateway, imageCache);

      final result = await syncService.sync();

      expect(result.conflicts, 1);
      expect(db.statusFor(1), SyncStatus.conflict);
      expect(gateway.updatedRecipe, isNull);
    });

    test(
      'suppresses conflict when image differs only as local path vs managed server path',
      () async {
        final db = _FakeRecipeDatabase();
        db.seed(
          const Recipe(
            localId: 1,
            remoteId: 13,
            name: 'Rye Bread',
            recipeCategory: 'Bakery',
            image:
                '/data/user/0/de.karoc.smag/app_flutter/smag_local_images/123.jpg',
            localImagePath:
                '/data/user/0/de.karoc.smag/app_flutter/smag_local_images/123.jpg',
            dateModified: 'local-change',
          ),
          SyncStatus.pendingUpload,
          remoteDateModified: 'remote-v1',
        );

        final gateway = _FakeRemoteGateway()
          ..stubs = const [
            RecipeStub(
              id: 13,
              name: 'Rye Bread',
              category: 'Bakery',
              dateModified: 'remote-v2',
            ),
          ]
          ..recipes[13] = const Recipe(
            remoteId: 13,
            name: 'Rye Bread',
            recipeCategory: 'Bakery',
            image: 'full.jpg',
            dateModified: 'remote-v2',
          );

        final imageCache = _FakeRecipeImageCache();
        final syncService = SyncService(db, gateway, imageCache);

        final result = await syncService.sync();

        expect(result.conflicts, 0);
        expect(result.pulled, 1);
        expect(result.pushed, 0);
        expect(db.statusFor(1), SyncStatus.synced);
        expect(gateway.updatedRecipe, isNull);
      },
    );

    test('aborts sync when cookbook folder config cannot be loaded', () async {
      final db = _FakeRecipeDatabase();
      final gateway = _FakeRemoteGateway()..throwOnCookbookFolder = true;
      final imageCache = _FakeRecipeImageCache();
      final syncService = SyncService(db, gateway, imageCache);

      expect(syncService.sync(), throwsA(isA<StateError>()));
    });

    test('uses manual cookbook folder override without config call', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'smag_sync_override_test',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final imageFile = File('${tempDir.path}/manual.jpg');
      await imageFile.writeAsBytes(const [3, 1, 4]);

      final db = _FakeRecipeDatabase();
      db.seed(
        Recipe(
          localId: 1,
          name: 'Manual Folder Recipe',
          image: imageFile.path,
          localImagePath: imageFile.path,
        ),
        SyncStatus.localOnly,
      );

      final gateway = _FakeRemoteGateway()
        ..cookbookFolderPath = '/Rezepte'
        ..recipes[999] = const Recipe(
          remoteId: 999,
          name: 'Manual Folder Recipe',
          image: 'https://cloud.example/recipes/999/image',
          dateModified: 'remote-v1',
        );

      final imageCache = _FakeRecipeImageCache();
      final syncService = SyncService(db, gateway, imageCache);

      await syncService.sync(cookbookFolderOverride: '/Manuell');

      expect(gateway.cookbookFolderRequests, 0);
      expect(gateway.uploadedCookbookFolderPath, '/Manuell');
      expect(gateway.createdRecipe?.image, '/Manuell/.smag-upload-1.jpg');
      expect(gateway.deletedUserFiles, ['/Manuell/.smag-upload-1.jpg']);
    });

    test(
      'uploads local recipe images before creating remote recipes',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('smag_sync_test');
        addTearDown(() => tempDir.delete(recursive: true));
        final imageFile = File('${tempDir.path}/pancakes.jpg');
        await imageFile.writeAsBytes(const [9, 8, 7, 6]);

        final db = _FakeRecipeDatabase();
        db.seed(
          Recipe(
            localId: 1,
            name: 'Pancakes',
            image: imageFile.path,
            localImagePath: imageFile.path,
          ),
          SyncStatus.localOnly,
        );

        final gateway = _FakeRemoteGateway()
          ..recipes[999] = const Recipe(
            remoteId: 999,
            name: 'Pancakes',
            image: 'https://cloud.example/recipes/999/image',
            dateModified: 'remote-v1',
          )
          ..images[999] = Uint8List.fromList([1, 2, 3, 4]);
        final imageCache = _FakeRecipeImageCache();
        final syncService = SyncService(db, gateway, imageCache);

        final result = await syncService.sync();

        expect(gateway.uploadedRecipe?.localId, 1);
        expect(gateway.uploadedBytes, Uint8List.fromList([9, 8, 7, 6]));
        expect(gateway.uploadedCookbookFolderPath, '/Rezepte');
        expect(gateway.createdRecipe?.image, '/Rezepte/.smag-upload-1.jpg');
        expect(gateway.deletedUserFiles, ['/Rezepte/.smag-upload-1.jpg']);

        final saved = await db.getByRemoteId(999);
        expect(saved?.name, 'Pancakes');
        expect(saved?.image, 'https://cloud.example/recipes/999/image');
        expect(saved?.localImagePath, '/cache/999.jpg');
        expect(db.statusFor(saved!.localId!), SyncStatus.synced);
        expect(result.pushed, 1);
      },
    );
  });
}
