# SMAG - Simple Meal Archive Gallery

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
4. **Nextcloud Sync** — bidirectional sync with field-level conflict comparison and a copyable sync log via the [Nextcloud Cookbook Plugin API](https://github.com/nextcloud/cookbook)

## Navigation

- App-wide top bar actions: **Search** and **Settings**.
- Bottom-right floating actions:
  - **Add (`+`)** in recipe view
  - **List/Grid Toggle** always visible, positioned directly to the right of `+` in recipe view and in the same position in grid view
- The **Add (`+`)** action opens a chooser:
  - **New Recipe**: opens the recipe editor
  - **Import**: opens the import screen (URL/Text tabs)
- Import and Settings are opened as dedicated screens and return to the recipe view on back navigation.
- Settings include direct links to GitHub and Privacy Policy.

## Import Workflow

**From URL:**

- **Import Locally:** extracts structured data via JSON-LD / HTML heuristics and lets you choose an image.
  Local gallery images are copied into SMAG-managed app storage so they remain stable even if the original picker path disappears.
- **Send to Nextcloud:** uses Cookbook server-side import endpoint (`POST /apps/cookbook/api/v1/import`), so the server fetches and parses the URL.

**From Text:** paste recipe text (markdown-style) or strict JSON. Use the _Copy Prompt_ button to generate an AI-ready prompt for JSON output.

After parsing, choose: **Import Locally** or **Send to Nextcloud** (pushes to Cookbook API, then syncs).

URL sharing is supported: choose **Share** on a URL and select SMAG to open the import flow with the URL pre-filled.
SMAG does not claim generic browser links (`http/https`) as a default handler.

## Nextcloud Integration

SMAG authenticates via the [Nextcloud Android SSO](https://github.com/nextcloud/Android-SingleSignOn/) library (v1.3.4). The installed Nextcloud Android client handles authentication — no manual URL/password entry needed.

- Connect/disconnect in **Settings → Sync Management**
- Manual sync trigger (no background sync)
- Sync runs in a dedicated **Sync Log** screen with a copyable action log
- Locally selected recipe images are uploaded to your Nextcloud files and referenced from Cookbook during sync
- Conflict resolution: local vs. server comparison including differing fields and values
- Unresolved conflicts remain explicit and are not auto-overwritten on the next sync run
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
