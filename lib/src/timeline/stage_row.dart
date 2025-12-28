import 'package:flutter/material.dart';

import 'stage_item.dart';
// Tools
import 'package:swiip_pubdev_timeline/src/tools/tools.dart';

class StageRow extends StatefulWidget {
  const StageRow(
      {super.key,
      required this.colors,
      required this.stagesList,
      required this.centerItemIndex,
      required this.dayWidth,
      required this.dayMargin,
      required this.height,
      required this.isUniqueProject,
      required this.openEditStage,
      required this.openEditElement});

  final Map<String, Color> colors;
  final List stagesList;
  final int centerItemIndex;
  final double dayWidth;
  final double dayMargin;
  final double height;
  final bool isUniqueProject;
  final Function(String?, String?, String?, String?, String?, double?, String?)?
      openEditStage;
  final Function(String?, String?, String?, String?, String?, double?, String?)?
      openEditElement;

  @override
  State<StageRow> createState() => _StageRow();
}

class _StageRow extends State<StageRow> {
  List<Widget> list = [];

  // Variables pour le Stack et le positionnement
  double currentPosition = 0;
  List<Widget> spacers = [];
  List<Widget> stageItems = [];
  List<Widget> labels = [];

  // Initialisation
  @override
  void initState() {
    buildStageList();
    super.initState();
  }

  // Méthode appelée lorsque les paramètres changent
  @override
  void didUpdateWidget(StageRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.centerItemIndex != oldWidget.centerItemIndex) {
      // Reconstruit la liste des étapes si la date en cours change
      buildStageList();

      setState(() {}); // Fait un rebuild
    }
  }

  // Construit la liste de stages/éléments
  void buildStageList() {
    // Reset toutes les listes
    list.clear();
    spacers.clear();
    stageItems.clear();
    labels.clear();
    currentPosition = 0;

    // On boucle sur les étapes de la ligne
    for (int index = 0; index < widget.stagesList.length; index++) {
      // Nombre de jour de durée
      int daysWidth = widget.stagesList[index]['endDateIndex'] -
          widget.stagesList[index]['startDateIndex'] +
          1;

      // Taux de progresion
      String progressLabel = (widget.stagesList[index]['prog'] != null &&
              widget.stagesList[index]['prog'] > 0)
          ? ' (${widget.stagesList[index]['prog']}%)'
          : '';
      bool isStage = ['milestone', 'cycle', 'sequence', 'stage']
          .contains(widget.stagesList[index]['type']);

      // Construction du label du stage
      String label = '';
      if (isStage) {
        // Nom du stage
        label = (widget.stagesList[index]['name'] != null)
            ? widget.stagesList[index]['name'] + progressLabel
            : '';
      } else {
        label = widget.stagesList[index]['pre_name'] ?? '';
      }

      // On ajoute la couleur du projet pour l'icon
      if (widget.stagesList[index]['pcolor'] != null) {
        widget.colors['pcolor'] =
            formatStringToColor(widget.stagesList[index]['pcolor'])!;
      } else {
        widget.colors['pcolor'] = Color(int.parse('ffffff', radix: 16));
      }
      Color fontColor = ThemeData.estimateBrightnessForColor(
                  (widget.colors['pcolor'] ?? widget.colors['primaryText']!)) ==
              Brightness.dark
          ? Colors.white
          : Colors.black;

      // Largeur de l'item
      double itemWidth = daysWidth * (widget.dayWidth - widget.dayMargin);

      // On récupère l'ancien étape de la liste
      var previousItem = index > 0 ? widget.stagesList[index - 1] : null;

      // On calcule l'espace avant cet élément
      double spacerWidth = 0;
      if (previousItem != null) {
        int daysBetweenElements = widget.stagesList[index]['startDateIndex'] -
            previousItem['endDateIndex'] -
            1;
        if (daysBetweenElements > 0) {
          spacerWidth =
              daysBetweenElements * (widget.dayWidth - widget.dayMargin);
        }
      } else {
        spacerWidth = widget.stagesList[index]['startDateIndex'] *
            (widget.dayWidth - widget.dayMargin);
      }

      // Ajouter un spacer si nécessaire
      if (spacerWidth > 0) {
        spacers.add(Positioned(
            left: currentPosition,
            child: SizedBox(
              width: spacerWidth,
              height: widget.height,
            )));
        currentPosition += spacerWidth;
      }

      // Position pour cet élément
      double stageItemPosition = currentPosition;

      // Ajoute le StageItem
      String entityId = isStage
          ? widget.stagesList[index]['prs_id']
          : widget.stagesList[index]['pre_id'];
      stageItems.add(Positioned(
          left: stageItemPosition,
          child: StageItem(
              colors: Map.from(widget.colors),
              dayWidth: widget.dayWidth,
              dayMargin: widget.dayMargin,
              itemWidth: itemWidth,
              daysNumber: daysWidth,
              height: widget.height,
              entityId: entityId,
              type: widget.stagesList[index]['type'] ??
                  widget.stagesList[index]['nat'],
              label: label,
              icon: widget.stagesList[index]['icon'],
              users: widget.stagesList[index]['users'],
              startDate: widget.stagesList[index]['sdate'],
              endDate: widget.stagesList[index]['edate'],
              progress: widget.stagesList[index]['prog'] != null
                  ? widget.stagesList[index]['prog'].toDouble()
                  : 0,
              prjId: widget.stagesList[index]['prj_id'],
              pname: widget.stagesList[index]['pname'],
              parentStageId: widget.stagesList[index]['prs_id'],
              isStage: isStage,
              isUniqueProject: widget.isUniqueProject,
              openEditStage: widget.openEditStage,
              openEditElement: widget.openEditElement)));

      // On vérifie si :
      // - Éléments uniquement
      // - Inférieur à 6 jours
      // - au centre de l'écran
      // Dans ce cas on affiche le label
      if (!isStage &&
          daysWidth < 4 &&
          widget.stagesList[index]['startDateIndex'] <=
              widget.centerItemIndex &&
          widget.stagesList[index]['endDateIndex'] >= widget.centerItemIndex) {
        // Ajoute le label associé
        labels.add(Positioned(
            left: stageItemPosition +
                30, // Décalage vers la droite par rapport au StageItem
            top: 5, // Positionnement vertical
            child: GestureDetector(
                // Call back lors du clic
                onTap: () {
                  widget.openEditElement?.call(
                      entityId,
                      label,
                      widget.stagesList[index]['type'],
                      widget.stagesList[index]['sdate'],
                      widget.stagesList[index]['edate'],
                      widget.stagesList[index]['prog'] != null
                          ? widget.stagesList[index]['prog'].toDouble()
                          : 0,
                      widget.stagesList[index]['prj_id']);
                },
                child: SizedBox(
                  child: Text(
                    label,
                    style: TextStyle(
                      background: Paint()..color = widget.colors['pcolor']!,
                      color: fontColor,
                      fontWeight: FontWeight.w300,
                      fontSize: 13,
                    ),
                  ),
                ))));
      }

      // Mise à jour de la position courante pour le prochain élément
      currentPosition += itemWidth;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        // Cette largeur est essentielle pour éviter l'erreur "size.isFinite is not true"
        width: currentPosition,
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ...spacers,
            ...stageItems,
            ...labels,
          ],
        ),
      ),
    );
  }
}
