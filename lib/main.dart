import 'dart:convert';
import 'dart:io';
import 'package:PsudoMap/mapWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'package:latlong/latlong.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Getting the data and init globals (so anywhere we can access those variables)
  Map<String, dynamic> jsonEnvFile = await loadEnvJsonFile();
  initGlobals(jsonEnvFile);

  HttpOverrides.global = new MyHttpOverrides();

  MarkerLayerOptions sensorMarkers = await getGroundSensorsOnce();

  runApp(PsudoMapApp(sensorMarkers));
}

class PsudoMapApp extends StatelessWidget {
  final MarkerLayerOptions markers;
  PsudoMapApp(this.markers);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Psudo Map',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MapWidget(
        markers: markers,
      ),
    );
  }
}

/// Loading json file from assets once on the start.
Future<Map<String, dynamic>> loadEnvJsonFile() async {
  String jsonString = await rootBundle.loadString("assets/env/env.json");
  final Map<String, dynamic> jsonResponse = jsonDecode(jsonString);
  return jsonResponse;
}

void initGlobals(Map<String, dynamic> jsonEnvFile) {
  globals.gatewayUrl = jsonEnvFile["gatewayUrl"];
  globals.environment = jsonEnvFile["environment"];
  globals.mapLqUrl = jsonEnvFile["mapLqUrl"];
  globals.mapUrl = jsonEnvFile["mapUrl"];
  globals.bridgeProxy = jsonEnvFile["bridgeProxy"];
  globals.bridgeProxyPort = jsonEnvFile["bridgeProxyPort"];
}

/// Override HTTPS protocol for red
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    HttpClient httpClient = super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true;
      };

    if (globals.bridgeProxy != "") {
      httpClient.findProxy = (Uri url) =>
          'PROXY ${globals.bridgeProxy}:${globals.bridgeProxyPort};';
    }
    return httpClient;
  }
}

Future<List<dynamic>> getDataFromServer(String url) async {
  try {
    final response = await http
        .get(url, headers: {'Cookie': "ztube-token=${globals.tokenApi}"});
    return jsonDecode(response.body);
  } catch (e) {
    throw Exception();
  }
}

Future<MarkerLayerOptions> getGroundSensorsOnce() async {
  List<dynamic> dataJson;
  List<LatLng> locations = List<LatLng>();
  List<Marker> markers = List<Marker>();
  String sensorTypeUrl = globals.gatewayUrl + "/telemetry/ground";
  try {
    // Get the sensors from the httpService as a json
    dataJson = await getDataFromServer(sensorTypeUrl);
  } catch (e) {
    print(
        "Failed to http get at: ${DateTime.now().toString()} at url: $sensorTypeUrl");
    return null;
  }

  dataJson.forEach(
    (sensorData) {
      try {
        locations.add(LatLng(sensorData['geometry']['coordinates'][1],
            sensorData['geometry']['coordinates'][0]));
      } catch (e) {
        throw Exception("Failed to parse location for sensor");
      }
    },
  );

  locations.forEach((location) {
    markers.add(Marker(
        point: location,
        builder: (context) {
          return SvgPicture.asset(
            "assets/Icons/Sensors/ConstSensorOnline.svg",
            height: 30,
            width: 30,
          );
        }));
  });

  return MarkerLayerOptions(
    markers: markers,
  );
}
