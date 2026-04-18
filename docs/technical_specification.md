# Technical Specification

**Framework:** Flutter
**Data Format:** Nextcloud Cookbook JSON schema (schema.org Recipe) stored in SQLite.
**Sync:** Nextcloud Cookbook Plugin API v1 via Android SSO.

### 1. Storage Architecture

- **Local-First:** All data resides in a local SQLite database (`recipes` + `grid_slots` + `pending_deletions` tables).
- **JSON Blob:** Each recipe row stores the full Nextcloud Cookbook JSON in a `json_data` column for lossless API round-tripping.
- **Managed Image Copies:** Gallery-selected images are copied into app-managed storage immediately so recipes do not depend on volatile picker paths.
- **Sync Status:** Each recipe tracks its state: `localOnly`, `synced`, `pendingUpload`, or `conflict`.
- **Deferred Delete Queue:** Remote IDs of locally deleted synced recipes are queued and deleted on the next sync.

### 2. The SMAG Data Schema

Recipes follow the Nextcloud Cookbook JSON format:

```json
{
  "id": 42,
  "name": "Pornokuchen",
  "recipeCategory": "Desserts",
  "recipeYield": "8 servings",
  "prepTime": "PT20M",
  "cookTime": "PT45M",
  "recipeIngredient": ["200g chocolate", "4 eggs"],
  "recipeInstructions": ["Melt chocolate", "Mix with eggs", "Bake at 180°C"],
  "image": "https://...",
  "url": "https://...",
  "dateModified": "2026-04-14T23:45:00+0000"
}
```

### 3. Core Functional Pillars

- **The Grid:** A dynamic visual dashboard with exactly one trailing empty (`+`) slot. During drag, the trailing slot becomes a delete target.
  Shopping list aggregation from grid recipes is sorted alphabetically for predictable kitchen use.
  Returning from recipe detail reloads grid slots so deletions are reflected immediately.
- **The Search:** Global full-text search accessible from a persistent search icon in the top AppBar. Searches all recipes (name, category, ingredients) via SQLite LIKE, independent of any category selection. Opens a dedicated `SearchScreen` overlay.
- **The Cook-Mode:** Integration of `wakelock` to keep the screen active.
- **The Import Engine:**
  - **From URL:** JSON-LD extraction + heuristic HTML scraping. Up to 5 image candidates detected.
  - **From Text:** JSON parsing (Nextcloud schema + alternate keys) or markdown-style heuristic parsing.
  - **Nextcloud Push:** Import directly to Nextcloud Cookbook via `POST /api/v1/recipes/import`. A loading dialog blocks the UI until the server responds or an error occurs. The API response is parsed leniently (plain integer, JSON integer, or JSON object with `id` field).
- **The Sync Engine:**
  - **Bidirectional** sync with remote baseline tracking (`remote_date_modified`) to distinguish "local-only changes" from true local+remote conflicts.
  - Locally created recipes (`localOnly`) are automatically pushed to the server during sync when a Nextcloud account is linked.
  - Before sync, the app fetches the active Cookbook folder from `GET /apps/cookbook/api/v1/config`.
  - Local image files are uploaded as temporary staged files **inside the configured Cookbook folder only** before recipe create/update. Files outside that folder are never touched by SMAG's WebDAV operations.
  - After create/update, staged upload files are cleaned up best-effort and the recipe is refreshed from the server so local cache reflects canonical Cookbook state (`full.jpg`, `thumb.jpg`, `thumb16.jpg`).
  - Manual trigger only (no background sync).
  - Sync executes in a dedicated **Sync Log** screen with copy-to-clipboard support.
  - **Conflict resolution dialog** with four options: **Keep Local**, **Keep Server**, **Skip** (leave in conflict state), and **Cancel Sync** (abort remaining conflict resolution).
  - Conflict dialogs display differing fields and values for **Local** vs **Server** versions.
  - The conflict UI suppresses image-path noise; image differences are only shown when both sides are external HTTP(S) URLs.
  - Conflicts are suppressed when the only discrepancy is a local image file path versus a managed Cookbook image reference (`full.jpg` path variants).
  - Unresolved conflicts remain explicit across sync runs and are never auto-overwritten.
  - Pending remote deletions are executed first at sync start.
  - A manual cookbook-folder override is available in settings for troubleshooting. It is explicitly marked as an override because the authoritative source is Nextcloud config.

### 4. Authentication

- **Nextcloud Android SSO** library v1.3.4 via platform channel (Kotlin ↔ Dart).
- Channel name: `de.karoc.smag/nextcloud_sso`
- Methods: `pickAccount`, `getCurrentAccount`, `resetAccount`, `performRequest`, `performBinaryRequest`, `performBinaryUpload`.
- Requires the Nextcloud Android client to be installed on the device.

### 5. Navigation

`AppBar` with app title and persistent actions:

1. **Search**
2. **Settings**

Floating bottom-right actions:

1. **Add (`+`)** — visible in recipe view; opens a chooser for **New Recipe** or **Import**
2. **View Toggle** — always visible; toggles recipe list and grid, and sits directly right of `+` in recipe view

Back button: Import/Settings return to the recipe overview.

Settings About section includes links to repository and privacy policy.

Android share integration:

- `ACTION_SEND` (`text/plain`) routes shared URLs into the import flow.
- Generic browser link handling (`ACTION_VIEW` for `http`/`https`) is intentionally not claimed by SMAG.
- Intents are consumed once and cleared (`setIntent(Intent())`) to prevent re-navigation on app resume.

### 6. Theming

- **Light:** Sage green (#6B8F71) primary, warm white (#F5F2ED) background.
- **OLED Dark:** Pure black (#000000) background, #0A0A0A surface.
- Fonts: Playfair Display (headlines), Inter (body), JetBrains Mono (code/editor).

### 7. Recipe List UX

- An **"All Recipes"** virtual category is shown at the top of the category picker as a `FilledButton.tonal`. Tapping it displays every recipe regardless of category.
- Recipes without images show a placeholder icon (48×48 `restaurant` icon) so titles remain aligned across all entries.
- Category picker uses `OutlinedButton` list. Within a category, a `ListTile` header with back arrow allows navigation to the categories overview.

### 8. Error Handling

- A reusable `showErrorDialog()` displays errors in an `AlertDialog` with:
  - A user-friendly localized message derived from the HTTP status code (409 → recipe name collision, 401/403 → unauthorized, 404 → not found, 5xx → server error, `SocketException` → network error).
  - The technical error detail in a scrollable `bodySmall` block (max 6 lines).
  - A **Copy** button that copies the full error text to the clipboard.
- The error dialog is used for sync errors, URL import errors, and Nextcloud push errors.

### 9. Integration Testing

- A `start_integrationtests.sh` script supports two modes:
  - **Docker mode** (default): Launches a Docker container (`budtmo/docker-android:emulator_14.0`) with an Android emulator. Requires KVM (`/dev/kvm`); the script detects missing KVM and exits with a clear error message. Uses `--device /dev/kvm` passthrough and the `DEVICE` environment variable. Boot timeout is 360 seconds.
  - **Local mode** (`--local`): Runs tests against a connected physical device or host emulator via `adb devices`.
- Smoke tests cover: add-menu import navigation, add-menu recipe creation, search screen, settings screen, and grid view toggle.
