import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';

// Widgets
import 'timeline_day_info.dart';
import 'timeline_day_indicators.dart';
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

import 'package:swiip_pubdev_timeline/src/tools/tools.dart';
import 'package:swiip_pubdev_timeline/src/platform/platform_language.dart';

class Timeline extends StatefulWidget {
  const Timeline(
      {super.key,
      required this.colors,
      required this.mode,
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
  final String mode;
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

  // Valeur du slider
  double sliderValue = 0.0;
  double sliderMargin = 25;
  double sliderMaxValue = 10;

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

    // Vérifie que la timleline recoit bien des élement
    if (widget.elements != null && widget.elements.isNotEmpty) {
      // On positionne les dates de début et de fin
      if (widget.infos['startDate'] != null) {
        startDate = DateTime.parse(widget.infos['startDate']!);
      }
      // Si la timeline n'a aucun élement
      if (widget.infos['endDate'] != null) {
        endDate = DateTime.parse(widget.infos['endDate']!);
      }

      // Validate date range
      TimelineErrorHandler.withErrorHandling(
        'validateDateRange',
        () => TimelineErrorHandler.validateDateRange(startDate, endDate),
        endDate,
      );
    } else {
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

    // Calcule la valeur maximum du slider
    sliderMaxValue = days.length.toDouble() * (dayWidth - dayMargin);

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
    // - mettre à jour la valeur du slide
    // - reporter le scroll sur les étapes
    // - Si mode stages/éléments, scroll vertical automatique
    double oldSliderValue = 0.0;
    int oldCenterItemIndex = 0;
    _controllerTimeline.addListener(() {
      _performanceMonitor.startOperation('scroll_update');

      if (_controllerTimeline.offset >= 0 &&
          _controllerTimeline.offset < sliderMaxValue) {
        // Update TimelineController with throttling
        _timelineController.updateScrollOffset(_controllerTimeline.offset);

        // Met à jour les valeurs
        setState(() {
          // On met à jour la valeur du slider
          sliderValue = _controllerTimeline.offset;
        });

        // Get centerItemIndex from controller
        final centerItemIndex = _timelineController.centerItemIndex.value;

        // On fait le croll vertical automatique uniquement si l'élément du centre a changé. (optimisation)
        if (oldCenterItemIndex != centerItemIndex) {
          // Cancel any pending debounce timer
          _verticalScrollDebounceTimer?.cancel();

          // Debounce the vertical scroll calculations
          _verticalScrollDebounceTimer =
              Timer(_verticalScrollDebounceDuration, () {
            _performAutoScroll(centerItemIndex, oldSliderValue);
          });

          // Mise à jour du centre précédent
          oldCenterItemIndex = centerItemIndex;
        }

        // Mise à jour de la position précédente
        oldSliderValue = sliderValue;

        if (widget.updateCurrentDate != null && days.isNotEmpty) {
          // Use clampIndex to ensure safe array access
          final safeIndex = TimelineErrorHandler.clampIndex(
              centerItemIndex, 0, days.length - 1);
          if (days[safeIndex] != null && days[safeIndex]['date'] != null) {
            String dayDate =
                DateFormat('yyyy-MM-dd').format(days[safeIndex]['date']);
            widget.updateCurrentDate!.call(dayDate);
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

      // Scrollbar position will be updated in build() based on available height
      if (mounted) {
        setState(() {
          // Just trigger rebuild, calculations will happen in build()
        });
      }
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
    // Clamp the index to valid range
    final safeIndex =
        TimelineErrorHandler.clampIndex(dateIndex, 0, days.length - 1);

    if (safeIndex >= 0 && days.isNotEmpty) {
      // On calcule la valeur du scroll en fonction de la date
      double scroll = safeIndex * (dayWidth - dayMargin);

      // Clamp scroll offset to valid range
      scroll = TimelineErrorHandler.clampScrollOffset(scroll, sliderMaxValue);

      // Met à jour la valeur du scroll et scroll
      setState(() {
        sliderValue = scroll;
      });
      if (animated) {
        _scrollHAnimated(sliderValue);
      } else {
        _scrollH(sliderValue);
      }
    }
  }

  // Déclenche le scroll dans le controller timeline
  void _scrollH(double sliderValue) {
    // gestion du scroll via le slide
    _controllerTimeline.jumpTo(sliderValue);
  }

  // Déclenche le scroll dans le controller timeline
  void _scrollHAnimated(double sliderValue) {
    // gestion du scroll via le slide
    _controllerTimeline.animateTo(sliderValue,
        duration: _config.animationDuration, curve: Curves.easeInOut);
  }

  // Scroll vertical des stages automatique
  void _scrollV(double sliderValue) {
    // Marque que c'est un scroll automatique
    _isAutoScrolling = true;
    // gestion du scroll via le slide
    _controllerVerticalStages
        .animateTo(sliderValue,
            duration: _config.animationDuration, curve: Curves.easeInOut)
        .then((_) {
      // Une fois l'animation terminée, on réinitialise le flag
      _isAutoScrolling = false;
    });
  }

  // Perform auto-scroll with optimized calculations
  void _performAutoScroll(int centerItemIndex, double oldSliderValue) {
    if (widget.mode != 'chronology') return;
    if (stagesRows.isEmpty) return; // Guard against empty stages
    if (!_controllerVerticalStages.hasClients) {
      return; // Guard against no scroll controller
    }

    bool enableAutoScroll = false;

    // Index à gauche de l'écran - clamp to valid range
    int leftItemIndex = TimelineErrorHandler.clampIndex(
        centerItemIndex - 4, 0, days.length - 1);

    // On récupère l'index de la ligne du stage/élément la plus haute (optimized)
    int higherRowIndex =
        getHigherStageRowIndexOptimized(stagesRows, leftItemIndex);

    debugPrint(
        '🔍 AutoScroll Debug: centerIndex=$centerItemIndex, leftIndex=$leftItemIndex, higherRowIndex=$higherRowIndex, stagesRows.length=${stagesRows.length}');

    if (higherRowIndex == -1) {
      debugPrint(
          '⚠️ No matching row found for leftItemIndex=$leftItemIndex (should not happen with new logic)');
      return; // No matching row found
    }

    // Clamp higherRowIndex to valid range
    higherRowIndex = TimelineErrorHandler.clampIndex(
        higherRowIndex, 0, stagesRows.length - 1);

    // On calcule la hauteur de la ligne du stage/élément la plus haute
    double higherRowHeight = (higherRowIndex * (rowHeight + (rowMargin * 2)));
    // On vérifie si on est pas en bas du scroll pour éviter l'effet rebond du scroll en bas
    double totalRowsHeight = (rowHeight + rowMargin) * stagesRows.length;

    // Get current viewport height from controller if available
    double currentViewportHeight = _controllerVerticalStages.hasClients
        ? _controllerVerticalStages.position.viewportDimension
        : timelineHeightContainer;

    debugPrint(
        '📊 Heights: higherRowHeight=$higherRowHeight, totalRowsHeight=$totalRowsHeight, userScrollOffset=$userScrollOffset, viewportHeight=$currentViewportHeight');

    // On active le scroll automatique si :
    // - L'utilisateur n'a PAS scrollé manuellement (userScrollOffset == null)
    // - OU si l'utilisateur a scrollé mais le stage visible est plus bas que sa position
    enableAutoScroll = userScrollOffset == null ||
        (userScrollOffset != null && userScrollOffset! < higherRowHeight);

    debugPrint('✅ EnableAutoScroll (initial): $enableAutoScroll');

    // On ne calcule l'élément le plus bas que si on scroll vers la gauche
    // et que l'utilisateur a scrollé à la main (optimisation)
    if (sliderValue < oldSliderValue && userScrollOffset != null) {
      // Index à droite de l'écran - clamp to valid range
      int rightItemIndex = TimelineErrorHandler.clampIndex(
          centerItemIndex + 4, 0, days.length - 1);

      // On récupère l'index de la ligne du stage/élément la plus basse (optimized)
      int lowerRowIndex =
          getLowerStageRowIndexOptimized(stagesRows, rightItemIndex);

      if (lowerRowIndex != -1) {
        // Clamp lowerRowIndex to valid range
        lowerRowIndex = TimelineErrorHandler.clampIndex(
            lowerRowIndex, 0, stagesRows.length - 1);

        // On calcule la hauteur de la ligne du stage/élément la plus basse
        double lowerRowHeight = (lowerRowIndex * (rowHeight + (rowMargin * 2)));
        // On active le scroll si le stage visible est plus haut que la position de l'utilisateur
        enableAutoScroll = userScrollOffset == null ||
            (userScrollOffset != null && userScrollOffset! > lowerRowHeight);

        debugPrint(
            '⬅️ Scrolling left: lowerRowIndex=$lowerRowIndex, lowerRowHeight=$lowerRowHeight, enableAutoScroll=$enableAutoScroll');
      }
    }

    // On vérifie si l'utilisateur a fait un scroll manuel pour éviter de le perdre
    // On ne reprend le scroll automatique que si le stage/élément le plus haut est plus bas que le scroll de l'utilisateur
    if (enableAutoScroll) {
      if (totalRowsHeight - higherRowHeight > currentViewportHeight / 2) {
        // On déclenche le scroll
        debugPrint('🎯 Scrolling to: $higherRowHeight');
        _scrollV(higherRowHeight);
      } else {
        debugPrint('🎯 Scrolling to max extent');
        _scrollV(_controllerVerticalStages.position.maxScrollExtent);
      }
      // Réinitialise le scroll saisi par l'utilisateur
      userScrollOffset = null;
    } else {
      debugPrint('❌ AutoScroll disabled');
    }
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

            // Update TimelineController with actual viewport width immediately
            if (_timelineController.viewportWidth.value != screenWidth) {
              // Update synchronously to ensure visible range is calculated correctly
              _timelineController.updateViewportWidth(screenWidth);
            }

            // On calcule le padding pour avoir le début et la fin de la timeline au milieu de l'écran
            double firstElementMargin =
                ((screenWidth - (dayWidth - dayMargin)) / 2);
            double screenCenter = (screenWidth / 2);

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
                                width: widget.mode == 'chronology' ? 1.5 : 0),
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
                                      horizontal: firstElementMargin),
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
                                                        nowIndex: nowIndex,
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

                    // JOUR ET ICONES ELEMENTS
                    ValueListenableBuilder<int>(
                      valueListenable: _timelineController.centerItemIndex,
                      builder: (context, centerItemIndex, _) {
                        // Guard against empty days or invalid index
                        if (days.isEmpty || centerItemIndex >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return TimelineDayInfo(
                            lang: lang,
                            day: days[centerItemIndex],
                            colors: widget.colors,
                            elements: widget.elements,
                            openDayDetail: widget.openDayDetail);
                      },
                    ),
                    // ALERTES
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Stack(clipBehavior: Clip.none, children: [
                          // Alertes positionnées
                          SizedBox(
                              width: screenWidth - (sliderMargin * 2),
                              height: 50,
                              child: Padding(
                                  padding: EdgeInsets.only(
                                      left: sliderMargin - (alertWidth / 2)),
                                  child: Builder(builder: (context) {
                                    List<Widget> alerts = [];
                                    double screenWidthMargin =
                                        screenWidth - ((sliderMargin) * 4);
                                    if (days.isNotEmpty) {
                                      // On parcourt les jours et on ajoute les alertes
                                      for (var index = 0;
                                          index < days.length;
                                          index++) {
                                        if (days[index]['alertLevel'] != 0) {
                                          alerts.add(Positioned(
                                              left: (index) *
                                                  screenWidthMargin /
                                                  days.length,
                                              top: 0,
                                              child: GestureDetector(
                                                  // Call back lors du clic
                                                  onTap: () {
                                                    setState(() {
                                                      sliderValue =
                                                          index.toDouble();
                                                    });
                                                  },
                                                  child: Icon(
                                                    Icons.circle_rounded,
                                                    size: 12,
                                                    color: days[index][
                                                                'alertLevel'] ==
                                                            1
                                                        ? widget
                                                            .colors['warning']
                                                        : (days[index][
                                                                    'alertLevel'] ==
                                                                2
                                                            ? widget
                                                                .colors['error']
                                                            : Colors
                                                                .transparent),
                                                  ))));
                                        }
                                      }
                                    }
                                    // Point sur le jour en cours
                                    alerts.add(Positioned(
                                        left: (nowIndex) *
                                            screenWidthMargin /
                                            days.length,
                                        top: 0,
                                        child: GestureDetector(
                                            // Call back lors du clic
                                            onTap: () {
                                              scrollTo(nowIndex);
                                            },
                                            child: Icon(
                                              Icons.circle_outlined,
                                              size: 13,
                                              color:
                                                  widget.colors['primaryText'],
                                            ))));
                                    return Stack(
                                        children: alerts.isNotEmpty
                                            ? alerts
                                            : [const SizedBox()]);
                                  }))),
                          // Slider
                          Positioned(
                              bottom: 0,
                              child: SizedBox(
                                  width: screenWidth - (sliderMargin * 2),
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      thumbColor: widget.colors['primary'],
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 8.0),
                                      activeTrackColor:
                                          widget.colors['primary'],
                                      inactiveTrackColor:
                                          widget.colors['secondaryBackground'],
                                      trackHeight: 2,
                                    ),
                                    child: Slider(
                                      value: sliderValue,
                                      min: 0,
                                      max: sliderMaxValue,
                                      divisions: days.length,
                                      onChanged: (double value) {
                                        sliderValue = value;
                                        _scrollH(value);
                                      },
                                    ),
                                  )))
                        ])),
                  ]),
                ),
                if (widget.mode == 'effort')
                  Positioned.fill(
                    left: 1,
                    top: 35,
                    child: Align(
                        alignment: Alignment.centerLeft,
                        // INDICATEURS
                        child: ValueListenableBuilder<int>(
                          valueListenable: _timelineController.centerItemIndex,
                          builder: (context, centerItemIndex, _) {
                            // Guard against empty days or invalid index
                            if (days.isEmpty ||
                                centerItemIndex >= days.length) {
                              return const SizedBox.shrink();
                            }
                            return TimelineDayIndicators(
                                day: days[centerItemIndex],
                                colors: widget.colors,
                                elements: widget.elements);
                          },
                        )),
                  ),
                if (widget.mode == 'chronology')
                  // SCROLLBAR CUSTOM
                  // Scrollbar personnalisée (Positionné à droite)
                  Positioned(
                    right: 0,
                    top: 65,
                    bottom:
                        100, // Use bottom constraint instead of fixed height
                    child: SizedBox(
                      width: 8,
                      child: LayoutBuilder(
                        builder: (context, scrollbarConstraints) {
                          // Use available height from constraints
                          final availableScrollbarHeight =
                              scrollbarConstraints.maxHeight;

                          // Calculate scrollbar dimensions dynamically
                          final totalContentHeight =
                              stagesRows.length * rowHeight;
                          final viewportHeight = availableScrollbarHeight;

                          // Calculate scrollbar height proportionally
                          final calculatedScrollbarHeight =
                              totalContentHeight > 0
                                  ? (viewportHeight *
                                          viewportHeight /
                                          totalContentHeight)
                                      .clamp(20.0, viewportHeight)
                                  : 0.0;

                          // Calculate scrollbar offset based on scroll position
                          final currentScrollOffset =
                              _controllerVerticalStages.hasClients
                                  ? _controllerVerticalStages.position.pixels
                                  : 0.0;
                          final maxScrollExtent =
                              _controllerVerticalStages.hasClients
                                  ? _controllerVerticalStages
                                      .position.maxScrollExtent
                                  : 1.0;

                          final calculatedScrollbarOffset = maxScrollExtent > 0
                              ? (currentScrollOffset / maxScrollExtent) *
                                  (viewportHeight - calculatedScrollbarHeight)
                              : 0.0;

                          // Ensure scrollbar height doesn't exceed available space
                          final clampedScrollbarHeight =
                              calculatedScrollbarHeight.clamp(
                                  0.0, availableScrollbarHeight);
                          final clampedScrollbarOffset =
                              calculatedScrollbarOffset.clamp(
                                  0.0,
                                  availableScrollbarHeight -
                                      clampedScrollbarHeight);

                          return Stack(children: [
                            Positioned(
                                right: 0,
                                top: clampedScrollbarOffset,
                                child: Container(
                                  width: 4,
                                  height: clampedScrollbarHeight,
                                  decoration: BoxDecoration(
                                    color: widget.colors['secondaryBackground']!
                                        .withAlpha(120),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ))
                          ]);
                        },
                      ),
                    ),
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
