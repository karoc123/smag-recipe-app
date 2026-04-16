**Framework:** Flutter
**Data Format:** Nextcloud Cookbook JSON schema (schema.org Recipe) stored in SQLite.
**Sync:** Nextcloud Cookbook Plugin API v1 via Android SSO.

### 1. Storage Architecture

- **Local-First:** All data resides in a local SQLite database (`recipes` + `grid_slots` + `pending_deletions` tables).
- **JSON Blob:** Each recipe row stores the full Nextcloud Cookbook JSON in a `json_data` column for lossless API round-tripping.
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
- **The Search:** SQLite LIKE queries across recipe name, category, and ingredients.
- **The Cook-Mode:** Integration of `wakelock` to keep the screen active.
- **The Import Engine:**
  - **From URL:** JSON-LD extraction + heuristic HTML scraping. Up to 5 image candidates detected.
  - **From Text:** JSON parsing (Nextcloud schema + alternate keys) or markdown-style heuristic parsing.
  - **Nextcloud Push:** Import directly to Nextcloud Cookbook via `POST /api/v1/recipes/import`.
- **The Sync Engine:**
  - Bidirectional sync comparing `dateModified` timestamps.
  - Manual trigger only (no background sync).
  - Conflict detection with user-facing resolution dialog (keep local / keep server).
  - Pending remote deletions are executed first at sync start.

### 4. Authentication

- **Nextcloud Android SSO** library v0.8.1 via platform channel (Kotlin ↔ Dart).
- Channel name: `de.karoc.smag/nextcloud_sso`
- Methods: `pickAccount`, `getCurrentAccount`, `resetAccount`, `performRequest`, `performBinaryRequest`.
- Requires the Nextcloud Android client to be installed on the device.

### 5. Navigation

Three-button `BottomNavigationBar`:

1. **View Toggle** — switches between recipe list and 7-slot grid
2. **Import** — URL and text import with Nextcloud push option
3. **Settings** — sync management, theme, language, about

Back button: Grid/Settings/Import always return to the main recipe overview.

Android share integration:

- `ACTION_SEND` (`text/plain`) and `ACTION_VIEW` (`http`/`https`) route URLs into the import flow.

### 6. Theming

- **Light:** Sage green (#6B8F71) primary, warm white (#F5F2ED) background.
- **OLED Dark:** Pure black (#000000) background, #0A0A0A surface.
- Fonts: Playfair Display (headlines), Inter (body), JetBrains Mono (code/editor).
