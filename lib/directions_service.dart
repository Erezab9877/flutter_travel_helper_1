import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionsService {
  final String apiKey;

  DirectionsService({required this.apiKey});

  Future<String> getDirections({
    required LatLng origin,
    required String destination,
    required List<String> waypoints,
  }) async {
    String waypointsStr = waypoints.join('|');
    String originStr = '${origin.latitude},${origin.longitude}';
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=$originStr&destination=$destination&waypoints=$waypointsStr&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return response.body;
      // return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load directions');
    }
  }
}
