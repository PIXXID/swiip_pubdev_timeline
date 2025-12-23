import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'package:swiip_pubdev_timeline/main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await initializeDateFormatting('fr_FR', null);
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // ## PARAMETRES DU WIDGET
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
    const double width = 500;
    const double height = 420;

    // ## APP DEFAULT
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        color:  colors['primaryBackground'],
        home: FutureBuilder<Map<String, dynamic>>(
            future: fetchTimelineData(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final timelineData = snapshot.data!;


                // Prépare le changement de nomange
                if (timelineData['infos'] != null) {
                  timelineData['date_interval'] = {
                    'prj_startdate' : timelineData['infos']['prj_startdate'],
                    'prj_enddate' : timelineData['infos']['prj_enddate']
                  };
                }
  
                // Mode 'effort' / 'chronology'
                return Align(
                  alignment: Alignment.topLeft,
                  child: SafeArea(
                    left: false,
                    top: true,
                    right: false,
                    bottom: true,
                    minimum: const EdgeInsets.all(16.0),
                    child: Timeline(
                      width: width,
                      height: height,
                      colors: colors,
                      projectCount: 1,
                      mode : 'chronology',
                      infos: timelineData['infos'],
                      elements: timelineData['elements'],
                      elementsDone: timelineData['elementsDone'],
                      capacities: timelineData['capacities'],
                      stages: timelineData['stages'],
                      notifications: timelineData['notifications'],
                      openDayDetail: openDayDetail,
                      openEditStage: openEditStage,
                      openEditElement: openEditElement
                    ),
                  ));
              } else {
                return const Center(child: Text('Aucune donnée disponible'));
              }
            }));
  }
}

// -----------------------------------------------------------------
// Appel API à la Timeline
// -----------------------------------------------------------------

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

// Fetch content from the json file
Future<Map<String, dynamic>> readJson() async {
  final String response = await rootBundle.loadString('./timelineResults.json');
  return await json.decode(response);
}

// -----------------------------------------------------------------
// Fonctions Callback pour tests
// -----------------------------------------------------------------
void openDayDetail(String date, double? dayProgress, List<String>? preIds,
    List<dynamic>? elements, dynamic dayIndicators) {
  debugPrint(date.toString());
  //debugPrint(dayProgress.toString());
  debugPrint(preIds.toString());
  debugPrint(elements.toString());
  //debugPrint(dayIndicators.toString());
}


void openEditStage(String? prsId, String? prsName, String? prsType, String? startDate, String? endDate, double? progress, String? prjId) {
      debugPrint('$prsId $prsName $prsType $startDate $endDate $progress $prjId');
}


void openEditElement(String? entityId,  String? label, String? type, String? startDate, String? endDate, double? progress, String? prjId) {
  debugPrint(
      '$entityId $label $type $startDate $endDate $progress $prjId');
}

void selectDay(String? date) {
  debugPrint(date.toString());
}

void updateCapacity(String data) {
  debugPrint('!!!!================================!!!!');
  debugPrint(data);
  debugPrint('${data.runtimeType}');
}
