# Implementation Plan: Timeline Performance Optimization

## Overview

Ce plan d'implémentation transforme la conception en tâches concrètes pour optimiser les performances du package Flutter `swiip_pubdev_timeline`. L'approche est incrémentale : chaque tâche construit sur les précédentes et intègre immédiatement le code dans le système existant. Les tâches sont organisées par domaine d'optimisation, avec des tests de propriétés pour valider la correction à chaque étape.

## Tasks

- [x] 1. Créer les modèles de données et structures de base
  - Créer les fichiers pour VisibleRange, TimelineConfiguration, et PerformanceMetrics
  - Implémenter les modèles avec des méthodes utilitaires (contains, overlaps, copyWith)
  - Ajouter la documentation et les tests unitaires pour les modèles
  - _Requirements: 3.2, 8.4_

- [x] 1.1 Écrire les tests unitaires pour les modèles de données
  - Tester VisibleRange.contains et overlaps
  - Tester TimelineConfiguration.copyWith
  - Tester l'égalité et le hashCode des modèles
  - _Requirements: 3.2, 8.4_

- [x] 2. Implémenter TimelineController avec gestion d'état granulaire
  - [x] 2.1 Créer TimelineController avec ValueNotifiers
    - Implémenter scrollOffset, centerItemIndex, et visibleRange comme ValueNotifiers
    - Ajouter le throttling pour updateScrollOffset avec Timer
    - Implémenter _updateCenterItemIndex et _updateVisibleRange
    - Ajouter la méthode dispose pour nettoyer les ressources
    - _Requirements: 2.3, 5.1, 7.1, 7.3_

  - [x] 2.2 Écrire le test de propriété pour le throttling du scroll
    - **Property 6: Scroll Throttling**
    - **Validates: Requirements 5.1, 7.1**

  - [x] 2.3 Écrire le test de propriété pour le nettoyage des ressources
    - **Property 4: Resource Cleanup**
    - **Validates: Requirements 3.3, 7.3, 9.5**

- [x] 3. Créer TimelineDataManager avec cache
  - [x] 3.1 Implémenter TimelineDataManager
    - Créer les variables de cache (_cachedDays, _cachedStageRows, _lastDataHash)
    - Implémenter getFormattedDays avec détection de changement via hash
    - Implémenter getFormattedStageRows avec cache
    - Ajouter la méthode clearCache
    - _Requirements: 4.1, 4.5_

  - [x] 3.2 Optimiser _formatElementsOptimized
    - Créer des maps pour accès O(1) (elementsByDate, capacitiesByDate)
    - Pré-indexer les éléments par date
    - Utiliser List.generate pour créer les jours
    - Extraire _createEmptyDay et _processElementsForDay
    - _Requirements: 4.1, 4.4_

  - [x] 3.3 Optimiser _formatStagesRowsOptimized
    - Créer un index des éléments par pre_id
    - Utiliser des Sets pour éviter les doublons
    - Optimiser _organizeIntoRows avec recherche efficace
    - _Requirements: 4.1_

  - [x] 3.4 Écrire le test de propriété pour le cache des données
    - **Property 5: Data Caching**
    - **Validates: Requirements 4.1, 4.5**

- [x] 4. Checkpoint - Vérifier les fondations
  - S'assurer que tous les tests passent
  - Vérifier que les modèles et le controller fonctionnent correctement
  - Demander à l'utilisateur si des questions se posent

- [x] 5. Implémenter LazyTimelineViewport pour le rendu lazy
  - [x] 5.1 Créer LazyTimelineViewport widget
    - Implémenter le widget avec ValueListenableBuilder sur visibleRange
    - Calculer les widgets visibles basés sur la plage
    - Utiliser Positioned pour placer les widgets
    - Rendre uniquement les éléments dans la plage visible
    - _Requirements: 3.1, 3.2, 8.2_

  - [x] 5.2 Écrire le test de propriété pour le rendu viewport-based
    - **Property 3: Viewport-Based Rendering**
    - **Validates: Requirements 3.2, 8.2**

- [x] 6. Créer OptimizedTimelineItem avec RepaintBoundary
  - [x] 6.1 Implémenter OptimizedTimelineItem
    - Convertir TimelineItem en StatelessWidget
    - Utiliser ValueListenableBuilder pour centerItemIndex
    - Ajouter RepaintBoundary autour du contenu
    - Extraire _calculateDayTextColor et _buildDayContent
    - Utiliser const constructors où possible
    - _Requirements: 1.4, 1.5, 2.1_

  - [x] 6.2 Écrire le test de propriété pour les rebuilds sélectifs
    - **Property 2: Selective Widget Rebuilds**
    - **Validates: Requirements 1.3, 2.1, 3.1**

  - [x] 6.3 Écrire les tests unitaires pour la structure du widget
    - Vérifier l'utilisation de const constructors
    - Vérifier la présence de RepaintBoundary
    - Vérifier l'utilisation de ValueListenableBuilder
    - _Requirements: 1.4, 1.5, 2.3_

- [x] 7. Implémenter OptimizedStageRow avec rebuild conditionnel
  - [x] 7.1 Créer OptimizedStageRow widget
    - Convertir StageRow pour utiliser ValueNotifiers
    - Implémenter _shouldRebuildForCenterChange et _shouldRebuildForRangeChange
    - Ajouter des listeners avec rebuild conditionnel
    - Cacher les widgets de stage (_cachedStageItems, _cachedLabels)
    - Implémenter _buildStageWidgets et _updateLabelsVisibility
    - _Requirements: 2.2, 2.4_

  - [x] 7.2 Écrire le test de propriété pour le rebuild conditionnel des Stage_Rows
    - **Property 9: Stage Row Conditional Rebuild**
    - **Validates: Requirements 2.2**

- [x] 8. Intégrer TimelineController dans Timeline widget
  - [x] 8.1 Refactoriser Timeline pour utiliser TimelineController
    - Remplacer les variables d'état par TimelineController
    - Utiliser controller.updateScrollOffset dans le listener
    - Remplacer setState par des mises à jour de ValueNotifier
    - Passer les ValueNotifiers aux widgets enfants
    - _Requirements: 2.3, 2.5_

  - [x] 8.2 Écrire le test de propriété pour l'isolation du slider
    - **Property 10: Slider Isolation**
    - **Validates: Requirements 2.5**

- [x] 9. Intégrer TimelineDataManager dans Timeline
  - [x] 9.1 Utiliser TimelineDataManager pour le formatage
    - Créer une instance de TimelineDataManager dans initState
    - Remplacer les appels à formatElements par dataManager.getFormattedDays
    - Remplacer les appels à formatStagesRows par dataManager.getFormattedStageRows
    - Vérifier que le cache fonctionne lors des rebuilds
    - _Requirements: 4.1, 4.5_

  - [x] 9.2 Écrire le test de propriété pour les calculs conditionnels
    - **Property 7: Conditional Calculations**
    - **Validates: Requirements 5.5, 7.2**

- [x] 10. Checkpoint - Vérifier l'intégration
  - S'assurer que tous les tests passent
  - Vérifier que la timeline fonctionne avec les nouveaux composants
  - Tester manuellement le scroll et les interactions
  - Demander à l'utilisateur si des questions se posent

- [x] 11. Implémenter LazyTimelineViewport pour les dates et la timeline
  - [x] 11.1 Intégrer LazyTimelineViewport pour TimelineDayDate
    - Remplacer List.generate par LazyTimelineViewport
    - Passer le controller et les données nécessaires
    - Créer un itemBuilder pour TimelineDayDate
    - _Requirements: 3.1, 3.2_

  - [x] 11.2 Intégrer LazyTimelineViewport pour TimelineItem
    - Remplacer List.generate par LazyTimelineViewport
    - Utiliser OptimizedTimelineItem au lieu de TimelineItem
    - Passer le controller et les données nécessaires
    - _Requirements: 3.1, 3.2_

- [x] 12. Implémenter le rendu viewport-based pour Stage_Rows
  - [x] 12.1 Créer LazyStageRowsViewport
    - Implémenter un widget similaire à LazyTimelineViewport pour les lignes
    - Calculer quelles lignes sont visibles verticalement
    - Rendre uniquement les lignes visibles + buffer
    - Utiliser OptimizedStageRow pour chaque ligne
    - _Requirements: 8.2_

  - [x] 12.2 Intégrer LazyStageRowsViewport dans Timeline
    - Remplacer List.generate des Stage_Rows par LazyStageRowsViewport
    - Passer le controller vertical et les données
    - Ajuster le scroll vertical pour fonctionner avec le lazy loading
    - _Requirements: 8.2_

- [x] 13. Optimiser le scroll automatique avec debouncing
  - [x] 13.1 Implémenter le debouncing dans le scroll listener
    - Ajouter un Timer pour debouncer les calculs de scroll vertical
    - Implémenter la logique de désactivation/réactivation de l'auto-scroll
    - Optimiser getHigherStageRowIndex et getLowerStageRowIndex
    - _Requirements: 5.1, 5.3_

  - [x] 13.2 Écrire le test de propriété pour la gestion de l'auto-scroll
    - **Property 8: Auto-Scroll State Management**
    - **Validates: Requirements 5.3**

- [x] 14. Implémenter la gestion des erreurs
  - [x] 14.1 Créer TimelineErrorHandler
    - Implémenter handleDataError pour le logging
    - Implémenter withErrorHandling pour les opérations à risque
    - Implémenter validateDays, clampIndex, validateDateRange
    - _Requirements: 6.4_

  - [x] 14.2 Intégrer la gestion d'erreurs dans Timeline
    - Entourer les calculs critiques avec withErrorHandling
    - Valider les données d'entrée avec validateDays
    - Utiliser clampIndex pour tous les accès aux tableaux
    - Valider les plages de dates avec validateDateRange
    - _Requirements: 6.4_

  - [x] 14.3 Écrire le test de propriété pour la gestion des cas limites
    - **Property 11: Edge Case Handling**
    - **Validates: Requirements 6.4**

  - [x] 14.4 Écrire les tests unitaires pour les cas limites
    - Tester avec des données nulles ou vides
    - Tester avec des plages de dates invalides
    - Tester avec des indices négatifs
    - Tester avec un scroll au-delà des limites
    - _Requirements: 6.4_

- [x] 15. Checkpoint - Vérifier la robustesse
  - S'assurer que tous les tests passent
  - Tester avec des données invalides et des cas limites
  - Vérifier que les erreurs sont gérées gracieusement
  - Demander à l'utilisateur si des questions se posent

- [x] 16. Optimiser les animations
  - [x] 16.1 Refactoriser les animations avec AnimatedBuilder
    - Identifier les animations dans TimelineItem
    - Remplacer AnimatedContainer par AnimatedBuilder où approprié
    - Utiliser Transform pour les animations de position
    - Ajouter RepaintBoundary autour des widgets animés
    - _Requirements: 9.1, 9.4_

  - [x] 16.2 Implémenter le contrôle des animations par viewport
    - Désactiver les animations pour les widgets hors viewport
    - Créer un AnimationController par widget animé
    - Disposer les controllers proprement
    - _Requirements: 9.3, 9.5_

  - [x] 16.3 Écrire le test de propriété pour le scoping des animations
    - **Property 12: Animation Scoping**
    - **Validates: Requirements 9.2, 9.3**

  - [x] 16.4 Écrire les tests unitaires pour la structure des animations
    - Vérifier l'utilisation d'AnimatedBuilder
    - Vérifier l'utilisation de Transform
    - Vérifier le disposal des AnimationControllers
    - _Requirements: 9.1, 9.4, 9.5_

- [ ] 17. Implémenter les indicateurs de chargement
  - [ ] 17.1 Créer LoadingIndicatorOverlay widget
    - Créer un widget overlay pour afficher un indicateur de chargement
    - Implémenter la logique pour afficher/masquer basée sur un ValueNotifier
    - Ajouter un seuil de temps avant d'afficher (200ms)
    - _Requirements: 8.5_

  - [ ] 17.2 Intégrer les indicateurs dans Timeline
    - Ajouter un ValueNotifier<bool> isLoading dans TimelineController
    - Mesurer le temps des opérations longues (formatage, calculs)
    - Afficher LoadingIndicatorOverlay si l'opération dépasse 200ms
    - _Requirements: 8.5_

  - [ ] 17.3 Écrire le test de propriété pour les indicateurs de chargement
    - **Property 13: Loading Indicators**
    - **Validates: Requirements 8.5**

- [ ] 18. Implémenter le monitoring des performances
  - [ ] 18.1 Créer PerformanceMonitor
    - Implémenter startOperation et endOperation pour mesurer les temps
    - Implémenter trackRebuild pour compter les rebuilds
    - Implémenter getMetrics pour obtenir les métriques
    - Ajouter des hooks de profiling pour le mode développement
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [ ] 18.2 Intégrer PerformanceMonitor dans Timeline
    - Créer une instance de PerformanceMonitor en mode debug
    - Mesurer les temps de rendu initial
    - Mesurer les temps de scroll
    - Logger les métriques en mode debug
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [ ] 18.3 Écrire les tests unitaires pour le monitoring
    - Vérifier que les hooks de profiling existent
    - Vérifier que les logs sont produits en mode debug
    - Vérifier que les métriques sont collectées
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 19. Écrire le test de propriété pour la performance de rendu initial
  - [ ] 19.1 Implémenter le test de propriété pour le rendu initial
    - **Property 1: Initial Render Performance**
    - **Validates: Requirements 1.1**

- [ ] 20. Checkpoint final - Tests et validation
  - S'assurer que tous les tests passent (unitaires et propriétés)
  - Exécuter les tests de performance et vérifier les métriques
  - Tester manuellement avec différentes tailles de données
  - Vérifier qu'il n'y a pas de régressions de fonctionnalités
  - Demander à l'utilisateur si des questions se posent

- [ ] 21. Documentation et nettoyage
  - [ ] 21.1 Documenter les nouvelles APIs
    - Ajouter des commentaires de documentation pour TimelineController
    - Documenter TimelineDataManager et ses méthodes
    - Documenter TimelineConfiguration et ses options
    - Ajouter des exemples d'utilisation dans README
    - _Requirements: 8.4_

  - [ ] 21.2 Nettoyer le code legacy
    - Supprimer les anciennes implémentations non optimisées
    - Nettoyer les imports inutilisés
    - Formater le code selon les conventions Dart
    - Exécuter dart analyze et corriger les warnings
    - _Requirements: 6.2_

  - [ ] 21.3 Mettre à jour les exemples et tests
    - Mettre à jour l'exemple d'utilisation dans lib/run.dart
    - Ajouter des exemples de configuration de performance
    - Documenter les options de tuning des performances
    - _Requirements: 8.4_

## Notes

- Toutes les tâches sont obligatoires pour une approche complète dès le début
- Chaque tâche référence les exigences spécifiques pour la traçabilité
- Les checkpoints assurent une validation incrémentale
- Les tests de propriétés valident les propriétés de correction universelles
- Les tests unitaires valident des exemples spécifiques et des cas limites
- L'approche est incrémentale : chaque tâche s'intègre immédiatement dans le système existant
