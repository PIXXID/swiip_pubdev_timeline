import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ------
/// Format des couleurs hexadecimal en Color Dart
/// [color] Couleur au format #FFFFFF
/// ------
Color? formatStringToColor(String? color) {
  if (color == null || color.isEmpty) {
    return null; // Si la chaîne est nulle ou vide, on retourne null
  }

  // On enlève le # si présent
  String cleanedColor = color.replaceAll('#', '');

  // Si la chaîne a 6 caractères, on ajoute 'FF' pour une opacité maximale
  if (cleanedColor.length == 6) {
    cleanedColor = 'FF$cleanedColor';
  }

  try {
    // Conversion de la chaîne en entier et retour de la couleur
    return Color(int.parse(cleanedColor, radix: 16));
  } catch (e) {
    // En cas d'erreur de parsing, retourne null
    return null;
  }
}

/// ------
/// Transforme le format d'origine an format attendue par
/// le widget de timeline.
/// L'objectif est de recomposer pour chaque jour, la charge,
/// les élements et les étapes.
///
/// [startDate]       Date de départ
/// [endDate]         Date de fin
/// [elements]        Tableau d'élements
/// [elementsDone]    Tableau d'élements terminés
/// [capacities]      Tableau des capacités utilisateur
/// [stages]          Séquence et étapes associés aux élements
/// [maxCapacity]     Capacité maximum pour la calcul du graphique
/// ------
List formatElements(DateTime startDate, 
  DateTime endDate, 
  List elements,
  List elementsDone, 
  List capacities, 
  List stages, 
  int maxCapacity) {

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
          if (element['status'] == 'validated' ||
              element['status'] == 'finished') {
            day['elementCompleted'] += 1;
          } else if (element['status'] == 'pending' ||
              element['status'] == 'inprogress') {
            day['elementPending'] += 1;
          }
        }
      }
    }

    // Ajoute les élements terminée dans la liste des preIds
    if (elementsDone.isNotEmpty) {
      for (dynamic element in elementsDone) {
        // Date et preId
        if (element['date'] == DateFormat('yyyy-MM-dd').format(date) &&
            day['preIds'].indexOf(element['pre_id']) == -1) {
          day['preIds'].add(element['pre_id']);
        }
      }
    }

    // Informations sur les capacités du jour
    if (capacitiesDay != null) {
      day['lmax'] = maxCapacity;
      day['capeff'] =
          capacitiesDay.containsKey('capeff') && capacitiesDay['capeff'] != null
              ? capacitiesDay['capeff']
              : 0;
      day['buseff'] =
          capacitiesDay.containsKey('buseff') && capacitiesDay['buseff'] != null
              ? capacitiesDay['buseff']
              : 0;
      day['compeff'] = capacitiesDay.containsKey('compeff') &&
              capacitiesDay['compeff'] != null
          ? capacitiesDay['compeff']
          : 0;
      day['eicon'] = capacitiesDay['eicon'];
    }

    // Calcul des points d'alertes
    double progress =
        day['capeff'] > 0 ? (day['buseff'] / day['capeff']) * 100 : 0;
    if (progress > 100) {
      day['alertLevel'] = 2;
    } else if (progress > 80) {
      day['alertLevel'] = 1;
    }

    list.add(day);
  }

  return list.toList();
}

/// ------
/// Formate les étapes par lignes pour qu'ils ne se cheveauchent pas
///
/// [startDate]       Date de départ
/// [endDate]         Date de fin
/// [stages]          Tableau des séquence et étapes associés aux élements
/// [elements]        Tableau d'élements
/// ------
List formatStagesRows(DateTime startDate, 
  DateTime endDate,
  List days,
  List stages, 
  List elements) {

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
      return stages[i]['elm_filtered']?.contains(e['pre_id']) == true &&
          addedPreIds.add(e['pre_id']);
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
        DateFormat('yyyy-MM-dd').format(d['date']) ==
        DateFormat('yyyy-MM-dd').format(stageEndDate));

    stage['startDateIndex'] = startDateIndex;
    stage['endDateIndex'] = endDateIndex;
    stage['sdate'] = stage['sdate'];
    stage['edate'] = stage['edate'];

    // Exclue les stages hos plages de dates
    if (startDateIndex == -1 || endDateIndex == -1) {
      continue;
    }

    bool isStage =
        ['milestone', 'cycle', 'sequence', 'stage'].contains(stage['type']);

    // Si aucun row, on crée le premier
    if (rows.isEmpty) {
      rows.add([stage]);
    } else {
      // Si on au moins un row, on les parcourt pour voir dans lequel on peut se placer sans cheveaucher un autre créneau
      var added = false;
      for (var j = lastStageRowIndex; j < rows.length; j++) {
        // On cherche si on cheveauche un existant
        var overlapIndex = rows[j].indexWhere((r) {
          return (((r['endDateIndex'] + 1) > stage['startDateIndex'])
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

/// ------
/// Positionne le stage du premier niveau pour chaque jour
///
/// [days]    Liste des jours à positionner
/// [stages]  Tableau des séquences et étapes associés aux élements
/// ------
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


/// ------
/// Récupère la row qui a le stage/élément le plus haut pour adapter le scroll vertical
///
/// [stagesRows]        Tableau des séquences et étapes associés aux élements
/// [centerItemIndex]   Idex de l'item à centrer
/// ------
int getHigherStageRowIndex(List stagesRows, int centerItemIndex) {
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


/// ------
/// Récupère la row qui a le stage/élément le plus haut pour adapter le scroll vertical
///
/// [stagesRows]        Tableau des séquences et étapes associés aux élements
/// [centerItemIndex]   Idex de l'item à centrer
/// ------
int getLowerStageRowIndex(List stagesRows, int centerItemIndex) {
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

  
