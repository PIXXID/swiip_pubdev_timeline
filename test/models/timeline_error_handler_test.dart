import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_error_handler.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_data_manager.dart';

/// Unit tests for TimelineErrorHandler edge cases
///
/// **Validates: Requirements 6.4**
///
/// These tests verify specific edge cases and error conditions:
/// - Null data handling
/// - Empty lists
/// - Invalid date ranges
/// - Negative indices
/// - Scroll beyond limits
void main() {
  group('TimelineErrorHandler Unit Tests', () {
    group('validateDays', () {
      test('should return empty list for null input', () {
        final result = TimelineErrorHandler.validateDays(null);
        expect(result, isEmpty);
      });

      test('should return empty list for empty input', () {
        final result = TimelineErrorHandler.validateDays([]);
        expect(result, isEmpty);
      });

      test('should filter out days without date field', () {
        final days = [
          {'date': DateTime(2024, 1, 1), 'lmax': 8},
          {'lmax': 8}, // Missing date
          {'date': DateTime(2024, 1, 2), 'lmax': 8},
        ];

        final result = TimelineErrorHandler.validateDays(days);
        expect(result.length, equals(2));
      });

      test('should filter out days with non-DateTime date', () {
        final days = [
          {'date': DateTime(2024, 1, 1), 'lmax': 8},
          {'date': '2024-01-02', 'lmax': 8}, // String instead of DateTime
          {'date': DateTime(2024, 1, 3), 'lmax': 8},
        ];

        final result = TimelineErrorHandler.validateDays(days);
        expect(result.length, equals(2));
      });

      test('should filter out days without lmax field', () {
        final days = [
          {'date': DateTime(2024, 1, 1), 'lmax': 8},
          {'date': DateTime(2024, 1, 2)}, // Missing lmax
          {'date': DateTime(2024, 1, 3), 'lmax': 8},
        ];

        final result = TimelineErrorHandler.validateDays(days);
        expect(result.length, equals(2));
      });
    });

    group('validateStages', () {
      test('should return empty list for null input', () {
        final result = TimelineErrorHandler.validateStages(null);
        expect(result, isEmpty);
      });

      test('should return empty list for empty input', () {
        final result = TimelineErrorHandler.validateStages([]);
        expect(result, isEmpty);
      });

      test('should filter out stages without required fields', () {
        final stages = [
          {'sdate': '2024-01-01', 'edate': '2024-01-10', 'type': 'milestone'},
          {'edate': '2024-01-10', 'type': 'milestone'}, // Missing sdate
          {'sdate': '2024-01-01', 'type': 'milestone'}, // Missing edate
          {'sdate': '2024-01-01', 'edate': '2024-01-10'}, // Missing type
          {'sdate': '2024-01-15', 'edate': '2024-01-20', 'type': 'cycle'},
        ];

        final result = TimelineErrorHandler.validateStages(stages);
        expect(result.length, equals(2));
      });
    });

    group('validateElements', () {
      test('should return empty list for null input', () {
        final result = TimelineErrorHandler.validateElements(null);
        expect(result, isEmpty);
      });

      test('should return empty list for empty input', () {
        final result = TimelineErrorHandler.validateElements([]);
        expect(result, isEmpty);
      });

      test('should filter out elements without required fields', () {
        final elements = [
          {'pre_id': 'elem1', 'date': '2024-01-01'},
          {'date': '2024-01-01'}, // Missing pre_id
          {'pre_id': 'elem2'}, // Missing date
          {'pre_id': 'elem3', 'date': '2024-01-05'},
        ];

        final result = TimelineErrorHandler.validateElements(elements);
        expect(result.length, equals(2));
      });
    });

    group('clampIndex', () {
      test('should clamp negative index to min', () {
        expect(TimelineErrorHandler.clampIndex(-5, 0, 10), equals(0));
        expect(TimelineErrorHandler.clampIndex(-1, 0, 10), equals(0));
        expect(TimelineErrorHandler.clampIndex(-100, 5, 20), equals(5));
      });

      test('should clamp index beyond max to max', () {
        expect(TimelineErrorHandler.clampIndex(15, 0, 10), equals(10));
        expect(TimelineErrorHandler.clampIndex(100, 0, 10), equals(10));
        expect(TimelineErrorHandler.clampIndex(50, 5, 20), equals(20));
      });

      test('should not change valid index', () {
        expect(TimelineErrorHandler.clampIndex(5, 0, 10), equals(5));
        expect(TimelineErrorHandler.clampIndex(0, 0, 10), equals(0));
        expect(TimelineErrorHandler.clampIndex(10, 0, 10), equals(10));
      });
    });

    group('clampScrollOffset', () {
      test('should clamp negative offset to 0', () {
        expect(
            TimelineErrorHandler.clampScrollOffset(-10.0, 100.0), equals(0.0));
        expect(
            TimelineErrorHandler.clampScrollOffset(-0.1, 100.0), equals(0.0));
      });

      test('should clamp offset beyond max to max', () {
        expect(TimelineErrorHandler.clampScrollOffset(150.0, 100.0),
            equals(100.0));
        expect(TimelineErrorHandler.clampScrollOffset(1000.0, 100.0),
            equals(100.0));
      });

      test('should not change valid offset', () {
        expect(
            TimelineErrorHandler.clampScrollOffset(50.0, 100.0), equals(50.0));
        expect(TimelineErrorHandler.clampScrollOffset(0.0, 100.0), equals(0.0));
        expect(TimelineErrorHandler.clampScrollOffset(100.0, 100.0),
            equals(100.0));
      });
    });

    group('validateDateRange', () {
      test('should throw ArgumentError when end is before start', () {
        final start = DateTime(2024, 1, 31);
        final end = DateTime(2024, 1, 1);

        expect(
          () => TimelineErrorHandler.validateDateRange(start, end),
          throwsArgumentError,
        );
      });

      test('should return end date when range is valid', () {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);

        final result = TimelineErrorHandler.validateDateRange(start, end);
        expect(result, equals(end));
      });

      test('should accept same start and end date', () {
        final date = DateTime(2024, 1, 15);

        final result = TimelineErrorHandler.validateDateRange(date, date);
        expect(result, equals(date));
      });
    });

    group('safeListAccess', () {
      test('should return fallback for negative index', () {
        final list = [1, 2, 3, 4, 5];
        final result = TimelineErrorHandler.safeListAccess(list, -1, -999);
        expect(result, equals(-999));
      });

      test('should return fallback for index beyond length', () {
        final list = [1, 2, 3, 4, 5];
        final result = TimelineErrorHandler.safeListAccess(list, 10, -999);
        expect(result, equals(-999));
      });

      test('should return actual value for valid index', () {
        final list = [1, 2, 3, 4, 5];
        expect(TimelineErrorHandler.safeListAccess(list, 0, -999), equals(1));
        expect(TimelineErrorHandler.safeListAccess(list, 2, -999), equals(3));
        expect(TimelineErrorHandler.safeListAccess(list, 4, -999), equals(5));
      });

      test('should work with empty list', () {
        final list = <int>[];
        final result = TimelineErrorHandler.safeListAccess(list, 0, -999);
        expect(result, equals(-999));
      });
    });

    group('isValidList', () {
      test('should return false for null list', () {
        expect(TimelineErrorHandler.isValidList(null), isFalse);
      });

      test('should return false for empty list', () {
        expect(TimelineErrorHandler.isValidList([]), isFalse);
      });

      test('should return true for non-empty list', () {
        expect(TimelineErrorHandler.isValidList([1]), isTrue);
        expect(TimelineErrorHandler.isValidList([1, 2, 3]), isTrue);
      });
    });

    group('withErrorHandling', () {
      test('should return operation result on success', () {
        final result = TimelineErrorHandler.withErrorHandling(
          'test',
          () => 42,
          -1,
        );
        expect(result, equals(42));
      });

      test('should return fallback on exception', () {
        final result = TimelineErrorHandler.withErrorHandling(
          'test',
          () => throw Exception('Test error'),
          -1,
        );
        expect(result, equals(-1));
      });

      test('should handle different return types', () {
        final stringResult = TimelineErrorHandler.withErrorHandling(
          'test',
          () => 'success',
          'fallback',
        );
        expect(stringResult, equals('success'));

        final listResult = TimelineErrorHandler.withErrorHandling(
          'test',
          () => throw Exception('Error'),
          <int>[],
        );
        expect(listResult, isEmpty);
      });
    });
  });

  group('TimelineDataManager Edge Cases', () {
    test('should handle null elements gracefully', () {
      final dataManager = TimelineDataManager();
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      final result = dataManager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: [],
        elementsDone: [],
        capacities: [],
        stages: [],
        maxCapacity: 8,
      );

      expect(result, isNotEmpty);
      expect(result.length, equals(31)); // 31 days in January
    });

    test('should handle empty data gracefully', () {
      final dataManager = TimelineDataManager();
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 10);

      final result = dataManager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: [],
        elementsDone: [],
        capacities: [],
        stages: [],
        maxCapacity: 8,
      );

      expect(result, isNotEmpty);
      expect(result.length, equals(10));

      // Verify each day has default values
      for (final day in result) {
        expect(day['activityTotal'], equals(0));
        expect(day['elementCompleted'], equals(0));
        expect(day['preIds'], isEmpty);
      }
    });

    test('should handle invalid date range gracefully', () {
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

      expect(result, isEmpty);
    });

    test('should handle single day timeline', () {
      final dataManager = TimelineDataManager();
      final date = DateTime(2024, 1, 15);

      final result = dataManager.getFormattedDays(
        startDate: date,
        endDate: date,
        elements: [],
        elementsDone: [],
        capacities: [],
        stages: [],
        maxCapacity: 8,
      );

      expect(result.length, equals(1));
      expect(result[0]['date'], equals(date));
    });
  });
}
