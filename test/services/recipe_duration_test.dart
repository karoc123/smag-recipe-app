import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smag/services/recipe_duration.dart';

void main() {
  group('RecipeDuration.toDisplay', () {
    test('renders compact display strings for edit forms', () {
      expect(RecipeDuration.toDisplay('P1DT2H15M'), '1d 2h 15min');
      expect(RecipeDuration.toDisplay('PT45M'), '45min');
      expect(RecipeDuration.toDisplay('PT0M'), '0min');
    });

    test('renders spaced display strings for read-only views', () {
      expect(
        RecipeDuration.toDisplay('PT20M30S', spacedUnits: true),
        '20 min 30 s',
      );
      expect(RecipeDuration.toDisplay('P1DT2H', spacedUnits: true), '1 d 2 h');
    });

    test('returns raw input for invalid values and empty for empty input', () {
      expect(RecipeDuration.toDisplay(''), '');
      expect(RecipeDuration.toDisplay('not-a-duration'), 'not-a-duration');
    });
  });

  group('RecipeDuration.toTimeOfDay', () {
    test('parses iso duration strings and normalizes days into hours', () {
      expect(
        RecipeDuration.toTimeOfDay('P1DT2H15M'),
        const TimeOfDay(hour: 2, minute: 15),
      );
      expect(
        RecipeDuration.toTimeOfDay('PT45M'),
        const TimeOfDay(hour: 0, minute: 45),
      );
    });

    test('returns null for empty or invalid values', () {
      expect(RecipeDuration.toTimeOfDay(''), isNull);
      expect(RecipeDuration.toTimeOfDay('nope'), isNull);
    });
  });

  group('RecipeDuration.fromTimeOfDay', () {
    test('converts a time of day into the stored iso-like format', () {
      expect(
        RecipeDuration.fromTimeOfDay(const TimeOfDay(hour: 1, minute: 5)),
        'P0DT1H5M',
      );
      expect(
        RecipeDuration.fromTimeOfDay(const TimeOfDay(hour: 0, minute: 0)),
        'P0DT0H0M',
      );
    });
  });
}
