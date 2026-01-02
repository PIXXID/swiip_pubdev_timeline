# Design Document - Suite de Tests Unitaires Complète

## Overview

Ce document décrit la conception d'une suite de tests unitaires complète pour le composant Timeline Flutter. La suite comprendra environ 100+ tests couvrant les calculs de scroll, la gestion des données, la configuration, la validation, et la gestion d'erreurs.

L'approche combine des tests unitaires traditionnels pour des cas spécifiques et des tests basés sur les propriétés (Property-Based Testing) pour valider le comportement sur un large éventail d'entrées générées aléatoirement.

## Architecture

### Structure des Tests

```
test/
├── scroll_calculations_test.dart          # Tests des calculs de scroll
├── timeline_data_manager_test.dart        # Tests du gestionnaire de données
├── timeline_configuration_manager_test.dart # Tests du gestionnaire de configuration
├── configuration_validator_test.dart      # Tests du validateur de configuration
├── visible_range_test.dart                # Tests du modèle VisibleRange
├── timeline_error_handler_test.dart       # Tests du gestionnaire d'erreurs
├── parameter_constraints_test.dart        # Tests des contraintes de paramètres
└── integration/
    ├── data_formatting_integration_test.dart  # Tests d'intégration du formatage
    └── cache_performance_test.dart            # Tests de performance du cache
```

### Frameworks de Test

- **flutter_test**: Framework de test standard Flutter pour les tests unitaires
- **test**: Package Dart pour les tests de base
- **fake_async**: Pour tester le comportement asynchrone et les timers
- **mockito** (optionnel): Pour créer des mocks si nécessaire

### Property-Based Testing

Pour les tests basés sur les propriétés, nous utiliserons une approche manuelle avec des générateurs de données aléatoires, car Dart n'a pas de bibliothèque PBT mature comme QuickCheck ou Hypothesis. Nous créerons des fonctions helper pour générer des données de test aléatoires :

```dart
// Générateurs de données aléatoires
Random randomScrollOffset(int seed);
Random randomViewportDimensions(int seed);
Random randomDateRange(int seed);
Random randomConfiguration(int seed);
```

## Components and Interfaces

### Test Utilities

#### RandomDataGenerator

Classe utilitaire pour générer des données de test aléatoires :

```dart
class RandomDataGenerator {
  final Random _random;
  
  RandomDataGenerator([int? seed]) : _random = Random(seed);
  
  // Génère un scroll offset aléatoire
  double scrollOffset({double min = 0, double max = 10000});
  
  // Génère des dimensions de viewport aléatoires
  double viewportWidth({double min = 300, double max = 2000});
  
  // Génère une plage de dates aléatoire
  DateRange dateRange({int minDays = 1, int maxDays = 365});
  
  // Génère une configuration aléatoire
  Map<String, dynamic> configuration({bool valid = true});
  
  // Génère des éléments de timeline aléatoires
  List<Map<String, dynamic>> timelineElements({int count = 10});
  
  // Génère des stages aléatoires
  List<Map<String, dynamic>> stages({int count = 5});
}
```

#### TestHelpers

Fonctions helper pour les assertions et validations communes :

```dart
class TestHelpers {
  // Vérifie qu'un index est dans les limites
  static void expectIndexInBounds(int index, int min, int max);
  
  // Vérifie qu'une configuration est valide
  static void expectValidConfiguration(Map<String, dynamic> config);
  
  // Vérifie qu'une liste de jours est bien formatée
  static void expectValidDaysList(List<Map<String, dynamic>> days);
  
  // Vérifie qu'aucun stage ne se chevauche dans une ligne
  static void expectNoOverlapsInRow(List<Map<String, dynamic>> row);
}
```

### Test Data Fixtures

Données de test réutilisables pour les tests unitaires :

```dart
class TestFixtures {
  // Configuration valide par défaut
  static Map<String, dynamic> get defaultConfig;
  
  // Configuration invalide avec des valeurs hors limites
  static Map<String, dynamic> get invalidConfig;
  
  // Plage de dates de test standard
  static DateTime get testStartDate;
  static DateTime get testEndDate;
  
  // Éléments de timeline de test
  static List<Map<String, dynamic>> get sampleElements;
  
  // Stages de test
  static List<Map<String, dynamic>> get sampleStages;
  
  // Données de capacité de test
  static List<Map<String, dynamic>> get sampleCapacities;
}
```

## Data Models

### Test Case Models

Pour organiser les tests de manière structurée, nous utiliserons des modèles de cas de test :

```dart
// Cas de test pour calculateCenterDateIndex
class ScrollCalculationTestCase {
  final double scrollOffset;
  final double viewportWidth;
  final double dayWidth;
  final double dayMargin;
  final int totalDays;
  final int expectedIndex;
  final String description;
}

// Cas de test pour la validation de configuration
class ConfigValidationTestCase {
  final Map<String, dynamic> input;
  final Map<String, dynamic> expectedOutput;
  final List<String> expectedErrors;
  final List<String> expectedWarnings;
  final String description;
}

// Cas de test pour le formatage de données
class DataFormattingTestCase {
  final DateTime startDate;
  final DateTime endDate;
  final List<Map<String, dynamic>> elements;
  final List<Map<String, dynamic>> stages;
  final int expectedDaysCount;
  final int expectedRowsCount;
  final String description;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Scroll Calculations Properties

Property 1: Center index bounds
*For any* valid scroll offset, viewport width, day dimensions, and total days, the calculated center index should always be within the valid range [0, totalDays-1]
**Validates: Requirements 1.1, 10.1**

Property 2: Center index monotonicity
*For any* two scroll offsets where offset2 > offset1, if both produce valid indices, then centerIndex2 >= centerIndex1 (scrolling right increases or maintains the center index)
**Validates: Requirements 1.1**

### Data Manager Properties

Property 3: Cache consistency
*For any* input data, calling getFormattedDays twice with identical inputs should return results that are deeply equal (same content)
**Validates: Requirements 2.1, 8.1**

Property 4: Cache invalidation
*For any* two different input datasets, calling getFormattedDays with dataset1 then dataset2 should produce different results
**Validates: Requirements 2.2, 8.2**

Property 5: Days list length
*For any* valid date range, the length of the formatted days list should equal (endDate - startDate).inDays + 1
**Validates: Requirements 2.4, 10.2**

Property 6: Non-overlapping stages
*For any* row in the formatted stage rows, no two stages should have overlapping date ranges (for all pairs of stages in a row, stage1.endDateIndex < stage2.startDateIndex OR stage2.endDateIndex < stage1.startDateIndex)
**Validates: Requirements 2.6, 7.3**

Property 7: Element deduplication
*For any* list of elements with duplicate pre_ids on the same date, each unique pre_id should be counted exactly once in the day's totals
**Validates: Requirements 2.7**

Property 8: Alert level calculation
*For any* day with capacity data, the alert level should be 0 if progress <= 80%, 1 if 80% < progress <= 100%, and 2 if progress > 100%, where progress = (buseff / capeff) * 100
**Validates: Requirements 2.8, 7.2**

Property 9: Stage row optimization
*For any* set of non-overlapping stages, they should be placed in the same row (the number of rows should be minimized)
**Validates: Requirements 7.4**

Property 10: Multi-day element indices
*For any* element spanning multiple days, startDateIndex should correspond to the element's start date and endDateIndex should correspond to the element's end date, both relative to the timeline start date
**Validates: Requirements 7.5**

### Configuration Manager Properties

Property 11: Configuration fallback
*For any* invalid configuration parameter, the system should use the default value from ParameterConstraints
**Validates: Requirements 3.5, 4.2, 4.4, 4.5**

Property 12: Configuration validation completeness
*For any* configuration map (valid or invalid), the validator should produce a configuration with all required parameters present
**Validates: Requirements 4.1, 10.3**

### Validator Properties

Property 13: Range clamping
*For any* numeric parameter value outside its valid range, the validator should replace it with the default value
**Validates: Requirements 4.2**

Property 14: Type validation
*For any* parameter with an incorrect type, the validator should replace it with the default value and generate a warning
**Validates: Requirements 4.5**

### VisibleRange Properties

Property 15: Contains correctness
*For any* VisibleRange(start, end) and index, contains(index) should return true if and only if start <= index <= end
**Validates: Requirements 5.1, 5.2**

Property 16: Overlaps correctness
*For any* VisibleRange(start1, end1) and range (start2, end2), overlaps should return true if and only if NOT (end2 < start1 OR start2 > end1)
**Validates: Requirements 5.3, 5.4**

Property 17: Length formula
*For any* VisibleRange(start, end), the length property should equal (end - start + 1)
**Validates: Requirements 5.5, 10.4**

Property 18: Equality consistency
*For any* two VisibleRange instances with the same start and end values, they should be considered equal (== returns true and hashCode is the same)
**Validates: Requirements 5.6**

### Error Handler Properties

Property 19: Date range validation
*For any* date range where endDate >= startDate, validateDateRange should not throw an exception
**Validates: Requirements 6.1**

Property 20: Index clamping correctness
*For any* index and bounds (min, max), clampIndex should return: index if min <= index <= max, min if index < min, or max if index > max
**Validates: Requirements 6.3, 6.4, 6.5, 10.5**

Property 21: Scroll offset clamping
*For any* scroll offset and maxOffset, clampScrollOffset should return a value in the range [0, maxOffset]
**Validates: Requirements 6.6**

Property 22: Error handling success path
*For any* operation that completes successfully, withErrorHandling should return the operation's result
**Validates: Requirements 6.7**

Property 23: Error handling fallback path
*For any* operation that throws an exception, withErrorHandling should return the provided fallback value
**Validates: Requirements 6.8**

### Edge Cases Properties

Property 24: Empty list handling
*For any* function that processes lists, providing an empty list should not throw an exception and should return a valid result
**Validates: Requirements 9.1**

Property 25: Null value handling
*For any* function that processes data structures, null values in the input should be skipped gracefully without throwing exceptions
**Validates: Requirements 9.2**

Property 26: Boundary date handling
*For any* element with dates outside the timeline range, the system should clamp or skip them appropriately without errors
**Validates: Requirements 9.3**

Property 27: Malformed date handling
*For any* malformed date string, the system should handle the parsing error gracefully and skip the invalid data
**Validates: Requirements 9.5**

### Integration Properties

Property 28: Element aggregation
*For any* date with multiple elements, the day's totals (activityTotal, delivrableTotal, taskTotal) should equal the sum of elements of each type
**Validates: Requirements 7.1**

Property 29: Cache persistence
*For any* cached data, calling getFormattedTimelineRows after getFormattedDays should use the cached stage rows without recomputation
**Validates: Requirements 8.4**

## Error Handling

### Test Error Handling Strategy

Les tests doivent eux-mêmes être robustes et fournir des messages d'erreur clairs :

1. **Assertions descriptives**: Utiliser des messages d'erreur explicites dans les assertions
2. **Test isolation**: Chaque test doit être indépendant et ne pas affecter les autres
3. **Setup/Teardown**: Utiliser setUp() et tearDown() pour initialiser et nettoyer l'état
4. **Error messages**: Inclure le contexte dans les messages d'erreur (valeurs attendues vs réelles)

### Handling Test Failures

Stratégie pour gérer les échecs de tests :

1. **Property test failures**: Lorsqu'un test de propriété échoue, afficher l'entrée qui a causé l'échec
2. **Regression tests**: Créer un test unitaire spécifique pour chaque bug découvert
3. **Flaky tests**: Identifier et corriger les tests instables (utiliser des seeds fixes pour les générateurs aléatoires)

## Testing Strategy

### Dual Testing Approach

Nous utiliserons une approche de test duale combinant :

1. **Unit Tests**: Tests spécifiques avec des exemples concrets
   - Cas limites (empty, null, boundary values)
   - Exemples de régression
   - Cas d'erreur spécifiques

2. **Property-Based Tests**: Tests de propriétés avec génération aléatoire
   - Validation de propriétés universelles
   - Couverture large de l'espace d'entrée
   - Détection de cas limites non anticipés

### Test Organization

#### 1. scroll_calculations_test.dart (≈15 tests)

**Unit Tests** (5 tests):
- Test avec scroll offset à 0 (début)
- Test avec scroll offset au maximum (fin)
- Test avec timeline vide (totalDays = 0)
- Test avec scroll offset négatif (overscroll)
- Test avec valeurs de boundary exactes

**Property Tests** (2 tests, 100 iterations each):
- Property 1: Center index bounds
- Property 2: Center index monotonicity

**Tag format**: `Feature: comprehensive-unit-tests, Property 1: Center index bounds`

#### 2. timeline_data_manager_test.dart (≈25 tests)

**Unit Tests** (10 tests):
- Test getFormattedDays avec données valides
- Test getFormattedDays avec date range invalide
- Test getFormattedDays avec éléments vides
- Test clearCache force recomputation
- Test _createEmptyDay structure
- Test _processElementsForDay avec duplicates
- Test _processElementsForDay avec différents types (activity, delivrable, task)
- Test _formatElementsOptimized avec capacités
- Test _organizeIntoRows avec stages overlapping
- Test _organizeIntoRows avec stages non-overlapping

**Property Tests** (6 tests, 100 iterations each):
- Property 3: Cache consistency
- Property 4: Cache invalidation
- Property 5: Days list length
- Property 6: Non-overlapping stages
- Property 7: Element deduplication
- Property 8: Alert level calculation

#### 3. timeline_configuration_manager_test.dart (≈12 tests)

**Unit Tests** (8 tests):
- Test initialize avec file config valide
- Test initialize appelé deux fois (ignore second call)
- Test configuration access avant initialize (throws StateError)
- Test initialize avec programmatic config (precedence)
- Test initialize avec config invalide (uses defaults)
- Test reset() clears instance
- Test enableDebugMode/disableDebugMode
- Test toMap() returns correct structure

**Property Tests** (1 test, 100 iterations):
- Property 11: Configuration fallback

#### 4. configuration_validator_test.dart (≈15 tests)

**Unit Tests** (5 tests):
- Test validate avec config null (returns defaults)
- Test validate avec paramètre manquant (uses default)
- Test validate avec type invalide (uses default + warning)
- Test validate avec valeur négative pour paramètre positif
- Test validateParameter avec différents types

**Property Tests** (4 tests, 100 iterations each):
- Property 12: Configuration validation completeness
- Property 13: Range clamping
- Property 14: Type validation
- Property 11: Configuration fallback (duplicate from manager tests)

#### 5. visible_range_test.dart (≈12 tests)

**Unit Tests** (4 tests):
- Test contains avec index au début
- Test contains avec index à la fin
- Test overlaps avec ranges adjacents
- Test toString() format

**Property Tests** (4 tests, 100 iterations each):
- Property 15: Contains correctness
- Property 16: Overlaps correctness
- Property 17: Length formula
- Property 18: Equality consistency

#### 6. timeline_error_handler_test.dart (≈18 tests)

**Unit Tests** (8 tests):
- Test validateDateRange avec dates valides
- Test validateDateRange avec endDate avant startDate (throws)
- Test clampIndex avec index valide
- Test clampIndex avec index négatif
- Test clampIndex avec index trop grand
- Test clampScrollOffset avec offset valide
- Test withErrorHandling avec opération réussie
- Test withErrorHandling avec opération qui throw

**Property Tests** (5 tests, 100 iterations each):
- Property 19: Date range validation
- Property 20: Index clamping correctness
- Property 21: Scroll offset clamping
- Property 22: Error handling success path
- Property 23: Error handling fallback path

#### 7. parameter_constraints_test.dart (≈10 tests)

**Unit Tests** (6 tests):
- Test rangeString avec min et max
- Test rangeString avec seulement min
- Test rangeString avec seulement max
- Test rangeString sans limites
- Test isValid avec valeur valide
- Test isValid avec valeur invalide

**Property Tests** (2 tests, 100 iterations each):
- Test isValid retourne true pour toutes valeurs dans range
- Test isValid retourne false pour toutes valeurs hors range

#### 8. data_formatting_integration_test.dart (≈15 tests)

**Integration Tests** (8 tests):
- Test formatage complet avec données réelles
- Test formatage avec éléments multiples même date
- Test formatage avec capacités et alert levels
- Test formatage avec stages overlapping
- Test formatage avec éléments spanning multiple days
- Test formatage avec données vides
- Test formatage avec données nulles
- Test formatage avec dates hors limites

**Property Tests** (4 tests, 100 iterations each):
- Property 9: Stage row optimization
- Property 10: Multi-day element indices
- Property 28: Element aggregation
- Property 29: Cache persistence

#### 9. cache_performance_test.dart (≈8 tests)

**Performance Tests** (4 tests):
- Test cache hit performance (should be fast)
- Test cache miss performance (recomputation)
- Test clearCache impact
- Test memory usage avec large datasets

**Property Tests** (2 tests, 100 iterations each):
- Property 3: Cache consistency (duplicate)
- Property 4: Cache invalidation (duplicate)

**Edge Case Tests** (4 tests):
- Property 24: Empty list handling
- Property 25: Null value handling
- Property 26: Boundary date handling
- Property 27: Malformed date handling

### Test Configuration

Chaque test de propriété doit :
- Exécuter au minimum 100 itérations
- Utiliser un seed fixe pour la reproductibilité (optionnel, peut être randomisé)
- Logger l'entrée qui cause un échec
- Inclure un tag référençant la propriété du design

Format du tag :
```dart
test('Property 1: Center index bounds', () {
  // Feature: comprehensive-unit-tests, Property 1: Center index bounds
  for (int i = 0; i < 100; i++) {
    // Test implementation
  }
}, tags: ['property-test', 'scroll-calculations']);
```

### Coverage Goals

- **Line coverage**: > 90% pour tous les fichiers testés
- **Branch coverage**: > 85% pour la logique conditionnelle
- **Property coverage**: Toutes les propriétés définies doivent avoir au moins un test

### Test Execution

```bash
# Exécuter tous les tests
flutter test

# Exécuter les tests d'un fichier spécifique
flutter test test/scroll_calculations_test.dart

# Exécuter seulement les property tests
flutter test --tags property-test

# Exécuter avec coverage
flutter test --coverage

# Voir le rapport de coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Notes

- Les tests de propriétés utilisent une approche manuelle avec des boucles et des générateurs aléatoires
- Chaque test de propriété doit être reproductible (utiliser des seeds fixes si nécessaire)
- Les tests doivent être rapides (< 5 secondes pour toute la suite)
- Les tests d'intégration peuvent être plus lents mais doivent rester raisonnables (< 30 secondes)
- Utiliser `setUp()` et `tearDown()` pour gérer l'état entre les tests
- Pour les tests du ConfigurationManager, utiliser `reset()` dans tearDown()
