import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';

// Widgets
import 'timeline_day_date.dart';
import 'lazy_timeline_viewport.dart';
import 'lazy_stage_rows_viewport.dart';
import 'optimized_timeline_item.dart';
import 'loading_indicator_overlay.dart';

// Models
import 'models/timeline_controller.dart';
import 'models/timeline_data_manager.dart';
import 'models/timeline_error_handler.dart';
import 'models/performance_monitor.dart';
import 'models/timeline_configuration.dart';
import 'models/timeline_configuration_manager.dart';
import 'models/configuration_loader.dart';
import 'models/scroll_state.dart';

// Scroll calculations
import 'scroll_calculations.dart';

import 'package:swiip_pubdev_timeline/src/tools/tools.dart';
import 'package:swiip_pubdev_timeline/src/platform/platform_language.dart';

/// A high-performance Flutter timeline/Gantt chart widget for displaying project schedules.
///
/// The Timeline widget provides a scrollable view of project stages, milestones, and activities
/// across a date range. It uses lazy rendering and granular state management to efficiently
/// handle large datasets (500+ days with 100+ stages).
///
/// ## Features
///
/// - **Standard Scrolling**: Native Flutter scrolling with mouse wheel, trackpad, and touch gestures
/// - **Lazy Rendering**: Only renders visible items plus a configurable buffer
/// - **Data Caching**: Caches formatted data to avoid redundant calculations
/// - **Scroll Throttling**: Limits scroll updates to ~60 FPS for smooth performance
/// - **Auto-Scroll**: Vertical scrolling automatically follows horizontal position
/// - **External Configuration**: Performance tuning via JSON configuration file
///
/// ## Scrolling Behavior
///
/// - **Horizontal**: Scroll through timeline days using mouse wheel (with Shift), trackpad gestures,
///   or touch drag. Programmatic scrolling available via [scrollTo] method.
/// - **Vertical**: Scroll through stage rows independently. Auto-scroll follows horizontal position
///   when enabled.
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
/// - [TimelineController] for scroll state management
/// - [TimelineConfiguration] for performance tuning options
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
  final Function(String, double?, List<String>?, List<dynamic>?, dynamic)?
      openDayDetail;
  final Function(String?, String?, String?, String?, String?, double?, String?)?
      openEditStage;
  final Function(String?, String?, String?, String?, String?, double?, String?)?
      openEditElement;
  final Function(String?)? updateCurrentDate;

  @override
  State<Timeline> createState() => _Timeline();
}

class _Timeline extends State<Timeline> {
  // Liste des jours formatés
  List days = [];

  // TimelineController for state management
  late TimelineController _timelineController;

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
  // Hauteur du container de la timeline et des stages/éléments
  double timelineHeightContainer = 300.0;
  // Hauteur de la timeline
  double timelineHeight = 300.0;
  // Diamètre des pins d'alertes
  double alertWidth = 6;
  // Liste des widgets des alertes
  List<Widget> alertList = [];

  // Liste des lignes d'étapes
  List stagesRows = [];
  // Hauteur d'une ligne d'étapes
  double rowHeight = 30.0;
  // Marges d'une ligne d'étapes
  double rowMargin = 3.0;

  // Date de début et date de fin par défaut
  DateTime now = DateTime.now();
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now().add(const Duration(days: 30));
  int nowIndex = 0;
  int defaultDateIndex = -1;
  bool timelineIsEmpty = false;

  // Controllers des scroll
  final ScrollController _controllerTimeline = ScrollController();
  final ScrollController _controllerVerticalStages = ScrollController();

  // Position du scroll vertical
  double scrollbarHeight = 0.0;
  double scrollbarOffset = 0.0;
  // Scroll vertical si l'utilisateur a scrollé à la main
  double? userScrollOffset;
  // Flag pour indiquer si le scroll vertical est automatique
  bool _isAutoScrolling = false;

  // Track previous scroll state for direction detection
  double _previousScrollOffset = 0.0;
  int _previousCenterIndex = 0;

  // First element margin for centering calculations
  double _firstElementMargin = 0.0;

  bool isUniqueProject = false;

  // Debouncing timer for vertical scroll calculations
  Timer? _verticalScrollDebounceTimer;
  static const _verticalScrollDebounceDuration = Duration(milliseconds: 100);

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
        _isInitialized = true;
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

    // Apply configuration values to instance variables
    dayWidth = _config.dayWidth;
    dayMargin = _config.dayMargin;
    datesHeight = _config.datesHeight;
    timelineHeightContainer = _config.timelineHeight;
    rowHeight = _config.rowHeight;
    rowMargin = _config.rowMargin;

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
        elementsDone:
            (widget.elementsDone == null || widget.elementsDone.isEmpty)
                ? List.empty()
                : widget.elementsDone,
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
      'getFormattedStageRows',
      () => _dataManager.getFormattedStageRows(
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
      defaultDateIndex =
          DateTime.parse(widget.defaultDate!).difference(startDate).inDays + 1;
    }

    // Initialize TimelineController (viewportWidth will be updated in build)
    _timelineController = TimelineController(
      dayWidth: dayWidth,
      dayMargin: dayMargin,
      totalDays: days.length,
      viewportWidth:
          800, // Default width, will be updated with actual width in build
      scrollThrottleDuration: _config.scrollThrottleDuration,
      bufferDays: _config.bufferDays,
    );

    // Écoute du scroll pour :
    // - calculer quel élément est au centre
    // - mettre à jour le TimelineController avec la position de scroll
    // - Si mode stages/éléments, scroll vertical automatique
    _controllerTimeline.addListener(() {
      _performanceMonitor.startOperation('scroll_update');

      final currentOffset = _controllerTimeline.offset;
      final maxScrollExtent = _controllerTimeline.position.maxScrollExtent;

      if (currentOffset >= 0 && currentOffset < maxScrollExtent) {
        // 1. Mise à jour du TimelineController (throttled)
        _timelineController.updateScrollOffset(currentOffset);

        // 2. Calcul de l'état de scroll (CALCUL PUR)
        final scrollState = _calculateScrollState(
          currentScrollOffset: currentOffset,
          previousScrollOffset: _previousScrollOffset,
        );

        // 3. Vérification si le centre a changé de manière significative
        // Pour éviter les sauts à chaque cran de molette, on ne déclenche l'auto-scroll
        // que si le changement est significatif (au moins 2 jours de différence)
        final centerIndexDifference =
            (scrollState.centerDateIndex - _previousCenterIndex).abs();
        const minCenterIndexChange = 2; // Minimum 2 jours de différence

        if (scrollState.centerDateIndex != _previousCenterIndex) {
          // Mise à jour du callback de date (toujours, même pour petits changements)
          _updateCurrentDateCallback(scrollState.centerDateIndex);

          // Auto-scroll uniquement si le changement est significatif
          if (centerIndexDifference >= minCenterIndexChange) {
            // Annule le timer de debounce précédent
            _verticalScrollDebounceTimer?.cancel();

            // Debounce les calculs de scroll vertical
            _verticalScrollDebounceTimer = Timer(
              _verticalScrollDebounceDuration,
              () => _applyAutoScroll(scrollState),
            );
          }

          // Sauvegarde du centre précédent
          _previousCenterIndex = scrollState.centerDateIndex;
        }

        // Sauvegarde de l'offset précédent
        _previousScrollOffset = currentOffset;
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

    // timelineHeight will be calculated from available space in build()
    // timelineHeightContainer will be calculated dynamically

    // Scrollbar position will be calculated dynamically in build()
    scrollbarOffset = 0;

    // Écoute le scroll vertical pour ajuster la scrollbar
    _controllerVerticalStages.addListener(() {
      // Détecte si c'est un scroll manuel de l'utilisateur (pas automatique)
      if (!_isAutoScrolling && _controllerVerticalStages.hasClients) {
        userScrollOffset = _controllerVerticalStages.position.pixels;
      }

      // Note: Pas de setState() ici pour éviter les rebuilds excessifs
      // qui causent le clignotement des items lazy-loaded.
      // Le scrollbar est géré automatiquement par Flutter.
      // Les mises à jour visuelles seront déclenchées par le scroll horizontal.
    });

    // Exécuter une seule fois après la construction du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Complete initial render tracking
      _performanceMonitor.endOperation('timeline_init');

      // Log metrics in debug mode
      _performanceMonitor.logMetrics();

      // On scroll sur la date du jour par défaut
      scrollTo(widget.defaultDate != null ? defaultDateIndex : nowIndex,
          animated: true);
    });
  } // End of _initializeTimeline()

  // Destruction du widget
  @override
  void dispose() {
    // Cancel debounce timer
    _verticalScrollDebounceTimer?.cancel();
    // On enlève les écoutes du scroll de la timeline et vertical
    _controllerTimeline.removeListener(() {});
    _controllerVerticalStages.removeListener(() {});
    // Dispose TimelineController
    _timelineController.dispose();
    super.dispose();
  }

  // Scroll à une date
  void scrollTo(int dateIndex, {bool animated = false}) {
    // Early return if timeline is empty or controller not ready
    if (days.isEmpty || !_controllerTimeline.hasClients) {
      return;
    }

    // Clamp the index to valid range
    final safeIndex =
        TimelineErrorHandler.clampIndex(dateIndex, 0, days.length - 1);

    if (safeIndex >= 0) {
      // Calculate the scroll offset to center the specified date
      // The formula is: scroll = dateIndex * (dayWidth - dayMargin) - (viewportWidth / 2)
      // This positions the date at the center of the viewport
      final targetPosition = safeIndex * (dayWidth - dayMargin);
      final viewportWidth = _timelineController.viewportWidth.value;
      double scroll = targetPosition - (viewportWidth / 2);

      // Clamp scroll offset to valid range using ScrollController's maxScrollExtent
      final maxScroll = _controllerTimeline.position.maxScrollExtent;
      scroll = TimelineErrorHandler.clampScrollOffset(scroll, maxScroll);

      // Scroll using ScrollController directly
      if (animated) {
        _controllerTimeline.animateTo(
          scroll,
          duration: _config.animationDuration,
          curve: Curves.easeInOut,
        );
      } else {
        _controllerTimeline.jumpTo(scroll);
      }
    }
  }

  /// Calcule l'état complet du scroll basé sur la position actuelle.
  ///
  /// Cette fonction orchestre tous les calculs de scroll sans modifier l'état.
  /// Elle appelle les fonctions de calcul pures et retourne un objet ScrollState
  /// contenant tous les résultats.
  ///
  /// ## Paramètres
  ///
  /// - [currentScrollOffset]: Position actuelle du scroll horizontal
  /// - [previousScrollOffset]: Position précédente du scroll horizontal (pour détecter la direction)
  ///
  /// ## Retourne
  ///
  /// Un objet [ScrollState] contenant:
  /// - centerDateIndex: L'index du jour au centre du viewport
  /// - targetVerticalOffset: L'offset vertical calculé pour le stage visible
  /// - enableAutoScroll: Si l'auto-scroll doit être activé
  /// - scrollingLeft: La direction du scroll (true = gauche, false = droite)
  ///
  /// ## Validates
  ///
  /// Requirements 1.1, 1.2, 1.5
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

    // 2. Détection de la direction de scroll
    final scrollingLeft = currentScrollOffset < previousScrollOffset;

    // 3. Calcul de l'offset vertical cible
    final targetVerticalOffset = calculateTargetVerticalOffset(
      centerDateIndex: centerDateIndex,
      stagesRows: stagesRows,
      rowHeight: rowHeight,
      rowMargin: rowMargin,
      scrollingLeft: scrollingLeft,
      getHigherStageRowIndex: getHigherStageRowIndexOptimized,
      getLowerStageRowIndex: getLowerStageRowIndexOptimized,
    );

    // 4. Calcul de la hauteur totale des lignes
    final totalRowsHeight = (rowHeight + rowMargin) * stagesRows.length;

    // 5. Récupération de la hauteur du viewport
    final viewportHeight = _controllerVerticalStages.hasClients
        ? _controllerVerticalStages.position.viewportDimension
        : timelineHeightContainer;

    // 6. Détermination de l'auto-scroll
    final enableAutoScroll = shouldEnableAutoScroll(
      userScrollOffset: userScrollOffset,
      targetVerticalOffset: targetVerticalOffset,
      scrollingLeft: scrollingLeft,
      totalRowsHeight: totalRowsHeight,
      viewportHeight: viewportHeight,
    );

    // 7. Retour de l'état calculé
    return ScrollState(
      centerDateIndex: centerDateIndex,
      targetVerticalOffset: targetVerticalOffset,
      enableAutoScroll: enableAutoScroll,
      scrollingLeft: scrollingLeft,
    );
  }

  /// Applique le scroll vertical automatique basé sur l'état calculé.
  ///
  /// Cette fonction APPLIQUE les changements - elle n'est PAS pure.
  /// Elle prend un ScrollState en paramètre et déclenche le scroll vertical
  /// si les conditions sont remplies.
  ///
  /// La fonction vérifie plusieurs conditions avant d'appliquer le scroll:
  /// 1. L'auto-scroll doit être activé (enableAutoScroll = true)
  /// 2. Un offset vertical cible doit être disponible (targetVerticalOffset != null)
  /// 3. Le ScrollController vertical doit avoir des clients
  /// 4. La différence entre la position actuelle et la cible doit être significative (> seuil)
  ///
  /// Si toutes les conditions sont remplies, la fonction:
  /// - Calcule l'offset final en vérifiant l'espace restant
  /// - Déclenche une animation vers l'offset calculé
  /// - Gère le flag _isAutoScrolling pour éviter les conflits
  /// - Réinitialise userScrollOffset pour permettre de futurs auto-scrolls
  ///
  /// ## Paramètres
  ///
  /// - [scrollState]: L'état de scroll calculé contenant toutes les informations nécessaires
  ///
  /// ## Validates
  ///
  /// Requirements 1.3, 1.4, 3.4
  void _applyAutoScroll(ScrollState scrollState) {
    // Vérification 1: L'auto-scroll doit être activé
    if (!scrollState.enableAutoScroll) return;

    // Vérification 2: Un offset cible doit être disponible
    if (scrollState.targetVerticalOffset == null) return;

    // Vérification 3: Le ScrollController doit avoir des clients
    if (!_controllerVerticalStages.hasClients) return;

    final targetOffset = scrollState.targetVerticalOffset!;
    final currentOffset = _controllerVerticalStages.position.pixels;
    final maxExtent = _controllerVerticalStages.position.maxScrollExtent;

    // Calcul de la hauteur totale des lignes
    final totalRowsHeight = (rowHeight + rowMargin) * stagesRows.length;

    // Récupération de la hauteur du viewport
    final viewportHeight = _controllerVerticalStages.position.viewportDimension;

    // Détermine l'offset final en vérifiant l'espace restant
    // Si l'espace restant est suffisant (> viewportHeight / 2), on scroll vers le target
    // Sinon, on scroll vers le maximum pour éviter l'effet rebond
    final finalOffset = (totalRowsHeight - targetOffset > viewportHeight / 2)
        ? targetOffset
        : maxExtent;

    // Vérification 4: La différence doit être significative pour éviter les petits sauts
    // Seuil: au moins la largeur d'un jour (dayWidth)
    // Cela correspond au déplacement minimal significatif dans la timeline
    final scrollThreshold = dayWidth;
    final scrollDifference = (finalOffset - currentOffset).abs();

    if (scrollDifference < scrollThreshold) {
      // La différence est trop petite, on ne scroll pas pour éviter les micro-mouvements
      return;
    }

    // Marque que c'est un scroll automatique
    _isAutoScrolling = true;

    // Applique le scroll avec animation
    _controllerVerticalStages
        .animateTo(
      finalOffset,
      duration: _config.animationDuration,
      curve: Curves.easeInOut,
    )
        .then((_) {
      // Une fois l'animation terminée, on réinitialise le flag
      _isAutoScrolling = false;
    });

    // Réinitialise le scroll utilisateur pour permettre de futurs auto-scrolls
    userScrollOffset = null;
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
    // If not initialized yet, show loading indicator
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: widget.colors['primaryBackground'],
        body: Center(
          child: CircularProgressIndicator(
            color: widget.colors['primary'],
          ),
        ),
      );
    }

    // Track rebuild
    _performanceMonitor.trackRebuild();

    // Langue et locale
    final String lang = platformLanguage();

    return LoadingIndicatorOverlay(
      isLoadingNotifier: _timelineController.isLoading,
      overlayColor: widget.colors['primaryBackground']?.withValues(alpha: 0.7),
      indicatorColor: widget.colors['primary'],
      child: Scaffold(
        backgroundColor: widget.colors['primaryBackground'],
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Get actual available width from parent container
            final double screenWidth = constraints.maxWidth;
            final double screenCenter = (screenWidth / 2);

            // Update TimelineController with actual viewport width immediately
            if (_timelineController.viewportWidth.value != screenWidth) {
              // Update synchronously to ensure visible range is calculated correctly
              _timelineController.updateViewportWidth(screenWidth);
            }

            // Calculate firstElementMargin once and store it for use in scroll calculations
            _firstElementMargin = ((screenWidth - (dayWidth - dayMargin)) / 2);

            // Calculate dynamic heights based on available space
            final double availableHeight = constraints.maxHeight;

            return Stack(
              // Trait rouge indiquant le jour en cours
              children: [
                Positioned(
                  left: screenCenter,
                  top: 45,
                  child: Container(
                    height: availableHeight -
                        datesHeight -
                        200, // Adjust for dates and bottom controls
                    width: 1,
                    decoration: BoxDecoration(color: widget.colors['error']),
                  ),
                ),
                Positioned.fill(
                  child:
                      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    // CONTENEUR UNIQUE AVEC SCROLL HORIZONTAL
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: widget.colors['secondaryBackground']!,
                                width: 1.5),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, innerConstraints) {
                            // Use available height from constraints
                            final availableHeight = innerConstraints.maxHeight;

                            // Update timelineHeightContainer for scrollbar calculations
                            timelineHeightContainer = availableHeight;

                            return SizedBox(
                              width: screenWidth,
                              height:
                                  availableHeight, // Use available height instead of fixed timelineHeight
                              child: Listener(
                                onPointerSignal: (event) {
                                  if (event is PointerScrollEvent) {
                                    // Scroll horizontal avec Shift+molette ou trackpad horizontal
                                    final delta = event.scrollDelta;
                                    final scrollDelta =
                                        delta.dx != 0 ? delta.dx : delta.dy;

                                    // Calcule la nouvelle position
                                    final newOffset =
                                        _controllerTimeline.position.pixels +
                                            scrollDelta;

                                    // Applique le scroll
                                    _controllerTimeline.jumpTo(
                                      newOffset.clamp(
                                        0.0,
                                        _controllerTimeline
                                            .position.maxScrollExtent,
                                      ),
                                    );
                                  }
                                },
                                child: SingleChildScrollView(
                                  controller: _controllerTimeline,
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: _firstElementMargin),
                                  child: SizedBox(
                                    height:
                                        availableHeight, // Use available height
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize
                                          .min, // Prevent Column from expanding infinitely
                                      children: [
                                        // DATES
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                  color: widget.colors[
                                                      'secondaryBackground']!,
                                                  width: 1.5),
                                            ),
                                          ),
                                          child: SizedBox(
                                            width: days.length * (dayWidth),
                                            height: datesHeight,
                                            child: days.isNotEmpty
                                                ? LazyTimelineViewport(
                                                    controller:
                                                        _timelineController,
                                                    items: days,
                                                    itemWidth: dayWidth,
                                                    itemMargin: dayMargin,
                                                    itemBuilder:
                                                        (context, index) {
                                                      return TimelineDayDate(
                                                        lang: lang,
                                                        colors: widget.colors,
                                                        index: index,
                                                        centerItemIndex:
                                                            _timelineController
                                                                .centerItemIndex
                                                                .value,
                                                        days: days,
                                                        dayWidth: dayWidth,
                                                        dayMargin: dayMargin,
                                                        height: datesHeight,
                                                      );
                                                    },
                                                  )
                                                : const SizedBox
                                                    .shrink(), // Handle empty days
                                          ),
                                        ),
                                        // STAGES/ELEMENTS DYNAMIQUES - Use Expanded to take remaining space
                                        Expanded(
                                          child: SizedBox(
                                              child: stagesRows.isNotEmpty
                                                  ? Listener(
                                                      onPointerSignal: (event) {
                                                        if (event
                                                            is PointerScrollEvent) {
                                                          // Marque que c'est un scroll manuel
                                                          if (!_isAutoScrolling) {
                                                            userScrollOffset =
                                                                _controllerVerticalStages
                                                                    .position
                                                                    .pixels;
                                                          }

                                                          // Calcule la nouvelle position
                                                          final newOffset =
                                                              _controllerVerticalStages
                                                                      .position
                                                                      .pixels +
                                                                  event
                                                                      .scrollDelta
                                                                      .dy;

                                                          // Applique le scroll
                                                          _controllerVerticalStages
                                                              .jumpTo(
                                                            newOffset.clamp(
                                                              0.0,
                                                              _controllerVerticalStages
                                                                  .position
                                                                  .maxScrollExtent,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      child:
                                                          SingleChildScrollView(
                                                        controller:
                                                            _controllerVerticalStages,
                                                        scrollDirection:
                                                            Axis.vertical,
                                                        physics:
                                                            const ClampingScrollPhysics(), // Permet un scroll fluide
                                                        child:
                                                            LazyStageRowsViewport(
                                                          controller:
                                                              _timelineController,
                                                          stagesRows:
                                                              stagesRows,
                                                          rowHeight: rowHeight,
                                                          rowMargin: rowMargin,
                                                          dayWidth: dayWidth,
                                                          dayMargin: dayMargin,
                                                          totalDays:
                                                              days.length,
                                                          colors: widget.colors,
                                                          isUniqueProject:
                                                              isUniqueProject,
                                                          verticalScrollController:
                                                              _controllerVerticalStages,
                                                          viewportHeight:
                                                              availableHeight -
                                                                  datesHeight -
                                                                  140, // Subtract dates and timeline heights
                                                          openEditStage: widget
                                                              .openEditStage,
                                                          openEditElement: widget
                                                              .openEditElement,
                                                        ),
                                                      ),
                                                    )
                                                  : const SizedBox
                                                      .shrink()), // Handle empty stages
                                        ),
                                        // TIMELINE DYNAMIQUE
                                        SizedBox(
                                          width: days.length * (dayWidth),
                                          height: 140,
                                          child: days.isNotEmpty
                                              ? LazyTimelineViewport(
                                                  controller:
                                                      _timelineController,
                                                  items: days,
                                                  itemWidth: dayWidth,
                                                  itemMargin: dayMargin,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return OptimizedTimelineItem(
                                                      colors: widget.colors,
                                                      index: index,
                                                      centerItemIndexNotifier:
                                                          _timelineController
                                                              .centerItemIndex,
                                                      nowIndex: nowIndex,
                                                      day: days[index],
                                                      elements: widget.elements,
                                                      dayWidth: dayWidth,
                                                      dayMargin: dayMargin,
                                                      height: 120,
                                                      openDayDetail:
                                                          widget.openDayDetail,
                                                    );
                                                  },
                                                )
                                              : const SizedBox
                                                  .shrink(), // Handle empty days
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ]),
                ),
                // MESSAGE SI AUCUNE ACTIVITE
                if (timelineIsEmpty)
                  Positioned.fill(
                    child: Container(
                      color: widget.colors['primaryBackground'],
                      padding: const EdgeInsets.all(25),
                      child: Center(
                          child: Text(
                        'Aucune activité ne vous a été attribuée. Vous pouvez consulter le détail des projets et configurer vos équipes.',
                        style: TextStyle(
                            color: widget.colors['primaryText'], fontSize: 15),
                      )),
                    ),
                  )
              ],
            );
          },
        ),
      ),
    );
  }
}
