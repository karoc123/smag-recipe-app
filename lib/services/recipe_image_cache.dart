import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class RecipeImageCache {
  Future<String> save(int remoteId, Uint8List bytes);
  Future<String?> imagePath(int remoteId);
}

class FileRecipeImageCache implements RecipeImageCache {
  @override
  Future<String?> imagePath(int remoteId) async {
    final dir = await _imageCacheDir();
    final file = File(p.join(dir.path, '$remoteId.jpg'));
    if (await file.exists()) return file.path;
    return null;
  }

  @override
  Future<String> save(int remoteId, Uint8List bytes) async {
    final dir = await _imageCacheDir();
    final file = File(p.join(dir.path, '$remoteId.jpg'));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<Directory> _imageCacheDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'smag_images'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
