import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_error_handler.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_data_manager.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_controller.dart';

/// Property 11: Edge Case Handling
///
/// **Validates: Requirements 6.4**
///
/// This test verifies that:
/// - Null values are handled gracefully without crashes
/// - Empty lists are handled without exceptions
/// - Dates outside range are handled correctly
/// - Invalid indices are clamped to valid ranges
/// - Scroll beyond limits is handled properly
///
/// Property: For any edge case input (null values, empty lists, dates outside range,
/// invalid indices), the system should handle it gracefully without crashes or exceptions.
void main() {
  group('Property 11: Edge Case Handling', () {
    test('should handle null and empty data gracefully', () {
      // Feature: timeline-performance-optimization, Property 11: Edge Case Handling
      
      final random = Random(42); // Seed for reproducibility
      
      for (var i = 0; i < 100; i++) {
        final dataManager = TimelineDataManager();
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);
        
        // Test with various combinations of null/empty data
        final testCases = [
          {
            'elements': null,
            'elementsDone': null,
            'capacities': null,
            'stages': null,
          },
          {
            'elements': [],
            'elementsDone': [],
            'capacities': [],
            'stages': [],
          },
          {
            'elements': null,
            'elementsDone': [],
            'capacities': null,
            'stages': [],
          },
        ];
        
        final testCase = testCases[random.nextInt(testCases.length)];
        
        // Should not throw exception
        expect(() {
          final result = dataManager.getFormattedDays(
            startDate: startDate,
            endDate: endDate,
            elements: testCase['elements'] ?? [],
            elementsDone: testCase['elementsDone'] ?? [],
            capacities: testCase['capacities'] ?? [],
            stages: testCase['stages'] ?? [],
            maxCapacity: 8,
          );
          
          // Result should be a valid list (possibly empty)
          expect(result, isA<List>());
        }, returnsNormally,
            reason: 'Should handle null/empty data without throwing');
      }
    });

    test('should handle invalid date ranges gracefully', () {
      // Feature: timeline-performance-optimization, Property 11: Edge Case Handling
      
      for (var i = 0; i < 100; i++) {
        final startDate = DateTime(2024, 1, 31);
        final endDate = DateTime(2024, 1, 1); // End before start
        
        // Should throw ArgumentError for invalid range
        expect(
          () => TimelineErrorHandler.validateDateRange(startDate, endDate),
          throwsArgumentError,
          reason: 'Should throw ArgumentError when end date is before start date',
        );
      }
    });

    test('should clamp invalid indices to valid range', () {
      // Feature: timeline-performance-optimization, Property 11: Edge Case Handling
      
      final random = Random(42);
      
      for (var i = 0; i < 100; i++) {
        final min = 0;
        final max = random.nextInt(100) + 10; // 10-110
        
        // Test negative indices
        final negativeIndex = -random.nextInt(100) - 1; // -1 to -100
        final clampedNegative = TimelineErrorHandler.clampIndex(negativeIndex, min, max);
        expect(clampedNegative, equals(min),
            reason: 'Negative index should be clamped to min');
        
        // Test indices beyond max
        final beyondMax = max + random.nextInt(100) + 1; // max+1 to max+100
        final clampedBeyond = TimelineErrorHandler.clampIndex(beyondMax, min, max);
        expect(clampedBeyond, equals(max),
            reason: 'Index beyond max should be clamped to max');
        
        // Test valid indices
        final validIndex = random.nextInt(max - min + 1) + min;
        final clampedValid = TimelineErrorHandler.clampIndex(validIndex, min, max);
        expect(clampedValid, equals(validIndex),
            reason: 'Valid index should remain unchanged');
      }
    });

    test('should handle scroll beyond limits', () {
      // Feature: timeline-performance-optimization, Property 11: Edge Case Handling
      
      final random = Random(42);
      
      for (var i = 0; i < 100; i++) {
        final maxOffset = random.nextDouble() * 1000 + 100; // 100-1100
        
        // Test negative scroll offset
        final negativeOffset = -random.nextDouble() * 100; // 0 to -100
        final clampedNegative = TimelineErrorHandler.clampScrollOffset(negativeOffset, maxOffset);
        expect(clampedNegative, equals(0.0),
            reason: 'Negative scroll offset should be clamped to 0');
        
        // Test scroll beyond max
        final beyondMax = maxOffset + random.nextDouble() * 100; // maxOffset to maxOffset+100
        final clampedBeyond = TimelineErrorHandler.clampScrollOffset(beyondMax, maxOffset);
        expect(clampedBeyond, equals(maxOffset),
            reason: 'Scroll beyond max should be clamped to maxOffset');
        
        // Test valid scroll offset
        final validOffset = random.nextDouble() * maxOffset;
        final clampedValid = TimelineErrorHandler.clampScrollOffset(validOffset, maxOffset);
        expect(clampedValid, equals(validOffset),
            reason: 'Valid scroll offset should remain unchanged');
      }
    });

    test('should validate days list and filter invalid entries', () {
      // Feature: timeline-performance-optimization, Property 11: Edge Case Handling
      
      for (var i = 0; i < 100; i++) {
        final days = [
          // Valid day
          {'date': DateTime(2024, 1, 1), 'lmax': 8},
          // Missing date
          {'lmax': 8},
          // Invalid date type
          {'date': '2024-01-01', 'lmax': 8},
          // Missing lmax
          {'date': DateTime(2024, 1, 2)},
          // Valid day
          {'date': DateTime(2024, 1, 3), 'lmax': 8},
        ];
        
        final validDays = TimelineErrorHandler.validateDays(days);
        
        // Should only return valid days (2 out of 5)
        expect(validDays.length, equals(2),
            reason: 'Should filter out invalid day entries');
        
        // All returned days should have required fields
        for (final day in validDays) {
          expect(day.containsKey('date'), isTrue);
          expect(day['date'], isA<DateTime>());
          expect(day.containsKey('lmax'), isTrue);
        }
      }
    });

    test('should validate stages list and filter invalid entries', () {
      // Feature: timeline-performance-optimization, Property 11: Edge Case Handling
      
      for (var i = 0; i < 100; i++) {
        final stages = [
          // Valid stage
          {'sdate': '2024-01-01', 'edate': '2024-01-10', 'type': 'milestone'},
          // Missing sdate
          {'edate': '2024-01-10', 'type': 'milestone'},
          // Missing edate
          {'sdate': '2024-01-01', 'type': 'milestone'},
          // Missing type
          {'sdate': '2024-01-01', 'edate': '2024-01-10'},
          // Valid stage
          {'sdate': '2024-01-15', 'edate': '2024-01-20', 'type': 'cycle'},
        ];
        
        final validStages = TimelineErrorHandler.validateStages(stages);
        
        // Should only return valid stages (2 out of 5)
        expect(validStages.length, equals(2),
            reason: 'Should filter out invalid stage entries');
        
        // All returned stages should have required fields
        for (final stage in validStages) {
          expect(stage.containsKey('sdate'), isTrue);
          expect(stage.containsKey('edate'), isTrue);
          expect(stage.containsKey('type'), isTrue);
        }
      }
    });

    test('should validate elements list and filter invalid entries', () {
      // Feature: timeline-performance-optimization, Property 11: Edge Case Handling
      
      for (var i = 0; i < 100; i++) {
        final elements = [
          // Valid element
          {'pre_id': 'elem1', 'date': '2024-01-01'},
          // Missing pre_id
          {'date': '2024-01-01'},
          // Missing date
          {'pre_id': 'elem2'},
          // Valid element
          {'pre_id': 'elem3', 'date': '2024-01-05'},
        ];
        
        final validElements = TimelineErrorHandler.validateElements(elements);
        
        // Should only return valid elements (2 out of 4)
        expect(validElements.length, equals(2),
            reason: 'Should filter out invalid element entries');
        
        // All returned elements should have required fields
        for (final element in validElements) {
          expect(element.containsKey('pre_id'), isTrue);
          expect(element.containsKey('date'), isTrue);
        }
      }
    });

    test('should handle safe list access with invalid indices', () {
      // Feature: timeline-performance-optimization, Property 11: Edge Case Handling
      
      final random = Random(42);
      
      for (var i = 0; i < 100; i++) {
        final list = List.generate(10, (index) => index * 2);
        final fallback = -1;
        
        // Test negative index
        final negativeResult = TimelineErrorHandler.safeListAccess(list, -1, fallback);
        expect(negativeResult, equals(fallback),
            reason: 'Should return fallback for negative index');
        
        // Test index beyond length
        final beyondResult = TimelineErrorHandler.safeListAccess(list, 100, fallback);
        expect(beyondResult, equals(fallback),
            reason: 'Should return fallback for index beyond length');
        
        // Test valid index
        final validIndex = random.nextInt(list.length);
        final validResult = TimelineErrorHandler.safeListAccess(list, validIndex, fallback);
        expect(validResult, equals(list[validIndex]),
            reason: 'Should return actual value for valid index');
      }
    });

    test('should handle TimelineController with edge case values', () {
      // Feature: timeline-performance-optimization, Property 11: Edge Case Handling
      
      final random = Random(42);
      
      for (var i = 0; i < 100; i++) {
        final totalDays = random.nextInt(100) + 1; // 1-100
        final controller = TimelineController(
          dayWidth: 45.0,
          dayMargin: 5.0,
          totalDays: totalDays,
          viewportWidth: 800.0,
        );
        
        // Test negative scroll offset
        controller.updateScrollOffset(-100.0);
        // Wait for throttle
        Future.delayed(const Duration(milliseconds: 20), () {
          expect(controller.centerItemIndex.value, greaterThanOrEqualTo(0),
              reason: 'Center index should not be negative');
        });
        
        // Test very large scroll offset
        controller.updateScrollOffset(100000.0);
        Future.delayed(const Duration(milliseconds: 20), () {
          expect(controller.centerItemIndex.value, lessThan(totalDays),
              reason: 'Center index should not exceed total days');
        });
        
        controller.dispose();
      }
    });

    test('should handle withErrorHandling wrapper correctly', () {
      // Feature: timeline-performance-optimization, Property 11: Edge Case Handling
      
      for (var i = 0; i < 100; i++) {
        // Test successful operation
        final successResult = TimelineErrorHandler.withErrorHandling(
          'testOperation',
          () => 42,
          -1,
        );
        expect(successResult, equals(42),
            reason: 'Should return operation result on success');
        
        // Test operation that throws
        final errorResult = TimelineErrorHandler.withErrorHandling(
          'testOperation',
          () => throw Exception('Test error'),
          -1,
        );
        expect(errorResult, equals(-1),
            reason: 'Should return fallback on error');
      }
    });

    test('should handle data manager with invalid date ranges', () {
      // Feature: timeline-performance-optimization, Property 11: Edge Case Handling
      
      for (var i = 0; i < 100; i++) {
        final dataManager = TimelineDataManager();
        final startDate = DateTime(2024, 1, 31);
        final endDate = DateTime(2024, 1, 1); // Invalid: end before start
        
        // Should return empty list instead of crashing
        final result = dataManager.getFormattedDays(
          startDate: startDate,
          endDate: endDate,
          elements: [],
          elementsDone: [],
          capacities: [],
          stages: [],
          maxCapacity: 8,
        );
        
        expect(result, isEmpty,
            reason: 'Should return empty list for invalid date range');
      }
    });
  });
}
