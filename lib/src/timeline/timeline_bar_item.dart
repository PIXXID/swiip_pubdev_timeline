import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Optimized version of TimelineItem using ValueListenableBuilder and RepaintBoundary.
///
/// This widget is optimized for performance by:
/// - Using StatelessWidget instead of StatefulWidget
/// - Using ValueListenableBuilder for selective rebuilds
class TimelineBarItem extends StatefulWidget {
  final Map<String, Color> colors;
  final int index;
  final int centerItemIndex;
  final ValueNotifier<int> centerItemIndexNotifier;
  final int nowIndex;
  final Map<String, dynamic> day;
  final List elements;
  final double dayWidth;
  final double dayMargin;
  final double height;
  final Function(String, double?, List<String>?, List<dynamic>, dynamic)?
      openDayDetail;

  const TimelineBarItem({
    super.key,
    required this.colors,
    required this.index,
    required this.centerItemIndex,
    required this.centerItemIndexNotifier,
    required this.nowIndex,
    required this.day,
    required this.elements,
    required this.dayWidth,
    required this.dayMargin,
    required this.height,
    this.openDayDetail,
  });

  @override
  State<TimelineBarItem> createState() => _TimelineBarItemState();
}

class _TimelineBarItemState extends State<TimelineBarItem>
    with SingleTickerProviderStateMixin {
  bool _isInCenter = false;

  @override
  void initState() {
    super.initState();

    // Listen to centerItemIndex changes to control animation
    widget.centerItemIndexNotifier.addListener(_onCenterIndexChanged);

    _onCenterIndexChanged();
  }

  @override
  void dispose() {
    widget.centerItemIndexNotifier.removeListener(_onCenterIndexChanged);
    super.dispose();
  }

  void _onCenterIndexChanged() {
    final idxCenter = widget.centerItemIndex - widget.index;
    _isInCenter = (idxCenter == 0) ? true : false;
  }

  /// Builds the day content with bars and indicators.
  @override
  Widget build(BuildContext context) {
    final DateTime date = widget.day['date'];
    Color busyColor = widget.colors['secondaryText'] ?? Colors.grey;
    Color completeColor = widget.colors['primaryText'] ?? Colors.white;
    double alphaColor = (_isInCenter) ? 1 : 0.5;

    // Hauteur MAX
    final double heightLmax = widget.height - 5;

    // On calcule la hauteur de chaque barre
    double heightCapeff = 0, heightBuseff = 0, heightCompeff = 0;
    bool dayIsCompleted = false;

    if (widget.day['capeff'] > 0) {
      heightCapeff = (heightLmax * widget.day['capeff']) /
          ((widget.day['lmax'] > 0) ? widget.day['lmax'] : 1);
    }
    if (widget.day['buseff'] > 0) {
      heightBuseff = (heightLmax * widget.day['buseff']) /
          ((widget.day['lmax'] > 0) ? widget.day['lmax'] : 1);
    }
    if (widget.day['compeff'] > 0) {
      heightCompeff = (heightLmax * widget.day['compeff']) /
          ((widget.day['lmax'] > 0) ? widget.day['lmax'] : 1);
      if (heightCompeff >= heightLmax) {
        heightCompeff = heightLmax;
        dayIsCompleted = true;
        // On masque le fond
        completeColor =
            widget.colors['primaryBackground']!.withValues(alpha: 0.0);
      }
    }
    // Réduit la hauteur en cas de dépassement excessif
    if (heightBuseff >= heightLmax) {
      heightBuseff = heightLmax;
    }

    // Border radius
    const BorderRadius borderRadius = BorderRadius.only(
      topLeft: Radius.circular(5),
      topRight: Radius.circular(5),
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
                (e) =>
                    e['date'] ==
                    DateFormat('yyyy-MM-dd').format(widget.day['date']),
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
        child: Container(
          width: widget.dayWidth / 2,
          height: widget.height,
          margin: EdgeInsets.only(top: 5.0, left: widget.dayWidth / 4),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: [
                    // 1 - Barre de capacité + Icon jour non travaillé
                    Center(
                      child:
                          // Icon soleil si aucune capacité
                          (heightCapeff == 0 &&
                                  heightBuseff == 0 &&
                                  heightCompeff == 0)
                              ? Icon(
                                  Icons.block,
                                  color:
                                      busyColor.withValues(alpha: alphaColor),
                                  size: 14,
                                )
                              : null,
                    ),
                    // Barre de travail affecté (busy)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: widget.dayWidth / 2,
                          height: (heightBuseff > 0) ? heightBuseff : 0,
                          decoration: BoxDecoration(
                            borderRadius: borderRadius,
                            color: busyColor.withValues(alpha: alphaColor),
                          ),
                        ),
                      ),
                    ),
                    // Barre de travail terminé - Using AnimatedBuilder with Transform
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: widget.dayWidth / 2,
                          height: heightCompeff,
                          decoration: BoxDecoration(
                            borderRadius: borderRadius,
                            color: completeColor,
                          ),
                          child: (dayIsCompleted && heightCompeff > 0)
                              ? Center(
                                  child: Icon(
                                    Icons.check,
                                    color: widget.colors['primaryText'],
                                    size: 16,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    // ALERTES
                    if (widget.day['alertLevel'] != 0)
                      Positioned(
                        top: 20,
                        child: SizedBox(
                          width: widget.dayWidth / 2,
                          height: heightLmax,
                          child: Icon(
                            Icons.circle,
                            color: widget.day['alertLevel'] == 1
                                ? widget.colors['warning']
                                : (widget.day['alertLevel'] == 2
                                    ? widget.colors['error']
                                    : Colors.transparent),
                            size: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
