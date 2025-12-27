import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Optimized version of TimelineItem using ValueListenableBuilder and RepaintBoundary.
/// 
/// This widget is optimized for performance by:
/// - Using StatelessWidget instead of StatefulWidget
/// - Using ValueListenableBuilder for selective rebuilds
/// - Wrapping content in RepaintBoundary to isolate repaints
/// - Using const constructors where possible
/// - Extracting calculation methods to reduce build complexity
class OptimizedTimelineItem extends StatelessWidget {
  final Map<String, Color> colors;
  final int index;
  final ValueNotifier<int> centerItemIndexNotifier;
  final int nowIndex;
  final Map<String, dynamic> day;
  final List elements;
  final double dayWidth;
  final double dayMargin;
  final double height;
  final Function(String, double?, List<String>?, List<dynamic>, dynamic)?
      openDayDetail;

  const OptimizedTimelineItem({
    super.key,
    required this.colors,
    required this.index,
    required this.centerItemIndexNotifier,
    required this.nowIndex,
    required this.day,
    required this.elements,
    required this.dayWidth,
    required this.dayMargin,
    required this.height,
    this.openDayDetail,
  });

  /// Calculates the day text color based on distance from center.
  Color _calculateDayTextColor(int centerIndex) {
    final idxCenter = centerIndex - index;

    if (idxCenter == 0) {
      return colors['primaryText']!;
    } else if ((idxCenter >= 1 && idxCenter < 4) ||
        (idxCenter <= -1 && idxCenter > -4)) {
      return colors['secondaryText']!;
    } else if ((idxCenter >= 4 && idxCenter < 6) ||
        (idxCenter <= -4 && idxCenter > -6)) {
      return colors['accent1']!;
    } else {
      return Colors.transparent;
    }
  }

  /// Builds the day content with bars and indicators.
  Widget _buildDayContent(Color dayTextColor) {
    final DateTime date = day['date'];
    Color busyColor = colors['secondaryText'] ?? Colors.grey;
    Color completeColor = colors['secondaryText'] ?? Colors.white;
    const double margin = 0.0; // Use dayMargin from widget

    // Hauteur MAX
    final double heightLmax = height;

    // On calcule la hauteur de chaque barre
    double heightCapeff = 0, heightBuseff = 0, heightCompeff = 0;
    bool dayIsCompleted = false;
    
    if (day['capeff'] > 0) {
      heightCapeff =
          (heightLmax * day['capeff']) / ((day['lmax'] > 0) ? day['lmax'] : 1);
    }
    if (day['buseff'] > 0) {
      heightBuseff =
          (heightLmax * day['buseff']) / ((day['lmax'] > 0) ? day['lmax'] : 1);
    }
    if (day['compeff'] > 0) {
      heightCompeff =
          (heightLmax * day['compeff']) / ((day['lmax'] > 0) ? day['lmax'] : 1);
      if (heightCompeff >= heightLmax) {
        heightCompeff = heightLmax;
        dayIsCompleted = true;
      }
      // Met à jour la couleur si progression
      completeColor = colors['primary']!;
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
      'capacity': day['capeff'],
      'busy': day['buseff'],
      'completed': day['compeff']
    };

    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        // Call back lors du clic
        onTap: () {
          // On calcule la progression du jour pour le renvoyer en callback
          double dayProgress = 0;
          if (day['buseff'] != null && day['buseff'] > 0) {
            dayProgress = 100 * day['compeff'] / day['buseff'];
          }

          // Liste des éléments présents sur la journée
          final elementsDay = elements
              .where(
                (e) =>
                    e['date'] == DateFormat('yyyy-MM-dd').format(day['date']),
              )
              .toList();

          // Callback de la fonction d'ouverture du jour
          openDayDetail?.call(
            DateFormat('yyyy-MM-dd').format(date),
            dayProgress,
            (day['preIds'] as List<dynamic>).cast<String>(),
            elementsDay,
            dayIndicators,
          );
        },
        child: SizedBox(
          width: dayWidth - dayMargin,
          height: height,
          child: Column(
            children: <Widget>[
              // Alertes
              if (index == nowIndex)
                Padding(
                  padding: const EdgeInsets.only(top: 3, bottom: 5),
                  child: Icon(
                    Icons.circle_outlined,
                    size: 12,
                    color: colors['primaryText'],
                  ),
                )
              else if (day['alertLevel'] != 0)
                Padding(
                  padding: const EdgeInsets.only(top: 3, bottom: 5),
                  child: Icon(
                    Icons.circle_rounded,
                    size: 12,
                    color: day['alertLevel'] == 1
                        ? colors['warning']
                        : (day['alertLevel'] == 2
                            ? colors['error']
                            : Colors.transparent),
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
                          left: dayMargin / 2,
                          right: dayMargin / 2,
                          bottom: dayMargin / 3,
                        ),
                        width: dayWidth - dayMargin - 15,
                        height: (heightCapeff > 0) ? heightCapeff - 2 : heightLmax,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: (index == centerItemIndexNotifier.value)
                                  ? colors['secondaryText']!
                                  : const Color(0x00000000),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Center(
                          child:
                              // Icon soleil si aucune capacité
                              (heightCapeff == 0 &&
                                      heightBuseff == 0 &&
                                      heightCompeff == 0)
                                  ? Icon(
                                      Icons.sunny,
                                      color: colors['secondaryBackground'],
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
                          left: dayMargin / 2,
                          right: dayMargin / 2,
                          bottom: dayMargin / 3,
                        ),
                        width: dayWidth - dayMargin - 16,
                        // On affiche 1 pixel pour marquer une journée travaillée
                        height: (heightBuseff <= 0) ? 0.5 : heightBuseff,
                        decoration: BoxDecoration(
                          borderRadius: borderRadius,
                          color: busyColor,
                        ),
                      ),
                    ),
                    // Barre de travail terminé
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: (dayTextColor != Colors.transparent)
                            ? heightCompeff
                            : 0,
                        child: Container(
                          margin: EdgeInsets.only(
                            left: dayMargin / 2,
                            right: dayMargin / 2,
                            bottom: dayMargin / 3,
                          ),
                          width: dayWidth - dayMargin - 16,
                          decoration: BoxDecoration(
                            borderRadius: borderRadius,
                            color: completeColor,
                          ),
                          child: (dayIsCompleted)
                              ? Center(
                                  child: Icon(
                                    Icons.check,
                                    color: colors['info'],
                                    size: 16,
                                  ),
                                )
                              : null,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<int>(
        valueListenable: centerItemIndexNotifier,
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
