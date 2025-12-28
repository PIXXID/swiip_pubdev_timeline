import 'dart:async';
import 'package:flutter/material.dart';
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

import 'package:swiip_pubdev_timeline/src/tools/tools.dart';
import 'package:swiip_pubdev_timeline/src/platform/platform_language.dart';

class Timeline extends StatefulWidget {
  const Timeline(
      {Key? key,
      required this.width,
      required this.height,
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
      this.updateCurrentDate})
      : super(key: key);

  final double width;
  final double height;
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

  bool isUniqueProject = false;

  // Debouncing timer for vertical scroll calculations
  Timer? _verticalScrollDebounceTimer;
  static const _verticalScrollDebounceDuration = Duration(milliseconds: 100);

  // Initialisation
  @override
  void initState() {
    super.initState();
    debugPrint('------ Timeline InitState');

    // Initialize PerformanceMonitor (only enabled in debug mode)
    _performanceMonitor = PerformanceMonitor();
    _performanceMonitor.startOperation('timeline_init');

    // Initialize TimelineDataManager
    _dataManager = TimelineDataManager();

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

    // Initialize TimelineController
    _timelineController = TimelineController(
      dayWidth: dayWidth,
      dayMargin: dayMargin,
      totalDays: days.length,
      viewportWidth: widget.width,
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

    // Personnalise la taile de l'affichage
    timelineHeight = widget.height;
    timelineHeightContainer = timelineHeight - datesHeight;

    // Calcule la position de la scrollbar
    scrollbarHeight = timelineHeightContainer *
        timelineHeightContainer /
        (stagesRows.length * rowHeight);
    scrollbarOffset = 0;

    // Écoute le scroll vertical pour ajuster la scrollbar
    _controllerVerticalStages.addListener(() {
      setState(() {
        double currentVerticalScrollOffset =
            _controllerVerticalStages.position.pixels;
        // Hauteur de la barre de scroll
        scrollbarHeight = timelineHeightContainer *
            timelineHeightContainer /
            (stagesRows.length * rowHeight);
        // Position de la bar selon le scroll (en tenant compte de la hauteur de la barre)
        scrollbarOffset = currentVerticalScrollOffset *
            (timelineHeightContainer - (scrollbarHeight * 2)) /
            (stagesRows.length * rowHeight);
      });
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
  }

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
        duration: const Duration(milliseconds: 220), curve: Curves.easeInOut);
  }

  // Scroll vertical des stages automatique
  void _scrollV(double sliderValue) {
    // gestion du scroll via le slide
    _controllerVerticalStages.animateTo(sliderValue,
        duration: const Duration(milliseconds: 220), curve: Curves.easeInOut);
  }

  // Perform auto-scroll with optimized calculations
  void _performAutoScroll(int centerItemIndex, double oldSliderValue) {
    if (widget.mode != 'chronology') return;
    if (stagesRows.isEmpty) return; // Guard against empty stages

    bool enableAutoScroll = false;

    // Index à gauche de l'écran - clamp to valid range
    int leftItemIndex = TimelineErrorHandler.clampIndex(
        centerItemIndex - 4, 0, days.length - 1);

    // On récupère l'index de la ligne du stage/élément la plus haute (optimized)
    int higherRowIndex =
        getHigherStageRowIndexOptimized(stagesRows, leftItemIndex);

    if (higherRowIndex == -1) return; // No matching row found

    // Clamp higherRowIndex to valid range
    higherRowIndex = TimelineErrorHandler.clampIndex(
        higherRowIndex, 0, stagesRows.length - 1);

    // On calcule la hauteur de la ligne du stage/élément la plus haute
    double higherRowHeight = (higherRowIndex * (rowHeight + (rowMargin * 2)));
    // On vérifie si on est pas en bas du scroll pour éviter l'effet rebond du scroll en bas
    double totalRowsHeight = (rowHeight + rowMargin) * stagesRows.length;
    // On active le scroll si l'utilisateur a fait un scroll vertical et si, quand on scroll vers la droite,
    // le stage/élément le plus haut est plus bas que le niveau de scroll de l'utilisateur
    enableAutoScroll = userScrollOffset == null ||
        userScrollOffset != null && (userScrollOffset! < higherRowHeight);

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
        // On active le scroll si l'utilisateur a fait un scroll vertical et si, quand on scroll vers la gauche,
        // le stage/élément le plus bas est plus haut que le niveau de scroll de l'utilisateur
        enableAutoScroll = userScrollOffset == null ||
            userScrollOffset != null && (userScrollOffset! > lowerRowHeight);
      }
    }

    // On vérifie si l'utilisateur a fait un scroll manuel pour éviter de le perdre
    // On ne reprend le scroll automatique que si le stage/élément le plus haut est plus bas que le scroll de l'utilisateur
    if (enableAutoScroll) {
      if (totalRowsHeight - higherRowHeight > timelineHeight / 2) {
        // On déclenche le scroll
        _scrollV(higherRowHeight);
      } else {
        _scrollV(_controllerVerticalStages.position.maxScrollExtent);
      }
      // Réinitialise le scroll saisi par l'utilisateur
      userScrollOffset = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Track rebuild
    _performanceMonitor.trackRebuild();

    // On calcule le padding pour avoir le début et la fin de la timeline au milieu de l'écran
    // double screenWidth = MediaQuery.sizeOf(context).width;
    double screenWidth = widget.width;
    double firstElementMargin = ((screenWidth - (dayWidth - dayMargin)) / 2);
    double screenCenter = (screenWidth / 2);

    // Langue et locale
    final String lang = platformLanguage();

    return LoadingIndicatorOverlay(
      isLoadingNotifier: _timelineController.isLoading,
      overlayColor: widget.colors['primaryBackground']?.withValues(alpha: 0.7),
      indicatorColor: widget.colors['primary'],
      child: Scaffold(
        backgroundColor: widget.colors['primaryBackground'],
        body: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.width),
          child: Stack(
            // Trait rouge indiquant le jour en cours
            children: [
              Positioned(
                left: screenCenter,
                top: 45,
                child: Container(
                  height: timelineHeightContainer,
                  width: 1,
                  decoration: BoxDecoration(color: widget.colors['error']),
                ),
              ),
              Positioned.fill(
                child: Column(children: <Widget>[
                  // CONTENEUR UNIQUE AVEC SCROLL HORIZONTAL
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: widget.colors['secondaryBackground']!,
                            width: widget.mode == 'chronology' ? 1.5 : 0),
                      ),
                    ),
                    child: SizedBox(
                      width: screenWidth,
                      child: SingleChildScrollView(
                        controller: _controllerTimeline,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                            horizontal: firstElementMargin),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // DATES
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      color:
                                          widget.colors['secondaryBackground']!,
                                      width: 1.5),
                                ),
                              ),
                              child: SizedBox(
                                width: days.length * (dayWidth),
                                height: datesHeight,
                                child: LazyTimelineViewport(
                                  controller: _timelineController,
                                  items: days,
                                  itemWidth: dayWidth,
                                  itemMargin: dayMargin,
                                  itemBuilder: (context, index) {
                                    return TimelineDayDate(
                                      lang: lang,
                                      colors: widget.colors,
                                      index: index,
                                      centerItemIndex: _timelineController
                                          .centerItemIndex.value,
                                      nowIndex: nowIndex,
                                      days: days,
                                      dayWidth: dayWidth,
                                      dayMargin: dayMargin,
                                      height: datesHeight,
                                    );
                                  },
                                ),
                              ),
                            ),
                            // STAGES/ELEMENTS DYNAMIQUES
                            SizedBox(
                                height:
                                    timelineHeightContainer, // Hauteur fixe pour la zone des stages
                                child: SingleChildScrollView(
                                  controller: _controllerVerticalStages,
                                  scrollDirection: Axis.vertical,
                                  physics:
                                      const ClampingScrollPhysics(), // Permet un scroll fluide
                                  child: LazyStageRowsViewport(
                                    controller: _timelineController,
                                    stagesRows: stagesRows,
                                    rowHeight: rowHeight,
                                    rowMargin: rowMargin,
                                    dayWidth: dayWidth,
                                    dayMargin: dayMargin,
                                    totalDays: days.length,
                                    colors: widget.colors,
                                    isUniqueProject: isUniqueProject,
                                    verticalScrollController:
                                        _controllerVerticalStages,
                                    viewportHeight: timelineHeightContainer,
                                    openEditStage: widget.openEditStage,
                                    openEditElement: widget.openEditElement,
                                  ),
                                )),
                            // TIMELINE DYNAMIQUE
                            SizedBox(
                              width: days.length * (dayWidth),
                              height: 140,
                              child: LazyTimelineViewport(
                                controller: _timelineController,
                                items: days,
                                itemWidth: dayWidth,
                                itemMargin: dayMargin,
                                itemBuilder: (context, index) {
                                  return OptimizedTimelineItem(
                                    colors: widget.colors,
                                    index: index,
                                    centerItemIndexNotifier:
                                        _timelineController.centerItemIndex,
                                    nowIndex: nowIndex,
                                    day: days[index],
                                    elements: widget.elements,
                                    dayWidth: dayWidth,
                                    dayMargin: dayMargin,
                                    height: 120,
                                    openDayDetail: widget.openDayDetail,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // JOUR ET ICONES ELEMENTS
                  ValueListenableBuilder<int>(
                    valueListenable: _timelineController.centerItemIndex,
                    builder: (context, centerItemIndex, _) {
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
                                                  color: days[index]
                                                              ['alertLevel'] ==
                                                          1
                                                      ? widget.colors['warning']
                                                      : (days[index][
                                                                  'alertLevel'] ==
                                                              2
                                                          ? widget
                                                              .colors['error']
                                                          : Colors.transparent),
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
                                            color: widget.colors['primaryText'],
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
                                    activeTrackColor: widget.colors['primary'],
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
                  child: SizedBox(
                    width: 8,
                    height: timelineHeightContainer,
                    child: Stack(children: [
                      Positioned(
                          right: 0,
                          top: scrollbarOffset,
                          child: Container(
                            width: 4,
                            height: scrollbarHeight,
                            decoration: BoxDecoration(
                              color: widget.colors['secondaryBackground']!
                                  .withAlpha(120),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ))
                    ]),
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
          ),
        ),
      ),
    );
  }
}
