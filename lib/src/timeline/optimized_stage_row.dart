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
  final Function(String?, String?, String?, String?, String?, double?, String?)? openEditStage;
  final Function(String?, String?, String?, String?, String?, double?, String?)? openEditElement;

  @override
  State<OptimizedStageRow> createState() => _OptimizedStageRowState();
}

class _OptimizedStageRowState extends State<OptimizedStageRow> {
  // Cached widgets to avoid rebuilding
  late List<Widget> _cachedStageItems;
  late List<Widget> _cachedLabels;
  late List<Widget> _cachedSpacers;
  
  // Track last values to detect changes
  int? _lastCenterIndex;
  VisibleRange? _lastVisibleRange;
  
  // Current position for layout
  double _currentPosition = 0;

  @override
  void initState() {
    super.initState();
    _buildStageWidgets();
    
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
        _buildStageWidgets();
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

  /// Builds all stage widgets, spacers, and labels.
  ///
  /// This method is called during initialization and when the visible range changes.
  /// It creates cached widgets that can be reused until the next rebuild.
  void _buildStageWidgets() {
    _cachedStageItems = [];
    _cachedLabels = [];
    _cachedSpacers = [];
    _currentPosition = 0;
    
    final visibleRange = widget.visibleRangeNotifier.value;
    final centerIndex = widget.centerItemIndexNotifier.value;
    
    for (int index = 0; index < widget.stagesList.length; index++) {
      final stage = widget.stagesList[index];
      final startIndex = stage['startDateIndex'] as int;
      final endIndex = stage['endDateIndex'] as int;
      
      // Skip stages that are completely outside the visible range
      if (endIndex < visibleRange.start || startIndex > visibleRange.end) {
        continue;
      }
      
      // Calculate dimensions
      int daysWidth = endIndex - startIndex + 1;
      double itemWidth = daysWidth * (widget.dayWidth - widget.dayMargin);
      
      // Calculate spacer before this stage
      var previousItem = index > 0 ? widget.stagesList[index - 1] : null;
      double spacerWidth = 0;
      
      if (previousItem != null) {
        int daysBetweenElements = startIndex - (previousItem['endDateIndex'] as int) - 1;
        if (daysBetweenElements > 0) {
          spacerWidth = daysBetweenElements * (widget.dayWidth - widget.dayMargin);
        }
      } else {
        spacerWidth = startIndex * (widget.dayWidth - widget.dayMargin);
      }
      
      // Add spacer if needed
      if (spacerWidth > 0) {
        _cachedSpacers.add(
          Positioned(
            left: _currentPosition,
            child: SizedBox(
              width: spacerWidth,
              height: widget.height,
            ),
          ),
        );
        _currentPosition += spacerWidth;
      }
      
      // Store position for this stage
      double stageItemPosition = _currentPosition;
      
      // Build the stage item
      _cachedStageItems.add(_buildStageItem(stage, stageItemPosition, itemWidth, daysWidth));
      
      // Build label if needed
      if (_shouldShowLabel(stage, centerIndex, daysWidth)) {
        _cachedLabels.add(_buildLabel(stage, stageItemPosition));
      }
      
      // Update position for next stage
      _currentPosition += itemWidth;
    }
  }

  /// Builds a single stage item widget.
  Widget _buildStageItem(
    Map<String, dynamic> stage,
    double position,
    double itemWidth,
    int daysWidth,
  ) {
    // Determine if this is a stage or element
    bool isStage = ['milestone', 'cycle', 'sequence', 'stage'].contains(stage['type']);
    
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
        type: stage['type'] ?? stage['nat'],
        label: label,
        icon: stage['icon'],
        users: stage['users'],
        startDate: stage['sdate'],
        endDate: stage['edate'],
        progress: stage['prog'] != null ? stage['prog'].toDouble() : 0,
        prjId: stage['prj_id'],
        pname: stage['pname'],
        parentStageId: stage['prs_id'],
        isStage: isStage,
        isUniqueProject: widget.isUniqueProject,
        openEditStage: widget.openEditStage,
        openEditElement: widget.openEditElement,
      ),
    );
  }

  /// Builds a label widget for a stage.
  Widget _buildLabel(Map<String, dynamic> stage, double position) {
    bool isStage = ['milestone', 'cycle', 'sequence', 'stage'].contains(stage['type']);
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
    
    Color fontColor = ThemeData.estimateBrightnessForColor(pcolor) == Brightness.dark 
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
  bool _shouldShowLabel(Map<String, dynamic> stage, int centerIndex, int daysWidth) {
    bool isStage = ['milestone', 'cycle', 'sequence', 'stage'].contains(stage['type']);
    
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
    double currentPos = 0;
    
    for (int index = 0; index < widget.stagesList.length; index++) {
      final stage = widget.stagesList[index];
      final startIndex = stage['startDateIndex'] as int;
      final endIndex = stage['endDateIndex'] as int;
      int daysWidth = endIndex - startIndex + 1;
      double itemWidth = daysWidth * (widget.dayWidth - widget.dayMargin);
      
      // Calculate spacer
      var previousItem = index > 0 ? widget.stagesList[index - 1] : null;
      double spacerWidth = 0;
      
      if (previousItem != null) {
        int daysBetweenElements = startIndex - (previousItem['endDateIndex'] as int) - 1;
        if (daysBetweenElements > 0) {
          spacerWidth = daysBetweenElements * (widget.dayWidth - widget.dayMargin);
        }
      } else {
        spacerWidth = startIndex * (widget.dayWidth - widget.dayMargin);
      }
      
      currentPos += spacerWidth;
      double stageItemPosition = currentPos;
      
      // Add label if needed
      if (_shouldShowLabel(stage, centerIndex, daysWidth)) {
        _cachedLabels.add(_buildLabel(stage, stageItemPosition));
      }
      
      currentPos += itemWidth;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _currentPosition,
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ..._cachedSpacers,
              ..._cachedStageItems,
              ..._cachedLabels,
            ],
          ),
        ),
      ),
    );
  }
}
