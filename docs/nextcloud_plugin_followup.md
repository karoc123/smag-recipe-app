# Nextcloud Cookbook Plugin Follow-up Ideas

This app refactor intentionally does not modify the plugin code. The items below are optional improvements for a future plugin-side iteration.

## 1. Expose an Image Upload Endpoint

### 1.1 Current App Behavior

SMAG stages a temporary image file inside the configured cookbook folder via WebDAV, then sends that path in `image` during recipe create/update.

### 1.2 Suggested Enhancement

Add an API endpoint that accepts raw image bytes directly and stores them in the recipe folder as `full.jpg` (including thumbnail regeneration).

### 1.3 Benefits

- No temporary staged files needed
- Smaller client responsibility surface
- Cleaner transactional flow on the server

## 2. Return Canonical Image Reference in Recipe API

### 2.1 Current Plugin Reality

`image` values can vary (relative `full.jpg`, absolute-like paths depending on source data/history).

### 2.2 Suggested Enhancement

Normalize API responses to a canonical image reference (for example always `full.jpg` for managed recipe images).

### 2.3 Benefits

- Fewer client-side image alias heuristics
- Cleaner conflict diffs

## 3. Add Optional Strict Folder Guard Diagnostics

### 3.1 Suggested Enhancement

Return folder metadata in config response, such as:

- normalized effective folder path
- whether folder exists and is writable

### 3.2 Benefits

- Better sync diagnostics in client apps
- Faster user support for misconfigured cookbook folders

## 4. Optional Draft Recipe Transaction API

### 4.1 Suggested Enhancement

Introduce a lightweight transaction flow:

1. create draft recipe id
2. upload image to draft
3. commit recipe JSON + image atomically

### 4.2 Benefits

- Better failure handling for unstable networks
- Easier idempotent retries from mobile clients
