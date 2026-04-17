import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class ManagedRecipeImageStore {
  Future<String> persist(String sourcePath);
  Future<void> delete(String path);
  bool ownsPath(String path);
}

class FileManagedRecipeImageStore implements ManagedRecipeImageStore {
  @override
  Future<void> delete(String path) async {
    if (!ownsPath(path)) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  bool ownsPath(String path) {
    if (path.isEmpty) return false;
    final marker = '${p.separator}smag_local_images${p.separator}';
    return path.contains(marker) ||
        path.endsWith('${p.separator}smag_local_images');
  }

  @override
  Future<String> persist(String sourcePath) async {
    if (ownsPath(sourcePath)) return sourcePath;

    final source = File(sourcePath);
    if (!await source.exists()) {
      throw ArgumentError('Image file does not exist: $sourcePath');
    }

    final dir = await _imagesDir();
    final extension = _normalizedExtension(sourcePath);
    final targetPath = p.join(
      dir.path,
      '${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    final target = await source.copy(targetPath);
    return target.path;
  }

  Future<Directory> _imagesDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(_dirPathForBase(base.path));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _dirPathForBase(String basePath) {
    return p.join(basePath, 'smag_local_images');
  }

  String _normalizedExtension(String sourcePath) {
    final extension = p.extension(sourcePath).toLowerCase();
    if (extension == '.jpg' ||
        extension == '.jpeg' ||
        extension == '.png' ||
        extension == '.webp') {
      return extension;
    }
    return '.jpg';
  }
}
