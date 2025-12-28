import 'dart:async';
import 'package:flutter/foundation.dart';
import 'visible_range.dart';
import '../scroll_calculations.dart';

/// Controller for managing timeline state with granular notifications.
///
/// This controller manages the scroll state, center item index, and visible range
/// of the timeline using ValueNotifiers for localized updates. It implements
/// throttling to prevent excessive calculations during scroll operations.
class TimelineController extends ChangeNotifier {
  /// Current scroll offset
  final ValueNotifier<double> scrollOffset = ValueNotifier(0.0);

  /// Index of the item at the center of the viewport
  final ValueNotifier<int> centerItemIndex = ValueNotifier(0);

  /// Range of visible items (with buffer)
  final ValueNotifier<VisibleRange> visibleRange =
      ValueNotifier(const VisibleRange(0, 0));

  /// Loading state for long-running operations
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  /// Viewport width as a ValueNotifier
  final ValueNotifier<double> viewportWidth = ValueNotifier(0.0);

  /// Width of each day item
  final double dayWidth;

  /// Margin between day items
  final double dayMargin;

  /// Total number of days in the timeline
  final int totalDays;

  /// Number of buffer days to render outside the visible viewport
  final int bufferDays;

  /// Viewport width for calculating visible range
  double? _viewportWidth;

  /// First element margin for centering calculations
  double? _firstElementMargin;

  /// Timer for throttling scroll updates
  Timer? _scrollThrottleTimer;

  /// Flag to track if controller is disposed
  bool _isDisposed = false;

  /// Throttle duration for scroll updates
  final Duration _scrollThrottleDuration;

  /// Creates a TimelineController with the specified configuration.
  TimelineController({
    required this.dayWidth,
    required this.dayMargin,
    required this.totalDays,
    double? viewportWidth,
    Duration? scrollThrottleDuration,
    int? bufferDays,
  })  : _viewportWidth = viewportWidth,
        _scrollThrottleDuration =
            scrollThrottleDuration ?? const Duration(milliseconds: 16),
        bufferDays = bufferDays ?? 5 {
    // Initialize viewportWidth ValueNotifier
    this.viewportWidth.value = viewportWidth ?? 0.0;
    debugPrint(
        '🎬 TimelineController initialized: viewportWidth=${viewportWidth ?? 0.0}, totalDays=$totalDays, bufferDays=${bufferDays ?? 5}');

    // Initialize visible range if viewport width is available
    if (viewportWidth != null && viewportWidth > 0) {
      _updateVisibleRange();
    }
  }

  /// Sets the viewport width for calculating visible range.
  void setViewportWidth(double width) {
    debugPrint(
        '📐 setViewportWidth called: $width (previous: $_viewportWidth)');
    _viewportWidth = width;
    viewportWidth.value = width;
    // Recalculate firstElementMargin when viewport width changes
    _firstElementMargin = (width - (dayWidth - dayMargin)) / 2;
    _updateVisibleRange();
  }

  /// Updates the viewport width (alias for setViewportWidth).
  void updateViewportWidth(double width) {
    setViewportWidth(width);
  }

  /// Updates the scroll offset with throttling.
  ///
  /// This method throttles updates to approximately 60 FPS to prevent
  /// excessive calculations during scroll operations.
  void updateScrollOffset(double offset) {
    // Don't update if disposed
    if (_isDisposed) return;

    // Cancel existing timer if active
    if (_scrollThrottleTimer?.isActive ?? false) return;

    // Schedule throttled update
    _scrollThrottleTimer = Timer(_scrollThrottleDuration, () {
      // Check again if disposed before updating
      if (_isDisposed) return;

      scrollOffset.value = offset;
      _updateCenterItemIndex();
      _updateVisibleRange();
    });
  }

  /// Updates the center item index based on current scroll offset.
  void _updateCenterItemIndex() {
    // Handle empty timeline
    if (totalDays == 0) {
      if (centerItemIndex.value != 0) {
        centerItemIndex.value = 0;
      }
      return;
    }

    // Use the pure calculation function
    final newIndex = calculateCenterDateIndex(
      scrollOffset: scrollOffset.value,
      viewportWidth: _viewportWidth ?? 0.0,
      dayWidth: dayWidth,
      dayMargin: dayMargin,
      totalDays: totalDays,
    );

    if (newIndex != centerItemIndex.value) {
      centerItemIndex.value = newIndex;
    }
  }

  /// Updates the visible range based on center index and viewport width.
  void _updateVisibleRange() {
    if (_viewportWidth == null || _viewportWidth == 0) {
      debugPrint('⚠️ VisibleRange: viewportWidth is null or 0');
      return;
    }

    // Calculate number of visible days
    final visibleDays = (_viewportWidth! / (dayWidth - dayMargin)).ceil();

    // Use configured buffer days
    final buffer = bufferDays;

    // Calculate start and end indices with buffer
    final start = (centerItemIndex.value - (visibleDays ~/ 2) - buffer)
        .clamp(0, totalDays);
    final end = (centerItemIndex.value + (visibleDays ~/ 2) + buffer)
        .clamp(0, totalDays);

    // Update visible range if changed
    final newRange = VisibleRange(start, end);
    if (newRange != visibleRange.value) {
      debugPrint(
          '📍 VisibleRange updated: $start to $end (visibleDays=$visibleDays, buffer=$buffer, viewportWidth=$_viewportWidth, centerIndex=${centerItemIndex.value})');
      visibleRange.value = newRange;
    }
  }

  @override
  void dispose() {
    // Mark as disposed first
    _isDisposed = true;

    // Cancel throttle timer
    _scrollThrottleTimer?.cancel();

    // Dispose ValueNotifiers
    scrollOffset.dispose();
    centerItemIndex.dispose();
    visibleRange.dispose();
    isLoading.dispose();
    viewportWidth.dispose();

    super.dispose();
  }
}
