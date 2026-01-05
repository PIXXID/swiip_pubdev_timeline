/// A high-performance Flutter timeline/Gantt chart widget.
///
/// This library provides a scrollable timeline widget for displaying project schedules,
/// milestones, and activities across a date range. It's optimized for large datasets
/// with lazy rendering, data caching, and efficient scroll management.
///
/// ## Features
///
/// - **Lazy Rendering**: Only renders visible items plus a configurable buffer
/// - **High Performance**: Handles 500+ days with 100+ stages efficiently
/// - **Data Caching**: Avoids redundant calculations for better performance
/// - **External Configuration**: Performance tuning via JSON configuration file
/// - **Interactive**: Callbacks for day clicks, stage edits, and element edits
///
/// ## Usage
///
/// ```dart
/// import 'package:swiip_pubdev_timeline/swiip_pubdev_timeline.dart';
///
/// Timeline(
///   colors: {
///     'primaryBackground': Colors.white,
///     'error': Colors.red,
///     // ... other colors
///   },
///   infos: {
///     'startDate': '2024-01-01',
///     'endDate': '2024-12-31',
///     'lmax': 100,
///   },
///   elements: myElements,
///   elementsDone: myCompletedElements,
///   capacities: myCapacities,
///   stages: myStages,
///   openDayDetail: (date, capacity, stageIds, elements, metadata) {
///     print('Clicked day: $date');
///   },
/// )
/// ```
///
/// ## Performance
///
/// The widget is optimized for large datasets:
/// - Initial render < 500ms
/// - Memory usage ~50MB (vs ~200MB unoptimized)
/// - 90% reduction in rebuild count
///
/// See [Timeline] for detailed documentation.
library;

export "src/timeline/timeline.dart";
