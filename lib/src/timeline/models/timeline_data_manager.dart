import 'package:intl/intl.dart';
import 'timeline_error_handler.dart';

/// Manages timeline data formatting and caching for performance optimization.
///
/// This class is responsible for:
/// - Caching formatted days and stage rows to avoid redundant calculations
/// - Detecting when input data has changed using hash comparison
/// - Providing optimized versions of formatElements and formatStagesRows
///
/// The cache is invalidated automatically when input data changes, ensuring
/// data consistency while maximizing performance.
class TimelineDataManager {
  /// Cached list of formatted days.
  List<Map<String, dynamic>>? _cachedDays;

  /// Cached list of formatted stage rows.
  List<List<Map<String, dynamic>>>? _cachedTimelineRows;

  /// Hash of the last input data used to generate cached days.
  ///
  /// This is used to detect when input data has changed and the cache
  /// needs to be invalidated.
  int? _lastDataHash;

  /// Returns formatted days with caching.
  ///
  /// If the input data hasn't changed since the last call (determined by
  /// comparing hashes), returns the cached result. Otherwise, recomputes
  /// the formatted days and updates the cache.
  ///
  /// Parameters:
  /// - [startDate]: The start date of the timeline
  /// - [endDate]: The end date of the timeline
  /// - [elements]: List of timeline elements
  /// - [elementsDone]: List of completed elements
  /// - [capacities]: List of capacity data
  /// - [stages]: List of stages
  /// - [maxCapacity]: Maximum capacity value for calculations
  ///
  /// Returns a list of formatted day maps.
  List<Map<String, dynamic>> getFormattedDays({
    required DateTime startDate,
    required DateTime endDate,
    required List elements,
    required List elementsDone,
    required List capacities,
    required List stages,
    required int maxCapacity,
  }) {
    // Validate date range
    try {
      TimelineErrorHandler.validateDateRange(startDate, endDate);
    } catch (e, stack) {
      TimelineErrorHandler.handleDataError('validateDateRange', e, stack);
      return [];
    }

    // Calculate a hash of the input data
    final dataHash = Object.hash(
      startDate,
      endDate,
      elements.length,
      elementsDone.length,
      capacities.length,
      stages.length,
      maxCapacity,
    );

    // Return cached result if data hasn't changed
    if (_cachedDays != null && dataHash == _lastDataHash) {
      return _cachedDays!;
    }

    // Otherwise, recompute and cache with error handling
    _lastDataHash = dataHash;
    _cachedDays = TimelineErrorHandler.withErrorHandling(
      'formatElementsOptimized',
      () => _formatElementsOptimized(
        startDate,
        endDate,
        elements,
        elementsDone,
        capacities,
        stages,
        maxCapacity,
      ),
      [], // Fallback to empty list on error
    );

    return _cachedDays!;
  }

  /// Returns formatted stage rows with caching.
  ///
  /// If cached stage rows exist, returns them. Otherwise, computes the
  /// stage rows and caches the result.
  ///
  /// Note: This method assumes that if days data hasn't changed (checked
  /// in getFormattedDays), the stage rows also don't need recomputation.
  ///
  /// Parameters:
  /// - [startDate]: The start date of the timeline
  /// - [endDate]: The end date of the timeline
  /// - [days]: List of formatted days
  /// - [stages]: List of stages
  /// - [elements]: List of timeline elements
  ///
  /// Returns a list of stage row lists.
  List<List<Map<String, dynamic>>> getFormattedTimelineRows({
    required DateTime startDate,
    required DateTime endDate,
    required List days,
    required List stages,
    required List elements,
  }) {
    // Return cached result if available
    if (_cachedTimelineRows != null) {
      return _cachedTimelineRows!;
    }

    // Otherwise, compute and cache with error handling
    _cachedTimelineRows = TimelineErrorHandler.withErrorHandling(
      'formatStagesRowsOptimized',
      () => _formatStagesRowsOptimized(
        startDate,
        endDate,
        days,
        stages,
        elements,
      ),
      [], // Fallback to empty list on error
    );

    return _cachedTimelineRows!;
  }

  /// Clears all cached data.
  ///
  /// This should be called when you want to force a recomputation on the
  /// next call to getFormattedDays or getFormattedTimelineRows, regardless
  /// of whether the input data has changed.
  void clearCache() {
    _cachedDays = null;
    _cachedTimelineRows = null;
    _lastDataHash = null;
  }

  /// Optimized version of formatElements that uses efficient data structures.
  ///
  /// This method improves performance by:
  /// - Using maps for O(1) lookups instead of O(n) searches
  /// - Pre-indexing elements by date
  /// - Using List.generate for efficient list creation
  /// - Extracting helper methods for better code organization
  List<Map<String, dynamic>> _formatElementsOptimized(
    DateTime startDate,
    DateTime endDate,
    List elements,
    List elementsDone,
    List capacities,
    List stages,
    int maxCapacity,
  ) {
    final duration = endDate.difference(startDate).inDays;

    // Create maps for O(1) access instead of O(n) searches
    final elementsByDate = <String, List<Map<String, dynamic>>>{};
    final capacitiesByDate = <String, Map<String, dynamic>>{};
    final elementsDoneByDate = <String, List<Map<String, dynamic>>>{};

    // Pre-index elements by date
    for (final element in elements) {
      if (element == null) continue;
      final date = element['date'] as String?;
      if (date != null && date.isNotEmpty) {
        elementsByDate.putIfAbsent(date, () => []).add(element);
      }
    }

    for (final capacity in capacities) {
      if (capacity == null) continue;
      final date = capacity['date'] as String?;
      if (date != null && date.isNotEmpty) {
        capacitiesByDate[date] = capacity;
      }
    }

    for (final element in elementsDone) {
      if (element == null) continue;
      final date = element['date'] as String?;
      if (date != null && date.isNotEmpty) {
        elementsDoneByDate.putIfAbsent(date, () => []).add(element);
      }
    }

    // Generate the list of days efficiently
    final result = List<Map<String, dynamic>>.generate(
      duration + 1,
      (index) {
        final date = startDate.add(Duration(days: index));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final day = _createEmptyDay(date, maxCapacity);

        // Process elements for this day
        final dayElements = elementsByDate[dateStr];
        if (dayElements != null) {
          _processElementsForDay(day, dayElements);
        }

        // Process completed elements
        final dayElementsDone = elementsDoneByDate[dateStr];
        if (dayElementsDone != null) {
          for (final element in dayElementsDone) {
            final preId = element['pre_id'];
            if (!day['preIds'].contains(preId)) {
              day['preIds'].add(preId);
            }
          }
        }

        // Process capacities
        final dayCapacity = capacitiesByDate[dateStr];
        if (dayCapacity != null) {
          day['capeff'] = dayCapacity['capeff'] ?? 0;
          day['buseff'] = dayCapacity['buseff'] ?? 0;
          day['compeff'] = dayCapacity['compeff'] ?? 0;
          day['eicon'] = dayCapacity['eicon'];

          // Calculate alert level
          final progress =
              day['capeff'] > 0 ? (day['buseff'] / day['capeff']) * 100 : 0.0;
          day['alertLevel'] = progress > 100 ? 2 : (progress > 80 ? 1 : 0);
        }

        return day;
      },
    );

    return result;
  }

  /// Creates an empty day map with default values.
  Map<String, dynamic> _createEmptyDay(DateTime date, int maxCapacity) {
    return {
      'date': date,
      'lmax': maxCapacity,
      'activityTotal': 0,
      'activityCompleted': 0,
      'delivrableTotal': 0,
      'delivrableCompleted': 0,
      'taskTotal': 0,
      'taskCompleted': 0,
      'elementCompleted': 0,
      'elementPending': 0,
      'preIds': <String>[],
      'stage': {},
      'eicon': '',
      'capeff': 0,
      'buseff': 0,
      'compeff': 0,
      'alertLevel': 0,
    };
  }

  /// Processes elements for a specific day and updates the day map.
  ///
  /// This method counts elements by type and status, avoiding duplicates
  /// by tracking pre_ids that have already been processed.
  void _processElementsForDay(
      Map<String, dynamic> day, List<Map<String, dynamic>> elements) {
    final seenPreIds = <String>{};

    for (final element in elements) {
      final preId = element['pre_id'] as String?;
      if (preId == null || seenPreIds.contains(preId)) continue;

      seenPreIds.add(preId);
      day['preIds'].add(preId);

      // Count by type
      final nat = element['nat'] as String?;
      final status = element['status'] as String?;

      if (nat != null) {
        switch (nat) {
          case 'activity':
            day['activityTotal']++;
            if (status == 'status') day['activityCompleted']++;
            break;
          case 'delivrable':
            day['delivrableTotal']++;
            if (status == 'status') day['delivrableCompleted']++;
            break;
          case 'task':
            day['taskTotal']++;
            if (status == 'status') day['taskCompleted']++;
            break;
        }
      }

      // Count by status
      if (status == 'validated' || status == 'finished') {
        day['elementCompleted']++;
      } else if (status == 'pending' || status == 'inprogress') {
        day['elementPending']++;
      }
    }
  }

  /// Optimized version of formatStagesRows that uses efficient data structures.
  ///
  /// This method improves performance by:
  /// - Creating an index of elements by pre_id for O(1) lookups
  /// - Using Sets to avoid duplicates
  /// - Optimizing the row organization algorithm
  List<List<Map<String, dynamic>>> _formatStagesRowsOptimized(
    DateTime startDate,
    DateTime endDate,
    List days,
    List stages,
    List elements,
  ) {
    // Create an index of elements by pre_id for O(1) access
    final elementsByPreId = <String, Map<String, dynamic>>{};
    for (final element in elements) {
      if (element == null) continue;
      final preId = element['pre_id'];
      if (preId != null && preId is String && preId.isNotEmpty) {
        elementsByPreId[preId] = element;
      }
    }

    final mergedList = <Map<String, dynamic>>[];

    // Merge stages and their associated elements
    for (final stage in stages) {
      if (stage == null) continue;
      mergedList.add(stage);

      final elmFiltered = stage['elm_filtered'] as List?;
      if (elmFiltered != null) {
        final stageElements = <Map<String, dynamic>>[];
        final seenPreIds = <String>{};

        for (final preId in elmFiltered) {
          if (preId == null || preId is! String || seenPreIds.contains(preId)) {
            continue;
          }

          final element = elementsByPreId[preId];
          if (element != null) {
            seenPreIds.add(preId);
            stageElements.add({
              ...element,
              'pcolor': stage['pcolor'],
              'prs_id': stage['prs_id'],
            });
          }
        }

        // Sort by start date - with null safety
        stageElements.sort((a, b) {
          final aDate = a['sdate'];
          final bDate = b['sdate'];
          if (aDate == null || bDate == null) return 0;
          if (aDate is! String || bDate is! String) return 0;
          return aDate.compareTo(bDate);
        });

        mergedList.addAll(stageElements);
      }
    }

    // Organize into rows without overlap
    return _organizeIntoRows(mergedList, days, startDate);
  }

  /// Organizes stages and elements into rows such that no items overlap.
  ///
  /// This method uses an efficient algorithm to place items in the first
  /// available row where they don't overlap with existing items.
  List<List<Map<String, dynamic>>> _organizeIntoRows(
    List<Map<String, dynamic>> items,
    List days,
    DateTime startDate,
  ) {
    final rows = <List<Map<String, dynamic>>>[];
    var lastTimelineRowIndex = 0;

    for (final item in items) {
      // Safely access date fields with error handling
      final sdateStr = item['sdate'];
      final edateStr = item['edate'];

      if (sdateStr == null || edateStr == null) continue;

      // Validate that date strings are not empty
      if (sdateStr is! String || edateStr is! String) continue;
      if (sdateStr.isEmpty || edateStr.isEmpty) continue;

      DateTime stageStartDate;
      DateTime stageEndDate;

      try {
        stageStartDate = DateTime.parse(sdateStr);
        stageEndDate = DateTime.parse(edateStr);
      } catch (e) {
        // Skip items with invalid date formats
        continue;
      }

      // Clamp start date to timeline start
      final clampedStartDate =
          stageStartDate.isBefore(startDate) ? startDate : stageStartDate;

      final startDateIndex = days.indexWhere((d) =>
          d['date'] != null &&
          DateFormat('yyyy-MM-dd').format(d['date']) ==
              DateFormat('yyyy-MM-dd').format(clampedStartDate));

      final endDateIndex = days.indexWhere((d) =>
          d['date'] != null &&
          DateFormat('yyyy-MM-dd').format(d['date']) ==
              DateFormat('yyyy-MM-dd').format(stageEndDate));

      // Skip items outside the date range
      if (startDateIndex == -1 || endDateIndex == -1) continue;

      final itemWithIndices = {
        ...item,
        'startDateIndex': startDateIndex,
        'endDateIndex': endDateIndex,
      };

      final isStage =
          ['milestone', 'cycle', 'sequence', 'stage'].contains(item['type']);

      if (rows.isEmpty) {
        rows.add([itemWithIndices]);
        if (isStage) lastTimelineRowIndex = 0;
      } else {
        var placed = false;

        // Try to place in existing rows starting from lastTimelineRowIndex
        // Clamp lastTimelineRowIndex to valid range
        lastTimelineRowIndex = TimelineErrorHandler.clampIndex(
            lastTimelineRowIndex, 0, rows.length - 1);

        for (var j = lastTimelineRowIndex; j < rows.length; j++) {
          final hasOverlap = rows[j]
              .any((r) => (r['endDateIndex'] ?? -1) + 1 > startDateIndex);

          if (!hasOverlap) {
            if (isStage) lastTimelineRowIndex = j;
            rows[j].add(itemWithIndices);
            placed = true;
            break;
          }
        }

        // Create new row if no suitable row found
        if (!placed) {
          rows.add([itemWithIndices]);
          if (isStage) lastTimelineRowIndex = rows.length - 1;
        }
      }
    }

    return rows;
  }
}
