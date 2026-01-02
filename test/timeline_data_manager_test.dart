import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_data_manager.dart';

void main() {
  group('TimelineDataManager - getFormattedDays', () {
    late TimelineDataManager manager;

    setUp(() {
      manager = TimelineDataManager();
    });

    test('should format days with valid data', () {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 5);
      final elements = [
        {
          'pre_id': 'elem_001',
          'date': '2024-01-02',
          'nat': 'activity',
          'status': 'pending',
        },
        {
          'pre_id': 'elem_002',
          'date': '2024-01-03',
          'nat': 'delivrable',
          'status': 'status',
        },
      ];
      final elementsDone = <Map<String, dynamic>>[];
      final capacities = <Map<String, dynamic>>[];
      final stages = <Map<String, dynamic>>[];

      // Act
      final result = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );

      // Assert
      expect(result, isNotEmpty);
      expect(result.length, equals(5)); // 5 days from Jan 1 to Jan 5

      // Verify structure of first day
      final firstDay = result[0];
      expect(firstDay.containsKey('date'), isTrue);
      expect(firstDay.containsKey('lmax'), isTrue);
      expect(firstDay.containsKey('activityTotal'), isTrue);
      expect(firstDay.containsKey('delivrableTotal'), isTrue);
      expect(firstDay.containsKey('taskTotal'), isTrue);
      expect(firstDay.containsKey('preIds'), isTrue);
      expect(firstDay['lmax'], equals(100));

      // Verify element was counted on correct day (Jan 2 is index 1)
      expect(result[1]['activityTotal'], equals(1));
      expect(result[1]['preIds'], contains('elem_001'));

      // Verify deliverable on Jan 3 (index 2)
      expect(result[2]['delivrableTotal'], equals(1));
      expect(result[2]['preIds'], contains('elem_002'));
    });

    test('should handle invalid date range gracefully', () {
      // Arrange - endDate before startDate
      final startDate = DateTime(2024, 1, 10);
      final endDate = DateTime(2024, 1, 1);
      final elements = <Map<String, dynamic>>[];
      final elementsDone = <Map<String, dynamic>>[];
      final capacities = <Map<String, dynamic>>[];
      final stages = <Map<String, dynamic>>[];

      // Act
      final result = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );

      // Assert - should return empty list on error
      expect(result, isEmpty);
    });

    test('should return empty days list when elements are empty', () {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 3);
      final elements = <Map<String, dynamic>>[];
      final elementsDone = <Map<String, dynamic>>[];
      final capacities = <Map<String, dynamic>>[];
      final stages = <Map<String, dynamic>>[];

      // Act
      final result = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );

      // Assert - should still return days, just with no elements
      expect(result, isNotEmpty);
      expect(result.length, equals(3));

      // All days should have zero counts
      for (final day in result) {
        expect(day['activityTotal'], equals(0));
        expect(day['delivrableTotal'], equals(0));
        expect(day['taskTotal'], equals(0));
        expect(day['preIds'], isEmpty);
      }
    });

    test('should skip null elements gracefully', () {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 3);
      final elements = [
        {
          'pre_id': 'elem_001',
          'date': '2024-01-02',
          'nat': 'activity',
          'status': 'pending',
        },
        null, // Null element
        {
          'pre_id': 'elem_002',
          'date': '2024-01-03',
          'nat': 'task',
          'status': 'pending',
        },
      ];
      final elementsDone = <Map<String, dynamic>>[];
      final capacities = <Map<String, dynamic>>[];
      final stages = <Map<String, dynamic>>[];

      // Act
      final result = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );

      // Assert - should process valid elements and skip null
      expect(result, isNotEmpty);
      expect(result.length, equals(3));
      expect(result[1]['activityTotal'], equals(1));
      expect(result[2]['taskTotal'], equals(1));
    });
  });

  group('TimelineDataManager - Cache', () {
    late TimelineDataManager manager;

    setUp(() {
      manager = TimelineDataManager();
    });

    test('should use cached results for identical calls', () {
      // Arrange
      // This test verifies that the TimelineDataManager caches results
      // to avoid redundant calculations when called with identical parameters.
      // The cache uses a hash of the input data to determine if results can be reused.
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 5);
      final elements = [
        {
          'pre_id': 'elem_001',
          'date': '2024-01-02',
          'nat': 'activity',
          'status': 'pending',
        },
      ];
      final elementsDone = <Map<String, dynamic>>[];
      final capacities = <Map<String, dynamic>>[];
      final stages = <Map<String, dynamic>>[];

      // Act - First call (cache miss, will compute)
      final result1 = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );

      // Act - Second call with identical parameters (cache hit, should return cached result)
      final result2 = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );

      // Assert - Results should be identical (same reference, not just equal content)
      // Using identical() checks if they're the exact same object in memory
      expect(identical(result1, result2), isTrue);
      expect(result1.length, equals(result2.length));
      expect(result1[1]['activityTotal'], equals(result2[1]['activityTotal']));
    });

    test('should invalidate cache when data changes', () {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 5);
      final elements1 = [
        {
          'pre_id': 'elem_001',
          'date': '2024-01-02',
          'nat': 'activity',
          'status': 'pending',
        },
      ];
      final elements2 = [
        {
          'pre_id': 'elem_001',
          'date': '2024-01-02',
          'nat': 'activity',
          'status': 'pending',
        },
        {
          'pre_id': 'elem_002',
          'date': '2024-01-03',
          'nat': 'task',
          'status': 'pending',
        },
      ];
      final elementsDone = <Map<String, dynamic>>[];
      final capacities = <Map<String, dynamic>>[];
      final stages = <Map<String, dynamic>>[];

      // Act - First call with elements1
      final result1 = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements1,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );

      // Act - Second call with elements2 (different data)
      final result2 = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements2,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );

      // Assert - Results should be different
      expect(identical(result1, result2), isFalse);
      expect(result1[2]['taskTotal'], equals(0)); // First call had no task
      expect(result2[2]['taskTotal'], equals(1)); // Second call has task
    });

    test('should force recomputation after clearCache', () {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 5);
      final elements = [
        {
          'pre_id': 'elem_001',
          'date': '2024-01-02',
          'nat': 'activity',
          'status': 'pending',
        },
      ];
      final elementsDone = <Map<String, dynamic>>[];
      final capacities = <Map<String, dynamic>>[];
      final stages = <Map<String, dynamic>>[];

      // Act - First call
      final result1 = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );

      // Clear cache
      manager.clearCache();

      // Act - Second call after clearing cache
      final result2 = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );

      // Assert - Results should not be identical (different instances)
      expect(identical(result1, result2), isFalse);
      // But content should be the same
      expect(result1.length, equals(result2.length));
      expect(result1[1]['activityTotal'], equals(result2[1]['activityTotal']));
    });
  });

  group('TimelineDataManager - Private Methods', () {
    late TimelineDataManager manager;

    setUp(() {
      manager = TimelineDataManager();
    });

    test('_createEmptyDay should return correct structure', () {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 1); // Single day

      // Act - Test indirectly through getFormattedDays
      final result = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: [],
        elementsDone: [],
        capacities: [],
        stages: [],
        maxCapacity: 150,
      );

      // Assert - Verify empty day structure
      expect(result.length, equals(1));
      final day = result[0];

      expect(day['date'], isA<DateTime>());
      expect(day['lmax'], equals(150));
      expect(day['activityTotal'], equals(0));
      expect(day['activityCompleted'], equals(0));
      expect(day['delivrableTotal'], equals(0));
      expect(day['delivrableCompleted'], equals(0));
      expect(day['taskTotal'], equals(0));
      expect(day['taskCompleted'], equals(0));
      expect(day['elementCompleted'], equals(0));
      expect(day['elementPending'], equals(0));
      expect(day['preIds'], isA<List>());
      expect(day['preIds'], isEmpty);
      expect(day['stage'], isA<Map>());
      expect(day['eicon'], equals(''));
      expect(day['capeff'], equals(0));
      expect(day['buseff'], equals(0));
      expect(day['compeff'], equals(0));
      expect(day['alertLevel'], equals(0));
    });

    test('_processElementsForDay should deduplicate elements with same pre_id', () {
      // Arrange
      // This test verifies that elements with duplicate pre_ids are counted only once.
      // This is important because the same element might appear multiple times in the
      // input data (e.g., from different data sources or processing stages), but we
      // only want to count each unique element once per day.
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 1);
      final elements = [
        {
          'pre_id': 'elem_dup',
          'date': '2024-01-01',
          'nat': 'activity',
          'status': 'pending',
        },
        {
          'pre_id': 'elem_dup', // Duplicate pre_id - should be counted only once
          'date': '2024-01-01',
          'nat': 'activity',
          'status': 'pending',
        },
        {
          'pre_id': 'elem_unique',
          'date': '2024-01-01',
          'nat': 'task',
          'status': 'pending',
        },
      ];

      // Act
      final result = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: [],
        capacities: [],
        stages: [],
        maxCapacity: 100,
      );

      // Assert - Should count each unique pre_id only once
      final day = result[0];
      expect(day['activityTotal'], equals(1)); // Only one activity despite duplicate
      expect(day['taskTotal'], equals(1));
      expect(day['preIds'].length, equals(2)); // Only 2 unique pre_ids
      expect(day['preIds'], contains('elem_dup'));
      expect(day['preIds'], contains('elem_unique'));
    });

    test('_processElementsForDay should count different element types correctly', () {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 1);
      final elements = [
        {
          'pre_id': 'elem_001',
          'date': '2024-01-01',
          'nat': 'activity',
          'status': 'pending',
        },
        {
          'pre_id': 'elem_002',
          'date': '2024-01-01',
          'nat': 'activity',
          'status': 'status', // Completed
        },
        {
          'pre_id': 'elem_003',
          'date': '2024-01-01',
          'nat': 'delivrable',
          'status': 'pending',
        },
        {
          'pre_id': 'elem_004',
          'date': '2024-01-01',
          'nat': 'delivrable',
          'status': 'status', // Completed
        },
        {
          'pre_id': 'elem_005',
          'date': '2024-01-01',
          'nat': 'task',
          'status': 'pending',
        },
        {
          'pre_id': 'elem_006',
          'date': '2024-01-01',
          'nat': 'task',
          'status': 'status', // Completed
        },
      ];

      // Act
      final result = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: [],
        capacities: [],
        stages: [],
        maxCapacity: 100,
      );

      // Assert
      final day = result[0];
      expect(day['activityTotal'], equals(2));
      expect(day['activityCompleted'], equals(1));
      expect(day['delivrableTotal'], equals(2));
      expect(day['delivrableCompleted'], equals(1));
      expect(day['taskTotal'], equals(2));
      expect(day['taskCompleted'], equals(1));
    });

    test('_formatElementsOptimized should calculate alert levels correctly', () {
      // Arrange
      // Alert levels indicate capacity utilization:
      // - Level 0 (green): buseff/capeff <= 80% (normal capacity)
      // - Level 1 (yellow): 80% < buseff/capeff <= 100% (high capacity)
      // - Level 2 (red): buseff/capeff > 100% (over capacity)
      // This helps visualize resource allocation and identify bottlenecks.
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 3);
      final capacities = [
        {
          'date': '2024-01-01',
          'capeff': 100.0,
          'buseff': 60.0, // 60% utilization - Alert level 0 (green)
          'compeff': 0.0,
          'eicon': 'icon1',
        },
        {
          'date': '2024-01-02',
          'capeff': 100.0,
          'buseff': 90.0, // 90% utilization - Alert level 1 (yellow)
          'compeff': 0.0,
          'eicon': 'icon2',
        },
        {
          'date': '2024-01-03',
          'capeff': 100.0,
          'buseff': 120.0, // 120% utilization - Alert level 2 (red, over capacity)
          'compeff': 0.0,
          'eicon': 'icon3',
        },
      ];

      // Act
      final result = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: [],
        elementsDone: [],
        capacities: capacities,
        stages: [],
        maxCapacity: 100,
      );

      // Assert - Verify alert levels are calculated correctly
      expect(result[0]['capeff'], equals(100.0));
      expect(result[0]['buseff'], equals(60.0));
      expect(result[0]['alertLevel'], equals(0)); // 60% <= 80%
      expect(result[0]['eicon'], equals('icon1'));

      expect(result[1]['capeff'], equals(100.0));
      expect(result[1]['buseff'], equals(90.0));
      expect(result[1]['alertLevel'], equals(1)); // 80% < 90% <= 100%
      expect(result[1]['eicon'], equals('icon2'));

      expect(result[2]['capeff'], equals(100.0));
      expect(result[2]['buseff'], equals(120.0));
      expect(result[2]['alertLevel'], equals(2)); // 120% > 100%
      expect(result[2]['eicon'], equals('icon3'));
    });
  });

  group('TimelineDataManager - getFormattedTimelineRows', () {
    late TimelineDataManager manager;

    setUp(() {
      manager = TimelineDataManager();
    });

    test('_organizeIntoRows should place overlapping stages in different rows', () {
      // Arrange
      // This test verifies the row organization algorithm that prevents overlapping stages
      // from being placed in the same row. The algorithm should:
      // 1. Try to place each stage in the first available row where it doesn't overlap
      // 2. Create a new row if no existing row can accommodate the stage
      // This ensures a compact, readable visualization of the timeline.
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      // First get formatted days
      final days = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: [],
        elementsDone: [],
        capacities: [],
        stages: [],
        maxCapacity: 100,
      );

      final stages = [
        {
          'type': 'stage',
          'id': 'stage_1',
          'sdate': '2024-01-01',
          'edate': '2024-01-10',
          'pcolor': '#FF0000',
        },
        {
          'type': 'stage',
          'id': 'stage_2',
          'sdate': '2024-01-05', // Overlaps with stage_1 (days 5-10)
          'edate': '2024-01-15',
          'pcolor': '#00FF00',
        },
        {
          'type': 'stage',
          'id': 'stage_3',
          'sdate': '2024-01-12', // Overlaps with stage_2 (days 12-15)
          'edate': '2024-01-20',
          'pcolor': '#0000FF',
        },
      ];

      // Act
      final rows = manager.getFormattedTimelineRows(
        startDate: startDate,
        endDate: endDate,
        days: days,
        stages: stages,
        elements: [],
      );

      // Assert - Overlapping stages should be in different rows
      expect(rows.length, greaterThanOrEqualTo(2));

      // Verify no overlaps within each row
      // For each row, check that all stages are non-overlapping
      for (final row in rows) {
        for (int i = 0; i < row.length - 1; i++) {
          final current = row[i];
          final next = row[i + 1];
          final currentEnd = current['endDateIndex'] as int;
          final nextStart = next['startDateIndex'] as int;

          // Current stage should end before next stage starts
          // (no overlap means currentEnd < nextStart)
          expect(currentEnd, lessThan(nextStart), reason: 'Stages should not overlap in same row');
        }
      }
    });

    test('_organizeIntoRows should place non-overlapping stages in same row', () {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      final days = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: [],
        elementsDone: [],
        capacities: [],
        stages: [],
        maxCapacity: 100,
      );

      final stages = [
        {
          'type': 'stage',
          'id': 'stage_1',
          'sdate': '2024-01-01',
          'edate': '2024-01-05',
          'pcolor': '#FF0000',
        },
        {
          'type': 'stage',
          'id': 'stage_2',
          'sdate': '2024-01-06', // No overlap
          'edate': '2024-01-10',
          'pcolor': '#00FF00',
        },
        {
          'type': 'stage',
          'id': 'stage_3',
          'sdate': '2024-01-11', // No overlap
          'edate': '2024-01-15',
          'pcolor': '#0000FF',
        },
      ];

      // Act
      final rows = manager.getFormattedTimelineRows(
        startDate: startDate,
        endDate: endDate,
        days: days,
        stages: stages,
        elements: [],
      );

      // Assert - Non-overlapping stages can be in same row
      expect(rows, isNotEmpty);

      // Should be able to fit in 1 row since they don't overlap
      expect(rows.length, equals(1));
      expect(rows[0].length, equals(3));
    });

    test('should skip stages with dates outside timeline range', () {
      // Arrange
      final startDate = DateTime(2024, 1, 10);
      final endDate = DateTime(2024, 1, 20);

      final days = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: [],
        elementsDone: [],
        capacities: [],
        stages: [],
        maxCapacity: 100,
      );

      final stages = [
        {
          'type': 'stage',
          'id': 'stage_before',
          'sdate': '2024-01-01', // Before timeline
          'edate': '2024-01-05',
          'pcolor': '#FF0000',
        },
        {
          'type': 'stage',
          'id': 'stage_valid',
          'sdate': '2024-01-12', // Within timeline
          'edate': '2024-01-18',
          'pcolor': '#00FF00',
        },
        {
          'type': 'stage',
          'id': 'stage_after',
          'sdate': '2024-01-25', // After timeline
          'edate': '2024-01-30',
          'pcolor': '#0000FF',
        },
      ];

      // Act
      final rows = manager.getFormattedTimelineRows(
        startDate: startDate,
        endDate: endDate,
        days: days,
        stages: stages,
        elements: [],
      );

      // Assert - Only valid stage should be included
      expect(rows, isNotEmpty);

      // Count total stages across all rows
      final totalStages = rows.fold<int>(0, (sum, row) => sum + row.length);
      expect(totalStages, equals(1)); // Only the valid stage

      // Verify it's the correct stage
      final allStages = rows.expand((row) => row).toList();
      expect(allStages[0]['id'], equals('stage_valid'));
    });

    test('should handle stages with invalid date formats gracefully', () {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      final days = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: [],
        elementsDone: [],
        capacities: [],
        stages: [],
        maxCapacity: 100,
      );

      final stages = [
        {
          'type': 'stage',
          'id': 'stage_invalid',
          'sdate': 'invalid-date', // Invalid format
          'edate': '2024-01-10',
          'pcolor': '#FF0000',
        },
        {
          'type': 'stage',
          'id': 'stage_valid',
          'sdate': '2024-01-05',
          'edate': '2024-01-15',
          'pcolor': '#00FF00',
        },
      ];

      // Act
      final rows = manager.getFormattedTimelineRows(
        startDate: startDate,
        endDate: endDate,
        days: days,
        stages: stages,
        elements: [],
      );

      // Assert - Should skip invalid stage and process valid one
      expect(rows, isNotEmpty);

      final totalStages = rows.fold<int>(0, (sum, row) => sum + row.length);
      expect(totalStages, equals(1)); // Only the valid stage

      final allStages = rows.expand((row) => row).toList();
      expect(allStages[0]['id'], equals('stage_valid'));
    });

    test('should add startDateIndex and endDateIndex to stages', () {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      final days = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: [],
        elementsDone: [],
        capacities: [],
        stages: [],
        maxCapacity: 100,
      );

      final stages = [
        {
          'type': 'stage',
          'id': 'stage_1',
          'sdate': '2024-01-05', // Day 4 (0-indexed)
          'edate': '2024-01-10', // Day 9
          'pcolor': '#FF0000',
        },
      ];

      // Act
      final rows = manager.getFormattedTimelineRows(
        startDate: startDate,
        endDate: endDate,
        days: days,
        stages: stages,
        elements: [],
      );

      // Assert
      expect(rows, isNotEmpty);
      final stage = rows[0][0];

      expect(stage.containsKey('startDateIndex'), isTrue);
      expect(stage.containsKey('endDateIndex'), isTrue);
      expect(stage['startDateIndex'], equals(4)); // Jan 5 is index 4
      expect(stage['endDateIndex'], equals(9)); // Jan 10 is index 9
    });
  });
}
