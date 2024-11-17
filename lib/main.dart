import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart'; // Import the config file

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarbonCourier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();
  TextEditingController _fromController = TextEditingController();
  TextEditingController _toController = TextEditingController();
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _mapLoaded = false;

  // Initial camera position (Mumbai coordinates)
  static final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(19.0760, 72.8777), // Mumbai coordinates
    zoom: 11,
  );

  @override
  void initState() {
    super.initState();
    _checkGoogleMapsServices();
  }

  Future<void> _checkGoogleMapsServices() async {
    try {
      final GoogleMapController controller = await _controller.future;
      setState(() {
        _mapLoaded = true;
      });
    } catch (e) {
      print('Error initializing map: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error loading map. Please check your configuration.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CarbonCourier-route'),
        backgroundColor: Colors.green, // Theme color for CarbonCourier
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _fromController,
                  decoration: InputDecoration(
                    labelText: 'From',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _toController,
                  decoration: InputDecoration(
                    labelText: 'To',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _getRoute,
                  icon: Icon(Icons.directions),
                  label: Text('Show Route'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    //primary: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _initialPosition,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  polylines: _polylines,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                ),
                if (!_mapLoaded)
                  Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getRoute() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both locations')),
      );
      return;
    }

    final from = Uri.encodeComponent(_fromController.text);
    final to = Uri.encodeComponent(_toController.text);

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$from&destination=$to&key=${Config.googleApiKey}';

    try {
      final response = await http.get(Uri.parse(url));
      print('API Response: ${response.body}'); // Debug print

      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final points =
            _decodePolyline(data['routes'][0]['overview_polyline']['points']);

        final startLatLng = LatLng(
          data['routes'][0]['legs'][0]['start_location']['lat'],
          data['routes'][0]['legs'][0]['start_location']['lng'],
        );

        final endLatLng = LatLng(
          data['routes'][0]['legs'][0]['end_location']['lat'],
          data['routes'][0]['legs'][0]['end_location']['lng'],
        );

        setState(() {
          _markers = {
            Marker(
              markerId: MarkerId('start'),
              position: startLatLng,
              infoWindow: InfoWindow(title: 'Start'),
            ),
            Marker(
              markerId: MarkerId('end'),
              position: endLatLng,
              infoWindow: InfoWindow(title: 'End'),
            ),
          };

          _polylines = {
            Polyline(
              polylineId: PolylineId('route'),
              points: points,
              color: Colors.green,
              width: 5,
            ),
          };
        });

        final bounds = LatLngBounds(
          southwest: LatLng(
            data['routes'][0]['bounds']['southwest']['lat'],
            data['routes'][0]['bounds']['southwest']['lng'],
          ),
          northeast: LatLng(
            data['routes'][0]['bounds']['northeast']['lat'],
            data['routes'][0]['bounds']['northeast']['lng'],
          ),
        );

        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not find route: ${data['status']}')),
        );
      }
    } catch (e) {
      print('Error getting route: $e'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting route: $e')),
      );
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
