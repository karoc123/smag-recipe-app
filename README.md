# SMAG

The Scandinavian Digital Cookbook.

SMAG is quiet software for recipes: local-first, offline-first, distraction-free, and built to last.

No feeds. No tracking. No noise between you and your food.

## Why SMAG

Most recipe apps fight for attention. SMAG protects it.

- **Privacy by design:** recipes stay local by default
- **Nextcloud Cookbook integration:** optional sync via the Nextcloud Android SSO library
- **No noise:** no social layer, no gamification, no addictive loops
- **Kitchen-ready:** fast, high-contrast reading, stay-awake recipe mode
- **OLED Dark theme:** pure black for night cooking

This project follows one rule: _Does this feature respect focus, or demand attention?_

## Core Experience

1. **Recipe Library** — category-first navigation, thumbnail list, swipe between recipes
2. **Weekly Planner** — dynamic drag-and-drop grid with exactly one trailing `+` tile
3. **Import** — from URL (web scraping + JSON-LD) or pasted text/JSON
4. **Nextcloud Sync** — bidirectional sync with conflict resolution via the Nextcloud Cookbook Plugin API

## Data Format

Recipes are stored locally in SQLite using the **Nextcloud Cookbook JSON schema** (schema.org `Recipe`). This ensures lossless round-tripping with the Nextcloud Cookbook API.

```json
{
  "name": "Pancakes",
  "recipeCategory": "Breakfast",
  "recipeYield": "4 servings",
  "prepTime": "PT10M",
  "cookTime": "PT15M",
  "recipeIngredient": ["2 cups flour", "1 egg", "1 cup milk"],
  "recipeInstructions": ["Mix ingredients", "Cook on griddle"]
}
```

## Import Workflow

**From URL:**

- **Import Locally:** extracts structured data via JSON-LD / HTML heuristics and lets you choose an image.
- **Send to Nextcloud:** uses Cookbook server-side import endpoint (`POST /apps/cookbook/api/v1/import`), so the server fetches and parses the URL.

**From Text:** paste recipe text (markdown-style) or strict JSON. Use the _Copy Prompt_ button to generate an AI-ready prompt for JSON output.

After parsing, choose: **Import Locally** or **Send to Nextcloud** (pushes to Cookbook API, then syncs).

Browser sharing is supported: choose **Share** on a URL and select SMAG to open the import flow with the URL pre-filled.

## Nextcloud Integration

SMAG authenticates via the [Nextcloud Android SSO](https://github.com/nextcloud/Android-SingleSignOn/) library (v0.8.1). The installed Nextcloud Android client handles authentication — no manual URL/password entry needed.

- Connect/disconnect in **Settings → Sync Management**
- Manual sync trigger (no background sync)
- Conflict resolution: side-by-side choice of local vs. server version
- Local delete of synced recipes is queued and executed remotely on the **next sync**

## Quick Start

```bash
flutter pub get
flutter gen-l10n
flutter run
```

## Build APK

```bash
flutter build apk --release --no-tree-shake-icons
```

## Platform Notes

- Application ID: `de.karoc.smag`
- Version: 2.0.0
- minSdk: 23
- Internal storage only (no broad external storage permissions)
- WAKE_LOCK for cooking session readability
- Requires Nextcloud Android client for SSO (optional)

## Development

```bash
flutter analyze
flutter test
```

## License

See LICENSE.
