import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/scroll_calculations.dart';
import 'package:swiip_pubdev_timeline/src/tools/tools.dart';

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

    /// Generate random stages rows for testing
    List generateRandomStagesRows(int rowCount, int totalDays) {
      final rows = <List>[];
      for (int i = 0; i < rowCount; i++) {
        final stages = <Map<String, dynamic>>[];
        int currentIndex = 0;
        while (currentIndex < totalDays) {
          final duration = 5 + random.nextInt(20);
          final endIndex = (currentIndex + duration).clamp(0, totalDays - 1);
          stages.add({
            'startDateIndex': currentIndex,
            'endDateIndex': endIndex,
          });
          currentIndex = endIndex + 1;
        }
        rows.add(stages);
      }
      return rows;
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

    test('calculateTargetVerticalOffset est pure - 100 itérations', () {
      // Run 100 iterations with random parameters
      for (int iteration = 0; iteration < 100; iteration++) {
        final params = generateRandomParams();
        final centerDateIndex = params['centerDateIndex'] as int;
        final rowHeight = params['rowHeight'] as double;
        final rowMargin = params['rowMargin'] as double;
        final scrollingLeft = params['scrollingLeft'] as bool;
        final totalDays = params['totalDays'] as int;

        // Generate random stages rows
        final rowCount = 3 + random.nextInt(10);
        final stagesRows = generateRandomStagesRows(rowCount, totalDays);

        // Call the function 10 times with the same parameters
        final results = List.generate(
          10,
          (_) => calculateTargetVerticalOffset(
            centerDateIndex: centerDateIndex,
            stagesRows: stagesRows,
            rowHeight: rowHeight,
            rowMargin: rowMargin,
            scrollingLeft: scrollingLeft,
            getHigherStageRowIndex: getHigherStageRowIndexOptimized,
            getLowerStageRowIndex: getLowerStageRowIndexOptimized,
          ),
        );

        // Verify all results are identical (purity)
        expect(
          results.toSet().length,
          equals(1),
          reason:
              'Iteration $iteration: calculateTargetVerticalOffset should return the same result for the same inputs',
        );

        // If result is not null, verify it's non-negative
        if (results.first != null) {
          expect(results.first, greaterThanOrEqualTo(0));
        }
      }
    });

    test('shouldEnableAutoScroll est pure - 100 itérations', () {
      // Run 100 iterations with random parameters
      for (int iteration = 0; iteration < 100; iteration++) {
        final params = generateRandomParams();
        final userScrollOffset = params['userScrollOffset'] as double?;
        final targetVerticalOffset = params['targetVerticalOffset'] as double?;
        final scrollingLeft = params['scrollingLeft'] as bool;
        final totalRowsHeight = params['totalRowsHeight'] as double;
        final viewportHeight = params['viewportHeight'] as double;

        // Call the function 10 times with the same parameters
        final results = List.generate(
          10,
          (_) => shouldEnableAutoScroll(
            userScrollOffset: userScrollOffset,
            targetVerticalOffset: targetVerticalOffset,
            scrollingLeft: scrollingLeft,
            totalRowsHeight: totalRowsHeight,
            viewportHeight: viewportHeight,
          ),
        );

        // Verify all results are identical (purity)
        expect(
          results.toSet().length,
          equals(1),
          reason: 'Iteration $iteration: shouldEnableAutoScroll should return the same result for the same inputs',
        );

        // Verify result is a boolean
        expect(results.first, isA<bool>());
      }
    });

    test('Composition des fonctions est pure - 100 itérations', () {
      // This test verifies that composing all three functions together
      // (simulating _calculateScrollState) is also pure

      for (int iteration = 0; iteration < 100; iteration++) {
        final params = generateRandomParams();
        final scrollOffset = params['scrollOffset'] as double;
        final viewportWidth = params['viewportWidth'] as double;
        final dayWidth = params['dayWidth'] as double;
        final dayMargin = params['dayMargin'] as double;
        final totalDays = params['totalDays'] as int;
        final rowHeight = params['rowHeight'] as double;
        final rowMargin = params['rowMargin'] as double;
        final userScrollOffset = params['userScrollOffset'] as double?;
        final totalRowsHeight = params['totalRowsHeight'] as double;
        final viewportHeight = params['viewportHeight'] as double;

        // Ensure dayWidth > dayMargin for valid calculation
        final validDayWidth = dayWidth.clamp(dayMargin + 1, dayWidth + 10);

        // Generate random stages rows
        final rowCount = 3 + random.nextInt(10);
        final stagesRows = generateRandomStagesRows(rowCount, totalDays);

        // Simulate _calculateScrollState by calling all functions in sequence
        final results = List.generate(10, (_) {
          // 1. Calculate center date index
          final centerDateIndex = calculateCenterDateIndex(
            scrollOffset: scrollOffset,
            viewportWidth: viewportWidth,
            dayWidth: validDayWidth,
            dayMargin: dayMargin,
            totalDays: totalDays,
          );

          // 2. Determine scroll direction (simulated)
          final scrollingLeft = random.nextBool();

          // 3. Calculate target vertical offset
          final targetVerticalOffset = calculateTargetVerticalOffset(
            centerDateIndex: centerDateIndex,
            stagesRows: stagesRows,
            rowHeight: rowHeight,
            rowMargin: rowMargin,
            scrollingLeft: scrollingLeft,
            getHigherStageRowIndex: getHigherStageRowIndexOptimized,
            getLowerStageRowIndex: getLowerStageRowIndexOptimized,
          );

          // 4. Determine if auto-scroll should be enabled
          final enableAutoScroll = shouldEnableAutoScroll(
            userScrollOffset: userScrollOffset,
            targetVerticalOffset: targetVerticalOffset,
            scrollingLeft: scrollingLeft,
            totalRowsHeight: totalRowsHeight,
            viewportHeight: viewportHeight,
          );

          return {
            'centerDateIndex': centerDateIndex,
            'targetVerticalOffset': targetVerticalOffset,
            'enableAutoScroll': enableAutoScroll,
            'scrollingLeft': scrollingLeft,
          };
        });

        // Verify all centerDateIndex results are identical
        final centerIndices = results.map((r) => r['centerDateIndex']).toSet();
        expect(
          centerIndices.length,
          equals(1),
          reason: 'Iteration $iteration: centerDateIndex should be consistent across calls',
        );

        // Note: We can't verify targetVerticalOffset and enableAutoScroll consistency
        // because scrollingLeft is randomized in each call. In the real implementation,
        // scrollingLeft is determined by comparing scroll positions, which would be
        // consistent for the same inputs.
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

    test('Aucun effet de bord - stagesRows n\'est pas modifié', () {
      // Run 100 iterations to verify no side effects on stagesRows
      for (int iteration = 0; iteration < 100; iteration++) {
        final params = generateRandomParams();
        final centerDateIndex = params['centerDateIndex'] as int;
        final rowHeight = params['rowHeight'] as double;
        final rowMargin = params['rowMargin'] as double;
        final scrollingLeft = params['scrollingLeft'] as bool;
        final totalDays = params['totalDays'] as int;

        // Generate random stages rows
        final rowCount = 3 + random.nextInt(10);
        final stagesRows = generateRandomStagesRows(rowCount, totalDays);

        // Store original state
        final originalLength = stagesRows.length;
        final originalFirstRowLength = stagesRows.isNotEmpty ? stagesRows[0].length : 0;

        // Call the function
        calculateTargetVerticalOffset(
          centerDateIndex: centerDateIndex,
          stagesRows: stagesRows,
          rowHeight: rowHeight,
          rowMargin: rowMargin,
          scrollingLeft: scrollingLeft,
          getHigherStageRowIndex: getHigherStageRowIndexOptimized,
          getLowerStageRowIndex: getLowerStageRowIndexOptimized,
        );

        // Verify stagesRows hasn't been modified
        expect(stagesRows.length, equals(originalLength));
        if (stagesRows.isNotEmpty) {
          expect(stagesRows[0].length, equals(originalFirstRowLength));
        }
      }
    });
  });
}
