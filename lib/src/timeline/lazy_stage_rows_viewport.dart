import 'package:flutter/material.dart';
import 'models/timeline_controller.dart';
import 'models/visible_range.dart';
import 'optimized_stage_row.dart';

/// A viewport widget that implements lazy rendering for stage rows.
///
/// This widget only renders stage rows that are currently visible in the
/// vertical viewport plus a configurable buffer on each side. This significantly
/// improves performance when dealing with timelines that have many stage rows
/// by reducing the number of widgets that need to be built and maintained.
///
/// The widget calculates which rows are visible based on the vertical scroll
/// position and only renders those rows plus a buffer.
class LazyStageRowsViewport extends StatefulWidget {
  /// The timeline controller managing horizontal scroll state.
  final TimelineController controller;

  /// The complete list of stage rows to be rendered.
  final List<dynamic> stagesRows;

  /// Height of each row.
  final double rowHeight;

  /// Margin between rows.
  final double rowMargin;

  /// Width of each day in the timeline.
  final double dayWidth;

  /// Margin between days.
  final double dayMargin;

  /// Total number of days in the timeline.
  final int totalDays;

  /// Color scheme for the timeline.
  final Map<String, Color> colors;

  /// Whether the timeline displays a single project.
  final bool isUniqueProject;

  /// Callback for editing a stage.
  final Function(String?, String?, String?, String?, String?, double?, String?)?
      openEditStage;

  /// Callback for editing an element.
  final Function(String?, String?, String?, String?, String?, double?, String?)?
      openEditElement;

  /// The scroll controller for vertical scrolling.
  final ScrollController verticalScrollController;

  /// Height of the viewport container.
  final double viewportHeight;

  /// Number of rows to render as buffer above and below visible area.
  final int bufferRows;

  /// Creates a [LazyStageRowsViewport] with the specified configuration.
  const LazyStageRowsViewport({
    Key? key,
    required this.controller,
    required this.stagesRows,
    required this.rowHeight,
    required this.rowMargin,
    required this.dayWidth,
    required this.dayMargin,
    required this.totalDays,
    required this.colors,
    required this.isUniqueProject,
    required this.verticalScrollController,
    required this.viewportHeight,
    this.openEditStage,
    this.openEditElement,
    this.bufferRows = 2,
  }) : super(key: key);

  @override
  State<LazyStageRowsViewport> createState() => _LazyStageRowsViewportState();
}

class _LazyStageRowsViewportState extends State<LazyStageRowsViewport> {
  /// Current visible range of rows.
  VisibleRange _visibleRowRange = const VisibleRange(0, 0);

  @override
  void initState() {
    super.initState();
    // Calculate initial visible range
    _updateVisibleRowRange();

    // Listen to vertical scroll changes
    widget.verticalScrollController.addListener(_onVerticalScroll);
  }

  @override
  void dispose() {
    widget.verticalScrollController.removeListener(_onVerticalScroll);
    super.dispose();
  }

  /// Called when vertical scroll position changes.
  void _onVerticalScroll() {
    _updateVisibleRowRange();
  }

  /// Calculates and updates the visible row range based on scroll position.
  void _updateVisibleRowRange() {
    if (!mounted) return;

    final scrollOffset = widget.verticalScrollController.hasClients
        ? widget.verticalScrollController.offset
        : 0.0;

    // Calculate which rows are visible
    final rowTotalHeight = widget.rowHeight + (widget.rowMargin * 2);
    final firstVisibleRow = (scrollOffset / rowTotalHeight).floor();
    final visibleRowCount = (widget.viewportHeight / rowTotalHeight).ceil();
    final lastVisibleRow = firstVisibleRow + visibleRowCount;

    // Add buffer
    final start = (firstVisibleRow - widget.bufferRows)
        .clamp(0, widget.stagesRows.length - 1);
    final end = (lastVisibleRow + widget.bufferRows)
        .clamp(0, widget.stagesRows.length - 1);

    final newRange = VisibleRange(start, end);

    // Only update if range has changed
    if (newRange != _visibleRowRange) {
      setState(() {
        _visibleRowRange = newRange;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total height for proper layout
    final totalHeight =
        widget.stagesRows.length * (widget.rowHeight + (widget.rowMargin * 2));

    // Calculate the actual width based on timeline dimensions
    final totalWidth = widget.totalDays * widget.dayWidth;

    // Build only visible rows
    final visibleRows = <Widget>[];

    for (var i = _visibleRowRange.start;
        i <= _visibleRowRange.end && i < widget.stagesRows.length;
        i++) {
      final rowTop = i * (widget.rowHeight + (widget.rowMargin * 2));

      visibleRows.add(
        Positioned(
          top: rowTop,
          left: 0,
          right: 0,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: widget.rowMargin),
            width: widget.totalDays * (widget.dayWidth - widget.dayMargin),
            height: widget.rowHeight,
            child: OptimizedStageRow(
              colors: widget.colors,
              stagesList: widget.stagesRows[i],
              centerItemIndexNotifier: widget.controller.centerItemIndex,
              visibleRangeNotifier: widget.controller.visibleRange,
              dayWidth: widget.dayWidth,
              dayMargin: widget.dayMargin,
              height: widget.rowHeight,
              isUniqueProject: widget.isUniqueProject,
              openEditStage: widget.openEditStage,
              openEditElement: widget.openEditElement,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Stack(
        children: visibleRows,
      ),
    );
  }
}
