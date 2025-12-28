import 'package:flutter/material.dart';
import 'models/timeline_controller.dart';
import 'models/visible_range.dart';

/// A viewport widget that implements lazy rendering for timeline items.
///
/// This widget only renders items that are currently visible in the viewport
/// plus a configurable buffer on each side. This significantly improves
/// performance when dealing with large timelines by reducing the number of
/// widgets that need to be built and maintained.
///
/// The widget listens to the [TimelineController]'s visibleRange and rebuilds
/// only when the visible range changes, ensuring minimal rebuilds.
class LazyTimelineViewport extends StatelessWidget {
  /// The timeline controller managing scroll state and visible range.
  final TimelineController controller;

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

  /// Creates a [LazyTimelineViewport] with the specified configuration.
  ///
  /// The [controller] manages the visible range and scroll state.
  /// The [items] list contains all data to be rendered.
  /// The [itemBuilder] creates widgets for visible items.
  const LazyTimelineViewport({
    super.key,
    required this.controller,
    required this.items,
    required this.itemWidth,
    required this.itemMargin,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VisibleRange>(
      valueListenable: controller.visibleRange,
      builder: (context, range, _) {
        // Calculate total width for proper positioning
        final totalWidth = items.length * itemWidth;

        // Build only visible widgets
        final visibleWidgets = <Widget>[];

        // Iterate through visible range and create positioned widgets
        for (var i = range.start; i <= range.end && i < items.length; i++) {
          visibleWidgets.add(
            Positioned(
              left: i * (itemWidth - itemMargin),
              child: itemBuilder(context, i),
            ),
          );
        }

        return SizedBox(
          width: totalWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: visibleWidgets,
          ),
        );
      },
    );
  }
}
