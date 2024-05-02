import 'package:dio/dio.dart';
import 'package:flutter_travel_helper/models/place/place_model.dart';
import 'package:flutter_travel_helper/models/prediction/predictions_model.dart';

class PlaceSearchService {
  PlaceSearchService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const _autoCompletePath = '/autocomplete/json?';
  static const _placeSearchPath = '/details/json?';
  static const _key = "AIzaSyCtDZe1bsOKTMKwId3f9oggIaHb8h2sakw";

  Future<Place?> getPlace(String placeId) async {
    final placeDetail = await _dio.get(
      '$_baseUrl$_placeSearchPath',
      queryParameters: {'place_id': placeId, 'key': 'AIzaSyCtDZe1bsOKTMKwId3f9oggIaHb8h2sakw'},
    );
    if (placeDetail.statusCode != 200) {
      throw Error();
    }
    return Place.fromJson(
      placeDetail.data as Map<String, dynamic>,
    );
  }

  Future<PredictionResponse?> placesAutoCompleteSearch(String input) async {
    final placeDetail = await _dio.get(
      '$_baseUrl$_autoCompletePath',
      queryParameters: {'input': input, 'key': _key},
    );
    if (placeDetail.statusCode != 200) {
      throw Error();
    }
    return PredictionResponse.fromJson(
      placeDetail.data as Map<String, dynamic>,
    );
  }
}
