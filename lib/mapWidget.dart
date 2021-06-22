import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';
import 'globals.dart' as globals;
import 'package:proj4dart/proj4dart.dart' as proj4;

class MapWidget extends StatefulWidget {
  final MarkerLayerOptions markers;

  const MapWidget({Key key, this.markers}) : super(key: key);

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  var resolutions = <double>[];
  var epsg;
  var index = 0;
  var epsgOptions = [
    Epsg3857(),
    Epsg4326(),
    Proj4Crs.fromFactory(
      code: 'EPSG:3413',
      proj4Projection: proj4.Projection.add('EPSG:3413',
          '+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs'),
      resolutions: <double>[
        32768,
        16384,
        8192,
        4096,
        2048,
        1024,
        512,
        256,
        128
      ],
    ),
    Proj4Crs.fromFactory(
      code: 'EPSG:3413',
      proj4Projection: proj4.Projection.add('EPSG:3413',
          '+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs'),
      resolutions: <double>[
        32768,
        16384,
        8192,
        4096,
        2048,
        1024,
        512,
        256,
        128
      ],
    )
  ];
  @override
  void initState() {
    super.initState();
    epsg = epsgOptions[index];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: LatLng(32.086569, 34.789790),
              crs: epsg,
              zoom: 8,
              minZoom: 3,
              maxZoom: 17,
              onPositionChanged: (pos, bool) => Future.delayed(
                Duration.zero,
                () async {
                  setState(() {});
                },
              ),
            ),
            layers: [
              TileLayerOptions(
                urlTemplate: globals.mapLqUrl,
                backgroundColor: Colors.transparent,
              ),
              TileLayerOptions(
                urlTemplate: globals.mapUrl,
                backgroundColor: Colors.transparent,
              ),
              widget.markers,
            ],
          ),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                index++;
                epsg = epsgOptions[index % epsgOptions.length];
              });
            },
            child: Row(
              children: [
                Icon(Icons.track_changes),
                Text((index % epsgOptions.length).toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
