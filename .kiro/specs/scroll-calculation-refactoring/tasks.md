# Implementation Plan: Scroll Calculation Refactoring

## Overview

Ce plan d'implémentation décompose la refactorisation du mécanisme de scroll en tâches discrètes et incrémentales. L'approche consiste à créer d'abord les nouvelles fonctions de calcul pures, puis à refactoriser progressivement le code existant pour utiliser ces fonctions, tout en maintenant la fonctionnalité à chaque étape.

## Tasks

- [x] 1. Créer la classe ScrollState
  - Créer le fichier `lib/src/timeline/models/scroll_state.dart`
  - Définir la classe immutable avec les champs: centerDateIndex, targetVerticalOffset, enableAutoScroll, scrollingLeft
  - Ajouter un constructeur const
  - Ajouter l'export dans `lib/src/timeline/models/models.dart`
  - _Requirements: 1.5_

- [x] 2. Créer les fonctions de calcul pures
  - [x] 2.1 Créer calculateCenterDateIndex()
    - Créer le fichier `lib/src/timeline/scroll_calculations.dart`
    - Implémenter la fonction pure avec la formule: (scrollOffset + viewportWidth/2) / (dayWidth - dayMargin)
    - Ajouter le clamping à [0, totalDays-1]
    - Ajouter les assertions de validation des paramètres
    - Documenter la fonction avec des commentaires détaillés
    - _Requirements: 2.1, 2.2, 2.3_

  - [x] 2.2 Créer calculateTargetVerticalOffset()
    - Implémenter la fonction pure dans `scroll_calculations.dart`
    - Gérer la détection de direction (scrollingLeft)
    - Utiliser getHigherStageRowIndexOptimized() et getLowerStageRowIndexOptimized()
    - Calculer l'offset avec la formule: rowIndex * (rowHeight + rowMargin * 2)
    - Retourner null si aucun stage trouvé
    - Documenter la fonction avec des commentaires détaillés
    - _Requirements: 3.1, 3.2, 3.3_

  - [x] 2.3 Créer shouldEnableAutoScroll()
    - Implémenter la fonction pure dans `scroll_calculations.dart`
    - Implémenter la logique de décision basée sur userScrollOffset et targetVerticalOffset
    - Documenter la fonction avec des commentaires détaillés
    - _Requirements: 3.5_

  - [x] 2.4 Écrire les tests unitaires pour les fonctions de calcul
    - Créer `test/scroll_calculations_test.dart`
    - Tester calculateCenterDateIndex() avec différentes positions
    - Tester calculateTargetVerticalOffset() avec différents dateIndex
    - Tester shouldEnableAutoScroll() avec différentes conditions
    - Vérifier la pureté (pas d'effets de bord)
    - _Requirements: 1.1, 1.2_

- [ ] 3. Créer la fonction d'orchestration _calculateScrollState()
  - [ ] 3.1 Implémenter _calculateScrollState() dans timeline.dart
    - Appeler calculateCenterDateIndex() avec les paramètres appropriés
    - Détecter la direction de scroll (scrollingLeft)
    - Appeler calculateTargetVerticalOffset()
    - Appeler shouldEnableAutoScroll()
    - Retourner un objet ScrollState
    - _Requirements: 1.1, 1.2, 1.5_

  - [ ] 3.2 Écrire un property test pour _calculateScrollState()
    - **Property 1: Pureté des Fonctions de Calcul**
    - **Validates: Requirements 1.1, 1.2, 1.3**
    - Générer des paramètres aléatoires (scrollOffset, viewportWidth, etc.)
    - Appeler _calculateScrollState() 10 fois avec les mêmes paramètres
    - Vérifier que tous les résultats sont identiques
    - Vérifier qu'aucun ScrollController n'a été appelé
    - Run 100 iterations

- [ ] 4. Créer la fonction d'action _applyAutoScroll()
  - [ ] 4.1 Implémenter _applyAutoScroll() dans timeline.dart
    - Prendre un ScrollState en paramètre
    - Vérifier enableAutoScroll avant d'agir
    - Calculer l'offset final (avec vérification de l'espace restant)
    - Appeler _controllerVerticalStages.animateTo()
    - Gérer le flag _isAutoScrolling
    - Réinitialiser userScrollOffset
    - _Requirements: 1.3, 1.4, 3.4_

  - [ ] 4.2 Écrire un property test pour _applyAutoScroll()
    - **Property 4: Indépendance Calcul/Action**
    - **Validates: Requirements 1.4, 5.4**
    - Générer des ScrollState aléatoires
    - Appeler _applyAutoScroll() avec enableAutoScroll=false
    - Vérifier qu'aucun scroll n'est déclenché
    - Appeler avec enableAutoScroll=true
    - Vérifier que le scroll est déclenché uniquement dans ce cas
    - Run 100 iterations

- [ ] 5. Checkpoint - Vérifier que les nouvelles fonctions sont correctes
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Refactoriser le listener de scroll horizontal
  - [ ] 6.1 Simplifier le listener _controllerTimeline
    - Remplacer le calcul inline du centerItemIndex par un appel à _calculateScrollState()
    - Utiliser scrollState.centerDateIndex au lieu du calcul local
    - Remplacer l'appel à _performAutoScroll() par _applyAutoScroll(scrollState)
    - Conserver le debouncing avec Timer
    - Conserver la mise à jour du TimelineController
    - _Requirements: 4.3, 4.4_

  - [ ] 6.2 Extraire la logique de callback dans une fonction séparée
    - Créer _updateCurrentDateCallback(int centerDateIndex)
    - Déplacer la logique de formatage de date et d'appel du callback
    - Appeler depuis le listener
    - _Requirements: 2.5, 6.5_

  - [ ] 6.3 Écrire un property test pour le listener
    - **Property 2: Calcul Correct du DateIndex Central**
    - **Validates: Requirements 2.1, 2.2, 2.3**
    - Générer des positions de scroll aléatoires
    - Simuler le scroll en appelant jumpTo()
    - Vérifier que le centerDateIndex calculé correspond à la formule
    - Vérifier le clamping aux limites
    - Run 100 iterations

- [ ] 7. Supprimer l'ancienne fonction _performAutoScroll()
  - Supprimer la méthode _performAutoScroll() de timeline.dart
  - Vérifier qu'aucune référence ne subsiste
  - _Requirements: 5.1, 5.2_

- [ ] 8. Checkpoint - Vérifier que le scroll fonctionne correctement
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Écrire les property tests pour les formules de calcul
  - [ ] 9.1 Property test pour le calcul du dateIndex
    - **Property 2: Calcul Correct du DateIndex Central**
    - **Validates: Requirements 2.1, 2.2, 2.3**
    - Générer scrollOffset, viewportWidth, dayWidth, dayMargin aléatoires
    - Calculer manuellement: (scrollOffset + viewportWidth/2) / (dayWidth - dayMargin)
    - Appeler calculateCenterDateIndex()
    - Vérifier que les résultats correspondent
    - Run 100 iterations

  - [ ] 9.2 Property test pour le calcul de l'offset vertical
    - **Property 3: Calcul Correct de l'Offset Vertical**
    - **Validates: Requirements 3.1, 3.2, 3.3**
    - Générer dateIndex, stagesRows, rowHeight, rowMargin aléatoires
    - Calculer manuellement: rowIndex * (rowHeight + rowMargin * 2)
    - Appeler calculateTargetVerticalOffset()
    - Vérifier que les résultats correspondent
    - Run 100 iterations

- [ ] 10. Écrire les property tests pour la conservation du comportement
  - [ ] 10.1 Property test pour scrollTo()
    - **Property 5: Conservation du Comportement de Scroll**
    - **Validates: Requirements 6.1**
    - Générer des dateIndex aléatoires
    - Appeler scrollTo(dateIndex)
    - Vérifier que le scroll est appliqué correctement
    - Vérifier que la position finale correspond au dateIndex
    - Run 100 iterations

  - [ ] 10.2 Property test pour l'auto-scroll
    - **Property 5: Conservation du Comportement de Scroll**
    - **Validates: Requirements 6.2**
    - Générer des positions horizontales aléatoires
    - Simuler le scroll horizontal
    - Vérifier que l'auto-scroll vertical se déclenche
    - Vérifier que la position verticale correspond au stage visible
    - Run 100 iterations

  - [ ] 10.3 Property test pour la détection du scroll manuel
    - **Property 7: Détection Correcte du Scroll Manuel**
    - **Validates: Requirements 6.3**
    - Simuler un scroll vertical manuel
    - Vérifier que userScrollOffset est mis à jour
    - Vérifier que l'auto-scroll est désactivé
    - Simuler un scroll horizontal qui devrait réactiver l'auto-scroll
    - Vérifier les conditions de réactivation
    - Run 100 iterations

- [ ] 11. Écrire les property tests pour le callback de date
  - [ ] 11.1 Property test pour updateCurrentDate callback
    - **Property 6: Callback de Date Correct**
    - **Validates: Requirements 2.5, 6.5**
    - Générer des changements de centerDateIndex aléatoires
    - Fournir un mock callback
    - Simuler le scroll
    - Vérifier que le callback est appelé
    - Vérifier le format de la date (YYYY-MM-DD)
    - Vérifier la correspondance avec le dateIndex
    - Run 100 iterations

- [ ] 12. Écrire les tests d'intégration
  - [ ] 12.1 Test d'intégration pour le scroll horizontal natif
    - **Property 7: Scroll Natif**
    - **Validates: Requirements 4.1, 4.3, 4.5**
    - Simuler un geste de scroll horizontal (PointerScrollEvent)
    - Vérifier que le ScrollController gère le scroll nativement
    - Vérifier que la position est mise à jour
    - Vérifier qu'aucune interception n'a lieu

  - [ ] 12.2 Test d'intégration pour le scroll vertical natif
    - **Property 7: Scroll Natif**
    - **Validates: Requirements 4.2, 4.3, 4.5**
    - Simuler un geste de scroll vertical (PointerScrollEvent)
    - Vérifier que le ScrollController gère le scroll nativement
    - Vérifier que la position est mise à jour
    - Vérifier qu'aucune interception n'a lieu

  - [ ] 12.3 Test d'intégration pour le throttling
    - **Validates: Requirements 6.4**
    - Simuler des scrolls rapides successifs
    - Vérifier que le throttling limite les mises à jour
    - Vérifier que la performance est maintenue

- [ ] 13. Checkpoint - Vérifier que tous les tests passent
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 14. Mettre à jour la documentation
  - Mettre à jour les commentaires dans timeline.dart pour décrire la nouvelle architecture
  - Documenter les nouvelles fonctions de calcul dans scroll_calculations.dart
  - Mettre à jour README.md pour expliquer l'architecture de scroll
  - Mettre à jour CONFIGURATION.md si nécessaire
  - Ajouter une entrée dans CHANGELOG.md décrivant la refactorisation
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 15. Tests de régression manuels
  - Tester le scroll horizontal avec la souris
  - Tester le scroll horizontal avec le trackpad
  - Tester le scroll vertical avec la souris
  - Tester le scroll vertical avec le trackpad
  - Tester scrollTo() avec différentes dates
  - Tester l'auto-scroll en scrollant horizontalement
  - Tester la détection du scroll manuel
  - Vérifier que la performance est maintenue
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 16. Checkpoint final - Vérifier que tout fonctionne
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Toutes les tâches sont obligatoires pour une implémentation complète et bien testée
- Chaque tâche référence les exigences spécifiques pour la traçabilité
- Les checkpoints assurent une validation incrémentale
- Les property tests valident les propriétés de correction universelles
- Les tests d'intégration valident les scénarios d'interaction utilisateur
- La refactorisation est progressive pour maintenir la fonctionnalité à chaque étape
- L'ordre d'implémentation permet de tester chaque composant indépendamment avant l'intégration

## Ordre d'Exécution Recommandé

1. **Phase 1: Création des fondations** (Tâches 1-2)
   - Créer les structures de données et fonctions pures
   - Tester unitairement chaque fonction

2. **Phase 2: Orchestration** (Tâches 3-4)
   - Créer les fonctions d'orchestration et d'action
   - Tester l'indépendance calcul/action

3. **Phase 3: Intégration** (Tâches 6-7)
   - Refactoriser le code existant pour utiliser les nouvelles fonctions
   - Supprimer l'ancien code

4. **Phase 4: Validation** (Tâches 9-13)
   - Écrire tous les property tests
   - Écrire les tests d'intégration
   - Vérifier la conservation du comportement

5. **Phase 5: Finalisation** (Tâches 14-16)
   - Mettre à jour la documentation
   - Tests de régression manuels
   - Validation finale

## Estimation

- **Phase 1**: 2-3 heures
- **Phase 2**: 2-3 heures
- **Phase 3**: 1-2 heures
- **Phase 4**: 4-5 heures
- **Phase 5**: 1-2 heures

**Total**: 10-15 heures pour une implémentation complète avec tous les tests
