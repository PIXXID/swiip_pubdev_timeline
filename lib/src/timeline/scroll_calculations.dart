/// Pure calculation functions for timeline scroll behavior.
///
/// This module contains pure functions that calculate scroll-related values
/// without modifying any state or triggering side effects. These functions
/// are designed to be easily testable and maintainable.
///
/// Key principles:
/// - All functions are pure (same inputs = same outputs)
/// - No side effects (no state modification, no scroll actions)
/// - Calculations are separated from actions
/// - Easy to test in isolation
library;

/// Calcule le dateIndex au centre du viewport basé sur la position de scroll.
///
/// Cette fonction est PURE - elle ne modifie aucun état et ne déclenche aucun
/// effet de bord. Elle calcule simplement quel jour devrait être au centre
/// du viewport en fonction de la position de scroll actuelle.
///
/// La formule utilisée est:
/// ```
/// centerPosition = scrollOffset + (viewportWidth / 2)
/// centerIndex = centerPosition / (dayWidth - dayMargin)
/// ```
///
/// Le scrollOffset représente la position du bord gauche du viewport.
/// On ajoute viewportWidth/2 pour obtenir la position du centre du viewport.
///
/// Le résultat est ensuite clamped à la plage valide [0, totalDays-1].
///
/// ## Paramètres
///
/// - [scrollOffset]: Position actuelle du scroll horizontal (en pixels)
/// - [viewportWidth]: Largeur du viewport visible (en pixels)
/// - [dayWidth]: Largeur d'un jour dans la timeline (en pixels)
/// - [dayMargin]: Marge entre les jours (en pixels)
/// - [totalDays]: Nombre total de jours dans la timeline
///
/// ## Retourne
///
/// L'index du jour qui devrait être au centre du viewport, clamped à [0, totalDays-1].
///
/// ## Exemple
///
/// ```dart
/// final centerIndex = calculateCenterDateIndex(
///   scrollOffset: 1000.0,
///   viewportWidth: 800.0,
///   dayWidth: 45.0,
///   dayMargin: 5.0,
///   totalDays: 100,
/// );
/// // centerIndex sera l'index du jour au centre du viewport
/// ```
///
/// ## Validates
///
/// Requirements 2.1, 2.2, 2.3
int calculateCenterDateIndex({
  required double scrollOffset,
  required double viewportWidth,
  required double dayWidth,
  required double dayMargin,
  required int totalDays,
}) {
  // Validation des paramètres en mode debug
  // Note: scrollOffset can be negative during overscroll/bounce effects
  assert(viewportWidth > 0, 'viewportWidth must be positive');
  assert(dayWidth > dayMargin, 'dayWidth must be greater than dayMargin');
  assert(totalDays >= 0, 'totalDays must be non-negative');

  // Handle empty timeline
  if (totalDays == 0) return 0;

  // Calcul de la position du centre du viewport
  final centerPosition = scrollOffset + (viewportWidth / 2);

  // Calcul de l'index du jour au centre
  final centerIndex = (centerPosition / (dayWidth - dayMargin)).round();

  // Clamp à la plage valide [0, totalDays-1]
  return centerIndex.clamp(0, totalDays - 1);
}

/// Calcule l'offset vertical pour afficher le stage correspondant au dateIndex.
///
/// Cette fonction est PURE - elle ne modifie aucun état et ne déclenche aucun
/// effet de bord. Elle calcule simplement quelle position de scroll vertical
/// devrait être utilisée pour afficher le stage approprié.
///
/// La fonction prend en compte la direction du scroll:
/// - Si on scroll vers la gauche (scrollingLeft = true), on cherche le stage
///   à droite du centre (centerDateIndex + 4)
/// - Si on scroll vers la droite (scrollingLeft = false), on cherche le stage
///   à gauche du centre (centerDateIndex - 4)
///
/// La formule pour calculer l'offset est:
/// ```
/// verticalOffset = rowIndex * (rowHeight + (rowMargin * 2))
/// ```
///
/// ## Paramètres
///
/// - [centerDateIndex]: Index du jour au centre du viewport
/// - [stagesRows]: Liste des lignes de stages (chaque ligne contient des stages)
/// - [rowHeight]: Hauteur d'une ligne de stage (en pixels)
/// - [rowMargin]: Marge autour d'une ligne de stage (en pixels)
/// - [scrollingLeft]: true si on scroll vers la gauche, false sinon
/// - [getHigherStageRowIndex]: Fonction pour trouver la ligne la plus haute
/// - [getLowerStageRowIndex]: Fonction pour trouver la ligne la plus basse
///
/// ## Retourne
///
/// L'offset vertical calculé (en pixels), ou null si aucun stage n'est trouvé.
///
/// ## Exemple
///
/// ```dart
/// final offset = calculateTargetVerticalOffset(
///   centerDateIndex: 50,
///   stagesRows: myStagesRows,
///   rowHeight: 30.0,
///   rowMargin: 3.0,
///   scrollingLeft: false,
///   getHigherStageRowIndex: getHigherStageRowIndexOptimized,
///   getLowerStageRowIndex: getLowerStageRowIndexOptimized,
/// );
/// // offset sera la position de scroll vertical, ou null
/// ```
///
/// ## Validates
///
/// Requirements 3.1, 3.2, 3.3
double? calculateTargetVerticalOffset({
  required int centerDateIndex,
  required List stagesRows,
  required double rowHeight,
  required double rowMargin,
  required bool scrollingLeft,
  required int Function(List, int) getHigherStageRowIndex,
  required int Function(List, int) getLowerStageRowIndex,
}) {
  // Validation des paramètres en mode debug
  assert(centerDateIndex >= 0, 'centerDateIndex must be non-negative');
  assert(rowHeight > 0, 'rowHeight must be positive');
  assert(rowMargin >= 0, 'rowMargin must be non-negative');

  // Guard contre les stages vides
  if (stagesRows.isEmpty) return null;

  // Détermine l'index à utiliser pour la recherche en fonction de la direction
  // +4 ou -4 pour regarder légèrement à côté du centre
  final searchIndex = scrollingLeft
      ? centerDateIndex + 4 // Index à droite pour scroll gauche
      : centerDateIndex - 4; // Index à gauche pour scroll droit

  // Trouve la ligne appropriée en fonction de la direction
  final rowIndex =
      scrollingLeft ? getLowerStageRowIndex(stagesRows, searchIndex) : getHigherStageRowIndex(stagesRows, searchIndex);

  // Si aucune ligne trouvée, retourne null
  if (rowIndex == -1) return null;

  // Calcule l'offset vertical pour cette ligne
  // Formule: rowIndex * (rowHeight + rowMargin * 2)
  return rowIndex * (rowHeight + (rowMargin * 2));
}

/// Détermine si l'auto-scroll vertical doit être activé.
///
/// Cette fonction est PURE - elle ne modifie aucun état et ne déclenche aucun
/// effet de bord. Elle décide simplement si le scroll vertical automatique
/// devrait être activé en fonction de l'état actuel.
///
/// La logique de décision prend en compte la direction du scroll:
/// 1. Si pas de target vertical, pas d'auto-scroll
/// 2. Si l'utilisateur n'a pas scrollé manuellement (userScrollOffset == null),
///    activer l'auto-scroll
/// 3. Si on scroll vers la droite (scrollingLeft = false):
///    - On cherche les stages à gauche (plus hauts dans la liste)
///    - On peut seulement scroller vers le haut (offset plus petit)
///    - Activer si userScrollOffset > targetVerticalOffset
/// 4. Si on scroll vers la gauche (scrollingLeft = true):
///    - On cherche les stages à droite (plus bas dans la liste)
///    - On peut seulement scroller vers le bas (offset plus grand)
///    - Activer si userScrollOffset < targetVerticalOffset
///
/// ## Paramètres
///
/// - [userScrollOffset]: Position de scroll manuel de l'utilisateur (null si pas de scroll manuel)
/// - [targetVerticalOffset]: Position de scroll vertical calculée pour le stage visible
/// - [scrollingLeft]: true si on scroll vers la gauche, false si vers la droite
/// - [totalRowsHeight]: Hauteur totale de toutes les lignes de stages
/// - [viewportHeight]: Hauteur de la zone visible
///
/// ## Retourne
///
/// true si l'auto-scroll doit être activé, false sinon.
///
/// ## Exemple
///
/// ```dart
/// final shouldAutoScroll = shouldEnableAutoScroll(
///   userScrollOffset: null, // Pas de scroll manuel
///   targetVerticalOffset: 150.0,
///   scrollingLeft: false,
///   totalRowsHeight: 1000.0,
///   viewportHeight: 300.0,
/// );
/// // shouldAutoScroll sera true car pas de scroll manuel
/// ```
///
/// ## Validates
///
/// Requirements 3.5
bool shouldEnableAutoScroll({
  required double? userScrollOffset,
  required double? targetVerticalOffset,
  required bool scrollingLeft,
  required double totalRowsHeight,
  required double viewportHeight,
}) {
  // Validation des paramètres en mode debug
  assert(totalRowsHeight >= 0, 'totalRowsHeight must be non-negative');
  assert(viewportHeight > 0, 'viewportHeight must be positive');

  // Si pas de target, pas d'auto-scroll
  if (targetVerticalOffset == null) return false;

  // Si l'utilisateur n'a pas scrollé manuellement, activer l'auto-scroll
  if (userScrollOffset == null) return true;

  // La logique dépend de la direction du scroll:
  // - Scroll vers la droite (scrollingLeft = false): on cherche les stages à gauche (plus hauts)
  //   donc on peut seulement scroller vers le haut (offset plus petit)
  //   -> activer si userScrollOffset > targetVerticalOffset
  // - Scroll vers la gauche (scrollingLeft = true): on cherche les stages à droite (plus bas)
  //   donc on peut seulement scroller vers le bas (offset plus grand)
  //   -> activer si userScrollOffset < targetVerticalOffset
  if (scrollingLeft) {
    // Scroll vers la gauche: on peut seulement scroller vers le bas
    return userScrollOffset < targetVerticalOffset;
  } else {
    // Scroll vers la droite: on peut seulement scroller vers le haut
    return userScrollOffset > targetVerticalOffset;
  }
}
