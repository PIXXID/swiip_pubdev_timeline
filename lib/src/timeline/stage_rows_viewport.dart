import 'package:flutter/material.dart';
import 'models/visible_range.dart';
import 'optimized_stage_row.dart';

/// This widget renders stage rows
class StageRowsViewport extends StatefulWidget {
  /// Start index of the visible horizontal range (inclusive).
  final int visibleStart;

  /// End index of the visible horizontal range (exclusive).
  final int visibleEnd;

  /// Center item index for label visibility calculations.
  final int centerItemIndex;

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

  /// Height of the viewport container.
  final double viewportHeight;
  final double viewportWidth;

  /// Number of rows to render as buffer above and below visible area.
  final int bufferRows;

  /// Creates a [StageRowsViewport] with the specified configuration.
  const StageRowsViewport({
    super.key,
    required this.visibleStart,
    required this.visibleEnd,
    required this.centerItemIndex,
    required this.stagesRows,
    required this.rowHeight,
    required this.rowMargin,
    required this.dayWidth,
    required this.dayMargin,
    required this.totalDays,
    required this.colors,
    required this.isUniqueProject,
    required this.viewportWidth,
    required this.viewportHeight,
    this.openEditStage,
    this.openEditElement,
    this.bufferRows = 2,
  });

  @override
  State<StageRowsViewport> createState() => _StageRowsViewportState();
}

class _StageRowsViewportState extends State<StageRowsViewport> {
  /// ValueNotifier for horizontal visible range (for OptimizedStageRow compatibility).
  late final ValueNotifier<VisibleRange> _visibleRangeNotifier;

  /// ValueNotifier for center item index (for OptimizedStageRow compatibility).
  /// Note: centerItemIndex is not provided to StageRowsViewport, so we use 0 as default.
  late final ValueNotifier<int> _centerItemIndexNotifier;

  @override
  void initState() {
    super.initState();

    // Initialize ValueNotifiers with current widget values
    _visibleRangeNotifier = ValueNotifier<VisibleRange>(
      VisibleRange(widget.visibleStart, widget.visibleEnd),
    );
    _centerItemIndexNotifier = ValueNotifier<int>(widget.centerItemIndex);
  }

  @override
  void didUpdateWidget(StageRowsViewport oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update ValueNotifiers when widget parameters change
    if (oldWidget.visibleStart != widget.visibleStart || oldWidget.visibleEnd != widget.visibleEnd) {
      _visibleRangeNotifier.value = VisibleRange(widget.visibleStart, widget.visibleEnd);
    }

    // Update center item index notifier when it changes
    if (oldWidget.centerItemIndex != widget.centerItemIndex) {
      _centerItemIndexNotifier.value = widget.centerItemIndex;
    }
  }

  @override
  void dispose() {
    _visibleRangeNotifier.dispose();
    _centerItemIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total height for proper layout
    final totalHeight = widget.stagesRows.length * (widget.rowHeight + (widget.rowMargin * 2));

    // Calculate the actual width based on timeline dimensions
    final totalWidth = widget.totalDays * widget.dayWidth;

    // Build only visible rows
    final visibleRows = <Widget>[];

    for (var i = 0; i < widget.stagesRows.length; i++) {
      final rowTop = i * (widget.rowHeight + (widget.rowMargin * 2));

      visibleRows.add(
        Positioned(
          top: rowTop,
          left: 0,
          right: 0,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: widget.rowMargin),
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
