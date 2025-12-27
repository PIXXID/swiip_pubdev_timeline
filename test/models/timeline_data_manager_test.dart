import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_data_manager.dart';
import 'dart:math';

void main() {
  group('TimelineDataManager', () {
    late TimelineDataManager dataManager;

    setUp(() {
      dataManager = TimelineDataManager();
    });

    group('Property 5: Data Caching', () {
      // Feature: timeline-performance-optimization, Property 5: Data Caching
      // Validates: Requirements 4.1, 4.5
      //
      // Property: For any timeline initialization with unchanged input data,
      // the formatElements and formatStagesRows functions should return cached
      // results without recomputation, and position calculations should occur
      // only once.

      test('should return cached days when input data is unchanged', () {
        final random = Random(42); // Fixed seed for reproducibility

        // Run the property test 100 times with different random data
        for (var iteration = 0; iteration < 100; iteration++) {
          // Generate random timeline data
          final startDate = DateTime(2024, 1, 1);
          final dayCount = 10 + random.nextInt(50); // 10-60 days
          final endDate = startDate.add(Duration(days: dayCount));

          final elementCount = random.nextInt(20);
          final elements = List.generate(
            elementCount,
            (i) => {
              'pre_id': 'elem_$i',
              'date': _formatDate(
                  startDate.add(Duration(days: random.nextInt(dayCount)))),
              'nat': ['activity', 'delivrable', 'task'][random.nextInt(3)],
              'status': ['pending', 'inprogress', 'validated', 'finished']
                  [random.nextInt(4)],
            },
          );

          final elementsDoneCount = random.nextInt(10);
          final elementsDone = List.generate(
            elementsDoneCount,
            (i) => {
              'pre_id': 'done_$i',
              'date': _formatDate(
                  startDate.add(Duration(days: random.nextInt(dayCount)))),
            },
          );

          final capacityCount = random.nextInt(dayCount);
          final capacities = List.generate(
            capacityCount,
            (i) => {
              'date': _formatDate(
                  startDate.add(Duration(days: random.nextInt(dayCount)))),
              'capeff': random.nextInt(8),
              'buseff': random.nextInt(8),
              'compeff': random.nextInt(8),
              'eicon': 'icon_$i',
            },
          );

          final stageCount = random.nextInt(5);
          final stages = List.generate(
            stageCount,
            (i) {
              final stageStart =
                  startDate.add(Duration(days: random.nextInt(dayCount ~/ 2)));
              final stageDuration = 1 + random.nextInt(10);
              return {
                'prs_id': 'stage_$i',
                'type': ['milestone', 'cycle', 'sequence', 'stage']
                    [random.nextInt(4)],
                'sdate': _formatDate(stageStart),
                'edate': _formatDate(stageStart.add(Duration(days: stageDuration))),
                'pcolor': '#FF0000',
                'elm_filtered': <String>[],
              };
            },
          );

          final maxCapacity = 8;

          // First call - should compute and cache
          final firstResult = dataManager.getFormattedDays(
            startDate: startDate,
            endDate: endDate,
            elements: elements,
            elementsDone: elementsDone,
            capacities: capacities,
            stages: stages,
            maxCapacity: maxCapacity,
          );

          // Second call with same data - should return cached result
          final secondResult = dataManager.getFormattedDays(
            startDate: startDate,
            endDate: endDate,
            elements: elements,
            elementsDone: elementsDone,
            capacities: capacities,
            stages: stages,
            maxCapacity: maxCapacity,
          );

          // Property: The cached result should be identical to the first result
          expect(identical(firstResult, secondResult), isTrue,
              reason:
                  'Iteration $iteration: Second call should return the exact same cached list instance');

          // Verify the results are equal in content as well
          expect(firstResult.length, equals(secondResult.length),
              reason: 'Iteration $iteration: Results should have same length');

          // Clear cache for next iteration
          dataManager.clearCache();
        }
      });

      test('should recompute when input data changes', () {
        final random = Random(123); // Fixed seed for reproducibility

        // Run the property test 100 times
        for (var iteration = 0; iteration < 100; iteration++) {
          final startDate = DateTime(2024, 1, 1);
          final dayCount = 10 + random.nextInt(30);
          final endDate = startDate.add(Duration(days: dayCount));

          final elements = List.generate(
            5,
            (i) => {
              'pre_id': 'elem_$i',
              'date': _formatDate(
                  startDate.add(Duration(days: random.nextInt(dayCount)))),
              'nat': 'activity',
              'status': 'pending',
            },
          );

          final elementsDone = <Map<String, dynamic>>[];
          final capacities = <Map<String, dynamic>>[];
          final stages = <Map<String, dynamic>>[];
          final maxCapacity = 8;

          // First call
          final firstResult = dataManager.getFormattedDays(
            startDate: startDate,
            endDate: endDate,
            elements: elements,
            elementsDone: elementsDone,
            capacities: capacities,
            stages: stages,
            maxCapacity: maxCapacity,
          );

          // Modify the data (add one more element)
          final modifiedElements = [
            ...elements,
            {
              'pre_id': 'elem_new',
              'date': _formatDate(
                  startDate.add(Duration(days: random.nextInt(dayCount)))),
              'nat': 'task',
              'status': 'inprogress',
            }
          ];

          // Second call with modified data
          final secondResult = dataManager.getFormattedDays(
            startDate: startDate,
            endDate: endDate,
            elements: modifiedElements,
            elementsDone: elementsDone,
            capacities: capacities,
            stages: stages,
            maxCapacity: maxCapacity,
          );

          // Property: The results should be different instances (cache invalidated)
          expect(identical(firstResult, secondResult), isFalse,
              reason:
                  'Iteration $iteration: Changed data should invalidate cache and return new instance');

          // Clear cache for next iteration
          dataManager.clearCache();
        }
      });

      test('should cache stage rows independently', () {
        final random = Random(456); // Fixed seed for reproducibility

        // Run the property test 100 times
        for (var iteration = 0; iteration < 100; iteration++) {
          final startDate = DateTime(2024, 1, 1);
          final dayCount = 20 + random.nextInt(30);
          final endDate = startDate.add(Duration(days: dayCount));

          final elements = List.generate(
            10,
            (i) => {
              'pre_id': 'elem_$i',
              'date': _formatDate(
                  startDate.add(Duration(days: random.nextInt(dayCount)))),
              'nat': 'activity',
              'status': 'pending',
              'sdate': _formatDate(
                  startDate.add(Duration(days: random.nextInt(dayCount ~/ 2)))),
              'edate': _formatDate(startDate
                  .add(Duration(days: dayCount ~/ 2 + random.nextInt(10)))),
              'type': 'activity',
            },
          );

          final stages = List.generate(
            3,
            (i) {
              final stageStart =
                  startDate.add(Duration(days: random.nextInt(dayCount ~/ 2)));
              return {
                'prs_id': 'stage_$i',
                'type': 'stage',
                'sdate': _formatDate(stageStart),
                'edate': _formatDate(stageStart.add(Duration(days: 5))),
                'pcolor': '#FF0000',
                'elm_filtered': ['elem_0', 'elem_1'],
              };
            },
          );

          // First, get formatted days (this will cache them)
          final days = dataManager.getFormattedDays(
            startDate: startDate,
            endDate: endDate,
            elements: elements,
            elementsDone: [],
            capacities: [],
            stages: stages,
            maxCapacity: 8,
          );

          // First call to getFormattedStageRows - should compute and cache
          final firstStageRows = dataManager.getFormattedStageRows(
            startDate: startDate,
            endDate: endDate,
            days: days,
            stages: stages,
            elements: elements,
          );

          // Second call - should return cached result
          final secondStageRows = dataManager.getFormattedStageRows(
            startDate: startDate,
            endDate: endDate,
            days: days,
            stages: stages,
            elements: elements,
          );

          // Property: The cached result should be identical
          expect(identical(firstStageRows, secondStageRows), isTrue,
              reason:
                  'Iteration $iteration: Second call should return the exact same cached stage rows instance');

          // Clear cache for next iteration
          dataManager.clearCache();
        }
      });

      test('clearCache should invalidate all cached data', () {
        final random = Random(789);

        // Run the property test 100 times
        for (var iteration = 0; iteration < 100; iteration++) {
          final startDate = DateTime(2024, 1, 1);
          final dayCount = 10 + random.nextInt(20);
          final endDate = startDate.add(Duration(days: dayCount));

          final elements = List.generate(
            5,
            (i) => {
              'pre_id': 'elem_$i',
              'date': _formatDate(
                  startDate.add(Duration(days: random.nextInt(dayCount)))),
              'nat': 'activity',
              'status': 'pending',
              'sdate': _formatDate(startDate),
              'edate': _formatDate(startDate.add(Duration(days: 2))),
              'type': 'activity',
            },
          );

          final stages = <Map<String, dynamic>>[];

          // First call - caches the result
          final firstResult = dataManager.getFormattedDays(
            startDate: startDate,
            endDate: endDate,
            elements: elements,
            elementsDone: [],
            capacities: [],
            stages: stages,
            maxCapacity: 8,
          );

          // Clear the cache
          dataManager.clearCache();

          // Second call with same data - should recompute (not use cache)
          final secondResult = dataManager.getFormattedDays(
            startDate: startDate,
            endDate: endDate,
            elements: elements,
            elementsDone: [],
            capacities: [],
            stages: stages,
            maxCapacity: 8,
          );

          // Property: After clearCache, results should be different instances
          expect(identical(firstResult, secondResult), isFalse,
              reason:
                  'Iteration $iteration: clearCache should force recomputation, returning new instance');

          // But content should be equal
          expect(firstResult.length, equals(secondResult.length),
              reason:
                  'Iteration $iteration: Content should be equal even though instances differ');
        }
      });

      test('should handle edge case of empty data', () {
        // Property: Caching should work correctly even with empty data
        final startDate = DateTime(2024, 1, 1);
        final endDate = startDate.add(const Duration(days: 5));

        // First call with empty data
        final firstResult = dataManager.getFormattedDays(
          startDate: startDate,
          endDate: endDate,
          elements: [],
          elementsDone: [],
          capacities: [],
          stages: [],
          maxCapacity: 8,
        );

        // Second call with same empty data
        final secondResult = dataManager.getFormattedDays(
          startDate: startDate,
          endDate: endDate,
          elements: [],
          elementsDone: [],
          capacities: [],
          stages: [],
          maxCapacity: 8,
        );

        // Property: Should still cache and return same instance
        expect(identical(firstResult, secondResult), isTrue,
            reason: 'Empty data should still be cached correctly');

        expect(firstResult.length, equals(6),
            reason: 'Should create 6 days (inclusive of start and end)');
      });
    });
  });
}

/// Helper function to format a DateTime as 'yyyy-MM-dd'
String _formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
