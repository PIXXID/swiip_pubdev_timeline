import 'package:flutter/material.dart';

import 'stage_item.dart';
import 'models/visible_range.dart';
// Tools
import 'package:swiip_pubdev_timeline/src/tools/tools.dart';

/// Optimized version of StageRow with conditional rebuilds.
///
/// This widget uses ValueNotifiers to listen to state changes and only rebuilds
/// when necessary. It caches stage widgets and labels to avoid unnecessary
/// reconstructions during scroll operations.
class OptimizedStageRow extends StatefulWidget {
  const OptimizedStageRow({
    super.key,
    required this.colors,
    required this.stagesList,
    required this.centerItemIndexNotifier,
    required this.visibleRangeNotifier,
    required this.dayWidth,
    required this.dayMargin,
    required this.height,
    required this.isUniqueProject,
    this.openEditStage,
    this.openEditElement,
  });

  final Map<String, Color> colors;
  final List stagesList;
  final ValueNotifier<int> centerItemIndexNotifier;
  final ValueNotifier<VisibleRange> visibleRangeNotifier;
  final double dayWidth;
  final double dayMargin;
  final double height;
  final bool isUniqueProject;
  final Function(String?, String?, String?, String?, String?, double?, String?)?
      openEditStage;
  final Function(String?, String?, String?, String?, String?, double?, String?)?
      openEditElement;

  @override
  State<OptimizedStageRow> createState() => _OptimizedStageRowState();
}

class _OptimizedStageRowState extends State<OptimizedStageRow> {
  // Cached stage items with their positions (calculated once)
  List<_StageItemData> _stageItemsData = [];

  // Cached widgets for each stage (built once, reused)
  Map<int, Widget> _cachedStageWidgets = {};

  // Cached widgets for labels
  final List<Widget> _cachedLabels = [];

  // Track last values to detect changes
  int? _lastCenterIndex;
  VisibleRange? _lastVisibleRange;

  // Total width for layout
  double _totalWidth = 0;

  @override
  void initState() {
    super.initState();
    // Calculate positions once and cache them
    _calculateStagePositions();
    _updateLabelsVisibility();

    // Listen to state changes with conditional rebuild
    widget.centerItemIndexNotifier.addListener(_onCenterIndexChanged);
    widget.visibleRangeNotifier.addListener(_onVisibleRangeChanged);
  }

  @override
  void dispose() {
    widget.centerItemIndexNotifier.removeListener(_onCenterIndexChanged);
    widget.visibleRangeNotifier.removeListener(_onVisibleRangeChanged);
    super.dispose();
  }

  /// Called when center item index changes.
  /// Only rebuilds if this row is affected by the change.
  void _onCenterIndexChanged() {
    final newIndex = widget.centerItemIndexNotifier.value;

    // Rebuild only if the center affects this row
    if (_shouldRebuildForCenterChange(newIndex)) {
      setState(() {
        _lastCenterIndex = newIndex;
        _updateLabelsVisibility();
      });
    }
  }

  /// Called when visible range changes.
  /// Only rebuilds if this row is affected by the change.
  void _onVisibleRangeChanged() {
    final newRange = widget.visibleRangeNotifier.value;

    // Rebuild only if the visible range affects this row
    if (_shouldRebuildForRangeChange(newRange)) {
      setState(() {
        _lastVisibleRange = newRange;
        // No need to recalculate positions, just trigger rebuild
      });
    }
  }

  /// Determines if the row should rebuild based on center index change.
  ///
  /// Returns true if:
  /// - The center index has actually changed
  /// - Any stage in this row contains the new center index
  bool _shouldRebuildForCenterChange(int newIndex) {
    if (_lastCenterIndex == newIndex) return false;

    // Check if any stage in this row contains the new center index
    return widget.stagesList.any((stage) =>
        stage['startDateIndex'] <= newIndex &&
        stage['endDateIndex'] >= newIndex);
  }

  /// Determines if the row should rebuild based on visible range change.
  ///
  /// Returns true if:
  /// - The visible range has actually changed
  /// - Any stage in this row overlaps with the new visible range
  bool _shouldRebuildForRangeChange(VisibleRange newRange) {
    if (_lastVisibleRange == newRange) return false;

    // Check if any stage in this row overlaps with the new visible range
    return widget.stagesList.any((stage) =>
        newRange.overlaps(stage['startDateIndex'], stage['endDateIndex']));
  }

  /// Calculates and caches the positions of all stage items.
  /// This is called ONCE during initialization and positions never change.
  void _calculateStagePositions() {
    _stageItemsData = [];
    _cachedStageWidgets = {};
    double currentPosition = 0;

    for (int index = 0; index < widget.stagesList.length; index++) {
      final stage = widget.stagesList[index];
      final startIndex = stage['startDateIndex'] as int;
      final endIndex = stage['endDateIndex'] as int;

      // Calculate dimensions
      int daysWidth = endIndex - startIndex + 1;
      double itemWidth = daysWidth * (widget.dayWidth - widget.dayMargin);

      // Calculate spacer before this stage
      var previousItem = index > 0 ? widget.stagesList[index - 1] : null;
      double spacerWidth = 0;

      if (previousItem != null) {
        int daysBetweenElements =
            startIndex - (previousItem['endDateIndex'] as int) - 1;
        if (daysBetweenElements > 0) {
          spacerWidth =
              daysBetweenElements * (widget.dayWidth - widget.dayMargin);
        }
      } else {
        spacerWidth = startIndex * (widget.dayWidth - widget.dayMargin);
      }

      // Add spacer width to position
      currentPosition += spacerWidth;

      // Store the stage data with its fixed position
      _stageItemsData.add(_StageItemData(
        stage: stage,
        position: currentPosition,
        itemWidth: itemWidth,
        daysWidth: daysWidth,
        startIndex: startIndex,
        endIndex: endIndex,
        index: index,
      ));

      // Build and cache the stage widget once
      _cachedStageWidgets[index] = _buildStageItem(
        stage,
        currentPosition,
        itemWidth,
        daysWidth,
      );

      // Update position for next stage
      currentPosition += itemWidth;
    }

    _totalWidth = currentPosition;
  }

  /// Builds a single stage item widget.
  Widget _buildStageItem(
    Map<String, dynamic> stage,
    double position,
    double itemWidth,
    int daysWidth,
  ) {
    // Determine if this is a stage or element
    bool isStage =
        ['milestone', 'cycle', 'sequence', 'stage'].contains(stage['type']);

    // Build label
    String progressLabel = (stage['prog'] != null && stage['prog'] > 0)
        ? ' (${stage['prog']}%)'
        : '';
    String label = '';
    if (isStage) {
      label = (stage['name'] != null) ? stage['name'] + progressLabel : '';
    } else {
      label = stage['pre_name'] ?? '';
    }

    // Set project color
    Map<String, Color> stageColors = Map.from(widget.colors);
    if (stage['pcolor'] != null) {
      stageColors['pcolor'] = formatStringToColor(stage['pcolor'])!;
    } else {
      stageColors['pcolor'] = Color(int.parse('ffffff', radix: 16));
    }

    // Get entity ID
    String entityId = isStage ? stage['prs_id'] : stage['pre_id'];

    return Positioned(
      left: position,
      child: StageItem(
        colors: stageColors,
        dayWidth: widget.dayWidth,
        dayMargin: widget.dayMargin,
        itemWidth: itemWidth,
        daysNumber: daysWidth,
        height: widget.height,
        entityId: entityId,
        type: stage['type'] ?? stage['nat'] ?? '',
        label: label,
        icon: stage['icon'],
        users: stage['users'],
        startDate: stage['sdate'] ?? '',
        endDate: stage['edate'] ?? '',
        progress: stage['prog'] != null ? stage['prog'].toDouble() : 0,
        prjId: stage['prj_id'] ?? '',
        pname: stage['pname'] ?? '',
        parentStageId: stage['prs_id'] ?? '',
        isStage: isStage,
        isUniqueProject: widget.isUniqueProject,
        openEditStage: widget.openEditStage,
        openEditElement: widget.openEditElement,
      ),
    );
  }

  /// Builds a label widget for a stage.
  Widget _buildLabel(Map<String, dynamic> stage, double position) {
    bool isStage =
        ['milestone', 'cycle', 'sequence', 'stage'].contains(stage['type']);
    String entityId = isStage ? stage['prs_id'] : stage['pre_id'];

    String progressLabel = (stage['prog'] != null && stage['prog'] > 0)
        ? ' (${stage['prog']}%)'
        : '';
    String label = '';
    if (isStage) {
      label = (stage['name'] != null) ? stage['name'] + progressLabel : '';
    } else {
      label = stage['pre_name'] ?? '';
    }

    // Set project color
    Color pcolor;
    if (stage['pcolor'] != null) {
      pcolor = formatStringToColor(stage['pcolor'])!;
    } else {
      pcolor = Color(int.parse('ffffff', radix: 16));
    }

    Color fontColor =
        ThemeData.estimateBrightnessForColor(pcolor) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return Positioned(
      left: position + 30,
      top: 5,
      child: GestureDetector(
        onTap: () {
          widget.openEditElement?.call(
            entityId,
            label,
            stage['type'],
            stage['sdate'],
            stage['edate'],
            stage['prog'] != null ? stage['prog'].toDouble() : 0,
            stage['prj_id'],
          );
        },
        child: SizedBox(
          child: Text(
            label,
            style: TextStyle(
              background: Paint()..color = pcolor,
              color: fontColor,
              fontWeight: FontWeight.w300,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  /// Determines if a label should be shown for a stage.
  ///
  /// Labels are shown for elements (not stages) that are:
  /// - Less than 4 days wide
  /// - Contain the center index
  bool _shouldShowLabel(
      Map<String, dynamic> stage, int centerIndex, int daysWidth) {
    bool isStage =
        ['milestone', 'cycle', 'sequence', 'stage'].contains(stage['type']);

    return !isStage &&
        daysWidth < 4 &&
        stage['startDateIndex'] <= centerIndex &&
        stage['endDateIndex'] >= centerIndex;
  }

  /// Updates only the labels visibility without rebuilding all stages.
  ///
  /// This is called when the center index changes but the visible range hasn't.
  /// It's more efficient than rebuilding all stage widgets.
  void _updateLabelsVisibility() {
    _cachedLabels.clear();

    final centerIndex = widget.centerItemIndexNotifier.value;

    for (final itemData in _stageItemsData) {
      // Add label if needed
      if (_shouldShowLabel(itemData.stage, centerIndex, itemData.daysWidth)) {
        _cachedLabels.add(_buildLabel(itemData.stage, itemData.position));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleRange = widget.visibleRangeNotifier.value;

    // Build only visible stage items based on current visible range
    // Use cached widgets instead of rebuilding them
    final visibleStageItems = <Widget>[];

    for (final itemData in _stageItemsData) {
      // Check if stage overlaps with visible range (with buffer for smooth scrolling)
      bool isVisible = !(itemData.endIndex < visibleRange.start - 2 ||
          itemData.startIndex > visibleRange.end + 2);

      if (isVisible) {
        // Use the cached widget
        final cachedWidget = _cachedStageWidgets[itemData.index];
        if (cachedWidget != null) {
          visibleStageItems.add(cachedWidget);
        }
      }
    }

    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _totalWidth,
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ...visibleStageItems,
              ..._cachedLabels,
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class to store stage item information with fixed position
class _StageItemData {
  final Map<String, dynamic> stage;
  final double position;
  final double itemWidth;
  final int daysWidth;
  final int startIndex;
  final int endIndex;
  final int index;

  _StageItemData({
    required this.stage,
    required this.position,
    required this.itemWidth,
    required this.daysWidth,
    required this.startIndex,
    required this.endIndex,
    required this.index,
  });
}
