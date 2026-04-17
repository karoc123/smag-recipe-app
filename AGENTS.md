# Repository Guidelines

## Project Structure & Module Organization
`lib/` holds application code. Keep persistence and remote access in `lib/data/`, core models in `lib/domain/`, app services in `lib/services/`, `ChangeNotifier` state in `lib/state/`, and screens/dialogs in `lib/ui/`. Localization sources live in `lib/l10n/*.arb`; generated localization Dart files in `lib/l10n/` should be regenerated, not edited by hand. Tests mirror the app layout in `test/domain/`, `test/services/`, and `test/ui/`. End-to-end coverage lives in `integration_test/`. Android-specific code and release signing live under `android/`. Product notes and specs are in `docs/`.

## Build, Test, and Development Commands
Run `flutter pub get` after dependency changes. Use `flutter gen-l10n` after editing `.arb` files. Start the app with `flutter run`. Run static checks with `flutter analyze` and the main test suite with `flutter test`. Integration tests run with `./start_integrationtests.sh --local` on a connected device, or `./start_integrationtests.sh` for the Docker-based emulator flow. Build a release APK with `flutter build apk --release --no-tree-shake-icons`.

## Coding Style & Naming Conventions
This repo uses `flutter_lints` from `analysis_options.yaml`; keep the analyzer clean before opening a PR. Follow standard Dart style: 2-space indentation, trailing commas where they improve formatting, `snake_case.dart` filenames, `UpperCamelCase` types, and `lowerCamelCase` members. Keep UI code thin: parsing, sync, and database work belong in services, providers, or data classes, not directly in widgets.

## Testing Guidelines
Name tests `*_test.dart` and keep them near the layer they exercise. Prefer focused unit tests for `domain/` and `services/`, and `testWidgets` for UI behavior. Use small fakes, as in `test/ui/recipe_list_clickflow_test.dart`, instead of real database or network dependencies where possible. There is no published coverage gate yet, so new behavior should ship with targeted regression tests.

## Commit & Pull Request Guidelines
Recent history favors short, imperative commit subjects with prefixes such as `feat:` and `fix:`. Keep that pattern, for example `feat: add conflict banner to sync screen`. PRs should describe user-visible changes, list validation steps (`flutter analyze`, `flutter test`, integration coverage if touched), and include screenshots for UI changes. Link the relevant issue or task when available, and call out changes to signing, sync, or localization explicitly.
