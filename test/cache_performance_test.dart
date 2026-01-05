import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_data_manager.dart';

void main() {
  group('TimelineDataManager - Cache Performance', () {
    late TimelineDataManager manager;

    setUp(() {
      manager = TimelineDataManager();
    });

    test('cache hit should be significantly faster than cache miss', () {
      // Arrange - Create a moderately large dataset
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 12, 31); // 366 days
      final elements = List.generate(
        500,
        (i) => {
          'pre_id': 'elem_$i',
          'date': DateTime(2024, 1, 1)
              .add(Duration(days: i % 366))
              .toString()
              .substring(0, 10),
          'nat': ['activity', 'delivrable', 'task'][i % 3],
          'status': 'pending',
        },
      );
      final elementsDone = <Map<String, dynamic>>[];
      final capacities = <Map<String, dynamic>>[];
      final stages = <Map<String, dynamic>>[];

      // Act - First call (cache miss)
      final stopwatch1 = Stopwatch()..start();
      final result1 = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );
      stopwatch1.stop();
      final cacheMissTime = stopwatch1.elapsedMicroseconds;

      // Act - Second call (cache hit)
      final stopwatch2 = Stopwatch()..start();
      final result2 = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );
      stopwatch2.stop();
      final cacheHitTime = stopwatch2.elapsedMicroseconds;

      // Assert
      expect(result1.length, equals(366));
      expect(identical(result1, result2), isTrue,
          reason: 'Should return cached instance');

      // Cache hit should be at least 10x faster (very conservative threshold)
      // In practice, it's often 100x+ faster
      expect(
        cacheHitTime,
        lessThan(cacheMissTime / 10),
        reason:
            'Cache hit ($cacheHitTime μs) should be much faster than cache miss ($cacheMissTime μs)',
      );

      // Print performance metrics for visibility
      print('Cache miss time: $cacheMissTime μs');
      print('Cache hit time: $cacheHitTime μs');
      print('Speedup: ${(cacheMissTime / cacheHitTime).toStringAsFixed(1)}x');
    });

    test('cache miss should recompute data', () {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 6, 30); // 182 days
      final elements = List.generate(
        200,
        (i) => {
          'pre_id': 'elem_$i',
          'date': DateTime(2024, 1, 1)
              .add(Duration(days: i % 182))
              .toString()
              .substring(0, 10),
          'nat': 'activity',
          'status': 'pending',
        },
      );
      final elementsDone = <Map<String, dynamic>>[];
      final capacities = <Map<String, dynamic>>[];
      final stages = <Map<String, dynamic>>[];

      // Act - First call
      final stopwatch1 = Stopwatch()..start();
      final result1 = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );
      stopwatch1.stop();
      final firstCallTime = stopwatch1.elapsedMicroseconds;

      // Clear cache to force recomputation
      manager.clearCache();

      // Act - Second call after cache clear (another cache miss)
      final stopwatch2 = Stopwatch()..start();
      final result2 = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );
      stopwatch2.stop();
      final secondCallTime = stopwatch2.elapsedMicroseconds;

      // Assert
      expect(result1.length, equals(result2.length));
      expect(identical(result1, result2), isFalse,
          reason: 'Should be different instances after cache clear');

      // Both calls should take similar time (both are cache misses)
      // Allow 3x variance due to system noise
      expect(
        secondCallTime,
        lessThan(firstCallTime * 3),
        reason: 'Both cache misses should take similar time',
      );
      expect(
        firstCallTime,
        lessThan(secondCallTime * 3),
        reason: 'Both cache misses should take similar time',
      );

      print('First call (cache miss): $firstCallTime μs');
      print('Second call (cache miss after clear): $secondCallTime μs');
    });

    test('clearCache should force recomputation on next access', () {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 3, 31); // 91 days
      final elements = List.generate(
        100,
        (i) => {
          'pre_id': 'elem_$i',
          'date': DateTime(2024, 1, 1)
              .add(Duration(days: i % 91))
              .toString()
              .substring(0, 10),
          'nat': 'task',
          'status': 'pending',
        },
      );
      final elementsDone = <Map<String, dynamic>>[];
      final capacities = <Map<String, dynamic>>[];
      final stages = <Map<String, dynamic>>[];

      // Act - First call to populate cache
      final result1 = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );

      // Verify cache is being used
      final result2 = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );
      expect(identical(result1, result2), isTrue,
          reason: 'Cache should be used');

      // Clear cache
      manager.clearCache();

      // Act - Call after clearing cache
      final stopwatch = Stopwatch()..start();
      final result3 = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );
      stopwatch.stop();

      // Assert
      expect(identical(result1, result3), isFalse,
          reason: 'Should create new instance after cache clear');
      expect(result1.length, equals(result3.length));
      expect(result1[0]['taskTotal'], equals(result3[0]['taskTotal']));

      // Recomputation should take measurable time (> 0)
      expect(stopwatch.elapsedMicroseconds, greaterThan(0));

      print(
          'Recomputation time after clearCache: ${stopwatch.elapsedMicroseconds} μs');
    });

    test('large dataset performance should remain reasonable', () {
      // Arrange - Create a large dataset (1 year, 1000 elements)
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 12, 31); // 366 days
      final elements = List.generate(
        1000,
        (i) => {
          'pre_id': 'elem_$i',
          'date': DateTime(2024, 1, 1)
              .add(Duration(days: i % 366))
              .toString()
              .substring(0, 10),
          'nat': ['activity', 'delivrable', 'task'][i % 3],
          'status': ['pending', 'status', 'validated'][i % 3],
        },
      );
      final elementsDone = List.generate(
        200,
        (i) => {
          'pre_id': 'done_$i',
          'date': DateTime(2024, 1, 1)
              .add(Duration(days: i % 366))
              .toString()
              .substring(0, 10),
        },
      );
      final capacities = List.generate(
        366,
        (i) => {
          'date': DateTime(2024, 1, 1)
              .add(Duration(days: i))
              .toString()
              .substring(0, 10),
          'capeff': 100.0,
          'buseff': 50.0 + (i % 60),
          'compeff': 0.0,
          'eicon': 'icon_$i',
        },
      );
      final stages = List.generate(
        50,
        (i) => {
          'type': 'stage',
          'id': 'stage_$i',
          'sdate': DateTime(2024, 1, 1)
              .add(Duration(days: i * 7))
              .toString()
              .substring(0, 10),
          'edate': DateTime(2024, 1, 1)
              .add(Duration(days: i * 7 + 5))
              .toString()
              .substring(0, 10),
          'pcolor': '#FF0000',
          'prs_id': 'prs_$i',
          'elm_filtered': ['elem_${i * 10}', 'elem_${i * 10 + 1}'],
        },
      );

      // Act - Measure cache miss performance
      final stopwatch1 = Stopwatch()..start();
      final result = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );
      stopwatch1.stop();
      final cacheMissTime = stopwatch1.elapsedMilliseconds;

      // Act - Measure cache hit performance
      final stopwatch2 = Stopwatch()..start();
      manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: elementsDone,
        capacities: capacities,
        stages: stages,
        maxCapacity: 100,
      );
      stopwatch2.stop();
      final cacheHitTime = stopwatch2.elapsedMicroseconds;

      // Assert
      expect(result.length, equals(366));

      // Cache miss should complete in reasonable time (< 500ms for large dataset)
      expect(
        cacheMissTime,
        lessThan(500),
        reason:
            'Large dataset processing should complete in < 500ms (was $cacheMissTime ms)',
      );

      // Cache hit should be very fast (< 1ms)
      expect(
        cacheHitTime,
        lessThan(1000),
        reason: 'Cache hit should be < 1ms (was $cacheHitTime μs)',
      );

      print('Large dataset (1000 elements, 366 days):');
      print('  Cache miss: $cacheMissTime ms');
      print('  Cache hit: $cacheHitTime μs');
      print('  Days formatted: ${result.length}');
    });

    test('getFormattedTimelineRows should use cached stage rows', () {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 6, 30); // 182 days
      final elements = List.generate(
        100,
        (i) => {
          'pre_id': 'elem_$i',
          'date': DateTime(2024, 1, 1)
              .add(Duration(days: i % 182))
              .toString()
              .substring(0, 10),
          'nat': 'activity',
          'status': 'pending',
          'sdate': DateTime(2024, 1, 1)
              .add(Duration(days: i % 182))
              .toString()
              .substring(0, 10),
          'edate': DateTime(2024, 1, 1)
              .add(Duration(days: (i % 182) + 5))
              .toString()
              .substring(0, 10),
        },
      );
      final stages = List.generate(
        20,
        (i) => {
          'type': 'stage',
          'id': 'stage_$i',
          'sdate': DateTime(2024, 1, 1)
              .add(Duration(days: i * 9))
              .toString()
              .substring(0, 10),
          'edate': DateTime(2024, 1, 1)
              .add(Duration(days: i * 9 + 7))
              .toString()
              .substring(0, 10),
          'pcolor': '#00FF00',
          'prs_id': 'prs_$i',
          'elm_filtered': ['elem_${i * 5}'],
        },
      );

      // First get formatted days to populate cache
      final days = manager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: elements,
        elementsDone: [],
        capacities: [],
        stages: stages,
        maxCapacity: 100,
      );

      // Act - First call to getFormattedTimelineRows (cache miss)
      final stopwatch1 = Stopwatch()..start();
      final rows1 = manager.getFormattedTimelineRows(
        startDate: startDate,
        endDate: endDate,
        days: days,
        stages: stages,
        elements: elements,
      );
      stopwatch1.stop();
      final firstCallTime = stopwatch1.elapsedMicroseconds;

      // Act - Second call to getFormattedTimelineRows (cache hit)
      final stopwatch2 = Stopwatch()..start();
      final rows2 = manager.getFormattedTimelineRows(
        startDate: startDate,
        endDate: endDate,
        days: days,
        stages: stages,
        elements: elements,
      );
      stopwatch2.stop();
      final secondCallTime = stopwatch2.elapsedMicroseconds;

      // Assert
      expect(identical(rows1, rows2), isTrue,
          reason: 'Should return cached stage rows');
      expect(rows1.length, equals(rows2.length));

      // Cache hit should be much faster
      expect(
        secondCallTime,
        lessThan(firstCallTime / 5),
        reason:
            'Cached stage rows ($secondCallTime μs) should be much faster than first call ($firstCallTime μs)',
      );

      print('Stage rows first call: $firstCallTime μs');
      print('Stage rows cached call: $secondCallTime μs');
      print('Speedup: ${(firstCallTime / secondCallTime).toStringAsFixed(1)}x');
    });
  });
}
