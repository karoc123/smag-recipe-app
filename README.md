# SMAG

The Scandinavian Digital Cookbook.

SMAG is quiet software for recipes: local-first, offline-first, distraction-free, and built to last.

No feeds. No tracking. No account wall between you and your food.

## Why SMAG

Most recipe apps fight for attention.
SMAG protects it.

- Privacy by design: recipes stay local by default
- No noise: no social layer, no gamification, no addictive loops
- Long-term readability: plain Markdown + TOML frontmatter
- Kitchen-ready: fast, high contrast reading, stay-awake recipe mode

This project follows one rule:
Does this feature respect focus, or demand attention?

## Core Experience

1. Recipe-first home

- Open the app into a calm recipe library
- Browse categories like a family cookbook
- Open a recipe and swipe left or right inside that category

2. Weekly rhythm grid

- Drag recipes into a planning grid
- Grid is unbounded but always keeps exactly one trailing plus tile
- Fill the plus tile, a new plus tile appears

3. Offline-first with optional cloud sync

- Storage is app-private internal storage (Play Store compliant)
- Optional manual WebDAV sync for Nextcloud and compatible servers

## Data Ownership

SMAG stores recipes in your internal app data directory:

- config.toml
- images/
- CategoryName/recipe-title.md

Recipe format stays portable and future-proof:

```toml
+++
title = "Pancakes"
date = 2026-04-15T08:00:00Z
category = "Breakfast"
[extra]
servings = "2"
prep_time = "10 min"
cook_time = "10 min"
+++
```

```markdown
{{< figure src="/images/pancakes.jpg" >}}

## Ingredients

- ...

## Instructions

1. ...
```

## Import Workflow

SMAG supports two import paths:

1. From URL

- Extracts title, ingredients, instructions, and image candidates
- Lets you pick one of up to five detected images

2. From Text

- Paste normal recipe text
- Or use Copy Prompt to ask an AI for strict JSON output and paste it directly

Accepted JSON shape:

```json
{
  "title": "Kartoffelsuppe",
  "category": "Suppen",
  "servings": "4",
  "prep_time": "20 min",
  "cook_time": "30 min",
  "image": "https://example.com/image.jpg",
  "ingredients": ["1 kg Kartoffeln", "1 Zwiebel"],
  "instructions": ["Alles schneiden.", "30 Minuten kochen."],
  "notes": "Optional",
  "source_url": "https://example.com"
}
```

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

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## WebDAV Sync

- Open cloud icon in top app bar
- Enter WebDAV URL, username, app password/token, and remote path
- Save and run manual sync

Current sync mode is local-to-remote mirror (manual trigger).

## Platform Notes

- Application ID: de.karoc.smag
- minSdk: 23
- Internal storage only (no broad external storage permissions)
- WAKE_LOCK used for cooking session readability

## Development

```bash
flutter analyze
flutter test
```

## License

See LICENSE.
