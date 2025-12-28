# Requirements Document

## Introduction

Cette spécification définit les exigences pour une refactorisation en profondeur du mécanisme de scroll du widget Timeline. L'objectif est de simplifier le code en séparant clairement les responsabilités : les fonctions de scroll doivent se limiter à **calculer** les valeurs (dateIndex au centre, position de scroll vertical) sans déplacer directement la timeline. Le déplacement sera géré par les mécanismes natifs de Flutter (ScrollController).

## Glossary

- **Timeline**: Le widget principal affichant les plannings de projet
- **ScrollController**: Contrôleur Flutter gérant la position de scroll
- **DateIndex**: Index du jour qui doit être positionné au centre du viewport
- **Viewport**: Zone visible de la timeline à l'écran
- **Auto_Scroll**: Comportement de scroll vertical automatique suivant la position horizontale
- **Scroll_Calculation**: Calcul de la position de scroll sans déplacement effectif
- **Gesture_Scroll**: Scroll déclenché par geste utilisateur (souris, trackpad, touch)

## Requirements

### Requirement 1: Séparation des Responsabilités de Scroll

**User Story:** En tant que développeur, je veux séparer le calcul de scroll du déplacement effectif, afin que le code soit plus simple et maintenable.

#### Acceptance Criteria

1. THE Timeline SHALL calculate the dateIndex that should be centered in the viewport based on current scroll position
2. THE Timeline SHALL calculate the vertical scroll position based on the dateIndex without moving the timeline
3. THE Timeline SHALL NOT directly manipulate scroll position in calculation functions
4. THE Timeline SHALL delegate actual scrolling to Flutter's native ScrollController mechanisms
5. THE Timeline SHALL maintain all calculation variables (dateIndex, scroll offsets) as computed values

### Requirement 2: Calcul du DateIndex Central

**User Story:** En tant que développeur, je veux calculer quel dateIndex doit être au centre du viewport, afin de déterminer la date actuellement visible.

#### Acceptance Criteria

1. WHEN the horizontal scroll position changes, THE Timeline SHALL calculate the dateIndex at the viewport center
2. THE Timeline SHALL use the formula: centerDateIndex = (scrollOffset + viewportWidth/2) / (dayWidth - dayMargin)
3. THE Timeline SHALL clamp the calculated dateIndex to valid range [0, days.length-1]
4. THE Timeline SHALL update the TimelineController with the calculated centerDateIndex
5. THE Timeline SHALL trigger updateCurrentDate callback when centerDateIndex changes

### Requirement 3: Calcul du Scroll Vertical Automatique

**User Story:** En tant que développeur, je veux calculer la position de scroll vertical basée sur le dateIndex, afin de positionner l'affichage sur l'élément correspondant.

#### Acceptance Criteria

1. WHEN the centerDateIndex changes, THE Timeline SHALL calculate which stage row should be visible
2. THE Timeline SHALL calculate the vertical scroll offset for the target stage row
3. THE Timeline SHALL use the formula: verticalOffset = rowIndex * (rowHeight + rowMargin * 2)
4. THE Timeline SHALL NOT directly call scroll methods in calculation functions
5. THE Timeline SHALL provide calculated offset to auto-scroll mechanism

### Requirement 4: Gestion des Gestes de Scroll

**User Story:** En tant qu'utilisateur, je veux que le scroll par geste (souris, trackpad) fonctionne naturellement, sans que le code ne redéplace la timeline.

#### Acceptance Criteria

1. WHEN a user performs a horizontal scroll gesture, THE ScrollController SHALL handle the scroll natively
2. WHEN a user performs a vertical scroll gesture, THE ScrollController SHALL handle the scroll natively
3. THE Timeline SHALL listen to scroll position changes via ScrollController listeners
4. THE Timeline SHALL recalculate dateIndex and vertical position based on new scroll offset
5. THE Timeline SHALL NOT intercept or override native scroll behavior

### Requirement 5: Simplification du Code

**User Story:** En tant que développeur, je veux un code simplifié, afin de faciliter la maintenance et réduire les bugs.

#### Acceptance Criteria

1. THE Timeline SHALL remove redundant scroll manipulation code
2. THE Timeline SHALL consolidate scroll calculations into dedicated pure functions
3. THE Timeline SHALL reduce the number of state variables related to scroll
4. THE Timeline SHALL eliminate circular dependencies between scroll state and calculations
5. THE Timeline SHALL maintain clear separation between calculation and action

### Requirement 6: Conservation des Fonctionnalités Existantes

**User Story:** En tant qu'utilisateur, je veux que toutes les fonctionnalités de scroll existantes continuent de fonctionner, afin de ne pas perdre de capacités.

#### Acceptance Criteria

1. THE Timeline SHALL maintain the scrollTo(dateIndex) programmatic scroll functionality
2. THE Timeline SHALL maintain the auto-scroll behavior following horizontal position
3. THE Timeline SHALL maintain the manual vertical scroll detection
4. THE Timeline SHALL maintain the scroll throttling for performance
5. THE Timeline SHALL maintain the updateCurrentDate callback functionality

### Requirement 7: Mise à Jour des Tests

**User Story:** En tant que développeur, je veux des tests mis à jour reflétant la nouvelle architecture, afin de garantir la qualité du code.

#### Acceptance Criteria

1. THE Test_Suite SHALL update tests to verify calculation functions return correct values
2. THE Test_Suite SHALL verify that calculations do not trigger scroll movements
3. THE Test_Suite SHALL maintain test coverage for scroll behavior
4. THE Test_Suite SHALL verify separation between calculation and scroll action
5. THE Test_Suite SHALL test that native scroll gestures work correctly

### Requirement 8: Mise à Jour de la Documentation

**User Story:** En tant que développeur, je veux une documentation à jour, afin de comprendre la nouvelle architecture de scroll.

#### Acceptance Criteria

1. THE Documentation SHALL describe the calculation-based scroll architecture
2. THE Documentation SHALL explain the separation between calculation and action
3. THE Documentation SHALL document all calculation functions and their formulas
4. THE Documentation SHALL update code comments to reflect the new approach
5. THE Documentation SHALL provide examples of how scroll calculations work
