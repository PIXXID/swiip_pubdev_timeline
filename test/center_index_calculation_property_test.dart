import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/scroll_calculations.dart';

/// Property-Based Test for Center Item Calculation
///
/// **Feature: native-scroll-only, Property 2: Center Item Calculation**
/// **Validates: Requirements 2.3, 3.1, 3.2**
///
/// This test verifies that for any horizontal scroll offset and viewport width,
/// the calculated center item index matches the result of calculateCenterDateIndex()
/// with the same parameters, and corresponds to the day item visually centered
/// in the viewport.
///
/// The test generates random scroll offsets and viewport widths and verifies that:
/// 1. The calculated center index matches the pure function result
/// 2. The index is within valid range [0, totalDays-1]
/// 3. The calculation is consistent across multiple calls with same inputs
void main() {
  group('Property 2: Center Item Calculation', () {
    test('For any scroll offset and viewport width, center index should match pure function result', () {
      // Feature: native-scroll-only, Property 2: Center Item Calculation
      // Validates: Requirements 2.3, 3.1, 3.2

      const numIterations = 100;
      final random = Random(42); // Fixed seed for reproducibility

      // Test configuration
      const dayWidth = 45.0;
      const dayMargin = 5.0;
      const totalDays = 100;

      int passedTests = 0;

      for (int i = 0; i < numIterations; i++) {
        // Generate random scroll offset (0 to max possible scroll)
        final maxScroll = totalDays * (dayWidth - dayMargin);
        final scrollOffset = random.nextDouble() * maxScroll;

        // Generate random viewport width (300 to 2000 pixels)
        final viewportWidth = 300.0 + random.nextDouble() * 1700.0;

        try {
          // Calculate center index using pure function
          final centerIndex = calculateCenterDateIndex(
            scrollOffset: scrollOffset,
            viewportWidth: viewportWidth,
            dayWidth: dayWidth,
            dayMargin: dayMargin,
            totalDays: totalDays,
          );

          // Verify index is within valid range [0, totalDays-1]
          final isInRange = centerIndex >= 0 && centerIndex < totalDays;

          // Calculate expected center index manually to verify formula
          final centerPosition = scrollOffset + (viewportWidth / 2);
          final expectedIndex = (centerPosition / (dayWidth - dayMargin)).round();
          final clampedExpected = expectedIndex.clamp(0, totalDays - 1);

          // Verify calculated index matches expected
          final matchesExpected = centerIndex == clampedExpected;

          if (isInRange && matchesExpected) {
            passedTests++;
          } else {
            print(
                'Iteration $i failed: scrollOffset=$scrollOffset, viewportWidth=$viewportWidth, centerIndex=$centerIndex, expectedIndex=$clampedExpected, isInRange=$isInRange, matchesExpected=$matchesExpected');
          }
        } catch (e) {
          print('Iteration $i failed with scrollOffset=$scrollOffset, viewportWidth=$viewportWidth: $e');
        }
      }

      // Verify that all iterations passed
      expect(passedTests, equals(numIterations),
          reason: 'Property test failed: $passedTests/$numIterations iterations passed. '
              'Expected center index to match pure function result and be within valid range.');
    });

    test('Center index calculation is consistent across multiple calls', () {
      // Feature: native-scroll-only, Property 2: Center Item Calculation
      // Validates: Requirements 2.3, 3.1, 3.2

      const numIterations = 100;
      final random = Random(42); // Fixed seed for reproducibility

      // Test configuration
      const dayWidth = 45.0;
      const dayMargin = 5.0;
      const totalDays = 100;

      int passedTests = 0;

      for (int i = 0; i < numIterations; i++) {
        // Generate random parameters
        final maxScroll = totalDays * (dayWidth - dayMargin);
        final scrollOffset = random.nextDouble() * maxScroll;
        final viewportWidth = 300.0 + random.nextDouble() * 1700.0;

        try {
          // Call function multiple times with same inputs
          final result1 = calculateCenterDateIndex(
            scrollOffset: scrollOffset,
            viewportWidth: viewportWidth,
            dayWidth: dayWidth,
            dayMargin: dayMargin,
            totalDays: totalDays,
          );

          final result2 = calculateCenterDateIndex(
            scrollOffset: scrollOffset,
            viewportWidth: viewportWidth,
            dayWidth: dayWidth,
            dayMargin: dayMargin,
            totalDays: totalDays,
          );

          final result3 = calculateCenterDateIndex(
            scrollOffset: scrollOffset,
            viewportWidth: viewportWidth,
            dayWidth: dayWidth,
            dayMargin: dayMargin,
            totalDays: totalDays,
          );

          // Verify all results are identical (pure function property)
          if (result1 == result2 && result2 == result3) {
            passedTests++;
          } else {
            print('Iteration $i: Inconsistent results - result1=$result1, result2=$result2, result3=$result3');
          }
        } catch (e) {
          print('Iteration $i failed with scrollOffset=$scrollOffset, viewportWidth=$viewportWidth: $e');
        }
      }

      // Verify that all iterations passed
      expect(passedTests, equals(numIterations),
          reason: 'Property test failed: $passedTests/$numIterations iterations passed. '
              'Expected center index calculation to be consistent (pure function).');
    });

    test('Center index handles edge cases correctly', () {
      // Feature: native-scroll-only, Property 2: Center Item Calculation
      // Validates: Requirements 2.3, 3.1, 3.2

      const dayWidth = 45.0;
      const dayMargin = 5.0;
      const totalDays = 100;

      // Test edge case: scroll at start (offset = 0)
      final centerAtStart = calculateCenterDateIndex(
        scrollOffset: 0.0,
        viewportWidth: 800.0,
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: totalDays,
      );
      expect(centerAtStart, greaterThanOrEqualTo(0));
      expect(centerAtStart, lessThan(totalDays));

      // Test edge case: scroll at end
      final maxScroll = totalDays * (dayWidth - dayMargin);
      final centerAtEnd = calculateCenterDateIndex(
        scrollOffset: maxScroll,
        viewportWidth: 800.0,
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: totalDays,
      );
      expect(centerAtEnd, greaterThanOrEqualTo(0));
      expect(centerAtEnd, lessThan(totalDays));

      // Test edge case: very small viewport
      final centerSmallViewport = calculateCenterDateIndex(
        scrollOffset: 1000.0,
        viewportWidth: 100.0,
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: totalDays,
      );
      expect(centerSmallViewport, greaterThanOrEqualTo(0));
      expect(centerSmallViewport, lessThan(totalDays));

      // Test edge case: very large viewport
      final centerLargeViewport = calculateCenterDateIndex(
        scrollOffset: 1000.0,
        viewportWidth: 5000.0,
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: totalDays,
      );
      expect(centerLargeViewport, greaterThanOrEqualTo(0));
      expect(centerLargeViewport, lessThan(totalDays));

      // Test edge case: empty timeline (totalDays = 0)
      final centerEmpty = calculateCenterDateIndex(
        scrollOffset: 0.0,
        viewportWidth: 800.0,
        dayWidth: dayWidth,
        dayMargin: dayMargin,
        totalDays: 0,
      );
      expect(centerEmpty, equals(0));
    });

    test('Center index corresponds to visually centered day', () {
      // Feature: native-scroll-only, Property 2: Center Item Calculation
      // Validates: Requirements 2.3, 3.1, 3.2

      const numIterations = 100;
      final random = Random(42); // Fixed seed for reproducibility

      // Test configuration
      const dayWidth = 45.0;
      const dayMargin = 5.0;
      const totalDays = 100;

      int passedTests = 0;

      for (int i = 0; i < numIterations; i++) {
        // Generate random parameters - limit scroll and viewport to reasonable ranges
        // to avoid edge cases where viewport extends beyond timeline
        final maxReasonableScroll = (totalDays - 20) * (dayWidth - dayMargin);
        final scrollOffset = random.nextDouble() * maxReasonableScroll;
        final viewportWidth = 300.0 + random.nextDouble() * 1200.0; // Max 1500px viewport

        try {
          // Calculate center index
          final centerIndex = calculateCenterDateIndex(
            scrollOffset: scrollOffset,
            viewportWidth: viewportWidth,
            dayWidth: dayWidth,
            dayMargin: dayMargin,
            totalDays: totalDays,
          );

          // Calculate the visual position of the center of the viewport
          final viewportCenter = scrollOffset + (viewportWidth / 2);

          // Calculate the visual position of the center day
          final dayCenter = centerIndex * (dayWidth - dayMargin) + ((dayWidth - dayMargin) / 2);

          // The difference should be less than one full day width
          // (due to rounding in the calculation, the center can be off by up to half a day)
          final difference = (viewportCenter - dayCenter).abs();
          final tolerance = (dayWidth - dayMargin);

          if (difference <= tolerance) {
            passedTests++;
          } else {
            print(
                'Iteration $i: Visual mismatch - viewportCenter=$viewportCenter, dayCenter=$dayCenter, difference=$difference, tolerance=$tolerance');
          }
        } catch (e) {
          print('Iteration $i failed with scrollOffset=$scrollOffset, viewportWidth=$viewportWidth: $e');
        }
      }

      // Verify that all iterations passed
      expect(passedTests, equals(numIterations),
          reason: 'Property test failed: $passedTests/$numIterations iterations passed. '
              'Expected center index to correspond to visually centered day.');
    });
  });
}
