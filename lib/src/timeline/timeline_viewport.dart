import 'package:flutter/material.dart';

/// A viewport widget that implements lazy rendering for timeline items.
///
/// This widget only renders items that are currently visible in the viewport
/// plus a configurable buffer on each side. This significantly improves
/// performance when dealing with large timelines by reducing the number of
/// widgets that need to be built and maintained.
///
/// The widget receives visible range parameters directly and renders only
/// items within that range, ensuring minimal rebuilds.
class TimelineViewport extends StatelessWidget {
  /// Start index of the visible range (inclusive).
  final int visibleStart;

  /// End index of the visible range (exclusive).
  final int visibleEnd;

  /// Index of the center item in the viewport.
  final int centerItemIndex;

  /// The complete list of data items (e.g., days) to be rendered.
  final List<dynamic> items;

  /// Width of each item in the timeline.
  final double itemWidth;

  /// Margin between items.
  final double itemMargin;

  /// Builder function that creates a widget for a given item index.
  ///
  /// This function is called only for items within the visible range.
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Color map for styling the viewport.
  final Map<String, Color>? colors;

  /// Creates a [TimelineViewport] with the specified configuration.
  ///
  /// The [visibleStart] and [visibleEnd] define the range of items to render.
  /// The [centerItemIndex] is passed to the itemBuilder for highlighting.
  /// The [items] list contains all data to be rendered.
  /// The [itemBuilder] creates widgets for visible items.
  /// The [colors] map provides styling colors (optional).
  const TimelineViewport({
    super.key,
    required this.visibleStart,
    required this.visibleEnd,
    required this.centerItemIndex,
    required this.items,
    required this.itemWidth,
    required this.itemMargin,
    required this.itemBuilder,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    // Handle empty items list
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate total width for proper positioning
    final totalWidth = items.length * itemWidth;

    // Build only visible widgets
    final visibleWidgets = <Widget>[];

    // Ensure range is within bounds
    final safeStart = visibleStart.clamp(0, items.length);
    final safeEnd = visibleEnd.clamp(0, items.length);

    // Iterate through visible range and create positioned widgets
    // visibleEnd is inclusive, so we use <= instead of <
    for (var i = safeStart; i <= safeEnd && i < items.length; i++) {
      visibleWidgets.add(
        Positioned(
          left: i * (itemWidth - itemMargin),
          child: itemBuilder(context, i),
        ),
      );
    }

    return SizedBox(
      width: totalWidth,
      child: Container(
        decoration: BoxDecoration(color: colors!['primaryBackground']!.withValues(alpha: 0.80)),
        child: Stack(
          clipBehavior: Clip.none,
          children: visibleWidgets,
        ),
      ),
    );
  }
}
