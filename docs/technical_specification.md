**Framework:** Flutter
**Data Format:** Hugo-compatible Markdown (.md) with TOML frontmatter (`+++`).

### 1. Storage Architecture

- **Local-First:** All data resides in a user-defined local directory (perfect for Nextcloud/Syncthing).
- **Folder Hierarchy:** Categories = Folders.
- **Assets:** Images are stored in a relative `/images` folder, ensuring the Markdown file remains portable.

### 2. The SMAG File Standard

Files follow the Hugo static site generator structure:

```toml
+++
title = "Pornokuchen"
date = 2026-04-14T23:45:00Z
category = "Desserts"
[extra]
slot = 3  # Link to the 7-day grid
+++

{{< figure src="/images/pornokuchen.jpg" >}}

## Ingredients
- ...
```

### 3. Core Functional Pillars

- **The Grid:** A 7-square visual dashboard. Users assign recipes to slots via a simple toggle in the recipe view. Slots are managed in a local `config.toml`.
- **The Hybrid Search:** A local SQLite FTS5 index enables instant full-text searching across all Markdown files without needing a backend.
- **The Cook-Mode:** Integration of `wakelock` to keep the screen active.
- **The Portability Engine:**
  - **Import:** Local scraper converts URLs to SMAG-formatted Markdown.
  - **Export:** Generates a `.zip` archive containing the `.md` files, images, and a plan-manifest for easy sharing between devices without overwriting existing local edits.
