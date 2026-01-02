import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'package:swiip_pubdev_timeline/main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Example application demonstrating the usage of the Timeline widget.
///
/// This example shows:
/// - How to configure the Timeline widget with custom colors
/// - How to fetch and display timeline data from an API
/// - How to handle user interactions (day clicks, stage edits, etc.)
/// - Performance optimization features that work automatically
///
/// ## Performance Features
///
/// The Timeline widget includes several automatic performance optimizations:
///
/// 1. **Lazy Rendering**: Only visible items are rendered, plus a 5-day buffer
///    on each side. This keeps memory usage low even with hundreds of days.
///
/// 2. **Data Caching**: Formatted data is cached and only recomputed when
///    input data changes. This significantly improves performance for large datasets.
///
/// 3. **Selective Rebuilds**: Only widgets affected by state changes are rebuilt,
///    not the entire timeline. This is achieved through ValueNotifiers and
///    ValueListenableBuilder.
///
/// 4. **Conditional Calculations**: Calculations are skipped when values haven't
///    changed significantly, reducing unnecessary work.
///
/// ## Configuration Tips
///
/// For optimal performance with large datasets:
///
/// - Minimize data updates: The timeline caches formatted data, so avoid
///   unnecessary updates to elements, stages, or capacities props.
///
/// - Use stable data structures: Ensure your data objects have consistent
///   structure to maximize cache hits.
///
/// - Monitor performance: In debug mode, the timeline logs performance metrics.
///   Use these to identify bottlenecks in your data or configuration.
///
/// ## Example Usage Patterns
///
/// ### Basic Timeline
/// ```dart
/// Timeline(
///   colors: myColors,
///   infos: myInfos,
///   elements: myElements,
///   elementsDone: [],
///   capacities: [],
///   stages: myStages,
///   openDayDetail: (date, progress, preIds, elements, indicators) {
///     // Handle day click
///   },
/// )
/// ```
///
/// ### With Custom Interactions
/// ```dart
/// Timeline(
///   // ... basic props
///   openEditStage: (id, name, type, start, end, progress, projectId) {
///     // Handle stage edit
///   },
///   openEditElement: (id, label, type, start, end, progress, projectId) {
///     // Handle element edit
///   },
/// )
/// ```
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR', null);
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // ## TIMELINE WIDGET PARAMETERS
    //
    // Color configuration for the timeline.
    // These colors control the appearance of all timeline elements.
    final Map<String, Color> colors = {
      'primary': const Color(0xFFEB1C6C),
      'secondary': const Color(0xFF3997FB),
      'primaryText': const Color(0xFFE1E1E1),
      'secondaryText': const Color(0xFF8591a4),
      'primaryBackground': const Color(0xFF060C1A),
      'secondaryBackground': const Color(0xFF252F43),
      'accent1': const Color(0xFF252F43),
      'accent2': const Color(0xFF697A8F),
      'success': const Color(0xFF78f25B),
      'accent4': const Color(0xFF8CFF98),
      'error': const Color(0xFFB64758),
      'warning': const Color(0xFFF6A522),
      'black': const Color(0xFF060C1A)
    };

    // Timeline dimensions
    // Note: The timeline automatically handles responsive sizing and
    // lazy rendering. Both width and height are now 100% of parent container.

    // ## APP DEFAULT
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        color: colors['primaryBackground'],
        home: FutureBuilder<Map<String, dynamic>>(
            future: fetchTimelineData(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final timelineData = snapshot.data!;

                // Prépare le changement de nomange
                if (timelineData['infos'] != null) {
                  timelineData['date_interval'] = {
                    'prj_startdate': timelineData['infos']['prj_startdate'],
                    'prj_enddate': timelineData['infos']['prj_enddate']
                  };
                }

                // The Timeline widget automatically optimizes rendering based on
                // the data size. With the current implementation:
                // - Only visible days are rendered (plus a 5-day buffer)
                // - Data formatting is cached
                // - Widget rebuilds are minimized through selective updates
                return Align(
                    alignment: Alignment.topLeft,
                    child: SafeArea(
                        left: false,
                        top: true,
                        right: false,
                        bottom: true,
                        minimum: const EdgeInsets.all(16.0),
                        child: Timeline(
                            colors: colors,
                            infos: timelineData['infos'],
                            elements: timelineData['elements'],
                            elementsDone: timelineData['elementsDone'],
                            capacities: timelineData['capacities'],
                            stages: timelineData['stages'],
                            openDayDetail: openDayDetail,
                            openEditStage: openEditStage,
                            openEditElement: openEditElement,
                            updateCurrentDate: updateCurrentDate)));
              } else {
                return const Center(child: Text('Aucune donnée disponible'));
              }
            }));
  }
}

// -----------------------------------------------------------------
// API Call to Timeline
// -----------------------------------------------------------------

/// Fetches timeline data from the API.
///
/// This function demonstrates how to load data for the Timeline widget.
/// In a production app, you would:
/// 1. Fetch data from your backend API
/// 2. Transform it to match the Timeline's expected format
/// 3. Handle errors appropriately
///
/// The Timeline widget will automatically cache and optimize this data
/// once it's provided.
Future<Map<String, dynamic>> fetchTimelineData() async {
  final baseUri = dotenv.env['API_BASE_URL'] ?? '';
  final userId = dotenv.env['USER_ID'] ?? '';
  final prjId = dotenv.env['USER_PROJECTS'] ?? '';
  final uri = '$baseUri/showTimeline?prj_id=$prjId&usp_id=$userId&timeline_segment=dashboard';
  final userToken = dotenv.env['USER_TOKEN'] ?? '';

  final response = await http.get(
    Uri.parse(uri),
    headers: {
      'user_id': userId,
      'user_token': userToken,
    },
  );
  if (response.statusCode == 200) {
    //debugPrint(response.body);
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    debugPrint(response.body);
    return await readJson();
  }
}

/// Fetch content from the json file as fallback.
///
/// This is used when the API call fails, providing a local data source
/// for development and testing.
Future<Map<String, dynamic>> readJson() async {
  final String response = await rootBundle.loadString('./timelineResults.json');
  return await json.decode(response);
}

// -----------------------------------------------------------------
// Callback Functions for User Interactions
// -----------------------------------------------------------------

/// Callback when a user clicks on a day in the timeline.
///
/// Parameters:
/// - [date]: The date of the clicked day (ISO 8601 format)
/// - [dayProgress]: Progress percentage for the day (0-100)
/// - [preIds]: List of element IDs associated with this day
/// - [elements]: List of element objects for this day
/// - [dayIndicators]: Additional indicators/metadata for the day
///
/// Use this callback to:
/// - Show a detail view for the day
/// - Navigate to a day-specific page
/// - Display a modal with day information
/// - Update other parts of your UI based on the selected day
void openDayDetail(
    String date, double? dayProgress, List<String>? preIds, List<dynamic>? elements, dynamic dayIndicators) {
  debugPrint(date.toString());
  //debugPrint(dayProgress.toString());
  debugPrint(preIds.toString());
  debugPrint(elements.toString());
  //debugPrint(dayIndicators.toString());
}

/// Callback when a user wants to edit a stage.
///
/// Parameters:
/// - [prsId]: Stage ID
/// - [prsName]: Stage name
/// - [prsType]: Stage type (milestone, cycle, sequence, stage)
/// - [startDate]: Stage start date
/// - [endDate]: Stage end date
/// - [progress]: Stage progress percentage (0-100)
/// - [prjId]: Project ID
///
/// Use this callback to:
/// - Open an edit form for the stage
/// - Navigate to a stage detail page
/// - Show a modal for stage editing
/// - Update stage data in your backend
void openEditStage(String? prsId, String? prsName, String? prsType, String? startDate, String? endDate,
    double? progress, String? prjId) {
  debugPrint('$prsId $prsName $prsType $startDate $endDate $progress $prjId');
}

/// Callback when a user wants to edit an element.
///
/// Parameters:
/// - [entityId]: Element ID
/// - [label]: Element label/name
/// - [type]: Element type (activity, deliverable, task)
/// - [startDate]: Element start date
/// - [endDate]: Element end date
/// - [progress]: Element progress percentage (0-100)
/// - [prjId]: Project ID
///
/// Use this callback to:
/// - Open an edit form for the element
/// - Navigate to an element detail page
/// - Show a modal for element editing
/// - Update element data in your backend
void openEditElement(String? entityId, String? label, String? type, String? startDate, String? endDate,
    double? progress, String? prjId) {
  debugPrint('$entityId $label $type $startDate $endDate $progress $prjId');
}

/// Callback when a day is selected (alternative to openDayDetail).
///
/// This is a simpler callback that only receives the date.
/// Use this when you only need to know which day was selected,
/// without needing the full day details.
void selectDay(String? date) {
  debugPrint(date.toString());
}

void updateCurrentDate(String? date) {
  debugPrint(date.toString());
}

/// Callback for capacity updates.
///
/// This callback is triggered when capacity data changes.
/// Use this to:
/// - Update capacity in your backend
/// - Refresh related UI components
/// - Validate capacity constraints
void updateCapacity(String data) {
  debugPrint('!!!!================================!!!!');
  debugPrint(data);
  debugPrint('${data.runtimeType}');
}
