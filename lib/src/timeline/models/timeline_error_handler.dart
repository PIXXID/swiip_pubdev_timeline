import 'package:flutter/foundation.dart';

/// Error handler for timeline operations.
///
/// Provides utilities for handling errors gracefully, validating data,
/// and ensuring safe operations on timeline data structures.
class TimelineErrorHandler {
  /// Handles and logs data errors.
  ///
  /// In debug mode, prints the error and stack trace. In production,
  /// this could be extended to log to analytics services.
  static void handleDataError(String context, dynamic error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('Timeline Error [$context]: $error');
      debugPrintStack(stackTrace: stack);
    }
    // In production, log to analytics service
    // Example: Analytics.logError(context, error, stack);
  }

  /// Wraps an operation with error handling.
  ///
  /// Executes the [operation] and returns its result. If an error occurs,
  /// logs the error and returns the [fallback] value instead.
  ///
  /// Example:
  /// ```dart
  /// final result = TimelineErrorHandler.withErrorHandling(
  ///   'formatDays',
  ///   () => formatDays(data),
  ///   [],
  /// );
  /// ```
  static T withErrorHandling<T>(
    String context,
    T Function() operation,
    T fallback,
  ) {
    try {
      return operation();
    } catch (e, stack) {
      handleDataError(context, e, stack);
      return fallback;
    }
  }

  /// Validates a list of day items.
  ///
  /// Filters out invalid day items that don't have required fields
  /// or have invalid data types. Returns only valid days.
  static List<Map<String, dynamic>> validateDays(
      List<Map<String, dynamic>>? days) {
    if (days == null) return [];

    return days.where((day) {
      return day.containsKey('date') &&
          day['date'] is DateTime &&
          day.containsKey('lmax');
    }).toList();
  }

  /// Clamps an index to a valid range.
  ///
  /// Ensures the [index] is within [min] and [max] bounds (inclusive).
  /// Returns the clamped value.
  static int clampIndex(int index, int min, int max) {
    return index.clamp(min, max);
  }

  /// Validates a date range.
  ///
  /// Ensures that [end] is not before [start]. Throws an [ArgumentError]
  /// if the range is invalid.
  ///
  /// Returns [end] if valid.
  static DateTime validateDateRange(DateTime start, DateTime end) {
    if (end.isBefore(start)) {
      throw ArgumentError(
          'End date must be after start date: start=$start, end=$end');
    }
    return end;
  }

  /// Validates and clamps a scroll offset.
  ///
  /// Ensures the scroll offset is within valid bounds [0, maxOffset].
  /// Returns the clamped offset.
  static double clampScrollOffset(double offset, double maxOffset) {
    return offset.clamp(0.0, maxOffset);
  }

  /// Validates a list is not null and not empty.
  ///
  /// Returns true if the list is valid (not null and not empty).
  static bool isValidList(List? list) {
    return list != null && list.isNotEmpty;
  }

  /// Safely gets an element from a list at the given index.
  ///
  /// Returns the element if the index is valid, otherwise returns [fallback].
  static T safeListAccess<T>(List<T> list, int index, T fallback) {
    if (index < 0 || index >= list.length) {
      return fallback;
    }
    return list[index];
  }

  /// Validates stage data.
  ///
  /// Filters out invalid stages that don't have required fields.
  static List<Map<String, dynamic>> validateStages(
      List<Map<String, dynamic>>? stages) {
    if (stages == null) return [];

    return stages.where((stage) {
      return stage.containsKey('sdate') &&
          stage.containsKey('edate') &&
          stage.containsKey('type');
    }).toList();
  }

  /// Validates element data.
  ///
  /// Filters out invalid elements that don't have required fields.
  static List<Map<String, dynamic>> validateElements(
      List<Map<String, dynamic>>? elements) {
    if (elements == null) return [];

    return elements.where((element) {
      return element.containsKey('pre_id') && element.containsKey('date');
    }).toList();
  }
}
