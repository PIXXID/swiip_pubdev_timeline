import 'package:flutter/material.dart';

/// Widget that displays a single stage or element item in the timeline row.
///
/// Shows progress bars, labels, icons, and user assignments.
class TimelineRowItem extends StatelessWidget {
  /// Creates a timeline row item widget.
  const TimelineRowItem(
      {super.key,
      required this.colors,
      required this.dayWidth,
      required this.dayMargin,
      required this.itemWidth,
      required this.daysNumber,
      required this.height,
      required this.label,
      this.icon,
      this.users,
      required this.startDate,
      required this.endDate,
      required this.type,
      required this.entityId,
      required this.progress,
      required this.prjId,
      this.pname,
      required this.parentStageId,
      required this.isStage,
      required this.isUniqueProject,
      required this.openEditStage,
      required this.openEditElement});

  /// Color scheme for the item.
  final Map<String, Color> colors;

  /// Width of each day column in pixels.
  final double dayWidth;

  /// Margin between day columns in pixels.
  final double dayMargin;

  /// Total width of this item in pixels.
  final double itemWidth;

  /// Number of days this item spans.
  final int daysNumber;

  /// Height of the item in pixels.
  final double height;

  /// Unique identifier for this stage or element.
  final String entityId;

  /// Start date in ISO format (yyyy-MM-dd).
  final String startDate;

  /// End date in ISO format (yyyy-MM-dd).
  final String endDate;

  /// Type of item (milestone, cycle, sequence, stage, or element type).
  final String type;

  /// Display label for the item.
  final String label;

  /// Optional icon emoji or character.
  final String? icon;

  /// Comma-separated list of user initials.
  final String? users;

  /// Progress percentage (0-100).
  final double progress;

  /// Project ID this item belongs to.
  final String prjId;

  /// Project name (optional).
  final String? pname;

  /// Parent stage ID (for elements).
  final String parentStageId;

  /// Whether this is a stage (true) or element (false).
  final bool isStage;

  /// Whether the timeline displays a single project.
  final bool isUniqueProject;

  /// Callback when a stage is tapped for editing.
  final Function(String?, String?, String?, String?, String?, double?, String?)?
      openEditStage;

  /// Callback when an element is tapped for editing.
  final Function(String?, String?, String?, String?, String?, double?, String?)?
      openEditElement;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(4));
    const fontSize = 14.0;
    const fontWeight = FontWeight.w400;
    // Laisse un ecart entre les items
    double itemSize = itemWidth - 2;

    // Couleur du texte dynamique en fonction de la couleur du projet
    Color fontColor = ThemeData.estimateBrightnessForColor(
                (colors['pcolor'] ?? colors['primaryText']!)) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;
    Color backgroundColor =
        (colors['pcolor'] ?? colors['primaryText'])!.withAlpha(150);
    Color completeColor = colors['pcolor'] ?? colors['primaryText']!;

    List<String> usersList = [];
    if (users != null) {
      usersList = users!.split(',');
    }

    return GestureDetector(
      // Call back lors du clic
      onTap: () {
        if (isStage) {
          openEditStage?.call(
              entityId, label, type, startDate, endDate, progress, prjId);
        } else {
          openEditElement?.call(
              entityId, label, type, startDate, endDate, progress, prjId);
        }
      },
      child: Stack(children: [
        // FOND DU STAGE/ELEMENT
        Container(
            width: itemSize,
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
                  !isStage ? borderRadius : const BorderRadius.all(Radius.zero),
            ),
            child: Stack(children: [
              // Progression
              Container(
                  width: itemSize * progress / 100,
                  decoration: BoxDecoration(
                    borderRadius: !isStage
                        ? borderRadius
                        : const BorderRadius.all(Radius.zero),
                    color: completeColor,
                  )),
              // Bloc qui masque une partie du fond pour effet
              if (isStage)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: itemSize - 2,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors['primaryBackground']?.withAlpha(220),
                      ),
                    ),
                  ),
                ),
              // TEXTE STAGES
              if (isStage)
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                    child: SizedBox(
                      width: itemSize - 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Affiche le badge seulement en multi-projet
                          if (!isUniqueProject)
                            Flexible(
                              fit: FlexFit.loose,
                              child: Text(
                                pname != null ? '$pname | ' : '',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: completeColor,
                                  fontWeight: fontWeight,
                                  fontSize: fontSize - 2,
                                ),
                              ),
                            ),
                          // Nom du stage
                          Expanded(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors['primaryText'],
                                fontWeight: fontWeight,
                                fontSize: fontSize - 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // TEXTE ELEMENT
              if (!isStage)
                Align(
                    alignment: Alignment.center,
                    child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Row(children: [
                          // PASTILLE USER
                          if (usersList.isNotEmpty)
                            Stack(children: [
                              // 1ER RESPONSABLE
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(150),
                                    shape: BoxShape.circle),
                                child: Center(
                                    child: Text(
                                  // Initiale ou Initiale +
                                  (usersList.length > 1)
                                      ? '${usersList[0]}+'
                                      : usersList[0],
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: fontWeight,
                                    fontSize: fontSize - 2,
                                  ),
                                )),
                              ),
                            ]),
                          if (usersList.isEmpty)
                            Stack(children: [
                              // AUCUN UTILISATEUR
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(150),
                                    shape: BoxShape.circle),
                                child: const Center(
                                    child: Text(
                                  '?',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: fontWeight,
                                    fontSize: fontSize - 2,
                                  ),
                                )),
                              ),
                            ]),
                          // ICON
                          if (daysNumber > 1) ...{
                            if (icon != null) const SizedBox(width: 5),
                            Text(
                              icon ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: fontWeight,
                                fontSize: fontSize,
                              ),
                            ),
                            // LABEL
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: fontColor,
                                  fontWeight: fontWeight,
                                  fontSize: fontSize,
                                ),
                              ),
                            )
                          },
                        ])))
            ])),
      ]),
    );
  }
}

//colors['primaryBackground']
