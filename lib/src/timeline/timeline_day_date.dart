import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimelineDayDate extends StatefulWidget {
  final String lang;
  final Map<String, Color> colors;
  final int index;
  final int centerItemIndex;
  final List days;
  final double dayWidth;
  final double dayMargin;
  final double height;

  const TimelineDayDate(
      {super.key,
      required this.lang,
      required this.colors,
      required this.index,
      required this.centerItemIndex,
      required this.days,
      required this.dayWidth,
      required this.dayMargin,
      required this.height});

  @override
  State<TimelineDayDate> createState() => _TimelineDayDate();
}

class _TimelineDayDate extends State<TimelineDayDate>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    dynamic day = widget.days[widget.index];
    dynamic colors = widget.colors;
    double margin = widget.dayMargin;

    final DateTime date = day['date'];
    final int idxCenter = widget.centerItemIndex - widget.index;

    return Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
            child: SizedBox(
                width: widget.dayWidth - margin,
                height: widget.height,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Dates
                    Flexible(
                      child: Text(
                        DateFormat.E(widget.lang)
                            .format(date)
                            .toUpperCase()
                            .substring(0, 1),
                        style: TextStyle(
                            color: (idxCenter == 0)
                                ? colors['primaryText']
                                : colors['secondaryText'],
                            fontSize: (idxCenter == 0) ? 14 : 12,
                            fontWeight: (idxCenter == 0)
                                ? FontWeight.w800
                                : FontWeight.w200),
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        DateFormat.Md(widget.lang).format(date),
                        style: TextStyle(
                            color: (idxCenter == 0)
                                ? colors['primaryText']
                                : colors['secondaryText'],
                            fontSize: 12,
                            fontWeight: (idxCenter == 0)
                                ? FontWeight.w800
                                : FontWeight.w200),
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    // Météo
                    if (day['eicon'] != null)
                      Flexible(
                          child: Padding(
                              padding: const EdgeInsets.only(top: 2, bottom: 2),
                              child: Text(
                                '${day['eicon']}',
                                style: TextStyle(
                                  color: colors['primaryText'],
                                  fontWeight: FontWeight.w300,
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.clip,
                              )))
                    else
                      const Flexible(child: SizedBox(height: 28)),
                  ],
                ))));
  }
}
