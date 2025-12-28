/// Represents the calculated scroll state
///
/// This class is immutable and contains only data computed from scroll calculations.
/// It separates the calculation of scroll values from the actual scroll actions.
class ScrollState {
  /// The index of the day that should be centered in the viewport
  final int centerDateIndex;

  /// The calculated vertical scroll offset for the target stage row
  /// Can be null if no stage is found for the current position
  final double? targetVerticalOffset;

  /// Whether auto-scroll should be enabled based on current conditions
  final bool enableAutoScroll;

  /// Whether the user is scrolling left (true) or right (false)
  final bool scrollingLeft;

  /// Creates a new immutable ScrollState
  const ScrollState({
    required this.centerDateIndex,
    required this.targetVerticalOffset,
    required this.enableAutoScroll,
    required this.scrollingLeft,
  });
}
