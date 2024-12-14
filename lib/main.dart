import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/pages/page2.dart';
import 'dart:convert';
import 'config.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CarbonCourier',
      theme: ThemeData(
        primaryColor: const Color(0xFF4CAF50), // Green color from Figma
        hintColor: Colors.white, // White color from Figma
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50), // Green color from Figma
            textStyle: TextStyle(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(8.0), // Rounded corners from Figma
            ),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 18.0, // Font size from Figma
            fontWeight: FontWeight.bold, // Font weight from Figma
          ),
          bodyMedium: TextStyle(
            fontSize: 16.0, // Font size from Figma
          ),
        ),
      ),
      home: MapSample(),
    );
  }
}

class LocationInput {
  final TextEditingController controller;
  final List<String> suggestions;
  final bool isSearching;

  LocationInput({
    required this.controller,
    this.suggestions = const [],
    this.isSearching = false,
  });
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();
  List<LocationInput> _stopInputs = [];
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _mapLoaded = false;
  Timer? _debounceTimer;

  static final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(19.0760, 72.8777),
    zoom: 11,
  );

  @override
  void initState() {
    super.initState();
    _checkGoogleMapsServices();
    // Initialize with start and end locations
    _stopInputs.add(LocationInput(
      controller: TextEditingController(),
    ));
    _stopInputs.add(LocationInput(
      controller: TextEditingController(),
    ));
  }

  @override
  void dispose() {
    for (var input in _stopInputs) {
      input.controller.dispose();
    }
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkGoogleMapsServices() async {
    try {
      // ignore: unused_local_variable
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

  Future<List<String>> _getPlacePredictions(String input) async {
    if (input.isEmpty) return [];

    final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=${Config.googleApiKey}'
        '&types=address';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        return (data['predictions'] as List)
            .map((prediction) => prediction['description'] as String)
            .toList();
      }
    } catch (e) {
      print('Error getting predictions: $e');
    }
    return [];
  }

  void _onLocationInputChanged(int index, String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      if (value.isEmpty) {
        setState(() {
          _stopInputs[index] = LocationInput(
            controller: _stopInputs[index].controller,
            suggestions: [],
          );
        });
        return;
      }

      final predictions = await _getPlacePredictions(value);
      setState(() {
        _stopInputs[index] = LocationInput(
          controller: _stopInputs[index].controller,
          suggestions: predictions,
          isSearching: false,
        );
      });
    });
  }

  Widget _buildLocationInput(int index) {
    final input = _stopInputs[index];
    final isFirst = index == 0;
    final isLast = index == _stopInputs.length - 1;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: input.controller,
                    decoration: InputDecoration(
                      labelText: isFirst
                          ? 'From'
                          : isLast
                              ? 'To'
                              : 'Stop ${index}',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    onChanged: (value) => _onLocationInputChanged(index, value),
                  ),
                  if (input.suggestions.isNotEmpty)
                    Container(
                      color: Colors.white,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: input.suggestions.length,
                        itemBuilder: (context, i) {
                          return ListTile(
                            title: Text(input.suggestions[i]),
                            onTap: () {
                              input.controller.text = input.suggestions[i];
                              setState(() {
                                _stopInputs[index] = LocationInput(
                                  controller: input.controller,
                                  suggestions: [],
                                );
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            if (!isFirst && !isLast)
              IconButton(
                icon: Icon(Icons.remove_circle_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StatsPage()), 
  );
                  setState(() {
                    _stopInputs.removeAt(index);
                  });
                },
              ),
          ],
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Future<void> _getRoute() async {
    // Validate inputs
    if (_stopInputs.any((input) => input.controller.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter all locations')),
      );
      return;
    }

    try {
      Set<Marker> markers = {};
      List<LatLng> allPoints = [];

      // Calculate routes between consecutive stops
      for (int i = 0; i < _stopInputs.length - 1; i++) {
        final origin = Uri.encodeComponent(_stopInputs[i].controller.text);
        final destination =
            Uri.encodeComponent(_stopInputs[i + 1].controller.text);

        final url = 'https://maps.googleapis.com/maps/api/directions/json'
            '?origin=$origin'
            '&destination=$destination'
            '&key=${Config.googleApiKey}';

        final response = await http.get(Uri.parse(url));
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final points =
              _decodePolyline(data['routes'][0]['overview_polyline']['points']);
          allPoints.addAll(points);

          // Add markers for each stop
          final stopLatLng = LatLng(
            data['routes'][0]['legs'][0]['start_location']['lat'],
            data['routes'][0]['legs'][0]['start_location']['lng'],
          );

          markers.add(Marker(
            markerId: MarkerId('stop_$i'),
            position: stopLatLng,
            infoWindow: InfoWindow(title: 'Stop $i'),
          ));

          // Add final destination marker for last leg
          if (i == _stopInputs.length - 2) {
            final endLatLng = LatLng(
              data['routes'][0]['legs'][0]['end_location']['lat'],
              data['routes'][0]['legs'][0]['end_location']['lng'],
            );
            markers.add(Marker(
              markerId: MarkerId('destination'),
              position: endLatLng,
              infoWindow: InfoWindow(title: 'Destination'),
            ));
          }
        }
      }

      setState(() {
        _markers = markers;
        _polylines = {
          Polyline(
            polylineId: PolylineId('route'),
            points: allPoints,
            color: Colors.green,
            width: 5,
          ),
        };
      });

      // Fit bounds to show all points
      if (allPoints.isNotEmpty) {
        final bounds = _getBounds(allPoints);
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }
    } catch (e) {
      print('Error getting route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting route: $e')),
      );
    }
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carbon Route'),
        backgroundColor: Color(0xFF4CAF50),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                // Handle profile button press
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: _stopInputs.length > 2 ? 2 : 1,
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
          Expanded(
            flex: 1,
            child: Container(
              color:
                  Color(0xFFF0F0F0), // Light grey background color from Figma
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._stopInputs.asMap().entries.map((entry) {
                    return _buildLocationInput(entry.key);
                  }).toList(),
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_stopInputs.length < 10)
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _stopInputs.insert(
                                  _stopInputs.length - 1,
                                  LocationInput(
                                      controller: TextEditingController()));
                            });
                          },
                          icon: Icon(Icons.add),
                          label: Text('Add Stop'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                                0xFF4CAF50), // Green color from Figma
                            textStyle: TextStyle(
                                color: Colors.white), // White text color.
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8.0), // Rounded corners from Figma
                            ),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: _getRoute,
                        icon: Icon(Icons.directions),
                        label: Text('Show Route'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Color(0xFF4CAF50), // Green color from Figma
                          textStyle: TextStyle(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                8.0), // Rounded corners from Figma
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
