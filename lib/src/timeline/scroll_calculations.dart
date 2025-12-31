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
