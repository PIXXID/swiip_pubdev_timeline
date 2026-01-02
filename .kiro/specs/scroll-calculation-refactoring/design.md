# Design Document: Scroll Calculation Refactoring

## Overview

Ce document décrit la refactorisation en profondeur du mécanisme de scroll du widget Timeline. L'objectif principal est de **séparer clairement le calcul des valeurs de scroll du déplacement effectif de la timeline**. 

### Principe Fondamental

**Les fonctions de scroll doivent être pures et calculatoires** :
- Elles **calculent** le dateIndex au centre du viewport
- Elles **calculent** la position de scroll vertical nécessaire
- Elles **ne déplacent PAS** la timeline directement
- Le déplacement est délégué aux mécanismes natifs de Flutter (ScrollController)

Cette approche simplifie le code en éliminant les effets de bord et les dépendances circulaires entre calcul et action.

## Architecture

### Architecture Actuelle (Avant Refactorisation)

```
User Gesture (scroll)
    ↓
Listener onPointerSignal
    ↓
_controllerHorizontal.jumpTo() [DÉPLACEMENT]
    ↓
ScrollController Listener
    ↓
_performAutoScroll() [CALCUL + DÉPLACEMENT]
    ↓
_scrollV() [DÉPLACEMENT]
    ↓
_controllerVerticalStages.animateTo()
```

**Problèmes identifiés :**
- Mélange de calcul et d'action dans les mêmes fonctions
- `_performAutoScroll()` calcule ET déplace
- Difficile à tester (effets de bord)
- Logique de scroll dispersée dans plusieurs méthodes

### Architecture Cible (Après Refactorisation)

```
User Gesture (scroll)
    ↓
ScrollController (gestion native)
    ↓
ScrollController Listener
    ↓
_calculateScrollState() [CALCUL PUR]
    |
    ├─> calculateCenterDateIndex()
    ├─> calculateTargetVerticalOffset()
    └─> shouldEnableAutoScroll()
    ↓
_applyAutoScroll() [ACTION UNIQUEMENT]
    ↓
_controllerVerticalStages.animateTo()
```

**Avantages :**
- Séparation claire calcul/action
- Fonctions pures testables unitairement
- Logique centralisée et compréhensible
- Pas d'effets de bord dans les calculs
- ScrollController gère nativement les gestes

## Components and Interfaces

### Nouvelles Fonctions de Calcul (Pures)

#### 1. `calculateCenterDateIndex()`

Calcule l'index du jour qui doit être au centre du viewport.

```dart
/// Calcule le dateIndex au centre du viewport basé sur la position de scroll
/// 
/// Cette fonction est PURE - elle ne modifie aucun état
/// 
/// Returns: L'index du jour au centre (clamped à [0, totalDays-1])
int calculateCenterDateIndex({
  required double scrollOffset,
  required double viewportWidth,
  required double dayWidth,
  required double dayMargin,
  required int totalDays,
}) {
  final centerPosition = scrollOffset + (viewportWidth / 2);
  final centerIndex = (centerPosition / (dayWidth - dayMargin)).round();
  return centerIndex.clamp(0, totalDays - 1);
}
```

**Validates: Requirements 2.1, 2.2, 2.3**

#### 2. `calculateTargetVerticalOffset()`

Calcule la position de scroll vertical pour un dateIndex donné.

```dart
/// Calcule l'offset vertical pour afficher le stage correspondant au dateIndex
/// 
/// Cette fonction est PURE - elle ne modifie aucun état
/// 
/// Returns: L'offset vertical calculé, ou null si aucun stage trouvé
double? calculateTargetVerticalOffset({
  required int centerDateIndex,
  required List stagesRows,
  required double rowHeight,
  required double rowMargin,
  required bool scrollingLeft,
  required int? previousCenterIndex,
}) {
  // Détermine l'index à utiliser pour la recherche
  final searchIndex = scrollingLeft 
      ? centerDateIndex + 4  // Index à droite pour scroll gauche
      : centerDateIndex - 4; // Index à gauche pour scroll droit
  
  // Trouve la ligne appropriée
  final rowIndex = scrollingLeft
      ? getLowerTimelineRowIndexOptimized(stagesRows, searchIndex)
      : getHigherTimelineRowIndexOptimized(stagesRows, searchIndex);
  
  if (rowIndex == -1) return null;
  
  // Calcule l'offset
  return rowIndex * (rowHeight + (rowMargin * 2));
}
```

**Validates: Requirements 3.1, 3.2, 3.3**

#### 3. `shouldEnableAutoScroll()`

Détermine si l'auto-scroll doit être activé.

```dart
/// Détermine si l'auto-scroll vertical doit être activé
/// 
/// Cette fonction est PURE - elle ne modifie aucun état
/// 
/// Returns: true si l'auto-scroll doit être activé
bool shouldEnableAutoScroll({
  required double? userScrollOffset,
  required double? targetVerticalOffset,
  required double totalRowsHeight,
  required double viewportHeight,
}) {
  // Si pas de target, pas d'auto-scroll
  if (targetVerticalOffset == null) return false;
  
  // Si l'utilisateur n'a pas scrollé manuellement
  if (userScrollOffset == null) return true;
  
  // Si l'utilisateur a scrollé mais le stage visible est plus bas
  return userScrollOffset < targetVerticalOffset;
}
```

**Validates: Requirements 3.4, 3.5**

### Fonction de Calcul Centralisée

#### `_calculateScrollState()`

Fonction centrale qui orchestre tous les calculs.

```dart
/// Calcule l'état complet du scroll basé sur la position actuelle
/// 
/// Cette fonction orchestre tous les calculs de scroll sans modifier l'état
/// 
/// Returns: ScrollState contenant tous les calculs
ScrollState _calculateScrollState({
  required double currentScrollOffset,
  required double previousScrollOffset,
}) {
  // 1. Calcul du dateIndex central
  final centerDateIndex = calculateCenterDateIndex(
    scrollOffset: currentScrollOffset,
    viewportWidth: _timelineController.viewportWidth.value,
    dayWidth: dayWidth,
    dayMargin: dayMargin,
    totalDays: days.length,
  );
  
  // 2. Détection de la direction
  final scrollingLeft = currentScrollOffset < previousScrollOffset;
  
  // 3. Calcul de l'offset vertical cible
  final targetVerticalOffset = calculateTargetVerticalOffset(
    centerDateIndex: centerDateIndex,
    stagesRows: stagesRows,
    rowHeight: rowHeight,
    rowMargin: rowMargin,
    scrollingLeft: scrollingLeft,
    previousCenterIndex: _previousCenterIndex,
  );
  
  // 4. Détermination de l'auto-scroll
  final enableAutoScroll = shouldEnableAutoScroll(
    userScrollOffset: userScrollOffset,
    targetVerticalOffset: targetVerticalOffset,
    totalRowsHeight: (rowHeight + rowMargin) * stagesRows.length,
    viewportHeight: _controllerVerticalStages.hasClients
        ? _controllerVerticalStages.position.viewportDimension
        : timelineHeightContainer,
  );
  
  return ScrollState(
    centerDateIndex: centerDateIndex,
    targetVerticalOffset: targetVerticalOffset,
    enableAutoScroll: enableAutoScroll,
    scrollingLeft: scrollingLeft,
  );
}
```

**Validates: Requirements 1.1, 1.2, 1.5**

### Fonction d'Action (Séparée)

#### `_applyAutoScroll()`

Applique le scroll vertical basé sur les calculs.

```dart
/// Applique le scroll vertical automatique basé sur l'état calculé
/// 
/// Cette fonction APPLIQUE les changements - elle n'est PAS pure
void _applyAutoScroll(ScrollState scrollState) {
  if (!scrollState.enableAutoScroll) return;
  if (scrollState.targetVerticalOffset == null) return;
  if (!_controllerVerticalStages.hasClients) return;
  
  final targetOffset = scrollState.targetVerticalOffset!;
  final maxExtent = _controllerVerticalStages.position.maxScrollExtent;
  
  // Détermine l'offset final
  final finalOffset = (totalRowsHeight - targetOffset > viewportHeight / 2)
      ? targetOffset
      : maxExtent;
  
  // Applique le scroll
  _isAutoScrolling = true;
  _controllerVerticalStages
      .animateTo(
        finalOffset,
        duration: _config.animationDuration,
        curve: Curves.easeInOut,
      )
      .then((_) {
        _isAutoScrolling = false;
      });
  
  // Réinitialise le scroll utilisateur
  userScrollOffset = null;
}
```

**Validates: Requirements 1.3, 1.4**

### Classe de Données pour l'État de Scroll

```dart
/// Représente l'état calculé du scroll
/// 
/// Cette classe est immutable et contient uniquement des données
class ScrollState {
  final int centerDateIndex;
  final double? targetVerticalOffset;
  final bool enableAutoScroll;
  final bool scrollingLeft;
  
  const ScrollState({
    required this.centerDateIndex,
    required this.targetVerticalOffset,
    required this.enableAutoScroll,
    required this.scrollingLeft,
  });
}
```

### Listener de Scroll Simplifié

Le listener du ScrollController devient beaucoup plus simple :

```dart
_controllerHorizontal.addListener(() {
  _performanceMonitor.startOperation('scroll_update');
  
  final currentOffset = _controllerHorizontal.offset;
  final maxScrollExtent = _controllerHorizontal.position.maxScrollExtent;
  
  if (currentOffset >= 0 && currentOffset < maxScrollExtent) {
    // 1. Mise à jour du TimelineController (throttled)
    _timelineController.updateScrollOffset(currentOffset);
    
    // 2. Calcul de l'état de scroll (CALCUL PUR)
    final scrollState = _calculateScrollState(
      currentScrollOffset: currentOffset,
      previousScrollOffset: _previousScrollOffset,
    );
    
    // 3. Vérification si le centre a changé
    if (scrollState.centerDateIndex != _previousCenterIndex) {
      // Annule le timer de debounce précédent
      _verticalScrollDebounceTimer?.cancel();
      
      // Debounce les calculs de scroll vertical
      _verticalScrollDebounceTimer = Timer(
        _verticalScrollDebounceDuration,
        () => _applyAutoScroll(scrollState),
      );
      
      // Mise à jour du callback de date
      _updateCurrentDateCallback(scrollState.centerDateIndex);
      
      // Sauvegarde du centre précédent
      _previousCenterIndex = scrollState.centerDateIndex;
    }
    
    // Sauvegarde de l'offset précédent
    _previousScrollOffset = currentOffset;
  }
  
  _performanceMonitor.endOperation('scroll_update');
});
```

**Validates: Requirements 4.3, 4.4, 5.4**

## Data Models

### ScrollState (Nouveau)

Classe immutable représentant l'état calculé du scroll.

```dart
class ScrollState {
  final int centerDateIndex;
  final double? targetVerticalOffset;
  final bool enableAutoScroll;
  final bool scrollingLeft;
  
  const ScrollState({
    required this.centerDateIndex,
    required this.targetVerticalOffset,
    required this.enableAutoScroll,
    required this.scrollingLeft,
  });
}
```

### Variables d'État Simplifiées

**Variables conservées :**
- `_previousScrollOffset` - Pour détecter la direction
- `_previousCenterIndex` - Pour détecter les changements de centre
- `userScrollOffset` - Pour détecter le scroll manuel
- `_isAutoScrolling` - Pour éviter les conflits

**Variables supprimées :**
- Aucune suppression majeure, mais simplification de l'utilisation

## Correctness Properties

*Une propriété est une caractéristique ou un comportement qui doit être vrai pour toutes les exécutions valides du système - essentiellement, une déclaration formelle de ce que le système doit faire.*

### Property 1: Pureté des Fonctions de Calcul

*Pour toute* fonction de calcul (calculateCenterDateIndex, calculateTargetVerticalOffset, shouldEnableAutoScroll), appeler la fonction plusieurs fois avec les mêmes paramètres doit retourner le même résultat sans modifier aucun état.

**Validates: Requirements 1.1, 1.2, 1.3**

### Property 2: Calcul Correct du DateIndex Central

*Pour toute* position de scroll valide, le dateIndex calculé doit correspondre au jour visuellement centré dans le viewport (formule: (scrollOffset + viewportWidth/2) / (dayWidth - dayMargin)).

**Validates: Requirements 2.1, 2.2, 2.3**

### Property 3: Calcul Correct de l'Offset Vertical

*Pour tout* dateIndex valide, l'offset vertical calculé doit correspondre à la position de la ligne de stage appropriée (formule: rowIndex * (rowHeight + rowMargin * 2)).

**Validates: Requirements 3.1, 3.2, 3.3**

### Property 4: Indépendance Calcul/Action

*Pour toute* séquence d'appels aux fonctions de calcul, aucun déplacement de scroll ne doit être déclenché tant que _applyAutoScroll() n'est pas appelée.

**Validates: Requirements 1.4, 5.4**

### Property 5: Conservation du Comportement de Scroll

*Pour toute* interaction utilisateur (geste, souris, trackpad), le comportement de scroll doit être identique à l'implémentation précédente.

**Validates: Requirements 6.1, 6.2, 6.3, 6.4**

### Property 6: Callback de Date Correct

*Pour tout* changement de centerDateIndex, si le callback updateCurrentDate est fourni, il doit être appelé avec la date au format YYYY-MM-DD correspondant au nouveau centerDateIndex.

**Validates: Requirements 2.5, 6.5**

### Property 7: Détection Correcte du Scroll Manuel

*Pour tout* scroll vertical manuel de l'utilisateur, la variable userScrollOffset doit être mise à jour et l'auto-scroll doit être désactivé jusqu'à ce que les conditions de réactivation soient remplies.

**Validates: Requirements 6.3**

## Error Handling

### Gestion d'Erreurs Préservée

Tous les mécanismes existants sont maintenus :

1. **Index Clamping**: `TimelineErrorHandler.clampIndex()` dans les calculs
2. **Scroll Offset Clamping**: `TimelineErrorHandler.clampScrollOffset()`
3. **Empty Collection Guards**: Vérifications `isEmpty` avant calculs
4. **Mounted Checks**: Vérification avant setState
5. **ScrollController Client Checks**: `hasClients` avant accès

### Nouvelle Gestion d'Erreurs

**Validation des Paramètres de Calcul** :
```dart
int calculateCenterDateIndex({...}) {
  assert(scrollOffset >= 0, 'scrollOffset must be non-negative');
  assert(viewportWidth > 0, 'viewportWidth must be positive');
  assert(dayWidth > dayMargin, 'dayWidth must be greater than dayMargin');
  assert(totalDays > 0, 'totalDays must be positive');
  
  // ... calcul ...
}
```

**Gestion des Cas Limites** :
- `targetVerticalOffset` peut être null (aucun stage trouvé)
- Vérification systématique avant application du scroll
- Retour anticipé si conditions non remplies

## Testing Strategy

### Unit Tests (Nouveaux)

**Tests des Fonctions de Calcul Pures** :

1. **calculateCenterDateIndex()**
   - Test avec différentes positions de scroll
   - Test des cas limites (début, fin de timeline)
   - Test du clamping
   - Vérification de la pureté (pas d'effets de bord)

2. **calculateTargetVerticalOffset()**
   - Test avec différents dateIndex
   - Test de la direction de scroll
   - Test des cas où aucun stage n'est trouvé
   - Vérification de la formule de calcul

3. **shouldEnableAutoScroll()**
   - Test avec userScrollOffset null
   - Test avec userScrollOffset défini
   - Test des conditions de réactivation
   - Vérification de la logique booléenne

### Property-Based Tests

Configuration : Minimum 100 itérations par test, tag format: **Feature: scroll-calculation-refactoring, Property {number}: {property_text}**

**Property 1: Pureté des Fonctions de Calcul**
- Générer des paramètres aléatoires
- Appeler chaque fonction de calcul 10 fois avec les mêmes paramètres
- Vérifier que tous les résultats sont identiques
- Vérifier qu'aucun état n'a été modifié

**Property 2: Calcul Correct du DateIndex Central**
- Générer des positions de scroll aléatoires
- Calculer le dateIndex avec la fonction
- Calculer manuellement avec la formule
- Vérifier que les résultats correspondent

**Property 3: Calcul Correct de l'Offset Vertical**
- Générer des dateIndex aléatoires
- Calculer l'offset avec la fonction
- Calculer manuellement avec la formule
- Vérifier que les résultats correspondent

**Property 4: Indépendance Calcul/Action**
- Générer des séquences d'appels aux fonctions de calcul
- Vérifier qu'aucun scroll n'est déclenché
- Vérifier que les ScrollControllers ne sont pas appelés

**Property 5: Conservation du Comportement de Scroll**
- Simuler des gestes de scroll aléatoires
- Comparer le comportement avec l'implémentation précédente
- Vérifier que les positions finales sont identiques

**Property 6: Callback de Date Correct**
- Générer des changements de centerDateIndex aléatoires
- Vérifier que le callback est appelé
- Vérifier le format de la date (YYYY-MM-DD)
- Vérifier la correspondance avec le dateIndex

**Property 7: Détection Correcte du Scroll Manuel**
- Simuler des scrolls manuels aléatoires
- Vérifier que userScrollOffset est mis à jour
- Vérifier que l'auto-scroll est désactivé
- Vérifier les conditions de réactivation

### Integration Tests

**Tests de Comportement Global** :
- Test du scroll horizontal avec gestes
- Test du scroll vertical avec gestes
- Test de l'auto-scroll suivant la position horizontale
- Test du scrollTo() programmatique
- Test de la détection du scroll manuel

### Tests de Régression

**Vérification de Non-Régression** :
- Tous les tests existants doivent passer
- Comportement identique pour l'utilisateur final
- Performance maintenue ou améliorée

## Implementation Notes

### Ordre d'Implémentation

1. **Créer les fonctions de calcul pures**
   - `calculateCenterDateIndex()`
   - `calculateTargetVerticalOffset()`
   - `shouldEnableAutoScroll()`

2. **Créer la classe ScrollState**
   - Définir la structure immutable
   - Ajouter les constructeurs nécessaires

3. **Créer `_calculateScrollState()`**
   - Orchestrer les fonctions de calcul
   - Retourner un ScrollState

4. **Créer `_applyAutoScroll()`**
   - Extraire la logique d'action de `_performAutoScroll()`
   - Prendre un ScrollState en paramètre

5. **Refactoriser le listener de scroll**
   - Simplifier en utilisant les nouvelles fonctions
   - Séparer clairement calcul et action

6. **Supprimer `_performAutoScroll()`**
   - Remplacer par `_calculateScrollState()` + `_applyAutoScroll()`

7. **Écrire les tests unitaires**
   - Tests des fonctions pures
   - Tests de la classe ScrollState

8. **Écrire les property tests**
   - Implémenter les 7 propriétés

9. **Mettre à jour la documentation**
   - Commenter les nouvelles fonctions
   - Mettre à jour README et CONFIGURATION

### Exemple de Code Avant/Après

**Avant (dans le listener) :**
```dart
_controllerHorizontal.addListener(() {
  // ... code complexe mêlant calcul et action ...
  _performAutoScroll(centerItemIndex, oldScrollOffset); // CALCUL + ACTION
});
```

**Après (dans le listener) :**
```dart
_controllerHorizontal.addListener(() {
  // CALCUL (pur, testable)
  final scrollState = _calculateScrollState(
    currentScrollOffset: currentOffset,
    previousScrollOffset: _previousScrollOffset,
  );
  
  // ACTION (séparée, conditionnelle)
  if (scrollState.centerDateIndex != _previousCenterIndex) {
    _applyAutoScroll(scrollState);
  }
});
```

### Performance Considerations

**Impact Attendu** :
- **Neutre à Positif** : Les calculs sont les mêmes, juste mieux organisés
- **Positif** : Fonctions pures plus faciles à optimiser par le compilateur
- **Positif** : Moins d'effets de bord = moins de rebuilds potentiels
- **Neutre** : Même nombre d'opérations de scroll

**Optimisations Possibles** :
- Mise en cache des résultats de calcul si paramètres identiques
- Parallélisation des calculs indépendants (si nécessaire)

## Migration Path

Cette refactorisation est **interne** et ne change pas l'API publique :

1. Implémenter les nouvelles fonctions en parallèle
2. Écrire les tests pour les nouvelles fonctions
3. Refactoriser progressivement le listener
4. Supprimer l'ancien code une fois validé
5. Mettre à jour la documentation

**Pas de breaking change** pour les utilisateurs du widget.

## Alternatives Considered

### Alternative 1: Garder le Code Actuel

**Rejeté car** :
- Mélange calcul/action difficile à maintenir
- Tests difficiles (effets de bord)
- Logique dispersée

### Alternative 2: Utiliser un State Management Package (Bloc, Riverpod)

**Rejeté car** :
- Overhead inutile pour ce cas d'usage
- Complexité ajoutée
- Dépendance externe

### Alternative 3: Refactorisation Partielle

**Rejeté car** :
- Ne résout pas le problème fondamental
- Laisse du code legacy
- Maintenance future compliquée

## Conclusion

Cette refactorisation simplifie profondément le mécanisme de scroll en séparant clairement les responsabilités :
- **Calcul** : Fonctions pures, testables, sans effets de bord
- **Action** : Fonctions d'application, séparées, conditionnelles

Le code devient plus maintenable, plus testable, et plus compréhensible, tout en conservant exactement le même comportement pour l'utilisateur final.
