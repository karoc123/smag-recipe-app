# Grid + Sync + Privacy Fixes (2026-04-18)

## What was fixed

- Grid refresh bug: stale slot IDs are now cleared immediately when a recipe no longer exists.
- Grid return flow: opening recipe from grid and returning now forces a grid reload, so deletions are visible instantly.
- Sync conflict noise: `dateModified` comparison now normalizes equivalent timestamp formats (for example `+0000` vs `+00:00`).
- Sync fallback: missing comparable remote baseline no longer triggers conflict noise.
- Settings About: added privacy policy link to `PRIVACY.md` in GitHub.

## Test coverage added/updated

- New state test: `test/state/grid_provider_test.dart` validates stale slot cleanup.
- New sync regression test: equivalent timestamp formats do not trigger conflicts.
- Integration smoke test: settings now checks privacy link icon.

## Plugin note

- No plugin code changes were made in `cookbook-master`.
- Follow-up suggestions were documented in `docs/nextcloud_plugin_followup.md`.
