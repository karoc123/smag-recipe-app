### _The Scandinavian Digital Cookbook_

**SMAG** (Danish/Norwegian for "Taste" or "Flavor") is **Quiet Software**. It is an open-source recipe manager built as a counter-movement to noisy, ad-filled, and cloud-dependent applications. This is a serene, secure vault for culinary knowledge—a tool designed to respect the human being behind the screen.

---

## 1. Philosophy: Respect by Restraint

This is software built on a foundation of intentional restraint.

- **Privacy by Design:** There are no accounts and no tracking. Data remains strictly local by default. Optional Nextcloud sync keeps data on infrastructure the user controls.
- **No "Gedöns" (No Noise):** There is a deliberate rejection of social feeds, "smart" recommendations, or gamification. This is a focused tool, not a time-thief.
- **Built for Longevity:** This project prioritizes decades over trends. By utilizing the Nextcloud Cookbook JSON schema (schema.org Recipe), recipes remain portable and interoperable with the open ecosystem.

## 2. Design Language: Scandinavian Clarity

The aesthetic follows the Northern tradition where **form follows function**, wrapped in minimalist beauty.

- **Essentialism:** Every screen utilizes white space and intentional typography. Elegant Serif fonts are used for recipes to evoke the tactile feeling of a high-quality, linen-bound physical cookbook.
- **Visual Serenity:** A palette of natural tones—slate, sage, and pale wood—creates a stress-free environment that complements the kitchen.
- **Organic Interaction:** The UI is snappy and responsive—a "hygge" experience that feels natural and fluid rather than clinical or robotic.

## 3. The Three Pillars of SMAG

### I. The Recipe Vault (Data Sovereignty)

This is a system that treats recipes as digital heirlooms. Everything is stored locally in **SQLite** using the **Nextcloud Cookbook JSON schema**.

- **Interoperability:** The schema.org Recipe format ensures recipes can be synced with Nextcloud Cookbook, exported, or processed by any tool understanding this standard.
- **Transparency:** Recipes can be synced via the Nextcloud Cookbook Plugin, keeping data on self-hosted infrastructure without proprietary barriers.

### II. The Meal Planner Grid

Meal planning is stripped of its administrative burden. The rigid calendar is replaced by a **visual grid of squares**.

- **Intuition over Logistics:** Favorites are simply dragged and dropped into the weekly cycle.
- **Flexibility:** An empty slot is an invitation for spontaneity, not a reminder of a failure to plan.
- **Clarity:** The grid provides a beautiful, gallery-like overview of the week at a single glance.

### III. The Cooking Ritual

At the stove, the app transforms into a dedicated kitchen assistant.

- **Stay-Awake:** The screen remains active as long as a recipe is open to prevent the need for touching the display with messy fingers.
- **Kitchen-Optimized:** The reading view is optimized for the cooking environment—high contrast, large type, and a complete absence of distractions.

---

### The Guiding Principle

Every feature must pass a singular test: **"Does this respect the user's focus, or does it demand their attention?"** If it adds noise, it does not belong in SMAG.
