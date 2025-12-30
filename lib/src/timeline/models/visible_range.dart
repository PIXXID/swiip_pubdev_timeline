/// A model representing a range of visible items in the timeline.
///
/// This class is used to track which items (days, stages, etc.) are currently
/// visible in the viewport, enabling lazy rendering and performance optimization.
class VisibleRange {
  /// The starting index of the visible range (inclusive).
  final int start;

  /// The ending index of the visible range (inclusive).
  final int end;

  /// Creates a [VisibleRange] with the given [start] and [end] indices.
  const VisibleRange(this.start, this.end);

  /// Checks if the given [index] is within this visible range.
  ///
  /// Returns `true` if [index] is between [start] and [end] (inclusive).
  bool contains(int index) => index >= start && index <= end;

  /// Checks if this range overlaps with the range defined by [startIndex] and [endIndex].
  ///
  /// Returns `true` if there is any overlap between the two ranges.
  /// Returns `false` if the ranges are completely separate.
  bool overlaps(int startIndex, int endIndex) => !(endIndex < start || startIndex > end);

  /// Returns the number of items in this range.
  int get length => end - start + 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisibleRange && runtimeType == other.runtimeType && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'VisibleRange($start, $end)';
}
