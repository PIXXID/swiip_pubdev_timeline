/// Performance metrics for monitoring timeline rendering and behavior.
///
/// This class captures key performance indicators that can be used for
/// profiling, debugging, and validating optimization efforts.
class PerformanceMetrics {
  /// Time taken to render the timeline.
  final Duration renderTime;

  /// Total number of widgets in the timeline.
  final int widgetCount;

  /// Number of widget rebuilds that occurred.
  final int rebuildCount;

  /// Memory usage in megabytes.
  final double memoryUsageMB;

  /// Average frames per second during the measured period.
  final double averageFPS;

  /// Creates a [PerformanceMetrics] instance with the given measurements.
  const PerformanceMetrics({
    required this.renderTime,
    required this.widgetCount,
    required this.rebuildCount,
    required this.memoryUsageMB,
    required this.averageFPS,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceMetrics &&
          runtimeType == other.runtimeType &&
          renderTime == other.renderTime &&
          widgetCount == other.widgetCount &&
          rebuildCount == other.rebuildCount &&
          memoryUsageMB == other.memoryUsageMB &&
          averageFPS == other.averageFPS;

  @override
  int get hashCode => Object.hash(
        renderTime,
        widgetCount,
        rebuildCount,
        memoryUsageMB,
        averageFPS,
      );

  @override
  String toString() {
    return 'PerformanceMetrics(\n'
        '  renderTime: ${renderTime.inMilliseconds}ms,\n'
        '  widgetCount: $widgetCount,\n'
        '  rebuildCount: $rebuildCount,\n'
        '  memoryUsage: ${memoryUsageMB.toStringAsFixed(2)}MB,\n'
        '  averageFPS: ${averageFPS.toStringAsFixed(1)}\n'
        ')';
  }
}
