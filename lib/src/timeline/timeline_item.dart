import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimelineItem extends StatefulWidget {
  final Map<String, Color> colors;
  final int index;
  final int centerItemIndex;
  final int nowIndex;
  final List days;
  final List elements;
  final double dayWidth;
  final double dayMargin;
  final double height;
  final Function(String, double?, List<String>?, List<dynamic>, dynamic)?
      openDayDetail;

  const TimelineItem(
      {super.key,
      required this.colors,
      required this.index,
      required this.centerItemIndex,
      required this.nowIndex,
      required this.days,
      required this.elements,
      required this.dayWidth,
      required this.dayMargin,
      required this.height,
      required this.openDayDetail});

  @override
  State<TimelineItem> createState() => _BouncingTimelineItem();
}

class _BouncingTimelineItem extends State<TimelineItem>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    dynamic day = widget.days[widget.index];
    dynamic colors = widget.colors;
    double margin = widget.dayMargin;

    final DateTime date = day['date'];
    Color busyColor = colors['secondaryText'] ?? Colors.grey;
    Color completeColor = colors['secondaryText'] ?? Colors.white;
    Color dayTextColor = colors['primaryText'] ?? Colors.white;

    // Hauteur MAX
    double heightLmax = widget.height - 90;

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
      completeColor = (colors['primary'])!;
    }

    // Réduit la hauteur en cas de dépassement exessif
    if (heightBuseff > heightCapeff) {
      heightBuseff = heightCapeff - 2;
    }

    // Gestion de l'affichage des dates en fonction de la la date au centre.
    int idxCenter = widget.centerItemIndex - widget.index;
    if (idxCenter == 0) {
      dayTextColor = colors['primaryText']!;
    } else if ((idxCenter >= 1 && idxCenter < 4) ||
        (idxCenter <= -1 && idxCenter > -4)) {
      dayTextColor = colors['secondaryText']!;
    } else if ((idxCenter >= 4 && idxCenter < 6) ||
        (idxCenter <= -4 && idxCenter > -6)) {
      dayTextColor = colors['accent1']!;
    } else {
      dayTextColor = Colors.transparent;
    }

    // Border radius
    BorderRadius borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(4), topRight: Radius.circular(4));

    // Indicateurs de capacité et charges
    dynamic dayIndicators = {
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
              if (day != null && day['buseff'] != null && day['buseff'] > 0) {
                dayProgress = 100 * day['compeff'] / day['buseff'];
              }

              // Lite des élements présent sur la journée
              var elementsDay = widget.elements
                  .where(
                    (e) =>
                        e['date'] ==
                        DateFormat('yyyy-MM-dd').format(day['date']),
                  )
                  .toList();

              // Callback de la fonction d'ouverture du jour
              widget.openDayDetail?.call(
                  DateFormat('yyyy-MM-dd').format(date),
                  dayProgress,
                  (day['preIds'] as List<dynamic>).cast<String>(),
                  elementsDay,
                  dayIndicators);
            },
            child: SizedBox(
                width: widget.dayWidth - margin,
                height: widget.height,
                child: Column(
                  children: <Widget>[
                    // Alertes
                    if (widget.index == widget.nowIndex)
                      Padding(
                          padding: const EdgeInsets.only(top: 3, bottom: 5),
                          child: Icon(
                            Icons.circle_outlined,
                            size: 12,
                            color: colors['primaryText'],
                          ))
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
                          ))
                    else
                      Container(height: 18),
                    // Barre avec données
                    SizedBox(
                        height: heightLmax,
                        child: Stack(children: [
                          // Barre de capacité
                          Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                  margin: EdgeInsets.only(
                                      left: margin / 2,
                                      right: margin / 2,
                                      bottom: margin / 3),
                                  width: widget.dayWidth - margin - 15,
                                  height: (heightCapeff > 0)
                                      ? heightCapeff - 2
                                      : heightLmax,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: (widget.index ==
                                                widget.centerItemIndex)
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
                                              ? Icon(Icons.sunny,
                                                  color: colors['secondaryBackground'],
                                                  size: 14)
                                              : null))),
                          // Barre de travail affecté (busy)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              margin: EdgeInsets.only(
                                  left: margin / 2,
                                  right: margin / 2,
                                  bottom: margin / 3),
                              width: widget.dayWidth - margin - 16,
                              // On affiche 1 pixel pour marquer une journée travaillée
                              height: (heightBuseff <= 0) ? 0.5 : heightBuseff,
                              decoration: BoxDecoration(
                                borderRadius: borderRadius,
                                color: busyColor,
                              ),
                            ),
                          ),
                          // Barre de tavail terminé
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
                                          left: margin / 2,
                                          right: margin / 2,
                                          bottom: margin / 3),
                                      width: widget.dayWidth - margin - 16,
                                      decoration: BoxDecoration(
                                        borderRadius: borderRadius,
                                        color: completeColor,
                                      ),
                                      child: (dayIsCompleted)
                                          ? Center(
                                              child: Icon(Icons.check,
                                                  color: colors['info'],
                                                  size: 16))
                                          : null)))
                        ])),
                  ],
                ))));
  }
}
