import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_data_manager.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_controller.dart';

/// Property 7: Conditional Calculations
///
/// **Validates: Requirements 5.5, 7.2**
///
/// This test verifies that:
/// - When input data hasn't changed, formatElements and formatStagesRows return cached results
/// - When centerItemIndex hasn't changed, no recalculations occur
/// - When scroll offset changes below a threshold, calculations are skipped
///
/// Property: For any state update where the relevant value hasn't changed
/// (centerItemIndex, scroll offset below threshold), the system should skip
/// associated calculations and not trigger rebuilds.
void main() {
  group('Property 7: Conditional Calculations', () {
    test('should return cached days when input data is unchanged', () {
      // Feature: timeline-performance-optimization, Property 7: Conditional Calculations

      final dataManager = TimelineDataManager();
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final elements = [
        {
          'date': '2024-01-15',
          'pre_id': 'elem1',
          'nat': 'activity',
          'status': 'pending'
        }
      ];
      final elementsDone = <Map<String, dynamic>>[];
      final capacities = <Map<String, dynamic>>[];
      final stages = <Map<String, dynamic>>[];
      const maxCapacity = 8;

      // First call - should compute
      final result1 = dataManager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: maxCapacity,
      );

      // Second call with same data - should return cached result
      final result2 = dataManager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: maxCapacity,
      );

      // Verify same instance is returned (cached)
      expect(identical(result1, result2), isTrue,
          reason: 'Should return cached result when data is unchanged');
    });

    test('should recompute when input data changes', () {
      // Feature: timeline-performance-optimization, Property 7: Conditional Calculations

      final dataManager = TimelineDataManager();
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final elements1 = [
        {
          'date': '2024-01-15',
          'pre_id': 'elem1',
          'nat': 'activity',
          'status': 'pending'
        }
      ];
      final elements2 = [
        {
          'date': '2024-01-15',
          'pre_id': 'elem1',
          'nat': 'activity',
          'status': 'pending'
        },
        {
          'date': '2024-01-20',
          'pre_id': 'elem2',
          'nat': 'task',
          'status': 'finished'
        }
      ];
      final elementsDone = <Map<String, dynamic>>[];
      final capacities = <Map<String, dynamic>>[];
      final stages = <Map<String, dynamic>>[];
      const maxCapacity = 8;

      // First call
      final result1 = dataManager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements1,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: maxCapacity,
      );

      // Second call with different data - should recompute
      final result2 = dataManager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements2,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: maxCapacity,
      );

      // Verify different instance is returned (recomputed)
      expect(identical(result1, result2), isFalse,
          reason: 'Should recompute when data changes');

      // Verify the results are different
      expect(result1.length, equals(result2.length));
      // The second result should have more elements processed
      final day20Index = 19; // January 20th is index 19 (0-based)
      expect(result2[day20Index]['preIds'].length,
          greaterThan(result1[day20Index]['preIds'].length));
    });

    test('should skip centerItemIndex update when value hasn\'t changed', () {
      // Feature: timeline-performance-optimization, Property 7: Conditional Calculations

      final controller = TimelineController(
        dayWidth: 45.0,
        dayMargin: 5.0,
        totalDays: 100,
        viewportWidth: 800.0,
      );

      // Set initial scroll offset
      controller.updateScrollOffset(200.0);

      // Wait for throttle
      Future.delayed(const Duration(milliseconds: 20), () {
        final initialCenterIndex = controller.centerItemIndex.value;

        // Update with same scroll offset (should skip calculation)
        controller.updateScrollOffset(200.0);

        Future.delayed(const Duration(milliseconds: 20), () {
          final newCenterIndex = controller.centerItemIndex.value;

          expect(newCenterIndex, equals(initialCenterIndex),
              reason:
                  'CenterItemIndex should not change when scroll offset is the same');
        });
      });
    });

    test('should skip calculations when scroll offset changes insignificantly',
        () {
      // Feature: timeline-performance-optimization, Property 7: Conditional Calculations

      final controller = TimelineController(
        dayWidth: 45.0,
        dayMargin: 5.0,
        totalDays: 100,
        viewportWidth: 800.0,
      );

      // Set initial scroll offset
      controller.updateScrollOffset(200.0);

      Future.delayed(const Duration(milliseconds: 20), () {
        final initialCenterIndex = controller.centerItemIndex.value;

        // Update with slightly different offset (less than one day width)
        // This should result in the same centerItemIndex
        controller.updateScrollOffset(202.0);

        Future.delayed(const Duration(milliseconds: 20), () {
          final newCenterIndex = controller.centerItemIndex.value;

          expect(newCenterIndex, equals(initialCenterIndex),
              reason:
                  'CenterItemIndex should not change for insignificant scroll changes');
        });
      });
    });

    test('should update calculations when scroll offset changes significantly',
        () {
      // Feature: timeline-performance-optimization, Property 7: Conditional Calculations

      final controller = TimelineController(
        dayWidth: 45.0,
        dayMargin: 5.0,
        totalDays: 100,
        viewportWidth: 800.0,
      );

      // Set initial scroll offset
      controller.updateScrollOffset(200.0);

      Future.delayed(const Duration(milliseconds: 20), () {
        final initialCenterIndex = controller.centerItemIndex.value;

        // Update with significantly different offset (more than one day width)
        controller.updateScrollOffset(250.0);

        Future.delayed(const Duration(milliseconds: 20), () {
          final newCenterIndex = controller.centerItemIndex.value;

          expect(newCenterIndex, isNot(equals(initialCenterIndex)),
              reason:
                  'CenterItemIndex should change for significant scroll changes');
        });
      });
    });

    test('should cache stage rows independently of days', () {
      // Feature: timeline-performance-optimization, Property 7: Conditional Calculations

      final dataManager = TimelineDataManager();
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final days = List.generate(
          31,
          (i) => {
                'date': startDate.add(Duration(days: i)),
                'lmax': 8,
              });
      final stages = [
        {
          'prs_id': 'stage1',
          'type': 'milestone',
          'sdate': '2024-01-10',
          'edate': '2024-01-15',
          'elm_filtered': <String>[],
        }
      ];
      final elements = <Map<String, dynamic>>[];

      // First call - should compute
      final result1 = dataManager.getFormattedStageRows(
        startDate: startDate,
        endDate: endDate,
        days: days,
        stages: stages,
        elements: elements,
      );

      // Second call with same data - should return cached result
      final result2 = dataManager.getFormattedStageRows(
        startDate: startDate,
        endDate: endDate,
        days: days,
        stages: stages,
        elements: elements,
      );

      // Verify same instance is returned (cached)
      expect(identical(result1, result2), isTrue,
          reason: 'Should return cached stage rows when data is unchanged');
    });

    test('should clear cache and recompute on clearCache call', () {
      // Feature: timeline-performance-optimization, Property 7: Conditional Calculations

      final dataManager = TimelineDataManager();
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final elements = [
        {
          'date': '2024-01-15',
          'pre_id': 'elem1',
          'nat': 'activity',
          'status': 'pending'
        }
      ];
      final elementsDone = <Map<String, dynamic>>[];
      final capacities = <Map<String, dynamic>>[];
      final stages = <Map<String, dynamic>>[];
      const maxCapacity = 8;

      // First call - should compute
      final result1 = dataManager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: maxCapacity,
      );

      // Clear cache
      dataManager.clearCache();

      // Second call after clearing cache - should recompute
      final result2 = dataManager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: maxCapacity,
      );

      // Verify different instance is returned (recomputed)
      expect(identical(result1, result2), isFalse,
          reason: 'Should recompute after cache is cleared');

      // But the content should be the same
      expect(result1.length, equals(result2.length));
    });
  });
}
