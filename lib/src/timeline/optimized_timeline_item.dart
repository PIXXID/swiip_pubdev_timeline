import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/visible_range.dart';

/// Optimized version of TimelineItem using ValueListenableBuilder and RepaintBoundary.
///
/// This widget is optimized for performance by:
/// - Using StatelessWidget instead of StatefulWidget
/// - Using ValueListenableBuilder for selective rebuilds
/// - Wrapping content in RepaintBoundary to isolate repaints
/// - Using const constructors where possible
/// - Extracting calculation methods to reduce build complexity
/// - Using AnimatedBuilder with Transform for efficient animations
class OptimizedTimelineItem extends StatefulWidget {
  final Map<String, Color> colors;
  final int index;
  final ValueNotifier<int> centerItemIndexNotifier;
  final ValueNotifier<VisibleRange>? visibleRangeNotifier;
  final int nowIndex;
  final Map<String, dynamic> day;
  final List elements;
  final double dayWidth;
  final double dayMargin;
  final double height;
  final Function(String, double?, List<String>?, List<dynamic>, dynamic)? openDayDetail;

  const OptimizedTimelineItem({
    super.key,
    required this.colors,
    required this.index,
    required this.centerItemIndexNotifier,
    this.visibleRangeNotifier,
    required this.nowIndex,
    required this.day,
    required this.elements,
    required this.dayWidth,
    required this.dayMargin,
    required this.height,
    this.openDayDetail,
  });

  @override
  State<OptimizedTimelineItem> createState() => _OptimizedTimelineItemState();
}

class _OptimizedTimelineItemState extends State<OptimizedTimelineItem> with SingleTickerProviderStateMixin {
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  double _targetHeight = 0.0;
  bool _isVisible = false;
  bool _isInViewport = true;

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Initialize animation with current height
    final initialHeight = _calculateCompletedHeight();
    _targetHeight = initialHeight;
    _progressAnimation = Tween<double>(begin: initialHeight, end: initialHeight).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Listen to centerItemIndex changes to control animation
    widget.centerItemIndexNotifier.addListener(_onCenterIndexChanged);

    // Listen to visibleRange changes to control animation based on viewport
    widget.visibleRangeNotifier?.addListener(_onVisibleRangeChanged);

    _onCenterIndexChanged(); // Initialize visibility
    _onVisibleRangeChanged(); // Initialize viewport visibility
  }

  @override
  void dispose() {
    widget.centerItemIndexNotifier.removeListener(_onCenterIndexChanged);
    widget.visibleRangeNotifier?.removeListener(_onVisibleRangeChanged);
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _onCenterIndexChanged() {
    final centerIndex = widget.centerItemIndexNotifier.value;
    final dayTextColor = _calculateDayTextColor(centerIndex);
    final newIsVisible = dayTextColor != Colors.transparent;

    if (newIsVisible != _isVisible) {
      setState(() {
        _isVisible = newIsVisible;
      });
    }
  }

  void _onVisibleRangeChanged() {
    if (widget.visibleRangeNotifier == null) {
      _isInViewport = true;
      return;
    }

    final visibleRange = widget.visibleRangeNotifier!.value;
    final newIsInViewport = visibleRange.contains(widget.index);

    if (newIsInViewport != _isInViewport) {
      setState(() {
        _isInViewport = newIsInViewport;
      });

      // Stop animation if widget is outside viewport
      if (!_isInViewport && _progressAnimationController.isAnimating) {
        _progressAnimationController.stop();
      }
    }
  }

  @override
  void didUpdateWidget(OptimizedTimelineItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animation if day data changed
    if (oldWidget.day != widget.day) {
      // Schedule animation update after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateProgressAnimation();
        }
      });
    }
  }

  void _updateProgressAnimation() {
    // Don't animate if widget is outside viewport
    if (!_isInViewport) {
      return;
    }

    final heightCompeff = _calculateCompletedHeight();

    if (_targetHeight != heightCompeff) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: heightCompeff,
      ).animate(
        CurvedAnimation(
          parent: _progressAnimationController,
          curve: Curves.easeInOut,
        ),
      );

      _targetHeight = heightCompeff;
      _progressAnimationController.forward(from: 0.0);
    }
  }

  double _calculateCompletedHeight() {
    final heightLmax = widget.height;
    double heightCompeff = 0;

    if (widget.day['compeff'] > 0) {
      heightCompeff = (heightLmax * widget.day['compeff']) / ((widget.day['lmax'] > 0) ? widget.day['lmax'] : 1);
      if (heightCompeff >= heightLmax) {
        heightCompeff = heightLmax;
      }
    }

    return heightCompeff;
  }

  /// Calculates the day text color based on distance from center.
  Color _calculateDayTextColor(int centerIndex) {
    final idxCenter = centerIndex - widget.index;

    if (idxCenter == 0) {
      return widget.colors['primaryText']!;
    } else if ((idxCenter >= 1 && idxCenter < 4) || (idxCenter <= -1 && idxCenter > -4)) {
      return widget.colors['secondaryText']!;
    } else if ((idxCenter >= 4 && idxCenter < 6) || (idxCenter <= -4 && idxCenter > -6)) {
      return widget.colors['accent1']!;
    } else {
      return Colors.transparent;
    }
  }

  /// Builds the day content with bars and indicators.
  Widget _buildDayContent(Color dayTextColor) {
    final DateTime date = widget.day['date'];
    Color busyColor = widget.colors['secondaryText'] ?? Colors.grey;
    Color completeColor = widget.colors['secondaryText'] ?? Colors.white;

    // Hauteur MAX
    final double heightLmax = widget.height;

    // On calcule la hauteur de chaque barre
    double heightCapeff = 0, heightBuseff = 0, heightCompeff = 0;
    bool dayIsCompleted = false;

    if (widget.day['capeff'] > 0) {
      heightCapeff = (heightLmax * widget.day['capeff']) / ((widget.day['lmax'] > 0) ? widget.day['lmax'] : 1);
    }
    if (widget.day['buseff'] > 0) {
      heightBuseff = (heightLmax * widget.day['buseff']) / ((widget.day['lmax'] > 0) ? widget.day['lmax'] : 1);
    }
    if (widget.day['compeff'] > 0) {
      heightCompeff = (heightLmax * widget.day['compeff']) / ((widget.day['lmax'] > 0) ? widget.day['lmax'] : 1);
      if (heightCompeff >= heightLmax) {
        heightCompeff = heightLmax;
        dayIsCompleted = true;
      }
      // Met à jour la couleur si progression
      completeColor = widget.colors['primary']!;
    }

    // Réduit la hauteur en cas de dépassement excessif
    if (heightBuseff > heightCapeff) {
      heightBuseff = heightCapeff - 2;
    }

    // Border radius
    const BorderRadius borderRadius = BorderRadius.only(
      topLeft: Radius.circular(4),
      topRight: Radius.circular(4),
    );

    // Indicateurs de capacité et charges
    final dayIndicators = {
      'capacity': widget.day['capeff'],
      'busy': widget.day['buseff'],
      'completed': widget.day['compeff']
    };

    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        // Call back lors du clic
        onTap: () {
          // On calcule la progression du jour pour le renvoyer en callback
          double dayProgress = 0;
          if (widget.day['buseff'] != null && widget.day['buseff'] > 0) {
            dayProgress = 100 * widget.day['compeff'] / widget.day['buseff'];
          }

          // Liste des éléments présents sur la journée
          final elementsDay = widget.elements
              .where(
                (e) => e['date'] == DateFormat('yyyy-MM-dd').format(widget.day['date']),
              )
              .toList();

          // Callback de la fonction d'ouverture du jour
          widget.openDayDetail?.call(
            DateFormat('yyyy-MM-dd').format(date),
            dayProgress,
            (widget.day['preIds'] as List<dynamic>).cast<String>(),
            elementsDay,
            dayIndicators,
          );
        },
        child: SizedBox(
          width: widget.dayWidth - widget.dayMargin,
          height: widget.height,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.10),
            ),
            child: Column(
              children: <Widget>[
                // Alertes
                if (widget.index == widget.nowIndex)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, bottom: 5),
                    child: Icon(
                      Icons.circle_outlined,
                      size: 12,
                      color: widget.colors['primaryText'],
                    ),
                  )
                else if (widget.day['alertLevel'] != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, bottom: 5),
                    child: Icon(
                      Icons.circle_rounded,
                      size: 12,
                      color: widget.day['alertLevel'] == 1
                          ? widget.colors['warning']
                          : (widget.day['alertLevel'] == 2 ? widget.colors['error'] : Colors.transparent),
                    ),
                  )
                else
                  const SizedBox(height: 18),
                // Barre avec données
                Expanded(
                  child: SizedBox(
                    height: heightLmax,
                    child: Stack(
                      children: [
                        // Barre de capacité
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            margin: EdgeInsets.only(
                              left: widget.dayMargin / 2,
                              right: widget.dayMargin / 2,
                              bottom: widget.dayMargin / 3,
                            ),
                            width: widget.dayWidth - widget.dayMargin - 15,
                            height: (heightCapeff > 0) ? heightCapeff - 2 : heightLmax,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: (widget.index == widget.centerItemIndexNotifier.value)
                                      ? widget.colors['secondaryText']!
                                      : const Color(0x00000000),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Center(
                              child:
                                  // Icon soleil si aucune capacité
                                  (heightCapeff == 0 && heightBuseff == 0 && heightCompeff == 0)
                                      ? Icon(
                                          Icons.stop_circle,
                                          color: widget.colors['secondaryBackground'],
                                          size: 14,
                                        )
                                      : null,
                            ),
                          ),
                        ),
                        // Barre de travail affecté (busy)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            margin: EdgeInsets.only(
                              left: widget.dayMargin / 2,
                              right: widget.dayMargin / 2,
                              bottom: widget.dayMargin / 3,
                            ),
                            width: widget.dayWidth - widget.dayMargin - 16,
                            // On affiche 1 pixel pour marquer une journée travaillée
                            height: (heightBuseff <= 0) ? 0.5 : heightBuseff,
                            decoration: BoxDecoration(
                              borderRadius: borderRadius,
                              color: busyColor,
                            ),
                          ),
                        ),
                        // Barre de travail terminé - Using AnimatedBuilder with Transform
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                final animatedHeight = _isVisible ? _progressAnimation.value : 0.0;

                                return Transform.translate(
                                  offset: Offset(0, heightLmax - animatedHeight),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      left: widget.dayMargin / 2,
                                      right: widget.dayMargin / 2,
                                      bottom: widget.dayMargin / 3,
                                    ),
                                    width: widget.dayWidth - widget.dayMargin - 16,
                                    height: animatedHeight,
                                    decoration: BoxDecoration(
                                      borderRadius: borderRadius,
                                      color: completeColor,
                                    ),
                                    child: (dayIsCompleted && animatedHeight > 0)
                                        ? Center(
                                            child: Icon(
                                              Icons.check,
                                              color: widget.colors['info'],
                                              size: 16,
                                            ),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<int>(
        valueListenable: widget.centerItemIndexNotifier,
        builder: (context, centerIndex, child) {
          // Calculate the day text color based on distance from center
          final dayTextColor = _calculateDayTextColor(centerIndex);

          // Build the day content with the calculated color
          return _buildDayContent(dayTextColor);
        },
      ),
    );
  }
}
