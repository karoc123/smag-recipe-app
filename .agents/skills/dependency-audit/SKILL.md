---
name: dependency-audit
description: Use when checking, auditing, aligning, updating, or reviewing dependencies for the SMAG Flutter project.
---

# Dependency Audit & Management

Use this skill to systematically inspect, audit, and remediate dependencies for the SMAG Flutter project. It enforces version constraint best practices, detects phantom or unused dependencies, checks for outdated packages, and prevents breaking changes across Flutter, Dart, and Android platform layers.

Run all commands from the repository root.

---

## The Audit Protocol (Step-by-Step)

### Step 1: Constraint & Policy Check

Run the automated dependency checker:

```bash
dart .agents/skills/dependency-audit/scripts/check_deps.dart
```

This automated script checks:

1. **Version Constraint Sanity**: Detects unbounded wildcards (such as `any`) in direct `dependencies` and `dev_dependencies`.
2. **Import Coverage**: Scans `lib/` and `test/` to verify that all declared runtime dependencies are actively imported and used.
3. **Phantom Dependencies**: Scans `lib/` and `test/` for package imports that are not explicitly declared in `pubspec.yaml` (which can occur if accidentally importing transitive dependencies).

Fix any `[FAIL]` or `[WARN]` outputs surfaced in this step before proceeding.

---

### Step 2: Outdated & Drift Analysis

Check available upstream versions using the Flutter toolchain:

```bash
flutter pub outdated
```

Categorize findings from the output columns:

- **Current**: The version currently resolved in `pubspec.lock`.
- **Upgradable**: The highest version matching constraints in `pubspec.yaml`. These can be updated safely without modifying `pubspec.yaml`.
- **Resolvable**: The highest version that can resolve if constraints in `pubspec.yaml` are adjusted.
- **Latest**: The newest published release on pub.dev.

#### Update Classification:
- **Patch/Minor updates**: Generally safe. Verify release notes on pub.dev.
- **Major updates**: Potential breaking changes. Requires API review and full test suite validation.

---

### Step 3: Dependency Graph & Bloat Analysis

Inspect the dependency tree to identify heavy transitive dependencies or platform interfaces:

```bash
flutter pub deps --style=compact
```

Key checks:
- Verify shared platform interfaces (`sqflite_platform_interface`, `image_picker_platform_interface`, `url_launcher_platform_interface`).
- Look for duplicate versions of transitive utilities.

---

### Step 4: Upgrades & Lockfile Synchronization

When updating or adding dependencies:

1. **Safe Minor/Patch Upgrades**:
   ```bash
   # Preview updates:
   flutter pub upgrade --dry-run

   # Apply safe updates:
   flutter pub upgrade
   ```

2. **Major Upgrades**:
   - Update the specific package constraint in `pubspec.yaml` (e.g. `cached_network_image: ^4.0.0`).
   - Run `flutter pub get`.

3. **Inspect Lockfile Changes**:
   ```bash
   git diff pubspec.lock
   ```
   Verify that transitive dependencies were updated as intended and that unexpected version downgrades or major transitive bumps did not occur.

---

### Step 5: Full Verification Sweep

Always verify the app after any dependency changes:

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

Optional release build smoke check (to ensure Android Gradle plugins and minSdk remain compatible):
```bash
flutter build apk --release --no-tree-shake-icons
```

---

### Step 6: Audit & Migration Report (Mandatory Output)

Always present a structured report to the user at the end of the audit:

1. **Status of Baseline Checks**: Confirmation that all direct dependencies have valid constraints, no phantom dependencies exist, and all tests/analysis pass.
2. **Major Upgrades Requiring Adaptations**: Explicitly list all available major version bumps (from `flutter pub outdated`), detailing:
   - Package name and version jump (e.g. `cached_network_image 3.4.1 -> 4.0.0`).
   - Any breaking API changes and affected files in `lib/` or `test/`.
   - Any Android platform constraints (e.g., Gradle version or `minSdkVersion` bumps).
3. **User Decision Prompt**: Ask the user explicitly which of the identified major upgrades should be migrated, proposing an isolated, step-by-step approach with separate commits.

---

## Stolpersteine (Known Traps & Pitfalls)

### Stolperstein 1: `intl: any` and `flutter_localizations` Conflicts

- **Problem**: `intl` is tightly coupled with `flutter_localizations` shipped with the Flutter SDK. Using `intl: any` in `pubspec.yaml` can allow pub to resolve an `intl` version incompatible with Flutter's SDK tools, breaking `flutter gen-l10n`.
- **Solution**: Check the `intl` version bundled by the current Flutter release (`flutter pub deps | grep intl`) and specify a compatible constraint (e.g. `^0.20.2`).

### Stolperstein 2: Android `minSdkVersion` and Gradle Build Failures

- **Problem**: Major version bumps of native Flutter plugins (such as `sqflite`, `wakelock_plus`, or `image_picker`) frequently raise the minimum required Android SDK (e.g. from API 21 to 24) or Android Gradle Plugin (AGP) version.
- **Solution**: Always run `flutter build apk --release --no-tree-shake-icons` or check Android manifest / Gradle files when upgrading native plugins.

### Stolperstein 3: Federated Platform Plugin Mismatches

- **Problem**: Plugins like `sqflite`, `url_launcher`, and `shared_preferences` use federated platform interfaces. Pinning or forcing mismatched platform packages can cause runtime `MissingPluginException` or method channel signature errors.
- **Solution**: Let Flutter resolve transitive platform interface packages automatically; avoid manually adding platform interface packages (`*_platform_interface`) to direct dependencies in `pubspec.yaml`.

### Stolperstein 4: Dart SDK Constraint Drift

- **Problem**: Packages on pub.dev may require a Dart SDK newer than the one bundled with the user's current Flutter stable release (defined in `pubspec.yaml` under `environment.sdk`).
- **Solution**: Check `pubspec.yaml` environment constraints (`sdk: ^3.11.4`) and confirm that upgraded packages support the repository's Dart SDK version.

### Stolperstein 5: `pubspec.lock` Merge Conflicts

- **Problem**: Manually resolving merge conflicts in `pubspec.lock` often corrupts hashes and package descriptions.
- **Solution**: Never edit `pubspec.lock` manually. Resolve conflicts in `pubspec.yaml`, delete conflicted sections in `pubspec.lock`, and run `flutter pub get`.

### Stolperstein 6: Stale Generated Localization Code

- **Problem**: Updating dependencies like `intl` or changing localization files can leave generated Dart classes in `lib/l10n/` out of sync, causing subtle type or compilation errors during tests.
- **Solution**: Always run `flutter gen-l10n` immediately following dependency operations.

### Stolperstein 7: Recipe Parsing & Nextcloud Sync Regressions

- **Problem**: Bumping HTTP or HTML parsing dependencies (`http`, `html`, `flutter_markdown`) can alter whitespace handling, DOM node selection, or network headers used by the Nextcloud Cookbook synchronization.
- **Solution**: Always run targeted service tests (`flutter test test/services/`) after modifying networking or parsing dependencies.
