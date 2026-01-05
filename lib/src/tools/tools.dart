import 'package:flutter/material.dart';

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
/// Récupère la row qui a le stage/élément le plus haut pour adapter le scroll vertical (optimized)
/// Uses early exit and avoids redundant checks
/// If no exact match is found, returns the row with the nearest upcoming stage
///
/// [stagesRows]        Tableau des séquences et étapes associés aux élements
/// [centerItemIndex]   Idex de l'item à centrer
/// ------
int getHigherTimelineRowIndexOptimized(List stagesRows, int centerItemIndex) {
  final int rowCount = stagesRows.length;
  int nearestRowIndex = -1;
  int nearestDistance = double.maxFinite.toInt();

  for (int i = 0; i < rowCount; i++) {
    final row = stagesRows[i];
    final int stageCount = row.length;

    // On parcourt les stages de chaque ligne
    for (int j = 0; j < stageCount; j++) {
      final stage = row[j];
      final int startIndex = stage['startDateIndex'];
      final int endIndex = stage['endDateIndex'];

      // On Vérifie si l'index est dans la plage de date (match exact)
      if (centerItemIndex >= startIndex && centerItemIndex <= endIndex) {
        return i;
      }

      // Si le stage est après l'index, calculer la distance
      if (startIndex > centerItemIndex) {
        final distance = startIndex - centerItemIndex;
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestRowIndex = i;
        }
        break; // Pas besoin de vérifier les autres stages de cette ligne
      }
    }
  }

  // Si aucun match exact, retourner le stage le plus proche
  // Si aucun stage trouvé du tout, retourner la première ligne
  return nearestRowIndex != -1 ? nearestRowIndex : (rowCount > 0 ? 0 : -1);
}

/// ------
/// Récupère la row qui a le stage/élément le plus bas pour adapter le scroll vertical (optimized)
/// Uses early exit and avoids redundant checks
/// If no exact match is found, returns the row with the nearest previous stage
///
/// [stagesRows]        Tableau des séquences et étapes associés aux élements
/// [centerItemIndex]   Idex de l'item à centrer
/// ------
int getLowerTimelineRowIndexOptimized(List stagesRows, int centerItemIndex) {
  final int rowCount = stagesRows.length;
  int nearestRowIndex = -1;
  int nearestDistance = double.maxFinite.toInt();

  // On parcourt les lignes en ordre inverse
  for (int i = rowCount - 1; i >= 0; i--) {
    final row = stagesRows[i];
    final int stageCount = row.length;

    // On parcourt les stages de chaque ligne en ordre inverse
    for (int j = stageCount - 1; j >= 0; j--) {
      final stage = row[j];
      final int startIndex = stage['startDateIndex'];
      final int endIndex = stage['endDateIndex'];

      // On Vérifie si l'index est dans la plage de date (match exact)
      if (centerItemIndex >= startIndex && centerItemIndex <= endIndex) {
        return i;
      }

      // Si le stage est avant l'index, calculer la distance
      if (endIndex < centerItemIndex) {
        final distance = centerItemIndex - endIndex;
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestRowIndex = i;
        }
        break; // Pas besoin de vérifier les autres stages de cette ligne
      }
    }
  }

  // Si aucun match exact, retourner le stage le plus proche
  // Si aucun stage trouvé du tout, retourner la dernière ligne
  return nearestRowIndex != -1
      ? nearestRowIndex
      : (rowCount > 0 ? rowCount - 1 : -1);
}
