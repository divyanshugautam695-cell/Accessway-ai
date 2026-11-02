import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LiveMapPage extends StatefulWidget {
  const LiveMapPage({super.key});

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  final MapController mapController = MapController();
  LatLng? current;
  List<_OsmPlace> places = [];
  bool locating = false;
  bool loadingPlaces = false;
  String? message;
  bool showOnlyAccessibilityTags = false;

  @override
  void initState() {
    super.initState();
    locateAndLoad();
  }

  Future<void> locateAndLoad() async {
    setState(() {
      locating = true;
      message = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Turn on Location Services and try again.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is needed to centre the map. You can still browse the map manually.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        current = point;
        locating = false;
      });
      mapController.move(point, 15);
      await loadNearby(point);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        locating = false;
        message = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> loadNearby(LatLng point) async {
    setState(() {
      loadingPlaces = true;
      message = null;
    });
    const endpoint = 'https://overpass-api.de/api/interpreter';
    final query = '''
[out:json][timeout:25];
(
  node(around:1800,${point.latitude},${point.longitude})[amenity~"hospital|clinic|doctors|school|university|college|community_centre|library|public_building"];
  way(around:1800,${point.latitude},${point.longitude})[amenity~"hospital|clinic|doctors|school|university|college|community_centre|library|public_building"];
  node(around:1800,${point.latitude},${point.longitude})[wheelchair];
  way(around:1800,${point.latitude},${point.longitude})[wheelchair];
);
out center tags 80;
''';
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': query},
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('OpenStreetMap data service is busy. Please retry shortly.');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = (decoded['elements'] as List<dynamic>? ?? []);
      final found = <_OsmPlace>[];
      for (final item in elements) {
        final row = item as Map<String, dynamic>;
        final tags = Map<String, dynamic>.from(row['tags'] ?? {});
        final lat = (row['lat'] ?? row['center']?['lat']) as num?;
        final lon = (row['lon'] ?? row['center']?['lon']) as num?;
        if (lat == null || lon == null) continue;
        final name = (tags['name'] ?? tags['name:en'] ?? tags['amenity'] ?? tags['building'] ?? 'Mapped place').toString();
        final wheelchair = (tags['wheelchair'] ?? 'not mapped').toString();
        final kind = (tags['amenity'] ?? tags['shop'] ?? tags['building'] ?? 'Place').toString().replaceAll('_', ' ');
        found.add(_OsmPlace(
          name: name,
          kind: kind,
          wheelchair: wheelchair,
          point: LatLng(lat.toDouble(), lon.toDouble()),
          osmId: '${row['type']}/${row['id']}',
        ));
      }
      if (!mounted) return;
      setState(() {
        places = found;
        loadingPlaces = false;
        if (found.isEmpty) {
          message = 'No mapped places found nearby. This does not mean the area has no accessible places.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadingPlaces = false;
        message = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = current ?? const LatLng(25.2138, 75.8648);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live accessibility map'),
        actions: [
          IconButton(
            tooltip: 'Use my location',
            onPressed: locating ? null : locateAndLoad,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(initialCenter: center, initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'org.accessway.ai',
                ),
                MarkerLayer(markers: [
                  if (current != null)
                    Marker(
                      point: current!,
                      width: 42,
                      height: 42,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 32),
                    ),
                  ...places.map((place) => Marker(
                    point: place.point,
                    width: 42,
                    height: 48,
                    child: GestureDetector(
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        builder: (context) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(place.name, style: Theme.of(context).textTheme.titleLarge),
                                Text(place.kind),
                                const SizedBox(height: 8),
                                Text('OpenStreetMap wheelchair tag: ${place.wheelchair}'),
                                const SizedBox(height: 8),
                                const Text('Map tags are community mapping data, not an AccessWay inspection or accessibility certification. Verify important details before travelling.'),
                                Text('OSM reference: ${place.osmId}', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ),
                      ),
                      child: const Icon(Icons.location_on, color: Color(0xFF1769E0), size: 38),
                    ),
                  )),
                ]),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(
                    current == null ? 'Map preview · Kota, Rajasthan' : 'Nearby mapped places · ${places.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )),
                  if (loadingPlaces || locating)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  IconButton(onPressed: current == null || loadingPlaces ? null : () => loadNearby(current!), icon: const Icon(Icons.refresh)),
                ]),
                if (message != null) Text(message!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const Text(
                  'Live GPS location + OpenStreetMap. Accessibility details may be missing or outdated; unknown is not inaccessible.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OsmPlace {
  const _OsmPlace({
    required this.name,
    required this.kind,
    required this.wheelchair,
    required this.point,
    required this.osmId,
  });
  final String name;
  final String kind;
  final String wheelchair;
  final LatLng point;
  final String osmId;
}
