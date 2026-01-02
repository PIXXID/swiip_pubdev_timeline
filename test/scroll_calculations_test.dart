import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/scroll_calculations.dart';
import 'helpers/test_helpers.dart';

void main() {
  group('calculateCenterDateIndex', () {
    group('Unit Tests', () {
      test('returns 0 when scroll offset is at start (0)', () {
        // Arrange
        const scrollOffset = 0.0;
        const viewportWidth = 800.0;
        const dayWidth = 100.0;
        const dayMargin = 5.0;
        const totalDays = 100;

        // Act
        final result = calculateCenterDateIndex(
          scrollOffset: scrollOffset,
          viewportWidth: viewportWidth,
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
        );

        // Assert
        // Center position = 0 + 800/2 = 400
        // Center index = 400 / (100 - 5) = 400 / 95 ≈ 4.2 → rounds to 4
        expect(result, equals(4));
        TestHelpers.expectIndexInBounds(result, 0, totalDays - 1);
      });

      test('returns last valid index when scroll offset is at maximum', () {
        // Arrange
        const scrollOffset = 10000.0; // Very large offset
        const viewportWidth = 800.0;
        const dayWidth = 100.0;
        const dayMargin = 5.0;
        const totalDays = 100;

        // Act
        final result = calculateCenterDateIndex(
          scrollOffset: scrollOffset,
          viewportWidth: viewportWidth,
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
        );

        // Assert
        // Should be clamped to totalDays - 1
        expect(result, equals(totalDays - 1));
        TestHelpers.expectIndexInBounds(result, 0, totalDays - 1);
      });

      test('returns 0 when timeline is empty (totalDays = 0)', () {
        // Arrange
        const scrollOffset = 500.0;
        const viewportWidth = 800.0;
        const dayWidth = 100.0;
        const dayMargin = 5.0;
        const totalDays = 0;

        // Act
        final result = calculateCenterDateIndex(
          scrollOffset: scrollOffset,
          viewportWidth: viewportWidth,
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
        );

        // Assert
        expect(result, equals(0));
      });

      test('handles negative scroll offset (overscroll) gracefully', () {
        // Arrange
        const scrollOffset = -100.0; // Negative offset (overscroll/bounce)
        const viewportWidth = 800.0;
        const dayWidth = 100.0;
        const dayMargin = 5.0;
        const totalDays = 100;

        // Act
        final result = calculateCenterDateIndex(
          scrollOffset: scrollOffset,
          viewportWidth: viewportWidth,
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
        );

        // Assert
        // Center position = -100 + 800/2 = 300
        // Center index = 300 / 95 ≈ 3.2 → rounds to 3
        // Should be clamped to valid range [0, 99]
        expect(result, equals(3));
        TestHelpers.expectIndexInBounds(result, 0, totalDays - 1);
      });

      test('handles boundary values correctly', () {
        // Arrange - Test exact boundary where center index should be at edge
        // This test verifies that the calculation works correctly when the viewport
        // is positioned such that the center should be exactly at the last day.
        const totalDays = 50;
        const dayWidth = 100.0;
        const dayMargin = 5.0;
        const viewportWidth = 800.0;

        // Calculate scroll offset that should put us exactly at the last day
        // The effective day width is (dayWidth - dayMargin) = 95
        // For last day (index 49): centerPosition = 49 * 95 = 4655
        // scrollOffset = centerPosition - viewportWidth/2 = 4655 - 400 = 4255
        const scrollOffset = 4255.0;

        // Act
        final result = calculateCenterDateIndex(
          scrollOffset: scrollOffset,
          viewportWidth: viewportWidth,
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
        );

        // Assert
        expect(result, equals(49)); // Last valid index
        TestHelpers.expectIndexInBounds(result, 0, totalDays - 1);
      });

      test('calculates correct center index for middle position', () {
        // Arrange - Test calculation at a typical middle scroll position
        // This verifies the core calculation formula works correctly
        const scrollOffset = 2000.0;
        const viewportWidth = 800.0;
        const dayWidth = 100.0;
        const dayMargin = 5.0;
        const totalDays = 100;

        // Act
        final result = calculateCenterDateIndex(
          scrollOffset: scrollOffset,
          viewportWidth: viewportWidth,
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
        );

        // Assert
        // Calculation breakdown:
        // 1. Center position in timeline = scrollOffset + (viewportWidth / 2)
        //    = 2000 + 400 = 2400
        // 2. Effective day width = dayWidth - dayMargin = 100 - 5 = 95
        // 3. Center index = centerPosition / effectiveDayWidth
        //    = 2400 / 95 ≈ 25.26 → rounds to 25
        expect(result, equals(25));
        TestHelpers.expectIndexInBounds(result, 0, totalDays - 1);
      });

      test('handles single day timeline', () {
        // Arrange
        const scrollOffset = 100.0;
        const viewportWidth = 800.0;
        const dayWidth = 100.0;
        const dayMargin = 5.0;
        const totalDays = 1;

        // Act
        final result = calculateCenterDateIndex(
          scrollOffset: scrollOffset,
          viewportWidth: viewportWidth,
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
        );

        // Assert
        // With only 1 day, result should always be 0
        expect(result, equals(0));
      });

      test('handles very small viewport width', () {
        // Arrange
        const scrollOffset = 500.0;
        const viewportWidth = 100.0; // Small viewport
        const dayWidth = 100.0;
        const dayMargin = 5.0;
        const totalDays = 100;

        // Act
        final result = calculateCenterDateIndex(
          scrollOffset: scrollOffset,
          viewportWidth: viewportWidth,
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
        );

        // Assert
        // Center position = 500 + 100/2 = 550
        // Center index = 550 / 95 ≈ 5.8 → rounds to 6
        expect(result, equals(6));
        TestHelpers.expectIndexInBounds(result, 0, totalDays - 1);
      });

      test('handles very large viewport width', () {
        // Arrange
        const scrollOffset = 500.0;
        const viewportWidth = 5000.0; // Large viewport
        const dayWidth = 100.0;
        const dayMargin = 5.0;
        const totalDays = 100;

        // Act
        final result = calculateCenterDateIndex(
          scrollOffset: scrollOffset,
          viewportWidth: viewportWidth,
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
        );

        // Assert
        // Center position = 500 + 5000/2 = 3000
        // Center index = 3000 / 95 ≈ 31.6 → rounds to 32
        expect(result, equals(32));
        TestHelpers.expectIndexInBounds(result, 0, totalDays - 1);
      });

      test('handles different day width and margin combinations', () {
        // Arrange
        const scrollOffset = 1000.0;
        const viewportWidth = 800.0;
        const dayWidth = 50.0; // Smaller day width
        const dayMargin = 2.0; // Smaller margin
        const totalDays = 200;

        // Act
        final result = calculateCenterDateIndex(
          scrollOffset: scrollOffset,
          viewportWidth: viewportWidth,
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: totalDays,
        );

        // Assert
        // Center position = 1000 + 800/2 = 1400
        // Center index = 1400 / (50 - 2) = 1400 / 48 ≈ 29.2 → rounds to 29
        expect(result, equals(29));
        TestHelpers.expectIndexInBounds(result, 0, totalDays - 1);
      });
    });
  });
}
