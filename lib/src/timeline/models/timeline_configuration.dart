/// Configuration options for timeline performance and rendering behavior.
///
/// This class encapsulates all configurable parameters that affect how the
/// timeline renders and performs, allowing for easy tuning and optimization.
class TimelineConfiguration {
  /// Width of each day item in pixels.
  final double dayWidth;

  /// Margin between day items in pixels.
  final double dayMargin;

  /// Height of the dates section in pixels.
  final double datesHeight;

  /// Height of the timeline section in pixels.
  final double timelineHeight;

  /// Height of each stage row in pixels.
  final double rowHeight;

  /// Margin between stage rows in pixels.
  final double rowMargin;

  /// Number of buffer days to render outside the visible viewport.
  ///
  /// A larger buffer reduces the chance of blank areas during fast scrolling,
  /// but increases memory usage and render time.
  final int bufferDays;

  /// Duration for throttling scroll events.
  ///
  /// Scroll calculations will be performed at most once per this duration,
  /// reducing CPU usage during rapid scrolling.
  final Duration scrollThrottleDuration;

  /// Duration for animations (e.g., auto-scroll, transitions).
  final Duration animationDuration;

  /// Creates a [TimelineConfiguration] with the given parameters.
  ///
  /// All parameters have sensible defaults optimized for typical use cases.
  const TimelineConfiguration({
    this.dayWidth = 45.0,
    this.dayMargin = 5.0,
    this.datesHeight = 65.0,
    this.timelineHeight = 300.0,
    this.rowHeight = 30.0,
    this.rowMargin = 3.0,
    this.bufferDays = 5,
    this.scrollThrottleDuration = const Duration(milliseconds: 16),
    this.animationDuration = const Duration(milliseconds: 220),
  });

  /// Creates a [TimelineConfiguration] from a map.
  ///
  /// This is useful for loading configuration from JSON files.
  /// Missing parameters will use default values.
  factory TimelineConfiguration.fromMap(Map<String, dynamic> map) {
    // Parse durations
    Duration scrollThrottleDuration = const Duration(milliseconds: 16);
    if (map['scrollThrottleMs'] != null) {
      scrollThrottleDuration = Duration(
        milliseconds: (map['scrollThrottleMs'] as num).toInt(),
      );
    }

    Duration animationDuration = const Duration(milliseconds: 220);
    if (map['animationDurationMs'] != null) {
      animationDuration = Duration(
        milliseconds: (map['animationDurationMs'] as num).toInt(),
      );
    }

    return TimelineConfiguration(
      dayWidth: (map['dayWidth'] as num?)?.toDouble() ?? 45.0,
      dayMargin: (map['dayMargin'] as num?)?.toDouble() ?? 5.0,
      datesHeight: (map['datesHeight'] as num?)?.toDouble() ?? 65.0,
      timelineHeight: (map['timelineHeight'] as num?)?.toDouble() ?? 300.0,
      rowHeight: (map['rowHeight'] as num?)?.toDouble() ?? 30.0,
      rowMargin: (map['rowMargin'] as num?)?.toDouble() ?? 3.0,
      bufferDays: (map['bufferDays'] as num?)?.toInt() ?? 5,
      scrollThrottleDuration: scrollThrottleDuration,
      animationDuration: animationDuration,
    );
  }

  /// Converts this configuration to a map.
  ///
  /// This is useful for debugging and serialization.
  Map<String, dynamic> toMap() {
    return {
      'dayWidth': dayWidth,
      'dayMargin': dayMargin,
      'datesHeight': datesHeight,
      'timelineHeight': timelineHeight,
      'rowHeight': rowHeight,
      'rowMargin': rowMargin,
      'bufferDays': bufferDays,
      'scrollThrottleMs': scrollThrottleDuration.inMilliseconds,
      'animationDurationMs': animationDuration.inMilliseconds,
    };
  }

  /// Creates a copy of this configuration with the given fields replaced.
  ///
  /// This is useful for creating variations of a configuration without
  /// modifying the original.
  TimelineConfiguration copyWith({
    double? dayWidth,
    double? dayMargin,
    double? datesHeight,
    double? timelineHeight,
    double? rowHeight,
    double? rowMargin,
    int? bufferDays,
    Duration? scrollThrottleDuration,
    Duration? animationDuration,
  }) {
    return TimelineConfiguration(
      dayWidth: dayWidth ?? this.dayWidth,
      dayMargin: dayMargin ?? this.dayMargin,
      datesHeight: datesHeight ?? this.datesHeight,
      timelineHeight: timelineHeight ?? this.timelineHeight,
      rowHeight: rowHeight ?? this.rowHeight,
      rowMargin: rowMargin ?? this.rowMargin,
      bufferDays: bufferDays ?? this.bufferDays,
      scrollThrottleDuration: scrollThrottleDuration ?? this.scrollThrottleDuration,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineConfiguration &&
          runtimeType == other.runtimeType &&
          dayWidth == other.dayWidth &&
          dayMargin == other.dayMargin &&
          datesHeight == other.datesHeight &&
          timelineHeight == other.timelineHeight &&
          rowHeight == other.rowHeight &&
          rowMargin == other.rowMargin &&
          bufferDays == other.bufferDays &&
          scrollThrottleDuration == other.scrollThrottleDuration &&
          animationDuration == other.animationDuration;

  @override
  int get hashCode => Object.hash(
        dayWidth,
        dayMargin,
        datesHeight,
        timelineHeight,
        rowHeight,
        rowMargin,
        bufferDays,
        scrollThrottleDuration,
        animationDuration,
      );

  @override
  String toString() {
    return 'TimelineConfiguration(\n'
        '  dayWidth: $dayWidth,\n'
        '  dayMargin: $dayMargin,\n'
        '  datesHeight: $datesHeight,\n'
        '  timelineHeight: $timelineHeight,\n'
        '  rowHeight: $rowHeight,\n'
        '  rowMargin: $rowMargin,\n'
        '  bufferDays: $bufferDays,\n'
        '  scrollThrottleDuration: $scrollThrottleDuration,\n'
        '  animationDuration: $animationDuration\n'
        ')';
  }
}
