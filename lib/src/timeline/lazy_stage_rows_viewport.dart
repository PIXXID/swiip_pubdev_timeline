import 'package:flutter/material.dart';
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
  /// Start index of the visible horizontal range (inclusive).
  final int visibleStart;

  /// End index of the visible horizontal range (exclusive).
  final int visibleEnd;

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
  final Function(String?, String?, String?, String?, String?, double?, String?)? openEditStage;

  /// Callback for editing an element.
  final Function(String?, String?, String?, String?, String?, double?, String?)? openEditElement;

  /// The scroll controller for vertical scrolling.
  final ScrollController verticalScrollController;

  /// Height of the viewport container.
  final double viewportHeight;

  /// Number of rows to render as buffer above and below visible area.
  final int bufferRows;

  /// Creates a [LazyStageRowsViewport] with the specified configuration.
  const LazyStageRowsViewport({
    super.key,
    required this.visibleStart,
    required this.visibleEnd,
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
  });

  @override
  State<LazyStageRowsViewport> createState() => _LazyStageRowsViewportState();
}

class _LazyStageRowsViewportState extends State<LazyStageRowsViewport> {
  /// Current visible range of rows (vertical).
  VisibleRange _visibleRowRange = const VisibleRange(0, 0);

  /// ValueNotifier for horizontal visible range (for OptimizedStageRow compatibility).
  late final ValueNotifier<VisibleRange> _visibleRangeNotifier;

  /// ValueNotifier for center item index (for OptimizedStageRow compatibility).
  /// Note: centerItemIndex is not provided to LazyStageRowsViewport, so we use 0 as default.
  late final ValueNotifier<int> _centerItemIndexNotifier;

  @override
  void initState() {
    super.initState();

    // Initialize ValueNotifiers with current widget values
    _visibleRangeNotifier = ValueNotifier<VisibleRange>(
      VisibleRange(widget.visibleStart, widget.visibleEnd),
    );
    _centerItemIndexNotifier = ValueNotifier<int>(0);

    // Calculate initial visible range
    _updateVisibleRowRange();

    // Listen to vertical scroll changes
    widget.verticalScrollController.addListener(_onVerticalScroll);
  }

  @override
  void didUpdateWidget(LazyStageRowsViewport oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update ValueNotifiers when widget parameters change
    if (oldWidget.visibleStart != widget.visibleStart || oldWidget.visibleEnd != widget.visibleEnd) {
      _visibleRangeNotifier.value = VisibleRange(widget.visibleStart, widget.visibleEnd);
    }
  }

  @override
  void dispose() {
    widget.verticalScrollController.removeListener(_onVerticalScroll);
    _visibleRangeNotifier.dispose();
    _centerItemIndexNotifier.dispose();
    super.dispose();
  }

  /// Called when vertical scroll position changes.
  void _onVerticalScroll() {
    _updateVisibleRowRange();
  }

  /// Calculates and updates the visible row range based on scroll position.
  void _updateVisibleRowRange() {
    if (!mounted) return;

    // Handle empty stage rows
    if (widget.stagesRows.isEmpty) {
      final emptyRange = const VisibleRange(0, 0);
      if (emptyRange != _visibleRowRange) {
        setState(() {
          _visibleRowRange = emptyRange;
        });
      }
      return;
    }

    final scrollOffset = widget.verticalScrollController.hasClients ? widget.verticalScrollController.offset : 0.0;

    // Calculate which rows are visible
    final rowTotalHeight = widget.rowHeight + (widget.rowMargin * 2);
    final firstVisibleRow = (scrollOffset / rowTotalHeight).floor();
    final visibleRowCount = (widget.viewportHeight / rowTotalHeight).ceil();
    final lastVisibleRow = firstVisibleRow + visibleRowCount;

    // Add buffer
    final start = (firstVisibleRow - widget.bufferRows).clamp(0, widget.stagesRows.length);
    final end = (lastVisibleRow + widget.bufferRows).clamp(0, widget.stagesRows.length);

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
    final totalHeight = widget.stagesRows.length * (widget.rowHeight + (widget.rowMargin * 2));

    // Calculate the actual width based on timeline dimensions
    final totalWidth = widget.totalDays * widget.dayWidth;

    // Build only visible rows
    final visibleRows = <Widget>[];

    for (var i = _visibleRowRange.start; i <= _visibleRowRange.end && i < widget.stagesRows.length; i++) {
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
              centerItemIndexNotifier: _centerItemIndexNotifier,
              visibleRangeNotifier: _visibleRangeNotifier,
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
