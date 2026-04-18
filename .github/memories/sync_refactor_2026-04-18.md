# Sync Refactor Memory (2026-04-18)

## Decisions

- SMAG must never write or delete files outside the active Nextcloud Cookbook folder.
- Cookbook folder source of truth is `GET /apps/cookbook/api/v1/config`.
- Sync aborts if folder resolution fails and no manual override is set.
- Manual folder override is allowed in app settings, but clearly marked as troubleshooting-only.
- Temporary image staging inside cookbook folder is allowed and cleaned up best-effort.
- No migration/deletion of legacy root files (`/.smag-recipe-image-*`) is performed.

## Implemented Guardrails

- Central path policy utility normalizes paths and blocks out-of-folder access.
- WebDAV image staging + staged-file deletion both run through folder guard checks.
- Conflict UI no longer shows image-path noise; image diffs appear only for differing external HTTP(S) URLs.

## Testing Focus

- Sync fails when cookbook folder config is unavailable.
- Manual override bypasses config lookup and controls upload path.
- Upload flow stages file in cookbook folder and performs cleanup.
- Path policy unit tests cover normalization and out-of-folder rejection.
