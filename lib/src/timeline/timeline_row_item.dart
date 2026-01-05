import 'package:flutter/material.dart';

class TimelineRowItem extends StatelessWidget {
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

  final Map<String, Color> colors;
  final double dayWidth;
  final double dayMargin;
  final double itemWidth;
  final int daysNumber;
  final double height;
  final String entityId;
  final String startDate;
  final String endDate;
  final String type;
  final String label;
  final String? icon;
  final String? users;
  final double progress;
  final String prjId;
  final String? pname;
  final String parentStageId;
  final bool isStage;
  final bool isUniqueProject;
  final Function(String?, String?, String?, String?, String?, double?, String?)?
      openEditStage;
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
