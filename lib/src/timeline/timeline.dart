import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Widgets
import 'timeline_item.dart';
import 'timeline_day_info.dart';
import 'timeline_day_indicators.dart';
import 'timeline_day_date.dart';
import 'stage_row.dart';

class Timeline extends StatefulWidget {
  const Timeline(
      {Key? key,
      required this.width,
      required this.height,
      required this.colors,
      required this.lang,
      required this.projectCount,
      required this.mode,
      required this.infos,
      required this.elements,
      required this.elementsDone,
      required this.capacities,
      required this.stages,
      required this.notifications,
      this.defaultDate,
      required this.openDayDetail,
      this.openEditStage,
      this.openEditElement,
      this.updateCurrentDate}) : super(key: key);

  final double width;
  final double height;
  final Map<String, Color> colors;
  final String lang;
  final int projectCount;
  final String mode;
  final dynamic infos;
  final dynamic elements;
  final dynamic elementsDone;
  final dynamic capacities;
  final dynamic stages;
  final dynamic notifications;
  final String? defaultDate;
  final Function(String, double?, List<String>?, List<dynamic>?, dynamic)? openDayDetail;
  final Function(String?, String?, String?, String?, String?, double?, String?)? openEditStage;
  final Function(String?, String?, String?, String?, String?, double?, String?)? openEditElement;
  final Function(String?)? updateCurrentDate;

  @override
  State<Timeline> createState() => _Timeline();
}

class _Timeline extends State<Timeline> {
  // Liste des jours formatés
  List days = [];

  // Valeur du slider
  double sliderValue = 0.0;
  double sliderMargin = 25;
  double sliderMaxValue = 10;

  // Largeur d'un item jour
  double dayWidth = 45.0;
  double dayMargin = 5;
  // Hauteut de la liste des jours
  double datesHeight = 65.0;
  // Hauteur du container de la timeline et des stages/éléments
  double timelineHeightContainer = 300.0;
  // Hauteur de la timeline
  double timelineHeight = 300.0;
  // Diamètre des pins d'alertes
  double alertWidth = 6;
  // Liste des widgets des alertes
  List<Widget> alertList = [];

  // Liste des lignes d'étapes
  List stagesRows = [];
  // Hauteur d'une ligne d'étapes
  double rowHeight = 30.0;
  // Marges d'une ligne d'étapes
  double rowMargin = 3.0;
  // Index de l'item jour au centre
  int centerItemIndex = 0;

  // Date de début et date de fin par défaut
  DateTime now = DateTime.now();
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now().add(const Duration(days: 30));
  int nowIndex = 0;
  int defaultDateIndex = -1;
  bool timelineIsEmpty = false; 

  // Controllers des scroll
  final ScrollController _controllerTimeline = ScrollController();
  final ScrollController _controllerVerticalStages = ScrollController();

  // Position du scroll vertical
  double scrollbarHeight = 0.0;
  double scrollbarOffset = 0.0;
  // Scroll vertical si l'utilisateur a scrollé à la main
  double? userScrollOffset;

  bool isUniqueProject = false;

  // Déclenche le scroll dans le controller timeline
  void _scrollH(double sliderValue) {
    // gestion du scroll via le slide
    _controllerTimeline.jumpTo(sliderValue);
  }
  // Déclenche le scroll dans le controller timeline
  void _scrollHAnimated(double sliderValue) {
    // gestion du scroll via le slide
    _controllerTimeline.animateTo(
      sliderValue,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut
    );
  }

  // Scroll vertical des stages automatique
  void _scrollV(double sliderValue) {
    // gestion du scroll via le slide
    _controllerVerticalStages.animateTo(
      sliderValue,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut
    );
  }

  // Initialisation
  @override
  void initState() {
    super.initState();
    debugPrint('------ Timeline InitState');
    
    // Vérifie que la timleline recoit bien des élement
    if (widget.elements != null && widget.elements.isNotEmpty) {
      // On positionne les dates de début et de fin
      if (widget.infos['startDate'] != null) {
        startDate = DateTime.parse(widget.infos['startDate']!);
      }
      // Si la timeline n'a aucun élement
      if (widget.infos['endDate'] != null) {
        endDate = DateTime.parse(widget.infos['endDate']!);
      }
    } else {
       // Indique qu'il n'y a pas de données pour cette requete.
      timelineIsEmpty = true;
    }

    // Formate la liste des jours pour positionner les éléments correctement
    days = formatElements(
        startDate,
        endDate,
        widget.elements,
        (widget.elementsDone == null || widget.elementsDone.isEmpty)
            ? List.empty()
            : widget.elementsDone,
        widget.capacities,
        widget.notifications,
        widget.stages);

    // Formate la liste des étapes en plusieurs lignes selon les dates
    stagesRows = formatStagesRows(startDate, endDate, days, widget.stages, widget.elements);

    // On positionne le stage de la première ligne par jour
    days = getStageByDay(days, stagesRows);

    // Calcule la valeur maximum du slider
    sliderMaxValue = days.length.toDouble() * (dayWidth - dayMargin);

    // Calcule l'index de la date du jour
    nowIndex = now.difference(startDate).inDays;

    // Calcule l'index de la date positionnée par défaut
    if (widget.defaultDate != null) {
      defaultDateIndex = DateTime.parse(widget.defaultDate!).difference(startDate).inDays + 1;
    }

    // Écoute du scroll pour :
    // - calculer quel élément est au centre
    // - mettre à jour la valeur du slide
    // - reporter le scroll sur les étapes
    // - Si mode stages/éléments, scroll vertical automatique
    double oldSliderValue = 0.0;
    int oldCenterItemIndex = 0;
    _controllerTimeline.addListener(() {
      if (_controllerTimeline.offset >= 0 &&
          _controllerTimeline.offset < sliderMaxValue) {
        // Met à jour les valeurs
        setState(() {
          // On calcule l'élément du center
          int centerValue = (sliderValue / (dayWidth - dayMargin)).round();
          if (centerValue >= 0 && centerValue <= days.length - 1) {
            centerItemIndex = centerValue;
          }

          // On met à jour la valeur du slider
          sliderValue = _controllerTimeline.offset;

          // On fait le croll vertical automatique uniquement si l'élément du centre a changé. (optimisation)
          if (oldCenterItemIndex != centerItemIndex) {
            bool enableAutoScroll = false;

            // Index à gauche de l'écran
            int leftItemIndex = centerItemIndex - 4;
            // On récupère l'index de la ligne du stage/élément la plus haute
            int higherRowIndex = getHigherStageRowIndex(leftItemIndex > 0 ? leftItemIndex : 0);
            // On calcule la hauteur de la ligne du stage/élément la plus haute
            double higherRowHeight = (higherRowIndex * (rowHeight + (rowMargin * 2)));
            // On vérifie si on est pas en bas du scroll pour éviter l'effet  rebomb du scroll en bas
            double totalRowsHeight = (rowHeight + rowMargin) * stagesRows.length;
            // On active le scroll si l'utilisateur a fait un scroll vertical et si, quand on scroll vers la droite,
            // le stage/élément le plus haut est plus bas que le niveau de scroll de l'utilisateur
            enableAutoScroll = userScrollOffset == null || userScrollOffset != null && (userScrollOffset! < higherRowHeight);

            // On ne calcule l'élément le plus bas que si on scroll vers la gauche
            // et que l'utilsateur a scrollé à la main (optimisation)
            if (sliderValue < oldSliderValue && userScrollOffset != null && widget.mode == 'chronology') {
              // Index à droite de l'écran
              int rightItemIndex = centerItemIndex + 4;
              // On récupère l'index de la ligne du stage/élément la plus basse
              int lowerRowIndex = getLowerStageRowIndex(rightItemIndex > 0 ? rightItemIndex : 0);
              // On calcule la hauteur de la ligne du stage/élément la plus basse
              double lowerRowHeight = (lowerRowIndex * (rowHeight + (rowMargin * 2)));
              // On active le scroll si l'utilisateur a fait un scroll vertical et si, quand on scroll vers la gauche,
              // le stage/élément le plus bas est plus haut que le niveau de scroll de l'utilisateur
              enableAutoScroll = userScrollOffset == null || userScrollOffset != null && (userScrollOffset! > lowerRowHeight);
            }

            // On vérifie si l'utilisateur a fait un scroll manuel pour éviter de le perdre
            // On ne reprend le scroll automatique que si le stage/élément le plus haut est plus bas que le scroll de l'utilisateur
            if (enableAutoScroll && widget.mode == 'chronology') {
              if (totalRowsHeight - higherRowHeight > timelineHeight / 2) {
                // On déclenche le scroll
                _scrollV(higherRowHeight);
              } else {
                _scrollV(_controllerVerticalStages.position.maxScrollExtent);
              }
              // Réinitialise le scroll saisi par l'utilisateur
              userScrollOffset = null;
            }
          }

          // Mise à jour de la position précédente
          oldSliderValue = sliderValue;
          // Mise à jour du centre précédent
          oldCenterItemIndex = centerItemIndex;
        });

        if (widget.updateCurrentDate != null && days[centerItemIndex] != null && days[centerItemIndex]['date'] != null) {
          String dayDate = DateFormat('yyyy-MM-dd').format(days[centerItemIndex]['date']);
          widget.updateCurrentDate!.call(dayDate);
        }
      }
    });
  
    // On vérifie si la timeline affiche un ou plusieurs projets
    if (widget.stages.isNotEmpty) {
      Set<String> uniquePrjIds = {};
      for (var item in widget.stages) {
        String? prjId = item['prj_id'];
        if (prjId != null) {
          uniquePrjIds.add(prjId);
        }
      }
      isUniqueProject = uniquePrjIds.length > 1 ? false : true;      
    }

    // Personnalise la taile de l'affichage
    timelineHeight = widget.height;
    timelineHeightContainer = timelineHeight - datesHeight;

    // Calcule la position de la scrollbar
    scrollbarHeight = timelineHeightContainer * timelineHeightContainer / (stagesRows.length * rowHeight);
    scrollbarOffset = 0;

    // Écoute le scroll vertical pour ajuster la scrollbar
    _controllerVerticalStages.addListener(() {
      setState(() {
        double currentVerticalScrollOffset = _controllerVerticalStages.position.pixels;
        // Hauteur de la barre de scroll
        scrollbarHeight = timelineHeightContainer * timelineHeightContainer / (stagesRows.length * rowHeight);
        // Position de la bar selon le scroll (en tenant compte de la hauteur de la barre)
        scrollbarOffset = currentVerticalScrollOffset * (timelineHeightContainer - (scrollbarHeight * 2)) / (stagesRows.length * rowHeight);
      });
    });

    // Exécuter une seule fois après la construction du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // On scroll sur la date du jour par défaut
      scrollTo(widget.defaultDate != null ? defaultDateIndex : nowIndex, animated: true);
    });
  }

  // Destruction du widget
  @override
  void dispose() {
    // On enlève les écoutes du scroll de la timeline et vertical
    _controllerTimeline.removeListener(() {});
    _controllerVerticalStages.removeListener(() {});
    super.dispose();
  }

  /// Formate la liste des jours pour la timeline
  List formatElements(DateTime startDate, DateTime endDate, List elements, List elementsDone, List capacities, List notifications, List stages) {
    List list = [];

    // On récupère le nombre de jours entre la date de début et la date de fin
    int duration = endDate.difference(startDate).inDays;

    // On parcourt les dates pour y associer les jours et les étapes en cours
    for (var dateIndex = 0; dateIndex <= duration; dateIndex++) {
      DateTime date = startDate.add(Duration(days: dateIndex));

      var elementDay = elements
          .where(
            (e) => e['date'] == DateFormat('yyyy-MM-dd').format(date),
          )
          .toList();

      var capacitiesDay = capacities.firstWhere(
        (e) => e['date'] == DateFormat('yyyy-MM-dd').format(date),
        orElse: () => <String, Object>{},
      );

      // Données par défaut
      Map<String, dynamic> day = {
        'date': date,
        'lmax': 0,
        'activityTotal': 0,
        'activityCompleted': 0,
        'delivrableTotal': 0,
        'delivrableCompleted': 0,
        'taskTotal': 0,
        'taskCompleted': 0,
        'elementCompleted': 0,
        'elementPending': 0,
        'preIds': [],
        'stage': {},
        'eicon': ''
      };

      // Si on a des éléments on les comptes
      if (elementDay.isNotEmpty) {
        // On boucle sur les éléments pour compter le nombre d'activité/livrables/tâches
        for (Map<String, dynamic> element in elementDay) {
          if (day['preIds'].indexOf(element['pre_id']) == -1) {
            // On construit la liste des éléments (qui sera transmise lors du clic)
            day['preIds'].add(element['pre_id']);

            // Selon le type d'éléments on construit les compteurs
            switch (element['nat']) {
              case 'activity':
                if (element['status'] == 'status') {
                  day['activityCompleted'] += 1;
                }
                day['activityTotal']++;
                break;
              case 'delivrable':
                if (element['status'] == 'status') {
                  day['delivrableCompleted'] += 1;
                }
                day['delivrableTotal']++;
                break;
              case 'task':
                if (element['status'] == 'status') {
                  day['taskCompleted'] += 1;
                }
                day['taskTotal']++;
                break;
            }

            // Compte le nombres d'element terminé et en attente/encours
            if (element['status'] == 'validated' || element['status'] == 'finished') {
                day['elementCompleted'] += 1;
            } else if (element['status'] == 'pending' || element['status'] == 'inprogress') {
                day['elementPending'] += 1;
            }
          }
        }
      }

      // Ajoute les élements terminée dans la liste des preIds
      if (elementsDone.isNotEmpty) {
        for (dynamic element in elementsDone) {         
          // Date et preId
          if (element['date'] == DateFormat('yyyy-MM-dd').format(date) && day['preIds'].indexOf(element['pre_id']) == -1) {
            day['preIds'].add(element['pre_id']);
          }
        }
      }

      // Informations sur les capacités du jour
      if (capacitiesDay != null) {
        day['lmax'] = widget.infos['lmax'] ?? 0;
        day['capeff'] = capacitiesDay.containsKey('capeff') &&
                capacitiesDay['capeff'] != null
            ? capacitiesDay['capeff']
            : 0;
        day['buseff'] = capacitiesDay.containsKey('buseff') &&
                capacitiesDay['buseff'] != null
            ? capacitiesDay['buseff']
            : 0;
        day['compeff'] = capacitiesDay.containsKey('compeff') &&
                capacitiesDay['compeff'] != null
            ? capacitiesDay['compeff']
            : 0;
        day['eicon'] = capacitiesDay['eicon'];
      }

      // Calcul des points d'alertes
      double progress = day['capeff'] > 0 ? (day['buseff'] / day['capeff']) * 100 : 0;
      if (progress > 100) {
        day['alertLevel'] = 2;
      } else if (progress > 80) {
        day['alertLevel'] = 1;
      }

      list.add(day);
    }

    return list.toList();
  }

  // Formate les étapes par lignes pour qu'ils ne se cheveauchent pas
  List formatStagesRows(
      DateTime startDate, DateTime endDate, List days, List stages, List elements) {
    List rows = [];
    
    List<dynamic> mergedList = [];

    // Pour chaque stage, on positionne à la suite les éléments associés
    for (int i = 0; i < stages.length; i++) {
      // On ajoute le stage
      mergedList.add(stages[i]);
      // On filtre les éléments associés au stage
      Set<dynamic> addedPreIds = {};
      List<dynamic> stageElements = elements.where((e) {
        // Vérifie si l'élément est dans la liste des pre_ids et s'il n'a pas déjà été ajouté
        return stages[i]['elm_filtered']?.contains(e['pre_id']) == true && addedPreIds.add(e['pre_id']);
      }).map((e) {
        // Ajoute le paramètre 'pcolor' directement dans l'élément
        return {
          ...e,
          'pcolor': stages[i]['pcolor'],
          'prs_id': stages[i]['prs_id'],
        };
      }).toList();
      // Trie la liste par 'sdate'
      stageElements.sort((a, b) => a['sdate'].compareTo(b['sdate']));
      // On ajoute ces éléments à la liste
      mergedList = [...mergedList, ...stageElements];
    }

    // Si on définit l'index de départ uniquement dans le cas d'un stage
    // Une fois un stage défini, on parcourera les lignes libres à partir de l'index de ce stage
    // pour éviter que les éléments ne remontent au dessus sur une autre ligne
    int lastStageRowIndex = 0;
    // On parcourt les étapes et éléments pour construire les lignes
    for (int i = 0; i < mergedList.length - 1; i++) {
      // Dates des stages
      DateTime stageStartDate = DateTime.parse(mergedList[i]['sdate']);
      DateTime stageEndDate = DateTime.parse(mergedList[i]['edate']);

      Map<String, dynamic> stage = Map<String, dynamic>.from(mergedList[i]);

      // Prend en compte les stages commencant avant le premier élement
      if (stageStartDate.compareTo(startDate) < 0) {
        stageStartDate = startDate;
      }

      // On récupère les index des dates dans la liste
      int startDateIndex = days.indexWhere((d) =>
          DateFormat('yyyy-MM-dd').format(d["date"]) ==
          DateFormat('yyyy-MM-dd').format(stageStartDate));
      int endDateIndex = days.indexWhere((d) =>
          DateFormat('yyyy-MM-dd').format(d['date']) == DateFormat('yyyy-MM-dd').format(stageEndDate));

      stage['startDateIndex'] = startDateIndex;
      stage['endDateIndex'] = endDateIndex;
      stage['sdate'] = stage['sdate'];
      stage['edate'] = stage['edate'];

      // Exclue les stages hos plages de dates
      if (startDateIndex == -1 || endDateIndex == -1) {
        continue;
      }

      bool isStage = ['milestone', 'cycle', 'sequence', 'stage'].contains(stage['type']);
      
      // Si aucun row, on crée le premier
      if (rows.isEmpty) {
        rows.add([stage]);
      } else {
        // Si on au moins un row, on les parcourt pour voir dans lequel on peut se placer sans cheveaucher un autre créneau
        var added = false;
        for (var j = lastStageRowIndex;j < rows.length;j++) {
          // On cherche si on cheveauche un existant
          var overlapIndex = rows[j].indexWhere((r) {
            return (((r['endDateIndex'] + 1) >
                    stage['startDateIndex'])
                ? true
                : false);
          });
          // Si il n'y a pas de cheveauchement, on l'ajoute à ce row
          if (overlapIndex == -1) {
            // Met à jour le premier row de référence pour ne pas remonter au dessus un stage
            if (isStage) {
              lastStageRowIndex = j;
            }
            rows[j].add(stage);
            added = true;
            break;
          }
        }

        // Si on a pas trouvé de place dans un row existant, on créer un nouveau row
        if (!added) {
          rows.add([stage]);
          // Met à jour le premier row de référence pour ne pas remonter au dessus un stage
          if (isStage) {
            lastStageRowIndex = rows.length;
          }
        }
      }
    }

    return rows;
  }

  // Positionne le stage du premier niveau pour chaque jour
  List getStageByDay(List days, List stages) {
    // On boucle sur les jours
    if (stages.isNotEmpty) {
      int index = 0;
      for (var day in days) {
        // Pour chaque jour, on récupère le stage correspondant du premier niveau
        int stageDate = stages[0].indexWhere((s) {
          return (s['startDateIndex'].toInt() <= index &&
              s['endDateIndex'].toInt() >= index);
        });
        if (stageDate != -1) {
          day['currentStage'] = stages[0][stageDate];
        }

        index++;
      }
    }

    return days;
  }

  // Scroll à une date
  void scrollTo(int dateIndex, { bool animated = false }) {
    if (dateIndex >= 0) {
      // On calcule la valeur du scroll en fonction de la date
      double scroll = dateIndex * (dayWidth - dayMargin);

      // Met à jour la valeur du scroll et scroll
      setState(() {
        sliderValue = scroll;
      });
      if (animated) {
        _scrollHAnimated(sliderValue);
      } else {
        _scrollH(sliderValue);
      }
    }
  }

  // Récupère la row qui a le stage/élément le plus haut pour adapter le scroll vertical
  int getHigherStageRowIndex(int centerItemIndex) {
    final int rowCount = stagesRows.length;
    
    for (int i = 0; i < rowCount; i++) {
      final row = stagesRows[i];

      // On parcourt les stages de chaque ligne
      for (final stage in row) {
        final int startIndex = stage['startDateIndex'];
        final int endIndex = stage['endDateIndex'];
        
        // On Vérifie si l'index est dans la plage de date
        if (centerItemIndex >= startIndex && centerItemIndex <= endIndex) {
          return i;
        }
      }
    }
    
    // Aucune correspondance trouvée
    return -1;
  }
  
  // Récupère la row qui a le stage/élément le plus haut pour adapter le scroll vertical
  int getLowerStageRowIndex(int centerItemIndex) {
    final int rowCount = stagesRows.length;
    
    // On parcourt les lignes en ordre inverse
    for (int i = rowCount - 1; i >= 0; i--) {
      final row = stagesRows[i];
      
      // On parcourt les stages de chaque ligne
      for (final stage in row) {
        final int startIndex = stage['startDateIndex'];
        final int endIndex = stage['endDateIndex'];
        
        // On Vérifie si l'index est dans la plage de date
        if (centerItemIndex >= startIndex && centerItemIndex <= endIndex) {
          return i + 1;
        }
      }
    }
    
    // Aucune correspondance trouvée
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    // On calcule le padding pour avoir le début et la fin de la timeline au milieu de l'écran
    // double screenWidth = MediaQuery.sizeOf(context).width;
    double screenWidth = widget.width;
    double firstElementMargin = ((screenWidth - (dayWidth - dayMargin)) / 2);
    double screenCenter = (screenWidth / 2);

    return Scaffold(
        backgroundColor: widget.colors['primaryBackground'],
        body: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.width),
          child: Stack(
              // Trait rouge indiquant le jour en cours
              children: [
                Positioned(
                  left: screenCenter,
                  top: 45,
                  child: Container(
                    height: timelineHeightContainer,
                    width: 1,
                    decoration: BoxDecoration(color: widget.colors['error']),
                  ),
                ),
                Positioned.fill(
                  child: Column(
                      children: <Widget>[
                        // CONTENEUR UNIQUE AVEC SCROLL HORIZONTAL
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: widget.colors['secondaryBackground']!, width: widget.mode == 'chronology' ? 1.5 : 0),
                            ),
                          ),
                        child:
                          SizedBox(
                            width: screenWidth,
                            child: SingleChildScrollView(
                              controller: _controllerTimeline,
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: firstElementMargin),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // DATES
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: widget.colors['secondaryBackground']!, width: 1.5),
                                      ),
                                    ),
                                  child:
                                    SizedBox(
                                      width: days.length * (dayWidth),
                                      height: datesHeight,
                                      child: Row(
                                        children: List.generate(
                                          days.length,
                                          (index) => TimelineDayDate(
                                            colors: widget.colors,
                                            lang: widget.lang,
                                            index: index,
                                            centerItemIndex: centerItemIndex,
                                            nowIndex: nowIndex,
                                            days: days,
                                            dayWidth: dayWidth,
                                            dayMargin: dayMargin,
                                            height: datesHeight,
                                          )
                                        )
                                      )
                                    ),
                                  ),
                                  if (widget.mode == 'effort')
                                    // TIMELINE DYNAMIQUE
                                    SizedBox(
                                      width: days.length * (dayWidth),
                                      height: timelineHeightContainer,
                                      child: Row(
                                        children: List.generate(
                                          days.length,
                                          (index) => TimelineItem(
                                            colors: widget.colors,
                                            index: index,
                                            centerItemIndex: centerItemIndex,
                                            nowIndex: nowIndex,
                                            days: days,
                                            elements: widget.elements,
                                            dayWidth: dayWidth,
                                            dayMargin: dayMargin,
                                            height: timelineHeight,
                                            openDayDetail: widget.openDayDetail,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (widget.mode == 'chronology')
                                    // STAGES/ELEMENTS DYNAMIQUES
                                    SizedBox(
                                      height: timelineHeightContainer, // Hauteur fixe pour la zone des stages
                                      child: NotificationListener<UserScrollNotification>(
                                        onNotification: (notification) {
                                          userScrollOffset = _controllerVerticalStages.position.pixels;
                                          return false;
                                        },
                                        child: SingleChildScrollView(
                                          controller: _controllerVerticalStages,
                                          scrollDirection: Axis.vertical,
                                          physics: const ClampingScrollPhysics(), // Permet un scroll fluide
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: List.generate(
                                              stagesRows.length,
                                              (rowIndex) => Container(
                                                margin: EdgeInsets.symmetric(vertical: rowMargin),
                                                width: days.length * (dayWidth - dayMargin),
                                                height: rowHeight,
                                                child: StageRow(
                                                  colors: widget.colors,
                                                  stagesList: stagesRows[rowIndex],
                                                  centerItemIndex: centerItemIndex,
                                                  dayWidth: dayWidth,
                                                  dayMargin: dayMargin,
                                                  height: rowHeight,
                                                  isUniqueProject: isUniqueProject,
                                                  openEditStage: widget.openEditStage,
                                                  openEditElement: widget.openEditElement,
                                                ),
                                              )
                                            ),
                                          ),
                                        )
                                      )
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // JOUR ET ICONES ELEMENTS
                        TimelineDayInfo(
                          day: days[centerItemIndex],
                          colors: widget.colors,
                          lang: widget.lang,
                          elements: widget.elements,
                          openDayDetail: widget.openDayDetail),
                        // ALERTES
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: Stack(clipBehavior: Clip.none, children: [
                            // Alertes positionnées
                            SizedBox(
                                width: screenWidth - (sliderMargin * 2),
                                height: 50,
                                child: Padding(
                                    padding: EdgeInsets.only(
                                        left: sliderMargin - (alertWidth / 2)),
                                    child: Builder(builder: (context) {
                                      List<Widget> alerts = [];
                                      double screenWidthMargin =
                                          screenWidth - ((sliderMargin) * 4);
                                      if (days.isNotEmpty) {
                                        // On parcourt les jours et on ajoute les alertes
                                        for (var index = 0;
                                            index < days.length;
                                            index++) {
                                          if (days[index]['alertLevel'] != 0) {
                                            alerts.add(Positioned(
                                                left: (index) *
                                                    screenWidthMargin /
                                                    days.length,
                                                top: 0,
                                                child: GestureDetector(
                                                    // Call back lors du clic
                                                    onTap: () {
                                                      setState(() {
                                                        sliderValue =
                                                            index.toDouble();
                                                      });
                                                    },
                                                    child: Icon(
                                                      Icons.circle_rounded,
                                                      size: 12,
                                                      color: days[index]['alertLevel'] == 1
                                                          ? widget
                                                              .colors['warning']
                                                          : (days[index]['alertLevel'] == 2
                                                              ? widget.colors['error']
                                                              : Colors
                                                                  .transparent),
                                                    ))));
                                          }
                                        }
                                      }
                                      // Point sur le jour en cours
                                      alerts.add(Positioned(
                                          left: (nowIndex) *
                                              screenWidthMargin /
                                              days.length,
                                          top: 0,
                                          child: GestureDetector(
                                              // Call back lors du clic
                                              onTap: () {
                                                scrollTo(nowIndex);
                                              },
                                              child: Icon(
                                                Icons.circle_outlined,
                                                size: 13,
                                                color:
                                                    widget.colors['primaryText'],
                                              ))));
                                      return Stack(
                                          children: alerts.isNotEmpty
                                              ? alerts
                                              : [const SizedBox()]);
                                    })
                              )
                            ),
                            // Slider
                            Positioned(
                                bottom: 0,
                                child: SizedBox(
                                    width: screenWidth - (sliderMargin * 2),
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        thumbColor: widget.colors['primary'],
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                                        activeTrackColor:
                                            widget.colors['primary'],
                                        inactiveTrackColor:
                                            widget.colors['secondaryBackground'],
                                        trackHeight: 2,
                                      ),
                                      child: Slider(
                                        value: sliderValue,
                                        min: 0,
                                        max: sliderMaxValue,
                                        divisions: days.length,
                                        onChanged: (double value) {
                                          sliderValue = value;
                                          _scrollH(value);
                                        },
                                      ),
                                    )))
                          ]
                        )
                    ),
                  ]),
                ),
                if (widget.mode == 'effort')
                  Positioned.fill(
                    left: 1,
                    top: 35,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      // INDICATEURS
                      child: TimelineDayIndicators(
                          day: days[centerItemIndex],
                          colors: widget.colors,
                          lang: widget.lang,
                          elements: widget.elements)
                    ),
                  ),
                if (widget.mode == 'chronology')
                  // SCROLLBAR CUSTOM
                  // Scrollbar personnalisée (Positionné à droite)
                  Positioned(
                    right: 0,
                    top: 65,
                    child: SizedBox(
                      width: 8,
                      height: timelineHeightContainer,
                      child: Stack(
                        children: [
                          Positioned(
                            right: 0,
                            top: scrollbarOffset,
                            child: Container(
                              width: 4,
                              height: scrollbarHeight,
                              decoration: BoxDecoration(
                                color: widget.colors['secondaryBackground']!.withAlpha(120),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            )
                          )
                        ]
                      ),
                    ),
                  ),
                // MESSAGE SI AUCUNE ACTIVITE
                if (timelineIsEmpty)
                  Positioned.fill(
                    child: Container(
                      color: widget.colors['primaryBackground'],
                      padding: const EdgeInsets.all(25),
                      child: Center(
                        child: Text(
                          'Aucune activité ne vous a été attribuée. Vous pouvez consulter le détail des projets et configurer vos équipes.',
                          style: TextStyle(
                            color: widget.colors['primaryText'], fontSize: 15),
                          )
                      ),
                    ),
                  )
              ],
                ),
        )
    );
  }
}
