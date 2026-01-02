import 'package:flutter_test/flutter_test.dart';
import 'package:swiip_pubdev_timeline/src/timeline/models/timeline_error_handler.dart';

void main() {
  group('TimelineErrorHandler', () {
    group('validateDateRange', () {
      test('does not throw exception with valid dates', () {
        // Requirements: 6.1
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);

        expect(
          () => TimelineErrorHandler.validateDateRange(start, end),
          returnsNormally,
          reason: 'Valid date range should not throw exception',
        );

        final result = TimelineErrorHandler.validateDateRange(start, end);
        expect(result, equals(end), reason: 'Should return the end date when valid');
      });

      test('does not throw exception when start equals end', () {
        // Requirements: 6.1
        final date = DateTime(2024, 1, 15);

        expect(
          () => TimelineErrorHandler.validateDateRange(date, date),
          returnsNormally,
          reason: 'Date range with equal start and end should not throw exception',
        );
      });

      test('throws ArgumentError when endDate is before startDate', () {
        // Requirements: 6.2
        final start = DateTime(2024, 1, 31);
        final end = DateTime(2024, 1, 1);

        expect(
          () => TimelineErrorHandler.validateDateRange(start, end),
          throwsA(isA<ArgumentError>()),
          reason: 'Should throw ArgumentError when end date is before start date',
        );
      });

      test('throws ArgumentError with descriptive message', () {
        // Requirements: 6.2
        final start = DateTime(2024, 1, 31);
        final end = DateTime(2024, 1, 1);

        try {
          TimelineErrorHandler.validateDateRange(start, end);
          fail('Should have thrown ArgumentError');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          expect(
            e.toString(),
            contains('End date must be after start date'),
            reason: 'Error message should be descriptive',
          );
        }
      });
    });

    group('validateDays', () {
      test('filters out days without required date field', () {
        // Requirements: 6.2
        final days = [
          {'date': DateTime(2024, 1, 1), 'lmax': 10},
          {'lmax': 10}, // Missing date
          {'date': DateTime(2024, 1, 2), 'lmax': 10},
        ];

        final result = TimelineErrorHandler.validateDays(days);

        expect(result.length, equals(2), reason: 'Should filter out day without date field');
        expect(result[0]['date'], equals(DateTime(2024, 1, 1)));
        expect(result[1]['date'], equals(DateTime(2024, 1, 2)));
      });

      test('filters out days without required lmax field', () {
        // Requirements: 6.2
        final days = [
          {'date': DateTime(2024, 1, 1), 'lmax': 10},
          {'date': DateTime(2024, 1, 2)}, // Missing lmax
          {'date': DateTime(2024, 1, 3), 'lmax': 10},
        ];

        final result = TimelineErrorHandler.validateDays(days);

        expect(result.length, equals(2), reason: 'Should filter out day without lmax field');
        expect(result[0]['date'], equals(DateTime(2024, 1, 1)));
        expect(result[1]['date'], equals(DateTime(2024, 1, 3)));
      });

      test('filters out days with invalid date type', () {
        // Requirements: 6.2
        final days = [
          {'date': DateTime(2024, 1, 1), 'lmax': 10},
          {'date': '2024-01-02', 'lmax': 10}, // String instead of DateTime
          {'date': DateTime(2024, 1, 3), 'lmax': 10},
        ];

        final result = TimelineErrorHandler.validateDays(days);

        expect(result.length, equals(2), reason: 'Should filter out day with invalid date type');
        expect(result[0]['date'], equals(DateTime(2024, 1, 1)));
        expect(result[1]['date'], equals(DateTime(2024, 1, 3)));
      });

      test('returns empty list when input is null', () {
        // Requirements: 6.2
        final result = TimelineErrorHandler.validateDays(null);

        expect(result, isEmpty, reason: 'Should return empty list for null input');
      });

      test('returns empty list when all days are invalid', () {
        // Requirements: 6.2
        final days = [
          {'lmax': 10}, // Missing date
          {'date': '2024-01-02', 'lmax': 10}, // Invalid date type
        ];

        final result = TimelineErrorHandler.validateDays(days);

        expect(result, isEmpty, reason: 'Should return empty list when all days are invalid');
      });

      test('returns all days when all are valid', () {
        // Requirements: 6.2
        final days = [
          {'date': DateTime(2024, 1, 1), 'lmax': 10},
          {'date': DateTime(2024, 1, 2), 'lmax': 20},
          {'date': DateTime(2024, 1, 3), 'lmax': 30},
        ];

        final result = TimelineErrorHandler.validateDays(days);

        expect(result.length, equals(3), reason: 'Should return all valid days');
      });
    });

    group('validateStages', () {
      test('filters out stages without required sdate field', () {
        // Requirements: 6.2
        final stages = [
          {'sdate': '2024-01-01', 'edate': '2024-01-10', 'type': 'milestone'},
          {'edate': '2024-01-10', 'type': 'milestone'}, // Missing sdate
          {'sdate': '2024-01-05', 'edate': '2024-01-15', 'type': 'task'},
        ];

        final result = TimelineErrorHandler.validateStages(stages);

        expect(result.length, equals(2), reason: 'Should filter out stage without sdate field');
        expect(result[0]['sdate'], equals('2024-01-01'));
        expect(result[1]['sdate'], equals('2024-01-05'));
      });

      test('filters out stages without required edate field', () {
        // Requirements: 6.2
        final stages = [
          {'sdate': '2024-01-01', 'edate': '2024-01-10', 'type': 'milestone'},
          {'sdate': '2024-01-05', 'type': 'task'}, // Missing edate
          {'sdate': '2024-01-10', 'edate': '2024-01-20', 'type': 'phase'},
        ];

        final result = TimelineErrorHandler.validateStages(stages);

        expect(result.length, equals(2), reason: 'Should filter out stage without edate field');
        expect(result[0]['edate'], equals('2024-01-10'));
        expect(result[1]['edate'], equals('2024-01-20'));
      });

      test('filters out stages without required type field', () {
        // Requirements: 6.2
        final stages = [
          {'sdate': '2024-01-01', 'edate': '2024-01-10', 'type': 'milestone'},
          {'sdate': '2024-01-05', 'edate': '2024-01-15'}, // Missing type
          {'sdate': '2024-01-10', 'edate': '2024-01-20', 'type': 'phase'},
        ];

        final result = TimelineErrorHandler.validateStages(stages);

        expect(result.length, equals(2), reason: 'Should filter out stage without type field');
        expect(result[0]['type'], equals('milestone'));
        expect(result[1]['type'], equals('phase'));
      });

      test('returns empty list when input is null', () {
        // Requirements: 6.2
        final result = TimelineErrorHandler.validateStages(null);

        expect(result, isEmpty, reason: 'Should return empty list for null input');
      });

      test('returns empty list when all stages are invalid', () {
        // Requirements: 6.2
        final stages = [
          {'edate': '2024-01-10', 'type': 'milestone'}, // Missing sdate
          {'sdate': '2024-01-05', 'type': 'task'}, // Missing edate
          {'sdate': '2024-01-10', 'edate': '2024-01-20'}, // Missing type
        ];

        final result = TimelineErrorHandler.validateStages(stages);

        expect(result, isEmpty, reason: 'Should return empty list when all stages are invalid');
      });

      test('returns all stages when all are valid', () {
        // Requirements: 6.2
        final stages = [
          {'sdate': '2024-01-01', 'edate': '2024-01-10', 'type': 'milestone'},
          {'sdate': '2024-01-05', 'edate': '2024-01-15', 'type': 'task'},
          {'sdate': '2024-01-10', 'edate': '2024-01-20', 'type': 'phase'},
        ];

        final result = TimelineErrorHandler.validateStages(stages);

        expect(result.length, equals(3), reason: 'Should return all valid stages');
      });
    });

    group('validateElements', () {
      test('filters out elements without required pre_id field', () {
        // Requirements: 6.2
        final elements = [
          {'pre_id': 'elem1', 'date': '2024-01-01'},
          {'date': '2024-01-02'}, // Missing pre_id
          {'pre_id': 'elem3', 'date': '2024-01-03'},
        ];

        final result = TimelineErrorHandler.validateElements(elements);

        expect(result.length, equals(2), reason: 'Should filter out element without pre_id field');
        expect(result[0]['pre_id'], equals('elem1'));
        expect(result[1]['pre_id'], equals('elem3'));
      });

      test('filters out elements without required date field', () {
        // Requirements: 6.2
        final elements = [
          {'pre_id': 'elem1', 'date': '2024-01-01'},
          {'pre_id': 'elem2'}, // Missing date
          {'pre_id': 'elem3', 'date': '2024-01-03'},
        ];

        final result = TimelineErrorHandler.validateElements(elements);

        expect(result.length, equals(2), reason: 'Should filter out element without date field');
        expect(result[0]['pre_id'], equals('elem1'));
        expect(result[1]['pre_id'], equals('elem3'));
      });

      test('returns empty list when input is null', () {
        // Requirements: 6.2
        final result = TimelineErrorHandler.validateElements(null);

        expect(result, isEmpty, reason: 'Should return empty list for null input');
      });

      test('returns empty list when all elements are invalid', () {
        // Requirements: 6.2
        final elements = [
          {'date': '2024-01-01'}, // Missing pre_id
          {'pre_id': 'elem2'}, // Missing date
        ];

        final result = TimelineErrorHandler.validateElements(elements);

        expect(result, isEmpty, reason: 'Should return empty list when all elements are invalid');
      });

      test('returns all elements when all are valid', () {
        // Requirements: 6.2
        final elements = [
          {'pre_id': 'elem1', 'date': '2024-01-01'},
          {'pre_id': 'elem2', 'date': '2024-01-02'},
          {'pre_id': 'elem3', 'date': '2024-01-03'},
        ];

        final result = TimelineErrorHandler.validateElements(elements);

        expect(result.length, equals(3), reason: 'Should return all valid elements');
      });
    });

    group('isValidList', () {
      test('returns true for non-empty list', () {
        // Requirements: 6.2
        final list = [1, 2, 3];

        expect(
          TimelineErrorHandler.isValidList(list),
          isTrue,
          reason: 'Should return true for non-empty list',
        );
      });

      test('returns false for empty list', () {
        // Requirements: 6.2
        final list = [];

        expect(
          TimelineErrorHandler.isValidList(list),
          isFalse,
          reason: 'Should return false for empty list',
        );
      });

      test('returns false for null list', () {
        // Requirements: 6.2
        expect(
          TimelineErrorHandler.isValidList(null),
          isFalse,
          reason: 'Should return false for null list',
        );
      });

      test('returns true for list with single element', () {
        // Requirements: 6.2
        final list = [1];

        expect(
          TimelineErrorHandler.isValidList(list),
          isTrue,
          reason: 'Should return true for list with single element',
        );
      });

      test('works with different list types', () {
        // Requirements: 6.2
        expect(TimelineErrorHandler.isValidList([1, 2, 3]), isTrue);
        expect(TimelineErrorHandler.isValidList(['a', 'b']), isTrue);
        expect(TimelineErrorHandler.isValidList([true, false]), isTrue);
        expect(TimelineErrorHandler.isValidList(<int>[]), isFalse);
      });
    });

    group('clampIndex', () {
      test('returns same value when index is within bounds', () {
        // Requirements: 6.3
        final result = TimelineErrorHandler.clampIndex(5, 0, 10);

        expect(result, equals(5), reason: 'Should return same value when index is within bounds');
      });

      test('returns same value when index equals minimum', () {
        // Requirements: 6.3
        final result = TimelineErrorHandler.clampIndex(0, 0, 10);

        expect(result, equals(0), reason: 'Should return same value when index equals minimum');
      });

      test('returns same value when index equals maximum', () {
        // Requirements: 6.3
        final result = TimelineErrorHandler.clampIndex(10, 0, 10);

        expect(result, equals(10), reason: 'Should return same value when index equals maximum');
      });

      test('returns minimum when index is below minimum', () {
        // Requirements: 6.4
        final result = TimelineErrorHandler.clampIndex(-5, 0, 10);

        expect(result, equals(0), reason: 'Should return minimum when index is below minimum');
      });

      test('returns minimum when index is negative and min is positive', () {
        // Requirements: 6.4
        final result = TimelineErrorHandler.clampIndex(-1, 5, 10);

        expect(result, equals(5), reason: 'Should return minimum when index is negative');
      });

      test('returns maximum when index is above maximum', () {
        // Requirements: 6.5
        final result = TimelineErrorHandler.clampIndex(15, 0, 10);

        expect(result, equals(10), reason: 'Should return maximum when index is above maximum');
      });

      test('returns maximum when index is much larger than maximum', () {
        // Requirements: 6.5
        final result = TimelineErrorHandler.clampIndex(1000, 0, 10);

        expect(result, equals(10), reason: 'Should return maximum when index is much larger');
      });

      test('works correctly with single-value range', () {
        // Requirements: 6.3, 6.4, 6.5
        expect(TimelineErrorHandler.clampIndex(5, 5, 5), equals(5));
        expect(TimelineErrorHandler.clampIndex(3, 5, 5), equals(5));
        expect(TimelineErrorHandler.clampIndex(7, 5, 5), equals(5));
      });

      test('works correctly with negative ranges', () {
        // Requirements: 6.3, 6.4, 6.5
        expect(TimelineErrorHandler.clampIndex(-5, -10, -1), equals(-5));
        expect(TimelineErrorHandler.clampIndex(-15, -10, -1), equals(-10));
        expect(TimelineErrorHandler.clampIndex(0, -10, -1), equals(-1));
      });

      test('works correctly with large ranges', () {
        // Requirements: 6.3, 6.4, 6.5
        expect(TimelineErrorHandler.clampIndex(500, 0, 1000), equals(500));
        expect(TimelineErrorHandler.clampIndex(-100, 0, 1000), equals(0));
        expect(TimelineErrorHandler.clampIndex(1500, 0, 1000), equals(1000));
      });
    });

    group('clampScrollOffset', () {
      test('returns same value when offset is within bounds', () {
        // Requirements: 6.6
        final result = TimelineErrorHandler.clampScrollOffset(500.0, 1000.0);

        expect(result, equals(500.0), reason: 'Should return same value when offset is within bounds');
      });

      test('returns same value when offset equals zero', () {
        // Requirements: 6.6
        final result = TimelineErrorHandler.clampScrollOffset(0.0, 1000.0);

        expect(result, equals(0.0), reason: 'Should return same value when offset equals zero');
      });

      test('returns same value when offset equals maximum', () {
        // Requirements: 6.6
        final result = TimelineErrorHandler.clampScrollOffset(1000.0, 1000.0);

        expect(result, equals(1000.0), reason: 'Should return same value when offset equals maximum');
      });

      test('returns zero when offset is negative', () {
        // Requirements: 6.6
        final result = TimelineErrorHandler.clampScrollOffset(-50.0, 1000.0);

        expect(result, equals(0.0), reason: 'Should return zero when offset is negative');
      });

      test('returns zero when offset is very negative', () {
        // Requirements: 6.6
        final result = TimelineErrorHandler.clampScrollOffset(-1000.0, 1000.0);

        expect(result, equals(0.0), reason: 'Should return zero when offset is very negative');
      });

      test('returns maximum when offset exceeds maximum', () {
        // Requirements: 6.6
        final result = TimelineErrorHandler.clampScrollOffset(1500.0, 1000.0);

        expect(result, equals(1000.0), reason: 'Should return maximum when offset exceeds maximum');
      });

      test('returns maximum when offset is much larger than maximum', () {
        // Requirements: 6.6
        final result = TimelineErrorHandler.clampScrollOffset(10000.0, 1000.0);

        expect(result, equals(1000.0), reason: 'Should return maximum when offset is much larger');
      });

      test('works correctly with zero maximum', () {
        // Requirements: 6.6
        expect(TimelineErrorHandler.clampScrollOffset(0.0, 0.0), equals(0.0));
        expect(TimelineErrorHandler.clampScrollOffset(-10.0, 0.0), equals(0.0));
        expect(TimelineErrorHandler.clampScrollOffset(10.0, 0.0), equals(0.0));
      });

      test('works correctly with decimal values', () {
        // Requirements: 6.6
        expect(TimelineErrorHandler.clampScrollOffset(123.45, 1000.0), equals(123.45));
        expect(TimelineErrorHandler.clampScrollOffset(-0.5, 1000.0), equals(0.0));
        expect(TimelineErrorHandler.clampScrollOffset(1000.5, 1000.0), equals(1000.0));
      });

      test('works correctly with large maximum values', () {
        // Requirements: 6.6
        final maxOffset = 100000.0;
        expect(TimelineErrorHandler.clampScrollOffset(50000.0, maxOffset), equals(50000.0));
        expect(TimelineErrorHandler.clampScrollOffset(-100.0, maxOffset), equals(0.0));
        expect(TimelineErrorHandler.clampScrollOffset(150000.0, maxOffset), equals(maxOffset));
      });
    });

    group('withErrorHandling', () {
      test('returns result when operation succeeds', () {
        // Requirements: 6.7
        final result = TimelineErrorHandler.withErrorHandling(
          'test operation',
          () => 42,
          0,
        );

        expect(result, equals(42), reason: 'Should return operation result when successful');
      });

      test('returns result when operation succeeds with string', () {
        // Requirements: 6.7
        final result = TimelineErrorHandler.withErrorHandling(
          'test operation',
          () => 'success',
          'fallback',
        );

        expect(result, equals('success'), reason: 'Should return operation result when successful');
      });

      test('returns result when operation succeeds with list', () {
        // Requirements: 6.7
        final result = TimelineErrorHandler.withErrorHandling(
          'test operation',
          () => [1, 2, 3],
          <int>[],
        );

        expect(result, equals([1, 2, 3]), reason: 'Should return operation result when successful');
      });

      test('returns result when operation succeeds with map', () {
        // Requirements: 6.7
        final result = TimelineErrorHandler.withErrorHandling(
          'test operation',
          () => {'key': 'value'},
          <String, String>{},
        );

        expect(result, equals({'key': 'value'}), reason: 'Should return operation result when successful');
      });

      test('returns fallback when operation throws exception', () {
        // Requirements: 6.8
        final result = TimelineErrorHandler.withErrorHandling(
          'test operation',
          () => throw Exception('Test error'),
          42,
        );

        expect(result, equals(42), reason: 'Should return fallback when operation throws');
      });

      test('returns fallback when operation throws ArgumentError', () {
        // Requirements: 6.8
        final result = TimelineErrorHandler.withErrorHandling(
          'test operation',
          () => throw ArgumentError('Invalid argument'),
          'fallback',
        );

        expect(result, equals('fallback'), reason: 'Should return fallback when operation throws ArgumentError');
      });

      test('returns fallback when operation throws StateError', () {
        // Requirements: 6.8
        final result = TimelineErrorHandler.withErrorHandling(
          'test operation',
          () => throw StateError('Invalid state'),
          100,
        );

        expect(result, equals(100), reason: 'Should return fallback when operation throws StateError');
      });

      test('returns fallback when operation throws FormatException', () {
        // Requirements: 6.8
        final result = TimelineErrorHandler.withErrorHandling(
          'test operation',
          () => throw FormatException('Invalid format'),
          [],
        );

        expect(result, equals([]), reason: 'Should return fallback when operation throws FormatException');
      });

      test('returns fallback when operation throws RangeError', () {
        // Requirements: 6.8
        final result = TimelineErrorHandler.withErrorHandling(
          'test operation',
          () {
            final list = [1, 2, 3];
            return list[10]; // Out of bounds
          },
          -1,
        );

        expect(result, equals(-1), reason: 'Should return fallback when operation throws RangeError');
      });

      test('works with different fallback types - int', () {
        // Requirements: 6.7, 6.8
        final successResult = TimelineErrorHandler.withErrorHandling(
          'test',
          () => 100,
          0,
        );
        final errorResult = TimelineErrorHandler.withErrorHandling(
          'test',
          () => throw Exception(),
          0,
        );

        expect(successResult, equals(100));
        expect(errorResult, equals(0));
      });

      test('works with different fallback types - string', () {
        // Requirements: 6.7, 6.8
        final successResult = TimelineErrorHandler.withErrorHandling(
          'test',
          () => 'result',
          'fallback',
        );
        final errorResult = TimelineErrorHandler.withErrorHandling(
          'test',
          () => throw Exception(),
          'fallback',
        );

        expect(successResult, equals('result'));
        expect(errorResult, equals('fallback'));
      });

      test('works with different fallback types - list', () {
        // Requirements: 6.7, 6.8
        final successResult = TimelineErrorHandler.withErrorHandling(
          'test',
          () => [1, 2, 3],
          <int>[],
        );
        final errorResult = TimelineErrorHandler.withErrorHandling(
          'test',
          () => throw Exception(),
          <int>[],
        );

        expect(successResult, equals([1, 2, 3]));
        expect(errorResult, equals([]));
      });

      test('works with different fallback types - map', () {
        // Requirements: 6.7, 6.8
        final successResult = TimelineErrorHandler.withErrorHandling(
          'test',
          () => {'key': 'value'},
          <String, String>{},
        );
        final errorResult = TimelineErrorHandler.withErrorHandling(
          'test',
          () => throw Exception(),
          <String, String>{},
        );

        expect(successResult, equals({'key': 'value'}));
        expect(errorResult, equals({}));
      });

      test('works with different fallback types - bool', () {
        // Requirements: 6.7, 6.8
        final successResult = TimelineErrorHandler.withErrorHandling(
          'test',
          () => true,
          false,
        );
        final errorResult = TimelineErrorHandler.withErrorHandling(
          'test',
          () => throw Exception(),
          false,
        );

        expect(successResult, isTrue);
        expect(errorResult, isFalse);
      });

      test('works with different fallback types - double', () {
        // Requirements: 6.7, 6.8
        final successResult = TimelineErrorHandler.withErrorHandling(
          'test',
          () => 3.14,
          0.0,
        );
        final errorResult = TimelineErrorHandler.withErrorHandling(
          'test',
          () => throw Exception(),
          0.0,
        );

        expect(successResult, equals(3.14));
        expect(errorResult, equals(0.0));
      });

      test('works with nullable fallback types', () {
        // Requirements: 6.7, 6.8
        final successResult = TimelineErrorHandler.withErrorHandling<int?>(
          'test',
          () => 42,
          null,
        );
        final errorResult = TimelineErrorHandler.withErrorHandling<int?>(
          'test',
          () => throw Exception(),
          null,
        );

        expect(successResult, equals(42));
        expect(errorResult, isNull);
      });
    });

    group('safeListAccess', () {
      test('returns element when index is valid', () {
        // Requirements: 6.3
        final list = [10, 20, 30, 40, 50];
        final result = TimelineErrorHandler.safeListAccess(list, 2, -1);

        expect(result, equals(30), reason: 'Should return element at valid index');
      });

      test('returns element at first index', () {
        // Requirements: 6.3
        final list = [10, 20, 30];
        final result = TimelineErrorHandler.safeListAccess(list, 0, -1);

        expect(result, equals(10), reason: 'Should return element at first index');
      });

      test('returns element at last index', () {
        // Requirements: 6.3
        final list = [10, 20, 30];
        final result = TimelineErrorHandler.safeListAccess(list, 2, -1);

        expect(result, equals(30), reason: 'Should return element at last index');
      });

      test('returns fallback when index is negative', () {
        // Requirements: 6.3
        final list = [10, 20, 30];
        final result = TimelineErrorHandler.safeListAccess(list, -1, 999);

        expect(result, equals(999), reason: 'Should return fallback when index is negative');
      });

      test('returns fallback when index is very negative', () {
        // Requirements: 6.3
        final list = [10, 20, 30];
        final result = TimelineErrorHandler.safeListAccess(list, -100, 999);

        expect(result, equals(999), reason: 'Should return fallback when index is very negative');
      });

      test('returns fallback when index is out of bounds (too large)', () {
        // Requirements: 6.3
        final list = [10, 20, 30];
        final result = TimelineErrorHandler.safeListAccess(list, 3, 999);

        expect(result, equals(999), reason: 'Should return fallback when index is out of bounds');
      });

      test('returns fallback when index is much larger than list length', () {
        // Requirements: 6.3
        final list = [10, 20, 30];
        final result = TimelineErrorHandler.safeListAccess(list, 100, 999);

        expect(result, equals(999), reason: 'Should return fallback when index is much larger');
      });

      test('works with single-element list', () {
        // Requirements: 6.3
        final list = [42];
        expect(TimelineErrorHandler.safeListAccess(list, 0, -1), equals(42));
        expect(TimelineErrorHandler.safeListAccess(list, -1, -1), equals(-1));
        expect(TimelineErrorHandler.safeListAccess(list, 1, -1), equals(-1));
      });

      test('works with empty list', () {
        // Requirements: 6.3
        final list = <int>[];
        expect(TimelineErrorHandler.safeListAccess(list, 0, 999), equals(999));
        expect(TimelineErrorHandler.safeListAccess(list, -1, 999), equals(999));
        expect(TimelineErrorHandler.safeListAccess(list, 1, 999), equals(999));
      });

      test('works with string list', () {
        // Requirements: 6.3
        final list = ['a', 'b', 'c'];
        expect(TimelineErrorHandler.safeListAccess(list, 1, 'fallback'), equals('b'));
        expect(TimelineErrorHandler.safeListAccess(list, -1, 'fallback'), equals('fallback'));
        expect(TimelineErrorHandler.safeListAccess(list, 5, 'fallback'), equals('fallback'));
      });

      test('works with map list', () {
        // Requirements: 6.3
        final list = [
          {'id': 1},
          {'id': 2},
          {'id': 3}
        ];
        final fallback = {'id': -1};

        expect(TimelineErrorHandler.safeListAccess(list, 1, fallback), equals({'id': 2}));
        expect(TimelineErrorHandler.safeListAccess(list, -1, fallback), equals(fallback));
        expect(TimelineErrorHandler.safeListAccess(list, 10, fallback), equals(fallback));
      });

      test('works with bool list', () {
        // Requirements: 6.3
        final list = [true, false, true];
        expect(TimelineErrorHandler.safeListAccess(list, 1, true), isFalse);
        expect(TimelineErrorHandler.safeListAccess(list, -1, true), isTrue);
        expect(TimelineErrorHandler.safeListAccess(list, 5, true), isTrue);
      });

      test('works with double list', () {
        // Requirements: 6.3
        final list = [1.1, 2.2, 3.3];
        expect(TimelineErrorHandler.safeListAccess(list, 1, 0.0), equals(2.2));
        expect(TimelineErrorHandler.safeListAccess(list, -1, 0.0), equals(0.0));
        expect(TimelineErrorHandler.safeListAccess(list, 5, 0.0), equals(0.0));
      });

      test('works with nullable fallback', () {
        // Requirements: 6.3
        final list = [10, 20, 30];
        expect(TimelineErrorHandler.safeListAccess<int?>(list, 1, null), equals(20));
        expect(TimelineErrorHandler.safeListAccess<int?>(list, -1, null), isNull);
        expect(TimelineErrorHandler.safeListAccess<int?>(list, 10, null), isNull);
      });

      test('boundary test - index equals list length', () {
        // Requirements: 6.3
        final list = [10, 20, 30];
        final result = TimelineErrorHandler.safeListAccess(list, 3, 999);

        expect(result, equals(999), reason: 'Index equal to list length should return fallback');
      });

      test('boundary test - index equals list length minus one', () {
        // Requirements: 6.3
        final list = [10, 20, 30];
        final result = TimelineErrorHandler.safeListAccess(list, 2, 999);

        expect(result, equals(30), reason: 'Index equal to list length minus one should return element');
      });
    });
  });
}
