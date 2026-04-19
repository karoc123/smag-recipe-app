# Package + Settings Sync Stability (2026-04-19)

## What changed

- Renamed Android package/application ID from `de.karoc.smag` to `de.karoc.smagrecipe`.
- Updated Flutter/Dart/Kotlin method channel names to match new package prefix.
- Moved Kotlin sources to matching package path:
  - `android/app/src/main/kotlin/de/karoc/smagrecipe/MainActivity.kt`
  - `android/app/src/main/kotlin/de/karoc/smagrecipe/NextcloudSsoPlugin.kt`
- Updated docs/scripts/tests that referenced the old package ID.

## Settings sync bug fix

- Reworked `SettingsProvider` sync state from a plain bool to a reference-counted busy state.
- Added `runWhileSyncing(...)` helper so sync state is always entered/exited with `try/finally`.
- Updated sync flows in:
  - `lib/ui/sync_log_screen.dart`
  - `lib/ui/import_screen.dart`
- Added `linkingAccount` state and duplicate-call guard in `linkAccount()`.
- Connect button now shows progress and is disabled while account picker is active.

## Regression coverage

- Added `test/state/settings_provider_test.dart`:
  - sync busy-state reset on success/error
  - reference counting for overlapping sync operations
  - duplicate link-account guard
- Added `test/ui/settings_screen_test.dart`:
  - verifies only sync action is blocked while syncing and other settings stay interactive
- Extended `integration_test/smoke_flow_test.dart`:
  - validates settings label uses `Philosophie` and no `FOSS` suffix

## Verification run

- `flutter analyze` -> pass
- `flutter test` -> pass
- `./start_integrationtests.sh --local` -> failed in this environment (no connected adb device)
- `flutter build apk --release --no-tree-shake-icons` -> pass
