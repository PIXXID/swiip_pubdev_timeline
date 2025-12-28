# Design Document: Timeline Performance Optimization

## Overview

Ce document décrit la conception technique pour optimiser les performances du package Flutter `swiip_pubdev_timeline`. L'approche se concentre sur l'optimisation du rendu des widgets, la réduction des reconstructions inutiles, l'amélioration de la gestion de la mémoire, et l'optimisation des calculs. Les solutions proposées suivent les meilleures pratiques Flutter et utilisent des patterns éprouvés pour les applications performantes.

## Architecture

### Current Architecture Analysis

L'architecture actuelle présente plusieurs points d'amélioration :

**Problèmes identifiés :**
- Tous les Day_Items sont rendus même hors du viewport
- Les listeners de scroll déclenchent des setState() sur l'ensemble du widget
- Les calculs de formatage sont effectués à chaque initState sans cache
- Les Stage_Rows se reconstruisent entièrement lors du scroll
- Pas de séparation entre la logique métier et le rendu UI

**Architecture proposée :**

```
Timeline (StatefulWidget)
├── TimelineController (ChangeNotifier)
│   ├── ScrollState (ValueNotifier)
│   ├── VisibleRange (ValueNotifier)
│   └── CenterItemIndex (ValueNotifier)
├── TimelineDataManager
│   ├── FormattedDays (cached)
│   ├── FormattedStageRows (cached)
│   └── VisibilityCalculator
├── TimelineViewport (Lazy Rendering)
│   ├── DatesSection
│   ├── StagesSection (Viewport-based)
│   └── TimelineSection (Viewport-based)
└── TimelineControls
    ├── Slider
    └── Alerts
```

### Key Architectural Changes

1. **Separation of Concerns**: Séparer la gestion d'état, les calculs de données, et le rendu UI
2. **Lazy Rendering**: Rendre uniquement les éléments visibles + buffer
3. **Granular State Management**: Utiliser ValueNotifier pour des mises à jour localisées
4. **Data Caching**: Mettre en cache les résultats de calculs coûteux
5. **Viewport-based Rendering**: Calculer dynamiquement les éléments à afficher

## Components and Interfaces

### 1. TimelineController

Gère l'état global de la timeline avec des notifications granulaires.

```dart
class TimelineController extends ChangeNotifier {
  // State management avec ValueNotifier pour éviter les rebuilds globaux
  final ValueNotifier<double> scrollOffset = ValueNotifier(0.0);
  final ValueNotifier<int> centerItemIndex = ValueNotifier(0);
  final ValueNotifier<VisibleRange> visibleRange = ValueNotifier(VisibleRange(0, 0));
  
  // Configuration
  final double dayWidth;
  final double dayMargin;
  final int totalDays;
  
  // Throttling pour les calculs
  Timer? _scrollThrottleTimer;
  static const _scrollThrottleDuration = Duration(milliseconds: 16); // ~60 FPS
  
  void updateScrollOffset(double offset) {
    if (_scrollThrottleTimer?.isActive ?? false) return;
    
    _scrollThrottleTimer = Timer(_scrollThrottleDuration, () {
      scrollOffset.value = offset;
      _updateCenterItemIndex();
      _updateVisibleRange();
    });
  }
  
  void _updateCenterItemIndex() {
    final newIndex = (scrollOffset.value / (dayWidth - dayMargin)).round();
    if (newIndex != centerItemIndex.value) {
      centerItemIndex.value = newIndex.clamp(0, totalDays - 1);
    }
  }
  
  void _updateVisibleRange() {
    // Calcule les indices visibles avec buffer
    final screenWidth = /* from context */;
    final visibleDays = (screenWidth / (dayWidth - dayMargin)).ceil();
    final buffer = 5; // Buffer de 5 jours de chaque côté
    
    final start = (centerItemIndex.value - (visibleDays ~/ 2) - buffer).clamp(0, totalDays);
    final end = (centerItemIndex.value + (visibleDays ~/ 2) + buffer).clamp(0, totalDays);
    
    visibleRange.value = VisibleRange(start, end);
  }
  
  @override
  void dispose() {
    _scrollThrottleTimer?.cancel();
    scrollOffset.dispose();
    centerItemIndex.dispose();
    visibleRange.dispose();
    super.dispose();
  }
}

class VisibleRange {
  final int start;
  final int end;
  
  const VisibleRange(this.start, this.end);
  
  bool contains(int index) => index >= start && index <= end;
  
  @override
  bool operator ==(Object other) =>
      other is VisibleRange && other.start == start && other.end == end;
  
  @override
  int get hashCode => Object.hash(start, end);
}
```

### 2. TimelineDataManager

Gère le formatage et le cache des données.

```dart
class TimelineDataManager {
  // Cache des données formatées
  List<Map<String, dynamic>>? _cachedDays;
  List<List<Map<String, dynamic>>>? _cachedStageRows;
  
  // Hash des données d'entrée pour détecter les changements
  int? _lastDataHash;
  
  List<Map<String, dynamic>> getFormattedDays({
    required DateTime startDate,
    required DateTime endDate,
    required List elements,
    required List elementsDone,
    required List capacities,
    required List stages,
    required int maxCapacity,
  }) {
    // Calcule un hash des données d'entrée
    final dataHash = Object.hash(
      startDate,
      endDate,
      elements.length,
      elementsDone.length,
      capacities.length,
      stages.length,
      maxCapacity,
    );
    
    // Retourne le cache si les données n'ont pas changé
    if (_cachedDays != null && dataHash == _lastDataHash) {
      return _cachedDays!;
    }
    
    // Sinon, recalcule et met en cache
    _lastDataHash = dataHash;
    _cachedDays = _formatElementsOptimized(
      startDate,
      endDate,
      elements,
      elementsDone,
      capacities,
      stages,
      maxCapacity,
    );
    
    return _cachedDays!;
  }
  
  List<List<Map<String, dynamic>>> getFormattedStageRows({
    required DateTime startDate,
    required DateTime endDate,
    required List days,
    required List stages,
    required List elements,
  }) {
    // Retourne le cache si disponible
    if (_cachedStageRows != null) {
      return _cachedStageRows!;
    }
    
    // Sinon, calcule et met en cache
    _cachedStageRows = _formatStagesRowsOptimized(
      startDate,
      endDate,
      days,
      stages,
      elements,
    );
    
    return _cachedStageRows!;
  }
  
  // Version optimisée de formatElements
  List<Map<String, dynamic>> _formatElementsOptimized(
    DateTime startDate,
    DateTime endDate,
    List elements,
    List elementsDone,
    List capacities,
    List stages,
    int maxCapacity,
  ) {
    final duration = endDate.difference(startDate).inDays;
    final result = List<Map<String, dynamic>>.generate(
      duration + 1,
      (index) => _createEmptyDay(startDate.add(Duration(days: index)), maxCapacity),
    );
    
    // Créer des maps pour un accès O(1) au lieu de O(n)
    final elementsByDate = <String, List<Map<String, dynamic>>>{};
    final capacitiesByDate = <String, Map<String, dynamic>>{};
    final elementsDoneByDate = <String, List<Map<String, dynamic>>>{};
    
    // Pré-indexer les éléments par date
    for (final element in elements) {
      final date = element['date'] as String;
      elementsByDate.putIfAbsent(date, () => []).add(element);
    }
    
    for (final capacity in capacities) {
      final date = capacity['date'] as String;
      capacitiesByDate[date] = capacity;
    }
    
    for (final element in elementsDone) {
      final date = element['date'] as String;
      elementsDoneByDate.putIfAbsent(date, () => []).add(element);
    }
    
    // Remplir les données pour chaque jour
    for (var i = 0; i <= duration; i++) {
      final date = startDate.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final day = result[i];
      
      // Traiter les éléments du jour
      final dayElements = elementsByDate[dateStr];
      if (dayElements != null) {
        _processElementsForDay(day, dayElements);
      }
      
      // Traiter les éléments terminés
      final dayElementsDone = elementsDoneByDate[dateStr];
      if (dayElementsDone != null) {
        for (final element in dayElementsDone) {
          final preId = element['pre_id'];
          if (!day['preIds'].contains(preId)) {
            day['preIds'].add(preId);
          }
        }
      }
      
      // Traiter les capacités
      final dayCapacity = capacitiesByDate[dateStr];
      if (dayCapacity != null) {
        day['capeff'] = dayCapacity['capeff'] ?? 0;
        day['buseff'] = dayCapacity['buseff'] ?? 0;
        day['compeff'] = dayCapacity['compeff'] ?? 0;
        day['eicon'] = dayCapacity['eicon'];
        
        // Calculer le niveau d'alerte
        final progress = day['capeff'] > 0 
            ? (day['buseff'] / day['capeff']) * 100 
            : 0.0;
        day['alertLevel'] = progress > 100 ? 2 : (progress > 80 ? 1 : 0);
      }
    }
    
    return result;
  }
  
  Map<String, dynamic> _createEmptyDay(DateTime date, int maxCapacity) {
    return {
      'date': date,
      'lmax': maxCapacity,
      'activityTotal': 0,
      'activityCompleted': 0,
      'delivrableTotal': 0,
      'delivrableCompleted': 0,
      'taskTotal': 0,
      'taskCompleted': 0,
      'elementCompleted': 0,
      'elementPending': 0,
      'preIds': <String>[],
      'stage': {},
      'eicon': '',
      'capeff': 0,
      'buseff': 0,
      'compeff': 0,
      'alertLevel': 0,
    };
  }
  
  void _processElementsForDay(Map<String, dynamic> day, List<Map<String, dynamic>> elements) {
    final seenPreIds = <String>{};
    
    for (final element in elements) {
      final preId = element['pre_id'] as String;
      if (seenPreIds.contains(preId)) continue;
      
      seenPreIds.add(preId);
      day['preIds'].add(preId);
      
      // Compter par type
      final nat = element['nat'] as String;
      final status = element['status'] as String;
      
      switch (nat) {
        case 'activity':
          day['activityTotal']++;
          if (status == 'status') day['activityCompleted']++;
          break;
        case 'delivrable':
          day['delivrableTotal']++;
          if (status == 'status') day['delivrableCompleted']++;
          break;
        case 'task':
          day['taskTotal']++;
          if (status == 'status') day['taskCompleted']++;
          break;
      }
      
      // Compter les statuts
      if (status == 'validated' || status == 'finished') {
        day['elementCompleted']++;
      } else if (status == 'pending' || status == 'inprogress') {
        day['elementPending']++;
      }
    }
  }
  
  // Version optimisée de formatStagesRows
  List<List<Map<String, dynamic>>> _formatStagesRowsOptimized(
    DateTime startDate,
    DateTime endDate,
    List days,
    List stages,
    List elements,
  ) {
    // Créer un index des éléments par pre_id pour un accès O(1)
    final elementsByPreId = <String, Map<String, dynamic>>{};
    for (final element in elements) {
      elementsByPreId[element['pre_id']] = element;
    }
    
    final mergedList = <Map<String, dynamic>>[];
    
    // Fusionner stages et éléments
    for (final stage in stages) {
      mergedList.add(stage);
      
      final elmFiltered = stage['elm_filtered'] as List?;
      if (elmFiltered != null) {
        final stageElements = <Map<String, dynamic>>[];
        final seenPreIds = <String>{};
        
        for (final preId in elmFiltered) {
          if (seenPreIds.contains(preId)) continue;
          
          final element = elementsByPreId[preId];
          if (element != null) {
            seenPreIds.add(preId);
            stageElements.add({
              ...element,
              'pcolor': stage['pcolor'],
              'prs_id': stage['prs_id'],
            });
          }
        }
        
        // Trier par date de début
        stageElements.sort((a, b) => 
          (a['sdate'] as String).compareTo(b['sdate'] as String));
        
        mergedList.addAll(stageElements);
      }
    }
    
    // Organiser en lignes sans chevauchement
    return _organizeIntoRows(mergedList, days, startDate);
  }
  
  List<List<Map<String, dynamic>>> _organizeIntoRows(
    List<Map<String, dynamic>> items,
    List days,
    DateTime startDate,
  ) {
    final rows = <List<Map<String, dynamic>>>[];
    var lastStageRowIndex = 0;
    
    for (final item in items) {
      final stageStartDate = DateTime.parse(item['sdate']);
      final stageEndDate = DateTime.parse(item['edate']);
      
      final startDateIndex = days.indexWhere((d) =>
          DateFormat('yyyy-MM-dd').format(d['date']) ==
          DateFormat('yyyy-MM-dd').format(stageStartDate.isBefore(startDate) 
              ? startDate 
              : stageStartDate));
      
      final endDateIndex = days.indexWhere((d) =>
          DateFormat('yyyy-MM-dd').format(d['date']) ==
          DateFormat('yyyy-MM-dd').format(stageEndDate));
      
      if (startDateIndex == -1 || endDateIndex == -1) continue;
      
      final itemWithIndices = {
        ...item,
        'startDateIndex': startDateIndex,
        'endDateIndex': endDateIndex,
      };
      
      final isStage = ['milestone', 'cycle', 'sequence', 'stage']
          .contains(item['type']);
      
      if (rows.isEmpty) {
        rows.add([itemWithIndices]);
      } else {
        var placed = false;
        
        for (var j = lastStageRowIndex; j < rows.length; j++) {
          final hasOverlap = rows[j].any((r) =>
              r['endDateIndex'] + 1 > startDateIndex);
          
          if (!hasOverlap) {
            if (isStage) lastStageRowIndex = j;
            rows[j].add(itemWithIndices);
            placed = true;
            break;
          }
        }
        
        if (!placed) {
          rows.add([itemWithIndices]);
          if (isStage) lastStageRowIndex = rows.length - 1;
        }
      }
    }
    
    return rows;
  }
  
  void clearCache() {
    _cachedDays = null;
    _cachedStageRows = null;
    _lastDataHash = null;
  }
}
```

### 3. LazyTimelineViewport

Rend uniquement les éléments visibles avec un buffer.

```dart
class LazyTimelineViewport extends StatelessWidget {
  final TimelineController controller;
  final List<Map<String, dynamic>> days;
  final double dayWidth;
  final double dayMargin;
  final Widget Function(BuildContext, int) itemBuilder;
  
  const LazyTimelineViewport({
    Key? key,
    required this.controller,
    required this.days,
    required this.dayWidth,
    required this.dayMargin,
    required this.itemBuilder,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VisibleRange>(
      valueListenable: controller.visibleRange,
      builder: (context, range, _) {
        // Calculer la largeur totale pour le positionnement
        final totalWidth = days.length * dayWidth;
        
        // Créer uniquement les widgets visibles
        final visibleWidgets = <Widget>[];
        
        for (var i = range.start; i <= range.end && i < days.length; i++) {
          visibleWidgets.add(
            Positioned(
              left: i * (dayWidth - dayMargin),
              child: itemBuilder(context, i),
            ),
          );
        }
        
        return SizedBox(
          width: totalWidth,
          child: Stack(
            children: visibleWidgets,
          ),
        );
      },
    );
  }
}
```

### 4. OptimizedStageRow

Version optimisée de StageRow avec rebuild conditionnel.

```dart
class OptimizedStageRow extends StatefulWidget {
  final Map<String, Color> colors;
  final List stagesList;
  final ValueNotifier<int> centerItemIndexNotifier;
  final ValueNotifier<VisibleRange> visibleRangeNotifier;
  final double dayWidth;
  final double dayMargin;
  final double height;
  final bool isUniqueProject;
  final Function? openEditStage;
  final Function? openEditElement;
  
  const OptimizedStageRow({
    Key? key,
    required this.colors,
    required this.stagesList,
    required this.centerItemIndexNotifier,
    required this.visibleRangeNotifier,
    required this.dayWidth,
    required this.dayMargin,
    required this.height,
    required this.isUniqueProject,
    this.openEditStage,
    this.openEditElement,
  }) : super(key: key);
  
  @override
  State<OptimizedStageRow> createState() => _OptimizedStageRowState();
}

class _OptimizedStageRowState extends State<OptimizedStageRow> {
  late List<Widget> _cachedStageItems;
  late List<Widget> _cachedLabels;
  int? _lastCenterIndex;
  VisibleRange? _lastVisibleRange;
  
  @override
  void initState() {
    super.initState();
    _buildStageWidgets();
    
    // Écouter les changements avec rebuild conditionnel
    widget.centerItemIndexNotifier.addListener(_onCenterIndexChanged);
    widget.visibleRangeNotifier.addListener(_onVisibleRangeChanged);
  }
  
  @override
  void dispose() {
    widget.centerItemIndexNotifier.removeListener(_onCenterIndexChanged);
    widget.visibleRangeNotifier.removeListener(_onVisibleRangeChanged);
    super.dispose();
  }
  
  void _onCenterIndexChanged() {
    final newIndex = widget.centerItemIndexNotifier.value;
    
    // Rebuild uniquement si le centre affecte cette ligne
    if (_shouldRebuildForCenterChange(newIndex)) {
      setState(() {
        _lastCenterIndex = newIndex;
        _updateLabelsVisibility();
      });
    }
  }
  
  void _onVisibleRangeChanged() {
    final newRange = widget.visibleRangeNotifier.value;
    
    // Rebuild uniquement si la plage visible affecte cette ligne
    if (_shouldRebuildForRangeChange(newRange)) {
      setState(() {
        _lastVisibleRange = newRange;
        _buildStageWidgets();
      });
    }
  }
  
  bool _shouldRebuildForCenterChange(int newIndex) {
    if (_lastCenterIndex == newIndex) return false;
    
    // Vérifier si un stage de cette ligne contient le nouvel index
    return widget.stagesList.any((stage) =>
        stage['startDateIndex'] <= newIndex &&
        stage['endDateIndex'] >= newIndex);
  }
  
  bool _shouldRebuildForRangeChange(VisibleRange newRange) {
    if (_lastVisibleRange == newRange) return false;
    
    // Vérifier si un stage de cette ligne est dans la nouvelle plage
    return widget.stagesList.any((stage) =>
        stage['startDateIndex'] <= newRange.end &&
        stage['endDateIndex'] >= newRange.start);
  }
  
  void _buildStageWidgets() {
    _cachedStageItems = [];
    _cachedLabels = [];
    
    final visibleRange = widget.visibleRangeNotifier.value;
    
    for (final stage in widget.stagesList) {
      final startIndex = stage['startDateIndex'] as int;
      final endIndex = stage['endDateIndex'] as int;
      
      // Rendre uniquement les stages visibles
      if (endIndex < visibleRange.start || startIndex > visibleRange.end) {
        continue;
      }
      
      // Créer le widget du stage
      _cachedStageItems.add(_buildStageItem(stage));
      
      // Créer le label si nécessaire
      if (_shouldShowLabel(stage)) {
        _cachedLabels.add(_buildLabel(stage));
      }
    }
  }
  
  Widget _buildStageItem(Map<String, dynamic> stage) {
    // Construction du StageItem (code existant adapté)
    // ...
    return Container(); // Placeholder
  }
  
  Widget _buildLabel(Map<String, dynamic> stage) {
    // Construction du label (code existant adapté)
    // ...
    return Container(); // Placeholder
  }
  
  bool _shouldShowLabel(Map<String, dynamic> stage) {
    final centerIndex = widget.centerItemIndexNotifier.value;
    final daysWidth = stage['endDateIndex'] - stage['startDateIndex'] + 1;
    final isStage = ['milestone', 'cycle', 'sequence', 'stage']
        .contains(stage['type']);
    
    return !isStage &&
        daysWidth < 4 &&
        stage['startDateIndex'] <= centerIndex &&
        stage['endDateIndex'] >= centerIndex;
  }
  
  void _updateLabelsVisibility() {
    // Mettre à jour uniquement les labels sans reconstruire tous les stages
    _cachedLabels.clear();
    
    for (final stage in widget.stagesList) {
      if (_shouldShowLabel(stage)) {
        _cachedLabels.add(_buildLabel(stage));
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ..._cachedStageItems,
          ..._cachedLabels,
        ],
      ),
    );
  }
}
```

### 5. OptimizedTimelineItem

Version optimisée avec const constructors et RepaintBoundary.

```dart
class OptimizedTimelineItem extends StatelessWidget {
  final Map<String, Color> colors;
  final int index;
  final ValueNotifier<int> centerItemIndexNotifier;
  final int nowIndex;
  final Map<String, dynamic> day;
  final List elements;
  final double dayWidth;
  final double dayMargin;
  final double height;
  final Function? openDayDetail;
  
  const OptimizedTimelineItem({
    Key? key,
    required this.colors,
    required this.index,
    required this.centerItemIndexNotifier,
    required this.nowIndex,
    required this.day,
    required this.elements,
    required this.dayWidth,
    required this.dayMargin,
    required this.height,
    this.openDayDetail,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<int>(
        valueListenable: centerItemIndexNotifier,
        builder: (context, centerIndex, child) {
          // Calculer la couleur du texte basée sur la distance au centre
          final dayTextColor = _calculateDayTextColor(centerIndex);
          
          // Le contenu visuel qui ne change pas peut être dans child
          return _buildDayContent(dayTextColor);
        },
      ),
    );
  }
  
  Color _calculateDayTextColor(int centerIndex) {
    final idxCenter = centerIndex - index;
    
    if (idxCenter == 0) {
      return colors['primaryText']!;
    } else if ((idxCenter >= 1 && idxCenter < 4) ||
        (idxCenter <= -1 && idxCenter > -4)) {
      return colors['secondaryText']!;
    } else if ((idxCenter >= 4 && idxCenter < 6) ||
        (idxCenter <= -4 && idxCenter > -6)) {
      return colors['accent1']!;
    } else {
      return Colors.transparent;
    }
  }
  
  Widget _buildDayContent(Color dayTextColor) {
    // Construction du contenu (barres, icônes, etc.)
    // Utiliser des const constructors où possible
    // ...
    return Container(); // Placeholder
  }
}
```

## Data Models

### VisibleRange Model

```dart
class VisibleRange {
  final int start;
  final int end;
  
  const VisibleRange(this.start, this.end);
  
  bool contains(int index) => index >= start && index <= end;
  
  bool overlaps(int startIndex, int endIndex) =>
      !(endIndex < start || startIndex > end);
  
  int get length => end - start + 1;
  
  @override
  bool operator ==(Object other) =>
      other is VisibleRange && other.start == start && other.end == end;
  
  @override
  int get hashCode => Object.hash(start, end);
  
  @override
  String toString() => 'VisibleRange($start, $end)';
}
```

### TimelineConfiguration Model

```dart
class TimelineConfiguration {
  final double dayWidth;
  final double dayMargin;
  final double datesHeight;
  final double timelineHeight;
  final double rowHeight;
  final double rowMargin;
  final int bufferDays;
  final Duration scrollThrottleDuration;
  final Duration animationDuration;
  
  const TimelineConfiguration({
    this.dayWidth = 45.0,
    this.dayMargin = 5.0,
    this.datesHeight = 65.0,
    this.timelineHeight = 300.0,
    this.rowHeight = 30.0,
    this.rowMargin = 3.0,
    this.bufferDays = 5,
    this.scrollThrottleDuration = const Duration(milliseconds: 16),
    this.animationDuration = const Duration(milliseconds: 220),
  });
  
  TimelineConfiguration copyWith({
    double? dayWidth,
    double? dayMargin,
    double? datesHeight,
    double? timelineHeight,
    double? rowHeight,
    double? rowMargin,
    int? bufferDays,
    Duration? scrollThrottleDuration,
    Duration? animationDuration,
  }) {
    return TimelineConfiguration(
      dayWidth: dayWidth ?? this.dayWidth,
      dayMargin: dayMargin ?? this.dayMargin,
      datesHeight: datesHeight ?? this.datesHeight,
      timelineHeight: timelineHeight ?? this.timelineHeight,
      rowHeight: rowHeight ?? this.rowHeight,
      rowMargin: rowMargin ?? this.rowMargin,
      bufferDays: bufferDays ?? this.bufferDays,
      scrollThrottleDuration: scrollThrottleDuration ?? this.scrollThrottleDuration,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }
}
```

### PerformanceMetrics Model

```dart
class PerformanceMetrics {
  final Duration renderTime;
  final int widgetCount;
  final int rebuildCount;
  final double memoryUsageMB;
  final double averageFPS;
  
  const PerformanceMetrics({
    required this.renderTime,
    required this.widgetCount,
    required this.rebuildCount,
    required this.memoryUsageMB,
    required this.averageFPS,
  });
  
  @override
  String toString() {
    return 'PerformanceMetrics(\n'
        '  renderTime: ${renderTime.inMilliseconds}ms,\n'
        '  widgetCount: $widgetCount,\n'
        '  rebuildCount: $rebuildCount,\n'
        '  memoryUsage: ${memoryUsageMB.toStringAsFixed(2)}MB,\n'
        '  averageFPS: ${averageFPS.toStringAsFixed(1)}\n'
        ')';
  }
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Initial Render Performance
*For any* timeline with more than 100 Day_Items, the initial render time should be less than 500ms.
**Validates: Requirements 1.1**

### Property 2: Selective Widget Rebuilds
*For any* state change (centerItemIndex, scroll position), only widgets that are affected by that specific change should rebuild, and widgets outside the visible viewport should not rebuild.
**Validates: Requirements 1.3, 2.1, 3.1**

### Property 3: Viewport-Based Rendering
*For any* timeline with more than 200 days, the number of rendered Day_Items should equal the visible viewport size plus the configured buffer, not the total number of days.
**Validates: Requirements 3.2, 8.2**

### Property 4: Resource Cleanup
*For any* timeline widget that is disposed, all ScrollControllers, listeners, animation controllers, and timers should be properly disposed and removed to prevent memory leaks.
**Validates: Requirements 3.3, 7.3, 9.5**

### Property 5: Data Caching
*For any* timeline initialization with unchanged input data, the formatElements and formatStagesRows functions should return cached results without recomputation, and position calculations should occur only once.
**Validates: Requirements 4.1, 4.5**

### Property 6: Scroll Throttling
*For any* scroll operation, listener callbacks should be invoked at most 60 times per second (approximately every 16ms), preventing excessive calculations.
**Validates: Requirements 5.1, 7.1**

### Property 7: Conditional Calculations
*For any* state update where the relevant value hasn't changed (centerItemIndex, scroll offset below threshold), the system should skip associated calculations and not trigger rebuilds.
**Validates: Requirements 5.5, 7.2**

### Property 8: Auto-Scroll State Management
*For any* manual scroll by the user, auto-scroll should be disabled, and should only re-enable when the user scrolls to a position where auto-scroll is appropriate.
**Validates: Requirements 5.3**

### Property 9: Stage Row Conditional Rebuild
*For any* centerItemIndex update, a Stage_Row should rebuild only if it contains at least one stage whose date range includes the new centerItemIndex or falls within the visible range.
**Validates: Requirements 2.2**

### Property 10: Slider Isolation
*For any* slider value change, only the slider widget and directly related UI elements should rebuild, not the entire timeline or its Day_Items.
**Validates: Requirements 2.5**

### Property 11: Edge Case Handling
*For any* edge case input (null values, empty lists, dates outside range, invalid indices), the system should handle it gracefully without crashes or exceptions.
**Validates: Requirements 6.4**

### Property 12: Animation Scoping
*For any* animation (progress bars, transitions), only the specific widget being animated should rebuild during the animation, and widgets outside the viewport should not have active animations.
**Validates: Requirements 9.2, 9.3**

### Property 13: Loading Indicators
*For any* operation that takes longer than a defined threshold (e.g., 200ms), a loading indicator should be displayed to the user.
**Validates: Requirements 8.5**

## Error Handling

### Error Scenarios

1. **Null or Empty Data**
   - Handle null elements, stages, capacities gracefully
   - Display appropriate empty state UI
   - Don't crash on missing data fields

2. **Invalid Date Ranges**
   - Validate that endDate >= startDate
   - Handle dates outside the timeline range
   - Clamp indices to valid ranges

3. **Invalid Indices**
   - Clamp centerItemIndex to [0, days.length - 1]
   - Handle negative indices in calculations
   - Validate array access bounds

4. **Scroll Edge Cases**
   - Handle scroll to positions beyond timeline bounds
   - Manage scroll when timeline is empty
   - Handle rapid scroll direction changes

5. **Memory Constraints**
   - Monitor memory usage and warn if excessive
   - Implement fallback for very large datasets
   - Provide configuration to reduce memory footprint

### Error Handling Strategy

```dart
class TimelineErrorHandler {
  static void handleDataError(String context, dynamic error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('Timeline Error [$context]: $error');
      debugPrintStack(stackTrace: stack);
    }
    // Log to analytics in production
  }
  
  static T withErrorHandling<T>(
    String context,
    T Function() operation,
    T fallback,
  ) {
    try {
      return operation();
    } catch (e, stack) {
      handleDataError(context, e, stack);
      return fallback;
    }
  }
  
  static List<Map<String, dynamic>> validateDays(List<Map<String, dynamic>> days) {
    return days.where((day) {
      return day.containsKey('date') && 
             day['date'] is DateTime &&
             day.containsKey('lmax');
    }).toList();
  }
  
  static int clampIndex(int index, int min, int max) {
    return index.clamp(min, max);
  }
  
  static DateTime validateDateRange(DateTime start, DateTime end) {
    if (end.isBefore(start)) {
      throw ArgumentError('End date must be after start date');
    }
    return end;
  }
}
```

## Testing Strategy

### Dual Testing Approach

This feature will use both unit tests and property-based tests to ensure comprehensive coverage:

**Unit Tests** will verify:
- Specific examples of widget behavior
- Edge cases (empty data, null values, boundary conditions)
- Integration between components
- Error handling for specific scenarios
- Code structure requirements (const constructors, RepaintBoundary usage)

**Property-Based Tests** will verify:
- Universal properties across all valid inputs
- Performance characteristics with varying data sizes
- Rebuild behavior across different state changes
- Memory management across widget lifecycles
- Caching behavior with different input combinations

### Property-Based Testing Configuration

**Framework**: Use the `test` package with custom property testing utilities for Flutter, or integrate with `dart_check` for property-based testing.

**Configuration**:
- Minimum 100 iterations per property test
- Each test tagged with: **Feature: timeline-performance-optimization, Property {number}: {property_text}**
- Use generators for:
  - Random timeline data (days, stages, elements)
  - Random scroll positions and ranges
  - Random viewport sizes
  - Random state changes

**Test Generators**:

```dart
// Generator for timeline data
class TimelineDataGenerator {
  static List<Map<String, dynamic>> generateDays(int count) {
    final startDate = DateTime.now();
    return List.generate(count, (i) => {
      'date': startDate.add(Duration(days: i)),
      'lmax': 8,
      'capeff': Random().nextInt(8),
      'buseff': Random().nextInt(8),
      'compeff': Random().nextInt(8),
      'preIds': <String>[],
      'alertLevel': Random().nextInt(3),
    });
  }
  
  static List<Map<String, dynamic>> generateStages(int count, DateTime start, DateTime end) {
    return List.generate(count, (i) {
      final stageStart = start.add(Duration(days: Random().nextInt(30)));
      final stageEnd = stageStart.add(Duration(days: Random().nextInt(20) + 1));
      
      return {
        'prs_id': 'stage_$i',
        'type': ['milestone', 'cycle', 'sequence', 'stage'][Random().nextInt(4)],
        'sdate': DateFormat('yyyy-MM-dd').format(stageStart),
        'edate': DateFormat('yyyy-MM-dd').format(stageEnd),
        'name': 'Stage $i',
        'prog': Random().nextInt(100),
        'elm_filtered': <String>[],
      };
    });
  }
  
  static VisibleRange generateVisibleRange(int maxDays) {
    final start = Random().nextInt(maxDays - 10);
    final end = start + Random().nextInt(20) + 5;
    return VisibleRange(start, end.clamp(0, maxDays - 1));
  }
}

// Generator for state changes
class StateChangeGenerator {
  static int generateCenterIndex(int maxDays) {
    return Random().nextInt(maxDays);
  }
  
  static double generateScrollOffset(double maxOffset) {
    return Random().nextDouble() * maxOffset;
  }
}
```

**Example Property Test Structure**:

```dart
void main() {
  group('Timeline Performance Optimization Properties', () {
    test('Property 1: Initial Render Performance', () async {
      // Feature: timeline-performance-optimization, Property 1: Initial render time < 500ms
      
      for (var i = 0; i < 100; i++) {
        final dayCount = 100 + Random().nextInt(100); // 100-200 days
        final days = TimelineDataGenerator.generateDays(dayCount);
        final stages = TimelineDataGenerator.generateStages(10, 
          days.first['date'], days.last['date']);
        
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          MaterialApp(
            home: Timeline(
              colors: testColors,
              infos: testInfos,
              elements: [],
              elementsDone: [],
              capacities: [],
              stages: stages,
              openDayDetail: null,
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: 'Render time ${stopwatch.elapsedMilliseconds}ms exceeded 500ms for $dayCount days');
      }
    });
    
    test('Property 2: Selective Widget Rebuilds', () {
      // Feature: timeline-performance-optimization, Property 2: Only affected widgets rebuild
      
      for (var i = 0; i < 100; i++) {
        // Test implementation
      }
    });
    
    // Additional property tests...
  });
}
```

### Unit Test Strategy

**Test Categories**:

1. **Widget Structure Tests**
   - Verify const constructors are used
   - Verify RepaintBoundary placement
   - Verify ValueListenableBuilder usage
   - Verify proper key usage

2. **Edge Case Tests**
   - Empty timeline (no days, no stages)
   - Single day timeline
   - Timeline with null data fields
   - Invalid date ranges
   - Negative indices

3. **Integration Tests**
   - Controller and widget interaction
   - Data manager and widget interaction
   - Scroll synchronization
   - Animation coordination

4. **Error Handling Tests**
   - Null data handling
   - Invalid configuration
   - Disposal without initialization
   - Rapid state changes

**Example Unit Test**:

```dart
void main() {
  group('Timeline Widget Structure', () {
    testWidgets('uses const constructors for immutable widgets', (tester) async {
      // Verify const constructors through widget inspection
    });
    
    testWidgets('implements RepaintBoundary for sections', (tester) async {
      await tester.pumpWidget(createTestTimeline());
      
      final repaintBoundaries = find.byType(RepaintBoundary);
      expect(repaintBoundaries, findsAtLeastNWidgets(3),
        reason: 'Should have RepaintBoundary for dates, stages, and timeline sections');
    });
  });
  
  group('Edge Cases', () {
    testWidgets('handles empty timeline gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Timeline(
            width: 800,
            height: 600,
            colors: testColors,
            infos: {},
            elements: [],
            elementsDone: [],
            capacities: [],
            stages: [],
            openDayDetail: null,
          ),
        ),
      );
      
      expect(find.text('Aucune activité'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    
    testWidgets('clamps invalid centerItemIndex', (tester) async {
      final controller = TimelineController(
        dayWidth: 45,
        dayMargin: 5,
        totalDays: 100,
      );
      
      controller.updateScrollOffset(-100); // Negative offset
      expect(controller.centerItemIndex.value, equals(0));
      
      controller.updateScrollOffset(10000); // Beyond max
      expect(controller.centerItemIndex.value, equals(99));
    });
  });
}
```

### Performance Benchmarking

**Benchmark Tests** (separate from unit/property tests):

```dart
void main() {
  group('Performance Benchmarks', () {
    benchmark('Initial render with 100 days', () {
      return TimelineBenchmark.measureInitialRender(dayCount: 100);
    });
    
    benchmark('Initial render with 500 days', () {
      return TimelineBenchmark.measureInitialRender(dayCount: 500);
    });
    
    benchmark('Scroll performance over 100 frames', () {
      return TimelineBenchmark.measureScrollPerformance(frames: 100);
    });
    
    benchmark('Memory usage with 1000 days', () {
      return TimelineBenchmark.measureMemoryUsage(dayCount: 1000);
    });
  });
}
```

### Test Coverage Goals

- **Line Coverage**: Minimum 80%
- **Branch Coverage**: Minimum 75%
- **Property Tests**: All 13 correctness properties
- **Unit Tests**: All edge cases and code structure requirements
- **Integration Tests**: All component interactions
- **Performance Tests**: All performance-critical operations

### Continuous Integration

- Run unit tests on every commit
- Run property tests on every pull request
- Run performance benchmarks weekly
- Track performance metrics over time
- Alert on performance regressions > 10%
