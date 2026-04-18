/// Centralized path normalization and guard checks for Nextcloud cookbook files.
class CookbookPathPolicy {
  const CookbookPathPolicy._();

  static String normalizeFolderPath(String path) {
    final normalized = normalizeFilePath(path);
    if (normalized == '/') {
      throw ArgumentError.value(path, 'path', 'Folder path cannot be root.');
    }
    return normalized;
  }

  static String normalizeFilePath(String path) {
    var normalized = path.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) {
      throw ArgumentError.value(path, 'path', 'Path cannot be empty.');
    }

    while (normalized.contains('//')) {
      normalized = normalized.replaceAll('//', '/');
    }

    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }

    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  static bool isPathInsideFolder({
    required String path,
    required String folderPath,
  }) {
    final normalizedPath = normalizeFilePath(path);
    final normalizedFolder = normalizeFolderPath(folderPath);
    if (normalizedPath == normalizedFolder) {
      return true;
    }
    return normalizedPath.startsWith('$normalizedFolder/');
  }

  static String assertPathInsideFolder({
    required String path,
    required String folderPath,
  }) {
    final normalizedPath = normalizeFilePath(path);
    final normalizedFolder = normalizeFolderPath(folderPath);

    if (!isPathInsideFolder(
      path: normalizedPath,
      folderPath: normalizedFolder,
    )) {
      throw StateError(
        'Refusing to access path outside cookbook folder. '
        'Path="$normalizedPath", folder="$normalizedFolder".',
      );
    }

    return normalizedPath;
  }
}
