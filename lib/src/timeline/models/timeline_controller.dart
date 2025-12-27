import 'dart:async';
import 'package:flutter/foundation.dart';
import 'visible_range.dart';

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
  final ValueNotifier<VisibleRange> visibleRange = ValueNotifier(const VisibleRange(0, 0));
  
  /// Width of each day item
  final double dayWidth;
  
  /// Margin between day items
  final double dayMargin;
  
  /// Total number of days in the timeline
  final int totalDays;
  
  /// Viewport width for calculating visible range
  double? _viewportWidth;
  
  /// Timer for throttling scroll updates
  Timer? _scrollThrottleTimer;
  
  /// Flag to track if controller is disposed
  bool _isDisposed = false;
  
  /// Throttle duration (~60 FPS)
  static const _scrollThrottleDuration = Duration(milliseconds: 16);
  
  /// Creates a TimelineController with the specified configuration.
  TimelineController({
    required this.dayWidth,
    required this.dayMargin,
    required this.totalDays,
    double? viewportWidth,
  }) : _viewportWidth = viewportWidth;
  
  /// Sets the viewport width for calculating visible range.
  void setViewportWidth(double width) {
    _viewportWidth = width;
    _updateVisibleRange();
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
    final newIndex = (scrollOffset.value / (dayWidth - dayMargin)).round();
    if (newIndex != centerItemIndex.value) {
      centerItemIndex.value = newIndex.clamp(0, totalDays - 1);
    }
  }
  
  /// Updates the visible range based on center index and viewport width.
  void _updateVisibleRange() {
    if (_viewportWidth == null) return;
    
    // Calculate number of visible days
    final visibleDays = (_viewportWidth! / (dayWidth - dayMargin)).ceil();
    
    // Add buffer of 5 days on each side
    const buffer = 5;
    
    // Calculate start and end indices with buffer
    final start = (centerItemIndex.value - (visibleDays ~/ 2) - buffer)
        .clamp(0, totalDays);
    final end = (centerItemIndex.value + (visibleDays ~/ 2) + buffer)
        .clamp(0, totalDays);
    
    // Update visible range if changed
    final newRange = VisibleRange(start, end);
    if (newRange != visibleRange.value) {
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
    
    super.dispose();
  }
}
