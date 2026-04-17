import 'package:flutter/material.dart';

class RecipeDuration {
  static final RegExp _isoDurationPattern = RegExp(
    r'^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$',
  );

  static String toDisplay(String isoDuration, {bool spacedUnits = false}) {
    if (isoDuration.isEmpty) return '';

    final parts = _parseParts(isoDuration);
    if (parts == null) return isoDuration;

    final segments = <String>[
      if (parts.days > 0) _formatPart(parts.days, 'd', spacedUnits),
      if (parts.hours > 0) _formatPart(parts.hours, 'h', spacedUnits),
      if (parts.minutes > 0) _formatPart(parts.minutes, 'min', spacedUnits),
      if (parts.seconds > 0) _formatPart(parts.seconds, 's', spacedUnits),
    ];

    if (segments.isEmpty) {
      return _formatPart(0, 'min', spacedUnits);
    }

    return segments.join(' ');
  }

  static TimeOfDay? toTimeOfDay(String isoDuration) {
    final parts = _parseParts(isoDuration);
    if (parts == null) return null;

    final normalizedHours = ((parts.days * 24) + parts.hours) % 24;
    return TimeOfDay(hour: normalizedHours, minute: parts.minutes.clamp(0, 59));
  }

  static String fromTimeOfDay(TimeOfDay time) {
    return 'P0DT${time.hour}H${time.minute}M';
  }

  static _DurationParts? _parseParts(String isoDuration) {
    if (isoDuration.isEmpty) return null;

    final match = _isoDurationPattern.firstMatch(isoDuration);
    if (match == null) return null;

    return _DurationParts(
      days: int.tryParse(match.group(1) ?? '0') ?? 0,
      hours: int.tryParse(match.group(2) ?? '0') ?? 0,
      minutes: int.tryParse(match.group(3) ?? '0') ?? 0,
      seconds: int.tryParse(match.group(4) ?? '0') ?? 0,
    );
  }

  static String _formatPart(int value, String unit, bool spacedUnits) {
    return spacedUnits ? '$value $unit' : '$value$unit';
  }
}

class _DurationParts {
  final int days;
  final int hours;
  final int minutes;
  final int seconds;

  const _DurationParts({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
  });
}
