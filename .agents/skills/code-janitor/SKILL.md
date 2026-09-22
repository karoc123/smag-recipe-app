---
name: code-janitor
description: Use if the user requests full code cleanliness.
---

# Code Janitor

Before you finish a change — and any time you want confidence the codebase is
clean — run the janitor's rounds. Each step catches a different class of
problem; do not skip any. Run everything from the repository root and fix every failure
before moving on.

## The sweep (in order)

1. **Localization & CodeGen** — `flutter gen-l10n`
2. **Format check** — `dart format --output=none --set-exit-if-changed .` (auto-format with `dart format .`)
3. **Static analysis & Linting** — `flutter analyze`
4. **Unit & Widget tests** — `flutter test`
5. **Layer architecture check** — Verify thin UI and layer boundaries per `AGENTS.md`
6. **Integration tests** — `./start_integrationtests.sh --local` (or `./start_integrationtests.sh`)
7. **Cleanup & Cache reset** — `flutter clean && flutter pub get`

Fix failures at the step that surfaced them, then re-run that step and let the
rest of the sweep continue. If a step is irrelevant to your change (e.g. documentation-only changes), you may note it and skip, but never silently drop the formatting, analysis, or test steps on code modifications.

---

## Step details

### 1. Localization & CodeGen (flutter gen-l10n)

Ensures generated localization Dart files in `lib/l10n/` match the `.arb` source files defined in `l10n.yaml`.

```bash
flutter gen-l10n
```

Rules:
- Never hand-edit generated localization files in `lib/l10n/` (such as `app_localizations*.dart`).
- When modifying user-facing strings, edit `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`, then run `flutter gen-l10n`.

### 2. Format (Dart Formatter)

Checks code style based on standard Dart conventions (2-space indentation, trailing commas).

```bash
# Check formatting without writing changes:
dart format --output=none --set-exit-if-changed .

# Auto-format all modified files in place:
dart format .
```

Style reminders:
- Standard Dart style: 2-space indentation.
- Always include trailing commas in multiline parameter lists, widget trees, and collections to ensure clean formatting diffs.
- File naming: `snake_case.dart`. Types: `UpperCamelCase`. Members: `lowerCamelCase`.

### 3. Static Analysis & Linting (flutter analyze)

Runs the Dart analyzer against `analysis_options.yaml` (using `flutter_lints`).

```bash
flutter analyze
```

Common fixes:
- Unused imports or variables: remove them.
- Avoid raw type casts; prefer typed models or null checks.
- Unhandled futures: ensure async calls are properly awaited or documented.
- Follow deprecation warnings for Flutter framework updates.

### 4. Unit & Widget Tests (flutter test)

Runs the full automated test suite:

- Domain models: `test/domain/`
- Service logic: `test/services/`
- App state: `test/state/`
- UI & widgets: `test/ui/`

```bash
# Run all tests
flutter test

# Run a specific test directory or file
flutter test test/services/
flutter test test/ui/recipe_list_clickflow_test.dart
```

Testing guidelines:
- Name test files `*_test.dart` and mirror the app layout in `lib/`.
- Prefer focused unit tests for `domain/` and `services/`, and `testWidgets` for UI behavior.
- Use small fakes (e.g., in `test/ui/recipe_list_clickflow_test.dart`) rather than real SQLite databases or network requests.
- New behavior must ship with targeted regression tests.

### 5. Layer Architecture & Thin UI Check

Enforces module boundaries and separation of concerns per `AGENTS.md`:

- `lib/ui/` (Screens, dialogs, widgets): Must remain thin. Never perform database operations, network I/O, or complex parsing directly in widgets.
- `lib/data/`: Persistence (SQLite via `sqflite`) and remote access (Nextcloud Cookbook API).
- `lib/domain/`: Pure core models (`Recipe`, `CookbookPathPolicy`) free of UI dependencies.
- `lib/services/`: Parsing (`recipe_parser.dart`), duration formatting, synchronization, and import services.
- `lib/state/`: `ChangeNotifier` state (`RecipeProvider`, `SyncProvider`, `SettingsProvider`).

Verify that UI widgets delegate all business logic, synchronization, and data transformations to providers or services.

### 6. Integration Tests (Android Emulator / Device)

Runs end-to-end integration tests located in `integration_test/`.

```bash
# Run against a connected Android device or local emulator
./start_integrationtests.sh --local

# Run inside a headless Docker Android emulator (requires KVM)
./start_integrationtests.sh
```

Notes:
- Run integration tests before submitting pull requests that alter synchronization, database migrations, or core clickflows.
- Docker mode requires `/dev/kvm` hardware acceleration.

### 7. Cleanup & Build Reset

Removes intermediate build artifacts and resets the dependency cache if builds behave inconsistently:

```bash
flutter clean
flutter pub get
```

Optional release build smoke check:
```bash
flutter build apk --release --no-tree-shake-icons
```
