import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:defer_pointer/defer_pointer.dart';

// Widgets
import 'timeline_day_date.dart';
import 'timeline_viewport.dart';
import 'timeline_rows_viewport.dart';
import 'timeline_bar_item.dart';
import 'loading_indicator_overlay.dart';

// Models
import 'models/timeline_data_manager.dart';
import 'models/timeline_error_handler.dart';
import 'models/performance_monitor.dart';
import 'models/timeline_configuration.dart';
import 'models/timeline_configuration_manager.dart';
import 'models/configuration_loader.dart';

// Scroll calculations
import 'scroll_calculations.dart';

import 'package:swiip_pubdev_timeline/src/tools/tools.dart';
import 'package:swiip_pubdev_timeline/src/platform/platform_language.dart';

/// A high-performance Flutter timeline/Gantt chart widget for displaying project schedules.
///
/// The Timeline widget provides a scrollable view of project stages, milestones, and activities
/// across a date range. It uses lazy rendering and direct scroll calculations to efficiently
/// handle large datasets (500+ days with 100+ stages).
///
/// ## Features
///
/// - **Native Scrolling**: Uses Flutter's native ScrollController for all scroll management
/// - **Direct Calculations**: Calculates scroll state directly using pure functions
/// - **Lazy Rendering**: Only renders visible items plus a configurable buffer
/// - **Data Caching**: Caches formatted data to avoid redundant calculations
/// - **External Configuration**: Performance tuning via JSON configuration file
///
/// ## Scroll Architecture
///
/// The Timeline uses a simplified scroll architecture that relies entirely on native Flutter
/// ScrollControllers without custom abstraction layers:
///
/// 1. **Native Controllers**: Uses `_controllerHorizontal`
///    for horizontal and vertical scrolling respectively
/// 2. **Direct State Management**: Maintains scroll state in local variables
///    (`_centerItemIndex`, `_visibleStart`, `_visibleEnd`)
/// 3. **Pure Calculation Functions**: Calls pure functions from `scroll_calculations.dart`
///    to calculate center index and visible range
///
/// ## Example
///
/// ```dart
/// Timeline(
///   colors: myColors,
///   infos: {'startDate': '2024-01-01', 'endDate': '2024-12-31'},
///   elements: myElements,
///   elementsDone: [],
///   capacities: [],
///   stages: myStages,
///   openDayDetail: (day) => print('Clicked: ${day['date']}'),
/// )
/// ```
///
/// See also:
/// - [TimelineConfiguration] for performance tuning options
/// - [calculateCenterDateIndex] for center item calculation
class Timeline extends StatefulWidget {
  const Timeline(
      {super.key,
      required this.colors,
      required this.infos,
      required this.elements,
      required this.elementsDone,
      required this.capacities,
      required this.stages,
      this.defaultDate,
      required this.openDayDetail,
      this.openEditStage,
      this.openEditElement,
      this.updateCurrentDate});

  final Map<String, Color> colors;
  final dynamic infos;
  final dynamic elements;
  final dynamic elementsDone;
  final dynamic capacities;
  final dynamic stages;
  final String? defaultDate;
  final Function(String, double?, List<String>?, List<dynamic>?, dynamic)? openDayDetail;
  final Function(String?, String?, String?, String?, String?, double?, String?)? openEditStage;
  final Function(String?, String?, String?, String?, String?, double?, String?)? openEditElement;
  final Function(String?)? updateCurrentDate;

  @override
  State<Timeline> createState() => _Timeline();
}

class _Timeline extends State<Timeline> {
  // Liste des jours formatés
  List days = [];

  // TimelineDataManager for data formatting and caching
  late TimelineDataManager _dataManager;

  // PerformanceMonitor for tracking performance metrics
  late PerformanceMonitor _performanceMonitor;

  // Configuration for timeline
  late TimelineConfiguration _config;

  // Largeur d'un item jour
  double dayWidth = 45.0;
  double dayMargin = 5;
  // Hauteut de la liste des jours
  double datesHeight = 65.0;
  // Hauteur d'une ligne d'étapes
  double rowHeight = 30.0;
  // Marges d'une ligne d'étapes
  double rowMargin = 3.0;
  // Hauteur des barres de la timeline
  double barHeight = 70.0;

  // Diamètre des pins d'alertes
  double alertWidth = 6;

  // Liste des lignes d'étapes
  List stagesRows = [];

  // Date de début et date de fin par défaut
  DateTime now = DateTime.now();
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now().add(const Duration(days: 30));
  int nowIndex = 0;
  int defaultDateIndex = -1;
  bool timelineIsEmpty = false;

  // Controllers for native Flutter scrolling
  // _controllerHorizontal: Manages horizontal scroll through timeline days
  final ScrollController _controllerHorizontal = ScrollController();
  // _controllerVertical: Manages vertical scroll through stage rows
  final ScrollController _controllerVertical = ScrollController();

  // Scroll vertical si l'utilisateur a scrollé à la main
  double? userScrollOffset;

  // Track previous scroll state for direction detection
  int _previousCenterIndex = 0;

  // Native scroll state management (replaces TimelineController)
  // These local variables track the current scroll state:
  // - _centerItemIndex: The day item currently at the center of the viewport
  // - _visibleStart: Start index of the visible range (including buffer)
  // - _visibleEnd: End index of the visible range (including buffer)
  // - _viewportWidth: Current viewport width for calculations
  // - _viewportHeight: Current viewport height for calculations
  //
  // This approach is simpler than using a custom controller class because:
  // 1. State is managed directly in the widget (no extra abstraction)
  // 2. Calculations are performed using pure functions from scroll_calculations.dart
  // 3. Values are passed explicitly to child widgets (no reactive listeners)
  // 4. Easier to understand and maintain
  int _centerItemIndex = 0;
  int _visibleStart = 0;
  int _visibleEnd = 0;
  double _viewportWidth = 0.0;
  double _viewportHeight = 0.0;
  double _viewportMargin = 0.0;

  // ValueNotifier for center item index (used by TimelineBarItem)
  final ValueNotifier<int> _centerItemIndexNotifier = ValueNotifier<int>(0);

  bool isUniqueProject = false;

  // Track initialization state
  bool _isInitialized = false;

  // Initialisation
  @override
  void initState() {
    super.initState();

    // Initialize configuration manager if not already initialized
    if (!TimelineConfigurationManager.isInitialized) {
      // Load configuration asynchronously
      _initializeConfiguration();
    } else {
      // Configuration already initialized, use it
      _config = TimelineConfigurationManager.configuration;
      _initializeTimeline();
      _isInitialized = true;
    }
  }

  /// Initialize configuration asynchronously
  Future<void> _initializeConfiguration() async {
    try {
      debugPrint('Loading timeline configuration...');
      final fileConfig = await ConfigurationLoader.loadConfiguration();

      // Initialize with loaded configuration
      TimelineConfigurationManager.initialize(
        fileConfig: fileConfig,
      );

      debugPrint('Timeline configuration initialized');
    } catch (e) {
      debugPrint('Error loading configuration: $e');
      // Initialize with defaults
      TimelineConfigurationManager.initialize();
    }

    // Get configuration
    _config = TimelineConfigurationManager.configuration;

    // Continue initialization
    if (mounted) {
      setState(() {
        _initializeTimeline();
      });
    }
  } // End of _initializeConfiguration()

  /// Initialize timeline components
  void _initializeTimeline() {
    // Get configuration (widget parameter takes precedence)
    _config = TimelineConfigurationManager.configuration;

    // Initialize PerformanceMonitor (only enabled in debug mode)
    _performanceMonitor = PerformanceMonitor();
    _performanceMonitor.startOperation('timeline_init');

    // Initialize TimelineDataManager
    _dataManager = TimelineDataManager();

    // Reset them to initial values
    _centerItemIndexNotifier.value = 0;

    // Apply configuration values to instance variables
    dayWidth = _config.dayWidth;
    dayMargin = _config.dayMargin;
    datesHeight = _config.datesHeight;
    rowHeight = _config.rowHeight;
    rowMargin = _config.rowMargin;
    barHeight = _config.barHeight;

    // Parse dates from infos if provided
    if (widget.infos['startDate'] != null) {
      startDate = DateTime.parse(widget.infos['startDate']!);
    }
    if (widget.infos['endDate'] != null) {
      endDate = DateTime.parse(widget.infos['endDate']!);
    }

    // Validate date range
    TimelineErrorHandler.withErrorHandling(
      'validateDateRange',
      () => TimelineErrorHandler.validateDateRange(startDate, endDate),
      endDate,
    );

    // Vérifie que la timleline recoit bien des élement
    if (widget.elements == null || widget.elements.isEmpty) {
      // Indique qu'il n'y a pas de données pour cette requete.
      timelineIsEmpty = true;
    }

    // Use TimelineDataManager for formatting with caching and error handling
    _performanceMonitor.startOperation('format_days');
    days = TimelineErrorHandler.withErrorHandling(
      'getFormattedDays',
      () => _dataManager.getFormattedDays(
        startDate: startDate,
        endDate: endDate,
        elements: widget.elements ?? [],
        elementsDone: (widget.elementsDone == null || widget.elementsDone.isEmpty) ? List.empty() : widget.elementsDone,
        capacities: widget.capacities ?? [],
        stages: widget.stages ?? [],
        maxCapacity: widget.infos['lmax'] ?? 0,
      ),
      [], // Fallback to empty list on error
    );
    _performanceMonitor.endOperation('format_days');

    // Use TimelineDataManager for formatting stage rows with caching and error handling
    _performanceMonitor.startOperation('format_stage_rows');
    stagesRows = TimelineErrorHandler.withErrorHandling(
      'getFormattedTimelineRows',
      () => _dataManager.getFormattedTimelineRows(
        startDate: startDate,
        endDate: endDate,
        days: days,
        stages: widget.stages ?? [],
        elements: widget.elements ?? [],
      ),
      [], // Fallback to empty list on error
    );
    _performanceMonitor.endOperation('format_stage_rows');

    // On positionne le stage de la première ligne par jour
    days = getStageByDay(days, stagesRows);

    // Calcule l'index de la date du jour
    nowIndex = now.difference(startDate).inDays;

    // Calcule l'index de la date positionnée par défaut
    if (widget.defaultDate != null) {
      defaultDateIndex = DateTime.parse(widget.defaultDate!).difference(startDate).inDays + 1;
    }

    // Horizontal scroll listener for calculating scroll state and triggering updates
    //
    // This listener implements the native-only scroll architecture:
    // 1. Calculates center index directly using pure function (calculateCenterDateIndex)
    // 2. Calculates visible range inline using formula: visibleDays = ceil(viewportWidth / (dayWidth - dayMargin))
    // 3. Updates local state variables (_centerItemIndex, _visibleStart, _visibleEnd)
    // 4. Only calls setState when values actually change to minimize rebuilds
    // 5. Triggers callbacks and auto-scroll when center item changes
    //
    // Architecture benefits:
    // - No custom controller abstraction layer
    // - Direct use of native ScrollController.offset
    // - Transparent calculation logic
    // - Easy to test and maintain
    //
    // Performance optimizations:
    // - State change detection prevents unnecessary rebuilds
    // - Pure functions enable compiler optimizations
    _controllerHorizontal.addListener(() {
      if (!mounted) return;

      _performanceMonitor.startOperation('scroll_update');

      final currentOffset = _controllerHorizontal.offset;
      final maxScrollExtent = _controllerHorizontal.position.maxScrollExtent;

      if (currentOffset >= 0 && currentOffset < maxScrollExtent) {
        // 1. Calculate center index directly using pure function from scroll_calculations.dart
        // This determines which day item is currently at the center of the viewport
        final newCenterIndex = calculateCenterDateIndex(
          scrollOffset: currentOffset - (_viewportWidth / 2),
          viewportWidth: _viewportWidth,
          dayWidth: dayWidth,
          dayMargin: dayMargin,
          totalDays: days.length,
        );

        // 2. Calculate visible range inline using formula
        // visibleDays = number of days that fit in the viewport
        // buffer = extra days rendered on each side for smooth scrolling
        // This determines which items should be rendered by the lazy viewports
        final visibleDays = (_viewportWidth / (dayWidth - dayMargin)).ceil();
        final buffer = _config.bufferDays;
        final newVisibleStart = (newCenterIndex - (visibleDays ~/ 2) - buffer).clamp(0, days.length);
        final newVisibleEnd = (newCenterIndex + (visibleDays ~/ 2) + buffer).clamp(0, days.length);

        // 3. Update state only when values change (check before setState)
        // This optimization prevents unnecessary rebuilds when scrolling within the same range
        if (newCenterIndex != _centerItemIndex || newVisibleStart != _visibleStart || newVisibleEnd != _visibleEnd) {
          setState(() {
            _centerItemIndex = newCenterIndex;
            _visibleStart = newVisibleStart;
            _visibleEnd = newVisibleEnd;
          });

          // Update ValueNotifier for TimelineBarItem
          _centerItemIndexNotifier.value = newCenterIndex;

          // 4. Trigger callbacks and auto-scroll when center changes
          if (newCenterIndex != _previousCenterIndex) {
            // Update current date callback
            _updateCurrentDateCallback(newCenterIndex);

            // Save previous center index
            _previousCenterIndex = newCenterIndex;
          }
        }
      }

      _performanceMonitor.endOperation('scroll_update');
    });

    // On vérifie si la timeline affiche un ou plusieurs projets
    if (widget.stages.isNotEmpty) {
      Set<String> uniquePrjIds = {};
      for (var item in widget.stages) {
        String? prjId = item['prj_id'];
        if (prjId != null) {
          uniquePrjIds.add(prjId);
        }
      }
      isUniqueProject = uniquePrjIds.length > 1 ? false : true;
    }

    // Affiche l'overlay pendant 100ms minimum
    Future.delayed(const Duration(milliseconds: 100), () {
      // Initialisation OK
      setState(() => _isInitialized = true);

      // Exécuter une seule fois après la construction du widget
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Complete initial render tracking
        _performanceMonitor.endOperation('timeline_init');

        // Log metrics in debug mode
        _performanceMonitor.logMetrics();

        // On scroll sur la date du jour par défaut
        scrollTo(widget.defaultDate != null ? defaultDateIndex : nowIndex, animated: true);
      });
    });
  } // End of _initializeTimeline()

  // Destruction du widget
  @override
  void dispose() {
    // Dispose ValueNotifiers
    _centerItemIndexNotifier.dispose();
    // On enlève les écoutes du scroll de la timeline et vertical
    _controllerHorizontal.removeListener(() {});
    _controllerVertical.dispose();
    super.dispose();
  }

  // Scroll à une date
  void scrollTo(int dateIndex, {bool animated = false}) {
    // Early return if timeline is empty or controller not ready
    if (days.isEmpty || !_controllerHorizontal.hasClients) {
      return;
    }

    // Clamp the index to valid range
    final safeIndex = TimelineErrorHandler.clampIndex(dateIndex, 0, days.length - 1);

    if (safeIndex >= 0) {
      // Calculate the scroll offset to center the specified date
      // The formula is: scroll = dateIndex * (dayWidth - dayMargin) - (viewportWidth / 2)
      // This positions the date at the center of the viewport
      final targetPosition = safeIndex * (dayWidth - dayMargin);
      double scroll = targetPosition;

      // Clamp scroll offset to valid range using ScrollController's maxScrollExtent
      final maxScroll = _controllerHorizontal.position.maxScrollExtent;
      scroll = TimelineErrorHandler.clampScrollOffset(scroll, maxScroll);

      // Scroll using ScrollController directly
      if (animated) {
        _controllerHorizontal.animateTo(
          scroll,
          duration: _config.animationDuration,
          curve: Curves.easeInOut,
        );
      } else {
        _controllerHorizontal.jumpTo(scroll);
      }
    }
  }

  /// Met à jour le callback de date actuelle.
  ///
  /// Cette fonction formate la date correspondant au centerDateIndex
  /// et appelle le callback updateCurrentDate si fourni.
  ///
  /// ## Paramètres
  ///
  /// - [centerDateIndex]: L'index du jour au centre du viewport
  ///
  /// ## Validates
  ///
  /// Requirements 2.5, 6.5
  void _updateCurrentDateCallback(int centerDateIndex) {
    // Vérification: Le callback doit être fourni
    if (widget.updateCurrentDate == null) return;

    // Vérification: La liste des jours ne doit pas être vide
    if (days.isEmpty) return;

    // Clamp l'index pour éviter les erreurs d'accès
    final safeIndex = TimelineErrorHandler.clampIndex(
      centerDateIndex,
      0,
      days.length - 1,
    );

    // Vérification: Le jour doit exister et avoir une date
    if (days[safeIndex] == null || days[safeIndex]['date'] == null) return;

    // Formate la date au format YYYY-MM-DD
    final dayDate = DateFormat('yyyy-MM-dd').format(days[safeIndex]['date']);

    // Appelle le callback
    widget.updateCurrentDate!.call(dayDate);
  }

  @override
  Widget build(BuildContext context) {
    // Track rebuild
    if (_isInitialized) {
      _performanceMonitor.trackRebuild();
    }

    // Langue et locale
    final String lang = platformLanguage();

    // Overlay de chargement - always wrap to handle both initial load and runtime loading
    return Scaffold(
      backgroundColor: widget.colors['primaryBackground'],
      // If not initialized yet, show empty body (overlay will show loading indicator)
      body: !_isInitialized ? LoadingOverlay() : _buildTimelineContent(context, lang),
    );
  }

  /// Builds the timeline content (extracted for clarity)
  Widget _buildTimelineContent(BuildContext context, String lang) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Capture viewport width for scroll calculations
        // This value is used by the scroll listener to calculate:
        // - Center item index (which day is at the center)
        // - Visible range (which days should be rendered)
        // The width is captured here because LayoutBuilder provides the actual
        // available space, which may differ from MediaQuery.of(context).size.width
        _viewportWidth = constraints.maxWidth;
        _viewportHeight = constraints.maxHeight;
        _viewportMargin = (_viewportWidth / 2) - (dayWidth / 2);

        return Stack(
          children: <Widget>[
            Positioned(
              left: _viewportMargin + (dayWidth / 2),
              top: 0,
              child: Container(
                height: _viewportHeight,
                width: 1,
                decoration: BoxDecoration(color: widget.colors['error']),
              ),
            ),
            // CONTENEUR UNIQUE AVEC SCROLL HORIZONTAL
            DeferredPointerHandler(
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    final delta = event.scrollDelta;

                    // Si Shift est pressé, scroll horizontal
                    if (HardwareKeyboard.instance.isShiftPressed) {
                      if (_controllerHorizontal.hasClients) {
                        final newOffset = _controllerHorizontal.position.pixels + delta.dy;
                        _controllerHorizontal.jumpTo(
                          newOffset.clamp(
                            0.0,
                            _controllerHorizontal.position.maxScrollExtent,
                          ),
                        );
                      }
                    }
                    // Si scroll horizontal natif (trackpad)
                    else if (delta.dx != 0) {
                      if (_controllerHorizontal.hasClients) {
                        final newOffset = _controllerHorizontal.position.pixels + delta.dx;
                        _controllerHorizontal.jumpTo(
                          newOffset.clamp(
                            0.0,
                            _controllerHorizontal.position.maxScrollExtent,
                          ),
                        );
                      }
                    }
                    // Sinon, laisser le scroll vertical naturel
                  }
                },
                child: SizedBox(
                  width: _viewportWidth,
                  child: SingleChildScrollView(
                    controller: _controllerHorizontal,
                    scrollDirection: Axis.horizontal,
                    // Padding pour que le 1er element soit au milieu de l'écran
                    padding: EdgeInsets.symmetric(horizontal: _viewportMargin),
                    child: SizedBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // Prevent Column from expanding infinitely
                        children: [
                          // DATES
                          SizedBox(
                            width: days.length * (dayWidth),
                            height: 70,
                            child: days.isNotEmpty
                                ? TimelineViewport(
                                    // Pass calculated visible range directly as parameters
                                    // instead of using a controller with ValueNotifiers
                                    visibleStart: _visibleStart,
                                    visibleEnd: _visibleEnd,
                                    // Pass center index for highlighting
                                    centerItemIndex: _centerItemIndex,
                                    items: days,
                                    itemWidth: dayWidth,
                                    itemMargin: dayMargin,
                                    itemBuilder: (context, index) {
                                      return TimelineDayDate(
                                        lang: lang,
                                        colors: widget.colors,
                                        nowIndex: nowIndex,
                                        index: index,
                                        centerItemIndex: _centerItemIndex,
                                        days: days,
                                        dayWidth: dayWidth,
                                        dayMargin: dayMargin,
                                        height: datesHeight,
                                      );
                                    },
                                  )
                                : const SizedBox.shrink(), // Handle empty days
                          ),
                          // STAGES/ELEMENTS DYNAMIQUES - Use Expanded to take remaining space
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _controllerVertical,
                              scrollDirection: Axis.vertical,
                              child: SizedBox(
                                  child: stagesRows.isNotEmpty
                                      ? TimelineRowsViewport(
                                          // Pass calculated visible range directly as parameters
                                          // This eliminates the need for a controller with ValueNotifiers
                                          visibleStart: _visibleStart,
                                          visibleEnd: _visibleEnd,
                                          centerItemIndex: _centerItemIndex,
                                          stagesRows: stagesRows,
                                          rowHeight: rowHeight,
                                          rowMargin: rowMargin,
                                          dayWidth: dayWidth,
                                          dayMargin: dayMargin,
                                          totalDays: days.length,
                                          colors: widget.colors,
                                          isUniqueProject: isUniqueProject,
                                          viewportWidth: _viewportWidth,
                                          viewportHeight: _viewportHeight,
                                          openEditStage: widget.openEditStage,
                                          openEditElement: widget.openEditElement,
                                        )
                                      : const SizedBox.shrink()), // Handle empty stages
                            ),
                          ),
                          // CHARGE DYNAMIQUE
                          SizedBox(
                            height: barHeight,
                            child: days.isNotEmpty
                                ? TimelineViewport(
                                    visibleStart: _visibleStart,
                                    visibleEnd: _visibleEnd,
                                    centerItemIndex: _centerItemIndex,
                                    items: days,
                                    itemWidth: dayWidth,
                                    itemMargin: dayMargin,
                                    itemBuilder: (context, index) {
                                      return TimelineBarItem(
                                        colors: widget.colors,
                                        index: index,
                                        centerItemIndex: _centerItemIndex,
                                        centerItemIndexNotifier: _centerItemIndexNotifier,
                                        nowIndex: nowIndex,
                                        day: days[index],
                                        elements: widget.elements,
                                        dayWidth: dayWidth,
                                        dayMargin: dayMargin,
                                        height: barHeight,
                                        openDayDetail: widget.openDayDetail,
                                      );
                                    },
                                  )
                                : const SizedBox.shrink(), // Handle empty days
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
