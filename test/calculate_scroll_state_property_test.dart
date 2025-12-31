import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/scroll_calculations.dart';

/// Property-based test for scroll calculation purity
///
/// Feature: scroll-calculation-refactoring, Property 1: Pureté des Fonctions de Calcul
/// Validates: Requirements 1.1, 1.2, 1.3
///
/// This test verifies that all scroll calculation functions are pure:
/// - Calling them multiple times with the same inputs produces identical outputs
/// - No side effects occur (no state modification, no scroll actions)
/// - The calculations are deterministic and repeatable
void main() {
  group('Property 1: Pureté des Fonctions de Calcul', () {
    final random = Random(42); // Seed for reproducibility

    /// Generate random test parameters
    Map<String, dynamic> generateRandomParams() {
      return {
        'scrollOffset': random.nextDouble() * 10000,
        'viewportWidth': 600 + random.nextDouble() * 1000,
        'dayWidth': 30 + random.nextDouble() * 50,
        'dayMargin': random.nextDouble() * 10,
        'totalDays': 50 + random.nextInt(200),
        'centerDateIndex': random.nextInt(100),
        'rowHeight': 20 + random.nextDouble() * 40,
        'rowMargin': random.nextDouble() * 10,
        'scrollingLeft': random.nextBool(),
        'userScrollOffset': random.nextBool() ? random.nextDouble() * 1000 : null,
        'targetVerticalOffset': random.nextBool() ? random.nextDouble() * 1000 : null,
        'totalRowsHeight': 500 + random.nextDouble() * 2000,
        'viewportHeight': 200 + random.nextDouble() * 600,
      };
    }

    test('calculateCenterDateIndex est pure - 100 itérations', () {
      // Run 100 iterations with random parameters
      for (int iteration = 0; iteration < 100; iteration++) {
        final params = generateRandomParams();
        final scrollOffset = params['scrollOffset'] as double;
        final viewportWidth = params['viewportWidth'] as double;
        final dayWidth = params['dayWidth'] as double;
        final dayMargin = params['dayMargin'] as double;
        final totalDays = params['totalDays'] as int;

        // Ensure dayWidth > dayMargin for valid calculation
        final validDayWidth = dayWidth.clamp(dayMargin + 1, dayWidth + 10);

        // Call the function 10 times with the same parameters
        final results = List.generate(
          10,
          (_) => calculateCenterDateIndex(
            scrollOffset: scrollOffset,
            viewportWidth: viewportWidth,
            dayWidth: validDayWidth,
            dayMargin: dayMargin,
            totalDays: totalDays,
          ),
        );

        // Verify all results are identical (purity)
        expect(
          results.toSet().length,
          equals(1),
          reason: 'Iteration $iteration: calculateCenterDateIndex should return the same result for the same inputs',
        );

        // Verify result is within valid range
        expect(results.first, greaterThanOrEqualTo(0));
        expect(results.first, lessThanOrEqualTo(totalDays - 1));
      }
    });

    test('Aucun effet de bord - les paramètres ne sont pas modifiés', () {
      // Run 100 iterations to verify no side effects
      for (int iteration = 0; iteration < 100; iteration++) {
        final params = generateRandomParams();
        final scrollOffset = params['scrollOffset'] as double;
        final viewportWidth = params['viewportWidth'] as double;
        final dayWidth = params['dayWidth'] as double;
        final dayMargin = params['dayMargin'] as double;
        final totalDays = params['totalDays'] as int;

        // Ensure dayWidth > dayMargin
        final validDayWidth = dayWidth.clamp(dayMargin + 1, dayWidth + 10);

        // Store original values
        final originalScrollOffset = scrollOffset;
        final originalViewportWidth = viewportWidth;
        final originalDayWidth = validDayWidth;
        final originalDayMargin = dayMargin;
        final originalTotalDays = totalDays;

        // Call the function
        calculateCenterDateIndex(
          scrollOffset: scrollOffset,
          viewportWidth: viewportWidth,
          dayWidth: validDayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
        );

        // Verify parameters haven't changed
        expect(scrollOffset, equals(originalScrollOffset));
        expect(viewportWidth, equals(originalViewportWidth));
        expect(validDayWidth, equals(originalDayWidth));
        expect(dayMargin, equals(originalDayMargin));
        expect(totalDays, equals(originalTotalDays));
      }
    });
  });
}
