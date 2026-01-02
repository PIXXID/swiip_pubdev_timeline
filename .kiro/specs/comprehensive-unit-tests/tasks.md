# Implementation Plan: Suite de Tests Unitaires Complète

## Overview

Ce plan d'implémentation détaille les étapes pour créer une suite complète de tests unitaires couvrant les fonctions critiques du composant Timeline Flutter. L'implémentation suivra une approche incrémentale, en commençant par les utilitaires de test, puis en implémentant les tests par module.

## Tasks

- [x] 1. Créer les utilitaires de test et fixtures
  - Créer la classe RandomDataGenerator pour générer des données aléatoires
  - Créer la classe TestHelpers avec les fonctions d'assertion communes
  - Créer la classe TestFixtures avec les données de test réutilisables
  - _Requirements: Tous les requirements (infrastructure)_

- [ ]* 1.1 Écrire les tests pour RandomDataGenerator
  - Tester que les générateurs produisent des valeurs dans les plages attendues
  - Tester la reproductibilité avec des seeds fixes
  - _Requirements: Infrastructure de test_

- [x] 2. Implémenter les tests de scroll_calculations.dart
  - [x] 2.1 Écrire les tests unitaires pour calculateCenterDateIndex
    - Test avec scroll offset à 0 (début de timeline)
    - Test avec scroll offset au maximum (fin de timeline)
    - Test avec timeline vide (totalDays = 0)
    - Test avec scroll offset négatif (overscroll)
    - Test avec valeurs de boundary exactes
    - _Requirements: 1.2, 1.3, 1.4, 1.5_

  - [ ]* 2.2 Écrire le test de propriété pour center index bounds
    - **Property 1: Center index bounds**
    - **Validates: Requirements 1.1, 10.1**
    - Générer 100 combinaisons aléatoires de scroll offset, viewport width, day dimensions
    - Vérifier que l'index retourné est toujours dans [0, totalDays-1]
    - _Requirements: 1.1, 10.1_

  - [ ]* 2.3 Écrire le test de propriété pour center index monotonicity
    - **Property 2: Center index monotonicity**
    - **Validates: Requirements 1.1**
    - Générer 100 paires de scroll offsets où offset2 > offset1
    - Vérifier que centerIndex2 >= centerIndex1
    - _Requirements: 1.1_

- [x] 3. Checkpoint - Vérifier que les tests de scroll passent
  - Exécuter `flutter test test/scroll_calculations_test.dart`
  - S'assurer que tous les tests passent
  - Vérifier la couverture de code pour scroll_calculations.dart

- [x] 4. Implémenter les tests de timeline_data_manager.dart
  - [x] 4.1 Écrire les tests unitaires pour getFormattedDays
    - Test avec données valides (vérifie structure et contenu)
    - Test avec date range invalide (endDate avant startDate)
    - Test avec éléments vides (retourne liste vide de jours)
    - Test avec éléments null (skip gracefully)
    - _Requirements: 2.3, 2.4_

  - [x] 4.2 Écrire les tests unitaires pour le cache
    - Test clearCache force recomputation
    - Test que deux appels identiques retournent le même résultat
    - Test que des données différentes invalident le cache
    - _Requirements: 2.1, 2.2, 2.5_

  - [x] 4.3 Écrire les tests unitaires pour les méthodes privées
    - Test _createEmptyDay retourne structure correcte
    - Test _processElementsForDay avec éléments dupliqués (pre_ids)
    - Test _processElementsForDay avec différents types (activity, delivrable, task)
    - Test _formatElementsOptimized avec données de capacité
    - _Requirements: 2.7, 2.8_

  - [x] 4.4 Écrire les tests unitaires pour getFormattedTimelineRows
    - Test _organizeIntoRows avec stages overlapping (différentes lignes)
    - Test _organizeIntoRows avec stages non-overlapping (même ligne)
    - Test avec stages ayant des dates hors limites
    - _Requirements: 2.6, 7.3, 7.4_

  - [ ]* 4.5 Écrire les tests de propriété pour le cache
    - **Property 3: Cache consistency**
    - **Validates: Requirements 2.1, 8.1**
    - **Property 4: Cache invalidation**
    - **Validates: Requirements 2.2, 8.2**
    - _Requirements: 2.1, 2.2, 8.1, 8.2_

  - [ ]* 4.6 Écrire les tests de propriété pour le formatage
    - **Property 5: Days list length**
    - **Validates: Requirements 2.4, 10.2**
    - **Property 6: Non-overlapping stages**
    - **Validates: Requirements 2.6, 7.3**
    - **Property 7: Element deduplication**
    - **Validates: Requirements 2.7**
    - **Property 8: Alert level calculation**
    - **Validates: Requirements 2.8, 7.2**
    - _Requirements: 2.4, 2.6, 2.7, 2.8, 7.2, 7.3, 10.2_

- [x] 5. Checkpoint - Vérifier que les tests de data manager passent
  - Exécuter `flutter test test/timeline_data_manager_test.dart`
  - S'assurer que tous les tests passent
  - Vérifier la couverture de code pour timeline_data_manager.dart

- [x] 6. Implémenter les tests de timeline_configuration_manager.dart
  - [x] 6.1 Écrire les tests unitaires pour initialize
    - Test initialize avec file config valide
    - Test initialize appelé deux fois (ignore avec warning)
    - Test initialize avec programmatic config (precedence)
    - Test initialize avec config invalide (uses defaults)
    - _Requirements: 3.1, 3.2, 3.4, 3.5_

  - [x] 6.2 Écrire les tests unitaires pour l'accès à la configuration
    - Test configuration access avant initialize (throws StateError)
    - Test isInitialized retourne false avant initialize
    - Test isInitialized retourne true après initialize
    - _Requirements: 3.3_

  - [x] 6.3 Écrire les tests unitaires pour les utilitaires
    - Test reset() clears singleton instance
    - Test enableDebugMode/disableDebugMode
    - Test toMap() returns correct structure
    - _Requirements: 3.6_

  - [ ]* 6.4 Écrire le test de propriété pour configuration fallback
    - **Property 11: Configuration fallback**
    - **Validates: Requirements 3.5, 4.2, 4.4, 4.5**
    - _Requirements: 3.5, 4.2, 4.4, 4.5_

- [x] 7. Implémenter les tests de configuration_validator.dart
  - [x] 7.1 Écrire les tests unitaires pour validate
    - Test validate avec config null (returns defaults)
    - Test validate avec paramètre manquant (uses default)
    - Test validate avec type invalide (uses default + warning)
    - Test validate avec valeur négative pour paramètre positif
    - Test getDefaultConfiguration retourne tous les paramètres
    - _Requirements: 4.3, 4.4, 4.5_

  - [x] 7.2 Écrire les tests unitaires pour validateParameter
    - Test avec valeur valide (no errors/warnings)
    - Test avec type invalide (warning)
    - Test avec valeur hors range (error)
    - _Requirements: 4.1, 4.2, 4.5_

  - [ ]* 7.3 Écrire les tests de propriété pour la validation
    - **Property 12: Configuration validation completeness**
    - **Validates: Requirements 4.1, 10.3**
    - **Property 13: Range clamping**
    - **Validates: Requirements 4.2**
    - **Property 14: Type validation**
    - **Validates: Requirements 4.5**
    - _Requirements: 4.1, 4.2, 4.5, 10.3_

- [x] 8. Checkpoint - Vérifier que les tests de configuration passent
  - Exécuter `flutter test test/timeline_configuration_manager_test.dart`
  - Exécuter `flutter test test/configuration_validator_test.dart`
  - S'assurer que tous les tests passent
  - Vérifier la couverture de code

- [x] 9. Implémenter les tests de visible_range.dart
  - [x] 9.1 Écrire les tests unitaires pour VisibleRange
    - Test contains avec index au début
    - Test contains avec index à la fin
    - Test contains avec index hors range
    - Test overlaps avec ranges adjacents
    - Test overlaps avec ranges séparés
    - Test length calculation
    - Test equality (== operator)
    - Test hashCode consistency
    - Test toString() format
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

  - [ ]* 9.2 Écrire les tests de propriété pour VisibleRange
    - **Property 15: Contains correctness**
    - **Validates: Requirements 5.1, 5.2**
    - **Property 16: Overlaps correctness**
    - **Validates: Requirements 5.3, 5.4**
    - **Property 17: Length formula**
    - **Validates: Requirements 5.5, 10.4**
    - **Property 18: Equality consistency**
    - **Validates: Requirements 5.6**
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 10.4_

- [x] 10. Implémenter les tests de timeline_error_handler.dart
  - [x] 10.1 Écrire les tests unitaires pour la validation
    - Test validateDateRange avec dates valides (no exception)
    - Test validateDateRange avec endDate avant startDate (throws ArgumentError)
    - Test validateDays filtre les jours invalides
    - Test validateStages filtre les stages invalides
    - Test validateElements filtre les éléments invalides
    - Test isValidList avec liste null, vide, et valide
    - _Requirements: 6.1, 6.2_

  - [x] 10.2 Écrire les tests unitaires pour le clamping
    - Test clampIndex avec index valide (retourne même valeur)
    - Test clampIndex avec index négatif (retourne min)
    - Test clampIndex avec index trop grand (retourne max)
    - Test clampScrollOffset avec offset valide
    - Test clampScrollOffset avec offset négatif
    - Test clampScrollOffset avec offset trop grand
    - _Requirements: 6.3, 6.4, 6.5, 6.6_

  - [x] 10.3 Écrire les tests unitaires pour withErrorHandling
    - Test avec opération réussie (retourne résultat)
    - Test avec opération qui throw (retourne fallback)
    - Test avec différents types de fallback
    - _Requirements: 6.7, 6.8_

  - [x] 10.4 Écrire les tests unitaires pour safeListAccess
    - Test avec index valide (retourne élément)
    - Test avec index négatif (retourne fallback)
    - Test avec index hors limites (retourne fallback)
    - _Requirements: 6.3_

  - [ ]* 10.5 Écrire les tests de propriété pour error handler
    - **Property 19: Date range validation**
    - **Validates: Requirements 6.1**
    - **Property 20: Index clamping correctness**
    - **Validates: Requirements 6.3, 6.4, 6.5, 10.5**
    - **Property 21: Scroll offset clamping**
    - **Validates: Requirements 6.6**
    - **Property 22: Error handling success path**
    - **Validates: Requirements 6.7**
    - **Property 23: Error handling fallback path**
    - **Validates: Requirements 6.8**
    - _Requirements: 6.1, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 10.5_

- [x] 11. Checkpoint - Vérifier que les tests de base passent
  - Exécuter `flutter test test/visible_range_test.dart`
  - Exécuter `flutter test test/timeline_error_handler_test.dart`
  - S'assurer que tous les tests passent
  - Vérifier la couverture de code

- [x] 12. Implémenter les tests de parameter_constraints.dart
  - [x] 12.1 Écrire les tests unitaires pour ParameterConstraints
    - Test rangeString avec min et max
    - Test rangeString avec seulement min
    - Test rangeString avec seulement max
    - Test rangeString sans limites (null)
    - Test isValid avec valeur valide (retourne true)
    - Test isValid avec valeur invalide type (retourne false)
    - Test isValid avec valeur hors range (retourne false)
    - Test que all contient tous les paramètres attendus
    - _Requirements: 4.1, 4.2_

  - [ ]* 12.2 Écrire les tests de propriété pour isValid
    - Tester que isValid retourne true pour toutes valeurs dans range
    - Tester que isValid retourne false pour toutes valeurs hors range
    - _Requirements: 4.1, 4.2_

- [x] 13. Implémenter les tests d'intégration du formatage
  - [x] 13.1 Écrire les tests d'intégration end-to-end
    - Test formatage complet avec données réelles complexes
    - Test formatage avec éléments multiples sur même date
    - Test formatage avec capacités et calcul d'alert levels
    - Test formatage avec stages overlapping et non-overlapping
    - Test formatage avec éléments spanning multiple days
    - Test formatage avec données vides (graceful handling)
    - Test formatage avec données nulles (skip nulls)
    - Test formatage avec dates hors limites timeline
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

  - [ ]* 13.2 Écrire les tests de propriété d'intégration
    - **Property 9: Stage row optimization**
    - **Validates: Requirements 7.4**
    - **Property 10: Multi-day element indices**
    - **Validates: Requirements 7.5**
    - **Property 28: Element aggregation**
    - **Validates: Requirements 7.1**
    - **Property 29: Cache persistence**
    - **Validates: Requirements 8.4**
    - _Requirements: 7.1, 7.4, 7.5, 8.4_

- [ ] 14. Implémenter les tests de performance et edge cases
  - [x] 14.1 Écrire les tests de performance du cache
    - Test cache hit performance (mesurer temps)
    - Test cache miss performance (mesurer temps)
    - Test impact de clearCache
    - Test memory usage avec large datasets (optionnel)
    - _Requirements: 8.1, 8.2, 8.3_

  - [ ]* 14.2 Écrire les tests de propriété pour edge cases
    - **Property 24: Empty list handling**
    - **Validates: Requirements 9.1**
    - **Property 25: Null value handling**
    - **Validates: Requirements 9.2**
    - **Property 26: Boundary date handling**
    - **Validates: Requirements 9.3**
    - **Property 27: Malformed date handling**
    - **Validates: Requirements 9.5**
    - _Requirements: 9.1, 9.2, 9.3, 9.5_

- [x] 15. Checkpoint final - Vérifier toute la suite de tests
  - Exécuter `flutter test` pour tous les tests
  - S'assurer que tous les tests passent (100% success rate)
  - Générer le rapport de couverture avec `flutter test --coverage`
  - Vérifier que la couverture est > 90% pour les fichiers testés
  - Vérifier que toutes les propriétés ont été implémentées

- [x] 16. Documentation et nettoyage
  - Ajouter des commentaires explicatifs dans les tests complexes
  - Créer un README.md dans le dossier test/ expliquant l'organisation
  - Documenter comment exécuter les tests (commandes, tags, etc.)
  - Ajouter des exemples d'utilisation des utilitaires de test
  - _Requirements: Tous (documentation)_

## Notes

- Les tâches marquées avec `*` sont des tests de propriété (property-based tests) et sont optionnelles pour un MVP rapide
- Chaque test de propriété doit exécuter au minimum 100 itérations
- Utiliser `setUp()` et `tearDown()` pour gérer l'état entre les tests
- Pour les tests du ConfigurationManager, utiliser `reset()` dans `tearDown()`
- Les tests doivent être rapides : < 5 secondes pour toute la suite
- Utiliser des seeds fixes pour les générateurs aléatoires pour la reproductibilité
- Chaque propriété doit être annotée avec un tag référençant le design document
- Format du tag : `Feature: comprehensive-unit-tests, Property N: [property name]`
