import 'dart:io';

void main() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('Error: pubspec.yaml not found in current directory.');
    exit(1);
  }

  final lines = pubspecFile.readAsLinesSync();
  bool inDependencies = false;
  bool inDevDependencies = false;
  final dependencies = <String, String>{};
  final devDependencies = <String, String>{};

  for (var line in lines) {
    final trimmedComment = line.trim();
    if (trimmedComment.startsWith('#')) continue;

    if (line.startsWith('dependencies:')) {
      inDependencies = true;
      inDevDependencies = false;
      continue;
    } else if (line.startsWith('dev_dependencies:')) {
      inDependencies = false;
      inDevDependencies = true;
      continue;
    } else if (!line.startsWith(' ') && line.contains(':')) {
      inDependencies = false;
      inDevDependencies = false;
      continue;
    }

    if (inDependencies || inDevDependencies) {
      if (line.trim().isEmpty) continue;
      // Sub-properties like "  sdk: flutter" under "flutter:" are indented by >= 4 spaces
      final indent = line.length - line.trimLeft().length;
      if (indent > 2) {
        continue;
      }

      final trimmed = line.trim();
      final colonIdx = trimmed.indexOf(':');
      if (colonIdx > 0) {
        final name = trimmed.substring(0, colonIdx).trim();
        final version = trimmed.substring(colonIdx + 1).trim();
        if (inDependencies) {
          dependencies[name] = version;
        } else {
          devDependencies[name] = version;
        }
      }
    }
  }

  // Remove SDK entries like flutter and flutter_test
  dependencies.removeWhere(
    (k, v) => k == 'flutter' || k == 'flutter_localizations' || k == 'sdk',
  );
  devDependencies.removeWhere(
    (k, v) => k == 'flutter_test' || k == 'integration_test' || k == 'sdk',
  );

  print('=== SMAG DEPENDENCY AUDIT CHECK ===\n');

  int failures = 0;
  int warnings = 0;

  // 1. Constraint check
  print('1. Dependency Constraints Check');
  for (final entry in {...dependencies, ...devDependencies}.entries) {
    final name = entry.key;
    final ver = entry.value;
    if (ver == 'any' || ver.isEmpty) {
      print(
        '  [WARN] "$name" uses unconstrained "$ver". Consider pinning with a semver constraint (e.g. ^x.y.z).',
      );
      warnings++;
    }
  }
  if (warnings == 0) {
    print('  [PASS] All direct dependencies specify version constraints.');
  }

  // 2. Scan source files for imports
  print('\n2. Source Import Coverage Check');
  final dartFiles = <File>[];
  for (final dir in ['lib', 'test']) {
    final d = Directory(dir);
    if (d.existsSync()) {
      dartFiles.addAll(
        d
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart')),
      );
    }
  }

  final importedPackages = <String>{};
  final importRegex = RegExp(r'''import\s+['"]package:([a-zA-Z0-9_]+)/''');

  for (final file in dartFiles) {
    final content = file.readAsStringSync();
    for (final match in importRegex.allMatches(content)) {
      final pkg = match.group(1);
      if (pkg != null) {
        importedPackages.add(pkg);
      }
    }
  }

  // Check declared vs imported
  final toolOnly = {'flutter_launcher_icons', 'flutter_lints'};

  for (final pkg in dependencies.keys) {
    if (!importedPackages.contains(pkg) && !toolOnly.contains(pkg)) {
      print(
        '  [WARN] Direct dependency "$pkg" is declared in pubspec.yaml but not imported in lib/ or test/.',
      );
      warnings++;
    } else {
      print('  [PASS] Direct dependency "$pkg" is actively imported.');
    }
  }

  for (final pkg in devDependencies.keys) {
    if (!importedPackages.contains(pkg) && !toolOnly.contains(pkg)) {
      print(
        '  [INFO] Dev dependency "$pkg" is declared in pubspec.yaml (build/tooling asset).',
      );
    } else {
      print('  [PASS] Dev dependency "$pkg" is used in tests/source.');
    }
  }

  // 3. Check for phantom dependencies (imported but not in pubspec)
  print('\n3. Phantom Dependencies Check');
  final allDeclared = {
    ...dependencies.keys,
    ...devDependencies.keys,
    'smag', // local app package
    'flutter',
    'flutter_localizations',
    'flutter_test',
    'integration_test',
  };

  for (final imported in importedPackages) {
    if (!allDeclared.contains(imported)) {
      print(
        '  [FAIL] Package "$imported" is imported in source code but not declared in pubspec.yaml!',
      );
      failures++;
    }
  }
  if (failures == 0) {
    print('  [PASS] No undeclared / phantom package imports detected.');
  }

  print('\n=== AUDIT SUMMARY: $failures failure(s), $warnings warning(s) ===');
  if (failures > 0) {
    exit(1);
  }
}
