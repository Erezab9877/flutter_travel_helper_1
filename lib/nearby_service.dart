import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_travel_helper/models/place/nearby_response.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class NearbyService {
  static const String _apiKey = "AIzaSyCtDZe1bsOKTMKwId3f9oggIaHb8h2sakw";

  static Future<NearbyPlacesResponse?> getNearbyPlaces(String type, LatLng location, int radius) async {
    var url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location.latitude},${location.longitude}&radius=$radius&type=$type&key=$_apiKey',
    );

    var response = await http.get(url);

    if (response.statusCode == 200) {
      return NearbyPlacesResponse.fromJson(jsonDecode(response.body));
    } else {
      if (kDebugMode) {
        print('Failed to load nearby places');
      }
      return null;
    }
  }
}
