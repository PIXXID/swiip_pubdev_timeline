import 'package:flutter/material.dart';

/*
* Affichage des informations lors du survol d'une journée
* Permet d'afficher la séquence, les informations de progressions
* et la date survolée
*/
class TimelineDayIndicators extends StatelessWidget {
  const TimelineDayIndicators({
    super.key,
    required this.day,
    required this.colors,
    required this.elements,
  });

  final Map<String, Color> colors;
  final dynamic day;
  final List elements;

  @override
  Widget build(BuildContext context) {
    const double badgeWidth = 50;
    const double badgeHeight = 22;

    // Données de style
    const fontSize = 14.0;
     // Border radius
    BorderRadius borderRadius = const BorderRadius.only(
        topRight: Radius.circular(10), 
        bottomRight: Radius.circular(10)
    );

    return Column(
      children: <Widget>[
        Container(
          width: badgeWidth,
          height: badgeHeight,
          decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: colors['primaryBackground'],
              border: Border.all(color: colors['secondaryText']!)),
          child: Center(
              child: Text(
                "${day['capeff'].floor()}h",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors['primaryText'],
                  fontSize: fontSize,
                ),
              )
            )
        ),
        const SizedBox(height: 4),
        Container(
          width: badgeWidth,
          height: badgeHeight,
          decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: colors['secondaryText'],
              border: Border.all(color: colors['secondaryText']!)),
          child: Center(
              child: Text(
                "${day['buseff'].toStringAsFixed(1)}h",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors['info'],
                  fontSize: fontSize,
                ),
              )
            )
        ),
        const SizedBox(height: 4),
        Container(
          width: badgeWidth,
          height: badgeHeight,
          decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: colors['primary'],
              border: Border.all(color: colors['primary']!)),
          child: Center(
              child: Text(
                "${day['compeff'].toStringAsFixed(1)}h",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors['info'],
                  fontSize: fontSize,
                ),
              )
            )
        ),
      ]
    );
    
  }
}
