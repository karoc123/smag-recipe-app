/// Normalize Nextcloud `dateModified` values for reliable equality checks.
///
/// Nextcloud responses may use equivalent timestamp formats like
/// `2026-04-18T10:00:00+0000` and `2026-04-18T10:00:00+00:00`.
/// This helper canonicalizes parseable values to UTC ISO-8601.
String normalizeSyncDateModified(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  final parsed = _tryParseDateModified(trimmed);
  if (parsed == null) {
    return trimmed;
  }

  return parsed.toUtc().toIso8601String();
}

DateTime? _tryParseDateModified(String value) {
  try {
    return DateTime.parse(value);
  } catch (_) {
    // Try alternate formats below.
  }

  final timezoneNoColon = RegExp(r'([+-]\d{2})(\d{2})$');
  final match = timezoneNoColon.firstMatch(value);
  if (match != null) {
    final fixed =
        '${value.substring(0, match.start)}${match.group(1)}:${match.group(2)}';
    try {
      return DateTime.parse(fixed);
    } catch (_) {
      // Fall through.
    }
  }

  return null;
}
