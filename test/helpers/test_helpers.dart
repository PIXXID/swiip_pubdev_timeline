import 'package:flutter_test/flutter_test.dart';

/// Utility class with common test assertions and validation helpers.
///
/// This class provides reusable assertion methods that make tests more readable
/// and maintainable. Instead of writing complex expect() statements with custom
/// matchers, use these helper methods for common validation patterns.
///
/// **Categories:**
/// - **Bounds Checking**: Verify values are within expected ranges
/// - **Structure Validation**: Verify data structures have required fields
/// - **Comparison**: Deep equality, sorting, duplicates
/// - **Type Checking**: Verify types and list properties
///
/// **Usage Example:**
/// ```dart
/// import 'helpers/test_helpers.dart';
///
/// test('my test', () {
///   final index = calculateIndex();
///
///   // Instead of: expect(index >= 0 && index < 100, isTrue)
///   TestHelpers.expectIndexInBounds(index, 0, 99);
///
///   // Instead of complex configuration validation
///   TestHelpers.expectValidConfiguration(config);
/// });
/// ```
///
/// **Benefits:**
/// - More descriptive error messages
/// - Consistent validation across tests
/// - Reduced boilerplate code
/// - Self-documenting test intent
class TestHelpers {
  /// Verifies that an index is within the specified bounds [min, max]
  static void expectIndexInBounds(int index, int min, int max,
      {String? reason}) {
    final message =
        reason != null ? 'Index out of bounds: $reason' : 'Index out of bounds';
    expect(
      index >= min && index <= max,
      isTrue,
      reason: '$message (index: $index, min: $min, max: $max)',
    );
  }

  /// Verifies that a configuration map contains all required parameters
  static void expectValidConfiguration(Map<String, dynamic> config) {
    expect(config, isNotNull, reason: 'Configuration should not be null');
    expect(config, isNotEmpty, reason: 'Configuration should not be empty');

    // Check for common required parameters
    final requiredParams = [
      'dayWidth',
      'dayMargin',
      'rowHeight',
      'bufferDays',
      'scrollThrottleMs',
    ];

    for (final param in requiredParams) {
      expect(
        config.containsKey(param),
        isTrue,
        reason: 'Configuration missing required parameter: $param',
      );
    }
  }

  /// Verifies that a list of formatted days has the correct structure
  static void expectValidDaysList(List<Map<String, dynamic>> days) {
    expect(days, isNotNull, reason: 'Days list should not be null');

    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      expect(day, isNotNull, reason: 'Day at index $i should not be null');
      expect(day.containsKey('date'), isTrue,
          reason: 'Day $i missing date field');
      expect(day.containsKey('dayIndex'), isTrue,
          reason: 'Day $i missing dayIndex field');
    }
  }

  /// Verifies that no stages overlap within a single row
  static void expectNoOverlapsInRow(List<Map<String, dynamic>> row) {
    if (row.length <= 1) return; // No overlaps possible with 0 or 1 stages

    // Sort by start index
    final sorted = List<Map<String, dynamic>>.from(row)
      ..sort((a, b) =>
          (a['startDateIndex'] as int).compareTo(b['startDateIndex'] as int));

    for (int i = 0; i < sorted.length - 1; i++) {
      final current = sorted[i];
      final next = sorted[i + 1];

      final currentEnd = current['endDateIndex'] as int;
      final nextStart = next['startDateIndex'] as int;

      expect(
        currentEnd < nextStart,
        isTrue,
        reason: 'Stages overlap in row: stage ${current['id']} '
            '(end: $currentEnd) overlaps with stage ${next['id']} (start: $nextStart)',
      );
    }
  }

  /// Verifies that a value is within a specified range
  static void expectInRange(num value, num min, num max, {String? reason}) {
    final message =
        reason != null ? 'Value out of range: $reason' : 'Value out of range';
    expect(
      value >= min && value <= max,
      isTrue,
      reason: '$message (value: $value, min: $min, max: $max)',
    );
  }

  /// Verifies that two maps are deeply equal
  static void expectDeepEquals(
      Map<String, dynamic> actual, Map<String, dynamic> expected) {
    expect(actual.keys.length, equals(expected.keys.length),
        reason: 'Maps have different number of keys');

    for (final key in expected.keys) {
      expect(actual.containsKey(key), isTrue,
          reason: 'Actual map missing key: $key');
      expect(actual[key], equals(expected[key]),
          reason: 'Values differ for key: $key');
    }
  }

  /// Verifies that a list contains no duplicate elements based on a key extractor
  static void expectNoDuplicates<T>(
      List<T> list, dynamic Function(T) keyExtractor,
      {String? reason}) {
    final seen = <dynamic>{};
    final duplicates = <dynamic>[];

    for (final item in list) {
      final key = keyExtractor(item);
      if (seen.contains(key)) {
        duplicates.add(key);
      }
      seen.add(key);
    }

    expect(
      duplicates,
      isEmpty,
      reason: reason ?? 'List contains duplicates: $duplicates',
    );
  }

  /// Verifies that a date range is valid (endDate >= startDate)
  static void expectValidDateRange(DateTime startDate, DateTime endDate) {
    expect(
      endDate.isAfter(startDate) || endDate.isAtSameMomentAs(startDate),
      isTrue,
      reason:
          'Invalid date range: endDate ($endDate) must be >= startDate ($startDate)',
    );
  }

  /// Verifies that a list is sorted according to a comparator
  static void expectSorted<T>(List<T> list, int Function(T, T) compare,
      {String? reason}) {
    for (int i = 0; i < list.length - 1; i++) {
      final comparison = compare(list[i], list[i + 1]);
      expect(
        comparison <= 0,
        isTrue,
        reason: reason ??
            'List not sorted at index $i: ${list[i]} > ${list[i + 1]}',
      );
    }
  }

  /// Verifies that a value is of the expected type
  static void expectType<T>(dynamic value, {String? reason}) {
    expect(
      value is T,
      isTrue,
      reason: reason ?? 'Expected type $T but got ${value.runtimeType}',
    );
  }

  /// Verifies that a list has the expected length
  static void expectLength(List<dynamic> list, int expectedLength,
      {String? reason}) {
    expect(
      list.length,
      equals(expectedLength),
      reason:
          reason ?? 'Expected length $expectedLength but got ${list.length}',
    );
  }

  /// Verifies that all elements in a list satisfy a predicate
  static void expectAll<T>(List<T> list, bool Function(T) predicate,
      {String? reason}) {
    for (int i = 0; i < list.length; i++) {
      expect(
        predicate(list[i]),
        isTrue,
        reason: reason ??
            'Element at index $i does not satisfy predicate: ${list[i]}',
      );
    }
  }
}
