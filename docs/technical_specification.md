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
- **The Search:** Global full-text search accessible from a persistent search icon in the top AppBar. Searches all recipes (name, category, ingredients) via SQLite LIKE, independent of any category selection. Opens a dedicated `SearchScreen` overlay.
- **The Cook-Mode:** Integration of `wakelock` to keep the screen active.
- **The Import Engine:**
  - **From URL:** JSON-LD extraction + heuristic HTML scraping. Up to 5 image candidates detected.
  - **From Text:** JSON parsing (Nextcloud schema + alternate keys) or markdown-style heuristic parsing.
  - **Nextcloud Push:** Import directly to Nextcloud Cookbook via `POST /api/v1/recipes/import`. A loading dialog blocks the UI until the server responds or an error occurs. The API response is parsed leniently (plain integer, JSON integer, or JSON object with `id` field).
- **The Sync Engine:**
  - **Bidirectional** sync comparing `dateModified` timestamps. Locally created recipes (`localOnly`) are automatically pushed to the server during sync when a Nextcloud account is linked.
  - Local image files are uploaded into the user's Nextcloud files via WebDAV before recipe create/update, then the remote recipe is refreshed and its server image is cached locally.
  - Manual trigger only (no background sync).
  - **Conflict resolution dialog** with four options: **Keep Local**, **Keep Server**, **Skip** (leave in conflict state), and **Cancel Sync** (abort remaining conflict resolution).
  - Pending remote deletions are executed first at sync start.

### 4. Authentication

- **Nextcloud Android SSO** library v1.3.4 via platform channel (Kotlin ↔ Dart).
- Channel name: `de.karoc.smag/nextcloud_sso`
- Methods: `pickAccount`, `getCurrentAccount`, `resetAccount`, `performRequest`, `performBinaryRequest`, `performBinaryUpload`.
- Requires the Nextcloud Android client to be installed on the device.

### 5. Navigation

`AppBar` with app title and global search icon. Three-button `BottomNavigationBar`:

1. **View Toggle** — switches between recipe list (category picker → filtered list) and 7-slot grid
2. **Import** — URL and text import with Nextcloud push option
3. **Settings** — sync management, theme, language, about

Back button: Grid/Settings/Import always return to the main recipe overview.

Android share integration:

- `ACTION_SEND` (`text/plain`) and `ACTION_VIEW` (`http`/`https`) route URLs into the import flow.
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
- Smoke tests cover: import screen navigation, search screen, settings screen, grid view toggle, and FAB → recipe create screen.
