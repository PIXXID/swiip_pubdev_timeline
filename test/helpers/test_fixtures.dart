/// Reusable test data fixtures for timeline tests.
///
/// This class provides predefined test data for common testing scenarios,
/// eliminating the need to create test data from scratch in every test.
/// All fixtures are static getters that return fresh data on each access.
///
/// **Categories:**
/// - **Configuration Fixtures**: Valid, invalid, minimal, and boundary configurations
/// - **Date Fixtures**: Standard date ranges for testing
/// - **Element Fixtures**: Sample timeline elements with various types and scenarios
/// - **Stage Fixtures**: Sample stages with overlapping and non-overlapping configurations
/// - **Capacity Fixtures**: Sample capacity data with different alert levels
/// - **Scroll Calculation Fixtures**: Parameters for scroll calculation tests
///
/// **Usage Example:**
/// ```dart
/// import 'helpers/test_fixtures.dart';
///
/// test('my test', () {
///   // Use predefined configuration
///   final config = TestFixtures.defaultConfig;
///
///   // Use predefined date range
///   final startDate = TestFixtures.testStartDate;
///   final endDate = TestFixtures.testEndDate;
///
///   // Use predefined elements
///   final elements = TestFixtures.sampleElements;
/// });
/// ```
///
/// **Benefits:**
/// - Consistency across tests
/// - Reduced boilerplate code
/// - Well-documented test scenarios
/// - Easy to understand test intent
class TestFixtures {
  // ==================== Configuration Fixtures ====================

  /// Default valid configuration for testing
  static Map<String, dynamic> get defaultConfig => {
        'dayWidth': 100.0,
        'dayMargin': 5.0,
        'rowHeight': 60.0,
        'bufferDays': 10,
        'scrollThrottleMs': 16,
        'animationDurationMs': 200,
        'minDayWidth': 50.0,
        'maxDayWidth': 200.0,
        'minRowHeight': 40.0,
        'maxRowHeight': 100.0,
      };

  /// Invalid configuration with out-of-range and wrong-type values
  static Map<String, dynamic> get invalidConfig => {
        'dayWidth': -50.0, // Negative value
        'dayMargin': 'invalid', // Wrong type
        'rowHeight': 0.0, // Zero value
        'bufferDays': -5, // Negative value
        'scrollThrottleMs': null, // Null value
        'animationDurationMs': 'not a number', // Wrong type
      };

  /// Minimal valid configuration with only required parameters
  static Map<String, dynamic> get minimalConfig => {
        'dayWidth': 80.0,
        'dayMargin': 2.0,
        'rowHeight': 50.0,
        'bufferDays': 5,
        'scrollThrottleMs': 16,
      };

  /// Configuration with boundary values
  static Map<String, dynamic> get boundaryConfig => {
        'dayWidth': 50.0, // Minimum
        'dayMargin': 0.0, // Minimum
        'rowHeight': 40.0, // Minimum
        'bufferDays': 0, // Minimum
        'scrollThrottleMs': 0, // Minimum
      };

  // ==================== Date Fixtures ====================

  /// Standard test start date
  static DateTime get testStartDate => DateTime(2024, 1, 1);

  /// Standard test end date (30 days from start)
  static DateTime get testEndDate => DateTime(2024, 1, 31);

  /// Extended test end date (365 days from start)
  static DateTime get testEndDateExtended => DateTime(2024, 12, 31);

  /// Date range for a single day
  static DateTime get singleDayStart => DateTime(2024, 6, 15);
  static DateTime get singleDayEnd => DateTime(2024, 6, 15);

  // ==================== Element Fixtures ====================

  /// Sample timeline elements with various types
  static List<Map<String, dynamic>> get sampleElements => [
        {
          'pre_id': 'elem_001',
          'type': 'activity',
          'start_date': '2024-01-05T00:00:00.000',
          'end_date': '2024-01-10T00:00:00.000',
          'name': 'Activity 1',
          'buseff': 40.0,
        },
        {
          'pre_id': 'elem_002',
          'type': 'delivrable',
          'start_date': '2024-01-08T00:00:00.000',
          'end_date': '2024-01-12T00:00:00.000',
          'name': 'Deliverable 1',
          'buseff': 30.0,
        },
        {
          'pre_id': 'elem_003',
          'type': 'task',
          'start_date': '2024-01-15T00:00:00.000',
          'end_date': '2024-01-20T00:00:00.000',
          'name': 'Task 1',
          'buseff': 50.0,
        },
        {
          'pre_id': 'elem_004',
          'type': 'activity',
          'start_date': '2024-01-18T00:00:00.000',
          'end_date': '2024-01-25T00:00:00.000',
          'name': 'Activity 2',
          'buseff': 60.0,
        },
      ];

  /// Elements with duplicate pre_ids (for deduplication testing)
  static List<Map<String, dynamic>> get duplicateElements => [
        {
          'pre_id': 'elem_dup',
          'type': 'activity',
          'start_date': '2024-01-05T00:00:00.000',
          'end_date': '2024-01-10T00:00:00.000',
          'name': 'Duplicate Activity',
          'buseff': 40.0,
        },
        {
          'pre_id': 'elem_dup', // Same pre_id
          'type': 'activity',
          'start_date': '2024-01-05T00:00:00.000',
          'end_date': '2024-01-10T00:00:00.000',
          'name': 'Duplicate Activity',
          'buseff': 40.0,
        },
        {
          'pre_id': 'elem_unique',
          'type': 'task',
          'start_date': '2024-01-12T00:00:00.000',
          'end_date': '2024-01-15T00:00:00.000',
          'name': 'Unique Task',
          'buseff': 30.0,
        },
      ];

  /// Elements spanning multiple days
  static List<Map<String, dynamic>> get multiDayElements => [
        {
          'pre_id': 'elem_long_001',
          'type': 'activity',
          'start_date': '2024-01-01T00:00:00.000',
          'end_date': '2024-01-15T00:00:00.000', // 15 days
          'name': 'Long Activity',
          'buseff': 80.0,
        },
        {
          'pre_id': 'elem_long_002',
          'type': 'delivrable',
          'start_date': '2024-01-10T00:00:00.000',
          'end_date': '2024-01-30T00:00:00.000', // 21 days
          'name': 'Long Deliverable',
          'buseff': 90.0,
        },
      ];

  /// Empty elements list
  static List<Map<String, dynamic>> get emptyElements => [];

  /// Elements with null values (using dynamic list to allow nulls)
  static List<dynamic> get elementsWithNulls => [
        {
          'pre_id': 'elem_valid',
          'type': 'activity',
          'start_date': '2024-01-05T00:00:00.000',
          'end_date': '2024-01-10T00:00:00.000',
          'name': 'Valid Activity',
          'buseff': 40.0,
        },
        null, // Null element
        {
          'pre_id': null, // Null pre_id
          'type': 'task',
          'start_date': '2024-01-12T00:00:00.000',
          'end_date': '2024-01-15T00:00:00.000',
          'name': 'Task with null id',
          'buseff': 30.0,
        },
      ];

  // ==================== Stage Fixtures ====================

  /// Sample stages with various configurations
  static List<Map<String, dynamic>> get sampleStages => [
        {
          'id': 'stage_001',
          'name': 'Planning Phase',
          'start_date': '2024-01-01T00:00:00.000',
          'end_date': '2024-01-10T00:00:00.000',
          'color': '#FF5733',
        },
        {
          'id': 'stage_002',
          'name': 'Development Phase',
          'start_date': '2024-01-11T00:00:00.000',
          'end_date': '2024-01-25T00:00:00.000',
          'color': '#33FF57',
        },
        {
          'id': 'stage_003',
          'name': 'Testing Phase',
          'start_date': '2024-01-26T00:00:00.000',
          'end_date': '2024-01-31T00:00:00.000',
          'color': '#3357FF',
        },
      ];

  /// Overlapping stages (should be placed in different rows)
  static List<Map<String, dynamic>> get overlappingStages => [
        {
          'id': 'stage_overlap_1',
          'name': 'Stage 1',
          'start_date': '2024-01-01T00:00:00.000',
          'end_date': '2024-01-15T00:00:00.000',
          'color': '#FF5733',
        },
        {
          'id': 'stage_overlap_2',
          'name': 'Stage 2',
          'start_date': '2024-01-10T00:00:00.000', // Overlaps with Stage 1
          'end_date': '2024-01-20T00:00:00.000',
          'color': '#33FF57',
        },
        {
          'id': 'stage_overlap_3',
          'name': 'Stage 3',
          'start_date': '2024-01-18T00:00:00.000', // Overlaps with Stage 2
          'end_date': '2024-01-25T00:00:00.000',
          'color': '#3357FF',
        },
      ];

  /// Non-overlapping stages (can be placed in same row)
  static List<Map<String, dynamic>> get nonOverlappingStages => [
        {
          'id': 'stage_seq_1',
          'name': 'Stage 1',
          'start_date': '2024-01-01T00:00:00.000',
          'end_date': '2024-01-05T00:00:00.000',
          'color': '#FF5733',
        },
        {
          'id': 'stage_seq_2',
          'name': 'Stage 2',
          'start_date': '2024-01-06T00:00:00.000', // No overlap
          'end_date': '2024-01-10T00:00:00.000',
          'color': '#33FF57',
        },
        {
          'id': 'stage_seq_3',
          'name': 'Stage 3',
          'start_date': '2024-01-11T00:00:00.000', // No overlap
          'end_date': '2024-01-15T00:00:00.000',
          'color': '#3357FF',
        },
      ];

  /// Empty stages list
  static List<Map<String, dynamic>> get emptyStages => [];

  // ==================== Capacity Fixtures ====================

  /// Sample capacity data with various alert levels
  static List<Map<String, dynamic>> get sampleCapacities => [
        {
          'date': '2024-01-05T00:00:00.000',
          'capeff': 100.0,
          'buseff': 60.0, // 60% - Alert level 0
        },
        {
          'date': '2024-01-10T00:00:00.000',
          'capeff': 100.0,
          'buseff': 90.0, // 90% - Alert level 1
        },
        {
          'date': '2024-01-15T00:00:00.000',
          'capeff': 100.0,
          'buseff': 120.0, // 120% - Alert level 2 (over capacity)
        },
        {
          'date': '2024-01-20T00:00:00.000',
          'capeff': 80.0,
          'buseff': 40.0, // 50% - Alert level 0
        },
      ];

  /// Capacity data at boundary thresholds
  static List<Map<String, dynamic>> get boundaryCapacities => [
        {
          'date': '2024-01-05T00:00:00.000',
          'capeff': 100.0,
          'buseff': 80.0, // Exactly 80% - boundary between level 0 and 1
        },
        {
          'date': '2024-01-10T00:00:00.000',
          'capeff': 100.0,
          'buseff': 100.0, // Exactly 100% - boundary between level 1 and 2
        },
      ];

  /// Empty capacity list
  static List<Map<String, dynamic>> get emptyCapacities => [];

  // ==================== Scroll Calculation Fixtures ====================

  /// Standard scroll calculation parameters
  static Map<String, dynamic> get standardScrollParams => {
        'scrollOffset': 500.0,
        'viewportWidth': 800.0,
        'dayWidth': 100.0,
        'dayMargin': 5.0,
        'totalDays': 100,
      };

  /// Scroll parameters at start of timeline
  static Map<String, dynamic> get scrollAtStart => {
        'scrollOffset': 0.0,
        'viewportWidth': 800.0,
        'dayWidth': 100.0,
        'dayMargin': 5.0,
        'totalDays': 100,
      };

  /// Scroll parameters at end of timeline
  static Map<String, dynamic> get scrollAtEnd => {
        'scrollOffset': 10000.0, // Large offset
        'viewportWidth': 800.0,
        'dayWidth': 100.0,
        'dayMargin': 5.0,
        'totalDays': 100,
      };

  /// Scroll parameters with empty timeline
  static Map<String, dynamic> get scrollEmptyTimeline => {
        'scrollOffset': 100.0,
        'viewportWidth': 800.0,
        'dayWidth': 100.0,
        'dayMargin': 5.0,
        'totalDays': 0,
      };

  /// Scroll parameters with negative offset (overscroll)
  static Map<String, dynamic> get scrollNegativeOffset => {
        'scrollOffset': -100.0,
        'viewportWidth': 800.0,
        'dayWidth': 100.0,
        'dayMargin': 5.0,
        'totalDays': 100,
      };
}
