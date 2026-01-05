import 'package:flutter/foundation.dart';
import 'performance_metrics.dart';

/// A performance monitoring utility for tracking timeline operations.
///
/// This class provides hooks for measuring operation times, tracking rebuilds,
/// and collecting performance metrics in development mode.
class PerformanceMonitor {
  /// Map of operation names to their start times.
  final Map<String, DateTime> _operationStartTimes = {};

  /// Map of operation names to their durations.
  final Map<String, Duration> _operationDurations = {};

  /// Counter for widget rebuilds.
  int _rebuildCount = 0;

  /// Counter for total widgets rendered.
  int _widgetCount = 0;

  /// List of frame times for FPS calculation.
  final List<Duration> _frameTimes = [];

  /// Memory usage samples in MB.
  final List<double> _memoryUsageSamples = [];

  /// Whether profiling is enabled (typically only in debug mode).
  final bool profilingEnabled;

  /// Creates a [PerformanceMonitor] instance.
  ///
  /// [profilingEnabled] determines whether monitoring is active.
  /// Defaults to true in debug mode, false in release mode.
  PerformanceMonitor({bool? profilingEnabled})
      : profilingEnabled = profilingEnabled ?? kDebugMode;

  /// Starts tracking an operation with the given [operationName].
  ///
  /// Call [endOperation] with the same name to complete the measurement.
  void startOperation(String operationName) {
    if (!profilingEnabled) return;

    _operationStartTimes[operationName] = DateTime.now();

    if (kDebugMode) {
      debugPrint('[PerformanceMonitor] Started: $operationName');
    }
  }

  /// Ends tracking an operation and records its duration.
  ///
  /// Returns the duration of the operation, or null if the operation
  /// was not started or profiling is disabled.
  Duration? endOperation(String operationName) {
    if (!profilingEnabled) return null;

    final startTime = _operationStartTimes.remove(operationName);
    if (startTime == null) {
      if (kDebugMode) {
        debugPrint(
            '[PerformanceMonitor] Warning: endOperation called for "$operationName" without startOperation');
      }
      return null;
    }

    final duration = DateTime.now().difference(startTime);
    _operationDurations[operationName] = duration;

    if (kDebugMode) {
      debugPrint(
          '[PerformanceMonitor] Completed: $operationName in ${duration.inMilliseconds}ms');
    }

    return duration;
  }

  /// Tracks a widget rebuild event.
  ///
  /// Call this method whenever a widget rebuilds to increment the counter.
  void trackRebuild() {
    if (!profilingEnabled) return;

    _rebuildCount++;

    if (kDebugMode && _rebuildCount % 10 == 0) {
      debugPrint('[PerformanceMonitor] Total rebuilds: $_rebuildCount');
    }
  }

  /// Tracks the number of widgets rendered.
  ///
  /// [count] is the number of widgets to add to the total.
  void trackWidgetCount(int count) {
    if (!profilingEnabled) return;

    _widgetCount += count;
  }

  /// Records a frame rendering time for FPS calculation.
  ///
  /// [frameTime] is the duration it took to render a single frame.
  void recordFrameTime(Duration frameTime) {
    if (!profilingEnabled) return;

    _frameTimes.add(frameTime);

    // Keep only the last 60 frames for rolling average
    if (_frameTimes.length > 60) {
      _frameTimes.removeAt(0);
    }
  }

  /// Records a memory usage sample.
  ///
  /// [memoryMB] is the current memory usage in megabytes.
  void recordMemoryUsage(double memoryMB) {
    if (!profilingEnabled) return;

    _memoryUsageSamples.add(memoryMB);

    // Keep only the last 10 samples
    if (_memoryUsageSamples.length > 10) {
      _memoryUsageSamples.removeAt(0);
    }
  }

  /// Gets the current performance metrics.
  ///
  /// Returns a [PerformanceMetrics] object with aggregated measurements.
  /// If no data has been collected, returns metrics with zero/default values.
  PerformanceMetrics getMetrics() {
    // Calculate average render time from all operations
    final renderTime = _operationDurations.values.isEmpty
        ? Duration.zero
        : _operationDurations.values.reduce((a, b) => a + b);

    // Calculate average FPS
    double averageFPS = 60.0; // Default FPS
    if (_frameTimes.isNotEmpty) {
      final totalMicroseconds =
          _frameTimes.map((d) => d.inMicroseconds).reduce((a, b) => a + b);
      final averageMicroseconds = totalMicroseconds / _frameTimes.length;

      // Avoid division by zero
      if (averageMicroseconds > 0) {
        averageFPS = 1000000.0 / averageMicroseconds;
      }
    }

    // Calculate average memory usage
    final averageMemory = _memoryUsageSamples.isEmpty
        ? 0.0
        : _memoryUsageSamples.reduce((a, b) => a + b) /
            _memoryUsageSamples.length;

    return PerformanceMetrics(
      renderTime: renderTime,
      widgetCount: _widgetCount,
      rebuildCount: _rebuildCount,
      memoryUsageMB: averageMemory,
      averageFPS: averageFPS,
    );
  }

  /// Gets the duration of a specific operation.
  ///
  /// Returns null if the operation hasn't been completed or doesn't exist.
  Duration? getOperationDuration(String operationName) {
    return _operationDurations[operationName];
  }

  /// Resets all collected metrics and counters.
  void reset() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    _rebuildCount = 0;
    _widgetCount = 0;
    _frameTimes.clear();
    _memoryUsageSamples.clear();

    if (kDebugMode) {
      debugPrint('[PerformanceMonitor] Metrics reset');
    }
  }

  /// Logs the current metrics to the debug console.
  ///
  /// Only logs in debug mode when profiling is enabled.
  void logMetrics() {
    if (!profilingEnabled || !kDebugMode) return;

    final metrics = getMetrics();
    debugPrint('[PerformanceMonitor] Current Metrics:');
    debugPrint(metrics.toString());

    // Log individual operation durations
    if (_operationDurations.isNotEmpty) {
      debugPrint('[PerformanceMonitor] Operation Durations:');
      _operationDurations.forEach((name, duration) {
        debugPrint('  $name: ${duration.inMilliseconds}ms');
      });
    }
  }
}
